/*
TODO:
Swap "id" and "pode-id"?
- Since you can set duplicate IDs in Pode, or in Tables for example

- function for "mdi mdi-{name}" ?
  - or, make everything call PodeIcon? - would be better for more component re-use pattern

- all Home page types will need a /content url

- could we append a layout to the DOM first, and pass that as a 'sender' to elements?
  - saves building a massive html string to append if it works

- Home page only has -Layouts, really needs a -ScriptBlock as well!

- Split this files into separate files
  - Use a tool to combine and minimise on build - load this minimised file in html
*/

class PodeElementFactory {
    static classMap = new Map();
    static objMap = new Map();

    constructor() {}

    static setClass(clazz) {
        this.classMap.set(clazz.name.substring(4).toLowerCase(), clazz);
    }

    static getClass(name) {
        return this.classMap.get(name);
    }

    static invokeClass(name, action, data, sender, opts) {
        if (!name || !action) {
            return;
        }

        opts = opts ?? {};
        name = name.toLowerCase();
        action = action.toLowerCase();

        // invoke before base action event
        var detail = {
            action: action,
            data: data,
            sender: sender,
            opts: opts
        };

        var process = document.body.dispatchEvent(new CustomEvent(`pode:element.base.action.before`, {
            detail: detail
        }));
        if (!process) { return; }

        // invoke before element action event
        var process = document.body.dispatchEvent(new CustomEvent(`pode:element.${name.toLowerCase()}.action.before`, {
            detail: detail
        }));
        if (!process) { return; }

        // invoke element action
        var obj = this.findObject(name, action, data, sender, opts);
        if (action === 'new' && obj.created) {
            action = 'update';
        }
        var html = obj.refresh(action).apply(action, data, sender, opts);

        // invoke after element action event
        var process = document.body.dispatchEvent(new CustomEvent(`pode:element.${name.toLowerCase()}.action.after`, {
            detail: detail
        }));
        if (!process) { return; }

        // invoke after base action event
        var process = document.body.dispatchEvent(new CustomEvent(`pode:element.base.action.after`, {
            detail: detail
        }));
        if (!process) { return; }

        // return any result from action
        return {
            element: obj,
            html: html
        };
    }

    static findObject(name, action, data, sender, opts) {
        var clazz = this.getClass(name) ?? PodeElement;

        var obj = clazz.findId(data, sender, null, opts);
        if (obj) {
            return this.getObject(obj);
        }

        return (new clazz(data, sender, opts));
    }

    static setObject(id, obj) {
        this.objMap.set(id, obj);
    }

    static removeObject(id) {
        this.objMap.delete(id);
    }

    static getObject(id) {
        return this.objMap.get(id);
    }
}

// base elements and layouts
class PodeElement {
    static type = '';
    static tag = '';

    constructor(data, sender, opts) {
        this.id = PodeElement.makeId(data, opts);
        this.name = data.Name ?? '';
        this.uuid = generateUuid();
        this.created = false;
        this.ephemeral = false;
        this.dynamic = data.IsDynamic ?? false;
        this.autoRender = true;
        this.contentProperty = null;
        this.children = [];
        this.previous = null;
        this.next = null;
        this.isOutput = data.AsOutput ?? false;
        this.element = null;
        this.parent = opts.parent;
        this.isFirstChild = opts.isFirstChild;
        this.isLastChild = opts.isLastChild;
        this.url = `/components/${this.getType()}/${data.ID}`;

        if (this.parent) {
            this.parent.children.push(this);
        }

        PodeElementFactory.setObject(this.uuid, this);
    }

    refresh(action, force) {
        if ((action === 'new' || !this.created) && !force) {
            return this;
        }

        this.element = this.get();
        this.created = true;
        return this;
    }

    apply(action, data, sender, opts) {
        // invoke action
        switch (action) {
            case 'new':
                var html = opts.html ? opts.html : this.new(data, sender, opts);

                if (this.autoRender && sender) {
                    this.isOutput ? sender.after(html) : sender.append(html);
                    this.renderContentArea(data);
                    this.element = this.get();
                    this.load(data, sender, opts);
                    this.bind(data, sender, opts);
                    this.created = true;
                }
                else {
                    opts.html = html;
                }

                break;

            case 'update':
                this.update(data, sender, opts);
                break;

            case 'reset':
                this.reset(data, sender, opts);
                break;

            case 'submit':
                this.submit(data, sender, opts);
                break;

            case 'invoke':
                this.invoke(data, sender, opts);
                break;

            case 'enable':
                this.enable(data, sender, opts);
                break;

            case 'disable':
                this.disable(data, sender, opts);
                break;

            case 'show':
                this.show(data, sender, opts);
                break;

            case 'hide':
                this.hide(data, sender, opts);
                break;

            case 'move':
                this.move(data, sender, opts);
                break;

            case 'clear':
                this.clear(data, sender, opts);
                break;

            case 'start':
                this.start(data, sender, opts);
                break;

            case 'stop':
                this.stop(data, sender, opts);
                break;

            case 'sync':
                this.sync(data, sender, opts);
                break;

            // add, remove, set, restart
        }

        if (this.ephemeral) {
            PodeElementFactory.removeObject(this.uuid);
        }

        return opts.html;
    }

    renderContentArea(data, opts) {
        var area = this.getContentArea();
        if (!area) {
            return;
        }

        var content = this.contentProperty ? data[this.contentProperty] : data.Content;
        this.render(content, area, this, opts);
    }

    render(content, sender, parent, opts) {
        if (!content) {
            return null;
        }

        opts = opts ?? {};
        opts.parent = parent;

        content = convertToArray(content);
        var created = [];
        var html = '';

        content.forEach((item, index) => {
            opts.isFirstChild = index == 0;
            opts.isLastChild = index == content.length - 1;

            var result = PodeElementFactory.invokeClass(item.ObjectType, 'new', item, sender, opts);

            // store, and set next/previous
            created.push(result.element);
            if (index > 0) {
                result.element.previous = created[index - 1];
                created[index - 1].next = result.element;
            }
            if (index == content.length - 1) {
                result.element.next = created[0];
                created[0].previous = result.element;
            }

            // do we have any html?
            if (result.html) {
                html += result.html;
            }
        });

        return {
            html: html,
            elements: created
        };
    }

    serialize(element) {
        element = element ?? this.element;

        var data = null;
        var opts = {
            mimeType: 'multipart/form-data',
            contentType: false,
            processData: false
        };

        if (this.element.find('input[type=file]').length > 0) {
            data = newFormData(this.element.find('input, textarea, select'));
        }
        else {
            opts = null;

            if (this.checkParentType('form')) {
                data = this.element.serialize();
            }
            else {
                data = this.element.find('input, textarea, select').serialize();
            }
        }

        return {
            data: data,
            opts: opts
        };
    }

    events(evts) {
        if (!evts) {
            return '';
        }

        var strEvents = '';

        convertToArray(evts).forEach((evt) => {
            strEvents += `on${evt}="invokeEvent('${evt}', this);"`;
        });

        return strEvents;
    }

    spinner(show) {
        var spin = $(`span#${this.id}_spinner`);
        if (!spin) {
            return;
        }

        if (show) {
            spin.show();
        }
        else {
            spin.hide();
        }
    }

    tooltip(show, element) {
        element = element ?? this.element
        if (!element) {
            return;
        }

        if (element.attr('data-toggle') !== 'tooltip') {
            return;
        }

        element.tooltip(show ? 'show' : 'hide');
    }

    static makeId(data, opts) {
        if (!data.ID) {
            return null;
        }

        return opts && opts.subId ? `${data.ID}_${opts.subId}` : data.ID;
    }

    static find(data, sender, filter, opts) {
        if (!data) {
            return null;
        }

        filter = filter ?? '';

        // by ID
        var id = this.makeId(data, opts);
        if (id) {
            return $(`${this.tag}#${id}${filter}`);
        }

        // by Name
        if (data.Name) {
            if (!this.tag && this.type) {
                this.tag = `[pode-object="${this.type}"]`;
            }

            if (sender) {
                var obj = sender.find(`${this.tag}[name="${data.Name}"]${filter}`);
                if (obj.length > 0) {
                    return obj;
                }
            }

            return $(`${this.tag}[name="${data.Name}"]${filter}`);
        }

        return null;
    }

