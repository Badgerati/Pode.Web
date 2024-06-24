const PODE_CONTENT = $('content#pode-content');
const PODE_BREADCRUMB = $('nav#pode-breadcrumb ol.breadcrumb');
const PODE_NAVIGATION = $('div#pode-nav-items ul.navbar-nav');

class PodeElementFactory {
    static classMap = new Map();
    static objMap = new Map();
    static referenceMap = new Map();

    constructor() { }

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

        data = data ?? {};
        opts = opts ?? {};
        name = name.toLowerCase();
        action = action.toLowerCase();

        // do we need to load a reference element's data?
        if (data.Reference != null && action === 'use' && name === 'element') {
            // get reference element by ID
            var refData = this.getReference(data.Reference.ID);
            if (refData == null) {
                throw `Reference element data not found for ${data.Reference.ID}`;
            }

            // clean up data object
            delete data['ObjectType'];
            delete data['ComponentType'];
            delete data['Operation'];
            delete data['Reference'];

            // update name/action
            name = refData.ObjectType.toLowerCase();
            action = 'new';

            // create new data object
            data = mergeObjects(data, refData);
        }

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

        // invoke the element action, or cache a reference
        var asRef = ((data.Output ?? {}).AsReference ?? false);
        var obj = null;
        var html = null;

        if (asRef) {
            delete data['Output'];
            this.setReference(data.ID, data);
        }
        else {
            obj = this.findObject(name, action, data, sender, opts);
            if (action === 'new' && obj.created) {
                action = 'update';
            }
            html = obj.refresh(action).apply(action, data, sender, opts);
        }

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
        name = (name === 'element' && data.Type ? data.Type : name).toLowerCase();
        var clazz = this.getClass(name) ?? PodeElement;

        var obj = clazz.findId(data, sender, null, opts);
        if (obj) {
            obj = this.getObject(obj);
            if (obj) {
                return obj;
            }
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

    static setReference(id, data) {
        this.referenceMap.set(id, data);
    }

    static getReference(id) {
        return this.referenceMap.get(id);
    }

    static triggerObject(id, evt) {
        return this.getObject(id).trigger(evt, true);
    }
}

// base element class
class PodeElement {
    static type = 'element';
    static tag = '';

