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
(function() {
    hljs.highlightAll();
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

    sendAjaxReq(`${document.URL.trimEnd('/')}/content`, null, $('content#pode-content'), true, (res, sender) => {
        mapElementThemes();

        loadBreadcrumb();
        // loadTables();
        loadCharts();
        loadAutoCompletes();
        // loadTiles();
        loadSelects();

        setupSteppers();
        // setupAccordion();

        bindSidebarFilter();
        bindSidebarToggle();
        toggleSidebar();
        bindNavLinks();
        bindPageLinks();
        bindPageHelp();

        bindFormSubmits();
        // bindButtons();
        // bindCodeCopy();
        bindCodeEditors();
        bindFileStreams();

        // bindTableFilters();
        // bindTableExports();
        // bindTableRefresh();
        // bindTableButtons();

        bindChartRefresh();
        bindRangeValue();
        bindProgressValue();
        bindModalSubmits();
        // bindFormResets();

        // bindTileRefresh();
        // bindTileClick();

        bindPageGroupCollapse();
        // bindCardCollapse();

        bindTabCycling();
        // bindAccordionCycling();
        // bindTimers();
    });
});

function bindFileStreams() {
    $('div.file-stream pre textarea').each((i, e) => {
        var handle = setInterval(function() {
            var paused = $(e).attr('pode-streaming') == '0';
            if (paused) {
                return;
            }

            showSpinner($(e).closest('div.file-stream'));
            var fileUrl = $(e).attr('pode-file');
            var length = $(e).attr('pode-length');

            $.ajax({
                url: fileUrl,
                method: 'get',
                dataType: 'text',
                headers: { "Range": `bytes=${length}-` },
                success: function(data, status, xhr) {
                    if ($(e).closest('div.file-stream').hasClass('stream-error')) {
                        removeClass($(e).closest('div.file-stream'), 'stream-error', true);
                        show($(e).closest('div.file-stream').find('div.card-header div div.btn-group'));
                    }

                    hideSpinner($(e).closest('div.file-stream'));

                    var header = xhr.getResponseHeader('Content-Range');
                    if (header) {
                        var rangeLength = header.split('/')[1];

                        // if new content, append
                        if (rangeLength > parseInt(length)) {
                            $(e).append(data);
                            $(e).attr('pode-length', rangeLength);
                            e.scrollTop = e.scrollHeight;
                        }

                        // if length is now less, clear the textarea
                        else if (rangeLength < parseInt(length)) {
                            $(e).text('');
                            $(e).attr('pode-length', 0);
                            e.scrollTop = e.scrollHeight;
                        }
                    }
                },
                error: function(err) {
                    hideSpinner($(e).closest('div.file-stream'));

                    if (err.status == 416) {
                        return;
                    }

                    $(e).attr('pode-streaming', '0');
                    addClass($(e).closest('div.file-stream'), 'stream-error');
                    hide($(e).closest('div.file-stream').find('div.card-header div div.btn-group'));
                }
            });
        }, $(e).attr('pode-interval'));
    });

    $('div.file-stream button.pode-stream-download').off('click').on('click', function(e) {
        var button = getButton(e);
        var id = button.attr('for');
        var fileUrl = $(`textarea#${id}`).attr('pode-file');
        var parts = fileUrl.split('/');
        downloadFile(fileUrl, parts[parts.length - 1]);
        unfocus(button);
    });

    $('div.file-stream button.pode-stream-pause').off('click').on('click', function(e) {
        var button = getButton(e);
        var id = button.attr('for');
        var textarea = $(`textarea#${id}`);

        toggleAttr(textarea, 'pode-streaming', '0', '1');
        toggleIcon(button, 'pause', 'play', 'Pause', 'Play');
        unfocus(button);
    });

    $('div.file-stream button.pode-stream-clear').off('click').on('click', function(e) {
        var button = getButton(e);
        var id = button.attr('for');
        var textarea = $(`textarea#${id}`);

        $(textarea).text('');
        $(textarea).attr('pode-length', 0);
        textarea.scrollTop = textarea.scrollHeight;
        unfocus(button);
    });
}

// function setupAccordion() {
//     $('div.accordion div.bellow div.collapse').off('hide.bs.collapse').on('hide.bs.collapse', function(e) {
//         var icon = $(e.target).closest('div.card').find('span.arrow-toggle');
//         toggleIcon(icon, 'chevron-down', 'chevron-up');
//     });

//     $('div.accordion div.bellow div.collapse').off('show.bs.collapse').on('show.bs.collapse', function(e) {
//         var icon = $(e.target).closest('div.card').find('span.arrow-toggle');
//         toggleIcon(icon, 'chevron-up', 'chevron-down');
//     });
// }

function loadBreadcrumb() {
    // get breadcrumb
    var breadcrumb = $('nav ol.breadcrumb');
    if (!breadcrumb || isDynamic(breadcrumb)) {
        return;
    }

    breadcrumb.empty();

    // get base and current value query
    var base = getQueryStringValue('base');
    var value = getQueryStringValue('value');

    // do nothing with no values
    if (!base && !value) {
        return;
    }

    // add page name
    var title = getPageTitle();
    breadcrumb.append(`<li class='breadcrumb-item'><a href='${window.location.pathname}'>${title}</a></li>`);

    // add base values
    if (base) {
        var newBase = '';
        var data = null;

        base.split('/').forEach((i) => {
            data = `value=${i}`;
            if (newBase) {
                data = `base=${newBase}&${data}`;
            }

            breadcrumb.append(`<li class='breadcrumb-item'><a href='${window.location.pathname}?${data}'>${encodeHTML(i)}</a></li>`);

            if (newBase) {
                newBase = `${newBase}/${i}`;
            }
            else {
                newBase = i;
            }
        });
    }

    // add current value
    if (value) {
        breadcrumb.append(`<li class='breadcrumb-item active' aria-current='page'>${encodeHTML(value)}</li>`);
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

    return (event.which == 13 && event.keyCode == 13)
}

var _steppers = {};

function setupSteppers() {
    $('div.bs-stepper[role="stepper"]').each((i, e) => {
        var stepper = $(e);
        _steppers[stepper.attr('id')] = new Stepper(e, { linear: true });

        // override form enter-key
        stepper.find('form.pode-stepper-form').off('keypress').on('keypress', function(e) {
            if (!isEnterKey(e)) {
                return;
            }

            var btn = stepper.find('.bs-stepper-content .bs-stepper-pane.active button.step-next');
            if (!btn) {
                btn = stepper.find('.bs-stepper-content .bs-stepper-pane.active button.step-submit');
            }

            if (btn) {
                btn.trigger('click');
            }
        });

        // previous buttons
        stepper.find('.bs-stepper-content button.step-previous').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            // get the button and step
            var btn = getButton(e);
            var step = btn.closest(`div#${btn.attr('for')}`);

            // not need for validation, just go back
            _steppers[step.attr('for')].previous();
        });

        // next buttons
        stepper.find('.bs-stepper-content button.step-next').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            // get the button and step
            var btn = getButton(e);
            var step = btn.closest(`div#${btn.attr('for')}`);

            // skip if step not active
            if (!step.hasClass('active')) {
                return;
            }

            // call ajax, or move along?
            if (isDynamic(step)) {
                // serialize any step-form data
                var inputs = serializeInputs(step);
                var url = getComponentUrl(step);

                // send ajax req, and call next on no validation errors
                sendAjaxReq(url, inputs.data, step, true, (res, sender) => {
                    if (!hasValidationErrors(sender)) {
                        _steppers[sender.attr('for')].next();
                    }
                }, inputs.opts);
            }
            else {
                _steppers[step.attr('for')].next();
            }
        });

        // submit buttons
        stepper.find('.bs-stepper-content button.step-submit').off('click').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            // get the button and step
            var btn = getButton(e);
            var step = btn.closest(`div#${btn.attr('for')}`);

            // skip if step not active
            if (!step.hasClass('active')) {
                return;
            }

            var inputs = null;
            var url = null;

            // call ajax, or move along?
            if (isDynamic(step)) {
                // serialize any step-form data
                inputs = serializeInputs(step);
                url = getComponentUrl(step);

                // send ajax req, if not validation errors, send ajax for all steps
                sendAjaxReq(url, inputs.data, step, true, (res, sender) => {
                    if (!hasValidationErrors(sender)) {
                        var _steps = sender.attr('for');
                        var _inputs = serializeInputs(sender.closest('form.pode-stepper-form'));
                        var _url = getComponentUrl(_steps);

                        sendAjaxReq(_url, _inputs.data, sender, true, null, _inputs.opts);
                    }
                }, inputs.opts);
            }
            else {
                var steps = step.attr('for');
                inputs = serializeInputs(step.closest('form.pode-stepper-form'));
                url = getComponentUrl(steps);

                sendAjaxReq(url, inputs.data, step, true, null, inputs.opts);
            }
        });
    });
}