    static findId(data, sender, filter, opts) {
        var obj = this.find(data, sender, filter, opts);
        if (!obj) {
            return;
        }

        return obj.attr('pode-id');
    }

    filterChildren(func, firstOnly) {
        if (!func) {
            return null;
        }

        var result = this.children.filter(func);
        return firstOnly ? result[0] : result;
    }

    getType() {
        return this.constructor.type.toLowerCase();
    }

    getTag() {
        return this.constructor.tag.toLowerCase();
    }

    get() {
        return $(`[pode-id="${this.uuid}"]`);
    }

    checkParentType(type) {
        return this.parent ? this.parent.getType() === type.toLowerCase() : false;
    }

    getContentArea() {
        return this.get().find(`#${this.id}_content`);
    }

    html() {
        return this.get()[0].outerHTML;
    }

    reset(data, sender, opts) {
        this.element[0].reset();
    }

    submit(data, sender, opts) {
        this.element.trigger('click');
    }

    invoke(data, sender, opts) {
        this.submit(data, sender, opts);
    }

    enable(data, sender, opts) {
        enable(this.element);
    }

    disable(data, sender, opts) {
        disable(this.element);
    }

    show(data, sender, opts) {
        this.element.show();
    }

    hide(data, sender, opts) {
        this.element.hide();
    }

    sync(data, sender, opts) {
        this.load(data, sender, opts);
    }

    new(data, sender, opts) {
        throw `${this.getType()} "new" method not implemented`
    }

    update(data, sender, opts) {
        throw `${this.getType()} "update" method not implemented`
    }

    move(data, sender, opts) {
        throw `${this.getType()} "move" method not implemented`
    }

    clear(data, sender, opts) {
        throw `${this.getType()} "clear" method not implemented`
    }

    start(data, sender, opts) {
        throw `${this.getType()} "start" method not implemented`
    }

    stop(data, sender, opts) {
        throw `${this.getType()} "stop" method not implemented`
    }

    bind(data, sender, opts) {
        if (!this.element) {
            return;
        }

        this.element.find('[data-toggle="tooltip"]').tooltip();
    }

    load(data, sender, opts) {}
}

class PodeRefreshableElement extends PodeElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.refresh = {
            enabled: !(data.NoRefresh ?? false)
        };

        this.autoRefresh = {
            enabled: data.AutoRefresh ?? false,
            interval: data.RefreshInterval ?? 0
        };
    }

    buildRefreshButton(asSpan) {
        if (this.autoRefresh.enabled || !this.refresh.enabled) {
            return '';
        }

        // span?
        if (asSpan) {
            return `<span
                class='mdi mdi-refresh pode-${this.getType()}-refresh pode-refresh-btn'
                for='${this.id}'
                title='Refresh'
                data-toggle='tooltip'>
            </span>`;
        }

        // button
        return `<button
            type='button'
            class='btn btn-no-text btn-outline-secondary pode-${this.getType()}-refresh pode-refresh-btn'
            for='${this.id}'
            title='Refresh'
            data-toggle='tooltip'>
                <span class='mdi mdi-refresh mdi-size-20'></span>
        </button>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // refresh click
        this.element.find(`.pode-${this.getType()}-refresh`).off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            obj.tooltip(false, $(e.target));
            obj.load();
        });

        // auto-refresh timer
        if (this.autoRefresh.enabled) {
            var timeout = this.autoRefresh.interval;
            if (timeout == 60000) {
                timeout = (60 - (new Date()).getSeconds()) * 1000;
            }

            setTimeout(() => {
                this.load();
                setInterval(() => {
                    this.load();
                }, this.autoRefresh.interval);
            }, timeout);
        }
    }
}

class PodeFormElement extends PodeElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.readonly = data.ReadOnly ?? false;
        this.required = data.Required ?? false;
        this.autofocus = data.AutoFocus ?? false;
        this.dynamicLabel = data.DynamicLabel ?? false;
        this.inForm = this.checkParentType('form');
    }

    apply(action, data, sender, opts) {
        switch (action) {
            case 'new':
                var html = this.new(data, sender, opts);

                // help text
                if (data.HelpText) {
                    html += `<small id='${this.id}_help' class='form-text text-muted'>${data.HelpText}</small>`;
                }

                // validation
                html += `<div id="${this.id}_validation" class="invalid-feedback"></div>`;

                // are we in a form?
                html = `<div class='${this.inForm && !this.dynamicLabel ? 'col-sm-10' : ''}'>${html}</div>`;

                if (this.inForm && !this.dynamicLabel) {
                    html = `<label for='${this.id}' class='col-sm-2 col-form-label'>${data.DisplayName}</label>${html}`;
                }

                html = `<div class='pode-form-textbox ${!this.inForm || this.dynamicLabel ? '' : 'form-group row'} ${data.CssClasses}'>${html}</div>`;

                // overload html from super
                opts.html = html;
                break;
        }

        super.apply(action, data, sender, opts);
    }
}

class PodeMediaElement extends PodeElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
    }

    start(data, sender, opts) {
        this.element[0].play();
    }

    stop(data, sender, opts) {
        this.element[0].pause();
    }

    reset(data, sender, opts) {
        this.element[0].load();
    }

    update(data, sender, opts) {
        if (!data.Sources && !data.Tracks) {
            return;
        }

        // clear sources / tracks
        if (data.Sources) {
            this.element.find('source, track').remove();
        }
        else {
            this.element.find('track').remove();
        }

        // add sources
        convertToArray(data.Sources).forEach((src) => {
            this.element.append(`<source src='${src.Url}' type='${src.Type}'>`);
        });

        // add tracks
        convertToArray(data.Tracks).forEach((track) => {
            this.element.append(`<track src='${track.Url}' kind='${track.Type}' srclang='${track.Language}' label='${track.Title}' ${track.Default ? 'default' : ''}>`);
        });

        // reload
        this.reset(data, sender, opts);
    }
}

class PodeBadge extends PodeElement {
    static type = 'badge';
    static tag = 'span';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<span
            id='${this.id}'
            class='badge badge-${data.ColourType} ${data.CssClasses}'
            style='${data.CssStyles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${this.events(data.Events)}>
                ${data.Value}
        </span>`;
    }

    update(data, sender, opts) {
        // change text
        if (data.Value) {
            this.element.text(decodeHTML(data.Value));
        }

        // change colour
        if (data.Colour) {
            replaceClass(this.element, 'badge-\\w+', `badge-${data.ColourType}`);
        }
    }
}
PodeElementFactory.setClass(PodeBadge);

class PodeText extends PodeElement {
    static type = 'text';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var html = `<span
            id='${this.id}'
            class='pode-text ${data.CssClasses}'
            style='${data.CssStyles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                ${data.Value}
        </span>`;

        switch (data.Style.toLowerCase()) {
            case 'underlined':
                html = `<u>${html}</u>`;
                break;

            case 'strikethrough':
                html = `<s>${html}</s>`;
                break;

            case 'deleted':
                html = `<del>${html}</del>`;
                break;

            case 'inserted':
                html = `<ins>${html}</ins>`;
                break;

            case 'italics':
                html = `<em>${html}</em>`;
                break;

            case 'bold':
                html = `<strong>${html}</strong>`;
                break;

            case 'small':
                html = `<small>${html}</small>`;
                break;
        }

        if (data.Pronunciation) {
            html = `<ruby>${html} <rt>${data.Pronunciation}</rt></ruby>`
        }

        if (data.InParagraph) {
            html = `<p class='text-${data.Alignment}'>${html}</p>`
        }

        return html;
    }

    static find(data, sender, filter, opts) {
        var text = super.find(data, sender, filter, opts);
        if (!text) {
            return null;
        }

        if (!text.hasClass('pode-text')) {
            var subText = text.find('.pode-text');
            text = subText.length == 0 ? text : subText;
        }

        return text;
    }

    update(data, sender, opts) {
        this.element.text(decodeHTML(data.Value));
    }
}
PodeElementFactory.setClass(PodeText);

class PodeSpinner extends PodeElement {
    static type = 'spinner';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var colour = '';
        if (data.Colour) {
            colour = `color:${data.Colour};`
        }

        var title = '';
        if (data.Title) {
            title = `title='${data.Title}' data-toggle='tooltip'`;
        }