    constructor(data, sender, opts) {
        opts.child = opts.child ?? {};

        this.id = PodeElement.makeId(data, opts);
        this.name = encodeAttribute(data.Name ?? '');
        this.uuid = generateUuid();
        this.created = false;
        this.loading = false;
        this.hasSpinner = false;
        this.ephemeral = (opts.ephemeral ?? false);
        this.dynamic = data.IsDynamic ?? false;
        this.autoRender = opts.autoRender ?? true;
        this.output = {
            appendType: ((data.Output ?? {}).AppendType ?? 'append').toLowerCase()
        };
        this.element = null;
        this.container = null;
        this.icon = null;
        this.url = `/pode.web-dynamic/elements/${this.getType()}/${data.ID}`;
        this.disabled = data.Disabled ?? false;
        this.visible = data.Visible ?? true;
        this.title = encodeAttribute(data.Title ?? '');
        this.readonly = data.ReadOnly ?? false;
        this.required = data.Required ?? false;
        this.width = data.Width ?? '';
        this.height = data.Height ?? '';

        this.content = {
            0: 'Content'
        };

        this.parent = null;
        this.children = [];
        this.child = {
            ignore: false,
            isFirst: false,
            isLast: false,
            index: 0,
            next: null,
            previous: null
        };

        data.Css = data.Css ?? {};
        data.Css.Margin = data.Css.Margin ?? {};
        data.Css.Padding = data.Css.Padding ?? {};
        this.css = {
            classes: data.Css.Classes ?? [],
            styles: data.Css.Styles ?? {},
            display: data.Css.Display ?? '',
            margin: {
                all: data.Css.Margin.All ?? -1,
                top: data.Css.Margin.Top ?? -1,
                bottom: data.Css.Margin.Bottom ?? -1,
                left: data.Css.Margin.Left ?? -1,
                right: data.Css.Margin.Right ?? -1
            },
            padding: {
                all: data.Css.Padding.All ?? -1,
                top: data.Css.Padding.Top ?? -1,
                bottom: data.Css.Padding.Bottom ?? -1,
                left: data.Css.Padding.Left ?? -1,
                right: data.Css.Padding.Right ?? -1
            }
        };

        this.attributes = data.Attributes ?? {};

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

        // don't add element as child?
        if (opts.child && opts.child.ignore) {
            element.child.ignore = true;
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

    setIcon(data, padRight, padTop, opts) {
        // empty if not icon
        if (!data) {
            return '';
        }

        // build data, or use new-icon data?
        if (typeof (data) === 'string') {
            data = {
                ID: `${this.id}_icon`,
                Name: data
            }
        }

        // add padding
        if (padRight || padTop) {
            data.Css = data.Css ?? {};
            data.Css.Classes = data.Css.Classes ?? [];

            if (padRight) {
                data.Css.Classes.push('mRight02');
            }

            if (padTop) {
                data.Css.Classes.push('mTop-02');
            }
        }

        // build opts
        opts = opts ?? {};
        opts.child = opts.child ?? {};
        opts.child.ignore = true;

        // build icon
        var result = this.build('icon', data, opts);

        // set icon and return its html
        this.icon = result.elements[0];
        return result.html;
    }

    refresh(action, force) {
        if ((action === 'new' || !this.created) && !force) {
            return this;
        }

        this.element = this.get();
        this.container = this.getContainer();
        this.created = true;
        return this;
    }

    applyGeneral(action, subType, data, sender, opts) {
        switch (subType) {
            case 'style':
                switch (action) {
                    case 'add':
                        this.addStyle(data.Key, data.Value, sender, { ...data, ...opts });
                        break;

                    case 'remove':
                        this.removeStyle(data.Key, sender, { ...data, ...opts });
                        break;
                }
                break;

            case 'class':
                switch (action) {
                    case 'add':
                        this.addClass(data.Value, sender, { ...data, ...opts });
                        break;

                    case 'remove':
                        this.removeClass(data.Value, sender, { ...data, ...opts });
                        break;

                    case 'rename':
                        this.replaceClass(data.From, data.To, sender, { ...data, ...opts });
                        break;

                    case 'switch':
                        this.toggleClass(data.Value, data.State, sender, { ...data, ...opts })
                        break;
                }
                break;

            case 'display':
                switch (action) {
                    case 'set':
                        this.setDisplay(data.Value, sender, { ...data, ...opts });
                        break;
                }
                break;

            case 'margin':
                switch (action) {
                    case 'set':
                        var margin = {
                            all: data.Value.All ?? 0,
                            top: data.Value.Top ?? 0,
                            bottom: data.Value.Bottom ?? 0,
                            left: data.Value.Left ?? 0,
                            right: data.Value.Right ?? 0
                        };

                        this.setMargin(margin, sender, { ...data, ...opts });
                        break;
                }
                break;

            case 'padding':
                switch (action) {
                    case 'set':
                        var padding = {
                            all: data.Value.All ?? 0,
                            top: data.Value.Top ?? 0,
                            bottom: data.Value.Bottom ?? 0,
                            left: data.Value.Left ?? 0,
                            right: data.Value.Right ?? 0
                        };

                        this.setPadding(padding, sender, { ...data, ...opts });
                        break;
                }
                break;

            case 'validation':
                switch (action) {
                    case 'show':
                        this.showValidation(data.Message, sender, { ...data, ...opts });
                        break;
                }
                break;

            case 'attribute':
                switch (action) {
                    case 'add':
                        this.addAttribute(data.Key, data.Value, sender, { ...data, ...opts })
                        break;

                    case 'remove':
                        this.removeAttribute(data.Key, sender, { ...data, ...opts });
                        break;
                }
                break;

            case 'spinner':
                this.spinner(action === 'show');
                break;
        }

        return null;
    }

    apply(action, data, sender, opts) {
        // console.log(`[${action}] ${this.getType()} {${opts.subType ?? ''}}`);

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

            case 'open':
                this.open(data, sender, opts);
                break;

            case 'close':
                this.close(data, sender, opts);
                break;

            case 'switch':
                this.switch(data, sender, opts);
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
            switch (this.output.appendType) {
                case 'after':
                    sender.after(html);
                    break;

                case 'before':
                    sender.before(html);
                    break;

                default:
                    sender.append(html);
                    break;
            }
        }

        // render content, load and bind this element
        this.element = this.get();
        this.container = this.getContainer();
        this.setBaseAttributes();
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

    setBaseAttributes() {
        // add classes
        if (this.css.classes) {
            convertToArray(this.css.classes).forEach((c) => {
                this.addClass(c);
            });
        }

        // add styles
        if (this.css.styles) {
            Object.keys(this.css.styles).forEach((p) => {
                this.addStyle(p, this.css.styles[p]);
            });
        }

        // add attributes
        if (this.attributes) {
            Object.keys(this.attributes).forEach((p) => {
                this.addAttribute(p, this.attributes[p]);
            });
        }

        // add display
        if (this.css.display) {
            this.setDisplay(this.css.display);
        }

        // add margin
        if (this.css.margin) {
            this.setMargin(this.css.margin);
        }

        // add padding
        if (this.css.padding) {
            this.setPadding(this.css.padding);
        }

        // hide element
        if (!this.visible) {
            this.hide();
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

        var area = null;
        Object.keys(this.content).forEach((order) => {
            if (!this.content[order]) {
                return;
            }

            area = this.getContentArea(order);
            if (!area) {
                return;
            }

            this.render(data[this.content[order]], area, this, opts);
        });
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
        var senderToUse = null;

        content.forEach((item, index) => {
            if (sender && sender.length > 1) {
                senderToUse = this.filter(sender, (item) => {
                    if (item.attr('pode-min-index') <= index && item.attr('pode-max-index') >= index) {
                        return item;
                    }
                }, true);
            }
            else {
                senderToUse = sender;
            }

            opts.child = opts.child ?? {};
            opts.child.isLast = () => { return index == content.length - 1; };

            var result = PodeElementFactory.invokeClass(item.ObjectType, (item.Operation ?? 'new'), item, senderToUse, opts);
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

    serialize(element, checkGroup) {
        element = element ?? this.element;

        if (checkGroup) {
            var group = element.closest('.pode-element-group');
            if (group) {
                element = group;
            }
        }

        var data = null;
        var opts = {
            mimeType: 'multipart/form-data',
            contentType: false,
            processData: false
        };

        if (element.find('input[type=file]').length > 0) {
            data = newFormData(element.find('input, textarea, select'));
        }
        else {
            opts = {};

            if (this.checkParentType('form')) {
                data = element.serialize();
            }
            else {
                data = element.find('input, textarea, select').serialize();
            }
        }

        return {
            data: data,
            opts: opts ?? {}
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

    trigger(evt, asAjax) {
        if (asAjax) {
            var inputs = this.serialize(null, true);
            inputs.opts.keepFocus = true;
            sendAjaxReq(`${this.url}/events/${evt}`, inputs.data, this, true, null, null, inputs.opts);
        }
        else {
            this.element.trigger(evt);
        }
    }

    listen(element, evt, func, noPreventDefault) {
        element = element ?? this.element;
        if (!element) {
            return;
        }

        var obj = this;
        element.off(evt).on(evt, function(e) {
            if (!noPreventDefault) {
                e.preventDefault();
                e.stopPropagation();
            }

            func(e, $(this), obj);
        });
    }

    silence(element, evt) {
        element = element ?? this.element;
        if (!element) {
            return;
        }

        element.off(evt);
    }

    spinner(show) {
        if (!this.hasSpinner || (!show && this.loading)) {
            return;
        }

        var spinnerElement = $(`span.pode-spinner[for="${this.uuid}"]`);
        if (!spinnerElement) {
            return;
        }

        if (show) {
            spinnerElement.show();
        }
        else {
            spinnerElement.hide();
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
        if (data.UUID) {
            return data.UUID;
        }

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

        elements = convertToArray(elements);
        var result = [];

        if (elements.forEach) {
            elements.forEach((item) => {
                if (func(item)) {
                    result.push(item);
                }
            });
        }
        else {
            elements.each((_, item) => {
                item = $(item);
                if (func(item)) {
                    result.push(item);
                }
            })
        }

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

    getElement() {
        return this.element;
    }

    getContainer() {
        var obj = $(`[pode-container-for="${this.uuid}"]`);
        return obj && obj.length > 0 ? obj : undefined;
    }

    checkParentType(type) {
        return this.parent ? this.parent.getType() === type.toLowerCase() : false;
    }

    getContentArea(order) {
        return $(document).find(`[pode-content-for='${this.uuid}'][pode-content-order='${order}']`);
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

    setTitle(value) {
        if (value == null) {
            return;
        }

        this.element.attr('title', value);

        if (!this.title) {
            this.element.attr('data-toggle', 'tooltip');
            this.element.tooltip();
        }
        else {
            this.element.attr('data-original-title', value);
        }

        this.title = encodeAttribute(value);
    }

    reset(data, sender, opts) {
        this.element[0].reset();
    }

    submit(data, sender, opts) {
        this.trigger('click');
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
        (this.container ?? this.element).show();
        this.visible = true;
    }

    hide(data, sender, opts) {
        (this.container ?? this.element).hide();
        this.visible = false;
    }

    sync(data, sender, opts) {
        this.load(data, sender, opts);
    }

    addAttribute(name, value, sender, opts) {
        this.element.attr(name, value);
    }

    removeAttribute(name, sender, opts) {
        this.element.attr(name, null);
    }

    setDisplay(value, sender, opts) {
        this.addClass(`d-${value.toLowerCase()}`, sender, opts);
    }

    setMargin(value, sender, opts) {
        if (value.all >= 0) {
            this.addClass(`m-${value.all}`, sender, opts);
        }
        else {
            if (value.top >= 0) {
                this.addClass(`mt-${value.top}`, sender, opts);
            }

            if (value.bottom >= 0) {
                this.addClass(`mb-${value.bottom}`, sender, opts);
            }

            if (value.left >= 0) {
                this.addClass(`ml-${value.left}`, sender, opts);
            }

            if (value.right >= 0) {
                this.addClass(`mr-${value.right}`, sender, opts);
            }
        }
    }

    setPadding(value, sender, opts) {
        if (value.all >= 0) {
            this.addClass(`p-${value.all}`, sender, opts);
        }
        else {
            if (value.top >= 0) {
                this.addClass(`pt-${value.top}`, sender, opts);
            }

            if (value.bottom >= 0) {
                this.addClass(`pb-${value.bottom}`, sender, opts);
            }

            if (value.left >= 0) {
                this.addClass(`pl-${value.left}`, sender, opts);
            }

            if (value.right >= 0) {
                this.addClass(`pr-${value.right}`, sender, opts);
            }
        }
    }

    addStyle(name, value, sender, opts) {
        setElementStyle((this.container ?? this.element)[0], name, value, ((opts ?? {}).important === false));
    }

    removeStyle(name, sender, opts) {
        setElementStyle((this.container ?? this.element)[0], name);
    }

    addClass(clazz, sender, opts) {
        addClass((this.container ?? this.element), clazz);
    }

    removeClass(clazz, sender, opts) {
        removeClass((this.container ?? this.element), clazz, !((opts ?? {}).pattern ?? false));
    }

    replaceClass(oldClass, newClass, sender, opts) {
        var obj = (this.container ?? this.element);

        if (!hasClass(obj, newClass)) {
            removeClass(obj, oldClass, !((opts ?? {}).pattern ?? false));
            addClass(obj, newClass);
        }
    }

    toggleClass(clazz, state, sender, opts) {
        if (typeof (state) === 'string') {
            state = ({
                toggle: null,
                add: true,
                remove: false
            })[state.toLowerCase()];
        }

        var obj = (this.container ?? this.element);
        obj.toggleClass(clazz, state);
    }

    showValidation(message, sender, opts) {
        $(document).find(`[pode-validation-for='${this.uuid}']`).text(decodeHTML(message));
        setValidationError(this.element);
    }

    setHeight(value) {
        if (!value) {
            return;
        }

        this.addStyle('height', value, this, { important: false });
    }

    setWidth(value) {
        if (!value) {
            return;
        }

        this.addStyle('width', value, this, { important: false });
    }

    new(data, sender, opts) {
        throw `${this.getType()} "new" method not implemented`;
    }

    move(data, sender, opts) {
        throw `${this.getType()} "move" method not implemented`;
    }

    clear(data, sender, opts) {
        throw `${this.getType()} "clear" method not implemented`;
    }

    start(data, sender, opts) {
        throw `${this.getType()} "start" method not implemented`;
    }

    stop(data, sender, opts) {
        throw `${this.getType()} "stop" method not implemented`;
    }

    restart(data, sender, opts) {
        throw `${this.getType()} "restart" method not implemented`;
    }

    set(data, sender, opts) {
        throw `${this.getType()} "set" method not implemented`;
    }

    add(data, sender, opts) {
        throw `${this.getType()} "add" method not implemented`;
    }

    remove(data, sender, opts) {
        throw `${this.getType()} "remove" method not implemented`;
    }

    open(data, sender, opts) {
        throw `${this.getType()} "open" method not implemented`;
    }

    close(data, sender, opts) {
        throw `${this.getType()} "close" method not implemented`;
    }

    switch(data, sender, opts) {
        throw `${this.getType()} "switch" method not implemented`;
    }

    update(data, sender, opts) {
        // update icon
        if (this.icon && data.Icon) {
            if (typeof (data.Icon) === 'string') {
                this.icon.replace(data.Icon);
            }
            else {
                this.icon.update(data.Icon, sender, opts);
            }
        }
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
        super.update(data, sender, opts);

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
                this.move({ Direction: 'next' }, this);
            }, this.cycling.interval);
        }
    }

    move(data, sender, opts) {
        var obj = this.filter(this.children, (c) => {
            if (c.active) {
                return c;
            }
        }, true);

        if (obj) {
            if (data.Direction === 'previous') {
                obj.child.previous.open(data, sender, opts);
            }
            else {
                obj.child.next.open(data, sender, opts);
            }
        }
    }

    open(data, sender, opts) {
        this.children.forEach((c) => {
            c.open();
        });
    }

    close(data, sender, opts) {
        this.children.forEach((c) => {
            c.close();
        });
    }
}

class PodeCyclingChildElement extends PodeContentElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.active = this.child.isFirst;
    }

    open(data, sender, opts) {
        this.parent.children.forEach((c) => {
            if (c.uuid !== this.uuid) {
                c.close();
            }
        });

        this.active = true;
    }

    close(data, sender, opts) {
        this.active = false;
    }
}

class PodeRefreshableElement extends PodeTextualElement {
    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.hasSpinner = true;

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
                for='${this.uuid}'
                title='Refresh'
                data-toggle='tooltip'>
            </span>`;
        }

        // button
        return `<button
            type='button'
            class='btn btn-no-text btn-outline-secondary pode-action-btn pode-${this.getType()}-refresh pode-refresh-btn'
            for='${this.uuid}'
            title='Refresh'
            data-toggle='tooltip'>
                <span class='mdi mdi-refresh mdi-size-20'></span>
        </button>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // refresh click
        this.listen(this.element.find(`.pode-${this.getType()}-refresh`), 'click', function(e, target) {
            obj.tooltip(false, target);
            unfocus(target);
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

        this.autofocus = data.AutoFocus ?? false;
        this.dynamicLabel = data.DynamicLabel ?? false;
        this.validation = opts.validation ?? true;
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
        this.inForm = this.isInForm();
    }

    isInForm() {
        if (this.checkParentType('form') || this.checkParentType('step')) {
            return true;
        }

        if (this.checkParentType('modal') && this.parent.asForm) {
            return true;
        }

        return false;
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
                        class='col-sm-2 col-form-label ${this.label.asLegend ? 'float-sm-left pt-0' : ''}'>
                            ${data.DisplayName}
                    </${lblTag}>
                    ${html}`;
                }

                if (this.parent instanceof PodeForm) {
                    var formGroup = !this.inForm || this.dynamicLabel ? 'd-inline-block' : `form-group row`;
                    var divTag = this.asFieldset ? 'fieldset' : 'div';
                    var idProps = this.asFieldset ? `id='${this.id}' pode-object='${this.getType()}' pode-id='${this.uuid}'` : '';
                    var events = this.asFieldset ? this.events(data.Events) : '';
                    var width = this.inForm || !this.width ? '' : `width:${this.width}`;

                    html = `<${divTag}
                        class='pode-form-${this.getType()} ${formGroup}'
                        style='${width}'
                        ${idProps}
                        ${events}>
                            ${html}
                    </${divTag}>`;
                }

                // overload html from super
                if (!(this instanceof PodeButton) && !(this.parent instanceof PodeButtonGroup)) {
                    html = `<span pode-container-for='${this.uuid}'>${html}</span>`;
                }

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
        super.update(data, sender, opts);

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
            class='form-row'
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
        super.update(data, sender, opts);

        // skip if no sources/tracks
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
            class='badge badge-${data.ColourType} pode-text'
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
            this.replaceClass('badge-\\w+', `badge-${data.ColourType}`, null, { pattern: true });
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
            class='pode-text'
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

        return `<span pode-container-for='${this.uuid}'>${html}</span>`;
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
        this.hasSpinner = true;
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
            class="pode-spinner spinner-border spinner-border-sm"
            style="${colour}"
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
            href='${data.Url}'
            id='${this.id}'
            class="pode-text"
            target='${data.NewTab ? '_blank' : '_self'}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${this.events(data.Events)}>
                ${data.Value}
        </a>`;
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // update the url
        if (data.Url) {
            this.element.attr('href', data.Url);
        }

        // update target
        if (data.TabState != 'unchanged') {
            this.element.attr('target', data.TabState == 'newtab' ? '_blank' : '_self');
        }
    }
}
PodeElementFactory.setClass(PodeLink);

class PodeIcon extends PodeContentElement {
    static type = 'icon';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.setName(this.name);
        this.colour = (data.Colour ?? '').toLowerCase();
        this.size = data.Size ?? 0;
        this.flip = (data.Flip ?? '').toLowerCase();
        this.spin = data.Spin ?? false;
        this.rotate = data.Rotate ?? 0;
        this.icons = {
            base: data,
            toggle: (data.Icons ?? {}).Toggle,
            hover: (data.Icons ?? {}).Hover
        };
        this.state = 'base';
    }

    getName() {
        return this.name.startsWith('mdi-') ? this.name : `mdi-${this.name}`;
    }

    setName(name) {
        if (!name) {
            return;
        }

        name = name.toLowerCase();
        name = name.startsWith('mdi-') ? name : `mdi-${name}`
        this.name = encodeAttribute(name);
    }

    new(data, sender, opts) {
        var colour = this.colour ? `color:${this.colour};` : '';
        var title = this.title ? `title='${this.title}' data-toggle='tooltip'` : '';
        var size = this.size > 0 ? `mdi-size-${this.size}` : '';

        var spin = this.spin ? 'mdi-spin' : '';
        var flip = this.flip ? `mdi-flip-${this.flip[0]}` : '';
        var rotate = this.rotate > 0 ? `mdi-rotate-${this.rotate}` : '';

        return `<span
            id='${this.id}'
            class='mdi ${this.getName()} ${size} ${spin} ${flip} ${rotate}'
            style='${colour}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            ${title}
            ${this.events(data.Events)}>
        </span>`;
    }

    bind(data, sender, opts) {
        // icon or parent?
        var obj = this;
        if (this.parent && this.parent.icon && this.parent.icon.uuid === this.uuid) {
            obj = this.parent;
        }

        // is the icon wrapped in a top-level header?
        var ele = obj.element;

        var forObj = $(`[for='${obj.uuid}']`);
        if (forObj && forObj.length > 0) {
            ele = forObj;
        }

        // do we have a hover icon?
        if (this.icons.hover) {
            // add mouseover
            obj.listen(ele, 'mouseover', function(e, target, sender) {
                (sender.icon ?? sender).switch({ State: 'hover' }, sender, null);
            });

            // add mouseout
            obj.listen(ele, 'mouseout', function(e, target, sender) {
                (sender.icon ?? sender).switch({ State: 'base' }, sender, null);
            });
        }
        else {
            // remove mouseover/out
            obj.silence(ele, 'mouseover');
            obj.silence(ele, 'mouseout');
        }
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // update name
        if (data.Name) {
            this.replace(data.Name);
        }

        // update title
        this.setTitle(data.Title);

        // update colour
        if (data.Colour != null) {
            this.colour = data.Colour.toLowerCase();

            if (this.colour === '') {
                this.removeStyle('color', this);
            }
            else {
                this.addStyle('color', this.colour, this, { important: false });
            }
        }

        // update flip
        if (data.Flip != '') {
            var newFlip = data.Flip;

            if (data.Flip == null) {
                this.removeClass(`mdi-flip-\\w+`, this, { pattern: true });
            }
            else {
                newFlip = newFlip.toLowerCase();
                this.replaceClass(`mdi-flip-\\w+`, `mdi-flip-${newFlip[0]}`, this, { pattern: true });
            }

            this.flip = newFlip;
        }

        // update rotation
        if (data.Rotate || data.Rotate > -1) {
            if (data.Rotate === 0) {
                this.removeClass(`mdi-rotate-\\w+`, this, { pattern: true });
            }
            else {
                this.replaceClass(`mdi-rotate-\\w+`, `mdi-rotate-${data.Rotate}`, this, { pattern: true });
            }

            this.rotate = data.Rotate;
        }

        // update size
        if (data.Size || data.Size > -1) {
            if (data.Size === 0) {
                this.removeClass(`mdi-size-\\w+`, this, { pattern: true });
            }
            else {
                this.replaceClass(`mdi-size-\\w+`, `mdi-size-${data.Size}`, this, { pattern: true });
            }

            this.size = data.Size;
        }

        // update spin
        if (data.Spin != null) {
            this.toggleClass('mdi-spin', data.Spin, this);
        }

        // update toggle icon
        if (data.Icons) {
            if (data.Icons.Toggle != null) {
                this.icons.toggle = Object.keys(data.Icons.Toggle).length > 0 ? data.Icons.Toggle : null;
            }

            // update hover icon
            if (data.Icons.Hover != null) {
                this.icons.hover = Object.keys(data.Icons.Hover).length > 0 ? data.Icons.Hover : null;
                this.bind(data, sender, opts);
            }
        }
    }

    switch(data, sender, opts) {
        data.State = data.State.toLowerCase();
        if (this.state === data.State) {
            return;
        }

        switch (data.State) {
            case 'default':
                this.toggle(sender, opts);
                break;

            default:
                this.update(this.icons[data.State], sender, opts);
                this.state = data.State;
                break;
        }
    }

    replace(name, title) {
        if (!name) {
            return;
        }

        // replace
        name = name.toLowerCase();
        name = name.startsWith('mdi-') ? name : `mdi-${name}`;

        if (this.getName() !== name) {
            this.replaceClass(this.getName(), name);
            this.setName(name);
        }

        // replace title
        this.setTitle(title);
    }

    toggle(sender, opts) {
        this.switch({ State: this.state === 'base' ? 'toggle' : 'base' }, (sender ?? this), opts);
    }
}
PodeElementFactory.setClass(PodeIcon);

class PodeButtonGroup extends PodeContentElement {
    static type = 'button-group';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.content[0] = 'Buttons';
        this.direction = (data.Direction ?? 'horizontal').toLowerCase();
    }

    new(data, sender, opts) {
        var dirClass = this.direction == 'horizontal' ? 'btn-group' : 'btn-group-vertical'
        return `<div
            id='${this.id}'
            class="${dirClass} ${data.SizeType} mr-2"
            role="group"
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            pode-content-for="${this.uuid}"
            pode-content-order='0'>
        </div>`
    }
}
PodeElementFactory.setClass(PodeButtonGroup);

class PodeButton extends PodeFormElement {
    static type = 'button';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.iconOnly = data.IconOnly;
        this.validation = false;
        this.label.enabled = false;
        this.hasSpinner = true;
        this.displayName = data.DisplayName ?? '';
        this.clickName = data.ClickName ?? '';
    }

    new(data, sender, opts) {
        var newLine = data.NewLine ? '<br/>' : '';

        var icon = this.setIcon(data.Icon, true);
        var html = '';

        if (this.iconOnly) {
            if (this.dynamic) {
                html = `<button
                    type='button'
                    class='btn btn-icon-only pode-button'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    title='${this.displayName}'
                    data-toggle='tooltip'
                    pode-object='${this.getType()}'
                    pode-id='${this.uuid}'>
                        ${icon}
                </button>`;
            }
            else {
                html = `<a
                    role='button'
                    class='btn btn-icon-only pode-link-button'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    title='${this.displayName}'
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
                    class='btn btn-${colour} ${data.SizeType} pode-button'
                    id='${this.id}'
                    name='${this.name}'
                    pode-data-value='${data.DataValue}'
                    pode-object='${this.getType()}'
                    pode-colour='${data.ColourType}'
                    pode-id='${this.uuid}'>
                        <span for='${this.uuid}' class='pode-spinner spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
                        ${icon}
                        <span class='pode-text'>${this.displayName}</span>
                </button>`;
            }
            else {
                html = `<a
                    role='button'
                    class='btn btn-${colour} ${data.SizeType} pode-link-button'
                    id='${this.id}'
                    name='${this.name}'
                    href='${data.Url}'
                    target='${data.NewTab ? '_blank' : '_self'}'
                    pode-data-value='${data.DataValue}'
                    pode-object='${this.getType()}'
                    pode-colour='${data.ColourType}'
                    pode-id='${this.uuid}'>
                        ${icon}
                        <span class='pode-text'>${this.displayName}</span>
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

        // bind click if dynamic
        if (this.dynamic) {
            this.listen(this.element, 'click', function(e, target, sender) {
                // hide tooltip
                sender.tooltip(false);
                var inputs = {};

                // find group
                var group = sender.element.closest('.pode-element-group');
                if (group && group.length > 0) {
                    inputs = sender.serialize(group);
                }

                // find a form, if no group found
                if (!group || group.length == 0) {
                    var form = sender.element.closest('form');
                    if (form && form.length > 0) {
                        inputs = sender.serialize(form);
                    }
                }

                // get a data value
                var dataValue = getDataValue(sender.element);
                if (dataValue) {
                    inputs.data = addFormDataValue(inputs.data, 'Value', dataValue);
                }

                // invoke url
                sendAjaxReq(`${sender.url}/click`, inputs.data, sender, true, null, null, inputs.opts, $(e.currentTarget));
            });
        }
    }

    spinner(show) {
        super.spinner(show);

        // skip if no click name
        if (!this.clickName) {
            return;
        }

        // display name, or click name?
        var name = show ? this.clickName : this.displayName;

        // render name
        if (this.iconOnly) {
            this.setTitle(name);
        }
        else {
            this.element.find('span.pode-text').text(decodeHTML(name));
        }
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // update display name
        if (data.DisplayName) {
            this.displayName = data.DisplayName;

            if (this.iconOnly) {
                this.setTitle(this.displayName);
            }
            else {
                this.element.find('span.pode-text').text(decodeHTML(this.displayName));
            }
        }

        // update click name
        if (data.ClickName) {
            this.clickName = data.ClickName;
        }

        // change colour
        if (!this.iconOnly && (data.Colour || data.ColourState != 'unchanged')) {
            var isOutline = hasClass(this.element, 'btn-outline-\\w+');
            var colour = this.element.attr('pode-colour');

            var _class = isOutline ? `btn-outline-${colour}` : `btn-${colour}`;
            this.removeClass(_class);

            if (data.ColourState != 'unchanged') {
                isOutline = (data.ColourState == 'outline');
            }

            if (data.Colour) {
                colour = data.ColourType;
                this.element.attr('pode-colour', colour);
            }

            _class = isOutline ? `btn-outline-${colour}` : `btn-${colour}`;
            this.addClass(_class);
        }

        // change size
        if (!this.iconOnly && (data.Size || data.SizeState != 'unchanged')) {
            if (data.SizeState != 'unchanged') {
                if (data.SizeState == 'normal') {
                    this.removeClass('btn-block');
                }
                else {
                    this.addClass('btn-block');
                }
            }

            if (data.Size) {
                this.replaceClass('btn-(sm|lg)', data.SizeType, null, { pattern: true });
            }
        }

        // change url
        if (!this.dynamic && data.Url) {
            this.element.attr('href', data.Url);
        }

        // change data value
        if (data.DataValue) {
            this.element.attr('pode-data-value', data.DataValue);
        }

        // change tab state
        if (!this.dynamic && data.TabState != 'unchanged') {
            this.element.attr('target', data.TabState == 'newtab' ? '_blank' : '_self');
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
            class="container pode-container"
            pode-object="${this.getType()}"
            pode-transparent="${data.NoBackground}"
            pode-hidden="${data.Hide}"
            pode-id='${this.uuid}'>
                <div pode-content-for='${this.uuid}' pode-content-order='0'></div>
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
        this.hasSpinner = true;
    }

    new(data, sender, opts) {
        var resetBtn = !this.showReset ? '' : `<button
            class='btn pode-inbuilt-secondary-theme form-reset'
            for='${this.id}'
            type='button'>
                ${data.ResetText}
        </button>`;

        var html = `<form
            id="${this.id}"
            name="${this.name}"
            class="pode-form"
            method="${this.method}"
            action="${this.action}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <div pode-content-for='${this.uuid}' pode-content-order='0'></div>

                <button class="btn pode-inbuilt-primary-theme" type="submit">
                    <span for='${this.uuid}' class="pode-spinner spinner-border spinner-border-sm" role="status" aria-hidden="true" style="display: none"></span>
                    ${data.SubmitText}
                </button>

                ${resetBtn}
        </form>`;

        if (data.Message) {
            html += `<p class='card-text' pode-container-for='${this.uuid}'>${data.Message}</p>`;
        }

        return html;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // submit form
        this.listen(this.element, 'submit', function(e, target) {
            var result = obj.serialize();
            sendAjaxReq(obj.action, result.data, obj, true, null, null, result.opts, obj.getSubmitButton());
        });

        // reset form
        if (this.showReset) {
            this.listen(this.element.find('.form-reset'), 'click', function(e, target) {
                obj.reset();
                unfocus(target);
            });
        }
    }

    submit(data, sender, opts) {
        this.getSubmitButton().trigger('click');
    }

    getSubmitButton() {
        return $(this.element[0]).find('[type="submit"]');
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

        var icon = this.setIcon(data.Icon, false, false, { ephemeral: true });

        toastArea.append(`
            <div pode-id="${this.uuid}" class="toast" role="alert" aria-live="assertive" aria-atomic="true" data-delay="${data.Duration}">
                <div class="toast-header">
                    ${icon}
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

        if (this.icon) {
            this.refresh(null, true);
            this.icon.refresh(null, true);
            this.icon.bind();
        }

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
                icon: data.IconUrl
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
        this.content[1] = 'Buttons';
    }

    new(data, sender, opts) {
        var header = '';
        if ((!data.NoTitle && this.name) || !data.NoHide || data.Buttons) {
            var icon = this.setIcon(data.Icon, true);
            var title = data.NoTitle ? `${icon}` : `${icon}${data.DisplayName}`;

            var hideBtn = data.NoHide ? '' : `<div class='btn-group ml-2'>
                <button type='button' class='btn btn-no-text btn-outline-secondary pode-action-btn pode-card-collapse'>
                    <span class='mdi mdi-eye-outline mdi-size-20' title='Hide' data-toggle='tooltip'></span>
                </button>
            </div>`;

            var btns = `<div class='btn-toolbar mb-2 mb-md-0 mTop-05'>
                <span pode-content-for='${this.uuid}' pode-content-order='1'></span>
                ${hideBtn}
            </div>`;

            header = `<div
                class='card-header d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 border-bottom'
                for='${this.uuid}'>
                    <h5>${title}</h5>
                    ${btns}
            </div>`;
        }

        return `<div
            id="${this.id}"
            class="card pode-card"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                ${header}
                <div pode-content-for='${this.uuid}' pode-content-order='0' class="card-body"></div>
        </div>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);

        this.listen(this.element.find('.pode-card-collapse'), 'click', function(e, target) {
            toggleIcon(target, 'eye-outline', 'eye-off-outline', 'Hide', 'Show');
            target.closest('.card').find('.card-body').slideToggle();
            unfocus(target);
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
            class="alert alert-${data.ClassType}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'
            role="alert"
            ${this.events(data.Events)}>
                <h6 class='pode-alert-header'>
                    <span class="mdi mdi-${data.IconType.toLowerCase()}"></span>
                    <strong>${data.Type}</strong>
                </h6>
                <div pode-content-for='${this.uuid}' pode-content-order='0' class='pode-alert-body pode-text'>
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

        this.exportable = {
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

        var exportBtn = !this.exportable.enabled ? '' : `<button type='button' class='btn btn-no-text btn-outline-secondary pode-action-btn pode-table-export' for='${this.id}' title='Export' data-toggle='tooltip'>
            <span class='mdi mdi-download mdi-size-20'></span>
        </button>`;

        var customBtns = '';
        convertToArray(data.Buttons).forEach((btn) => {
            customBtns += `<button type='button' class='btn btn-no-text btn-outline-secondary pode-action-btn pode-table-button' for='${this.id}' title='${btn.Name}' data-toggle='tooltip' name='${btn.Name}'>
                <span class='mdi mdi-${btn.Icon.toLowerCase()} mdi-size-20 ${btn.WithText ? "mRight02" : ''}'></span>
                ${btn.WithText ? btn.DisplayName : ''}
            </button>`;
        });

        return `<span pode-container-for='${this.uuid}'>
            ${msg}
            <div
                id='${this.id}'
                name='${this.name}'
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
                            <span for='${this.uuid}' class='pode-spinner spinner-grow pode-inbuilt-secondary-theme' role='status' style='display: none'></span>
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
            </div>
        </span>`;
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
            if (data.Data) {
                this.update(data, sender, opts);
            }

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
        var url = `${this.url}/data`;

        if (this.element.attr('for')) {
            var form = $(`#${this.element.attr('for')}`);
            if (query) {
                query += '&';
            }

            query += form.serialize();
            url = form.attr('action');
        }

        // invoke and load table content
        sendAjaxReq(url, query, this, true, () => { this.loading = false; }, null, { successCallbackBefore: true });
        this.loading = true;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // export
        if (this.exportable.enabled) {
            this.listen(this.element.find('.pode-table-export'), 'click', function(e, target) {
                obj.tooltip(false, target);
                obj.download();
            });
        }

        // sort
        if (this.sort.enabled) {
            this.listen(this.element.find('table thead th'), 'click', function(e, target) {
                // what direction to sort?
                var direction = ({
                    none: 'asc',
                    asc: 'desc',
                    desc: 'asc'
                })[(target.attr('pode-direction') ?? 'none')];

                obj.element.find('table thead th').attr('sort-direction', 'none');
                target.attr('sort-direction', direction);

                // simple or dynamic sorting?
                if (obj.sort.simple) {
                    var rows = obj.element.find('table tr:gt(0)').toArray().sort(comparer(target.index()));
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
                            column: target.text(),
                            direction: direction
                        }
                    });
                }
            });
        }

        // filter
        if (this.filter.enabled) {
            this.listen(this.element.find("input.pode-table-filter"), 'keyup', delay(function(e, target) {
                e.preventDefault();
                e.stopPropagation();

                if (obj.filter.simple) {
                    obj.filterRows();
                }
                else {
                    obj.load();
                }
            }, 500), true);
        }

        // clickable rows
        if (this.clickableRows) {
            this.listen(this.element.find('tbody tr'), 'click', function(e, target) {
                var rowId = target.attr('pode-data-value');

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
            this.listen(this.element.find('nav[role="pagination"] input.page-size'), 'keyup', function(e, target) {
                var pageNav = target.closest('nav');

                // on enter, reload table
                if (isEnterKey(e)) {
                    unfocus(target);
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
                    pageNav.attr('pode-page-size', target.val());
                }
            });

            this.listen(this.element.find('nav[role="pagination"] .pagination a.page-link'), 'click', function(e, target) {
                obj.tooltip(false, target);

                // if active/disabled, do nothing
                if (target.hasClass('active') || target.hasClass('disabled')) {
                    return;
                }

                // get page size
                var pageNav = target.closest('nav');
                var pageSize = pageNav.attr('pode-page-size') ?? 20;

                // next or previous? - get current +/-
                var pageIndex = 1;

                if (target.hasClass('page-arrows')) {
                    pageIndex = target.closest('ul').find('a.page-link.active').text();

                    if (target.hasClass('page-previous')) {
                        pageIndex--;
                    }
                    else if (target.hasClass('page-next')) {
                        pageIndex++;
                    }
                    else if (target.hasClass('page-first')) {
                        pageIndex = 1;
                    }
                    else if (target.hasClass('page-last')) {
                        pageIndex = target.attr('pode-max');
                    }
                }
                else {
                    pageIndex = target.text();
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
        this.listen(this.element.find('.pode-table-button'), 'click', function(e, target) {
            obj.tooltip(false, target);
            var url = `${obj.url}/button/${target.attr('name')}`;
            sendAjaxReq(url, obj.export(), obj, true, null, null, { contentType: 'text/csv' }, $(e.currentTarget));
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
                e.finalise(null, rowData, sender, true, opts);
            });
        }

        // update the row's background colour
        setElementStyle(row[0], 'background-color', data.BackgroundColour);

        // update the row's forecolour
        setElementStyle(row[0], 'color', data.Colour);

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
            this.element.attr('for', sender.attr('id'));
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
                    convertToArray(renderResult.elements).forEach((e) => {
                        elements.push({
                            key: key,
                            item: e
                        });
                    });
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
                e.item.finalise(null, item[e.key], sender, true, opts);
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
        this.content[0] = 'Bellows'
        this.mode = data.Mode.toLowerCase()
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="accordion"
            name='${this.name}'
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <div pode-content-for='${this.uuid}' pode-content-order='0'></div>
        </div>`;
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
            class='card bellow'
            name='${this.name}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <div class='card-header bellow-header' id='${this.id}_header' for='${this.uuid}'>
                    <h2 class='mb-0'>
                        <button class='btn btn-link btn-block text-left ${collapsed}' type='button' data-toggle='collapse' data-target='#${this.id}_body' aria-expanded='${expanded}' aria-controls='${this.id}_body'>
                            ${icon}
                            ${data.DisplayName}
                            <span class='mdi mdi-chevron-${arrow} arrow-toggle'></span>
                        </button>
                    </h2>
                </div>

                <div id='${this.id}_body' class='bellow-body collapse ${show}' aria-labelledby='${this.id}_header' data-parent='#${this.parent.id}'>
                    <div pode-content-for='${this.uuid}' pode-content-order='0' class='card-body'></div>
                </div>
        </div>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // collapse buttons
        this.listen(this.element.find('.bellow-body.collapse'), 'hide.bs.collapse', function(e, target) {
            var icon = obj.element.find('span.arrow-toggle');
            toggleIcon(icon, 'chevron-down', 'chevron-up');
            obj.active = false;
        }, true);

        this.listen(this.element.find('.bellow-body.collapse'), 'show.bs.collapse', function(e, target) {
            var icon = obj.element.find('span.arrow-toggle');
            toggleIcon(icon, 'chevron-up', 'chevron-down');
            obj.active = true;
        }, true);
    }

    open(data, sender, opts) {
        if (!this.active) {
            this.get().find('div.bellow-header button').trigger('click');
        }

        super.open(data, sender, opts);
    }

    close(data, sender, opts) {
        if (this.active) {
            this.get().find('div.bellow-header button').trigger('click');
        }

        super.close(data, sender, opts);
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
            class="text-${data.Alignment}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <span pode-content-for='${this.uuid}' pode-content-order='0' class='pode-text'>
                    ${data.Value ? data.Value : ''}
                </span>
        </p>`;
    }
}
PodeElementFactory.setClass(PodeParagraph);

class PodeHeader extends PodeTextualElement {
    static type = 'header';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.size = data.Size ?? 1;
    }

    new(data, sender, opts) {
        var subHeader = data.Secondary ? `<small class='text-muted'>${data.Secondary}</small>` : '';
        var icon = this.setIcon(data.Icon);

        return `<span
            id='${this.id}'
            class='h${this.size} header d-block'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                ${icon}
                <span pode-content-for='${this.uuid}' pode-content-order='0' class='pode-text'>
                    ${data.Value}
                </span>
                ${subHeader}
        </span>`;
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // update size
        if (data.Size && data.Size > 0) {
            this.replaceClass(`h${this.size}`, `h${data.Size}`);
            this.size = data.Size;
        }
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
        var placeholder = data.Placeholder ? `placeholder='${encodeAttribute(data.Placeholder)}'` : '';
        var events = this.events(data.Events);

        // multiline textbox
        if (this.multiline) {
            html = `<textarea
                class='form-control'
                id='${this.id}'
                name='${this.name}'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'
                rows='${data.Size}'
                style='${width}'
                ${placeholder}
                ${autofocus}
                ${events}
                ${maxLength}></textarea>`;
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
                style='${width}'
                ${placeholder}
                ${autofocus}
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
            sendAjaxReq(`${this.url}/autocomplete`, null, null, false, null, null, {
                customActionCallback: (res) => {
                    obj.element.autocomplete({ source: res.Values });
                }
            });
        }
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // update value
        if (data.Value) {
            if (data.AsJson) {
                data.Value = data.JsonInline || !this.multiline
                    ? JSON.stringify(data.Value)
                    : JSON.stringify(data.Value, null, 4);
            }

            this.element.val(data.Value);
        }

        // resize textbox rows
        if (this.multiline && data.Size) {
            this.element.attr('rows', data.Size);
        }
    }

    clear(data, sender, opts) {
        this.element.val('');
    }
}
PodeElementFactory.setClass(PodeTextbox);

class PodeFileUpload extends PodeFormElement {
    static type = 'file-upload';

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<div class='custom-file' pode-container-for='${this.uuid}'>
            <input
                type='file'
                class="custom-file-input"
                id="$${this.id}"
                name="${this.name}"
                pode-object="${this.getType()}"
                pode-id='${this.uuid}'
                accept="${data.Accept}">
            <label class='custom-file-label' for='${this.id}'>Choose file</label>
        </div>`;
    }

    bind(data, sender, opts) {
        this.listen(this.element, 'change', function(e, target) {
            var fileName = target.val().split("\\").pop();
            target.siblings('.custom-file-label').addClass('selected').html(fileName);
        }, true);
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
            style="width:${data.Width}"
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
            style="width:${data.Width};height:${data.Height}"
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
        super.update(data, sender, opts);

        if (data.Thumbnail) {
            this.element.attr('thumbnail', data.Thumbnail);
        }
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
            class='code-block ${data.Scrollable ? 'pre-scrollable' : ''}'
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

        this.listen(this.element.find('.pode-code-copy'), 'click', function(e, target) {
            obj.tooltip(false, target);
            var value = obj.element.find('code').text().trim();
            navigator.clipboard.writeText(value);
        }, true);
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
            class="pode-text"
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
            class='blockquote text-${data.Alignment}'
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
            name="${this.name}"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
        </iframe>`;
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

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
            class="my-4"
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
            id='${this.id}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
            ${data.Value}
        </span>`;
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);
        this.element.html(data.Value);
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
            name='${this.name}'
            class="hide pode-timer"
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
        sendAjaxReq(`${this.url}/trigger`, null, null, true);
    }
}
PodeElementFactory.setClass(PodeTimer);

class PodeImage extends PodeContentElement {
    static type = 'image';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.source = data.Source;
    }

    new(data, sender, opts) {
        var fluid = data.Height === 'auto' || data.Width === 'auto' ? 'img-fluid' : '';
        var title = this.title ? `title='${this.title}' data-toggle='tooltip'` : '';

        var location = ({
            left: 'float-left',
            right: 'float-right',
            center: 'mx-auto d-block'
        })[data.Alignment];

        return `<img
            src='${this.source}'
            id='${this.id}'
            class='${fluid} rounded ${location}'
            style='height:${data.Height};width:${data.Width}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            data-placement='bottom'
            ${title}
            ${this.events(data.Events)}>`;
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // update source
        if (data.Source) {
            this.element.attr('src', data.Source);
            this.source = data.Source;
        }

        // update title
        this.setTitle(data.Title);

        // update height
        this.setHeight(data.Height);

        // update width
        this.setWidth(data.Width);
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
            class="media"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'>
                <img src="${data.AvatarUrl}" class="align-self-start mr-3" alt="${data.Username} icon">
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
        var content = data.Content ? `<hr class='my-4'><div pode-content-for='${this.uuid}' pode-content-order='0'></div>` : '';

        return `<div
            id="${this.id}"
            class="jumbotron"
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
        var contentId = this.dynamic ? '' : `pode-content-for='${this.uuid}' pode-content-order='0'`;

        return `<div
            id="${this.id}"
            class="container pode-tile alert-${data.ColourType} rounded"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'
            name="${this.name}">
                <h6 class="pode-tile-header" for='${this.uuid}'>
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
            sendAjaxReq(`${this.url}/data`, null, this, true);
        }

        // if not dynamic, and fully created, click refresh buttons of sub-elements
        else if (this.created) {
            this.element.find('.pode-tile-body .pode-refresh-btn').each((i, e) => {
                PodeElementFactory.getObject($(e).attr('for')).load();
            });
        }
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        // is the tile clickable?
        if (this.clickable) {
            this.listen(this.element, 'click', function(e, target) {
                sendAjaxReq(`${obj.url}/click`, null, obj, true);
            });
        }

        // hide sub-element refresh buttons
        this.element.find('.pode-tile-body .pode-refresh-btn').each((i, e) => {
            $(e).hide();
        });
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        /// update the colour
        if (data.Colour) {
            this.replaceClass('alert-\\w+', `alert-${data.ColourType}`, null, { pattern: true });
        }
    }
}
PodeElementFactory.setClass(PodeTile);

class PodeGrid extends PodeContentElement {
    static type = 'grid';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.content[0] = 'Cells';
        this.cells = convertToArray(data.Cells).length;
        this.width = data.Width === 0 ? this.cells : (data.Width ?? this.cells);
        this.rows = Math.ceil(this.cells / this.width);
    }

    new(data, sender, opts) {
        var rows = '';
        for (var i = 1; i <= this.rows; i++) {
            rows += `<div
                pode-content-for='${this.uuid}'
                pode-content-order='0'
                pode-min-index='${this.width * (i - 1)}'
                pode-max-index='${(this.width * i) - 1}'
                class='row'>
            </div>`;
        }

        return `<div
            id="${this.id}"
            class="container pode-grid"
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
            class='text-${data.Alignment} ${width}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <div pode-content-for='${this.uuid}' pode-content-order='0'></div>
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
        this.content[0] = 'Tabs';
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <ul class="nav nav-tabs" role="tablist"></ul>
                <div class='tab-content' pode-content-for='${this.uuid}' pode-content-order='0'></div>
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
                for='${element.uuid}'
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
            class='tab-pane fade show ${this.child.isFirst ? 'active' : ''}'
            pode-object="${this.getType()}"
            pode-id="${this.uuid}"
            role='tabpanel'
            aria-labelledby='${this.id}'>
                <div pode-content-for='${this.uuid}' pode-content-order='0'></div>
        </div>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        var obj = this;

        this.listen(this.parent.element.find(`a.nav-link[data-toggle='tab'][for='${this.uuid}']`), 'hide.bs.tab', function(e, target) {
            obj.active = false;
            unfocus($(e.target));
        }, true);

        this.listen(this.parent.element.find(`a.nav-link[data-toggle='tab'][for='${this.uuid}']`), 'show.bs.tab', function(e, target) {
            obj.active = true;
        }, true);
    }

    open(data, sender, opts) {
        if (!this.active) {
            this.parent.element.find(`.nav-link#${this.id}`).trigger('click');
        }

        super.open(data, sender, opts);
    }
}
PodeElementFactory.setClass(PodeTab);

class PodeCarousel extends PodeCyclingElement {
    static type = 'carousel';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.content[0] = 'Slides';
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="carousel slide"
            data-ride="carousel"
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <ol class="carousel-indicators"></ol>
                <div class="carousel-inner" pode-content-for='${this.uuid}' pode-content-order='0'></div>

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
            class='carousel-item ${this.child.isFirst ? 'active' : ''}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <div class='d-flex w-100 h-100' pode-content-for='${this.uuid}' pode-content-order='0'></div>
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
        this.language = (data.Language ?? 'plaintext').toLowerCase();
        this.uploadable = data.Uploadable ?? false;
        this.theme = (data.Theme ?? '').toLowerCase();
        this.value = data.Value ?? '';
        this.editor = null;
    }

    new(data, sender, opts) {
        var upload = !this.uploadable ? '' : `<button
            class='btn pode-inbuilt-primary-theme pode-upload mBottom1'
            type='button'
            title='Upload'
            data-toggle='tooltip'
            for='${this.id}'>
                <span class='mdi mdi-upload mRight02'></span>
        </button>`;

        return `<div
            id="${this.id}"
            name="${this.name}"
            class="pode-code-editor"
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
        require.config({ paths: { 'vs': src.substring(0, src.lastIndexOf('/')) } });

        // create the editors
        require(["vs/editor/editor.main"], function() {
            if (!obj.theme) {
                obj.theme = getCssVariable('--podeweb-code-editor-theme');
            }

            var theme = ({
                dark: 'vs-dark',
                light: 'vs',
                highcontrast: 'hc-black'
            })[obj.theme] ?? 'vs';

            obj.editor = monaco.editor.create(obj.element.find('.code-editor')[0], {
                value: obj.value,
                language: obj.language,
                theme: theme,
                readOnly: obj.readonly,
                automaticLayout: true
            });

            obj.value = '';
        });

        // bind upload buttons
        if (this.uploadable) {
            this.listen(this.element.find('.pode-upload'), 'click', function(e, target) {
                var data = JSON.stringify({
                    language: obj.language,
                    value: obj.editor.getValue()
                });

                sendAjaxReq(`${obj.url}/upload`, data, null, true, null, null, {
                    contentType: 'application/json; charset=UTF-8'
                }, $(e.currentTarget));
            });
        }
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

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
        var width = data.Width !== 'auto' ? `width:${data.Width};` : '';

        return `${message}<div
            id="${this.id}"
            name="${this.name}"
            class="w-100"
            role='chart'
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <div role='controls'>
                    <div class="btn-group mr-2">
                        ${this.buildRefreshButton(false)}
                    </div>
                </div>
                <canvas class="my-4" style="${height}${width}"></canvas>
                <div class="text-center">
                    <span for='${this.uuid}' class="pode-spinner spinner-grow pode-inbuilt-secondary-theme canvas-spinner" role="status"></span>
                </div>
        </div>`;
    }

    load(data, sender, opts) {
        if (!this.dynamic) {
            if (data.Data) {
                this.update(data, sender, opts);
            }

            return;
        }

        super.load(data, sender, opts);

        // is this the chart's first load?
        var data = !this.created || !this.appendData ? 'FirstLoad=1' : '';

        // things get funky here if we have a chart with a 'for' attr
        // if so, we need to serialize the form, and then send the request to the form instead
        var url = `${this.url}/data`;

        if (this.element.attr('for')) {
            var form = $(`#${this.element.attr('for')}`);
            if (data) {
                data += '&';
            }

            data += form.serialize();
            url = form.attr('action');
        }

        // invoke and load chart content
        sendAjaxReq(url, data, this, true, () => { this.loading = false; }, null, { successCallbackBefore: true });
        this.loading = true;
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // convert chart data points to array
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
        if (getTagName(sender) === 'form') {
            this.element.attr('for', sender.attr('id'));
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
            x: null,
            y: null
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
                },

                responsive: false,
                maintainAspectRatio: true
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
            class='btn pode-inbuilt-primary-theme pode-modal-submit'>
                ${data.SubmitText}
        </button>`;

        var contentArea = this.asForm
            ? `<form class='pode-form' method='${data.Method}' action='${data.Action}' for='${this.uuid}' pode-content-for='${this.uuid}' pode-content-order='0'>`
            : `<div pode-content-for='${this.uuid}' pode-content-order='0'></div>`;

        return `<div
            id="${this.id}"
            class="modal fade"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}"
            name="${this.name}"
            tabindex="-1"
            aria-labelledby="${this.id}_lbl"
            aria-hidden="true"
            pode-data-value="">
                <div class="modal-dialog modal-dialog-scrollable pode-modal-${data.Size.toLowerCase()}">
                    <div class="modal-content">
                        <div class="modal-header" for='${this.uuid}'>
                            <h5 class="modal-title" id="${this.id}_lbl">
                                ${icon}
                                ${data.DisplayName}
                            </h5>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            ${contentArea}
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
            this.listen(this.element.find("div.modal-content form.pode-form"), 'keypress', function(e, target) {
                if (!isEnterKey(e)) {
                    return;
                }

                e.preventDefault();
                e.stopPropagation();

                var btn = obj.element.find('div.modal-footer button.pode-modal-submit')
                if (btn) {
                    btn.trigger('click');
                }
            }, true);

            this.listen(this.element.find("div.modal-footer button.pode-modal-submit"), 'click', function(e, target) {
                // get url
                var url = obj.submit.url;
                if (!obj.submit.url) {
                    return;
                }

                // find a form
                var inputs = {};
                var method = 'post';

                if (obj.asForm) {
                    var form = obj.getElement();

                    var action = form.attr('action');
                    if (action) {
                        url = action;
                    }

                    var _method = form.attr('method');
                    if (_method) {
                        method = _method;
                    }

                    inputs = obj.serialize(form);
                    removeValidationErrors(form);
                }

                // get a data value
                var dataValue = getDataValue(target);

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
                sendAjaxReq(url, inputs.data, obj, true, null, null, inputs.opts, $(e.currentTarget));
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

    getElement() {
        var ele = super.getElement();
        return this.asForm
            ? ele.find('div.modal-body form')
            : ele;
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
        this.content[0] = 'Items';
    }

    new(data, sender, opts) {
        var listTag = data.Numbered ? 'ol' : 'ul';

        data.Values = convertToArray(data.Values);
        data.Items = convertToArray(data.Items);

        var content = '';
        if (data.Items.length > 0) {
            content = `<span pode-content-for='${this.uuid}' pode-content-order='0'></span>`
        }
        else {
            data.Values.forEach((v) => {
                content += `<li>${v}</li>`;
            });
        }

        return `<${listTag}
            id='${this.id}'
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
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'>
                <span pode-content-for='${this.uuid}' pode-content-order='0'></span>
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
            class="form-control"
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
                ${selectedValue.includes(opt) ? 'selected' : ''}>
                    ${data.DisplayOptions[index]}
            </option>`;
        });

        return `<select
            id='${this.id}'
            class='custom-select'
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
            sendAjaxReq(`${this.url}/options`, null, this, true);
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
                    ${data.SelectedValue.includes(opt) ? 'selected' : ''}>
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

        return `<span class='range-wrapper' for='${this.id}' pode-container-for='${this.uuid}'>
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

            this.listen(this.element, 'change', function(e, target) {
                valElement.val(obj.element.val());
            }, true);

            this.listen(valElement, 'change', function(e, target) {
                obj.element.val(valElement.val());
            }, true);
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

        var html = `<div class='progress'>
                <div
                    id='${this.id}'
                    name='${this.name}'
                    class='progress-bar bg-${data.ColourType ?? 'primary'} ${showValue} ${striped} ${animated}'
                    role='progressbar'
                    style='width: ${data.Percentage ?? 0}%'
                    aria-valuenow='${data.Value ?? 0}'
                    aria-valuemin='${data.Min ?? 0}'
                    aria-valuemax='${data.Max ?? 100}'
                    pode-object='${this.getType()}'
                    pode-id='${this.uuid}'
                    ${this.events(data.Events)}>
                </div>
        </div>`;

        if (!data.HideName && data.DisplayName) {
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
            this.listen(this.element, 'change', function(e, target) {
                obj.element.text(`${obj.element.attr('aria-valuenow')} / ${obj.element.attr('aria-valuemax')}`);
            }, true);
        }
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        // value
        this.updateValue(data.Value);

        // colour
        if (data.Colour) {
            this.replaceClass('bg-\\w+', `bg-${data.ColourType}`, null, { pattern: true });
        }
    }

    reset(data, sender, opts) {
        this.updateValue(0);
    }

    updateValue(value) {
        if (value == null || value < 0 || value > 100) {
            return;
        }

        this.element.attr('aria-valuenow', value);

        var max = this.element.attr('aria-valuemax');
        var percentage = value == 0 ? 0 : (value / max) * 100.0;

        this.element.css('width', `${percentage}%`);
    }

    show(data, sender, opts) {
        this.element.parent().show();
        this.visible = true;
    }

    hide(data, sender, opts) {
        this.element.parent().hide();
        this.visible = false;
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

            options += `<div
                id='${this.id}'
                class='custom-control ${divClass} ${inline}'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'>
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

        return `<div pode-container-for='${this.uuid}'>${options}</div>`;
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

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

            options += `<div
                id='${this.id}'
                class='custom-control custom-radio ${inline}'
                pode-object='${this.getType()}'
                pode-id='${this.uuid}'>
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

        return `<div pode-container-for='${this.uuid}'>${options}</div>`;
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
                DisplayName: data.Placeholders.Date,
                Value: data.Values.Date
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
                DisplayName: data.Placeholders.Time,
                Value: data.Values.Time
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
        this.hasSpinner = true;
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

            header = `<div class='card-header d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 border-bottom' for='${this.uuid}'>
                <h5>
                    ${icon}
                    ${encodeHTML(this.file.url)}
                </h5>
                <div class='btn-toolbar mb-2 mb-md-0 mTop-05'>
                    <div class='icon-group mr-2'>
                        <span class='mdi mdi-alert-circle-outline stream-error' style='display:none;'></span>
                        <span for='${this.uuid}' class='pode-spinner spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
                    </div>
                    <div class='btn-group mr-2 mLeft05'>
                        <button type='button' class='btn btn-no-text btn-outline-secondary pode-action-btn pode-stream-download' for='${this.id}'>
                            <span class='mdi mdi-download mdi-size-20' title='Download' data-toggle='tooltip'></span>
                        </button>
                        <button type='button' class='btn btn-no-text btn-outline-secondary pode-action-btn pode-stream-clear' for='${this.id}'>
                            <span class='mdi mdi-eraser mdi-size-20' title='Clear' data-toggle='tooltip'></span>
                        </button>
                        <button type='button' class='btn btn-no-text btn-outline-secondary pode-action-btn pode-stream-pause' for='${this.id}'>
                            <span class='mdi mdi-pause mdi-size-20' title='Pause' data-toggle='tooltip'></span>
                        </button>
                    </div>
                </div>
            </div>`;
        }

        return `<div
            id='${this.id}'
            name='${this.name}'
            class="card file-stream"
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
                        obj.removeClass('stream-error');
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
                    obj.addClass('stream-error');
                    hide(obj.element.find('div.card-header div div.btn-group'));
                }
            });
        }, this.file.interval);

        // download file
        this.listen(this.element.find('.pode-stream-download'), 'click', function(e, target) {
            obj.download();
            unfocus(target);
        });

        // pause/resume file streaming
        this.listen(this.element.find('.pode-stream-pause'), 'click', function(e, target) {
            obj.file.streaming = !obj.file.streaming;
            toggleIcon(target, 'pause', 'play', 'Pause', 'Play');
            unfocus(target);
        });

        // clear textarea
        this.listen(this.element.find('.pode-stream-clear'), 'click', function(e, target) {
            obj.clear();
            unfocus(target);
        });
    }

    download() {
        var parts = this.file.url.split('/');
        downloadFile(this.file.url, parts[parts.length - 1]);
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

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
        this.content[0] = 'Steps';
        this.stepper = null;
    }

    new(data, sender, opts) {
        return `<div
            id="${this.id}"
            class="bs-stepper linear"
            role="stepper"
            pode-object="${this.getType()}"
            pode-id="${this.uuid}">
                <div class="bs-stepper-header" role="tablist"></div>
                <div class="bs-stepper-content" pode-content-for='${this.uuid}' pode-content-order='0'></div>
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
        sendAjaxReq(`${this.url}/submit`, result.data, this, true, null, null, result.opts);
    }

    addChild(element, data, sender, opts) {
        super.addChild(element, data, sender, opts);

        // add new step indicator
        if (element.getType() !== 'step') {
            return;
        }

        var html = `<div class='step ${element.child.isFirst ? 'active' : ''}' data-target='#${element.id}'>
            <button type='button' class='step-trigger' role='tab' id='${element.id}-trigger' for='${this.uuid}' aria-controls='${element.id}' ${!element.child.isFirst ? 'disabled' : ''}>
                <span class='bs-stepper-circle'>
                    ${data.Icon ? element.setIcon(data.Icon) : element.child.index + 1}
                </span>
                <span class='bs-stepper-label'>${data.DisplayName}</span>
            </button>
        </div>
        ${!element.child.isLast ? "<div class='bs-stepper-line'></div>" : ''}`;

        this.element.find('div[role="tablist"]').append(html);
    }
}
PodeElementFactory.setClass(PodeSteps);

class PodeStep extends PodeContentElement {
    static type = 'step';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.hasSpinner = true;

        if (!this.checkParentType('steps')) {
            throw 'Step element can only be used in Steps'
        }
    }

    new(data, sender, opts) {
        //TODO: can be ".build()" these buttons? - which would also include the setIcon automatically
        var prevBtn = this.child.isFirst ? '' : `<button class='btn pode-inbuilt-primary-theme step-previous float-left' for='${this.id}'>
            <span class='mdi mdi-chevron-left mRight02'></span>
            Previous
            <span for='${this.uuid}' class='pode-spinner spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
        </button>`;

        var nextBtn = `<button class='btn pode-inbuilt-primary-theme step-${this.child.isLast ? 'submit' : 'next'} float-right' for='${this.id}'>
            <span for='${this.uuid}' class='pode-spinner spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
            ${this.child.isLast ? 'Submit' : 'Next'}
            <span class='mdi ${this.child.isLast ? 'mdi-checkbox-marked-circle-outline' : 'mdi-chevron-right'} mLeft02'></span>
        </button>`;

        return `<div
            id='${this.id}'
            class='bs-stepper-pane content fade ${this.child.isFirst ? 'active' : ''}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            role='tabpanel'
            aria-labelledby='${this.id}-trigger'
            for='${this.parent.id}'>
                <div pode-content-for='${this.uuid}' pode-content-order='0'></div>
                ${prevBtn}
                ${nextBtn}
        </div>`;
    }

    bind(data, sender, opts) {
        var obj = this;

        // auto submit on enter key
        this.listen(this.element, 'keypress', function(e, target) {
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
        }, true);

        // previous button
        this.listen(this.element.find('.step-previous'), 'click', function(e, target) {
            obj.parent.previous();
        });

        // next button
        this.listen(this.element.find('.step-next'), 'click', function(e, target) {
            if (!obj.element.hasClass('active')) {
                return;
            }

            if (obj.dynamic) {
                var result = obj.serialize();
                sendAjaxReq(`${obj.url}/submit`, result.data, obj, true, (_, sender) => {
                    if (!hasValidationErrors(sender)) {
                        obj.parent.next();
                    }
                }, null, result.opts, $(e.currentTarget));
            }
            else {
                obj.parent.next();
            }
        }, true);

        // submit button
        this.listen(this.element.find('.step-submit'), 'click', function(e, target) {
            if (!obj.element.hasClass('active')) {
                return;
            }

            if (obj.dynamic) {
                var result = obj.serialize();
                sendAjaxReq(`${obj.url}/submit`, result.data, obj, true, (_, sender) => {
                    if (!hasValidationErrors(sender)) {
                        obj.parent.submit();
                    }
                }, null, result.opts, $(e.currentTarget));
            }
            else {
                obj.parent.submit();
            }
        }, true);
    }
}
PodeElementFactory.setClass(PodeStep);

class PodeBreadcrumb extends PodeBreadcrumbElement {
    static type = 'breadcrumb';

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.id = '__pode_breadcrumb__';
        this.content[0] = 'Items';
        this.isCustom = opts.isCustom ?? true;
        PODE_BREADCRUMB.attr('for', this.uuid);
    }

