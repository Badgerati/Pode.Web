/*
TODO:
Swap "id" and "pode-id"?
- Since you can set duplicate IDs in Pode, or in Tables for example

- all Home page types will need a /content url

- Home page only has -Layouts, really needs a -ScriptBlock as well!

- Split this files into separate files
  - Use a tool to combine and minimise on build - load this minimised file in html

- A general "Out-PodeWebComponent" - to set "IsOutput" for ANY "New-" element

- Tiles need a spinner

- Clickable rows appears to be broken when calling "/content"

- no "Update-PodeWebIcon" ...

- add "-Attributes" hashtable to element New- funcs - to be able to add custom attrs to elements

- "reload()" function, to reload the HTML for an element
    - this would recall new(), load(), then bind() - basically the same as creation
    - everything would have to be stored as "this." in the constructor - no "data.", so we can dynamically reload

- "updateTheme()" function which is called when the theme is updated
    - this should hopefully let us update the page's theme without reloading the page
    - like charts for example

- some buttons need disabling once clicked - to prevent double-clicks
    - like forms, steppers, buttons, etc.

- there is a lot of ".off().on()" for events - can we centralise this somehow?
*/

const PODE_CONTENT = $('content#pode-content');
const PODE_BREADCRUMB = $('nav#pode-breadcrumb ol.breadcrumb');
const PODE_NAVIGATION = $('div#pode-nav-items ul.navbar-nav');

class PodeElementFactory {
    static classMap = new Map();
    static objMap = new Map();

    constructor() {}

    static setClass(clazz) {
        this.classMap.set(clazz.type.toLowerCase(), clazz);
    }

    static getClass(name) {
        return this.classMap.get(name);
    }

    static getBreadcrumb() {
        var id = PODE_BREADCRUMB.attr('for');
        if (!id) {
            var data = {
                ObjectType: 'breadcrumb',
                Items: []
            };

            var opts = {
                isCustom: false
            };

            var result = PodeElementFactory.invokeClass('breadcrumb', 'new', data, undefined, opts)
            id = result.element.uuid;
        }

        return this.getObject(id);
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
    static type = 'element';
    static tag = '';

    constructor(data, sender, opts) {
        opts.child = opts.child ?? {};

        this.id = PodeElement.makeId(data, opts);
        this.name = data.Name ?? '';
        this.uuid = generateUuid();
        this.created = false;
        this.loading = false;
        this.ephemeral = false;
        this.dynamic = data.IsDynamic ?? false;
        this.autoRender = opts.autoRender ?? true;
        this.contentProperty = null;
        this.isOutput = data.AsOutput ?? false;
        this.element = null;
        this.icon = null;
        this.url = `/components/${this.getType()}/${data.ID}`;
        this.disabled = data.Disabled ?? false;

        this.parent = null;
        this.children = [];
        this.child = {
            isFirst: false,
            isLast: false,
            index: 0,
            next: null,
            previous: null
        };

        this.css = {
            classes: data.CssClasses ?? '',
            styles: data.CssStyles ?? ''
        };

        this.setParent(opts.parent, data, sender, opts);
        PodeElementFactory.setObject(this.uuid, this);
    }

    setParent(element, data, sender, opts) {
        if (!element) {
            return;
        }

        this.parent = element;
        this.parent.addChild(this, data, sender, opts);
    }

    addChild(element, data, sender, opts) {
        if (!element) {
            return;
        }

        // set element child index and first/last
        element.child = {
            index: this.children.length,
            isFirst: this.children.length === 0,
            isLast: opts.child && opts.child.isLast ? opts.child.isLast() : true
        };

        // set the previous child to not the last child, and set next/previous properties
        if (this.children.length > 0) {
            // set previous to not last
            var prev = this.children[this.children.length - 1];
            prev.child.isLast = false;

            // prev/next link
            prev.child.next = element;
            element.child.previous = prev;

            // prev/next wrapper link for first/last children
            element.child.next = this.children[0];
            this.children[0].child.previous = element;
        }

        // add child
        this.children.push(element);
    }

    setIcon(name, padRight, padTop) {
        if (!name) {
            return '';
        }

        var result = this.build('icon', {
            ID: `${this.id}_icon`,
            Name: name,
            CssClasses: `${padRight ? 'mRight02' : ''} ${padTop ? 'mTop-02' : ''}`
        }, null, null);

        this.icon = result.elements[0];
        return result.html;
    }

    refresh(action, force) {
        if ((action === 'new' || !this.created) && !force) {
            return this;
        }

        this.element = this.get();
        this.created = true;
        return this;
    }

    applyGeneral(action, subType, data, sender, opts) {
        switch (subType) {
            case 'style':
                switch (action) {
                    case 'set':
                        this.setStyle(data, sender, opts);
                        break;

                    case 'remove':
                        this.removeStyle(data, sender, opts);
                        break;
                }
                break;

            case 'class':
                switch (action) {
                    case 'add':
                        this.addClass(data, sender, opts);
                        break;

                    case 'remove':
                        this.removeClass(data, sender, opts);
                        break;
                }
                break;

            case 'validation':
                switch (action) {
                    case 'output':
                        this.showValidation(data, sender, opts);
                        break;
                }
                break;
        }

        return null;
    }

    apply(action, data, sender, opts) {
        console.log(`[${action}] ${this.getType()} {${opts.subType ?? ''}}`);

        // is this a base element action - applies to all
        if (opts.subType && opts.type === 'element') {
            return this.applyGeneral(action, opts.subType, data, sender, opts);
        }

        // invoke action
        switch (action) {
            case 'new':
                var html = opts.html ? opts.html : this.new(data, sender, opts);
                this.finalise(html, data, sender, false, opts);
                break;

            case 'update':
                this.spinner(true);
                this.update(data, sender, opts);
                break;

            case 'reset':
                this.reset(data, sender, opts);
                break;

            case 'submit':
                this.spinner(true);
                this.submit(data, sender, opts);
                break;

            case 'invoke':
                this.spinner(true);
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

            case 'restart':
                this.restart(data, sender, opts);
                break;

            case 'sync':
                this.spinner(true);
                this.sync(data, sender, opts);
                break;

            case 'set':
                this.set(data, sender, opts);
                break;

            case 'add':
                this.add(data, sender, opts);
                break;

            case 'remove':
                this.remove(data, sender, opts);
                break;
        }

        if (this.ephemeral) {
            PodeElementFactory.removeObject(this.uuid);
        }

        this.spinner(false);
        opts.html = null;
        return html;
    }

    finalise(html, data, sender, force, opts) {
        if ((!this.autoRender || !sender) && !force) {
            return;
        }

        data = data ?? {};
        if (html && sender) {
            this.isOutput ? sender.after(html) : sender.append(html);
        }

        // render content, load and bind this element
        this.element = this.get();
        this.renderContentArea(data);
        this.load(data, sender, opts);
        this.bind(data, sender, opts);
        this.created = true;

        // finalise non-created children
        if (this.icon) {
            this.icon.finalise(null, null, null, true, null);
        }

        if (this.children && this.children.length > 0) {
            this.children.forEach((c) => {
                if (c.created) {
                    return;
                }

                c.finalise(null, null, null, true, null);
            });
        }
    }

    build(name, data, opts, parent) {
        if (!name || !data) {
            return null;
        }

        opts = opts ?? {};
        opts.autoRender = false;

        data.ObjectType = name;
        parent = parent === undefined ? this : opts.parent;

        return this.render(data, null, parent, opts);
    }

    renderContentArea(data, opts) {
        if (!data) {
            return;
        }

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
            if (sender && sender.length > 1) {
                sender = this.filter(sender, (item) => {
                    if (item.attr('pode-min-index') <= index && item.attr('pode-max-index') >= index) {
                        return item;
                    }
                }, true);
            }

            opts.child = {
                isLast: () => { return index == content.length - 1; }
            };

            var result = PodeElementFactory.invokeClass(item.ObjectType, 'new', item, sender, opts);
            created.push(result.element);

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
        if (!show && this.loading) {
            return;
        }

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
            if (!this.tag && this.type && this.type !== 'element') {
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

    filter(elements, func, firstOnly) {
        if (!elements || !func) {
            return null;
        }

        var result = elements.filter(func);
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
        return $(document).find(`[pode-content-for='${this.uuid}']`);


        // var element = this.get();
        // var id = this.id ?? this.uuid;

        // //TODO: this would be better as just "uuid" - then we can find the content anywhere on the page
        // //      - for scenarios where they're not embedded - like nav-dropdown
        // var area = element.find(`[pode-content-for='${id}']`);
        // if ((!area || area.length === 0) && element.attr('pode-content-for') === (id)) {
        //     area = element;
        // }

        // return area;
    }

    html() {
        return this.get()[0].outerHTML;
    }

    setReadonly(enabled) {
        if (!this.element) {
            return;
        }

        this.element.prop('readonly', enabled);
        this.children.forEach((child) => { child.setReadonly(enabled); });
    }

    setRequired(enabled) {
        if (!this.element) {
            return;
        }

        this.element.prop('required', enabled);
        this.children.forEach((child) => { child.setRequired(enabled); });
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
        if (!this.element) {
            return;
        }

        enable(this.element);
        this.children.forEach((child) => { child.enable(data, sender, opts); });
    }

    disable(data, sender, opts) {
        if (!this.element) {
            return;
        }

        disable(this.element);
        this.children.forEach((child) => { child.disable(data, sender, opts); });
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

    setStyle(data, sender, opts) {
        this.element[0].style.setProperty(data.Property, data.Value, 'important');
    }

    removeStyle(data, sender, opts) {
        this.element[0].style.setProperty(data.Property, null);
    }

    addClass(data, sender, opts) {
        this.element.addClass(data.Class);
    }

    removeClass(data, sender, opts) {
        this.element.removeClass(data.Class);
    }

    showValidation(data, sender, opts) {
        $(document).find(`[pode-validation-for='${this.uuid}']`).text(decodeHTML(data.Message));
        setValidationError(this.element);
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

    restart(data, sender, opts) {
        throw `${this.getType()} "restart" method not implemented`
    }

    set(data, sender, opts) {
        throw `${this.getType()} "set" method not implemented`
    }

    add(data, sender, opts) {
        throw `${this.getType()} "add" method not implemented`
    }

    remove(data, sender, opts) {
        throw `${this.getType()} "remove" method not implemented`
    }

    bind(data, sender, opts) {
        if (!this.element) {
            return;
        }

        this.element.find('[data-toggle="tooltip"]').tooltip();
    }

    load(data, sender, opts) {
        if (this.disabled) {
            this.disable(data, sender, opts);
        }

        this.spinner(true);
    }
}

class PodeContentElement extends PodeElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
    }

    apply(action, data, sender, opts) {
        sender = sender === undefined ? PODE_CONTENT : sender;
        return super.apply(action, data, sender, opts);
    }
}

class PodeBreadcrumbElement extends PodeElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
    }

    apply(action, data, sender, opts) {
        sender = sender === undefined ? PODE_BREADCRUMB : sender;
        return super.apply(action, data, sender, opts);
    }
}

class PodeNavElement extends PodeElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
    }

    apply(action, data, sender, opts) {
        sender = sender === undefined ? PODE_NAVIGATION : sender;
        return super.apply(action, data, sender, opts);
    }
}