        return `<span
            id='${this.id}'
            class="spinner-border spinner-border-sm ${data.CssClasses}"
            style="${colour} ${data.CssStyles}"
            role="status"
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            role='status'
            ${title}>
        </span>`;
    }
}
PodeElementFactory.setClass(PodeSpinner);

class PodeLink extends PodeElement {
    static type = 'link';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<a
            href='${data.Source}'
            id='${this.id}'
            class="${data.CssClasses}"
            style="${data.CssStyles}"
            target='${data.NewTab ? '_blank' : '_self'}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${this.events(data.Events)}>
                ${data.Value}
        </a>`;
    }
}
PodeElementFactory.setClass(PodeLink);

class PodeIcon extends PodeElement {
    static type = 'icon';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var colour = '';
        if (data.Colour) {
            colour = `color:${data.Colour};`
        }

        var title = '';
        if (data.Title) {
            title = `title='${data.Title}' data-toggle='tooltip'`;
        }

        var spin = '';
        if (data.Spin) {
            spin = 'mdi-spin'
        }

        var flip = '';
        if (data.Flip) {
            flip = `mdi-flip-${data.Flip[0]}`.toLowerCase();
        }

        var rotate = '';
        if (data.Rotate > 0) {
            rotate = `mdi-rotate-${data.Rotate}`;
        }

        // mdi-size-20
        //TODO: add new Size parameter

        return `<span
            id='${this.id}'
            class='mdi mdi-${this.name.toLowerCase()} ${spin} ${flip} ${rotate} ${data.CssClasses}'
            style='${colour} ${data.CssStyles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${title}
            ${this.events(data.Events)}>
        </span>`;
    }
}
PodeElementFactory.setClass(PodeIcon);

class PodeButton extends PodeElement {
    static type = 'button';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.iconOnly =  data.IconOnly;
    }

    new(data, sender, opts) {
        var newLine = '';
        if (data.NewLine) {
            newLine = '<br/>';
        }

        var icon = '';
        if (data.Icon) {
            icon = `<span class='mdi mdi-${data.Icon.toLowerCase()} mRight02'></span>`;
        }

        var disabled = data.Disabled ? 'disabled' : '';
        var disabled_link = data.Disabled ? "tabindex='-1' aria-disabled='true'" : '';
        var html = '';

        if (this.iconOnly) {
            if (this.dynamic) {
                html = `<button
                    type='button'
                    class='btn btn-icon-only pode-button ${data.CssClasses}'
                    style='${data.CssStyles}'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    title='${data.DisplayName}'
                    data-toggle='tooltip'
                    pode-object='${this.getType()}'
                    pode-id='${this.uuid}'
                    ${disabled}>
                        ${icon}
                </button>`;
            }
            else {
                html = `<a
                    role='button'
                    class='btn btn-icon-only pode-link-button ${data.CssClasses} ${disabled}'
                    style='${data.CssStyles}'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    title='${data.DisplayName}'
                    href='${data.Url}'
                    target='${data.NewTab ? '_blank' : '_self'}'
                    data-toggle='tooltip'
                    pode-object='${this.getType()}'
                    pode-id='${this.uuid}'
                    ${disabled_link}>
                        ${icon}
                </a>`;
            }
        }
        else {
            var colour = data.ColourType;
            if (data.Outline) {
                colour = `outline-${colour}`;
            }

            if (this.dynamic) {
                html = `<button
                    type='button'
                    class='btn btn-${colour} ${data.SizeType} pode-button ${data.CssClasses}'
                    style='${data.CssStyles}'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    pode-object='${this.getType()}'
                    pode-colour='${data.ColourType}'
                    pode-id='${this.uuid}'
                    ${disabled}>
                        <span class='spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
                        ${icon}
                        <span class='pode-text'>${data.DisplayName}</span>
                </button>`;
            }
            else {
                html = `<a
                    role='button'
                    class='btn btn-${colour} ${data.SizeType} pode-link-button ${data.CssClasses} ${disabled}'
                    style='${data.CssStyles}'
                    id='${this.id}'
                    name='${this.name}'
                    href='${data.Url}'
                    target='${data.NewTab ? '_blank' : '_self'}'
                    pode-data-value='${data.DataValue}'
                    pode-object='${this.getType()}'
                    pode-colour='${data.ColourType}'
                    pode-id='${this.uuid}'
                    ${disabled_link}>
                        ${icon}
                        <span class='pode-text'>${data.DisplayName}</span>
                </a>`;
            }
        }

        if (this.checkParentType('form')) {
            html = `<span class='form-group'>${html}</span>`
        }

        return `${newLine}${html}`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        this.element.off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            // hide tooltip
            obj.tooltip(false);

            // find a form
            var inputs = {};
            var form = obj.element.closest('form');
            if (form) {
                inputs = obj.serialize(form);
            }

            // get a data value
            var dataValue = getDataValue(obj.element);
            if (dataValue) {
                inputs.data = addFormDataValue(inputs.data, 'Value', dataValue);
            }

            sendAjaxReq(obj.url, inputs.data, obj.element, true, null, inputs.opts);
        });
    }

    update(data, sender, opts) {
        if (data.Icon) {
            replaceClass(this.element.find('span.mdi'), 'mdi-\\w+', `mdi-${data.Icon.toLowerCase()}`);
        }

        if (data.DisplayName) {
            if (this.iconOnly) {
                setTitle(this.element, data.DisplayName);
            }
            else {
                this.element.find('span.pode-text').text(decodeHTML(data.DisplayName));
            }
        }

        // change colour
        if (!this.iconOnly && (data.Colour || data.ColourState != 'unchanged')) {
            var isOutline = hasClass(this.element, 'btn-outline-\\w+');
            var colour = this.element.attr('pode-colour');

            var _class = isOutline ? `btn-outline-${colour}` : `btn-${colour}`;
            removeClass(this.element, _class, true);

            if (data.ColourState != 'unchanged') {
                isOutline = (data.ColourState == 'outline');
            }

            if (data.Colour) {
                colour = data.ColourType;
                this.element.attr('pode-colour', colour);
            }

            _class = isOutline ? `btn-outline-${colour}` : `btn-${colour}`;
            addClass(this.element, _class);
        }

        // change size
        if (!this.iconOnly && (data.Size || data.SizeState != 'unchanged')) {
            if (data.SizeState != 'unchanged') {
                if (data.SizeState == 'normal') {
                    removeClass(this.element, 'btn-block', true);
                }
                else {
                    addClass(this.element, 'btn-block');
                }
            }

            if (data.Size) {
                replaceClass(this.element, 'btn-(sm|lg)', data.SizeType);
            }
        }
    }
}
PodeElementFactory.setClass(PodeButton);

class PodeContainer extends PodeElement {
    static type = 'container';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="container pode-container ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-transparent="${data.NoBackground}"
            pode-hidden="${data.Hide}"
            pode-id='${this.uuid}'>
                <div id="${this.id}_content"></div>
        </div>`;
    }
}
PodeElementFactory.setClass(PodeContainer);

class PodeForm extends PodeElement {
    static type = 'form';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.showReset = data.ShowReset ?? false;
        this.action = data.Action ?? '';
        this.method = data.Method ?? 'POST';
    }

    new(data, sender, opts) {
        var resetBtn = !this.showReset ? '' : `<button
            class='btn btn-inbuilt-sec-theme form-reset'
            for='${this.id}'
            type='button'>
                ${data.ResetText}
        </button>`;

        var html = `<form
            id="${this.id}"
            name="${this.name}"
            class="pode-form ${data.CssClasses}"
            style="${data.CssStyles}"
            method="${this.method}"
            action="${this.action}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <div id="${this.id}_content"></div>

                <button class="btn btn-inbuilt-theme" type="submit">
                    <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true" style="display: none"></span>
                    ${data.SubmitText}
                </button>

                ${resetBtn}
        </form>`;

        if (data.Message) {
            html += `<p class='card-text'>${data.Message}</p>`;
        }

        return html;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // submit form
        this.element.off('submit').on('submit', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var result = obj.serialize();
            sendAjaxReq(obj.action, result.data, obj.element, true, null, result.opts);
        });

        // reset form
        if (this.showReset) {
            this.element.find('.form-reset').off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                obj.reset();
                unfocus($(this));
            });
        }
    }

    submit(data, sender, opts) {
        $(this.element[0]).find('[type="submit"]').trigger('click');
    }
}
PodeElementFactory.setClass(PodeForm);

