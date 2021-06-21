$.expr.pseudos.icontains = $.expr.createPseudo(function(arg) {
    return function(elem) {
        return $(elem).text().toLowerCase().indexOf(arg.toLowerCase()) >= 0;
    };
});


(function() {
    $('[data-toggle="tooltip"]').tooltip();
})();
(function() {
    hljs.highlightAll();
})();

$(() => {
    if (checkAutoTheme()) {
        return;
    }

    mapElementThemes();

    loadBreadcrumb();
    loadTables();
    loadCharts();
    loadAutoCompletes();
    loadTiles();

    setupSteppers();
    setupAccordion();

    bindSidebarFilter();
    bindMenuToggle();
    bindNavLinks();
    bindPageLinks();

    bindFormSubmits();
    bindButtons();
    bindCodeCopy();
    bindCodeEditors();
    bindFileStreams();

    bindTableFilters();
    bindTableExports();
    bindTableRefresh();
    bindTableButtons();

    bindChartRefresh();
    bindRangeValue();
    bindProgressValue();
    bindModalSubmits();

    bindTileRefresh();
    bindTileClick();

    bindPageGroupCollapse();
    bindCardCollapse();

    bindTabCycling();
    bindAccordionCycling();
    bindTimers();
});

var _fileStreams = {};

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
                error: function() {
                    hideSpinner($(e).closest('div.file-stream'));
                    clearInterval(_fileStreams[getId(e)]);
                    $(e).closest('div.file-stream').addClass('stream-error');
                    $(e).closest('div.file-stream').find('div.card-header div div.btn-group').hide();
                }
            });
        }, $(e).attr('pode-interval'));

        _fileStreams[getId(e)] = handle;
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

function setupAccordion() {
    $('div.accordion div.card div.collapse').off('hide.bs.collapse').on('hide.bs.collapse', function(e) {
        var icon = $(e.target).closest('div.card').find('span.arrow-toggle');
        toggleIcon(icon, 'chevron-down', 'chevron-up');
    });

    $('div.accordion div.card div.collapse').off('show.bs.collapse').on('show.bs.collapse', function(e) {
        var icon = $(e.target).closest('div.card').find('span.arrow-toggle');
        toggleIcon(icon, 'chevron-up', 'chevron-down');
    });
}

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

            breadcrumb.append(`<li class='breadcrumb-item'><a href='${window.location.pathname}?${data}'>${i}</a></li>`);

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
        breadcrumb.append(`<li class='breadcrumb-item active' aria-current='page'>${value}</li>`);
    }
}

function checkAutoTheme() {
    // is the them auto-switchable?
    var targetTheme = $('body').attr('pode-theme-target');

    // check if the system is dark/light
    if (targetTheme == 'auto') {
        var isSystemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        targetTheme = (isSystemDark ? 'dark' : 'light');
    }

    // get the body theme, do we need to switch?
    var bodyTheme = getPodeTheme();
    if (bodyTheme == targetTheme) {
        return false;
    }

    // set the cookie, expire after 1 month
    var d = new Date();
    d.setTime(d.getTime() + (30 * 24 * 60 * 60 * 1000));
    document.cookie = `pode.web.theme=${targetTheme}; expires=${d.toUTCString()}; path=/`

    // force a refresh
    refreshPage();
    return true;
}

function mapElementThemes() {
    var bodyTheme = getPodeTheme();

    var defTheme = 'primary';
    if (bodyTheme == 'terminal') {
        defTheme = 'success';
    }

    var types = ['badge', 'btn'];
    types.forEach((type) => {
        $(`.${type}-inbuilt-theme`).each((i, e) => {
            $(e).removeClass(`${type}-inbuilt-theme`);
            $(e).addClass(`${type}-${defTheme}`);
        });
    });
}

function getPodeTheme() {
    return $('body').attr('pode-theme');
}

function serializeInputs(element) {
    return element.find('input, textarea, select').serialize();
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
                var data = serializeInputs(step);
                var url = `/layouts/step/${step.attr('id')}`;

                // send ajax req, and call next on no validation errors
                sendAjaxReq(url, data, step, true, (res, sender) => {
                    if (!hasValidationErrors(sender)) {
                        _steppers[sender.attr('for')].next();
                    }
                });
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

            // call ajax, or move along?
            if (isDynamic(step)) {
                // serialize any step-form data
                var data = serializeInputs(step);
                var url = `/layouts/step/${step.attr('id')}`;

                // send ajax req, if not validation errors, send ajax for all steps
                sendAjaxReq(url, data, step, true, (res, sender) => {
                    if (!hasValidationErrors(sender)) {
                        var _steps = sender.attr('for');
                        var _data = sender.closest('form.pode-stepper-form').serialize();
                        var _url = `/layouts/steps/${_steps}`;

                        sendAjaxReq(_url, _data, sender, true);
                    }
                });
            }
            else {
                var steps = step.attr('for');
                var data = step.closest('form.pode-stepper-form').serialize();
                var url = `/layouts/steps/${steps}`;

                sendAjaxReq(url, data, step, true);
            }
        });
    });
}