class PodeTextualElement extends PodeContentElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.textual = true;
    }

    update(data, sender, opts) {
        if (this.textual && data.Value) {
            if (this.element.hasClass('pode-text')) {
                this.element.text(decodeHTML(data.Value));
            }
            else {
                this.element.find('.pode-text').text(decodeHTML(data.Value));
            }
        }
    }
}

class PodeCyclingElement extends PodeContentElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);

        this.cycling = {
            enabled: data.Cycle ? (data.Cycle.Enabled ?? false) : false,
            interval: data.Cycle ? (data.Cycle.Interval ?? 0) : 0,
            action: null
        };
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);

        if (this.cycling.enabled) {
            if (this.cycling.action) {
                clearInterval(this.cycling.action)
            }

            this.cycling.action = setInterval(() => {
                var obj = this.filter(this.children, (c) => {
                    if (c.active) {
                        return c;
                    }
                }, true);

                if (obj) {
                    obj.child.next.invoke();
                }
            }, this.cycling.interval);
        }
    }

    move(data, sender, opts) {
        var child = this.filter(this.children, (c) => {
            if (c.id == this.id || c.name == this.name) {
                return c;
            }
        }, true);

        if (child) {
            child.invoke();
        }
    }
}

class PodeCyclingChildElement extends PodeContentElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.active = this.child.isFirst;
    }

    invoke(data, sender, opts) {
        this.parent.children.forEach((c) => { c.active = false });
        this.active = true;
    }

    move(data, sender, opts) {
        this.invoke(data, sender, opts);
    }
}

class PodeRefreshableElement extends PodeTextualElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.refreshable = {
            enabled: !(data.NoRefresh ?? false)
        };

        this.autoRefresh = {
            enabled: data.AutoRefresh ?? false,
            interval: data.RefreshInterval ?? 0
        };
    }

    buildRefreshButton(asSpan) {
        if (this.autoRefresh.enabled || !this.refreshable.enabled) {
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

class PodeFormElement extends PodeContentElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        opts.help = opts.help ?? {};

        this.readonly = data.ReadOnly ?? false;
        this.required = data.Required ?? false;
        this.autofocus = data.AutoFocus ?? false;
        this.dynamicLabel = data.DynamicLabel ?? false;
        this.validation = opts.validation ?? true;
        this.width = data.Width ?? '';
        this.label = {
            enabled: opts.label ?? true,
            asLegend: false
        };
        this.asFieldset = false;
        this.help = {
            enabled: opts.help.enabled ?? (data.HelpText != null),
            text: opts.help.text ?? data.HelpText,
            id: opts.help.id ?? this.id
        };
        this.inForm = this.checkParentType('form');
    }

    apply(action, data, sender, opts) {
        // render the form element
        switch (action) {
            case 'new':
                var html = this.new(data, sender, opts);

                // help text
                if (this.help.enabled && this.help.text) {
                    html += `<small id='${this.help.id}_help' class='form-text text-muted'>${this.help.text}</small>`;
                }

                // validation
                if (this.validation) {
                    html += `<div pode-validation-for="${this.uuid}" class="invalid-feedback validation"></div>`;
                }

                // are we in a form?
                if (this.inForm && !this.dynamicLabel) {
                    html = `<div class='col-sm-10'>${html}</div>`;
                }

                if (this.label.enabled && this.inForm && !this.dynamicLabel) {
                    var lblTag = this.label.asLegend ? 'legend' : 'label';

                    html = `<${lblTag}
                        for='${this.id}'
                        class='col-sm-2 col-form-label ${this.label.asLegend ? 'float-sm-left pt-0' : '' }'>
                            ${data.DisplayName}
                    </${lblTag}>
                    ${html}`;
                }

                if (!(this.parent instanceof PodeFormElement)) {
                    var formGroup = !this.inForm || this.dynamicLabel ? 'd-inline-block' : `form-group row`;
                    var divTag = this.asFieldset ? 'fieldset' : 'div';
                    var idProps = this.asFieldset ? `id='${this.id}' pode-object='${this.getType()}' pode-id='${this.uuid}'` : '';
                    var events = this.asFieldset ? this.events(data.Events) : '';
                    var width = this.inForm || !this.width ? '' : `width:${this.width}`;

                    html = `<${divTag}
                        class='pode-form-${this.getType()} ${formGroup} ${this.css.classes}'
                        style='${width}'
                        ${idProps}
                        ${events}>
                            ${html}
                    </${divTag}>`;
                }

                // overload html from super
                opts.html = html;
                break;
        }

        return super.apply(action, data, sender, opts);
    }

    load(data, sender, opts) {
        super.load(data, sender, opts);

        if (this.readonly) {
            this.setReadonly(true);
        }

        if (this.required) {
            this.setRequired(true);
        }

        if (this.help.enabled) {
            this.element.attr('aria-describedby', `${this.help.id}_help`);
        }
    }

    update(data, sender, opts) {
        // disable / enable control
        if (data.DisabledState) {
            switch (data.DisabledState.toLowerCase()) {
                case 'enabled':
                    this.disabled = false;
                    this.enable(data, sender, opts);
                    break;

                case 'disabled':
                    this.disabled = true;
                    this.disable(data, sender, opts);
                    break;
            }
        }

        // readonly state
        if (data.ReadOnlyState) {
            switch (data.ReadOnlyState.toLowerCase()) {
                case 'enabled':
                    this.readonly = true;
                    this.setReadonly(true);
                    break;

                case 'disabled':
                    this.readonly = false;
                    this.setReadonly(false);
                    break;
            }
        }

        // required state
        if (data.RequiredState) {
            switch (data.RequiredState.toLowerCase()) {
                case 'enabled':
                    this.required = true;
                    this.setRequired(true);
                    break;

                case 'disabled':
                    this.readonly = false;
                    this.setRequired(false);
                    break;
            }
        }
    }
}

class PodeFormMultiElement extends PodeFormElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.formElements = [];
    }

    addFormElement(element) {
        if (!element) {
            return;
        }

        this.formElements.push(element.html ?? element);
    }

    new(data, sender, opts) {
        var colSize = Math.floor(12 / this.formElements.length);

        var html = '';
        this.formElements.forEach((e) => {
            html += `<div class='form-group col-md-${colSize}'>${e}</div>`;
        });
        this.formElements = [];

        return `<div
            id='${this.id}'
            name='${this.name}'
            class='form-row ${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${this.events(data.Events)}>
                ${html}
        </div>`;
    }
}

class PodeMediaElement extends PodeContentElement {
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

class PodeBadge extends PodeTextualElement {
    static type = 'badge';
    static tag = 'span';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<span
            id='${this.id}'
            class='badge badge-${data.ColourType} pode-text ${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${this.events(data.Events)}>
                ${data.Value}
        </span>`;
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // change colour
        if (data.Colour) {
            replaceClass(this.element, 'badge-\\w+', `badge-${data.ColourType}`);
        }
    }
}
PodeElementFactory.setClass(PodeBadge);

class PodeText extends PodeTextualElement {
    static type = 'text';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var html = `<span
            id='${this.id}'
            class='pode-text ${this.css.classes}'
            style='${this.css.styles}'
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
}
PodeElementFactory.setClass(PodeText);

class PodeSpinner extends PodeContentElement {
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
            class="spinner-border spinner-border-sm ${this.css.classes}"
            style="${colour} ${this.css.styles}"
            role="status"
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            role='status'
            ${title}>
        </span>`;
    }
}
PodeElementFactory.setClass(PodeSpinner);

class PodeLink extends PodeTextualElement {
    static type = 'link';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<a
            href='${data.Source}'
            id='${this.id}'
            class="pode-text ${this.css.classes}"
            style="${this.css.styles}"
            target='${data.NewTab ? '_blank' : '_self'}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${this.events(data.Events)}>
                ${data.Value}
        </a>`;
    }
}
PodeElementFactory.setClass(PodeLink);

class PodeIcon extends PodeContentElement {
    static type = 'icon';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.setName(this.name);
        this.title = data.Title ?? '';
    }

    getName() {
        return this.name.startsWith('mdi-') ? this.name : `mdi-${this.name}`;
    }

    setName(name) {
        if (name) {
            name = name.toLowerCase();
            this.name = name.startsWith('mdi-') ? name : `mdi-${name}`;
        }
    }

    new(data, sender, opts) {
        var colour = data.Colour ? `color:${data.Colour};` : '';
        var title = this.title ? `title='${this.title}' data-toggle='tooltip'` : '';
        var size = data.Size ? `mdi-size-${data.Size}` : '';

        var spin = data.Spin ? 'mdi-spin' : '';
        var flip = data.Flip ? `mdi-flip-${data.Flip[0]}`.toLowerCase() : '';
        var rotate = data.Rotate > 0 ? `mdi-rotate-${data.Rotate}` : '';

        return `<span
            id='${this.id}'
            class='mdi ${this.getName()} ${size} ${spin} ${flip} ${rotate} ${this.css.classes}'
            style='${colour} ${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${title}
            ${this.events(data.Events)}>
        </span>`;
    }

    replace(name, title) {
        if (!name) {
            return;
        }

        // replace
        name = name.toLowerCase();
        name = name.startsWith('mdi-') ? name : `mdi-${name}`;

        if (this.getName() !== name) {
            replaceClass(this.element, this.getName(), name);
            this.setName(name);
        }

        // replace title
        if (title) {
            setTitle(this.element, title);
            this.title = title;
        }
    }

    //TODO: toggle function to help with toggling between two icon?
    //          - plus a '-ToggleIcon' and title on New-PodeWebIcon ?
    //          - possible even a '-HoverIcon'
}
PodeElementFactory.setClass(PodeIcon);