class PodeToast extends PodeElement {
    static type = 'toast';

    constructor(...args) {
        super(...args);
        this.ephemeral = true;
    }

    show(data, sender, opts) {
        var toastArea = $('div#toast-area');
        if (toastArea.length == 0) {
            return;
        }

        toastArea.append(`
            <div pode-id="${this.uuid}" class="toast" role="alert" aria-live="assertive" aria-atomic="true" data-delay="${data.Duration}">
                <div class="toast-header">
                    <span class='mdi mdi-${data.Icon.toLowerCase()}'></span>
                    <strong class="mr-auto mLeft05">${data.Title}</strong>
                    <button type="button" class="ml-2 mb-1 close" data-dismiss="toast" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="toast-body">
                    ${data.Message}
                </div>
            </div>
        `);

        $(`div[pode-id='${this.uuid}']`).on('hidden.bs.toast', function(e) {
            $(e.target).remove();
        })

        $(`div[pode-id='${this.uuid}']`).toast('show');
    }
}
PodeElementFactory.setClass(PodeToast);

class PodeCard extends PodeElement {
    static type = 'card';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var header = '';
        if ((!data.NoTitle && this.name) || !data.NoHide) {
            var icon = data.Icon ? `<span class='mdi mdi-${data.Icon.toLowerCase()} mRight02'></span>` : '';
            var title = data.NoTitle ? `${icon}` : `${icon}${data.DisplayName}`;
            var hideBtn = data.NoHide ? '' : `<div class='btn-toolbar mb-2 mb-md-0 mTop-05'>
                <div class='btn-group mr-2'>
                    <button type='button' class='btn btn-no-text btn-outline-secondary pode-card-collapse'>
                        <span class='mdi mdi-eye-outline mdi-size-20' title='Hide' data-toggle='tooltip'></span>
                    </button>
                </div>
            </div>`;

            header = `<div class='card-header d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 border-bottom'>
                <h5>${title}</h5>
                ${hideBtn}
            </div>`;
        }

        return `<div
            id="${this.id}"
            class="card pode-card ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                ${header}
                <div id="${this.id}_content" class="card-body"></div>
        </div>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);

        this.element.find('.pode-card-collapse').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            var btn = $(this);
            toggleIcon(btn, 'eye-outline', 'eye-off-outline', 'Hide', 'Show');
            btn.closest('.card').find('.card-body').slideToggle();
            unfocus(btn);
        });
    }
}
PodeElementFactory.setClass(PodeCard);

class PodeAlert extends PodeElement {
    static type = 'alert';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="alert alert-${data.ClassType} ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'
            role="alert"
            ${this.events(data.Events)}>
                <h6 class='pode-alert-header'>
                    <span class="mdi mdi-${data.IconType.toLowerCase()}"></span>
                    <strong>${data.Type}</strong>
                </h6>
                <div id='${this.id}_content' class='pode-alert-body pode-text'>
                    ${data.Value ? data.Value : ''}
                </div>
        </div>`;
    }
}
PodeElementFactory.setClass(PodeAlert);

class PodeTable extends PodeRefreshableElement {
    static type = 'table';
    static tag = 'div';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.dataColumn = data.DataColumn;
        this.clickableRows = data.Click ?? false;
        this.clickIsDynamic = data.ClickIsDynamic ?? false;

        this.export = {
            enabled: data.Export ?? false
        };

        this.sort = {
            enabled: data.Sort.Enabled ?? false,
            simple: data.Sort.Simple ?? false
        };

        this.filter = {
            enabled: data.Filter.Enabled ?? false,
            simple: data.Filter.Simple ?? false
        };