function isDynamic(element) {
    if (!element) {
        return false;
    }

    return ($(element).attr('pode-dynamic') == 'True');
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

    element.addClass('is-invalid');

    // form-row? flag inside inputs
    if (element.hasClass('form-row')) {
        element.find('input').addClass('is-invalid');
    }

    // input? find parent input-group/form-row
    if (testTagName(element, 'input')) {
        element.closest('div.input-group').addClass('is-invalid');
        element.closest('div.form-row').addClass('is-invalid');
    }
}

function sendAjaxReq(url, data, sender, useActions, successCallback, opts) {
    // show the spinner
    showSpinner(sender);
    $('.alert.pode-error').remove();

    // remove validation errors
    removeValidationErrors(sender);

    // add current query string
    if (window.location.search) {
        url = `${url}${window.location.search}`;
    }

    // set default opts
    opts = (opts ?? {});
    opts.contentType = (opts.contentType == null ? 'application/x-www-form-urlencoded; charset=UTF-8' : opts.contentType);
    opts.processData = (opts.processData == null ? true : opts.processData);

    // make the call
    $.ajax({
        url: url,
        method: 'post',
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
            unfocus(sender);

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
            unfocus(sender);
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

    var spinner = sender.find('span.spinner-border');
    if (spinner) {
        spinner.show();
    }
}

function hideSpinner(sender) {
    if (!sender) {
        return;
    }

    var spinner = sender.find('span.spinner-border');
    if (spinner) {
        spinner.hide();
    }
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

        var url = `/elements/code-editor/${editorId}/upload`;
        var data = JSON.stringify({
            language: $(`#${editorId} .code-editor`).attr('pode-language'),
            value: _editors[editorId].getValue()
        });

        sendAjaxReq(url, data, null, true, null, {
            contentType: 'application/json; charset=UTF-8'
        });
    });
}

function bindCardCollapse() {
    $('button.pode-card-collapse').off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = getButton(e);
        toggleIcon(button, 'eye-outline', 'eye-off-outline', 'Hide', 'Show');

        button.closest('.card').find('.card-body').slideToggle();
        unfocus(button);
    });
}

function bindTabCycling() {
    $('ul.nav-tabs[pode-cycle="True"]').each((i, e) => {
        setInterval(() => {
            var tabId = $(e).find('li.nav-item a.nav-link.active').attr('pode-next');
            moveTab(tabId);
        }, $(e).attr('pode-interval'));
    });
}

function bindAccordionCycling() {
    $('div.accordion[pode-cycle="True"]').each((i, e) => {
        setInterval(() => {
            var itemId = $(e).find('div.card div.bellow-body.show').attr('pode-next');
            moveAccordion(itemId);
        }, $(e).attr('pode-interval'));
    });
}

function bindTimers() {
    $('span.pode-timer').each((i, e) => {
        var id = $(e).attr('id');

        invokeTimer(id);

        setInterval(() => {
            invokeTimer(id);
        }, $(e).attr('pode-interval'));
    });
}

function invokeTimer(timerId) {
    sendAjaxReq(`/elements/timer/${timerId}`, null, null, true);
}

function bindMenuToggle() {
    $('button#menu-toggle').off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        $('nav#sidebarMenu').toggleClass('hide');
        $('main[role="main"]').toggleClass('fullscreen');

        $('button#menu-toggle span').toggleClass('mdi-rotate-180');
    });
}

function bindTablePagination() {
    $('nav .pagination a.page-link').off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        var link = $(this);

        // if active/disabled, do nothing
        if (link.hasClass('active') || link.hasClass('disabled')) {
            return;
        }

        // get amount
        var pageNav = link.closest('nav');
        var amount = pageNav.attr('pode-amount') ?? 20;

        // next or previous? - get current +/-
        var page = 1;

        if (link.hasClass('page-arrows')) {
            var current = link.closest('ul').find('a.page-link.active').text();

            if (link.hasClass('page-previous')) {
                current--;
            }

            if (link.hasClass('page-next')) {
                current++;
            }

            page = current;
        }
        else {
            page = link.text();
        }

        loadTable(pageNav.attr('for'), page, amount);
    });
}

