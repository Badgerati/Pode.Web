$.expr.pseudos.icontains = $.expr.createPseudo(function(arg) {
    return function(elem) {
        return $(elem).text().toLowerCase().indexOf(arg.toLowerCase()) >= 0;
    };
});

var MIN_INT32 = (1 << 31);
var MAX_INT32 = ((2**31) - 1);


(function() {
    $('[data-toggle="tooltip"]').tooltip();
})();

var pageLoaded = false;
$(() => {
    if (pageLoaded) {
        return;
    }
    pageLoaded = true;

    if (checkAutoTheme()) {
        return;
    }

    sendAjaxReq(`${getPageUrl('content')}`, null, undefined, true, (res, sender) => {
        mapElementThemes();

        loadBreadcrumb();

        bindSidebarFilter();
        bindSidebarToggle();
        toggleSidebar();
        bindPageLinks();
        bindPageHelp();

        bindFormSubmits();

        bindPageGroupCollapse();
    });
});

function getUrl(subpath) {
    subpath = subpath ?? '';
    if (subpath && !subpath.startsWith('/')) {
        subpath = `/${subpath}`;
    }

    var base = `${window.location.origin}${window.location.pathname}`;
    return `${base.replace(/\/$/, '')}${subpath}`;
}

function getPageUrl(subpath) {
    subpath = subpath ?? '';
    if (subpath && !subpath.startsWith('/')) {
        subpath = `/${subpath}`;
    }

    var pageId = $('body').attr('pode-page-id');
    if (!pageId) {
        return getUrl(subpath);
    }

    var base = `${window.location.origin}`;

    var appPath = $('body').attr('pode-app-path');
    if (appPath) {
        base += `/${appPath}`;
    }

    return `${base}/pode.web-dynamic/pages/${pageId}${subpath}`;
}

function loadBreadcrumb() {
    // get breadcrumb
    var breadcrumb = PodeElementFactory.getBreadcrumb();
    if (breadcrumb.isCustom) {
        return;
    }

    // get base and current value query
    var base = getQueryStringValue('base');
    var value = getQueryStringValue('value');

    // do nothing with no values
    if (!base && !value) {
        return;
    }

    // base page
    breadcrumb.add({
        Name: getPageTitle(),
        Url: window.location.pathname
    });

    // base values
    if (base) {
        var newBase = '';
        var data = null;

        base.split('/').forEach((i) => {
            data = newBase ? `base=${newBase}&value=${i}` : `value=${i}`;

            breadcrumb.add({
                Name: i,
                Url: `${window.location.pathname}?${data}`
            });

            newBase = newBase ? `${newBase}/${i}` : i;
        });
    }

    // current value
    if (value) {
        breadcrumb.add({
            Name: value,
            Active: true
        });
    }
}

function checkAutoTheme() {
    var theme = getPodeTheme();

    if (theme != 'auto') {
        return;
    }

    var isSystemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    theme = (isSystemDark ? 'dark' : 'light');

    // set the cookie
    setPodeThemeCookie(theme);

    // force a refresh
    refreshPage();
    return true;
}

function mapElementThemes() {
    var bodyTheme = getPodeTheme();
    var isTerminal = bodyTheme == 'terminal';
    var types = ['badge', 'btn', 'text'];

    // main theme
    var defTheme = isTerminal ? 'success' : 'primary';

    types.forEach((type) => {
        $(`.${type}-inbuilt-theme`).each((i, e) => {
            $(e).removeClass(`${type}-inbuilt-theme`);
            addClass($(e), `${type}-${defTheme}`);
        });
    });

    // secondary theme
    defTheme = isTerminal ? 'success' : 'secondary';

    types.forEach((type) => {
        $(`.${type}-inbuilt-sec-theme`).each((i, e) => {
            $(e).removeClass(`${type}-inbuilt-sec-theme`);
            addClass($(e), `${type}-${defTheme}`);
        });
    });
}

function getPodeTheme() {
    return $('body').attr('pode-theme');
}

function setPodeTheme(theme, refresh) {
    // update body
    $('body').attr('pode-theme', theme);

    // set the cookie
    setPodeThemeCookie(theme);

    // refresh?
    if (refresh) {
        refreshPage();
    }
}