class PodeButton extends PodeFormElement {
    static type = 'button';

    //TODO: New-PodeWebButtonGroup needed -- horizontal and vertical support
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.iconOnly =  data.IconOnly;
        this.validation = false;
        this.label.enabled = false;
    }

    new(data, sender, opts) {
        var newLine = data.NewLine ? '<br/>' : '';

        var icon = this.setIcon(data.Icon, true);
        var html = '';

        if (this.iconOnly) {
            if (this.dynamic) {
                html = `<button
                    type='button'
                    class='btn btn-icon-only pode-button ${this.css.classes}'
                    style='${this.css.styles}'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    title='${data.DisplayName}'
                    data-toggle='tooltip'
                    pode-object='${this.getType()}'
                    pode-id='${this.uuid}'>
                        ${icon}
                </button>`;
            }
            else {
                html = `<a
                    role='button'
                    class='btn btn-icon-only pode-link-button ${this.css.classes}'
                    style='${this.css.styles}'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    title='${data.DisplayName}'
                    href='${data.Url}'
                    target='${data.NewTab ? '_blank' : '_self'}'
                    data-toggle='tooltip'
                    pode-object='${this.getType()}'
                    pode-id='${this.uuid}'>
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
                    class='btn btn-${colour} ${data.SizeType} pode-button ${this.css.classes}'
                    style='${this.css.styles}'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    pode-object='${this.getType()}'
                    pode-colour='${data.ColourType}'
                    pode-id='${this.uuid}'>
                        <span class='spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
                        ${icon}
                        <span class='pode-text'>${data.DisplayName}</span>
                </button>`;
            }
            else {
                html = `<a
                    role='button'
                    class='btn btn-${colour} ${data.SizeType} pode-link-button ${this.css.classes}'
                    style='${this.css.styles}'
                    id='${this.id}'
                    name='${this.name}'
                    href='${data.Url}'
                    target='${data.NewTab ? '_blank' : '_self'}'
                    pode-data-value='${data.DataValue}'
                    pode-object='${this.getType()}'
                    pode-colour='${data.ColourType}'
                    pode-id='${this.uuid}'>
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
        super.update(data, sender, opts);

        // update icon
        if (data.Icon) {
            replaceClass(this.element.find('span.mdi'), 'mdi-\\w+', `mdi-${data.Icon.toLowerCase()}`);
        }

        // update display name
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

class PodeContainer extends PodeContentElement {
    static type = 'container';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="container pode-container ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-transparent="${data.NoBackground}"
            pode-hidden="${data.Hide}"
            pode-id='${this.uuid}'>
                <div pode-content-for='${this.uuid}'></div>
        </div>`;
    }
}
PodeElementFactory.setClass(PodeContainer);

class PodeForm extends PodeContentElement {
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
            class="pode-form ${this.css.classes}"
            style="${this.css.styles}"
            method="${this.method}"
            action="${this.action}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <div pode-content-for='${this.uuid}'></div>

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

class PodeNotification extends PodeElement {
    static type = 'notification';

    constructor(...args) {
        super(...args);
        this.ephemeral = true;
    }

    show(data, sender, opts) {
        if (!window.Notification) {
            return;
        }

        var display = () => {
            new Notification(data.Title, {
                body: data.Body,
                icon: data.Icon
            });
        };

        if (Notification.permission === 'granted') {
            display();
        }
        else if (Notification.permission !== 'denied') {
            Notification.requestPermission().then(function(p) {
                if (p === 'granted') {
                    display();
                }
            });
        }
    }
}
PodeElementFactory.setClass(PodeNotification);

class PodeCard extends PodeContentElement {
    static type = 'card';

    constructor(...args) {
        super(...args);
    }

    //TODO: allow for "data.Buttons" -- which adds custom buttons to the card header
    new(data, sender, opts) {
        var header = '';
        if ((!data.NoTitle && this.name) || !data.NoHide) {
            var icon = this.setIcon(data.Icon, true);

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
            class="card pode-card ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                ${header}
                <div pode-content-for='${this.uuid}' class="card-body"></div>
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

class PodeAlert extends PodeTextualElement {
    static type = 'alert';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="alert alert-${data.ClassType} ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'
            role="alert"
            ${this.events(data.Events)}>
                <h6 class='pode-alert-header'>
                    <span class="mdi mdi-${data.IconType.toLowerCase()}"></span>
                    <strong>${data.Type}</strong>
                </h6>
                <div pode-content-for='${this.uuid}' class='pode-alert-body pode-text'>
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
        this.textual = false;
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
                <span class='mdi mdi-${btn.Icon.toLowerCase()} mdi-size-20 ${btn.WithText ? "mRight02" : ''}'></span>
                ${btn.WithText ? btn.DisplayName : ''}
            </button>`;
        });

        return `${msg}<div
            id='${this.id}'
            name='${this.name}'
            class="${this.css.classes}"
            style='${this.css.styles}'
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

        super.load(data, sender, opts);

        // show spinner
        opts = opts ?? {};
        this.element.find('table tbody').empty();

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

        // invoke and load table content
        sendAjaxReq(url, query, this.element, true, () => { this.loading = false; }, { successCallbackBefore: true });
        this.loading = true;
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
        super.update(data, sender, opts);

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

class PodeAccordion extends PodeCyclingElement {
    static type = 'accordion';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.contentProperty = 'Bellows'
        this.mode = data.Mode.toLowerCase()
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="accordion ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <div pode-content-for='${this.uuid}'></div>
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
    }
}
PodeElementFactory.setClass(PodeAccordion);

class PodeBellow extends PodeCyclingChildElement {
    static type = 'bellow';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.active = true;

        if (!this.checkParentType('accordion')) {
            throw 'Bellow element can only be used in an Accordion'
        }
    }

    new(data, sender, opts) {
        var collapsed = '';
        var expanded = true;
        var show = 'show';
        var arrow = 'up';

        if ((!this.child.isFirst && this.parent.mode !== 'expanded') || this.parent.mode === 'collapsed') {
            collapsed = 'collapsed';
            show = '';
            expanded = false;
            arrow = 'down';
            this.active = false;
        }

        var icon = this.setIcon(data.Icon);

        return `<div
            id='${this.id}'
            class='card bellow ${this.css.classes}'
            style='${this.css.styles}'
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
                    <div pode-content-for='${this.uuid}' class='card-body'></div>
                </div>
        </div>`;
    }

    invoke(data, sender, opts) {
        this.get().find('div.bellow-header button').trigger('click');
        super.invoke(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeBellow);

class PodeParagraph extends PodeTextualElement {
    static type = 'paragraph';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<p
            id="${this.id}"
            class="text-${data.Alignment} ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <span pode-content-for='${this.uuid}' class='pode-text'>
                    ${data.Value ? data.Value : ''}
                </span>
        </p>`;
    }
}
PodeElementFactory.setClass(PodeParagraph);

class PodeHeader extends PodeTextualElement {
    static type = 'header';

    constructor(...args) {
        super(...args);
    }

    //TODO: add icon support
    new(data, sender, opts) {
        var subHeader = data.Secondary ? `<small class='text-muted'>${data.Secondary}</small>` : '';

        return `<h${data.Size}
            id='${this.id}'
            class='${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <span pode-content-for='${this.uuid}' class='pode-text'>
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
        this.autoComplete = data.IsAutoComplete ?? false;
    }

    new(data, sender, opts) {
        data.Prepend = data.Prepend ?? {};
        data.Append = data.Append ?? {};

        var html = '';

        var autofocus = this.autofocus ? 'autofocus' : '';
        var maxLength = data.MaxLength ? `maxlength='${data.MaxLength}'` : '';
        var width = `width:${this.width};`;
        var placeholder = data.Placeholder ? `placeholder='${data.Placeholder}'` : '';
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
                rows='${data.Size}'
                style='${width} ${this.css.styles}'
                ${placeholder}
                ${autofocus}
                ${events}
                ${maxLength}>${value}</textarea>`;
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
            var inputType = data.Type === 'datetime' ? 'datetime-local' : data.Type;

            html += `<input
                type='${inputType}'
                class='form-control'
                id='${this.id}'
                name='${this.name}'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'
                style='${width} ${this.css.styles}'
                placeholder='${data.Placeholder ?? ''}'
                ${autofocus}
                ${value}
                ${events}
                ${maxLength}>`;

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
        super.load(data, sender, opts);
        this.update(data, sender, opts);
        var obj = this;

        if (this.autoComplete) {
            sendAjaxReq(`${this.url}/autocomplete`, null, null, false, (res) => {
                obj.element.autocomplete({ source: res.Values });
            });
        }
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // update value
        if (data.Value) {
            if (data.AsJson) {
                data.Value = JSON.stringify(data.Value, null, 4);
            }
        
            this.get().val(data.Value);
        }

        // resize textbox rows
        if (this.multiline && data.Size) {
            this.get().attr('rows', data.Size);
        }
    }

    clear(data, sender, opts) {
        this.get().val('');
    }
}
PodeElementFactory.setClass(PodeTextbox);

class PodeFileUpload extends PodeFormElement {
    static type = 'file-upload';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<div class='custom-file'>
            <input
                type='file'
                class="custom-file-input"
                id="$${this.id}"
                name="${this.name}"
                pode-object="${this.getType()}"
                pode-id='${this.uuid}'
                style="${this.css.styles}"
                accept="${data.Accept}">
            <label class='custom-file-label' for='${this.id}'>Choose file</label>
        </div>`;
    }

    bind(data, sender, opts) {
        this.element.off('change').on('change', function() {
            var fileName = $(this).val().split("\\").pop();
            $(this).siblings('.custom-file-label').addClass('selected').html(fileName);
        });
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
            class='${this.css.classes}'
            style="width:${data.Width};${this.css.styles}"
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
            class='${this.css.classes}'
            style="width:${data.Width};height:${data.Height};${this.css.styles}"
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

class PodeCodeBlock extends PodeTextualElement {
    static type = 'codeblock';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<pre
            id="${this.id}"
            class='code-block ${data.Scrollable ? 'pre-scrollable' : ''} ${this.css.classes}'
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <button type='button' class='btn btn-icon-only pode-code-copy' title='Copy to clipboard' data-toggle='tooltip'>
                    <span class='mdi mdi-clipboard-text-multiple-outline mdi-size-20 mRight02'></span>
                </button>

                <code class="${data.Language} pode-text">
                    ${data.Value}
                </code>
        </pre>`;
    }

    load(data, sender, opts) {
        super.load(data, sender, opts);
        hljs.highlightElement(this.element.find('code')[0]);
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;
        
        this.element.find('.pode-code-copy').off('click').on('click', function(e) {
            obj.tooltip(false, $(this));
            var value = obj.element.find('code').text().trim();
            navigator.clipboard.writeText(value);
        });
    }
}
PodeElementFactory.setClass(PodeCodeBlock);

class PodeCode extends PodeTextualElement {
    static type = 'code';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<code
            id="${this.id}"
            class="pode-text ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                ${data.Value}
        </code>`;
    }
}
PodeElementFactory.setClass(PodeCode);

class PodeQuote extends PodeTextualElement {
    static type = 'quote';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var footer = data.Source ? `<footer class='blockquote-footer'><cite>${data.Source}</cite></footer>` : '';

        return `<blockquote
            id='${this.id}'
            class='blockquote text-${data.Alignment} ${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <p class='pode-text mb-0'>${data.Value}</p>
                ${footer}
        </blockquote>`;
    }
}
PodeElementFactory.setClass(PodeQuote);

class PodeIFrame extends PodeContentElement {
    static type = 'iframe';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<iframe
            src="${data.Url}"
            title="${data.Title}"
            id="${this.id}"
            class="${this.css.classes}"
            style="${this.css.styles}"
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

class PodeLine extends PodeContentElement {
    static type = 'line';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<hr
            id="${this.id}"
            class="my-4 ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>`;
    }
}
PodeElementFactory.setClass(PodeLine);

class PodeRaw extends PodeContentElement {
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

class PodeTimer extends PodeContentElement {
    static type = 'timer';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.interval = data.Interval ?? 0;
    }

    new(data, sender, opts) {
        return `<span
            id="${this.id}"
            class="hide pode-timer ${this.css.classes}"
            style="${this.css.styles}"
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

class PodeImage extends PodeContentElement {
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
            class='${fluid} rounded ${location} ${this.css.classes}'
            style='height:${data.Height};width:${data.Width};${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${title}
            ${this.events(data.Events)}>`;
    }
}
PodeElementFactory.setClass(PodeImage);

class PodeComment extends PodeContentElement {
    static type = 'comment';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var timestamp = data.TimeStamp ? `<small class='mb-0'>${(new Date(data.TimeStamp)).toLocaleString()}</small>` : '';

        return `<div
            id="${this.id}"
            class="media ${this.css.classes}"
            style="${this.css.styles}"
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

class PodeHero extends PodeContentElement {
    static type = 'hero';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var content = data.Content ? `<hr class='my-4'><div pode-content-for='${this.uuid}'></div>` : '';

        return `<div
            id="${this.id}"
            class="jumbotron ${this.css.classes}"
            style="${this.css.styles}"
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
        var icon = this.setIcon(data.Icon);
        var contentId = this.dynamic ? '' : `pode-content-for='${this.uuid}'`;

        return `<div
            id="${this.id}"
            class="container pode-tile alert-${data.ColourType} rounded ${this.css.classes}"
            style="${this.css.styles}"
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
        super.load(data, sender, opts);

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
        super.update(data, sender, opts);

        if (data.Colour) {
            replaceClass(this.element, 'alert-\\w+', `alert-${data.ColourType}`);
        }
    }
}
PodeElementFactory.setClass(PodeTile);

class PodeGrid extends PodeContentElement {
    static type = 'grid';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.contentProperty = 'Cells';
        this.width = data.Width ?? 0;
        this.rows = this.width == 0 ? 1 : Math.ceil(convertToArray(data.Cells).length);
    }

    new(data, sender, opts) {
        var rows = '';
        for (var i = 1; i <= this.rows; i++) {
            rows += `<div pode-content-for='${this.uuid}' pode-min-index='${this.width * (i - 1)}' pode-max-index='${(this.width * i) - 1}' class='row'></div>`;
        }

        return `<div
            id="${this.id}"
            class="container pode-grid ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                ${rows}
        </div>`;
    }
}
PodeElementFactory.setClass(PodeGrid);

class PodeCell extends PodeContentElement {
    static type = 'cell';

    constructor(data, sender, opts) {
        super(data, sender, opts);

        if (!this.checkParentType('grid')) {
            throw 'Cell element can only be used in a Grid'
        }
    }

    new(data, sender, opts) {
        var html = '';

        // build cell
        var width = data.Width ? `col-${data.Width}` : 'col';

        html += `<div
            id='${this.id}'
            class='text-${data.Alignment} ${width} ${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <div pode-content-for='${this.uuid}'></div>
        </div>`;

        // render dummy cells if last child before grid width
        if ((this.parent.width > 0) && (this.child.index % this.parent.width !== this.parent.width - 1) && this.child.isLast) {
            for (var i = this.child.index; i < this.parent.width - 1; i++) {
                html += `<div class='${width}'></div>`;
            }
        }

        return html;
    }
}
PodeElementFactory.setClass(PodeCell);

class PodeTabs extends PodeCyclingElement {
    static type = 'tabs';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.contentProperty = 'Tabs';
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <ul class="nav nav-tabs" role="tablist"></ul>
                <div class='tab-content' pode-content-for='${this.uuid}'></div>
        </div>`;
    }

    addChild(element, data, sender, opts) {
        super.addChild(element, data, sender, opts);

        // add new tab selector
        if (element.getType() !== 'tab') {
            return;
        }

        var icon = element.setIcon(data.Icon, true);

        var html = `<li class='nav-item' role='presentation'>
            <a
                id='${element.id}'
                name='${element.name}'
                class='nav-link ${element.child.isFirst ? 'active' : ''}'
                data-toggle='tab'
                href='#${element.id}_content'
                role='tab'
                aria-controls='${element.id}_content'
                aria-selected='${element.child.isFirst}'>
                ${icon}
                ${data.DisplayName}
            </a>
        </li>`;

        this.element.find('ul[role="tablist"]').append(html);
    }
}
PodeElementFactory.setClass(PodeTabs);

class PodeTab extends PodeCyclingChildElement {
    static type = 'tab';

    constructor(data, sender, opts) {
        super(data, sender, opts);

        if (!this.checkParentType('tabs')) {
            throw 'Tab element can only be used in Tabs'
        }
    }

    new(data, sender, opts) {
        return `<div
            id='${this.id}_content'
            class='tab-pane fade show ${this.child.isFirst ? 'active' : ''} ${this.css.classes}'
            style='${this.css.styles}'
            pode-object="${this.getType()}"
            pode-id="${this.uuid}"
            role='tabpanel'
            aria-labelledby='${this.id}'>
                <div pode-content-for='${this.uuid}'></div>
        </div>`;
    }

    invoke(data, sender, opts) {
        this.parent.element.find(`.nav-link#${this.id}`).trigger('click');
        super.invoke(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeTab);

class PodeCarousel extends PodeCyclingElement {
    static type = 'carousel';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.contentProperty = 'Slides';
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="carousel slide ${this.css.classes}"
            style="${this.css.styles}"
            data-ride="carousel"
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <ol class="carousel-indicators"></ol>
                <div class="carousel-inner" pode-content-for='${this.uuid}'></div>

                <a class="carousel-control-prev carousel-arrow" href="#${this.id}" role="button" data-slide="prev">
                    <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                    <span class="sr-only">Previous</span>
                </a>
                <a class="carousel-control-next carousel-arrow" href="#${this.id}" role="button" data-slide="next">
                    <span class="carousel-control-next-icon" aria-hidden="true"></span>
                    <span class="sr-only">Next</span>
                </a>
        </div>`;
    }

    load(data, sender, opts) {
        super.load(data, sender, opts);
        this.element.carousel();
    }

    addChild(element, data, sender, opts) {
        super.addChild(element, data, sender, opts);

        // add new slide selector
        if (element.getType() !== 'slide') {
            return;
        }

        var html = `<li
            data-target='#${this.id}'
            data-slide-to='${element.child.index}'
            class='${element.child.isFirst ? 'active' : ''}'>
        </li>`;

        this.element.find('ol.carousel-indicators').append(html);
    }
}
PodeElementFactory.setClass(PodeCarousel);

class PodeSlide extends PodeCyclingChildElement {
    static type = 'slide';

    constructor(data, sender, opts) {
        super(data, sender, opts);

        if (!this.checkParentType('carousel')) {
            throw 'Slide element can only be used in a Carousel'
        }
    }

    new(data, sender, opts) {
        var title = data.Title ? `<h5>${data.Title}</h5>` : '';
        var message = data.Message ? `<p>${data.Message}</p>` : '';

        return `<div
            id='${this.id}'
            class='carousel-item ${this.child.isFirst ? 'active' : ''} ${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <div class='d-flex w-100 h-100' pode-content-for='${this.uuid}'></div>
                <div class='carousel-caption d-none d-md-block'>
                    ${title}
                    ${message}
                </div>
        </div>`;
    }

    invoke(data, sender, opts) {
        this.parent.find(`.nav-link#${this.id}`).trigger('click');
        super.invoke(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeSlide);

class PodeCodeEditor extends PodeContentElement {
    static type = 'code-editor';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.readonly = data.ReadOnly ?? false;
        this.language = (data.Language ?? 'plaintext').toLowerCase();
        this.uploadable = data.Uploadable ?? false;
        this.theme = (data.Theme ?? '').toLowerCase();
        this.value = data.Value ?? '';
        this.editor = null;
    }

    new(data, sender, opts) {
        var upload = !this.uploadable ? '' : `<button
            class='btn btn-inbuilt-theme pode-upload mBottom1'
            type='button'
            title='Upload'
            data-toggle='tooltip'
            for='${this.id}'>
                <span class='mdi mdi-upload mRight02'></span>
        </button>`;

        return `<div
            id="${this.id}"
            name="${this.name}"
            class="pode-code-editor ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}"
            ${this.events(data.Events)}>
                ${upload}
                <div class="code-editor" for="${this.id}"></div>
        </div>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        var src = $('script[role="monaco"]').attr('src');
        require.config({ paths: { 'vs': src.substring(0, src.lastIndexOf('/')) }});

        // create the editors
        require(["vs/editor/editor.main"], function() {
            if (!obj.theme) {
                switch(getPodeTheme()) {
                    case 'dark':
                        obj.theme = 'vs-dark';
                        break;

                    case 'terminal':
                        obj.theme = 'hc-black';
                        break;

                    default:
                        obj.theme = 'vs';
                        break;
                }
            }

            obj.editor = monaco.editor.create(obj.element.find('.code-editor')[0], {
                value: obj.value,
                language: obj.language,
                theme: obj.theme,
                readOnly: obj.readonly
            });

            obj.value = '';
        });

        // bind upload buttons
        if (this.uploadable) {
            this.element.find('.pode-upload').off('click').on('click', function(e) {
                var data = JSON.stringify({
                    language: obj.language,
                    value: obj.editor.getValue()
                });

                sendAjaxReq(`${obj.url}/upload`, data, null, true, null, {
                    contentType: 'application/json; charset=UTF-8'
                });
            });
        }
    }

    update(data, sender, opts) {
        // set value
        if (data.Value) {
            this.editor.setValue(data.Value);
        }

        // update language
        if (data.Language) {
            this.language = data.Language.toLowerCase();
            monaco.editor.setModelLanguage(this.editor.getModel(), this.language);
        }
    }

    clear(data, sender, opts) {
        this.editor.setValue('');
    }
}
PodeElementFactory.setClass(PodeCodeEditor);

class PodeChart extends PodeRefreshableElement {
    static type = 'chart';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.chartType = (data.ChartType ?? 'line').toLowerCase();
        this.appendData = data.Append ?? false;
        this.maxItems = data.MaxItems ?? 0;
        this.timeLabels = data.TimeLabels ?? false;
        this.min = {
            x: data.Min ? (data.Min.X ?? 0) : 0,
            y: data.Min ? (data.Min.Y ?? 0) : 0
        };
        this.max = {
            x: data.Max ? (data.Max.X ?? 0) : 0,
            y: data.Max ? (data.Max.Y ?? 0) : 0
        };
        this.showLegend = !(data.NoLegend ?? false);
        this.colours = data.Colours ? convertToArray(data.Colours) : [];
        this.chart = null;
    }

    new(data, sender, opts) {
        var message = data.Message ? `<p class='card-text'>${data.Message}</p>` : '';
        var height = data.Height !== 'auto' ? `height:${data.Height};` : '';

        return `${message}<div
            id="${this.id}"
            name="${this.name}"
            class="${this.css.classes}"
            style="${this.css.styles}"
            role='chart'
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <div role='controls'>
                    <div class="btn-group mr-2">
                        ${this.buildRefreshButton(false)}
                    </div>
                </div>
                <canvas class="my-4 w-100" style="${height}"></canvas>
                <div class="text-center">
                    <span id="${this.id}_spinner" class="spinner-grow text-inbuilt-sec-theme canvas-spinner" role="status"></span>
                </div>
        </div>`;
    }

    load(data, sender, opts) {
        if (!this.dynamic) {
            return;
        }

        super.load(data, sender, opts);

        // is this the chart's first load?
        var data = !this.created || !this.appendData ? 'FirstLoad=1' : '';

        // things get funky here if we have a chart with a 'for' attr
        // if so, we need to serialize the form, and then send the request to the form instead
        var url = this.url;

        if (this.element.attr('for')) {
            var form = $(`#${this.element.attr('for')}`);
            if (data) {
                data += '&';
            }

            data += form.serialize();
            url = form.attr('action');
        }

        // invoke and load chart content
        sendAjaxReq(url, data, this.element, true, () => { this.loading = false }, { successCallbackBefore: true });
        this.loading = true;
    }

    update(data, sender, opts) {
        data.Data = convertToArray(data.Data);
        if (data.Data.length === 0) {
            return;
        }

        // create chart canvas
        if (!this.chart) {
            this.createCanvas(data, sender, opts);
        }

        // update chart
        else {
            // append or update?
            if (this.appendData) {
                this.appendCanvas(data, sender, opts);
            }
            else {
                this.updateCanvas(data, sender, opts);
            }
        }
    }

    appendCanvas(data, sender, opts) {
        // labels (x-axis)
        this.updateXAxis(data.Data);
        this.chart.data.labels = truncateArray(this.chart.data.labels, this.maxItems);

        // data (y-axis)
        this.updateYAxis(data.Data);
        this.chart.data.datasets.forEach((dataset) => {
            dataset.data = truncateArray(dataset.data, this.maxItems);
        });

        // re-render
        this.rebuild();
    }

    updateCanvas(data, sender, opts) {
        this.chart.data.labels = [];
        this.chart.data.datasets.forEach((a) => a.data = []);

        // labels (x-axis)
        this.updateXAxis(data.Data);

        // data (y-axis)
        this.updateYAxis(data.Data);

        // re-render
        this.rebuild();
    }

    updateXAxis(data) {
        data.forEach((item) => {
            this.chart.data.labels.push(this.timeLabels ? getTimeString() : item.Key);
        });
    }

    updateYAxis(data) {
        data.forEach((item) => {
            item.Values.forEach((set, index) => {
                this.chart.data.datasets[index].data.push(set.Value);
            });
        });
    }

    createCanvas(data, sender, opts) {
        // remove the chart if exists
        if (this.chart) {
            this.chart.destroy();
        }

        // get the chart's canvas and type
        var ctx = this.element.find('canvas')[0].getContext('2d');
        var theme = getPodeTheme();

        // get senderId if present, and set on canvas as 'for'
        var senderId = getId(sender);
        if (senderId && getTagName(sender) == 'form') {
            this.element.attr('for', senderId);
        }

        // colours for lines/bars/segments
        var palette = getChartColourPalette(theme, this.colours);

        // x-axis labels
        var xAxis = [];
        data.Data.forEach((item) => {
            xAxis = xAxis.concat(this.timeLabels ? getTimeString() : item.Key);
        });

        // y-axis labels - need to support datasets
        var yAxises = {};
        data.Data[0].Values.forEach((item) => {
            yAxises[item.Key] = {
                data: [],
                label: item.Key
            };
        });

        data.Data.forEach((item) => {
            item.Values.forEach((set) => {
                yAxises[set.Key].data = yAxises[set.Key].data.concat(set.Value);
            });
        });

        // axis themes
        var axesOpts = {
            x: {},
            y: {}
        };

        // dataset details
        Object.keys(yAxises).forEach((key, index) => {
            switch (this.chartType) {
                case 'line':
                    yAxises[key].backgroundColor = palette[index % palette.length].replace('1.0)', '0.2)');
                    yAxises[key].borderColor = palette[index % palette.length];
                    yAxises[key].borderWidth = 3;
                    yAxises[key].fill = true;
                    yAxises[key].tension = 0.4;
                    axesOpts.x = getChartAxesColours(theme, this.element, this.min.x, this.max.x);
                    axesOpts.y = getChartAxesColours(theme, this.element, this.min.y, this.max.y);
                    break;

                case 'doughnut':
                case 'pie':
                    yAxises[key].backgroundColor = function(context) {
                        return palette[context.dataIndex % palette.length];
                    };
                    yAxises[key].borderColor = getChartPieBorderColour(theme);
                    break;

                case 'bar':
                    yAxises[key].backgroundColor = palette[index % palette.length].replace('1.0)', '0.6)');
                    yAxises[key].borderColor = palette[index % palette.length];
                    yAxises[key].borderWidth = 1;
                    axesOpts.x = getChartAxesColours(theme, this.element, this.min.x, this.max.x);
                    axesOpts.y = getChartAxesColours(theme, this.element, this.min.y, this.max.y);
                    break;
            }
        });

        // display the legend?
        var showLegend = (Object.keys(yAxises)[0].toLowerCase() != 'default');
        if ((this.element.closest('div.pode-tile').length > 0) || !this.showLegend) {
            showLegend = false;
        }

        // make the chart
        this.chart = new Chart(ctx, {
            type: this.chartType,

            data: {
                labels: xAxis,
                datasets: Object.values(yAxises)
            },

            options: {
                plugins: {
                    legend: {
                        display: showLegend,
                        labels: {
                            color: $('body').css('color')
                        }
                    }
                },

                scales: {
                    x: axesOpts.x,
                    y: axesOpts.y
                }
            }
        });
    }

    rebuild() {
        this.chart.update();
    }

    clear(data, sender, opts) {
        // clear labels (x-axis)
        this.chart.data.labels = [];

        // clear data (y-axis)
        this.chart.data.datasets.forEach((dataset) => {
            dataset.data = [];
        });

        // re-render
        this.rebuild();
    }
}
PodeElementFactory.setClass(PodeChart);

class PodeModal extends PodeContentElement {
    static type = 'modal';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.submit = {
            show: data.ShowSubmit ?? false,
            url: data.Action ?? ''
        }
        this.asForm = data.AsForm ?? false;
    }

    new(data, sender, opts) {
        var icon = this.setIcon(data.Icon);

        var submit = !this.submit.show ? '' : `<button
            type='button'
            class='btn btn-inbuilt-theme pode-modal-submit'>
                ${data.SubmitText}
        </button>`;

        var formStart = this.asForm ? `<form class='pode-form' method='${data.Method}' action='${data.Action}'>` : '';
        var formEnd = this.asForm ? `</form>` : '';

        return `<div
            id="${this.id}"
            class="modal fade ${this.css.classes}"
            style="${this.css.styles}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}"
            name="${this.name}"
            tabindex="-1"
            aria-labelledby="${this.id}_lbl"
            aria-hidden="true"
            pode-data-value="">
                <div class="modal-dialog modal-dialog-scrollable pode-modal-${data.Size.toLowerCase()}">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title" id="${this.id}_lbl">
                                ${icon}
                                ${data.DisplayName}
                            </h5>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            ${formStart}
                            <div pode-content-for='${this.uuid}'></div>
                            ${formEnd}
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">${data.CloseText}</button>
                            ${submit}
                        </div>
                    </div>
                </div>
        </div>`;
    }

    bind(data, sender, opts) {
        var obj = this;

        if (this.submit.show) {
            this.element.find("div.modal-content form.pode-form").off('keypress').on('keypress', function(e) {
                if (!isEnterKey(e)) {
                    return;
                }

                e.preventDefault();
                e.stopPropagation();

                var btn = obj.element.find('div.modal-footer button.pode-modal-submit')
                if (btn) {
                    btn.trigger('click');
                }
            });

            this.element.find("div.modal-footer button.pode-modal-submit").off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();

                // get url
                var url = obj.submit.url;
                if (!obj.submit.url) {
                    return;
                }

                // find a form
                var inputs = {};
                var form = null;
                var method = 'post';

                if (obj.asForm) {
                    form = obj.element.find('div.modal-body form');

                    var action = form.attr('action');
                    if (action) {
                        url = action;
                    }

                    var _method = form.attr('method');
                    if (_method) {
                        method = _method;
                    }

                    inputs = serializeInputs(form);
                    removeValidationErrors(form);
                }

                // get a data value
                var dataValue = getDataValue($(this));

                // build data
                if (dataValue) {
                    inputs.data = addFormDataValue(inputs.data, 'Value', dataValue);
                }

                // add method
                if (!inputs.opts) {
                    inputs.opts = {};
                }

                inputs.opts.method = method;

                // invoke url
                sendAjaxReq(url, inputs.data, (form ?? obj.element), true, null, inputs.opts);
            });
        }
    }

    show(data, sender, opts) {
        if (data.DataValue) {
            this.element.attr('pode-data-value', data.DataValue);
        }

        resetForm(this.element);
        removeValidationErrors(this.element);

        invokeActions(data.Actions);
        this.element.modal('show');
    }

    hide(data, sender, opts) {
        resetForm(this.element);
        removeValidationErrors(this.element);
        this.element.modal('hide');
    }

    static find(data, sender, filter, opts) {
        var modal = super.find(data, sender, filter, opts);
        if (modal) {
            return modal;
        }

        if (sender) {
            return sender.closest('.modal');
        }

        return null;
    }
}
PodeElementFactory.setClass(PodeModal);

class PodeList extends PodeContentElement {
    static type = 'list';

    constructor(...args) {
        super(...args);
        this.contentProperty = 'Items';
    }

    new(data, sender, opts) {
        var listTag = data.Numbered ? 'ol' : 'ul';

        data.Values = convertToArray(data.Values);
        data.Items = convertToArray(data.Items);

        var content = '';
        if (data.Items.length > 0) {
            content = `<span pode-content-for='${this.uuid}'></span>`
        }
        else {
            data.Values.forEach((v) => {
                content += `<li>${v}</li>`;
            });
        }

        return `<${listTag}
            id='${this.id}'
            class='${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                ${content}
        </${listTag}>`;
    }
}
PodeElementFactory.setClass(PodeList);

class PodeListItem extends PodeContentElement {
    static type = 'list-item';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<li
            id='${this.id}'
            class='${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <span pode-content-for='${this.uuid}'></span>
        </li>`;
    }
}
PodeElementFactory.setClass(PodeList);

class PodeHidden extends PodeFormElement {
    static type = 'hidden';

    constructor(...args) {
        super(...args);
        this.validation = false;
        this.label.enabled = false;
    }

    new(data, sender, opts) {
        return `<input
            type="hidden"
            id="${this.id}"
            class="form-control ${this.css.classes}"
            style="${this.css.styles}"
            name="${this.name}"
            value="${data.Value}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">`;
    }
}
PodeElementFactory.setClass(PodeHidden);

class PodeSelect extends PodeFormElement {
    static type = 'select';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.multiSelect = data.Multiple ?? false;
    }

    new(data, sender, opts) {
        var multiple = this.multiSelect ? `multiple size='${data.Size ?? 1}'` : '';

        var selectedValue = convertToArray(data.SelectedValue);
        if (!this.multiSelect && selectedValue.length >= 2) {
            selectedValue = [selectedValue[0]];
        }

        var options = '';
        data.DisplayOptions = convertToArray(data.DisplayOptions);
        convertToArray(data.Options).forEach((opt, index) => {
            if (!opt) {
                return;
            }

            options += `<option
                value='${opt}'
                ${selectedValue.includes(opt) ? 'selected' : '' }>
                    ${data.DisplayOptions[index]}
            </option>`;
        });

        return `<select
            id='${this.id}'
            class='custom-select ${this.css.classes}'
            style='${this.css.styles}'
            name='${this.name}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${multiple}
            ${this.events(data.Events)}>
                ${options}
        </select`;
    }

    //TODO: add "New-PodeWebSelectOption", and make "PodeSelectOption" class
    //          --  "-Options" is now an array of that func, and we can remove "-DisplayOptions"!
    //          -- need to fix "clear(...)" if we do this

    load(data, sender, opts) {
        super.load(data, sender, opts);
        if (this.dynamic) {
            sendAjaxReq(this.url, null, this.element, true);
        }
    }

    set(data, sender, opts) {
        if (!data.Value) {
            return;
        }

        this.element.val(decodeHTML(data.Value));
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // update options
        data.Options = convertToArray(data.Options);
        if (data.Options.length > 0) {
            this.clear();

            data.DisplayOptions = convertToArray(data.DisplayOptions);
            data.SelectedValue = convertToArray(data.SelectedValue);

            data.Options.forEach((opt, index) => {
                this.element.append(`<option
                    value="${opt}"
                    ${data.SelectedValue.includes(opt) ? 'selected' : '' }>
                        ${data.DisplayOptions[index]}
                </option>`);
            });
        }
    }

    clear(data, sender, opts) {
        this.element.empty();
    }
}
PodeElementFactory.setClass(PodeSelect);

class PodeRange extends PodeFormElement {
    static type = 'range';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.showValue = data.ShowValue ?? false;
    }

    new(data, sender, opts) {
        var rangeValue = !this.showValue ? '' : `<input
            id='${this.id}_value'
            type='number'
            class='form-control pode-range-value'
            for='${this.id}'
            value='${data.Value}'
            min='${data.Min}'
            max='${data.Max}'>
        <label class=''>/${data.Max}</label>`;

        return `<span class='range-wrapper ${this.css.classes}' style='${this.css.styles}' for='${this.id}'>
            <input
                type='range'
                id='${this.id}'
                name='${this.name}'
                class='form-control-range ${this.showValue ? 'pode-range-value' : ''}'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'
                value='${data.Value}'
                min='${data.Min}'
                max='${data.Max}'
                ${this.events(data.Events)}>
            ${rangeValue}
        </span>`;
    }

    bind(data, sender, opts) {
        var obj = this;

        if (this.showValue) {
            var valElement = this.getNumberInput();

            this.element.off('change').on('change', function(e) {
                valElement.val(obj.element.val());
            });

            valElement.off('change').on('change', function(e) {
                obj.element.val(valElement.val());
            });
        }
    }

    disable(data, sender, opts) {
        super.disable(data, sender, opts);
        disable(this.getNumberInput());
    }

    enable(data, sender, opts) {
        super.enable(data, sender, opts);
        enable(this.getNumberInput());
    }

    getNumberInput() {
        return !this.showValue ? null : this.element.closest('.range-wrapper').find(`input[type="number"][for="${this.id}"]`);
    }
}
PodeElementFactory.setClass(PodeRange);

class PodeProgress extends PodeContentElement {
    static type = 'progress';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.showValue = data.ShowValue ?? false;
        this.animated = data.Animated ?? false;
        this.striped = data.Striped ?? false;
    }

    new(data, sender, opts) {
        var showValue = this.showValue ? 'pode-progress-value' : '';
        var striped = this.striped ? 'progress-bar-striped' : '';
        var animated = this.animated ? 'progress-bar-animated' : '';

        var html = `<div
            class='progress'>
                <div
                    id='${this.id}'
                    name='${this.name}'
                    class='progress-bar bg-${data.ColourType ?? 'primary'} ${showValue} ${striped} ${animated} ${this.css.classes}'
                    role='progressbar'
                    style='width: ${data.Percentage ?? 0}%;${this.css.styles}'
                    aria-valuenow='${data.Value ?? 0}'
                    aria-valuemin='${data.Min ?? 0}'
                    aria-valuemax='${data.Max ?? 100}'
                    pode-object='${this.getType()}'
                    pode-id='${this.uuid}'
                    ${this.events(data.Events)}>
                </div>
        </div>`;

        if (data.DisplayName) {
            html = `<div class='form-group row'>
                <label for='${this.id}' class='col-sm-2 col-form-label'>${data.DisplayName}</label>
                <div class='col-sm-10 my-auto'>${html}</div>
            </div>`;
        }

        return html;
    }

    load(data, sender, opts) {
        super.load(data, sender, opts);

        if (this.showValue) {
            this.element.text(`${this.element.attr('aria-valuenow')} / ${this.element.attr('aria-valuemax')}`);
        }
    }

    bind(data, sender, opts) {
        var obj = this;

        if (this.showValue) {
            this.element.off('change').on('change', function(e) {
                obj.element.text(`${obj.element.attr('aria-valuenow')} / ${obj.element.attr('aria-valuemax')}`);
            });
        }
    }

    update(data, sender, opts) {
        // value
        if (data.Value) {
            this.element.attr('aria-valuenow', data.Value);

            var max = this.element.attr('aria-valuemax');
            var percentage = (data.Value / max) * 100.0;

            this.element.css('width', `${percentage}%`);
        }

        // colour
        if (data.Colour) {
            replaceClass(this.element, 'bg-\\w+', `bg-${data.ColourType}`);
        }
    }
}
PodeElementFactory.setClass(PodeProgress);

class PodeCheckbox extends PodeFormElement {
    static type = 'checkbox';

    constructor(...args) {
        super(...args);
        this.asFieldset = true;
    }

    new(data, sender, opts) {
        var inline = data.Inline ? 'custom-control-inline' : ''
        var checked = data.Checked ? 'checked' : '';

        var isSwitch = data.AsSwitch ?? false;
        var divClass = isSwitch ? 'custom-switch' : 'custom-checkbox';

        data.Options = convertToArray(data.Options);
        data.DisplayOptions = convertToArray(data.DisplayOptions);

        var options = '';
        data.Options.forEach((opt, index) => {
            if (!opt) {
                return;
            }

            options += `<div class='custom-control ${divClass} ${inline} ${this.css.classes}' style='${this.css.styles}'>
                <input
                    type='checkbox'
                    id='${this.id}_option${index}'
                    class='custom-control-input'
                    value='${opt}'
                    name='${this.name}'
                    pode-option-id='${index}'
                    ${checked}>
                <label class='custom-control-label' for='${this.id}_option${index}'>
                    ${opt !== 'true' ? data.DisplayOptions[index] : ''}
                </label>
            </div>`;
        });

        return `<div'>${options}</div>`;
    }

    update(data, sender, opts) {
        // get checkbox
        var checkbox = this.getCheckbox(data.OptionId);
        if (!checkbox) {
            return;
        }

        // check TODO: Checked should have an "Unchanged" state
        checkbox.attr('checked', data.Checked);

        // enable/disable TODO: this isn't "DisabledState"
        switch ((data.State ?? '').toLowerCase()) {
            case 'enabled':
                this.enable(data, sender, opts);
                break;

            case 'disabled':
                this.disable(data, sender, opts);
                break;
        }
    }

    enable(data, sender, opts) {
        var checkbox = this.getCheckbox(data.OptionId);
        if (!checkbox) {
            return;
        }

        enable(checkbox);
    }

    disable(data, sender, opts) {
        var checkbox = this.getCheckbox(data.OptionId);
        if (!checkbox) {
            return;
        }

        disable(checkbox);
    }

    getCheckbox(index) {
        return this.element.find(`input#${this.id}_option${index}`);
    }

    //TODO: same as the comment for "select" - CheckboxOption ?
    //          -- that would make this "Checkbox" not a "FormElement" but the "CheckOption" would be
    //          -- this is needed to control individual checkboxes, and fix disabled/required/etc support
    //          -- as well as update() support...
}
PodeElementFactory.setClass(PodeCheckbox);

class PodeRadio extends PodeFormElement {
    static type = 'radio';

    constructor(...args) {
        super(...args);
        this.label.asLegend = true;
        this.asFieldset = true;
    }

    new(data, sender, opts) {
        var inline = data.Inline ? 'custom-control-inline' : '';

        data.Options = convertToArray(data.Options);
        data.DisplayOptions = convertToArray(data.DisplayOptions);

        var options = '';
        data.Options.forEach((opt, index) => {
            if (!opt) {
                return;
            }

            options += `<div class='custom-control custom-radio ${inline} ${this.css.classes}' style='${this.css.styles}'>
                <input
                    type='radio'
                    id='${this.id}_option${index}'
                    class='custom-control-input'
                    value='${opt}'
                    name='${this.name}'
                    pode-option-id='${index}'
                    ${index === 0 ? 'checked' : ''}>
                <label class='custom-control-label' for='${this.id}_option${index}'>
                    ${opt !== 'true' ? data.DisplayOptions[index] : ''}
                </label>
            </div>`;
        });

        return `<div>${options}</div>`;
    }

    //TODO: same as the comment for "select" - CheckboxOption ?
    //          -- that would make this "Checkbox" not a "FormElement" but the "CheckOption" would be
    //          -- this is needed to control individual checkboxes, and fix disabled/required/etc support
    //          -- as well as update() support...

    //TODO: radio missing update/enable/etc.
}
PodeElementFactory.setClass(PodeRadio);

class PodeDateTime extends PodeFormMultiElement {
    static type = 'datetime';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        if (searchArray(data.Type, 'date', true)) {
            this.addFormElement(this.build('textbox', {
                ID: `${this.id}_date`,
                Name: `${this.id}_date`,
                Type: 'date',
                ReadOnly: this.readonly,
                Required: this.required,
                DynamicLabel: true,
                DisplayName: data.Placeholders.Date
            }, {
                help: { enabled: true, id: this.id }
            }));
        }

        if (searchArray(data.Type, 'time', true)) {
            this.addFormElement(this.build('textbox', {
                ID: `${this.id}_time`,
                Name: `${this.id}_time`,
                Type: 'time',
                ReadOnly: this.readonly,
                Required: this.required,
                DynamicLabel: true,
                DisplayName: data.Placeholders.Time
            }, {
                help: { enabled: true, id: this.id }
            }));
        }

        return super.new(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeDateTime);

class PodeCredential extends PodeFormMultiElement {
    static type = 'credential';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        if (searchArray(data.Type, 'username', true)) {
            this.addFormElement(this.build('textbox', {
                ID: `${this.id}_username`,
                Name: `${this.id}_username`,
                Type: 'text',
                ReadOnly: this.readonly,
                Required: this.required,
                DynamicLabel: true,
                DisplayName: data.Placeholders.Username
            }, {
                help: { enabled: true, id: this.id }
            }));
        }

        if (searchArray(data.Type, 'password', true)) {
            this.addFormElement(this.build('textbox', {
                ID: `${this.id}_password`,
                Name: `${this.id}_password`,
                Type: 'password',
                ReadOnly: this.readonly,
                Required: this.required,
                DynamicLabel: true,
                DisplayName: data.Placeholders.Password
            }, {
                help: { enabled: true, id: this.id }
            }));
        }

        return super.new(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeCredential);

class PodeMinMax extends PodeFormMultiElement {
    static type = 'minmax';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        if (searchArray(data.Type, 'min', true)) {
            this.addFormElement(this.build('textbox', {
                ID: `${this.id}_min`,
                Name: `${this.id}_min`,
                Type: 'number',
                ReadOnly: this.readonly,
                Required: this.required,
                DynamicLabel: true,
                DisplayName: data.Placeholders.Min,
                Value: data.Values.Min,
                Prepend: data.Prepend,
                Append: data.Append
            }, {
                help: { enabled: true, id: this.id }
            }));
        }

        if (searchArray(data.Type, 'max', true)) {
            this.addFormElement(this.build('textbox', {
                ID: `${this.id}_max`,
                Name: `${this.id}_max`,
                Type: 'number',
                ReadOnly: this.readonly,
                Required: this.required,
                DynamicLabel: true,
                DisplayName: data.Placeholders.Max,
                Value: data.Values.Max,
                Prepend: data.Prepend,
                Append: data.Append
            }, {
                help: { enabled: true, id: this.id }
            }));
        }

        return super.new(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeMinMax);

class PodeFileStream extends PodeContentElement {
    static type = 'file-stream';

    //TODO: could we build this entire element with pure Card, Button, and Textarea New- func calls?
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.file = {
            url: data.Url,
            length: 0,
            streaming: true,
            interval: data.Interval ?? 60000
        };
    }

    new(data, sender, opts) {
        var header = '';
        if (!data.NoHeader) {
            var icon = this.setIcon(data.Icon);

            header = `<div class='card-header d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 border-bottom'>
                <h5>
                    ${icon}
                    ${encodeHTML(this.file.url)}
                </h5>
                <div class='btn-toolbar mb-2 mb-md-0 mTop-05'>
                    <div class='icon-group mr-2'>
                        <span class='mdi mdi-alert-circle-outline stream-error' style='display:none;'></span>
                        <span id='${this.id}_spinner' class='spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
                    </div>
                    <div class='btn-group mr-2 mLeft05'>
                        <button type='button' class='btn btn-no-text btn-outline-secondary pode-stream-download' for='${this.id}'>
                            <span class='mdi mdi-download mdi-size-20' title='Download' data-toggle='tooltip'></span>
                        </button>
                        <button type='button' class='btn btn-no-text btn-outline-secondary pode-stream-clear' for='${this.id}'>
                            <span class='mdi mdi-eraser mdi-size-20' title='Clear' data-toggle='tooltip'></span>
                        </button>
                        <button type='button' class='btn btn-no-text btn-outline-secondary pode-stream-pause' for='${this.id}'>
                            <span class='mdi mdi-pause mdi-size-20' title='Pause' data-toggle='tooltip'></span>
                        </button>
                    </div>
                </div>
            </div>`;
        }

        return `<div
            id='${this.id}'
            name='${this.name}'
            class="card file-stream ${this.css.classes}"
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                ${header}
                <div>
                    <pre>
                        <textarea
                            class="form-control"
                            rows="$($data.Height)"
                            readonly
                            ${this.events(data.Events)}></textarea>
                    </pre>
                </div>
        </div>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // timer for reading file
        setInterval(function() {
            if (!obj.file.streaming) {
                return;
            }

            obj.spinner(true);

            $.ajax({
                url: obj.file.url,
                method: 'get',
                dataType: 'text',
                headers: { "Range": `bytes=${obj.file.length}-` },
                success: function(data, status, xhr) {
                    if (obj.element.hasClass('stream-error')) {
                        removeClass(obj.element, 'stream-error', true);
                        show(obj.element.find('div.card-header div div.btn-group'));
                    }

                    obj.spinner(false);

                    var header = xhr.getResponseHeader('Content-Range');
                    if (header) {
                        var rangeLength = header.split('/')[1];
                        var txt = obj.element.find('pre textarea');

                        // if new content, append
                        if (rangeLength > parseInt(obj.file.length)) {
                            txt.append(data);
                            obj.file.length = rangeLength;
                            txt.scrollTop = txt.scrollHeight;
                        }

                        // if length is now less, clear the textarea
                        else if (rangeLength < parseInt(obj.file.length)) {
                            obj.clear();
                        }
                    }
                },
                error: function(err) {
                    obj.spinner(false);

                    if (err.status == 416) {
                        return;
                    }

                    obj.file.streaming = false;
                    addClass(obj.element, 'stream-error');
                    hide(obj.element.find('div.card-header div div.btn-group'));
                }
            });
        }, this.file.interval);

        // download file
        this.element.find('.pode-stream-download').off('click').on('click', function(e) {
            obj.download();
            unfocus($(this));
        });

        // pause/resume file streaming
        this.element.find('.pode-stream-pause').off('click').on('click', function(e) {
            obj.file.streaming = !obj.file.streaming;
            toggleIcon($(this), 'pause', 'play', 'Pause', 'Play');
            unfocus($(this));
        });

        // clear textarea
        this.element.find('.pode-stream-clear').off('click').on('click', function(e) {
            obj.clear();
            unfocus($(this));
        });
    }

    download() {
        var parts = this.file.url.split('/');
        downloadFile(this.file.url, parts[parts.length - 1]);
    }

    update(data, sender, opts) {
        if (data.Url && this.file.url !== data.Url) {
            this.stop(data, sender, opts);
            this.clear(data, sender, opts);
            this.file.url = data.Url;
            this.start(data, sender, opts);
        }
    }

    start(data, sender, opts) {
        this.file.streaming = true;

        var btn = this.element.find('.pode-stream-pause span');
        if (btn.hasClass('mdi-play')) {
            toggleIcon(btn, 'pause', 'play', 'Pause', 'Play');
        }
    }

    stop(data, sender, opts) {
        this.file.streaming = false;

        var btn = this.element.find('.pode-stream-pause span');
        if (btn.hasClass('mdi-pause')) {
            toggleIcon(btn, 'pause', 'play', 'Pause', 'Play');
        }
    }

    restart(data, sender, opts) {
        this.stop(data, sender, opts);
        this.clear(data, sender, opts);
        this.start(data, sender, opts);
    }

    clear(data, sender, opts) {
        var txt = this.element.find('pre textarea');
        txt.text('');
        txt.scrollTop = txt.scrollHeight;
        this.file.length = 0;
    }
}
PodeElementFactory.setClass(PodeFileStream);

class PodeSteps extends PodeContentElement {
    static type = 'steps';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.contentProperty = 'Steps';
        this.stepper = null;
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="bs-stepper linear ${this.css.classes}"
            style="${this.css.styles}"
            role="stepper"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <div class="bs-stepper-header" role="tablist"></div>
                <div class="bs-stepper-content" pode-content-for='${this.uuid}'></div>
        </div>`;
    }

    load(data, sender, opts) {
        super.load(data, sender, opts);
        this.stepper = new Stepper(this.element[0], { linear: true });
    }

    previous() {
        this.stepper.previous();
    }

    next() {
        this.stepper.next();
    }

    submit() {
        var result = this.serialize();
        sendAjaxReq(this.url, result.data, this.element, true, null, result.opts);
    }

    addChild(element, data, sender, opts) {
        super.addChild(element, data, sender, opts);

        // add new step indicator
        if (element.getType() !== 'step') {
            return;
        }

        var html = `<div class='step ${element.child.isFirst ? 'active' : ''}' data-target='#${element.id}'>
            <button type='button' class='step-trigger' role='tab' id='${element.id}-trigger' aria-controls='${element.id}' ${!element.child.isFirst ? 'disabled' : ''}>
                <span class='bs-stepper-circle'>
                    ${data.Icon ? element.setIcon(data.Icon) : element.child.index + 1}
                </span>
                <span class='bs-stepper-label'>${data.DisplayName}</span>
            </button>
        </div>`;

        this.element.find('div[role="tablist"]').append(html);
    }
}
PodeElementFactory.setClass(PodeSteps);

class PodeStep extends PodeContentElement {
    static type = 'step';

    constructor(data, sender, opts) {
        super(data, sender, opts);

        if (!this.checkParentType('steps')) {
            throw 'Step element can only be used in Steps'
        }
    }

    new(data, sender, opts) {
        //TODO: can be ".build()" these buttons? - which would also include the setIcon automatically
        var prevBtn = this.child.isFirst ? '' : `<button class='btn btn-inbuilt-theme step-previous float-left' for='${this.id}'>
            <span class='mdi mdi-chevron-left mRight02'></span>
            Previous
            <span class='spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
        </button>`;

        var nextBtn = `<button class='btn btn-inbuilt-theme step-${this.child.isLast ? 'submit' : 'next'} float-right' for='${this.id}'>
            <span class='spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
            ${this.child.isLast ? 'Submit' : 'Next'}
            <span class='mdi ${this.child.isLast ? 'mdi-checkbox-marked-circle-outline' : 'mdi-chevron-right'} mLeft02'></span>
        </button>`;

        return `<div
            id='${this.id}'
            class='bs-stepper-pane content fade ${this.child.isFirst ? 'active' : ''} ${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            role='tabpanel'
            aria-labelledby='${this.id}-trigger'
            for='${this.parent.id}'>
                <div pode-content-for='${this.uuid}'></div>
                ${prevBtn}
                ${nextBtn}
        </div>`;
    }

    bind(data, sender, opts) {
        var obj = this;

        // auto submit on enter key
        this.element.off('keypress').on('keypress', function(e) {
            if (!isEnterKey(e)) {
                return;
            }

            var nextBtn = obj.element.find('.step-next');
            if (!nextBtn || nextBtn.length === 0) {
                nextBtn = obj.element.find('.step-submit');
            }

            if (nextBtn && nextBtn.length > 0) {
                nextBtn.trigger('click');
            }
        });

        // previous button
        this.element.find('.step-previous').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            obj.parent.previous();
        });

        // next button
        this.element.find('.step-next').off('click').on('click', function(e) {
            if (!obj.element.hasClass('active')) {
                return;
            }

            if (obj.dynamic) {
                var result = obj.serialize();
                sendAjaxReq(obj.url, result.data, obj.element, true, (_, sender) => {
                    if (!hasValidationErrors(sender)) {
                        obj.parent.next();
                    }
                }, result.opts);
            }
            else {
                obj.parent.next();
            }
        });

        // submit button
        this.element.find('.step-submit').off('click').on('click', function(e) {
            if (!obj.element.hasClass('active')) {
                return;
            }

            if (obj.dynamic) {
                var result = obj.serialize();
                sendAjaxReq(obj.url, result.data, obj.element, true, (_, sender) => {
                    if (!hasValidationErrors(sender)) {
                        obj.parent.submit();
                    }
                }, result.opts);
            }
            else {
                obj.parent.submit();
            }
        });
    }
}
PodeElementFactory.setClass(PodeStep);

class PodeBreadcrumb extends PodeBreadcrumbElement {
    static type = 'breadcrumb';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.id = '__pode_breadcrumb__';
        this.contentProperty = 'Items';
        this.isCustom = opts.isCustom ?? true;
        PODE_BREADCRUMB.attr('for', this.uuid);
    }

    new(data, sender, opts) {
        PODE_BREADCRUMB.empty();

        return `<div
            id='${this.id}'
            class='${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            pode-content-for='${this.uuid}'>
        </div>`;
    }

    add(data, sender, opts) {
        var data = {
            ObjectType: 'breadcrumb-item',
            Name: data.Name,
            DisplayName: encodeHTML(data.DisplayName ?? data.Name),
            Url: data.Url,
            Active: data.Active ?? false
        };

        this.render(data, this.element, this, null);
    }
}
PodeElementFactory.setClass(PodeBreadcrumb);