function bindTableSort(tableId) {
    $(`${tableId}[pode-sort='True'] thead th`).off('click').on('click', function() {
        var table = $(this).parents('table').eq(0);
        var rows = table.find('tr:gt(0)').toArray().sort(comparer($(this).index()));

        this.asc = !this.asc;
        if (!this.asc) {
            rows = rows.reverse();
        }

        rows.forEach((row) => {
            table.append(row);
        });
    });

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

    console.log(element);

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

function loadTables() {
    $(`table[pode-dynamic='True']`).each((i, e) => {
        loadTable($(e).attr('id'));
    });
}

function loadTable(tableId, pageNumber, pageAmount) {
    if (!tableId) {
        return;
    }

    // ensure the table is dynamic, or has the 'for' attr set
    var table = $(`table#${tableId}`);
    if (!isDynamic(table) && !table.attr('for')) {
        return;
    }

    // define any table paging
    var data = '';
    if (pageNumber || pageAmount) {
        pageNumber = (pageNumber ?? 1);
        pageAmount = (pageAmount ?? 20);
        data = `PageNumber=${pageNumber}&PageAmount=${pageAmount}`;
    }

    // things get funky here if we have a table with a 'for' attr
    // if so, we need to serialize the form, and then send the request to the form instead
    var url = `/elements/table/${tableId}`;

    if (table.attr('for')) {
        var form = $(`#${table.attr('for')}`);
        if (data) {
            data += '&';
        }

        data += form.serialize();
        url = form.attr('method');
    }

    // invoke and load table content
    sendAjaxReq(url, data, table, true);
}

function loadAutoCompletes() {
    $(`input[pode-autocomplete='True']`).each((i, e) => {
        sendAjaxReq(`/elements/autocomplete/${$(e).attr('id')}`, null, null, false, (res) => {
            $(e).autocomplete({ source: res.Values });
        });
    });
}

function loadTiles() {
    $(`div.pode-tile[pode-dynamic="True"]`).each((i, e) => {
        loadTile($(e).attr('id'), true);
    });
}

function loadTile(tileId, firstLoad = false) {
    if (!tileId) {
        return;
    }

    var tile = $(`div.pode-tile[pode-dynamic="True"]#${tileId}`);
    if (tile.length > 0) {
        sendAjaxReq(`/elements/tile/${tileId}`, null, tile, true);
    }
    else if (!firstLoad) {
        $(`div.pode-tile[pode-dynamic="False"]#${tileId} .pode-tile-body .pode-refresh-btn`).each((i, e) => {
            $(e).trigger('click');
        });
    }
}

function bindTileRefresh() {
    $("div.pode-tile .pode-tile-body .pode-refresh-btn").each((i, e) => {
        $(e).hide();
    });

    $("div.pode-tile span.pode-tile-refresh").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var icon = $(e.target);
        icon.tooltip('hide');
        loadTile(icon.attr('for'));
    });

    $("div.pode-tile[pode-auto-refresh='True']").each((i, e) => {
        setTimeout(() => {
            loadTile($(e).attr('id'));
            setInterval(() => {
                loadTile($(e).attr('id'));
            }, 60000);
        }, (60 - (new Date()).getSeconds()) * 1000);
    });
}

function bindTileClick() {
    $(`div.pode-tile[pode-click="True"]`).off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var tileId = $(e.target).closest('div.pode-tile').attr('id');
        var tile = $(`div.pode-tile#${tileId}`);

        var url = `/elements/tile/${tileId}/click`;
        sendAjaxReq(url, null, tile, true);
    });
}