function setPodeThemeCookie(theme) {
    // cookie expires after 1 month
    var d = new Date();
    d.setTime(d.getTime() + (30 * 24 * 60 * 60 * 1000));

    // save theme cookie
    document.cookie = `pode.web.theme=${theme}; expires=${d.toUTCString()}; path=/`
}

function serializeInputs(element) {
    if (!element) {
        return {};
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
        opts = null;

        if (testTagName(element, 'form')) {
            data = element.serialize();
        }
        else {
            data = element.find('input, textarea, select').serialize();
        }
    }

    return {
        data: data,
        opts: opts
    };
}

function isFormDataEmpty(data) {
    return (data == null || !data.entries().next().value);
}

function newFormData(inputs) {
    var data = new FormData();

    for (var input of inputs) {
        if (!input.name) {
            continue;
        }

        switch(input.type.toLowerCase()) {
            case 'file':
                if (input.files.length > 0) {
                    data.append(input.name, input.files[0], input.files[0].name);
                }
                else {
                    data.append(input.name, '');
                }
                break;

            case 'checkbox':
            case 'radio':
                if (input.checked) {
                    addFormDataInput(data, input);
                }
                break;

            default:
                addFormDataInput(data, input);
                break;
        }
    }

    return data;
}

function addFormDataInput(data, input) {
    return addFormDataValue(data, input.name, $(input).val());
}

function addFormDataValue(data, name, value) {
    if (data == null || typeof data === 'string') {
        if (!data) {
            data = '';
        }

        if (data) {
            data += '&';
        }

        data += `${name}=${value}`;
    }
    else {
        if (data.has(name)) {
            data.set(name, `${data.get(name)},${value}`);
        }
        else {
            data.append(name, value);
        }
    }

    return data;
}

function isEnterKey(event) {
    if (!event) {
        return false;
    }

    return (event.which == 13 && event.keyCode == 13 && !testTagName(event.target, 'textarea'));
}

function hasValidationErrors(element) {
    if (!element) {
        return;
    }

    return (element.find('.is-invalid').length > 0)
}

function removeValidationErrors(element) {
    if (!element) {
        return;
    }

    element.find('.is-invalid').removeClass('is-invalid');
}

function setValidationError(element) {
    if (!element) {
        return;
    }

    addClass(element, 'is-invalid');

    // form-row? flag inside inputs
    if (element.hasClass('form-row')) {
        addClass(element.find('input'), 'is-invalid');
    }

    // input? find parent input-group/form-row
    if (testTagName(element, 'input')) {
        addClass(element.closest('div.input-group'), 'is-invalid');
        addClass(element.closest('div.form-row'), 'is-invalid');
    }
}

function sendAjaxReq(url, data, sender, useActions, successCallback, errorCallback, opts, button) {
    // show the spinner
    showSpinner(sender);
    $('.alert.pode-error').remove();

    // disable the button
    if (isDisabled(button)) {
        return;
    }

    disable(button);

    // remove validation errors
    removeValidationErrors(sender);

    // add app-path to url (for the likes of IIS)
    var appPath = $('body').attr('pode-app-path');
    url = `${appPath}${url}`;

    // add current query string
    if (window.location.search) {
        url = `${url}${window.location.search}`;
    }

    // set default opts
    opts = (opts ?? {});
    opts.contentType = opts.contentType ?? 'application/x-www-form-urlencoded; charset=UTF-8';
    opts.processData = opts.processData ?? true;
    opts.method = opts.method ?? 'post';
    opts.successCallbackBefore = opts.successCallbackBefore ?? false;

    // make the call
    $.ajax({
        url: url,
        method: opts.method,
        data: data,
        dataType: 'binary',
        processData: opts.processData,
        contentType: opts.contentType,
        mimeType: opts.mimeType,
        timeout: 0,
        xhrFields: {
            responseType: 'blob'
        },
        success: function(res, status, xhr) {
            // attempt to hide any spinners
            hideSpinner(sender);

            // re-enable the button
            enable(button);

            // re-gain focus, or lose focus?
            if (!opts.keepFocus) {
                unfocus(sender);
            }

            // call success callback before actions
            if (successCallback && opts.successCallbackBefore) {
                res.text().then((v) => {
                    successCallback(JSON.parse(v), sender);
                });
            }

            // do we have a file to download?
            var filename = getAjaxFileName(xhr);
            if (filename) {
                downloadBlob(filename, res, xhr);
            }

            // run any actions, if we need to
            else if (useActions) {
                res.text().then((v) => {
                    invokeActions(JSON.parse(v), sender);
                });
            }

            // call success callback after actions
            if (successCallback && !opts.successCallbackBefore) {
                res.text().then((v) => {
                    successCallback(JSON.parse(v), sender);
                });
            }
        },
        error: function(err, msg, stack) {
            // attempt to hide any spinners
            hideSpinner(sender);

            // re-enable the button
            enable(button);

            // re-gain focus, or lose focus?
            if (!opts.keepFocus) {
                unfocus(sender);
            }

            // log the error/stack
            console.log(err);
            console.log(stack);

            // call error callback
            if (errorCallback) {
                errorCallback(err, msg, stack, sender);
            }
        }
    });
}