        this.paging = {
            enabled: data.Paging.Enabled ?? false,
            current: 1,
            count: 1,
            size: 20
        };
    }

    new(data, sender, opts) {
        var msg = data.Message ? `<p class='card-text'>${data.Message}</p>` : '';

        var filter = !this.filter.enabled ? '' : `<div class='input-group mb-2'>
            <div class='input-group-prepend'><div class='input-group-text'><span class='mdi mdi-filter'></span></div></div>
            <input type='text' class='form-control mBottom1 pode-table-filter' id='filter_${this.id}' placeholder='Filter' for='${this.id}' pode-simple='${data.Filter.Simple}'>
        </div>`;

        var paging = !this.paging.enabled ? '' : `<nav role='pagination' aria-label='${this.name} Pages' for='${this.id}' pode-page-size='${data.Paging.Size}' pode-current-page='1'>
            <ul class='pagination justify-content-end'>
            </ul>
        </nav>`;

        var exportBtn = !this.export.enabled ? '' : `<button type='button' class='btn btn-no-text btn-outline-secondary pode-table-export' for='${this.id}' title='Export' data-toggle='tooltip'>
            <span class='mdi mdi-download mdi-size-20'></span>
        </button>`;

        var customBtns = '';
        convertToArray(data.Buttons).forEach((btn) => {
            customBtns += `<button type='button' class='btn btn-no-text btn-outline-secondary pode-table-button' for='${this.id}' title='${btn.Name}' data-toggle='tooltip' name='${btn.Name}'>
                <span class='mdi mdi-${btn.Icon.toLowerCase()} mdi-size-20 ${$btn.WithText ? "mRight02" : ''}'></span>
                ${btn.WithText ? btn.DisplayName : ''}
            </button>`;
        });

        return `${msg}<div
            id='${this.id}'
            name='${this.name}'
            class="${data.CssClasses}"
            style='${data.CssStyles}'
            role='table'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            pode-data-column='${this.dataColumn}'>
                ${filter}
                <div class="table-responsive">
                    <table
                        class='table table-striped table-hover ${data.Compact ? 'table-sm' : ''} ${data.Click ? 'pode-table-click' : ''}'
                        pode-dynamic='${this.dynamic}'>
                            <thead></thead>
                            <tbody></tbody>
                    </table>
                    <div class='text-center'>
                        <span id='${this.id}_spinner' class='spinner-grow text-inbuilt-sec-theme' role='status' style='display: none'></span>
                    </div>
                </div>
                <div role='controls'>
                    <div class="btn-group mr-2">
                    ${this.buildRefreshButton(false)}
                    ${exportBtn}
                    ${customBtns}
                    </div>
                    ${paging}
                </div>
        </div>`;
    }

    getPagingInfo() {
        if (!this.paging.enabled) {
            return null;
        }

        var pagination = this.element.find('nav[role="pagination"]');
        if (pagination.length == 0) {
            return null;
        }

        var index = pagination.find('a.page-link.active').text();
        if (index.length == 0) {
            index = 1;
        }

        return {
            size: parseInt(pagination.attr('pode-page-size') ?? 20),
            index: parseInt(index)
        };
    }

    getSortingInfo() {
        if (!this.sort.enabled) {
            return null;
        }

        var header = this.element.find('table th[sort-direction!="none"]');
        if (header.length == 0) {
            return null;
        }

        header = $(header[0]);
        return {
            column: header.text(),
            direction: header.attr('sort-direction')
        };
    }

    filterRows() {
        if (!this.filter.simple) {
            return;
        }

        var value = this.element.find('input.pode-table-filter').val();
        this.element.find(`table tbody tr:not(:icontains('${value}'))`).hide();
        this.element.find(`table tbody tr:icontains('${value}')`).show();
    }

    buildPaging(index, count, size) {
        if (!this.paging.enabled) {
            return;
        }

        this.paging.count = count;
        this.paging.size = size;

        var paging = this.element.find('nav[role="pagination"] ul');
        var parent = paging.parent();

        parent.find('input.page-size').remove();
        paging.empty();

        // current page
        parent.attr('pode-current-page', index);

        // page size
        parent.prepend(`<input type="number" id="${parent.attr('for')}_size" class="form-control page-size" value="${size}" min="1">`);

        // if there is only 1 total page, don't even bother showing pagination
        if (count <= 1) {
            return;
        }

        // first
        paging.append(`
            <li class="page-item">
                <a class="page-link page-arrows page-first" href="#" aria-label="First" title="First (1)" data-toggle="tooltip">
                    <span aria-hidden="true">&lt;&lt;</span>
                </a>
            </li>`);

        // previous
        paging.append(`
            <li class="page-item">
                <a class="page-link page-arrows page-previous" href="#" aria-label="Previous" title="Previous" data-toggle="tooltip">
                    <span aria-hidden="true">&lt;</span>
                </a>
            </li>`);

        var pageActive = '';

        // pages
        var gap = (index == 1 || index == count ? 2 : 1);

        for (var i = (index - gap); i <= (index + gap); i++) {
            if (i < 1 || i > count) {
                continue;
            }

            pageActive = (i == index ? 'active' : '');
            paging.append(`<li class="page-item"><a class="page-link ${pageActive}" href="#">${i}</a></li>`);
        }

        // next
        paging.append(`
            <li class="page-item">
                <a class="page-link page-arrows page-next" href="#" aria-label="Next" pode-max="${count}" title="Next" data-toggle="tooltip">
                    <span aria-hidden="true">&gt;</span>
                </a>
            </li>`);

        // last
        paging.append(`
            <li class="page-item">
                <a class="page-link page-arrows page-last" href="#" aria-label="Last" pode-max="${count}" title="Last (${count})" data-toggle="tooltip">
                    <span aria-hidden="true">&gt;&gt;</span>
                </a>
            </li>`);
    }

    load(data, sender, opts) {
        // ensure the table is dynamic, or has "for" attr
        if (!this.dynamic && !this.element.attr('for')) {
            return;
        }

        // show spinner
        opts = opts ?? {};
        this.element.find('table tbody').empty();
        this.spinner(true);

        // define any table paging
        var query = '';
        if (opts.page) {
            var pageIndex = (opts.page.index ?? 1);
            var pageSize = (opts.page.size ?? 20);
            query = `PageIndex=${pageIndex}&PageSize=${pageSize}`;
        }
        else if (this.paging.enabled) {
            var paging = this.getPagingInfo();
            if (paging) {
                query = `PageIndex=${paging.index}&PageSize=${paging.size}`;
            }
        }

        // define any filter value
        if (this.filter.enabled) {
            var filter = this.element.find(`input#filter_${this.id}`).val();
            if (query) {
                query += '&';
            }

            query += `Filter=${filter}`;
        }

        // define any sorting
        if (opts.sort) {
            if (query) {
                query += '&';
            }

            query += `SortColumn=${opts.sort.column}&SortDirection=${opts.sort.direction}`;
        }
        else if (this.sort.enabled) {
            var sorting = this.getSortingInfo(this.element);
            if (sorting) {
                if (query) {
                    query += '&';
                }

                query += `SortColumn=${sorting.column}&SortDirection=${sorting.direction}`;
            }
        }

        // things get funky here if we have a table with a 'for' attr
        // if so, we need to serialize the form, and then send the request to the form instead
        var url = this.url;

        if (this.element.attr('for')) {
            var form = $(`#${this.element.attr('for')}`);
            if (query) {
                query += '&';
            }

            query += form.serialize();
            url = form.attr('action');
        }

        // if we're reloading, hide all query and show spinner
        // if (opts.reload) {
        //     table.find('tbody').empty();
        //     showLoadingSpinner(tableId);
        // }

        // invoke and load table content
        sendAjaxReq(url, query, this.element, true);
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // export
        if (this.export.enabled) {
            this.element.find('.pode-table-export').off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                obj.tooltip(false, $(this));
                obj.download();
            });
        }

        // sort
        if (this.sort.enabled) {
            this.element.find('table thead th').off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                var header = $(this);

                // what direction to sort?
                var direction = ({
                    none: 'asc',
                    asc: 'desc',
                    desc: 'asc'
                })[(header.attr('pode-direction') ?? 'none')];

                obj.element.find('table thead th').attr('sort-direction', 'none');
                header.attr('sort-direction', direction);

                // simple or dynamic sorting?
                if (obj.sort.simple) {
                    var rows = obj.element.find('table tr:gt(0)').toArray().sort(comparer(header.index()));
                    if (direction === 'desc') {
                        rows = rows.reverse();
                    }

                    rows.forEach((row) => {
                        obj.element.append(row);
                    })
                }
                else {
                    obj.load(null, null, {
                        sort: {
                            column: header.text(),
                            direction: direction
                        }
                    });
                }
            });
        }

        // filter
        if (this.filter.enabled) {
            this.element.find("input.pode-table-filter").off('keyup').on('keyup', delay(function(e) {
                e.preventDefault();
                e.stopPropagation();

                if (obj.filter.simple) {
                    obj.filterRows();
                }
                else {
                    obj.load();
                }
            }, 500));
        }

        // clickable rows
        if (this.clickableRows) {
            this.element.find('tbody tr').off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();

                var rowId = $(this).attr('pode-data-value');

                // check if we have a base path
                var base = getQueryStringValue('base');
                var value = getQueryStringValue('value');
                base = base ? `${base}/${value}` : value;

                // build the data to send
                var data = `value=${rowId}`;
                if (base) {
                    data = `base=${base}&${data}`;
                }

                if (obj.clickIsDynamic) {
                    sendAjaxReq(`${obj.url}/click`, data, null, true);
                }
                else {
                    window.location = `${window.location.origin}${window.location.pathname}?${data}`;
                }
            })
        }

        // paginate
        if (this.paging.enabled) {
            this.element.find('nav[role="pagination"] input.page-size').off('keyup').on('keyup', function(e) {
                e.preventDefault();
                e.stopPropagation();
                var size = $(this);
                var pageNav = size.closest('nav');

                // on enter, reload table
                if (isEnterKey(e)) {
                    unfocus(size);
                    obj.load(null, null, {
                        page: {
                            index: 1,
                            size: parseInt((pageNav.attr('pode-page-size') ?? 20))
                        },
                        reload: true
                    });
                }

                // otherwise, set the size
                else {
                    pageNav.attr('pode-page-size', size.val());
                }
            });

            this.element.find('nav[role="pagination"] .pagination a.page-link').off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                var link = $(this);
                obj.tooltip(false, link);

                // if active/disabled, do nothing
                if (link.hasClass('active') || link.hasClass('disabled')) {
                    return;
                }

                // get page size
                var pageNav = link.closest('nav');
                var pageSize = pageNav.attr('pode-page-size') ?? 20;

                // next or previous? - get current +/-
                var pageIndex = 1;

                if (link.hasClass('page-arrows')) {
                    pageIndex = link.closest('ul').find('a.page-link.active').text();

                    if (link.hasClass('page-previous')) {
                        pageIndex--;
                    }
                    else if (link.hasClass('page-next')) {
                        pageIndex++;
                    }
                    else if (link.hasClass('page-first')) {
                        pageIndex = 1;
                    }
                    else if (link.hasClass('page-last')) {
                        pageIndex = link.attr('pode-max');
                    }
                }
                else {
                    pageIndex = link.text();
                }

                if (pageIndex <= 0 || pageIndex == obj.paging.current || pageIndex > obj.paging.count) {
                    return;
                }

                obj.paging.current = pageIndex;

                obj.load(null, null, {
                    page: {
                        index: parseInt(pageIndex),
                        size: parseInt(pageSize)
                    },
                    reload: true
                });
            });
        }

        // custom buttons
        this.element.find('.pode-table-button').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            obj.tooltip(false, $(this));
            var url = `${obj.url}/button/${$(this).attr('name')}`;
            sendAjaxReq(url, obj.export(), obj.element, true, null, { contentType: 'text/csv' });
        });
    }

    export() {
        var rows = this.element.find(`table tr:visible`);
        if (!rows || rows.length == 0) {
            return;
        }

        var csv = [];
        rows.each((i, row) => {
            var data = [];
            var cols = $(row).find('td, th');

            cols.each((i, col) => {
                data.push(col.innerText);
            });

            csv.push(data.join(","));
        });

        return csv.join("\n");
    }

    download() {
        // the csv file
        var csvFile = new Blob([this.export()], { type: "text/csv" });

        // build a hidden download link
        var downloadLink = document.createElement('a');
        downloadLink.download = `${this.name.replace(' ', '_')}.csv`;
        downloadLink.href = window.URL.createObjectURL(csvFile);
        downloadLink.style.display = 'none';

        // add the link, and click it
        document.body.appendChild(downloadLink);
        downloadLink.click();

        // remove the link
        $(downloadLink).remove();
    }

    update(data, sender, opts) {
        switch (opts.subType) {
            case 'row':
                this.updateRow(data, sender, opts);
                break;

            default:
                this.updateTable(data, sender, opts);
                break;
        }
    }

    updateRow(data, sender, opts) {
        // get the table row
        var row = null;
        switch (data.Row.Type) {
            case 'id_and_datavalue':
            case 'name_and_datavalue':
                row = this.element.find(`table tbody tr[pode-data-value="${data.Row.DataValue}"]`);
                break;

            case 'id_and_index':
            case 'name_and_index':
                row = this.element.find('table tbody tr').eq(data.Row.Index);
                break;
        }

        // do nothing if no row
        if (!row || row.length == 0) {
            return;
        }

        var rowIndex = row.index();
        console.log(data);

        // update the row's data
        if (data.Data) {
            var keys = Object.keys(data.Data);
            var elements = [];
            var renderResult = null;

            keys.forEach((key) => {
                var html = '';
                var rowData = data.Data[key];

                if (Array.isArray(rowData) || rowData.ObjectType) {
                    renderResult = this.render(rowData, null, this, { subId: rowIndex });
                    html = renderResult.html;
                    elements.push(...(renderResult.elements));
                }
                else {
                    html = rowData;
                }

                row.find(`td[pode-column="${key}"]`).html(html);
            });

            elements.forEach((e) => {
                e.refresh(null, true).bind(data, sender, opts);
            });
        }

        // update the row's background colour
        setObjectStyle(row[0], 'background-color', data.BackgroundColour);
    
        // update the row's forecolour
        setObjectStyle(row[0], 'color', data.Colour);

        // binds sort/buttons/etc
        this.bind(data, sender, opts);
    }

    updateTable(data, sender, opts) {
        data.Data = convertToArray(data.Data);
        var head = this.element.find('table thead');
        var body = this.element.find('table tbody');

        // get custom column meta
        var columns = data.Columns ?? {};

        // render initial columns for new/empty table
        var value = '';
        var direction = 'none';
        var columnHidden = false;

        var columnKeys = Object.keys(columns);

        if (head.find('th').length == 0 && columnKeys.length > 0) {
            value = '<tr>';

            columnKeys.forEach((key) => {
                value += buildTableHeader(columns[key], direction);
            });

            value += '</tr>';
            head.append(value);
        }

        // clear the table if no data
        if (data.Data.length <= 0) {
            this.clear(data, sender, opts);

            // hide spinner
            this.spinner(false);
            return;
        }

        // get data keys for table columns
        var keys = Object.keys(data.Data[0]);

        // get senderId if present, and set on table as 'for'
        if (getTagName(sender) === 'form') {
            this.element.attr('for', getId(sender));
        }

        // table headers
        value = '<tr>';
        var oldHeader = null;
        var header = null;

        keys.forEach((key) => {
            // table header sort direction
            oldHeader = head.find(`th[name='${key}']`);
            direction = oldHeader.length > 0 ? oldHeader.attr('sort-direction') : 'none';
            columnHidden = oldHeader.length > 0 ? oldHeader.hasClass('d-none') : false;

            // add the table header
            if (key in columns) {
                value += buildTableHeader(columns[key], direction, columnHidden);
            }
            else {
                value += oldHeader.length > 0
                    ? oldHeader[0].outerHTML
                    : `<th sort-direction='${direction}' name='${key}'>${key}</th>`;
            }
        });
        value += '</tr>';

        head.empty();
        head.append(value);

        // table body
        body.empty();
        var elements = null;
        var renderResult = null;

        data.Data.forEach((item, index) => {
            value = `<tr ${item[this.dataColumn] != null ? `pode-data-value="${item[this.dataColumn]}"` : ''}>`;
            elements = [];

            keys.forEach((key) => {
                header = head.find(`th[name='${key}']`);
                if (header.length > 0) {
                    value += `<td pode-column='${key}' style='`;

                    if (header.css('text-align')) {
                        value += `text-align:${header.css('text-align')};`;
                    }

                    value += "'";

                    if (header.hasClass('d-none')) {
                        value += ` class='d-none'`;
                    }

                    value += ">";
                }
                else {
                    value += `<td pode-column='${key}'>`;
                }

                if (Array.isArray(item[key]) || (item[key] && item[key].ObjectType)) {
                    renderResult = this.render(item[key], null, this, { subId: index });
                    value += renderResult.html;
                    elements.push(...(renderResult.elements));
                }
                else if (item[key] != null) {
                    value += item[key];
                }
                else if (!item[key] && header.length > 0) {
                    value += header.attr('default-value');
                }

                value += `</td>`;
            });
            value += '</tr>';
            body.append(value);

            elements.forEach((e) => {
                e.refresh(null, true).bind(data, sender, opts);
            });
        });

        // hide spinner
        this.spinner(false);
        // hideLoadingSpinner(tableId);

        // is the table paginated?
        if (this.paging.enabled) {
            this.buildPaging(data.Paging.Index, data.Paging.Max, data.Paging.Size);
        }

        // binds sort/buttons/etc
        this.bind(data, sender, opts);

        // re-filter the table
        this.filterRows();
    }

    clear(data, sender, opts) {
        // empty table
        this.element.find('table tbody').empty();

        // empty paging
        if (this.paging.enabled) {
            this.element.find('nav ul').empty();
        }
    }

    show(data, sender, opts) {
        switch (opts.subType) {
            case 'column':
                this.showColumn(data, sender, opts);
                break;

            default:
                super.show(data, sender, opts);
                break;
        }
    }

    showColumn(data, sender, opts) {
        removeClass(this.element.find(`table thead th[name="${data.Key}"]`), 'd-none', true);
        removeClass(this.element.find(`table tbody td[pode-column="${data.Key}"]`), 'd-none', true);
    }

    hide(data, sender, opts) {
        switch (opts.subType) {
            case 'column':
                this.hideColumn(data, sender, opts);
                break;

            default:
                super.hide(data, sender, opts);
                break;
        }
    }

    hideColumn(data, sender, opts) {
        addClass(this.element.find(`table thead th[name="${data.Key}"]`), 'd-none');
        addClass(this.element.find(`table tbody td[pode-column="${data.Key}"]`), 'd-none');
    }
}
PodeElementFactory.setClass(PodeTable);