    new(data, sender, opts) {
        PODE_BREADCRUMB.empty();

        return `<div
            id='${this.id}'
            pode-object='${this.getType()}'
            pode-id='${this.uuid}'
            pode-content-for='${this.uuid}'
            pode-content-order='0'>
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
            class='breadcrumb-item d-inline-block ${data.Active ? 'active' : ''}'
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
        this.content[0] = 'Items';
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

            <ul class='dropdown-menu' aria-labelledby='${this.id}' pode-content-for='${this.uuid}' pode-content-order='0'></ul>
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
            this.listen(this.element, 'click', function(e, target) {
                sendAjaxReq(`${obj.url}/click`, null, null, true);
            });
        }
    }
}
PodeElementFactory.setClass(PodeNavLink);

class PodeElementGroup extends PodeElement {
    static type = 'element-group'

    constructor(data, sender, opts) {
        super(data, sender, opts);
        this.submitId = data.SubmitId;
    }

    new(data, sender, opts) {
        return `<span
            id="${this.id}"
            class="pode-element-group"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'
            pode-content-for='${this.uuid}'
            pode-content-order='0'>
        </span>`;
    }

    bind(data, sender, opts) {
        super.bind(data, sender, opts);
        if (!this.submitId) {
            return;
        }

        var obj = this;
        this.listen(this.element, 'keypress', function(e, target) {
            if (!isEnterKey(e)) {
                return;
            }

            obj.clickSubmitButton();
        }, true);
    }

    update(data, sender, opts) {
        super.update(data, sender, opts);

        if (data.SubmitId) {
            this.submitId = data.SubmitId
        }
    }

    submit(data, sender, opts) {
        this.clickSubmitButton();
    }

    clickSubmitButton() {
        var btn = this.element.find(`#${this.submitId}`);
        if (btn && btn.length > 0) {
            btn.trigger('click');
        }
    }

    reset(data, sender, opts) {
        // reset textboxes
        this.element.find('input:not(:checkbox, :radio)').each((_, item) => {
            item.value = item.defaultValue;
        });

        // reset radio and checkboxes
        this.element.find('input[type="checkbox"], input[type="radio"]').each((_, item) => {
            item.checked = item.defaultChecked;
        });

        // reset select options
        this.element.find('select').each((_, item) => {
            $(item).find('option').each((_, opt) => {
                opt.selected = opt.defaultSelected;
            });
        });

        // reset textareas
        this.element.find('textarea').each((_, item) => {
            item.value = item.defaultValue;
        });
    }
}
PodeElementFactory.setClass(PodeElementGroup);

class PodeSpan extends PodeElement {
    static type = 'span'

    constructor(...args) {
        super(...args);
    }

    new(data, sender, opts) {
        return `<span
            id="${this.id}"
            class="pode-span"
            pode-object="${this.getType()}"
            pode-id='${this.uuid}'
            pode-content-for='${this.uuid}'
            pode-content-order='0'>
        </span>`;
    }
}
PodeElementFactory.setClass(PodeSpan);