function downloadBlob(filename, blob, xhr) {
    // from: https://gist.github.com/jasonweng/393aef0c05c425d8dcfdb2fc1a8188e5
    // IE workaround for "HTML7007
    if (typeof window.navigator.msSaveBlob !== 'undefined') {
        window.navigator.msSaveBlob(blob, filename);
    }
    else {
        var URL = (window.URL || window.webkitURL);
        var downloadUrl = URL.createObjectURL(blob);
        downloadFile(downloadUrl, filename);

        // cleanup the blob url
        setTimeout(function() {
            URL.revokeObjectURL(downloadUrl);
        }, 1000);
    }
}

function downloadFile(url, filename) {
    // use HTML5 a[download] attribute to specify filename
    if (filename) {
        var a = document.createElement('a');

        // safari doesn't support this yet
        if (typeof a.download === 'undefined') {
            window.location = url;
        }
        else {
            a.href = url;
            a.download = filename;
            a.style.display = 'none';

            document.body.appendChild(a);
            a.click();

            $(a).remove();
        }
    }
    else {
        window.location = url;
    }
}

function getAjaxFileName(xhr) {
    var filename = '';
    var disposition = xhr.getResponseHeader('Content-Disposition');

    if (disposition && disposition.indexOf('attachment') !== -1) {
        var filenameRegex = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/;
        var matches = filenameRegex.exec(disposition);
        if (matches != null && matches[1]) {
            filename = matches[1].replace(/['"]/g, '');
        }
    }

    return filename;
}

function showSpinner(sender) {
    if (!sender) {
        return;
    }

    show(sender.find('span.spinner-border'));
}

function hideSpinner(sender) {
    if (!sender) {
        return;
    }

    hide(sender.find('span.spinner-border'));
}

function unfocus(sender) {
    if (!sender) {
        return;
    }

    sender.blur();
}

function bindSidebarToggle() {
    $('button#menu-toggle').off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        $('nav#sidebarMenu').toggleClass('hide');
        $('main[role="main"]').toggleClass('fullscreen');

        $('button#menu-toggle span').toggleClass('mdi-rotate-180');
    });
}

function toggleSidebar() {
    if ($('nav#sidebarMenu').hasClass('hide-on-start')) {
        $('button#menu-toggle').trigger('click');
    }
}

function comparer(index) {
    return function(a, b) {
        var valA = getCellValue(a, index);
        var valB = getCellValue(b, index);
        return isNumeric(valA) && isNumeric(valB) ? valA - valB : valA.toString().localeCompare(valB);
    }
}

function getCellValue(row, index) {
    return $(row).children('td').eq(index).text();
}

function isNumeric(value) {
    return (typeof(value) == 'number' || (typeof(value) == 'string' && value.match(/^\d+$/) != null));
}

function bindPageGroupCollapse() {
    $('ul#sidebar-list div.collapse').off('hide.bs.collapse').on('hide.bs.collapse', function(e) {
        var id = $(e.target).attr('id');
        var icon = $(`a[aria-controls="${id}"] span.mdi`);
        toggleIcon(icon, 'chevron-right', 'chevron-down');
    });

    $('ul#sidebar-list div.collapse').off('show.bs.collapse').on('show.bs.collapse', function(e) {
        var id = $(e.target).attr('id');
        var icon = $(`a[aria-controls="${id}"] span.mdi`);
        toggleIcon(icon, 'chevron-down', 'chevron-right');
    });
}