class PodeBreadcrumbItem extends PodeBreadcrumbElement {
    static type = 'breadcrumb-item';

    constructor(...args) {
        super(...args);
        this.ephemeral = true;
    }

    new(data, sender, opts) {
        var html = `${data.DisplayName}`;

        if (!data.Active) {
            html = `<a href='${data.Url}'>${html}</a>`;
        }

        return `<li
            class='breadcrumb-item d-inline-block ${data.Active ? 'active' : ''} ${this.css.classes}'
            style='${this.css.styles}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${data.Active ? "aria-current='page'" : ''}>
                ${html}
        </li>`;
    }
}
PodeElementFactory.setClass(PodeBreadcrumbItem);

class PodeNavDivider extends PodeNavElement {
    static type = 'nav-divider';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return data.InDropdown
            ? "<li><hr class='dropdown-divider'></li>"
            : "<span class='link-divider'>|</span>";
    }
}
PodeElementFactory.setClass(PodeNavDivider);

class PodeNavDropdown extends PodeNavElement {
    static type = 'nav-dropdown';

    constructor(...args) {
        super(...args);
        this.contentProperty = 'Items';
    }

    new(data, sender, opts) {
        var icon = this.setIcon(data.Icon, true, true);

        return `<li class='${data.InDropdown ? 'dropdown-submenu' : 'nav-item dropdown'}' pode-hover='${data.Hover ?? false}'>
            <a
                id='${this.id}'
                class='${data.InDropdown ? 'dropdown-item' : 'nav-link'} dropdown-toggle'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'
                href='#'
                role='button'
                data-toggle='dropdown'
                aria-haspopup='true'
                aria-expanded='false'>
                    ${icon}
                    ${data.DisplayName}
            </a>

            <ul class='dropdown-menu' aria-labelledby='${this.id}' pode-content-for='${this.uuid}'></ul>
        </li>`;
    }
}
PodeElementFactory.setClass(PodeNavDropdown);

class PodeNavLink extends PodeNavElement {
    static type = 'nav-link';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        var icon = this.setIcon(data.Icon, true, true);

        var href = '';
        if (!this.dynamic) {
            href = `href='${data.Url}' ${data.NewTab ? "target='_blank'" : ''}`;
        }

        return `<li ${data.InDropdown ? '' : "class='nav-item'"}>
            <a
                id='${this.id}'
                class='${data.InDropdown ? 'dropdown-item' : 'nav-link'} pode-nav-link'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'
                ${href}>
                    ${icon}
                    ${data.DisplayName}
            </a>
        <li>`;
    }

    bind(data, sender, opts) {
        var obj = this;

        if (this.dynamic) {
            this.element.off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                sendAjaxReq(obj.url, null, null, true);
            });
        }
    }
}
PodeElementFactory.setClass(PodeNavLink);