function loadCharts() {
    $(`canvas[pode-dynamic='True']`).each((i, e) => {
        loadChart($(e).attr('id'));
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
    var url = `/elements/chart/${chartId}`;

    if (chart.attr('for')) {
        var form = $(`#${chart.attr('for')}`);
        if (data) {
            data += '&';
        }

        data += form.serialize();
        url = form.attr('method');
    }

    sendAjaxReq(url, data, chart, true);
}

function invokeActions(actions, sender) {
    if (!actions) {
        return;
    }

    actions = convertToArray(actions);

    actions.forEach((action) => {
        var _type = action.ElementType;
        if (_type) {
            _type = _type.toLowerCase();
        }

        switch (_type) {
            case 'table':
                actionTable(action, sender);
                break;

            case 'tablerow':
                actionTableRow(action, sender);
                break;

            case 'chart':
                actionChart(action, sender);
                break;

            case 'textbox':
                actionTextbox(action, sender);
                break;

            case 'toast':
                actionToast(action);
                break;

            case 'validation':
                actionValidation(action, sender);
                break;

            case 'form':
                actionForm(action);
                break;

            case 'text':
                actionText(action);
                break;

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

            case 'badge':
                actionBadge(action);
                break;

            case 'progress':
                actionProgress(action);
                break;

            case 'tab':
                actionTab(action);
                break;

            case 'accordion':
                actionAccordion(action);
                break;

            case 'page':
                actionPage(action);
                break;

            case 'error':
                actionError(action, sender);
                break;

            case 'breadcrumb':
                actionBreadcrumb(action);
                break;

            case 'tile':
                actionTile(action, sender);
                break;

            default:
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
        var _type = ele.ElementType;
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
    $("form.pode-form").off('submit').on('submit', function(e) {
        e.preventDefault();
        e.stopPropagation();

        // get the form
        var form = $(e.target);

        // submit the form
        var data = null;
        var opts = null;

        if (form.find('input[type=file]').length > 0) {
            data = new FormData(form[0]);
            opts = {
                mimeType: 'multipart/form-data',
                contentType: false,
                processData: false
            }
        }
        else {
            data = form.serialize();
        }

        // submit the form
        sendAjaxReq(form.attr('method'), data, form, true, null, opts);
    });
}

function bindModalSubmits() {
    $("div.modal-content form.pode-form").off('keypress').on('keypress', function(e) {
        if (!isEnterKey(e)) {
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
        var formData = '';
        var form = null;

        if (button.attr('pode-modal-form') == 'True') {
            form = modal.find('div.modal-body form');
            formData = form.serialize();
            removeValidationErrors(form);
        }

        // get a data value
        var dataValue = getDataValue(button);

        // build data
        if (dataValue) {
            if (formData) {
                formData += '&';
            }

            formData += `Value=${dataValue}`;
        }

        // invoke url
        sendAjaxReq(url, formData, (form ?? button), true);
    });
}

function getDataValue(element) {
    var dataValue = element.attr('pode-data-value');
    if (!dataValue) {
        dataValue = element.closest('[pode-data-value!=""][pode-data-value]').attr('pode-data-value');
    }

    return dataValue;
}

function bindCodeCopy() {
    $('pre button.pode-code-copy').off('click').on('click', function(e) {
        var value = $(e.target).closest('pre').find('code').text().trim();
        navigator.clipboard.writeText(value);
    });
}

function getButton(event) {
    var button = $(event.target);
    if (!testTagName(button, 'button')) {
        button = button.closest('button');
    }

    return button;
}

function bindButtons() {
    $("button.pode-button").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        // get the button
        var button = getButton(e);
        button.tooltip('hide');

        // default data value
        var dataValue = getDataValue(button);
        var data = `Value=${dataValue}`;

        if (!dataValue) {
            var form = button.closest('form');

            if (form) {
                data = form.serialize();
            }
        }

        var url = `/elements/button/${button.attr('id')}`;
        sendAjaxReq(url, data, button, true);
    });
}

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

function bindTableFilters() {
    $("input.pode-table-filter").off('keyup').on('keyup', function(e) {
        e.preventDefault();
        filterTable($(e.target));
    });
}

function filterTable(filter) {
    if (!filter) {
        return;
    }

    var tableId = filter.attr('for');
    var value = filter.val();

    $(`table#${tableId} tbody tr:not(:icontains('${value}'))`).hide();
    $(`table#${tableId} tbody tr:icontains('${value}')`).show();
}

function bindSidebarFilter() {
    $("input.pode-nav-filter").off('keyup').on('keyup', function(e) {
        e.preventDefault();

        var input = $(e.target);
        var listId = input.attr('for');
        var value = input.val();

        if (value) {
            $('div.collapse').collapse('show');
            $(`ul#${listId} li.nav-group-title`).hide();
        }
        else {
            $('div.collapse').collapse('hide');
            $(`ul#${listId} li.nav-group-title`).show();
        }

        $(`ul#${listId} li.nav-page-item:not(:icontains('${value}'))`).hide();
        $(`ul#${listId} li.nav-page-item:icontains('${value}')`).show();
    });
}

function bindTableExports() {
    $("button.pode-table-export").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = getButton(e);
        button.tooltip('hide');

        var tableId = button.attr('for');
        var csv = exportTableAsCSV(tableId);
        downloadCSV(csv, getTableFileName(tableId));
    });
}

function bindTableRefresh() {
    $("button.pode-table-refresh").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = getButton(e);
        button.tooltip('hide');
        loadTable(button.attr('for'));
    });

    $("table[pode-auto-refresh='True']").each((index, item) => {
        setTimeout(() => {
            loadTable($(item).attr('id'));
            setInterval(() => {
                loadTable($(item).attr('id'));
            }, 60000);
        }, (60 - (new Date()).getSeconds()) * 1000);
    });
}