function toggleIcon(element, icon1, icon2, title1, title2) {
    // get span/icon
    if (!element.hasClass('mdi')) {
        element = element.find('.mdi');
    }

    // fix icon names
    if (icon1 && !icon1.startsWith('mdi-')) {
        icon1 = `mdi-${icon1}`;
    }

    if (icon2 && !icon2.startsWith('mdi-')) {
        icon2 = `mdi-${icon2}`;
    }

    // toggle titles
    if (title1 && title2) {
        if (element.hasClass(icon1)) {
            setTitle(element, title2);
        }

        if (element.hasClass(icon2)) {
            setTitle(element, title1);
        }

        element.tooltip('hide');
        element.tooltip();
    }

    // toggle icons
    if (icon1 && icon2) {
        element.toggleClass(icon1);
        element.toggleClass(icon2);
    }
}

function setTitle(element, title) {
    if (element.attr('title')) {
        element.attr('title', title);
    }

    if (element.attr('data-original-title')) {
        element.attr('data-original-title', title);
    }
}

function invokeActions(actions, sender) {
    convertToArray(actions).forEach((action) => {
        if (!action) {
            return;
        }

        var _type = (action.ObjectType ?? '').toLowerCase();
        var _subType = (action.SubObjectType ?? '').toLowerCase()
        var _operation = (action.Operation ?? 'new').toLowerCase();

        switch (_type) {
            case 'href':
                actionHref(action);
                break;

            case 'page':
                actionPage(action);
                break;

            case 'error':
                actionError(action, sender);
                break;

            case 'theme':
                actionTheme(action);
                break;

            default:
                PodeElementFactory.invokeClass(_type, _operation, action, sender, {
                    type: _type,
                    subType: _subType
                });
                break;
        }
    });
}

function bindFormSubmits() {
    // login form
    $("body#login-page .form-signin").off('submit').on('submit', function(e) {
        // get the form
        var form = $(e.target);

        // show the spinner
        showSpinner(form);
        $('.alert').remove();

        // remove validation errors
        removeValidationErrors(form);
    });
}

function getDataValue(element) {
    var dataValue = element.attr('pode-data-value');
    if (!dataValue) {
        dataValue = element.closest('[pode-data-value!=""][pode-data-value]').attr('pode-data-value');
    }

    return dataValue;
}

function bindPageLinks() {
    $(".nav-page-item a.nav-link[pode-dynamic='True']").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var url = getPagePath(null, null, this);
        sendAjaxReq(url, null, null, true);
    });
}

function bindPageHelp() {
    $('span.pode-page-help').off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var url = $(e.target).attr('for');
        sendAjaxReq(`${url}/help`, null, null, true);
    });
}

function getPagePath(name, group, page) {
    if (page) {
        name = $(page).attr('name');
        group = $(page).attr('pode-page-group');
    }

    var path = '';
    if (group) {
        path += `/groups/${group}`;
    }

    path += `/pages/${name}`;
    return path;
}

function delay(callback, ms) {
    var timer = 0;

    return function() {
        var context = this, args = arguments;
        clearTimeout(timer);
        timer = setTimeout(function () {
            callback.apply(context, args);
        }, ms || 0);
    };
}

function bindSidebarFilter() {
    $("input.pode-nav-filter").off('keyup').on('keyup', function(e) {
        e.preventDefault();

        var input = $(e.target);
        var listId = input.attr('for');
        var value = input.val();

        if (value) {
            $('div.collapse').collapse('show');
            hide($(`ul#${listId} li.nav-group-title`));
        }
        else {
            $('div.collapse').collapse('hide');
            show($(`ul#${listId} li.nav-group-title`));
        }

        hide($(`ul#${listId} li.nav-page-item:not(:icontains('${value}'))`));
        show($(`ul#${listId} li.nav-page-item:icontains('${value}')`));
    });
}

function getQueryStringValue(name) {
    if (!window.location.search) {
        return null;
    }

    return (new URLSearchParams(window.location.search)).get(name);
}

function buildTableHeader(column, direction, hidden) {
    var value = `<th sort-direction='${direction}' name='${column.Key}' default-value='${column.Default}' style='`;

    if (column.Width) {
        value += `width:${column.Width};`;
    }

    if (column.Alignment) {
        value += `text-align:${column.Alignment};`;
    }

    value += "'";

    if (hidden || (hidden == null && column.Hide)) {
        value += ` class='d-none'`;
    }

    value += ">";

    if (column.Icon) {
        value += `<span class='mdi mdi-${column.Icon.toLowerCase()} mRight04'></span>`;
    }

    value += `${column.Name}</th>`;
    return value;
}