class PodeAccordion extends PodeElement {
    static type = 'accordion';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        // this.cycling = data.Cycle.Enabled ?? false;
        this.contentProperty = 'Bellows'
        this.mode = data.Mode.toLowerCase()


        this.cycling = {
            enabled: data.Cycle.Enabled ?? false,
            interval: data.Cycle.Interval ?? 0,
            action: null
        };
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="accordion ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <div id='${this.id}_content'></div>
        </div>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);

        // collapse buttons
        this.element.find('.bellow .collapse').off('hide.bs.collapse').on('hide.bs.collapse', function(e) {
            var icon = $(e.target).closest('div.card').find('span.arrow-toggle');
            toggleIcon(icon, 'chevron-down', 'chevron-up');
        });
    
        this.element.find('.bellow .collapse').off('show.bs.collapse').on('show.bs.collapse', function(e) {
            var icon = $(e.target).closest('div.card').find('span.arrow-toggle');
            toggleIcon(icon, 'chevron-up', 'chevron-down');
        });

        // cycling bellows
        if (this.cycling) {
            if (this.cycling.action) {
                clearInterval(this.cycling.action)
            }

            this.cycling.action = setInterval(() => {
                var bellow = this.filterChildren((c) => {
                    if (c.active) {
                        return c;
                    }
                }, true);

                if (bellow) {
                    bellow.next.invoke();
                }
            }, this.cycling.interval);
        }
    }

    move(data, sender, opts) {
        var bellow = this.filterChildren((c) => {
            if (c.id == this.id || c.name == this.name) {
                return c;
            }
        }, true);

        if (!bellow) {
            return;
        }

        bellow.invoke();
    }
}
PodeElementFactory.setClass(PodeAccordion);

class PodeBellow extends PodeElement {
    static type = 'bellow';

    constructor(data, sender, opts) {
        super(data, sender, opts);

        if (!this.checkParentType('accordion')) {
            throw 'Bellow element can only be used in an Accordion'
        }

        this.active = true;
    }