function bindTableButtons() {
    $("button.pode-table-button").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = getButton(e);
        button.tooltip('hide');

        var tableId = button.attr('for');
        var table = $(`table#${tableId}`);
        var csv = exportTableAsCSV(tableId);

        var url = `/elements/table/${tableId}/button/${button.attr('name')}`;
        sendAjaxReq(url, csv, table, true, null, { contentType: 'text/csv' });
    });
}

function bindChartRefresh() {
    $("button.pode-chart-refresh").off('click').on('click', function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = getButton(e);
        button.tooltip('hide');
        loadChart(button.attr('for'));
    });

    $("canvas[pode-auto-refresh='True']").each((index, item) => {
        setTimeout(() => {
            loadChart($(item).attr('id'));
            setInterval(() => {
                loadChart($(item).attr('id'));
            }, 60000);
        }, (60 - (new Date()).getSeconds()) * 1000);
    });
}

function actionTableRow(action, sender) {
    switch (action.Operation.toLowerCase()) {
        case 'update':
            updateTableRow(action);
            break;
    }
}

function updateTableRow(action) {
    if ((!action.ID && !action.Name) || !action.Data) {
        return;
    }

    // ensure the table exists
    var table = getElementByNameOrId(action, 'table');
    if (table.length == 0) {
        return;
    }

    var tableId = `table#${getId(table)}`;

    // get the table row
    var row = null;
    switch (action.Row.Type) {
        case 'id_and_datavalue':
        case 'name_and_datavalue':
            row = table.find(`tbody tr[pode-data-value="${action.Row.DataValue}"]`);
            break;

        case 'id_and_index':
        case 'name_and_index':
            row = table.find('tbody tr').eq(action.Row.Index);
            break;
    }

    // do nothing if no row
    if (!row || row.length == 0) {
        return;
    }

    // update the rows cells
    var keys = Object.keys(action.Data);

    keys.forEach((key) => {
        var _html = '';
        var _value = action.Data[key];

        if (Array.isArray(_value) || _value.ElementType) {
            _html += buildElements(_value);
        }
        else {
            _html += _value;
        }

        row.find(`td[pode-column="${key}"]`).html(_html);
    });

    // binds sort/buttons/etc
    $('[data-toggle="tooltip"]').tooltip();
    bindButtons();

    // setup clickable rows
    bindTableClickableRows(tableId);
}

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
            var url = `/elements/table/${table.attr('id')}/click`;
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
    }
}

function syncTable(action) {
    if (!action.ID && !action.Name) {
        return;
    }

    var table = getElementByNameOrId(action, 'table');
    var id = getId(table);

    loadTable(id);
}