function getTagName(element) {
    if (!element) {
        return null;
    }

    var tagName = $(element).prop('nodeName');
    if (!tagName) {
        return null;
    }

    return tagName.toLowerCase();
}

function testTagName(element, tagName) {
    return (getTagName(element) == tagName.toLowerCase());
}

function resetForm(form, isInner = false) {
    if (!form) {
        return;
    }

    if (testTagName(form, 'form')) {
        form[0].reset();
    }
    else if (isInner) {
        return;
    }
    else {
        resetForm(form.find('form'), true);
    }
}

function setElementStyle(obj, property, value, notImportant) {
    if (value) {
        obj.style.setProperty(property, value, (notImportant ? undefined : 'important'));
    }
    else {
        obj.style.setProperty(property, null);
    }
}

function actionTheme(action) {
    if (!action) {
        return;
    }

    switch (action.Operation.toLowerCase()) {
        case 'update':
            updateTheme(action);
            break;

        case 'reset':
            resetTheme();
            break;
    }
}

function updateTheme(action) {
    if (!action.Name) {
        return;
    }

    setPodeTheme(action.Name, true);
}

function resetTheme() {
    setPodeTheme('', true);
}

function decodeHTML(value) {
    var textArea = document.createElement('textarea');
    textArea.innerHTML = value;
    value = textArea.value;
    textArea.remove();
    return value;
}

function encodeHTML(value) {
    return $('<div/>').text(value).html();
}

function truncateArray(array, maxItems) {
    if (maxItems <= 0) {
        return array;
    }

    if (array.length <= maxItems) {
        return array;
    }

    return array.slice(array.length - maxItems, array.length);
}

function convertToArray(element) {
    if (!element) {
        return [];
    }

    if (element.length && element.toArray) {
        return element;
    }

    return Array.isArray(element) ? element : [element];
}

function searchArray(array, element, caseInsensitive) {;
    return convertToArray(array).find((item) => {
        return caseInsensitive
            ? item.toLowerCase() === element.toLowerCase()
            : item === element;
    }) !== undefined;
}

function getChartAxesColours(theme, canvas, min, max) {
    var opts = {};

    // just hide ticks/legend for small tile charts
    if (canvas.closest('div.pode-tile').length > 0) {
        opts = {
            ticks: {
                display: false
            }
        }
    }

    // base opts on theme
    else {
        switch (theme) {
            case 'dark':
                opts = {
                    grid: {
                        color: '#214981',
                        zeroLineColor: '#214981'
                    },
                    ticks: { color: '#ccc' }
                };
                break;

            case 'terminal':
                opts = {
                    grid: {
                        color: 'darkgreen',
                        zeroLineColor: 'darkgreen'
                    },
                    ticks: { color: '#33ff00' }
                };
                break;

            default:
                opts = {
                    grid: {
                        color: 'lightgrey',
                        zeroLineColor: 'lightgrey'
                    },
                    ticks: { color: '#333' }
                };
                break;
        }
    }

    // add min/max
    if (min > MIN_INT32) {
        opts['min'] = min;
    }

    if (max < MAX_INT32) {
        opts['max'] = max;
    }

    // the opts
    return opts;
}

function getChartPieBorderColour(theme) {
    switch (theme) {
        case 'dark':
            return '#214981';

        case 'terminal':
            return 'darkgreen';

        default:
            return '#222';
    }
}

function getChartColourPalette(theme, colours) {
    // do the canvas have a defined set of colours?
    if (colours && colours.length > 0) {
        var converted = [];
        colours.forEach((c) => { converted.push(hexToRgb(c.trim())); });
        return converted;
    }

    // no colours, so use the defaults
    var first = [
        hexToRgb('#36a2eb'), // cornflower blue
        hexToRgb('#ffb000')  // orange
    ];

    if (theme == 'terminal') {
        first = [hexToRgb('#ffb000'), hexToRgb('#36a2eb')]; // orange, blue
    }

    return first.concat([
        hexToRgb('#ff6384'),    // red
        hexToRgb('#ffcd56'),    // yellow
        hexToRgb('#00a333'),    // green
        hexToRgb('#9966ff'),    // purple
        hexToRgb('#96b0c6'),    // grey
        hexToRgb('#275c7b'),    // teal
        hexToRgb('#665191'),    // purple
        hexToRgb('#bc5090'),    // pink
        hexToRgb('#f95d6a'),    // peach
        hexToRgb('#488f31'),    // green
        hexToRgb('#f1f1f1'),    // white
        hexToRgb('#a9b450'),    // lime green
        hexToRgb('#00d2ef')     // sky blue
    ]);
}