function isDynamic(element) {
    if (!element) {
        return false;
    }

    return ($(element).attr('pode-dynamic') == 'true');
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

function sendAjaxReq(url, data, sender, useActions, successCallback, opts) {
    // show the spinner
    showSpinner(sender);
    $('.alert.pode-error').remove();

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
    opts.contentType = (opts.contentType == null ? 'application/x-www-form-urlencoded; charset=UTF-8' : opts.contentType);
    opts.processData = (opts.processData == null ? true : opts.processData);
    opts.method = (opts.method == null ? 'post' : opts.method);

    // make the call
    $.ajax({
        url: url,
        method: opts.method,
        data: data,
        dataType: 'binary',
        processData: opts.processData,
        contentType: opts.contentType,
        mimeType: opts.mimeType,
        xhrFields: {
            responseType: 'blob'
        },
        success: function(res, status, xhr) {
            // attempt to hide any spinners
            hideSpinner(sender);

            if (!opts.keepFocus) {
                unfocus(sender);
            }

            // attempt to get a filename, for downloading
            var filename = getAjaxFileName(xhr);

            // do we have a file to download?
            if (filename) {
                downloadBlob(filename, res, xhr);
            }

            // run any actions, if we need to
            else if (useActions) {
                res.text().then((v) => {
                    invokeActions(JSON.parse(v), sender);
                });
            }

            if (successCallback) {
                res.text().then((v) => {
                    successCallback(JSON.parse(v), sender);
                });
            }
        },
        error: function(err, msg, stack) {
            hideSpinner(sender);

            if (!opts.keepFocus) {
                unfocus(sender);
            }

            console.log(err);
            console.log(stack);
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

var _editors = {};

function bindCodeEditors() {
    if ($('.pode-code-editor').length == 0) {
        return;
    }

    var src = $('script[role="monaco"]').attr('src');
    require.config({ paths: { 'vs': src.substring(0, src.lastIndexOf('/')) }});

    // create the editors
    require(["vs/editor/editor.main"], function() {
        $('.pode-code-editor .code-editor').each((i, e) => {
            var theme = $(e).attr('pode-theme');
            if (!theme) {
                var bodyTheme = getPodeTheme();

                switch (bodyTheme) {
                    case 'dark':
                        theme = 'vs-dark';
                        break;

                    case 'terminal':
                        theme = 'hc-black';
                        break;

                    default:
                        theme = 'vs';
                        break;
                }
            }

            var editor = monaco.editor.create(e, {
                value: $(e).attr('pode-value'),
                language: $(e).attr('pode-language'),
                theme: theme,
                readOnly: ($(e).attr('pode-read-only') == 'True')
            });

            $(e).attr('pode-value', '');
            _editors[$(e).attr('for')] = editor;
        });
    });

    // bind upload buttons
    $('.pode-code-editor .pode-upload').off('click').on('click', function(e) {
        var button = getButton(e);
        var editorId = button.attr('for');

        var url = `${getComponentUrl(editorId)}/upload`;
        var data = JSON.stringify({
            language: $(`#${editorId} .code-editor`).attr('pode-language'),
            value: _editors[editorId].getValue()
        });

        sendAjaxReq(url, data, null, true, null, {
            contentType: 'application/json; charset=UTF-8'
        });
    });
}

// function bindCardCollapse() {
//     $('button.pode-card-collapse').off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         var button = getButton(e);
//         toggleIcon(button, 'eye-outline', 'eye-off-outline', 'Hide', 'Show');

//         button.closest('.card').find('.card-body').slideToggle();
//         unfocus(button);
//     });
// }

function bindTabCycling() {
    $('ul.nav-tabs[pode-cycle="True"]').each((i, e) => {
        setInterval(() => {
            var tabId = $(e).find('li.nav-item a.nav-link.active').attr('pode-next');
            moveTab(tabId);
        }, $(e).attr('pode-interval'));
    });
}

// function bindAccordionCycling() {
//     $('div.accordion[pode-cycle="true"]').each((i, e) => {
//         setInterval(() => {
//             var itemId = $(e).find('div.card div.bellow-body.show').attr('pode-next');
//             moveAccordion(itemId);
//         }, $(e).attr('pode-interval'));
//     });
// }

// function bindTimers() {
//     $('span.pode-timer').each((i, e) => {
//         var id = $(e).attr('id');

//         invokeTimer(id);

//         setInterval(() => {
//             invokeTimer(id);
//         }, $(e).attr('pode-interval'));
//     });
// }

// function invokeTimer(timerId) {
//     sendAjaxReq(getComponentUrl(timerId), null, null, true);
// }

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

// function bindTablePagination() {
//     $('nav[role="pagination"] input.page-size').off('keyup').on('keyup', function(e) {
//         e.preventDefault();
//         e.stopPropagation();
//         var size = $(this);

//         // nav
//         var pageNav = size.closest('nav');

//         // on enter, reload table
//         if (isEnterKey(e)) {
//             unfocus(size);

//             loadTable(pageNav.attr('for'), {
//                 page: {
//                     index: 1,
//                     size: parseInt((pageNav.attr('pode-page-size') ?? 20))
//                 },
//                 reload: true
//             });
//         }

//         // otherwise, set the size
//         else {
//             pageNav.attr('pode-page-size', size.val());
//         }
//     });

//     $('nav[role="pagination"] .pagination a.page-link').off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();
//         var link = $(this);

//         // if active/disabled, do nothing
//         if (link.hasClass('active') || link.hasClass('disabled')) {
//             return;
//         }

//         // get page size
//         var pageNav = link.closest('nav');
//         var pageSize = pageNav.attr('pode-page-size') ?? 20;

//         // next or previous? - get current +/-
//         var pageIndex = 1;

//         if (link.hasClass('page-arrows')) {
//             var current = link.closest('ul').find('a.page-link.active').text();

//             if (link.hasClass('page-previous')) {
//                 current--;
//             }
//             else if (link.hasClass('page-next')) {
//                 current++;
//             }
//             else if (link.hasClass('page-first')) {
//                 current = 1;
//             }
//             else if (link.hasClass('page-last')) {
//                 current = link.attr('pode-max');
//             }

//             pageIndex = current;
//         }
//         else {
//             pageIndex = link.text();
//         }

//         loadTable(pageNav.attr('for'), {
//             page: {
//                 index: parseInt(pageIndex),
//                 size: parseInt(pageSize)
//             },
//             reload: true
//         });
//     });
// }

function getTablePaging(table) {
    if (!isTablePaginated(table)) {
        return null;
    }

    var pagination = table.closest('div[role="table"]').find('nav[role="pagination"]');
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

function isTablePaginated(table) {
    if (!table) {
        return false;
    }

    return (table.attr('pode-paginate') == 'true');
}

function getTableSorting(table) {
    if (!isTableSorted(table)) {
        return null;
    }

    var header = table.find('th[sort-direction!="none"]');
    if (header.length == 0) {
        return null;
    }

    header = $(header[0]);
    return {
        column: header.text(),
        direction: header.attr('sort-direction')
    };
}

function isTableSorted(table) {
    if (!table) {
        return;
    }

    return (table.attr('pode-sort') == 'true');
}

// function bindTableSort(tableId) {
//     $(`${tableId}[pode-sort='true'] thead th`).off('click').on('click', function() {
//         var header = $(this);
//         var table = header.parents('table').eq(0);

//         var direction = header.attr('sort-direction') ?? 'none';
//         switch (direction.toLowerCase()) {
//             case 'none': {
//                 direction = 'asc';
//                 break;
//             }

//             case 'asc': {
//                 direction = 'desc';
//                 break;
//             }

//             case 'desc': {
//                 direction = 'asc';
//                 break;
//             }
//         }

//         // save sort direction for current header, and set other headers to none
//         table.find('th').attr('sort-direction', 'none');
//         header.attr('sort-direction', direction);

//         // simple or dynamic?
//         var simple = table.attr('pode-sort-simple') == 'True';
//         if (simple) {
//             sortTable(table, header, direction);
//         }
//         else {
//             loadTable(table.attr('id'), {
//                 sort: {
//                     column: header.text(),
//                     direction: direction
//                 }
//             });
//         }
//     });
// }

// function sortTable(table, header, direction) {
//     var rows = table.find('tr:gt(0)').toArray().sort(comparer(header.index()));

//     if (direction == 'desc') {
//         rows = rows.reverse();
//     }

//     rows.forEach((row) => {
//         table.append(row);
//     });
// }

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

function toggleAttr(element, name, value1, value2) {
    var attr = element.attr(name);
    if (attr == value1) {
        element.attr(name, value2);
    }
    else {
        element.attr(name, value1);
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

function bindRangeValue() {
    $('input[type="range"].pode-range-value').each((index, item) => {
        var target = $(item);
        var value = $(`input#${target.attr('id')}_value`);

        target.on('change', (e) => {
            value.val(target.val());
        });

        value.on('change', (e) => {
            target.val(value.val());
        });
    });
}

function bindProgressValue() {
    $('div.progress div.pode-progress-value').each((index, item) => {
        var target = $(item);

        target.text(`${target.attr('aria-valuenow')} / ${target.attr('aria-valuemax')}`);
        target.on('change', (e) => {
            target.text(`${target.attr('aria-valuenow')} / ${target.attr('aria-valuemax')}`);
        });
    });
}

// function loadTables() {
//     $(`table[pode-dynamic='True']`).each((i, e) => {
//         loadTable($(e).attr('id'));
//     });

//     $(`table[pode-dynamic='False']`).each((i, e) => {
//         hideLoadingSpinner($(e).attr('id'));
//     });
// }

function loadTable(tableId, opts) {
    if (!tableId) {
        return;
    }

    // options
    opts = opts ?? {};

    // ensure the table is dynamic, or has the 'for' attr set
    var table = $(`table#${tableId}`);
    if (!isDynamic(table) && !table.attr('for')) {
        hideLoadingSpinner(tableId);
        return;
    }

    // define any table paging
    var data = '';
    if (opts && opts.page) {
        var pageIndex = (opts.page.index ?? 1);
        var pageSize = (opts.page.size ?? 20);
        data = `PageIndex=${pageIndex}&PageSize=${pageSize}`;
    }
    else if (isTablePaginated(table)) {
        var paging = getTablePaging(table);
        if (paging) {
            data = `PageIndex=${paging.index}&PageSize=${paging.size}`;
        }
    }

    // define any filter value
    var filter = $(`input#filter_${tableId}`);
    if (filter.length > 0) {
        if (data) {
            data += '&';
        }

        data += `Filter=${filter.val()}`;
    }

    // define any sorting
    if (opts && opts.sort) {
        if (data) {
            data += '&';
        }

        data += `SortColumn=${opts.sort.column}&SortDirection=${opts.sort.direction}`;
    }
    else if (isTableSorted(table)) {
        var sorting = getTableSorting(table);
        if (sorting) {
            if (data) {
                data += '&';
            }

            data += `SortColumn=${sorting.column}&SortDirection=${sorting.direction}`;
        }
    }

    // things get funky here if we have a table with a 'for' attr
    // if so, we need to serialize the form, and then send the request to the form instead
    var url = getComponentUrl(table);

    if (table.attr('for')) {
        var form = $(`#${table.attr('for')}`);
        if (data) {
            data += '&';
        }

        data += form.serialize();
        url = form.attr('action');
    }

    // if we're reloading, hide all data and show spinner
    if (opts.reload) {
        table.find('tbody').empty();
        showLoadingSpinner(tableId);
    }

    // invoke and load table content
    sendAjaxReq(url, data, table, true);
}

function loadAutoCompletes() {
    $(`input[pode-autocomplete='True']`).each((i, e) => {
        sendAjaxReq(`${getComponentUrl($(e))}/autocomplete`, null, null, false, (res) => {
            $(e).autocomplete({ source: res.Values });
        });
    });
}

// function loadTiles() {
//     $(`div.pode-tile[pode-dynamic="True"]`).each((i, e) => {
//         loadTile($(e).attr('id'), true);
//     });
// }

// function loadTile(tileId, firstLoad = false) {
//     if (!tileId) {
//         return;
//     }

//     var tile = $(`div.pode-tile[pode-dynamic="True"]#${tileId}`);
//     if (tile.length > 0) {
//         sendAjaxReq(getComponentUrl(tile), null, tile, true);
//     }
//     else if (!firstLoad) {
//         $(`div.pode-tile[pode-dynamic="False"]#${tileId} .pode-tile-body .pode-refresh-btn`).each((i, e) => {
//             $(e).trigger('click');
//         });
//     }
// }

function loadSelects() {
    $(`select[pode-dynamic="True"]`).each((i, e) => {
        loadSelect($(e).attr('id'));
    });
}

function loadSelect(selectId) {
    if (!selectId) {
        return;
    }

    var select = $(`select[pode-dynamic="True"]#${selectId}`);
    if (select.length > 0) {
        sendAjaxReq(getComponentUrl(select), null, select, true);
    }
}

// function bindTileRefresh() {
//     $("div.pode-tile .pode-tile-body .pode-refresh-btn").each((i, e) => {
//         hide($(e));
//     });

//     $("div.pode-tile span.pode-tile-refresh").off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         var icon = $(e.target);
//         icon.tooltip('hide');
//         loadTile(icon.attr('for'));
//     });

//     $("div.pode-tile[pode-auto-refresh='True']").each((i, e) => {
//         var interval = $(e).attr('pode-refresh-interval');

//         var timeout = interval;
//         if (interval == 60000) {
//             timeout = (60 - (new Date()).getSeconds()) * 1000;
//         }

//         setTimeout(() => {
//             loadTile($(e).attr('id'));
//             setInterval(() => {
//                 loadTile($(e).attr('id'));
//             }, interval);
//         }, timeout);
//     });
// }

// function bindTileClick() {
//     $(`div.pode-tile[pode-click="True"]`).off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         var tileId = $(e.target).closest('div.pode-tile').attr('id');
//         var tile = $(`div.pode-tile#${tileId}`);

//         var url = `${getComponentUrl(tile)}/click`;
//         sendAjaxReq(url, null, tile, true);
//     });
// }

function loadCharts() {
    $(`canvas[pode-dynamic='True']`).each((i, e) => {
        loadChart($(e).attr('id'));
    });

    $(`canvas[pode-dynamic='False']`).each((i, e) => {
        hideLoadingSpinner($(e).attr('id'));
    });
}

function loadChart(chartId) {
    if (!chartId) {
        return;
    }

    var chart = $(`canvas#${chartId}`);

    // is this the chart's first load?
    var data = '';
    if (!_charts[chartId] || !_charts[chartId].append) {
        data = 'FirstLoad=1';
    }

    // things get funky here if we have a chart with a 'for' attr
    // if so, we need to serialize the form, and then send the request to the form instead
    var url = getComponentUrl(chart);

    if (chart.attr('for')) {
        var form = $(`#${chart.attr('for')}`);
        if (data) {
            data += '&';
        }

        data += form.serialize();
        url = form.attr('action');
    }

    sendAjaxReq(url, data, chart, true);
}

function invokeActions(actions, sender) {
    if (!actions) {
        return;
    }

    actions = convertToArray(actions);

    actions.forEach((action) => {
        var _type = (action.ObjectType ?? '').toLowerCase();
        var _subType = (action.SubObjectType ?? '').toLowerCase()
        var _operation = (action.Operation ?? 'new').toLowerCase();

        console.log(`[${_operation}] ${_type} {${_subType}}`);

        switch (_type) {
            // case 'table':
            //     actionTable(action, sender);
            //     break;

            // case 'tablerow':
            //     actionTableRow(action, sender);
            //     break;

            // case 'tablecolumn':
            //     actionTableColumn(action);
            //     break;

            case 'chart':
                actionChart(action, sender);
                break;

            // case 'textbox':
            //     actionTextbox(action, sender);
            //     break;

            // case 'toast':
            //     actionToast(action);
            //     break;

            case 'validation':
                actionValidation(action, sender);
                break;

            // case 'form':
            //     PodeElementFactory.invokeClass(_type, _operation, action, sender);
            //     break;

            // case 'container':
            //     PodeElementFactory.invokeClass(_type, _operation, action, sender);
            //     break;

            // case 'text':
            //     PodeElementFactory.invokeClass(_type, _operation, action, sender);
            //     break;

            case 'select':
                actionSelect(action);
                break;

            case 'checkbox':
                actionCheckbox(action);
                break;

            case 'modal':
                actionModal(action, sender);
                break;

            case 'notification':
                actionNotification(action);
                break;

            case 'href':
                actionHref(action);
                break;

            // case 'badge':
            //     PodeElementFactory.invokeClass(_type, _operation, action, sender);
            //     break;

            case 'progress':
                actionProgress(action);
                break;

            case 'tab':
                actionTab(action);
                break;

            // case 'accordion':
            //     actionAccordion(action);
            //     break;

            case 'page':
                actionPage(action);
                break;

            case 'error':
                actionError(action, sender);
                break;

            case 'breadcrumb':
                actionBreadcrumb(action);
                break;

            // case 'tile':
            //     actionTile(action, sender);
            //     break;

            case 'theme':
                actionTheme(action);
                break;

            // case 'component':
            //     actionComponent(action);
            //     break;

            case 'component-style':
                actionComponentStyle(action);
                break;

            case 'component-class':
                actionComponentClass(action);
                break;

            case 'filestream':
                actionFileStream(action);
                break;

            // case 'audio':
            //     actionAudio(action);
            //     break;

            // case 'video':
            //     actionVideo(action);
            //     break;

            case 'code-editor':
                actionCodeEditor(action);
                break;

            // case 'iframe':
            //     actionIFrame(action);
            //     break;

            // case 'button':
                // PodeElementFactory.invokeClass(_type, _operation, action, sender);
                // break;

            default:
                PodeElementFactory.invokeClass(_type, _operation, action, sender, {
                    subType: _subType
                });
                break;
        }
    });
}

function buildElements(elements) {
    var html = '';

    if (!elements) {
        return html;
    }

    elements = convertToArray(elements);

    elements.forEach((ele) => {
        var _type = ele.ObjectType;
        if (_type) {
            _type = _type.toLowerCase();
        }

        switch (_type) {
            case 'button':
                html += buildButton(ele);
                break;

            case 'icon':
                html += buildIcon(ele);
                break;

            case 'badge':
                html += buildBadge(ele);
                break;

            case 'spinner':
                html += buildSpinner(ele);
                break;

            case 'link':
                html += buildLink(ele);
                break;

            default:
                break;
        }
    });

    return html;
}

function bindFormSubmits() {
    // general forms
    // $("form.pode-form").off('submit').on('submit', function(e) {
    //     e.preventDefault();
    //     e.stopPropagation();

    //     // get the form
    //     var form = $(e.target);

    //     // submit the form
    //     var inputs = serializeInputs(form);
    //     sendAjaxReq(form.attr('action'), inputs.data, form, true, null, inputs.opts);
    // });

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

// function bindFormResets() {
//     $('button.form-reset').off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         // get the button
//         var button = getButton(e);

//         // reset
//         resetForm($(`#${button.attr('for')}`));
//         unfocus(button);
//     });
// }

function bindModalSubmits() {
    $("div.modal-content form.pode-form").off('keypress').on('keypress', function(e) {
        if (!isEnterKey(e) || testTagName(e.target, 'textarea')) {
            return;
        }

        e.preventDefault();
        e.stopPropagation();

        var btn = $(this).closest('div.modal-content').find('div.modal-footer button.pode-modal-submit')
        if (btn) {
            btn.trigger('click');
        }
    });

    $("div.modal-footer button.pode-modal-submit").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        // get the button
        var button = getButton(e);

        // get url
        var url = button.attr('pode-url');
        if (!url) {
            return;
        }

        // get the modal
        var modal = button.closest('div.modal');
        if (!modal) {
            return;
        }

        // find a form
        var inputs = {};
        var form = null;
        var method = 'post';

        if (button.attr('pode-modal-form') == 'True') {
            form = modal.find('div.modal-body form');

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
        var dataValue = getDataValue(button);

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
        sendAjaxReq(url, inputs.data, (form ?? button), true, null, inputs.opts);
    });
}

function getDataValue(element) {
    var dataValue = element.attr('pode-data-value');
    if (!dataValue) {
        dataValue = element.closest('[pode-data-value!=""][pode-data-value]').attr('pode-data-value');
    }

    return dataValue;
}

// function bindCodeCopy() {
//     $('pre button.pode-code-copy').off('click').on('click', function(e) {
//         var value = $(e.target).closest('pre').find('code').text().trim();
//         navigator.clipboard.writeText(value);
//     });
// }

function getButton(event) {
    var button = $(event.target);
    if (!testTagName(button, 'button')) {
        button = button.closest('button');
    }

    return button;
}

// function bindButtons() {
//     $("button.pode-button").off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         // get the button
//         var button = getButton(e);
//         button.tooltip('hide');

//         // find a form
//         var inputs = {};

//         var form = button.closest('form');
//         if (form) {
//             inputs = serializeInputs(form);
//         }

//         // get a data value
//         var dataValue = getDataValue(button);
//         if (dataValue) {
//             inputs.data = addFormDataValue(inputs.data, 'Value', dataValue);
//         }

//         var url = getComponentUrl(button);
//         sendAjaxReq(url, inputs.data, button, true, null, inputs.opts);
//     });
// }

function bindNavLinks() {
    $("a.pode-nav-link[pode-dynamic='True']").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var url = `/nav/link/${$(this).attr('id')}`;
        sendAjaxReq(url, null, null, true);
    });
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

// function bindTableFilters() {
//     $("input.pode-table-filter").off('keyup').on('keyup', delay(function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         var input = $(e.target);
//         var simple = input.attr('pode-simple') == 'True';

//         if (simple) {
//             filterTable(input);
//         }
//         else {
//             loadTable(input.attr('for'));
//         }
//     }, 500));
// }

// function filterTable(filter) {
//     if (!filter) {
//         return;
//     }

//     var simple = filter.attr('pode-simple') == 'True';
//     if (!simple) {
//         return;
//     }

//     var tableId = filter.attr('for');
//     var value = filter.val();

//     hide($(`table#${tableId} tbody tr:not(:icontains('${value}'))`));
//     show($(`table#${tableId} tbody tr:icontains('${value}')`));
// }

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

// function bindTableExports() {
//     $("button.pode-table-export").off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         var button = getButton(e);
//         button.tooltip('hide');

//         var tableId = button.attr('for');
//         var csv = exportTableAsCSV(tableId);
//         downloadCSV(csv, getTableFileName(tableId));
//     });
// }

// function bindTableRefresh() {
//     $("button.pode-table-refresh").off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         var button = getButton(e);
//         button.tooltip('hide');
//         loadTable(button.attr('for'));
//     });

//     $("table[pode-auto-refresh='True']").each((index, item) => {
//         var interval = $(item).attr('pode-refresh-interval');

//         var timeout = interval;
//         if (interval == 60000) {
//             timeout = (60 - (new Date()).getSeconds()) * 1000;
//         }

//         setTimeout(() => {
//             loadTable($(item).attr('id'));
//             setInterval(() => {
//                 loadTable($(item).attr('id'));
//             }, interval);
//         }, timeout);
//     });
// }

// function bindTableButtons() {
//     $("button.pode-table-button").off('click').on('click', function(e) {
//         e.preventDefault();
//         e.stopPropagation();

//         var button = getButton(e);
//         button.tooltip('hide');

//         var tableId = button.attr('for');
//         var table = $(`table#${tableId}`);
//         var csv = exportTableAsCSV(tableId);

//         var url = `${getComponentUrl(table)}/button/${button.attr('name')}`;
//         sendAjaxReq(url, csv, table, true, null, { contentType: 'text/csv' });
//     });
// }

function bindChartRefresh() {
    $("button.pode-chart-refresh").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = getButton(e);
        button.tooltip('hide');
        loadChart(button.attr('for'));
    });

    $("canvas[pode-auto-refresh='True']").each((index, item) => {
        var interval = $(item).attr('pode-refresh-interval');

        var timeout = interval;
        if (interval == 60000) {
            timeout = (60 - (new Date()).getSeconds()) * 1000;
        }

        setTimeout(() => {
            loadChart($(item).attr('id'));
            setInterval(() => {
                loadChart($(item).attr('id'));
            }, interval);
        }, timeout);
    });
}

// function actionTableRow(action, sender) {
//     switch (action.Operation.toLowerCase()) {
//         case 'update':
//             updateTableRow(action);
//             break;
//     }
// }

// function updateTableRow(action) {
//     // ensure the table exists
//     var table = getElementByNameOrId(action, 'table');
//     if (!table || table.length == 0) {
//         return;
//     }

//     var tableId = `table#${getId(table)}`;

//     // get the table row
//     var row = null;
//     switch (action.Row.Type) {
//         case 'id_and_datavalue':
//         case 'name_and_datavalue':
//             row = table.find(`tbody tr[pode-data-value="${action.Row.DataValue}"]`);
//             break;

//         case 'id_and_index':
//         case 'name_and_index':
//             row = table.find('tbody tr').eq(action.Row.Index);
//             break;
//     }

//     // do nothing if no row
//     if (!row || row.length == 0) {
//         return;
//     }

//     // update the row's data
//     if (action.Data) {
//         var keys = Object.keys(action.Data);

//         keys.forEach((key) => {
//             var _html = '';
//             var _value = action.Data[key];

//             if (Array.isArray(_value) || _value.ObjectType) {
//                 _html += buildElements(_value);
//             }
//             else {
//                 _html += _value;
//             }

//             row.find(`td[pode-column="${key}"]`).html(_html);
//         });
//     }

//     // update the row's background colour
//     setObjectStyle(row[0], 'background-color', action.BackgroundColour);

//     // update the row's forecolour
//     setObjectStyle(row[0], 'color', action.Colour);

//     // binds sort/buttons/etc
//     $('[data-toggle="tooltip"]').tooltip();
//     bindButtons();

//     // setup clickable rows
//     bindTableClickableRows(tableId);
// }

// function actionTableColumn(action) {
//     switch (action.Operation.toLowerCase()) {
//         case 'hide':
//             hideTableColumn(action);
//             break;

//         case 'show':
//             showTableColumn(action);
//             break;
//     }
// }

// function hideTableColumn(action) {
//     var table = getElementByNameOrId(action, 'table');
//     if (!table) {
//         return;
//     }

//     addClass(table.find(`thead th[name="${action.Key}"]`), 'd-none');
//     addClass(table.find(`tbody td[pode-column="${action.Key}"]`), 'd-none');
// }

// function showTableColumn(action) {
//     var table = getElementByNameOrId(action, 'table');
//     if (!table) {
//         return;
//     }

//     removeClass(table.find(`thead th[name="${action.Key}"]`), 'd-none', true);
//     removeClass(table.find(`tbody td[pode-column="${action.Key}"]`), 'd-none', true);
// }

function getQueryStringValue(name) {
    if (!window.location.search) {
        return null;
    }

    return (new URLSearchParams(window.location.search)).get(name);
}

function bindTableClickableRows(tableId) {
    $(`${tableId}.pode-table-click tbody tr`).off('click').on('click', function() {
        var rowId = $(this).attr('pode-data-value');
        var table = $(tableId);

        // check if we have a base path
        var base = getQueryStringValue('base');
        var value = getQueryStringValue('value');

        if (base) {
            base = `${base}/${value}`;
        }
        else {
            base = value;
        }

        // build the data to send
        var data = `value=${rowId}`;
        if (base) {
            data = `base=${base}&${data}`;
        }

        if (table.attr('pode-click-dynamic') == 'True') {
            var url = `${getComponentUrl(table)}/click`;
            sendAjaxReq(url, data, null, true);
        }
        else {
            window.location = `${window.location.origin}${window.location.pathname}?${data}`;
        }
    });
}

function actionTable(action, sender) {
    switch (action.Operation.toLowerCase()) {
        case 'update':
            updateTable(action, sender);
            break;

        case 'output':
            writeTable(action, sender);
            break;

        case 'sync':
            syncTable(action);
            break;

        case 'clear':
            clearTable(action);
            break;
    }
}

function clearTable(action) {
    if (!action.ID && !action.Name) {
        return;
    }

    // get table
    var table = getElementByNameOrId(action, 'table');
    var tableId = `table#${getId(table)}`;

    // empty table
    $(`${tableId} tbody`).empty();

    // empty paging
    if (isTablePaginated(table)) {
        table.closest('div[role="table"]').find('nav ul').empty();
    }
}

function syncTable(action) {
    var table = getElementByNameOrId(action, 'table', null, '[pode-dynamic="True"]');
    if (!table) {
        return;
    }

    loadTable(getId(table));
}

function showLoadingSpinner(elementId) {
    $(`span#${elementId}_spinner`).show();
}

function hideLoadingSpinner(elementId) {
    $(`span#${elementId}_spinner`).hide();
}


// function updateTable(action, sender) {
//     // convert data to array
//     action.Data = convertToArray(action.Data);

//     // table meta
//     var table = getElementByNameOrId(action, 'table');
//     var tableId = getId(table);
//     var fullTableId = `table#${tableId}`;

//     var tableHead = $(`${fullTableId} thead`);
//     var tableBody = $(`${fullTableId} tbody`);
//     var isPaginated = isTablePaginated(table);

//     // get custom column meta - for widths etc
//     var columns = {};
//     if (action.Columns) {
//         columns = action.Columns;
//     }

//     // render initial columns?
//     var _value = '';
//     var _direction = 'none';
//     var _columnHidden = false;

//     var columnKeys = Object.keys(columns);

//     if (tableHead.find('th').length == 0 && columnKeys.length > 0) {
//         _value = '<tr>';

//         columnKeys.forEach((key) => {
//             _value += buildTableHeader(columns[key], _direction);
//         });

//         _value += '</tr>';
//         tableHead.append(_value);
//     }

//     // clear the table if no data
//     if (action.Data.length <= 0) {
//         // empty table
//         tableBody.empty();

//         // empty paging
//         if (isPaginated) {
//             table.closest('div[role="table"]').find('nav ul').empty();
//         }

//         // hide spinner
//         hideLoadingSpinner(tableId);
//         return;
//     }

//     // get data keys for table columns
//     var keys = Object.keys(action.Data[0]);

//     // get senderId if present, and set on table as 'for'
//     var senderId = getId(sender);
//     if (senderId && getTagName(sender) == 'form') {
//         table.attr('for', senderId);
//     }

//     // is there a data column?
//     var dataColumn = table.attr('pode-data-column');

//     // table headers
//     _value = '<tr>';
//     var _oldHeader = null;
//     var _header = null;

//     keys.forEach((key) => {
//         // table header sort direction
//         _oldHeader = tableHead.find(`th[name='${key}']`);
//         if (_oldHeader.length > 0) {
//             _direction = _oldHeader.attr('sort-direction');
//             _columnHidden = _oldHeader.hasClass('d-none');
//         }
//         else {
//             _direction = 'none';
//             _columnHidden = false;
//         }

//         // add the table header
//         if (key in columns) {
//             _value += buildTableHeader(columns[key], _direction, _columnHidden);
//         }
//         else {
//             if (_oldHeader.length > 0) {
//                 _value += _oldHeader[0].outerHTML;
//             }
//             else {
//                 _value += `<th sort-direction='${_direction}' name='${key}'>${key}</th>`;
//             }
//         }
//     });
//     _value += '</tr>';

//     tableHead.empty();
//     tableHead.append(_value);

//     // table body
//     tableBody.empty();

//     action.Data.forEach((item) => {
//         _value = `<tr ${item[dataColumn] != null ? `pode-data-value="${item[dataColumn]}"` : ''}>`;

//         keys.forEach((key) => {
//             _header = tableHead.find(`th[name='${key}']`);
//             if (_header.length > 0) {
//                 _value += `<td pode-column='${key}' style='`;

//                 if (_header.css('text-align')) {
//                     _value += `text-align:${_header.css('text-align')};`;
//                 }

//                 _value += "'";

//                 if (_header.hasClass('d-none')) {
//                     _value += ` class='d-none'`;
//                 }

//                 _value += ">";
//             }
//             else {
//                 _value += `<td pode-column='${key}'>`;
//             }

//             if (Array.isArray(item[key]) || (item[key] && item[key].ObjectType)) {
//                 _value += buildElements(item[key]);
//             }
//             else if (item[key] != null) {
//                 _value += item[key];
//             }
//             else if (!item[key] && _header.length > 0) {
//                 _value += _header.attr('default-value');
//             }

//             _value += `</td>`;
//         });
//         _value += '</tr>';
//         tableBody.append(_value);
//     });

//     // hide spinner
//     hideLoadingSpinner(tableId);

//     // is the table paginated?
//     if (isPaginated) {
//         buildTablePaging(table, action.Paging.Index, action.Paging.Max, action.Paging.Size);
//     }

//     // binds sort/buttons/etc
//     $('[data-toggle="tooltip"]').tooltip();
//     bindTableSort(fullTableId);
//     bindButtons();
//     bindTablePagination();

//     // setup table filter
//     filterTable(table.closest('div.card-body').find('input.pode-table-filter'));

//     // setup clickable rows
//     bindTableClickableRows(fullTableId);
// }

// function buildTablePaging(table, currentIndex, totalPages, size) {
//     var paging = table.closest('div[role="table"]').find('nav ul');
//     var parent = paging.parent();

//     parent.find('input.page-size').remove();
//     paging.empty();

//     // current page
//     parent.attr('pode-current-page', currentIndex);

//     // page size
//     parent.prepend(`<input type="number" id="${parent.attr('for')}_size" class="form-control page-size" value="${size}" min="1">`);

//     // if there is only 1 total page, don't even bother showing pagination
//     if (totalPages <= 1) {
//         return;
//     }

//     // first
//     paging.append(`
//         <li class="page-item">
//             <a class="page-link page-arrows page-first" href="#" aria-label="First" title="First (1)" data-toggle="tooltip">
//                 <span aria-hidden="true">&lt;&lt;</span>
//             </a>
//         </li>`);

//     // previous
//     paging.append(`
//         <li class="page-item">
//             <a class="page-link page-arrows page-previous" href="#" aria-label="Previous" title="Previous" data-toggle="tooltip">
//                 <span aria-hidden="true">&lt;</span>
//             </a>
//         </li>`);

//     var pageActive = '';

//     // pages
//     var gap = (currentIndex == 1 || currentIndex == totalPages ? 2 : 1);

//     for (var i = (currentIndex - gap); i <= (currentIndex + gap); i++) {
//         if (i < 1 || i > totalPages) {
//             continue;
//         }

//         pageActive = (i == currentIndex ? 'active' : '');
//         paging.append(`
//             <li class="page-item">
//                 <a class="page-link ${pageActive}" href="#">${i}</a>
//             </li>`);
//     }

//     // next
//     paging.append(`
//         <li class="page-item">
//             <a class="page-link page-arrows page-next" href="#" aria-label="Next" pode-max="${totalPages}" title="Next" data-toggle="tooltip">
//                 <span aria-hidden="true">&gt;</span>
//             </a>
//         </li>`);

//     // last
//     paging.append(`
//         <li class="page-item">
//             <a class="page-link page-arrows page-last" href="#" aria-label="Last" pode-max="${totalPages}" title="Last (${totalPages})" data-toggle="tooltip">
//                 <span aria-hidden="true">&gt;&gt;</span>
//             </a>
//         </li>`);
// }

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

function writeTable(action, sender) {
    var senderId = getId(sender);
    var tableId = `table_${senderId}`;

    // create table
    var table = $(`table#${tableId}`);
    if (table.length == 0) {
        sender.after(`
            <table id="${tableId}" class="table table-striped table-sm" pode-sort="${action.Sort}">
                <thead></thead>
                <tbody></tbody>
            </table>
        `);
    }

    // update
    action.ID = tableId;
    updateTable(action, sender);
}

function getId(element) {
    if (!element) {
        return null;
    }

    return $(element).attr('id');
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

// function actionForm(action) {
//     switch (action.Operation.toLowerCase()) {
//         case 'reset':
//             resetForm(getElementByNameOrId(action, 'form'));
//             break;

//         case 'submit':
//             submitForm(getElementByNameOrId(action, 'form'));
//             break;
//     }
// }

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

function submitForm(form, isInner = false) {
    if (!form) {
        return;
    }

    if (testTagName(form, 'form')) {
        $(form[0]).find('[type="submit"]').trigger('click');
    }
    else if (isInner) {
        return;
    }
    else {
        submitForm(form.find('form'), true);
    }
}

function getElementByNameOrId(action, tag, sender, filter) {
    if (!action) {
        return null;
    }

    tag = tag ?? '';
    filter = filter ?? '';

    // by ID
    if (action.ID) {
        return $(`${tag}#${action.ID}${filter}`);
    }

    // by Name
    if (action.Name) {
        if (!tag && action.Type) {
            tag = `[pode-object="${action.Type}"]`;
        }

        if (sender) {
            return sender.find(`${tag}[name="${action.Name}"]${filter}`);
        }

        return $(`${tag}[name="${action.Name}"]${filter}`);
    }

    return null;
}

function actionModal(action, sender) {
    switch (action.Operation.toLowerCase()) {
        case 'hide':
            hideModal(action, sender);
            break;

        case 'show':
            showModal(action);
            break;
    }
}

function showModal(action) {
    var modal = getElementByNameOrId(action, 'div.modal');
    if (!modal) {
        return;
    }

    if (action.DataValue) {
        modal.attr('pode-data-value', action.DataValue);
    }

    resetForm(modal);
    removeValidationErrors(modal);

    invokeActions(action.Actions);
    modal.modal('show');
}

function hideModal(action, sender) {
    var modal = getElementByNameOrId(action, 'div.modal');
    if (!modal) {
        modal = sender.closest('div.modal');
    }

    if (!modal) {
        return;
    }

    resetForm(modal);
    removeValidationErrors(modal);

    modal.modal('hide');
}

// function actionText(action) {
//     if (!action) {
//         return;
//     }

//     var text = $(`#${action.ID}`);
//     if (!text) {
//         return;
//     }

//     if (!text.hasClass('pode-text')) {
//         var subText = text.find('.pode-text');
//         text = subText.length == 0 ? text : subText;
//     }

//     text.text(decodeHTML(action.Value));
// }

// function actionTile(action, sender) {
//     if (!action) {
//         return;
//     }

//     switch (action.Operation.toLowerCase()) {
//         case 'update':
//             updateTile(action, sender);
//             break;

//         case 'sync':
//             syncTile(action);
//             break;
//     }
// }

// function updateTile(action, sender) {
//     var tile = getElementByNameOrId(action, 'div.pode-tile');
//     if (!tile) {
//         return;
//     }

//     // change the tile's value
//     if (action.Value) {
//         tile.find('.pode-text').text(decodeHTML(action.Value));
//     }

//     // change colour
//     if (action.Colour) {
//         removeClass(tile, 'alert-\\w+');
//         addClass(tile, `alert-${action.ColourType}`);
//     }
// }

// function syncTile(action) {
//     var tile = getElementByNameOrId(action, 'div', null, '[pode-dynamic="True"]');
//     if (!tile) {
//         return;
//     }

//     loadTile(getId(tile));
// }

function actionComponentClass(action) {
    if (!action) {
        return;
    }

    switch (action.Operation.toLowerCase()) {
        case 'add':
            addComponentClass(action);
            break;

        case 'remove':
            removeComponentClass(action);
            break;
    }
}

function addComponentClass(action) {
    var obj = getElementByNameOrId(action);
    if (!obj) {
        return;
    }

    addClass(obj, action.Class);
}

function removeComponentClass(action) {
    var obj = getElementByNameOrId(action);
    if (!obj) {
        return;
    }

    removeClass(obj, action.Class, true);
}

function actionComponentStyle(action) {
    if (!action) {
        return;
    }

    switch (action.Operation.toLowerCase()) {
        case 'set':
        case 'remove':
            updateComponentStyle(action);
            break;
    }
}

function updateComponentStyle(action) {
    var obj = getElementByNameOrId(action);
    if (!obj) {
        return;
    }

    setObjectStyle(obj[0], action.Property, action.Value);
}

function setObjectStyle(obj, property, value) {
    if (value) {
        obj.style.setProperty(property, value, 'important');
    }
    else {
        obj.style.setProperty(property, null);
    }
}

// function actionComponent(action) {
//     if (!action) {
//         return;
//     }

//     switch (action.Operation.toLowerCase()) {
//         case 'show':
//         case 'hide':
//             toggleComponent(action, action.Operation.toLowerCase());
//             break;
//     }
// }

function toggleComponent(action, toggle) {
    var obj = getElementByNameOrId(action);
    if (!obj) {
        return;
    }

    if (toggle == 'show') {
        obj.show();
    }
    else {
        obj.hide();
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

function actionSelect(action) {
    if (!action) {
        return;
    }

    switch (action.Operation.toLowerCase()) {
        case 'set':
            setSelect(action);
            break;

        case 'update':
            updateSelect(action);
            break;

        case 'clear':
            clearSelect(action);
            break;

        case 'sync':
            syncSelect(action);
            break;
    }
}

function setSelect(action) {
    var select = getElementByNameOrId(action, 'select');
    if (!select) {
        return;
    }

    setSelectValue(select, action.Value);
}

function setSelectValue(select, value) {
    if (!select || !value) {
        return
    }

    select.val(decodeHTML(value));
}

function updateSelect(action) {
    var select = getElementByNameOrId(action, 'select');
    if (!select) {
        return;
    }

    select.empty();

    action.Options = convertToArray(action.Options);
    if (action.Options.Length <= 0) {
        return;
    }

    action.DisplayOptions = convertToArray(action.DisplayOptions);
    action.SelectedValue = convertToArray(action.SelectedValue);

    action.Options.forEach((opt, idx) => {
        var optSelected = '';
        if (action.SelectedValue.includes(opt) == true) {
            optSelected = ' selected';
        }
        select.append(`<option value="${opt}"${optSelected}>${action.DisplayOptions[idx]}</option>`);
    })
}

function clearSelect(action) {
    var select = getElementByNameOrId(action, 'select');
    if (!select) {
        return;
    }

    select.empty();
}

function syncSelect(action) {
    var select = getElementByNameOrId(action, 'select', null, '[pode-dynamic="True"]');
    if (!select) {
        return;
    }

    loadSelect(getId(select));
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

// function actionButton(action) {
//     switch (action.Operation.toLowerCase()) {
//         case 'update':
//             updateButton(action);
//             break;

//         case 'invoke':
//             invokeButton(action);
//             break;

//         case 'enable':
//         case 'disable':
//             toggleButtonState(action, action.Operation.toLowerCase());
//             break;
//     }
// }

function getButtonElement(action) {
    var btn = getElementByNameOrId(action, 'button');
    if (btn.length == 0) {
        btn = getElementByNameOrId(action, 'a', null, "[role='button']");
    }

    return btn;
}

function updateButton(action) {
    var btn = getButtonElement(action);
    if (!btn) {
        return;
    }

    var isIconOnly = hasClass(btn, 'btn-icon-only', true);

    // change the display name (and icon?)
    if (action.Icon) {
        replaceClass(btn.find('span.mdi'), 'mdi-\\w+', `mdi-${action.Icon.toLowerCase()}`);
    }

    if (action.DisplayName) {
        if (isIconOnly) {
            setTitle(btn, action.DisplayName);
        }
        else {
            btn.find('span.pode-text').text(decodeHTML(action.DisplayName));
        }
    }

    // change colour
    if (!isIconOnly && (action.Colour || action.ColourState != 'unchanged')) {
        var isOutline = hasClass(btn, 'btn-outline-\\w+');
        var colour = btn.attr('pode-colour');

        var _class = isOutline ? `btn-outline-${colour}` : `btn-${colour}`;
        removeClass(btn, _class, true);

        if (action.ColourState != 'unchanged') {
            isOutline = (action.ColourState == 'outline');
        }

        if (action.Colour) {
            colour = action.ColourType;
            btn.attr('pode-colour', colour);
        }

        _class = isOutline ? `btn-outline-${colour}` : `btn-${colour}`;
        addClass(btn, _class);
    }

    // change size
    if (!isIconOnly && (action.Size || action.SizeState != 'unchanged')) {
        if (action.SizeState != 'unchanged') {
            if (action.SizeState == 'normal') {
                removeClass(btn, 'btn-block', true);
            }
            else {
                addClass(btn, 'btn-block');
            }
        }

        if (action.Size) {
            replaceClass(btn, 'btn-(sm|lg)', action.SizeType);
        }
    }
}

function invokeButton(action) {
    var btn = getButtonElement(action);
    if (!btn) {
        return;
    }

    btn.click();
}

function toggleButtonState(action, toggle) {
    var btn = getButtonElement(action);
    if (!btn) {
        return;
    }

    if (toggle == 'enable') {
        enable(btn);
    }
    else {
        disable(btn);
    }
}

function actionCheckbox(action) {
    switch (action.Operation.toLowerCase()) {
        case 'update':
            updateCheckbox(action);
            break;

        case 'enable':
        case 'disable':
            toggleCheckboxState(action, action.Operation.toLowerCase());
            break;
    }
}

function updateCheckbox(action) {
    if (action.ID) {
        action.ID = `${action.ID}_option${action.OptionId}`;
    }

    var checkbox = getElementByNameOrId(action, 'input', null, `[pode-option-id="${action.OptionId}"]`);
    if (!checkbox) {
        return;
    }

    // check/uncheck
    checkbox.attr('checked', action.Checked);

    // enable/disable
    if (action.State == 'enabled') {
        enable(checkbox);
    }
    else if (action.State == 'disabled') {
        disable(checkbox);
    }
}

function toggleCheckboxState(action, toggle) {
    if (action.ID) {
        action.ID = `${action.ID}_option${action.OptionId}`;
    }

    var checkbox = getElementByNameOrId(action, 'input', null, `[pode-option-id="${action.OptionId}"]`);
    if (!checkbox) {
        return;
    }

    if (toggle == 'enable') {
        enable(checkbox);
    }
    else {
        disable(checkbox);
    }
}

function actionToast(action) {
    var toastArea = $('div#toast-area');
    if (toastArea.length == 0) {
        return;
    }

    var toastCount = $('.toast').length;
    var toastId = `toast${toastCount + 1}`;

    toastArea.append(`
        <div id="${toastId}" class="toast" role="alert" aria-live="assertive" aria-atomic="true" data-delay="${action.Duration}">
            <div class="toast-header">
                <span class='mdi mdi-${action.Icon.toLowerCase()}'></span>
                <strong class="mr-auto mLeft05">${action.Title}</strong>
                <button type="button" class="ml-2 mb-1 close" data-dismiss="toast" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="toast-body">
                ${action.Message}
            </div>
        </div>
    `);

    $(`div#${toastId}`).on('hidden.bs.toast', function(e) {
        $(e.target).remove();
    })

    $(`div#${toastId}`).toast('show');
}

function actionValidation(action, sender) {
    var input = getElementByNameOrId(action, null, sender);
    if (!input) {
        return;
    }

    var validationId = `div#${$(input).attr('id')}_validation`;
    $(validationId).text(decodeHTML(action.Message));

    setValidationError(input);
}

// function actionTextbox(action, sender) {
//     switch (action.Operation.toLowerCase()) {
//         case 'update':
//             updateTextbox(action);
//             break;

//         case 'output':
//             writeTextbox(action, sender);
//             break;

//         case 'clear':
//             clearTextbox(action);
//             break;
//     }
// }

// function clearTextbox(action) {
//     var txt = action.Multiline
//         ? getElementByNameOrId(action, 'textarea')
//         : getElementByNameOrId(action, 'input');

//     txt.val('');
// }

// function updateTextbox(action) {
//     if (!action.Value) {
//         return;
//     }

//     var txt = action.Multiline
//         ? getElementByNameOrId(action, 'textarea')
//         : getElementByNameOrId(action, 'input');

//     if (action.AsJson) {
//         action.Value = JSON.stringify(action.Value, null, 4);
//     }

//     txt.val(action.Value);
// }

// function writeTextbox(action, sender) {
//     var senderId = getId(sender);
//     var txtId = `txt_${senderId}`;

//     // create textbox
//     var element = null;
//     var txt = null;

//     // default attrs
//     var readOnly = '';
//     if (action.ReadOnly) {
//         readOnly ='readonly';
//     }

//     // build the element
//     if (action.Multiline) {
//         txt = $(`textarea#${txtId}`);
//         if (txt.length == 0) {
//             element = `<textarea class='form-control' id='${txtId}' rows='${action.Size}' ${readOnly}></textarea>`;
//         }
//     }
//     else {
//         txt = $(`input#${txtId}`);
//         if (txt.length == 0) {
//             element = `<input type='text' class='form-control' id='${txtId}' ${readOnly}>`;
//         }
//     }

//     if (element) {
//         if (action.Preformat) {
//             element = `<pre>${element}</pre>`;
//         }

//         sender.after(element);
//     }

//     // update
//     action.ID = txtId;
//     updateTextbox(action);
// }

// function exportTableAsCSV(tableId) {
//     var csv = [];
//     var rows = $(`table#${tableId} tr:visible`);

//     if (!rows || rows.length == 0) {
//         return;
//     }

//     rows.each((i, row) => {
//         var data = [];
//         var cols = $(row).find('td, th');

//         cols.each((i, col) => {
//             data.push(col.innerText);
//         });

//         csv.push(data.join(","));
//     });

//     return csv.join("\n");
// }

// function getTableFileName(tableId) {
//     var tableName = $(`table#${tableId}`).attr('name').replace(' ', '_');
//     return `${tableName}.csv`
// }

// function downloadCSV(csv, filename) {
//     // the csv file
//     var csvFile = new Blob([csv], { type: "text/csv" });

//     // build a hidden download link
//     var downloadLink = document.createElement('a');
//     downloadLink.download = filename;
//     downloadLink.href = window.URL.createObjectURL(csvFile);
//     downloadLink.style.display = 'none';

//     // add the link, and click it
//     document.body.appendChild(downloadLink);
//     downloadLink.click();

//     // remove the link
//     $(downloadLink).remove();
// }

// function actionAudio(action) {
//     switch(action.Operation.toLowerCase()) {
//         case 'start':
//         case 'stop':
//             toggleMedia(action, action.Operation.toLowerCase(), 'audio');
//             break;

//         case 'reset':
//             resetMedia(action, 'audio');
//             break;

//         case 'update':
//             updateAudio(action);
//             break;
//     }
// }

// function toggleMedia(action, toggle, tag) {
//     var media = getElementByNameOrId(action, tag);
//     if (!media) {
//         return;
//     }

//     // play
//     if (toggle == 'start') {
//         media[0].play();
//     }

//     // pause
//     else {
//         media[0].pause();
//     }
// }

// function resetMedia(action, tag) {
//     var media = getElementByNameOrId(action, tag);
//     if (!media) {
//         return;
//     }

//     reloadMedia(media);
// }

// function reloadMedia(media) {
//     if (!media) {
//         return;
//     }

//     media[0].load();
// }

// function updateAudio(action) {
//     var audio = getElementByNameOrId(action, 'audio');
//     if (!audio) {
//         return;
//     }

//     // update and reload if we did something
//     if (updateMediaSourceTracks(audio, action.Sources, action.Tracks)) {
//         reloadMedia(audio);
//     }
// }

// function updateMediaSourceTracks(media, sources, tracks) {
//     if (!media) {
//         return false;
//     }

//     // do nothing if no sources/tracks
//     if (!sources && !tracks) {
//         return false;
//     }

//     // clear sources/tracks - both for new sources, only tracks for just tracks
//     if (sources) {
//         media.find('source, track').remove();
//     }
//     else {
//         media.find('track').remove();
//     }

//     // add sources
//     convertToArray(sources).forEach((src) => {
//         media.append(`<source src='${src.Url}' type='${src.Type}'>`);
//     });

//     // add tracks
//     convertToArray(tracks).forEach((track) => {
//         media.append(`<track src='${track.Url}' kind='${track.Type}' srclang='${track.Language}' label='${track.Title}' ${track.Default ? 'default' : ''}>`);
//     });

//     return true;
// }

// function actionVideo(action) {
//     switch(action.Operation.toLowerCase()) {
//         case 'start':
//         case 'stop':
//             toggleMedia(action, action.Operation.toLowerCase(), 'video');
//             break;

//         case 'reset':
//             resetMedia(action, 'video');
//             break;

//         case 'update':
//             updateVideo(action);
//             break;
//     }
// }

// function updateVideo(action) {
//     var video = getElementByNameOrId(action, 'video');
//     if (!video) {
//         return;
//     }

//     var _updated = false;

//     // update source/tracks
//     _updated = updateMediaSourceTracks(video, action.Sources, action.Tracks);

//     // update thumbnail
//     if (action.Thumbnail) {
//         video.attr('thumbnail', action.Thumbnail);
//         _updated = true;
//     }

//     // reload
//     if (_updated) {
//         reloadMedia(video);
//     }
// }

function actionFileStream(action) {
    switch (action.Operation.toLowerCase()) {
        case 'update':
            updateFileStream(action);
            break;

        case 'stop':
            stopFileStream(action);
            break;

        case 'start':
            startFileStream(action);
            break;

        case 'restart':
            stopFileStream(action);
            clearFileStream(action);
            startFileStream(action);
            break;

        case 'clear':
            clearFileStream(action);
            break;
    }
}

// function actionIFrame(action) {
//     switch(action.Operation.toLowerCase()) {
//         case 'update':
//             updateIFrame(action);
//             break;
//     }
// }

// function updateIFrame(action) {
//     var iframe = getElementByNameOrId(action, 'iframe');
//     if (!iframe) {
//         return;
//     }

//     // set url
//     if (action.Url) {
//         iframe.attr('src', action.Url);
//     }

//     // set title
//     if (action.Title) {
//         iframe.attr('title', action.Title);
//     }
// }

function actionCodeEditor(action) {
    switch(action.Operation.toLowerCase()) {
        case 'update':
            updateCodeEditor(action);
            break;

        case 'clear':
            clearCodeEditor(action);
            break;
    }
}

function updateCodeEditor(action) {
    var editor = getElementByNameOrId(action, 'div');
    if (!editor) {
        return;
    }

    editor = _editors[editor.attr('id')];
    if (!editor) {
        return;
    }

    // set value
    if (action.Value) {
        editor.setValue(action.Value);
    }

    // set language
    if (action.Language) {
        monaco.editor.setModelLanguage(editor.getModel(), action.Language);
    }
}

function clearCodeEditor(action) {
    var editor = getElementByNameOrId(action, 'div');
    if (!editor) {
        return;
    }

    editor = _editors[editor.attr('id')];
    if (!editor) {
        return;
    }

    editor.setValue('');
}

function updateFileStream(action) {
    var filestream = getElementByNameOrId(action, 'textarea');
    if (!filestream) {
        return;
    }

    if (action.Url && filestream.attr('pode-file') != action.Url) {
        stopFileStream(action);
        clearFileStream(action);
        filestream.attr('pode-file', action.Url);
        startFileStream(action);
    }
}

function stopFileStream(action) {
    var filestream = getElementByNameOrId(action, 'textarea');
    if (!filestream) {
        return;
    }

    filestream.attr('pode-streaming', '0');

    var button = filestream.closest('div.file-stream').find('button.pode-stream-pause span');
    if (!button.hasClass('mdi-play')) {
        toggleIcon(button, 'pause', 'play', 'Pause', 'Play');
    }
}

function startFileStream(action) {
    var filestream = getElementByNameOrId(action, 'textarea');
    if (!filestream) {
        return;
    }

    filestream.attr('pode-streaming', '1');

    var button = filestream.closest('div.file-stream').find('button.pode-stream-pause span');
    if (!button.hasClass('mdi-pause')) {
        toggleIcon(button, 'pause', 'play', 'Pause', 'Play');
    }
}

function clearFileStream(action) {
    var filestream = getElementByNameOrId(action, 'textarea');
    if (!filestream) {
        return;
    }

    filestream.text('');
    filestream.attr('pode-length', 0);
    filestream.scrollTop = filestream.scrollHeight;
}

function actionChart(action, sender) {
    switch (action.Operation.toLowerCase()) {
        case 'update':
            updateChart(action, sender);
            break;

        case 'output':
            writeChart(action, sender);
            break;

        case 'sync':
            syncChart(action);
            break;

        case 'clear':
            clearChart(action);
            break;
    }
}

function clearChart(action) {
    if (!action.ID && !action.Name) {
        return;
    }

    var chart = getElementByNameOrId(action, 'canvas');
    var id = getId(chart);

    var _chart = _charts[id];

    // clear labels (x-axis)
    _chart.canvas.data.labels = [];

    // clear data (y-axis)
    _chart.canvas.data.datasets.forEach((dataset) => {
        dataset.data = [];
    });

    // re-render
    _chart.canvas.update();
}

function syncChart(action) {
    var chart = getElementByNameOrId(action, 'canvas', null, '[pode-dynamic="True"]');
    if (!chart) {
        return;
    }

    loadChart(getId(chart));
}

var _charts = {};

function updateChart(action, sender) {
    if (!action.Data) {
        return;
    }

    var canvas = getElementByNameOrId(action, 'canvas');
    action.ID = getId(canvas);

    action.Data = convertToArray(action.Data);
    if (action.Data.length <= 0) {
        hideLoadingSpinner(action.ID);
        return;
    }

    var _append = (canvas.attr('pode-append') == 'True');
    var _chart = _charts[action.ID];

    // append new data
    if (_append && _chart) {
        appendToChart(canvas, action);
    }

    // update the chart with new data
    else if (_chart) {
        updateTheChart(canvas, action);
    }

    // build the chart
    else {
        createTheChart(canvas, action, sender);
    }

    hideLoadingSpinner(action.ID);
}

function appendToChart(canvas, action) {
    var _chart = _charts[action.ID];
    var _max = canvas.attr('pode-max');
    var _timeLabels = (canvas.attr('pode-time-labels') == 'True');

    // labels (x-axis)
    action.Data.forEach((item) => {
        if (_timeLabels) {
            _chart.canvas.data.labels.push(getTimeString());
        }
        else {
            _chart.canvas.data.labels.push(item.Key);
        }
    });

    _chart.canvas.data.labels = truncateArray(_chart.canvas.data.labels, _max);

    // data (y-axis)
    action.Data.forEach((item) => {
        item.Values.forEach((set, index) => {
            _chart.canvas.data.datasets[index].data.push(set.Value);
        });
    });

    _chart.canvas.data.datasets.forEach((dataset) => {
        dataset.data = truncateArray(dataset.data, _max);
    });

    // re-render
    _chart.canvas.update();
}

function updateTheChart(canvas, action) {
    var _chart = _charts[action.ID];
    var _timeLabels = (canvas.attr('pode-time-labels') == 'True');

    _chart.canvas.data.labels = [];
    _chart.canvas.data.datasets.forEach((a) => a.data = []);

    // labels (x-axis)
    action.Data.forEach((item) => {
        if (_timeLabels) {
            _chart.canvas.data.labels.push(getTimeString());
        }
        else {
            _chart.canvas.data.labels.push(item.Key);
        }
    });

    // data (y-axis)
    action.Data.forEach((item) => {
        item.Values.forEach((set, index) => {
            _chart.canvas.data.datasets[index].data.push(set.Value);
        });
    });

    // re-render
    _chart.canvas.update();
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

function createTheChart(canvas, action, sender) {
    // remove chart
    var _chart = _charts[action.ID];
    if (_chart) {
        _chart.canvas.destroy();
    }

    // get the chart's canvas and type
    var ctx = document.getElementById(action.ID).getContext('2d');
    var chartType = (canvas.attr('pode-chart-type') || action.ChartType);
    var theme = getPodeTheme();
    var _append = (canvas.attr('pode-append') == 'True');
    var _timeLabels = (canvas.attr('pode-time-labels') == 'True');

    // get senderId if present, and set on canvas as 'for'
    var senderId = getId(sender);
    if (senderId && getTagName(sender) == 'form') {
        canvas.attr('for', senderId);
    }

    // colours for lines/bars/segments
    var palette = getChartColourPalette(theme, canvas);

    // x-axis labels
    var xAxis = [];
    action.Data.forEach((item) => {
        if (_timeLabels) {
            xAxis = xAxis.concat(getTimeString());
        }
        else {
            xAxis = xAxis.concat(item.Key);
        }
    });

    // y-axis labels - need to support datasets
    var yAxises = {};
    action.Data[0].Values.forEach((item) => {
        yAxises[item.Key] = {
            data: [],
            label: item.Key
        };
    });

    action.Data.forEach((item) => {
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
        switch (chartType.toLowerCase()) {
            case 'line':
                yAxises[key].backgroundColor = palette[index % palette.length].replace('1.0)', '0.2)');
                yAxises[key].borderColor = palette[index % palette.length];
                yAxises[key].borderWidth = 3;
                yAxises[key].fill = true;
                yAxises[key].tension = 0.4;
                axesOpts.x = getChartAxesColours(theme, canvas, 'x');
                axesOpts.y = getChartAxesColours(theme, canvas, 'y');
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
                axesOpts.x = getChartAxesColours(theme, canvas, 'x');
                axesOpts.y = getChartAxesColours(theme, canvas, 'y');
                break;
        }
    });

    // display the legend?
    var showLegend = (Object.keys(yAxises)[0].toLowerCase() != 'default');
    if ((canvas.closest('div.pode-tile').length > 0) || (canvas.attr('pode-legend') == 'False')) {
        showLegend = false;
    }

    // make the chart
    var chart = new Chart(ctx, {
        type: chartType.toLowerCase(),

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

    // save chart for later appending, or resetting
    _charts[action.ID] = {
        canvas: chart,
        append: _append
    };
}

function getChartAxesColours(theme, canvas, axis) {
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
    var min = parseInt(canvas.attr(`pode-min-${axis}`));
    if (min > MIN_INT32) {
        opts['min'] = min;
    }

    var max = parseInt(canvas.attr(`pode-max-${axis}`));
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

function getChartColourPalette(theme, canvas) {
    // do the canvas have a defined set of colours?
    var colours = canvas.attr('pode-colours');
    if (colours) {
        var converted = [];
        colours.split(',').forEach((c) => { converted.push(hexToRgb(c.trim())); });
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

function writeChart(action, sender) {
    var senderId = getId(sender);
    var chartId = `chart_${senderId}`;

    // create canvas
    var canvas = $(`canvas#${chartId}`);
    if (canvas.length == 0) {
        sender.after(`<div><canvas class="my-4 w-100" id="${chartId}" pode-chart-type="${action.ChartType}" style="height:400px;"></canvas></div>`);
    }

    // update
    action.ID = chartId;
    updateChart(action, sender);
}

function getTimeString() {
    return (new Date()).toLocaleTimeString().split(':').slice(0,2).join(':');
}

function buildButton(element) {
    return PodeElementFactory.invokeClass('button', 'new', element);
}

function buildIcon(element) {
    return PodeElementFactory.invokeClass('icon', 'new', element);
}

function buildBadge(element) {
    return PodeElementFactory.invokeClass('badge', 'new', element);
}

function buildSpinner(element) {
    return PodeElementFactory.invokeClass('spinner', 'new', element);
}

function buildLink(element) {
    return PodeElementFactory.invokeClass('link', 'new', element);
}

function actionNotification(action) {
    if (!window.Notification) {
        return;
    }

    if (Notification.permission === 'granted') {
        showNotification(action);
    }
    else if (Notification.permission !== 'denied') {
        Notification.requestPermission().then(function(p) {
            if (p === 'granted') {
                showNotification(action);
            }
        });
    }
}

function showNotification(action) {
    if (!action) {
        return;
    }

    var notif = new Notification(action.Title, {
        body: action.Body,
        icon: action.Icon
    });
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

// function actionBadge(action) {
//     return PodeElementFactory.invokeClass('Badge', 'update', action);
// }

function actionProgress(action) {
    if (!action) {
        return;
    }

    var progress = getElementByNameOrId(action, 'div');
    if (!progress) {
        return;
    }

    // change value
    if (action.Value >= 0) {
        progress.attr('aria-valuenow', action.Value);

        var max = progress.attr('aria-valuemax');
        var percentage = (action.Value / max) * 100.0;

        progress.css('width', `${percentage}%`);
    }

    // change colour
    if (action.Colour) {
        removeClass(progress, 'bg-\\w+');
        addClass(progress, `bg-${action.ColourType}`);
    }
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

function actionTab(action) {
    if (!action) {
        return;
    }

    var tab = getElementByNameOrId(action, 'a.nav-link');
    moveTab(getId(tab));
}

function moveTab(tabId) {
    $(`a.nav-link#${tabId}`).trigger('click');
}

// function actionAccordion(action) {
//     if (!action) {
//         return;
//     }

//     var item = getElementByNameOrId(action, 'div.accordion div.card');
//     moveAccordion(getId(item));
// }

// function moveAccordion(itemId) {
//     $(`div.accordion div.bellow#${itemId} div.bellow-header button`).trigger('click');
// }

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

function actionBreadcrumb(action) {
    if (!action) {
        return;
    }

    var breadcrumb = $('nav ol.breadcrumb');
    if (!breadcrumb) {
        return;
    }

    breadcrumb.empty();

    action.Items = convertToArray(action.Items);
    if (action.Items.length <= 0) {
        return;
    }

    action.Items.forEach((i) => {
        if (i.Active) {
            breadcrumb.append(`<li class='breadcrumb-item active' aria-current='page'>${i.Name}</li>`);
        }
        else {
            breadcrumb.append(`<li class='breadcrumb-item'><a href='${i.Url}'>${i.Name}</a></li>`);
        }
    });
}

function convertToArray(element) {
    if (element == null) {
        return [];
    }

    if (!Array.isArray(element)) {
        element = [element];
    }

    return element;
}

function invokeEvent(type, sender) {
    sender = $(sender);
    var url = `${getComponentUrl(sender)}/events/${type}`;

    var inputs = {};

    if (getTagName(sender) != null) {
        inputs.data = sender.serialize();

        if (!inputs.data) {
            inputs = serializeInputs(sender);
        }

        if (!inputs.opts) {
            inputs.opts = {};
        }
        inputs.opts.keepFocus = true;
    }

    sendAjaxReq(url, inputs.data, sender, true, null, inputs.opts);
}

function getComponentUrl(component) {
    if (typeof component === 'string') {
        component = $(`#${component}`);
    }

    if (getTagName(component) == null) {
        return (window.location.pathname == '/' ? '/home' : window.location.pathname);
    }
    else {
        return `/components/${component.attr('pode-object').toLowerCase()}/${component.attr('id')}`;
    }
}

function buildEvents(events) {
    if (!events) {
        return '';
    }

    events = convertToArray(events);
    var strEvents = '';

    events.forEach((evt) => {
        strEvents += `on${evt}="invokeEvent('${evt}', this);"`;
    });

    return strEvents;
}

function generateUuid() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
        (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    );
}