function updateTable(action, sender) {
    if (action.Data == null) {
        return;
    }

    // convert data to array
    action.Data = convertToArray(action.Data);

    // table meta
    var table = getElementByNameOrId(action, 'table');
    var tableId = `table#${getId(table)}`;

    var tableHead = $(`${tableId} thead`);
    var tableBody = $(`${tableId} tbody`);

    // clear the table if no data
    if (action.Data.length <= 0) {
        tableBody.empty();
        return;
    }

    // get data keys for table columns
    var keys = Object.keys(action.Data[0]);

    // get custom column meta - for widths etc
    var columns = {};
    if (action.Columns) {
        columns = action.Columns;
    }

    // get senderId if present, and set on table as 'for'
    var senderId = getId(sender);
    if (senderId && getTagName(sender) == 'form') {
        table.attr('for', senderId);
    }

    // is there a data column?
    var dataColumn = table.attr('pode-data-column');

    // table headers
    tableHead.empty();

    var _value = '<tr>';
    var _col = null;
    keys.forEach((key) => {
        if (key in columns) {
            _col = columns[key];
            _value += `<th style='`;

            if (_col.Width > 0) {
                _value += `width:${_col.Width}%;`;
            }

            if (_col.Alignment) {
                _value += `text-align:${_col.Alignment};`;
            }

            _value += `'>`;

            if (_col.Icon) {
                _value += `<span class='mdi mdi-${_col.Icon.toLowerCase()} mRight02'></span>`;
            }

            _value += `${_col.Name ? _col.Name : key}</th>`;
        }
        else {
            _value += `<th>${key}</th>`;
        }
    });
    _value += '</tr>';

    tableHead.append(_value);

    // table body
    tableBody.empty();

    action.Data.forEach((item) => {
        _value = `<tr pode-data-value="${item[dataColumn]}">`;

        keys.forEach((key) => {
            var col = columns[key];
            if (key in columns) {
                _col = columns[key];
                _value += `<td pode-column='${key}' style='`;

                if (col.Alignment) {
                    _value += `text-align:${col.Alignment};`;
                }

                _value += `'>`;
            }
            else {
                _value += `<td pode-column='${key}'>`;
            }

            if (Array.isArray(item[key]) || (item[key] && item[key].ElementType)) {
                _value += buildElements(item[key]);
            }
            else if (item[key]) {
                _value += item[key];
            }

            _value += `</td>`;
        });
        _value += '</tr>';
        tableBody.append(_value);
    });

    // is the table paginated?
    var isPaginated = (table.attr('pode-paginate') == 'True');
    if (isPaginated) {
        var paging = table.closest('div[role="table"]').find('nav ul');
        paging.empty();

        // previous
        paging.append(`
            <li class="page-item">
                <a class="page-link page-arrows page-previous" href="#" aria-label="Previous">
                    <span aria-hidden="true">&laquo;</span>
                </a>
            </li>`);

        var pageActive = '';

        // first page
        pageActive = (1 == action.Paging.Number ? 'active' : '');
        paging.append(`
            <li class="page-item">
                <a class="page-link ${pageActive}" href="#">1</a>
            </li>`);

        // ...
        if (action.Paging.Number > 4) {
            paging.append(`
                <li class="page-item">
                    <a class="page-link disabled" href="#">...</a>
                </li>`);
        }

        // pages
        for (var i = (action.Paging.Number - 2); i <= (action.Paging.Number + 2); i++) {
            if (i <= 1 || i >= action.Paging.Max) {
                continue;
            }

            pageActive = (i == action.Paging.Number ? 'active' : '');
            paging.append(`
                <li class="page-item">
                    <a class="page-link ${pageActive}" href="#">${i}</a>
                </li>`);
        }

        // ...
        if (action.Paging.Number < action.Paging.Max - 3) {
            paging.append(`
                <li class="page-item">
                    <a class="page-link disabled" href="#">...</a>
                </li>`);
        }

        // last page
        if (action.Paging.Max > 1) {
            pageActive = (action.Paging.Max == action.Paging.Number ? 'active' : '');
            paging.append(`
                <li class="page-item">
                    <a class="page-link ${pageActive}" href="#">${action.Paging.Max}</a>
                </li>`);
        }

        // next
        paging.append(`
            <li class="page-item">
                <a class="page-link page-arrows page-next" href="#" aria-label="Next" pode-max="${action.Paging.Max}">
                    <span aria-hidden="true">&raquo;</span>
                </a>
            </li>`);
    }

    // binds sort/buttons/etc
    $('[data-toggle="tooltip"]').tooltip();
    bindTableSort(tableId);
    bindButtons();
    bindTablePagination();

    // setup table filter
    filterTable(table.closest('div.card-body').find('input.pode-table-filter'));

    // setup clickable rows
    bindTableClickableRows(tableId);
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

function actionForm(action) {
    var form = getElementByNameOrId(action, 'form');
    if (!form) {
        return;
    }

    resetForm(form);
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

function actionText(action) {
    if (!action) {
        return;
    }

    var text = $(`#${action.ID}`);
    if (!text) {
        return;
    }

    if (!text.hasClass('pode-text')) {
        text = text.find('.pode-text') ?? text;
    }

    text.text(decodeHTML(action.Value));
}

function actionTile(action, sender) {
    if (!action) {
        return;
    }

    switch (action.Operation.toLowerCase()) {
        case 'update':
            updateTile(action, sender);
            break;

        case 'sync':
            syncTile(action);
            break;
    }
}

function updateTile(action, sender) {
    var tile = getElementByNameOrId(action, 'div');
    if (!tile) {
        return;
    }

    // change the tile's value
    if (action.Value) {
        tile.find('.pode-text').text(decodeHTML(action.Value));
    }

    // change colour
    if (action.Colour) {
        removeClass(tile, 'alert-\\w+');
        tile.addClass(`alert-${action.ColourType}`);
    }
}

function syncTile(action) {
    if (!action.ID && !action.Name) {
        return;
    }

    var tile = getElementByNameOrId(action, 'div');
    var id = getId(tile);

    loadTile(id);
}

function actionSelect(action) {
    if (!action) {
        return;
    }

    var select = getElementByNameOrId(action, 'select');
    if (!select) {
        return;
    }

    select.val(decodeHTML(action.Value));
}

function decodeHTML(value) {
    var textArea = document.createElement('textarea');
    textArea.innerHTML = value;
    value = textArea.value;
    textArea.remove();
    return value;
}

function actionCheckbox(action) {
    if (action.ID) {
        action.ID = `${action.ID}_option${action.OptionId}`;
    }

    var checkbox = getElementByNameOrId(action, 'input', null, `[pode-option-id="${action.OptionId}"]`);
    if (!checkbox) {
        return;
    }

    checkbox.attr('checked', action.Checked);
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
    $(validationId).text(action.Message);

    setValidationError(input);
}

function actionTextbox(action, sender) {
    switch (action.Operation.toLowerCase()) {
        case 'update':
            updateTextbox(action);
            break;

        case 'output':
            writeTextbox(action, sender);
            break;
    }
}

function updateTextbox(action) {
    if (!action.Value) {
        return;
    }

    var txt = action.Multiline
        ? getElementByNameOrId(action, 'textarea')
        : getElementByNameOrId(action, 'input');

    if (action.AsJson) {
        action.Value = JSON.stringify(action.Value, null, 4);
    }

    txt.val(action.Value);
}

function writeTextbox(action, sender) {
    var senderId = getId(sender);
    var txtId = `txt_${senderId}`;

    // create textbox
    var element = null;
    var txt = null;

    // default attrs
    var readOnly = '';
    if (action.ReadOnly) {
        readOnly ='readonly';
    }

    // build the element
    if (action.Multiline) {
        txt = $(`textarea#${txtId}`);
        if (txt.length == 0) {
            element = `<textarea class='form-control' id='${txtId}' rows='${action.Height}' ${readOnly}></textarea>`;
        }
    }
    else {
        txt = $(`input#${txtId}`);
        if (txt.length == 0) {
            element = `<input type='text' class='form-control' id='${txtId}' ${readOnly}>`;
        }
    }

    if (element) {
        if (action.Preformat) {
            element = `<pre>${element}</pre>`;
        }

        sender.after(element);
    }

    // update
    action.ID = txtId;
    updateTextbox(action);
}

function exportTableAsCSV(tableId) {
    var csv = [];
    var rows = $(`table#${tableId} tr:visible`);

    if (!rows || rows.length == 0) {
        return;
    }

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

function getTableFileName(tableId) {
    var tableName = $(`table#${tableId}`).attr('name').replace(' ', '_');
    return `${tableName}.csv`
}

function downloadCSV(csv, filename) {
    // the csv file
    var csvFile = new Blob([csv], { type: "text/csv" });

    // build a hidden download link
    var downloadLink = document.createElement('a');
    downloadLink.download = filename;
    downloadLink.href = window.URL.createObjectURL(csvFile);
    downloadLink.style.display = 'none';

    // add the link, and click it
    document.body.appendChild(downloadLink);
    downloadLink.click();

    // remove the link
    $(downloadLink).remove();
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
    }
}

function syncChart(action) {
    if (!action.ID && !action.Name) {
        return;
    }

    var chart = getElementByNameOrId(action, 'canvas');
    var id = getId(chart);

    loadChart(id);
}

var _charts = {};

function updateChart(action, sender) {
    if (!action.Data) {
        return;
    }

    action.Data = convertToArray(action.Data);
    if (action.Data.length <= 0) {
        return;
    }

    var canvas = getElementByNameOrId(action, 'canvas');
    action.ID = getId(canvas);

    var _append = (canvas.attr('pode-append') == 'True');

    // append new data, rather than rebuild the chart
    if (_append && _charts[action.ID]) {
        appendToChart(canvas, action);
    }

    // build the chart
    else {
        createTheChart(canvas, action, sender);
    }
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
    var palette = getChartColourPalette(theme);

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
                yAxises[key].backgroundColor = palette[index % palette.length].replace(')', ', 0.2)');
                yAxises[key].borderColor = palette[index % palette.length];
                yAxises[key].borderWidth = 3;
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
                yAxises[key].backgroundColor = palette[index % palette.length].replace(')', ', 0.6)');
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
    var max = parseInt(canvas.attr(`pode-max-${axis}`));
    if (min != max) {
        opts['min'] = min;
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

function getChartColourPalette(theme) {
    var first = [
        'rgb(54, 162, 235)',    // blue
        'rgb(255, 176, 0)'      // orange
    ];

    if (theme == 'terminal') {
        first = ['rgb(255, 176, 0)', 'rgb(54, 162, 235)'];
    }


    return first.concat([
        'rgb(255, 99, 132)',    // red
        'rgb(255, 205, 86)',    // yellow
        'rgb(0, 163, 51)',      // green
        'rgb(153, 102, 255)',   // purple
        'rgb(201, 203, 207)'    // grey
    ]);
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
    var icon = '';
    if (element.Icon) {
        icon = `<span class='mdi mdi-${element.Icon.toLowerCase()} mdi-size-20 mRight02'></span>`
    }

    if (element.IconOnly) {
        return `<button type='button' class='btn btn-icon-only pode-button' id='${element.ID}' pode-data-value='${element.DataValue}' title='${element.Name}' data-toggle='tooltip'>${icon}</button>`;
    }

    return `<button type='button' class='btn btn-${element.ColourType} pode-button' id='${element.ID}' pode-data-value='${element.DataValue}'>
        <span class='spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
        ${icon}${element.Name}
    </button>`;
}

function buildIcon(element) {
    var colour = '';
    if (element.Colour) {
        colour = `style="color:${element.Colour};"`
    }

    var title = '';
    if (element.Title) {
        title = `title='${element.Title}' data-toggle='tooltip'`;
    }

    var spin = '';
    if (element.Spin) {
        spin = 'mdi-spin'
    }

    var flip = '';
    if (element.Flip) {
        flip = `mdi-flip-${element.Flip[0]}`.toLowerCase();
    }

    var rotate = '';
    if (element.Rotate > 0) {
        rotate = `mdi-rotate-${element.Rotate}`;
    }

    return `<span class='mdi mdi-${element.Name.toLowerCase()} ${spin} ${flip} ${rotate} mdi-size-20' ${colour} ${title}></span>`;
}

function buildBadge(element) {
    return `<span id='${element.ID}' class='badge badge-${element.ColourType}'>${element.Value}</span>`;
}

function buildSpinner(element) {
    var colour = '';
    if (element.Colour) {
        colour = `style="color:${element.Colour};"`
    }

    var title = '';
    if (element.Title) {
        title = `title='${element.Title}' data-toggle='tooltip'`;
    }

    return `<span class="spinner-border spinner-border-sm" role="status" ${colour} ${title}></span>`;
}

function buildLink(element) {
    var target = '_self';
    if (element.NewTab) {
        target = '_blank';
    }

    return `<a href='${element.Source}' id='${element.ID}' target='${target}'>${element.Value}</a>`;
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

function actionBadge(action) {
    if (!action) {
        return;
    }

    var badge = $(`span#${action.ID}`);
    if (!badge) {
        return;
    }

    // change text
    if (action.Value) {
        badge.text(decodeHTML(action.Value));
    }

    // change colour
    if (action.Colour) {
        removeClass(badge, 'badge-\\w+');
        badge.addClass(`badge-${action.ColourType}`);
    }
}

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
        progress.addClass(`bg-${action.ColourType}`);
    }
}

function getClass(element, filter) {
    if (!element || !filter) {
        return null;
    }

    var result = element.attr('class').match(new RegExp(filter));
    return (result ? result[0] : null);
}

function removeClass(element, filter) {
    if (!element) {
        return;
    }

    if (!filter) {
        element.removeClass();
    }
    else {
        element.removeClass(getClass(element, filter));
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

function actionAccordion(action) {
    if (!action) {
        return;
    }

    var item = getElementByNameOrId(action, 'div.accordion div.card');
    moveAccordion(getId(item));
}

function moveAccordion(itemId) {
    $(`div.accordion div.card#${itemId} div.card-header button`).trigger('click');
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
    if (!Array.isArray(element)) {
        element = [element];
    }

    return element;
}