    new(data, sender, opts) {
        var collapsed = '';
        var expanded = true;
        var show = 'show';
        var arrow = 'up';

        if ((!this.isFirstChild && this.parent.mode !== 'expanded') || this.parent.mode === 'collapsed') {
            collapsed = 'collapsed';
            show = '';
            expanded = false;
            arrow = 'down';
            this.active = false;
        }

        var icon = !data.Icon ? '' : `<span class='mdi mdi-${data.Icon.toLowerCase()}'></span>`;

        return `<div
            id='${this.id}'
            class='card bellow ${data.CssClasses}'
            style='${data.CssStyles}'
            name='${this.name}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <div class='card-header bellow-header' id='${this.id}_header'>
                    <h2 class='mb-0'>
                        <button class='btn btn-link btn-block text-left ${collapsed}' type='button' data-toggle='collapse' data-target='#${this.id}_body' aria-expanded='${expanded}' aria-controls='${this.id}_body'>
                            ${icon}
                            ${data.DisplayName}
                            <span class='mdi mdi-chevron-${arrow} arrow-toggle'></span>
                        </button>
                    </h2>
                </div>

                <div id='${this.id}_body' class='bellow-body collapse ${show}' aria-labelledby='${this.id}_header' data-parent='#${this.parent.id}'>
                    <div id='${this.id}_content' class='card-body'></div>
                </div>
        </div>`;
    }

    invoke(data, sender, opts) {
        this.get().find('div.bellow-header button').trigger('click');
        this.parent.children.forEach((c) => { c.active = false });
        this.active = true;
    }

    move(data, sender, opts) {
        this.invoke(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeBellow);

class PodeParagraph extends PodeElement {
    static type = 'paragraph';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<p
            id="${this.id}"
            class="text-${data.Alignment} ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <span id='${this.id}_content' class='pode-text'>
                    ${data.Value ? data.Value : ''}
                </span>
        </p>`;
    }
}
PodeElementFactory.setClass(PodeParagraph);

class PodeHeader extends PodeElement {
    static type = 'header';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var subHeader = data.Secondary ? `<small class='text-muted'>${data.Secondary}</small>` : '';

        return `<h${data.Size}
            id='${this.id}'
            class='${data.CssClasses}'
            style='${data.CssStyles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <span id='${this.id}_content' class='pode-text'>
                    ${data.Value}
                </span>
                ${subHeader}
        </h${data.Size}>`;
    }
}
PodeElementFactory.setClass(PodeHeader);

class PodeTextbox extends PodeFormElement {
    static type = 'textbox';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.multiline = data.Multiline ?? false;
    }

    new(data, sender, opts) {
        var html = '';

        var describedBy = data.HelpText ? `aria-describedby='${this.id}_help'` : '';
        var readOnly = this.readonly ? 'readonly' : '';
        var required = this.required ? 'required' : '';
        var autofocus = this.autofocus ? 'autofocus' : '';
        var maxLength = data.MaxLength ? `maxlength='${data.MaxLength}'` : '';
        var width = `width: ${data.Width};`;
        var events = this.events(data.Events);

        var value = '';
        if (data.Value) {
            value = this.multiline ? data.Value : `value='${data.Value}'`;
        }

        // multiline textbox
        if (this.multiline) {
            html = `<textarea
                class='form-control'
                id='${this.id}'
                name='${this.name}'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'
                placeholder='${data.Placeholder}'
                rows='${data.Size}'
                style='${width} ${data.CssStyles}'
                ${describedBy}
                ${readOnly}
                ${required}
                ${autofocus}
                ${events}
                ${maxLength}>
                    ${value}
            </textarea>`;
        }

        // single line textbox
        else {
            if (data.Prepend.Enabled || data.Append.Enabled) {
                html += `<div class='input-group mb-2'>`;
            }

            if (data.Prepend.Enabled) {
                html += data.Prepend.Text
                    ? `<div class='input-group-prepend'><div class='input-group-text'>${data.Prepend.Text}</div></div>`
                    : `<div class='input-group-prepend'><div class='input-group-text'><span class='mdi mdi-${data.Prepend.Icon.toLowerCase()}'></span></div></div>`;
            }

            data.Type = data.Type.toLowerCase();
            var inputType = data.Type === 'datatime' ? 'datetime-local' : data.Type;

            html += `<input
                type='${inputType}'
                class='form-control'
                id='${this.id}'
                name='${this.name}'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'
                style='${width} ${data.CssStyles}'
                placeholder='${data.Placeholder}'
                pode-autocomplete='${data.IsAutoComplete}'
                ${describedBy}
                ${readOnly}
                ${required}
                ${autofocus}
                ${value}
                ${events}
                ${maxLength}
            >`;

            if (data.Append.Enabled) {
                html += data.Append.Text
                    ? `<div class='input-group-append'><div class='input-group-text'>${data.Append.Text}</div></div>`
                    : `<div class='input-group-append'><div class='input-group-text'><span class='mdi mdi-${data.Append.Icon.toLowerCase()}'></span></div></div>`;
            }

            if (data.Prepend.Enabled || data.Append.Enabled) {
                html += '</div>';
            }
        }

        // preformatted
        if (data.Preformat) {
            html = `<pre>${html}</pre>`;
        }

        // dynamic label
        if (data.DynamicLabel) {
            html = `<div class='form-label-group'>
                ${html}
                <label for='${this.id}'>${data.DisplayName}</label>
            </div>`;
        }

        // return
        return html;
    }

    load(data, sender, opts) {
        this.update(data, sender, opts);
    }

    update(data, sender, opts) {
        if (!data.Value) {
            return;
        }

        if (data.AsJson) {
            data.Value = JSON.stringify(data.Value, null, 4);
        }

        if (this.multiline) {
            this.get().attr('rows', data.Size);
        }

        this.get().val(data.Value);
    }

    clear(data, sender, opts) {
        this.get().val('');
    }
}
PodeElementFactory.setClass(PodeTextbox);

class PodeFileUpload extends PodeFormElement {
    static type = 'fileupload';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<input
            type='file'
            class="form-control-file"
            id="$${this.id}"
            name="${this.name}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'
            style="${data.CssStyles}"
            accept="${data.Accept}"
            ${this.required ? 'required' : ''}
        >`;
    }
}
PodeElementFactory.setClass(PodeFileUpload);

class PodeAudio extends PodeMediaElement {
    static type = 'audio';
    static tag = 'audio';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var sources = '';
        convertToArray(data.Sources).forEach((src) => {
            sources += `<source src='${src.Url}' type='${src.Type}'>`;
        });

        var tracks = '';
        convertToArray(data.Tracks).forEach((track) => {
            tracks += `<track src='${track.Url}' kind='${track.Type}' srclang='${track.Language}' label='${track.Title}' ${track.Default ? 'default' : ''}>`;
        });

        return `<audio
            id='${this.id}'
            name='${this.name}'
            class='${data.CssClasses}'
            style="width:${data.Width};${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}"
            ${!data.NoControls ? 'controls' : ''}
            ${data.NoDownload ? "controlslist='nodownload'" : ''}
            ${data.AutoPlay ? 'autoplay' : ''}
            ${data.AutoBuffer ? 'autobuffer' : ''}
            ${data.Loop ? 'loop' : ''}
            ${data.Muted ? 'muted' : ''}
            ${this.events(data.Events)}>
                ${sources}
                ${tracks}
                ${data.NotSupportedText}
        </audio>`;
    }
}
PodeElementFactory.setClass(PodeAudio);

class PodeVideo extends PodeMediaElement {
    static type = 'video';
    static tag = 'video';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var sources = '';
        convertToArray(data.Sources).forEach((src) => {
            sources += `<source src='${src.Url}' type='${src.Type}'>`;
        });

        var tracks = '';
        convertToArray(data.Tracks).forEach((track) => {
            tracks += `<track src='${track.Url}' kind='${track.Type}' srclang='${track.Language}' label='${track.Title}' ${track.Default ? 'default' : ''}>`;
        });

        var thumbnail = data.Thumbnail ? `thumbnail='${data.Thumbnail}'` : '';