function hexToRgb(hex) {
    var shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
    hex = hex.replace(shorthandRegex, function(m, r, g, b) {
        return r + r + g + g + b + b;
    });

    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result) {
        return "rgba(0, 0, 0, 1.0)";
    }

    return `rgba(${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}, 1.0)`;
}

function getTimeString() {
    return (new Date()).toLocaleTimeString().split(':').slice(0,2).join(':');
}

function actionHref(action) {
    if (!action) {
        return;
    }

    // prepend host for relative urls
    if (action.Url.startsWith('/')) {
        action.Url = `${window.location.origin}${action.Url}`;
    }

    // new tab, or current page?
    var target = action.NewTab ? '_blank' : '_self';
    window.open(action.Url, target);
}

function getClass(element, _class) {
    if (!element) {
        return null;
    }

    var result = element.attr('class');
    if (!result) {
        return null;
    }

    if (_class) {
        result = result.match(new RegExp(_class));
    }
    else {
        result = result.split(' ');
    }

    return (result ? result[0] : null);
}

function hasClass(element, _class, raw) {
    if (!element) {
        return false;
    }

    return (raw ? element.hasClass(_class) : getClass(element, _class) != null);
}

function removeClass(element, _class, raw) {
    if (!element) {
        return;
    }

    if (!_class) {
        element.removeClass();
    }
    else {
        element.removeClass((raw ? _class : getClass(element, _class)));
    }
}

function addClass(element, _class) {
    if (!element || !_class) {
        return;
    }

    if (hasClass(element, _class, true)) {
        return;
    }

    element.addClass(_class);
}

function replaceClass(element, oldClass, newClass) {
    if (!element) {
        return;
    }

    removeClass(element, oldClass);
    addClass(element, newClass);
}

function hide(element) {
    if (!element) {
        return;
    }

    element.hide();
}

function show(element) {
    if (!element) {
        return;
    }

    element.show();
}

function enable(element) {
    if (!element) {
        return;
    }

    if (testTagName(element, 'a')) {
        element.removeClass('disabled');
        element.removeAttr('tabindex');
        element.removeAttr('aria-disabled');
    }
    else {
        element.prop('disabled', false);
    }
}

function disable(element) {
    if (!element) {
        return;
    }

    if (testTagName(element, 'a')) {
        element.addClass('disabled');
        element.prop('tabindex', '-1');
        element.prop('aria-disabled', 'true');
    }
    else {
        element.prop('disabled', true);
    }
}

function isDisabled(element) {
    if (!element) {
        return false;
    }

    return element.is(':disabled');
}

function actionPage(action) {
    if (!action) {
        return;
    }

    refreshPage();
}

function refreshPage() {
    window.location.reload();
}

function actionError(action, sender) {
    if (!action || !sender) {
        return;
    }

    showError(action.Message, sender);
}

function showError(message, sender, prepend) {
    var error = `<div class="alert alert-danger pode-error mTop1" role="alert">
        <h6 class='pode-alert-header'>
            <span class="alert-circle"></span>
            <strong>Error</strong>
        </h6>

        <div class='pode-alert-body pode-text'>
            ${message}
        </div>
    </div>`;

    if (prepend) {
        sender.prepend(error);
    }
    else {
        sender.append(error);
    }
}

function getPageTitle() {
    return $('#pode-page-title h1').text().trim();
}

function invokeEvent(type, sender) {
    sender = $(sender);

    if (getTagName(sender) == null) {
        var url = (window.location.pathname == '/' ? '/home' : window.location.pathname);
        sendAjaxReq(`${url}/events/${type}`, null, sender, true);
    }
    else {
        PodeElementFactory.triggerObject(sender.attr('pode-id'), type);
    }
}

function generateUuid() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
        (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    );
}