        return `<video
            id='${this.id}'
            name='${this.name}'
            class='${data.CssClasses}'
            style="width:${data.Width};height:${data.Height};${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}"
            ${!data.NoControls ? 'controls' : ''}
            ${data.NoDownload ? "controlslist='nodownload'" : ''}
            ${data.NoPictureInPicture ? 'disablepictureinpicture' : ''}
            ${data.AutoPlay ? 'autoplay' : ''}
            ${data.AutoBuffer ? 'autobuffer' : ''}
            ${data.Loop ? 'loop' : ''}
            ${data.Muted ? 'muted' : ''}
            ${thumbnail})
            ${this.events(data.Events)}>
                ${sources}
                ${tracks}
                ${data.NotSupportedText}
        </video>`;
    }

    update(data, sender, opts) {
        if (data.Thumbnail) {
            this.element.attr('thumbnail', data.Thumbnail);
        }

        super.update(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeVideo);

class PodeCodeBlock extends PodeElement {
    static type = 'codeblock';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<pre
            id="${this.id}"
            class='code-block ${data.Scrollable ? 'pre-scrollable' : ''} ${data.CssClasses}'
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <button type='button' class='btn btn-icon-only pode-code-copy' title='Copy to clipboard' data-toggle='tooltip'>
                    <span class='mdi mdi-clipboard-text-multiple-outline mdi-size-20 mRight02'></span>
                </button>

                <code class="pode-text ${data.Language}">
                    ${data.Value}
                </code>
        </pre>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;
        
        this.element.find('.pode-code-copy').off('click').on('click', function(e) {
            var value = obj.element.find('code').text().trim();
            navigator.clipboard.writeText(value);
        });
    }
}
PodeElementFactory.setClass(PodeCodeBlock);

class PodeCode extends PodeElement {
    static type = 'code';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<code
            id="${this.id}"
            class="pode-text ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                ${data.Value}
        </code>`;
    }
}
PodeElementFactory.setClass(PodeCode);

class PodeQuote extends PodeElement {
    static type = 'quote';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var footer = data.Source ? `<footer class='blockquote-footer'><cite>${data.Source}</cite></footer>` : '';

        return `<blockquote
            id='${this.id}'
            class='blockquote text-${data.Alignment} ${data.CssClasses}'
            style='${data.CssStyles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <p class='pode-text mb-0'>${data.Value}</p>
                ${footer}
        </blockquote>`;
    }
}
PodeElementFactory.setClass(PodeQuote);

class PodeIFrame extends PodeElement {
    static type = 'iframe';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<iframe
            src="${data.Url}"
            title="${data.Title}"
            id="${this.id}"
            class="${data.CssClasses}"
            style="${data.CssStyles}"
            name="${this.name}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
        </iframe>`;
    }

    update(data, sender, opts) {
        if (data.Url) {
            this.element.attr('src', data.Url);
        }

        if (data.Title) {
            this.element.attr('title', data.Title);
        }
    }
}
PodeElementFactory.setClass(PodeIFrame);

class PodeLine extends PodeElement {
    static type = 'line';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<hr
            id="${this.id}"
            class="my-4 ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>`;
    }
}
PodeElementFactory.setClass(PodeLine);

class PodeRaw extends PodeElement {
    static type = 'raw';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<span
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
            ${data.Value}
        </span>`;
    }
}
PodeElementFactory.setClass(PodeRaw);

class PodeTimer extends PodeElement {
    static type = 'timer';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.interval = data.Interval ?? 0;
    }

    new(data, sender, opts) {
        return `<span
            id="${this.id}"
            class="hide pode-timer ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
        </span>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        this.invoke();

        setInterval(() => {
            this.invoke();
        }, this.interval);
    }

    invoke(data, sender, opts) {
        sendAjaxReq(this.url, null, null, true);
    }
}
PodeElementFactory.setClass(PodeTimer);

class PodeImage extends PodeElement {
    static type = 'image';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var fluid = data.Height === 'auto' || data.Width === 'auto' ? 'img-fluid' : '';
        var title = data.Title ? `title='${data.Title}' data-toggle='tooltip' data-placement='bottom'` : '';

        var location = ({
            left: 'float-left',
            right: 'float-right',
            center: 'mx-auto d-block'
        })[data.Alignment];

        return `<img
            src='${data.Source}'
            id='${this.id}'
            class='${fluid} rounded ${location} ${data.CssClasses}'
            style='height:${data.Height};width:${data.Width};${data.CssStyles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${title}
            ${this.events(data.Events)}>`;
    }
}
PodeElementFactory.setClass(PodeImage);

class PodeComment extends PodeElement {
    static type = 'comment';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var timestamp = data.TimeStamp ? `<small class='mb-0'>${(new Date(data.TimeStamp)).toLocaleString()}</small>` : '';

        return `<div
            id="${this.id}"
            class="media ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <img src="${data.Icon}" class="align-self-start mr-3" alt="${data.Username} icon">
                <div class="media-body">
                    <div class="media-head">
                        <h5 class="mt-0">
                            ${data.Username}
                            ${timestamp}
                        </h5>
                    </div>
                    <p>${data.Message}</p>
                </div>
        </div>`;
    }
}
PodeElementFactory.setClass(PodeComment);

class PodeHero extends PodeElement {
    static type = 'hero';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var content = data.Content ? `<hr class='my-4'><div id="${this.id}_content"></div>` : '';

        return `<div
            id="${this.id}"
            class="jumbotron ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <h1 class="display-4">${data.Title}</h1>
                <p class="lead">${data.Message}</p>
                ${content}
        </div>`;
    }
}
PodeElementFactory.setClass(PodeHero);

class PodeTile extends PodeRefreshableElement {
    static type = 'tile';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.clickable = data.Click ?? false;
    }

    new(data, sender, opts) {
        var icon = data.Icon ? `<span class='mdi mdi-${data.Icon.toLowerCase()}'></span>` : '';
        var contentId = this.dynamic ? '' : `id="${this.id}_content"`;

        return `<div
            id="${this.id}"
            class="container pode-tile alert-${data.ColourType} rounded ${data.CssClasses}"
            style="${data.CssStyles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'
            name="${this.name}">
                <h6 class="pode-tile-header">
                    ${icon}
                    ${data.DisplayName}
                    ${this.buildRefreshButton(true)}
                </h6>
                <hr/>
                <div ${contentId} class="pode-tile-body pode-text"></div>
        </div>`;
    }

    load(data, sender, opts) {
        // call url for dynamic tiles
        if (this.dynamic) {
            sendAjaxReq(this.url, null, this.element, true);
        }

        // if not dynamic, and fully created, click refresh buttons of sub-elements
        else if (this.created) {
            this.element.find('.pode-tile-body .pode-refresh-btn').each((i, e) => {
                $(e).trigger('click');
            });
        }

        // hide sub-element refresh buttons
        this.element.find('.pode-tile-body .pode-refresh-btn').each((i, e) => {
            $(e).hide();
        });
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // is the tile clickable?
        if (this.clickable) {
            this.element.off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                sendAjaxReq(obj.url, null, obj.element, true);
            });
        }
    }

    update(data, sender, opts) {
        if (data.Value) {
            this.element.find('.pode-text').text(decodeHTML(data.Value));
        }

        if (data.Colour) {
            replaceClass(this.element, 'alert-\\w+', `alert-${data.ColourType}`);
        }
    }
}
PodeElementFactory.setClass(PodeTile);














class PodeNotification extends PodeElement {
    static type = 'notification';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeNotification);

class PodeCodeEditor extends PodeElement {
    static type = 'codeeditor';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeCodeEditor);

class PodeGrid extends PodeElement {
    static type = 'grid';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeGrid);

class PodeCell extends PodeElement {
    static type = 'cell';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeCell);

class PodeChart extends PodeElement {
    static type = 'chart';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeChart);

class PodeCarousel extends PodeElement {
    static type = 'carousel';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeCarousel);

class PodeSlide extends PodeElement {
    static type = 'slide';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeSlide);

class PodeTabs extends PodeElement {
    static type = 'tabs';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeTabs);

class PodeTab extends PodeElement {
    static type = 'tab';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeTab);

class PodeModal extends PodeElement {
    static type = 'modal';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeModal);

class PodeCheckbox extends PodeElement {
    static type = 'checkbox';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
    }
}
PodeElementFactory.setClass(PodeCheckbox);

// plus the ones missed