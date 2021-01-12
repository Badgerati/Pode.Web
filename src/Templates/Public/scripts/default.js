$.expr[":"].icontains = $.expr.createPseudo(function(arg) {
    return function(elem) {
        return $(elem).text().toLowerCase().indexOf(arg.toLowerCase()) >= 0;
    };
});

Chart.Legend.prototype.afterFit = function() {
    this.height = this.height + 10;
};


(function() {
    feather.replace();
})();
(function() {
    $('[data-toggle="tooltip"]').tooltip();
})();
(function() {
    hljs.initHighlightingOnLoad();
})();

$(document).ready(() => {
    mapElementThemes();

    loadTables();
    loadCharts();
    loadAutoCompletes();

    setupSteppers();

    bindSidebarFilter();
    bindMenuToggle();

    bindFormSubmits();
    bindButtons();
    bindCodeCopy();
    bindCodeEditors();

    bindTableFilters();
    bindTableExports();
    bindTableRefresh();
    bindTableButtons();

    bindChartRefresh();
    bindRangeValue();
    bindProgressValue();
    bindModalSubmits();

    bindPageGroupCollapse();
    bindCardCollapse();

    bindTabCycling();
    bindTimers();
});

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

var _steppers = {};

function setupSteppers() {
    $('div.bs-stepper[role="stepper"]').each((i, e) => {
        var stepper = $(e);
        _steppers[stepper.attr('id')] = new Stepper(e, { linear: true });

        // override form enter-key
        stepper.find('form.pode-stepper-form').unbind('keypress').keypress(function(e) {
            if (e.which != 13 && e.keyCode != 13) {
                return;
            }

            var btn = stepper.find('.bs-stepper-content .bs-stepper-pane.active button.step-next');
            if (!btn) {
                btn = stepper.find('.bs-stepper-content .bs-stepper-pane.active button.step-submit');
            }

            if (btn) {
                btn.click();
            }
        });

        // previous buttons
        stepper.find('.bs-stepper-content button.step-previous').unbind('click').click(function(e) {
            e.preventDefault();
            e.stopPropagation();

            // get the button and step
            var btn = getButton(e);
            var step = btn.closest(`div#${btn.attr('for')}`);

            // not need for validation, just go back
            _steppers[step.attr('for')].previous();
        });

        // next buttons
        stepper.find('.bs-stepper-content button.step-next').unbind('click').click(function(e) {
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
            if (step.attr('pode-dynamic') == 'True') {
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
        stepper.find('.bs-stepper-content button.step-submit').unbind('click').click(function(e) {
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
            if (step.attr('pode-dynamic') == 'True') {
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
}

function sendAjaxReq(url, data, sender, useActions, successCallback, opts) {
    // show the spinner
    showSpinner(sender);

    // remove validation errors
    removeValidationErrors(sender);

    // set default content type
    opts = (opts ?? {});
    opts.contentType = (opts.contentType ?? 'application/x-www-form-urlencoded; charset=UTF-8');

    // make the call
    $.ajax({
        url: url,
        method: 'post',
        data: data,
        dataType: 'binary',
        contentType: opts.contentType,
        xhrFields: {
            responseType: 'blob'
        },
        success: function(res, status, xhr) {
            // attempt to hide any spinners
            hideSpinner(sender);

            // attempt to get a filename, for downloading
            var filename = getAjaxFileName(xhr);

            // do we have a file to download?
            if (filename) {
                downloadAjaxFile(filename, res, xhr);
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
            console.log(err);
            console.log(stack);
        }
    });
}

function downloadAjaxFile(filename, blob, xhr) {
    // from: https://gist.github.com/jasonweng/393aef0c05c425d8dcfdb2fc1a8188e5
    // IE workaround for "HTML7007
    if (typeof window.navigator.msSaveBlob !== 'undefined') {
        window.navigator.msSaveBlob(blob, filename);
    }
    else {
        var URL = (window.URL || window.webkitURL);
        var downloadUrl = URL.createObjectURL(blob);

        if (filename) {
            // use HTML5 a[download] attribute to specify filename
            var a = document.createElement('a');

            // safari doesn't support this yet
            if (typeof a.download === 'undefined') {
                window.location = downloadUrl;
            }
            else {
                a.href = downloadUrl;
                a.download = filename;
                a.style.display = 'none';

                document.body.appendChild(a);
                a.click();

                $(a).remove();
            }
        }
        else {
            window.location = downloadUrl;
        }

        // cleanup the blob url
        setTimeout(function() {
            URL.revokeObjectURL(downloadUrl);
        }, 100);
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

function bindCodeEditors() {
    if ($('.code-editor').length == 0) {
        return;
    }

    var src = $('script[role="monaco"]').attr('src');
    require.config({ paths: { 'vs': src.substring(0, src.lastIndexOf('/')) }});

    require(["vs/editor/editor.main"], function() {
        $('.code-editor').each((i, e) => {
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
                value: '',
                language: $(e).attr('pode-language'),
                theme: theme
            });
        });
    });
}

function bindCardCollapse() {
    $('button.pode-card-collapse').unbind('click').click(function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = getButton(e);
        button.find('.feather-eye').toggle();
        button.find('.feather-eye-off').toggle();

        button.closest('.card').find('.card-body').slideToggle();
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
    $('button#menu-toggle').unbind('click').click(function(e) {
        e.preventDefault();
        e.stopPropagation();

        $('nav#sidebarMenu').toggleClass('hide');
        $('main[role="main"]').toggleClass('fullscreen');
    });
}

function bindTablePagination() {
    $('nav .pagination a.page-link').unbind('click').click(function(e) {
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
    $(`${tableId}[pode-sort='True'] thead th`).click(function() {
        var table = $(this).parents('table').eq(0);
        var rows = table.find('tr:gt(0)').toArray().sort(comparer($(this).index()));

        this.asc = !this.asc;
        if (!this.asc) {
            rows = rows.reverse();
        }

        for (var i = 0; i < rows.length; i++) {
            table.append(rows[i]);
        }
    });

    function comparer(index) {
        return function(a, b) {
            var valA = getCellValue(a, index), valB = getCellValue(b, index);
            return $.isNumeric(valA) && $.isNumeric(valB) ? valA - valB : valA.toString().localeCompare(valB);
        }
    }

    function getCellValue(row, index) {
        return $(row).children('td').eq(index).text();
    }
}

function bindPageGroupCollapse() {
    $('ul#sidebar-list div.collapse').on('hide.bs.collapse', function(e) {
        toggleCollapseArrow(e.target, 'arrow-right', 'arrow-down-right');
    });

    $('ul#sidebar-list div.collapse').on('show.bs.collapse', function(e) {
        toggleCollapseArrow(e.target, 'arrow-down-right', 'arrow-right');
    });
}

function toggleCollapseArrow(element, showIcon, hideIcon) {
    var id = $(element).attr('id');
    $(`a[aria-controls="${id}"]`).find(`svg.feather-${showIcon}`).show();
    $(`a[aria-controls="${id}"]`).find(`svg.feather-${hideIcon}`).hide();
}

function bindRangeValue() {
    $('input[type="range"].pode-range-value').each((index, item) => {
        var target = $(item);
        var value = $(`input#${target.attr('id')}_value`);

        target.change((e) => {
            value.val(target.val());
        });

        value.change((e) => {
            target.val(value.val());
        });
    });
}

function bindProgressValue() {
    $('div.progress div.pode-progress-value').each((index, item) => {
        var target = $(item);

        target.text(`${target.attr('aria-valuenow')} / ${target.attr('aria-valuemax')}`);
        target.change((e) => {
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
    if (table.attr('pode-dynamic') != 'True' && !table.attr('for')) {
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

    // add current query string
    if (window.location.search) {
        url = `${url}${window.location.search}`;
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

    // add current query string
    if (window.location.search) {
        url = `${url}${window.location.search}`;
    }

    sendAjaxReq(url, data, chart, true);
}

function invokeActions(actions, sender) {
    if (!actions) {
        return;
    }

    if (!$.isArray(actions)) {
        actions = [actions];
    }

    actions.forEach((action) => {
        var _type = action.ElementType;
        if (_type) {
            _type = _type.toLowerCase();
        }

        switch (_type) {
            case 'table':
                actionTable(action, sender);
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

            case 'tab':
                actionTab(action);
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

    if (!$.isArray(elements)) {
        elements = [elements];
    }

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
    $("form.pode-form").unbind('submit').submit(function(e) {
        e.preventDefault();
        e.stopPropagation();

        var form = $(e.target);
        sendAjaxReq(form.attr('method'), form.serialize(), form, true);
    });
}

function bindModalSubmits() {
    $("div.modal-footer button.pode-modal-submit").unbind('click').click(function(e) {
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

        // show spinner
        var spinner = button.find('span.spinner-border');
        if (spinner) {
            spinner.show();
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
    $('pre button.pode-code-copy').unbind('click').click(function(e) {
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
    $("button.pode-button").unbind('click').click(function(e) {
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

        var spinner = button.find('span.spinner-border');
        if (spinner) {
            spinner.show();
        }

        var url = `/elements/button/${button.attr('id')}`;
        sendAjaxReq(url, data, button, true);
    });
}

function bindTableFilters() {
    $("input.pode-table-filter").unbind('keyup').keyup(function(e) {
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
    $("input.pode-nav-filter").unbind('keyup').keyup(function(e) {
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
    $("button.pode-table-export").unbind('click').click(function(e) {
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
    $("button.pode-table-refresh").unbind('click').click(function(e) {
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
    $("button.pode-table-button").unbind('click').click(function(e) {
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
    $("button.pode-chart-refresh").unbind('click').click(function(e) {
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

function actionTable(action, sender) {
    switch (action.Operation.toLowerCase()) {
        case 'output':
            if (action.ID) {
                updateTable(action, sender);
            }
            else {
                writeTable(action, sender);
            }
            break;

        case 'sync':
            syncTable(action);
            break;
    }
}

function syncTable(action) {
    if (!action.ID) {
        return;
    }

    loadTable(action.ID);
}

function updateTable(action, sender) {
    if (!action.Data) {
        return;
    }

    // convert data to array
    if (!$.isArray(action.Data)) {
        action.Data = [action.Data];
    }

    // do nothing if no data
    if (action.Data.length <= 0) {
        return;
    }

    // get data keys for table columns
    var keys = Object.keys(action.Data[0]);

    // get custom column meta - for widths etc
    var columns = {};
    if (action.Columns) {
        columns = action.Columns;
    }

    // table meta
    var tableId = `table#${action.ID}`;
    var table = $(tableId);

    var tableHead = $(`${tableId} thead`);
    var tableBody = $(`${tableId} tbody`);

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
    keys.forEach((key) => {
        if ((key in columns) && (columns[key].Width > 0)) {
            _value += `<th style='width:${columns[key].Width}%'>${key}</th>`;
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
            _value += `<td>`;

            if ($.isArray(item[key]) || item[key].ElementType) {
                _value += buildElements(item[key]);
            }
            else {
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
    feather.replace();
    $('[data-toggle="tooltip"]').tooltip();
    bindTableSort(tableId);
    bindButtons();
    bindTablePagination();

    // setup table filter
    filterTable(table.closest('div.card-body').find('input.pode-table-filter'));

    // setup clickable rows
    $(`${tableId}.pode-table-click tbody tr`).click(function() {
        var dataValue = $(this).attr('pode-data-value');
        window.location = `${window.location.href}?value=${dataValue}`;
    });
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

    return $(element).prop('nodeName').toLowerCase();
}

function testTagName(element, tagName) {
    return (getTagName(element) == tagName.toLowerCase());
}

function actionForm(action) {
    var form = $(action.ID);
    if (!form) {
        return;
    }

    form[0].reset();
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
    var modal = $(`div#${action.ID}.modal`);
    if (!modal) {
        return;
    }

    if (action.DataValue) {
        modal.attr('pode-data-value', action.DataValue);
    }

    invokeActions(action.Actions);
    modal.modal('show');
}

function hideModal(action, sender) {
    var modal = null;
    if (action.ID) {
        modal = $(`div#${action.ID}.modal`);
    }
    else {
        modal = sender.closest('div.modal');
    }

    if (!modal) {
        return;
    }

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

    text.text(action.Value);
}

function actionCheckbox(action) {
    var checkbox = $(`#${action.ID}_option0`);
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
                <span data-feather='${action.Icon.toLowerCase()}'></span>
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

    feather.replace();

    $(`div#${toastId}`).on('hidden.bs.toast', function(e) {
        $(e.target).remove();
    })

    $(`div#${toastId}`).toast('show');
}

function actionValidation(action, sender) {
    var input = null;
    if (action.ID) {
        input = $(`#${action.ID}`);
    }
    else {
        input = sender.find(`[name="${action.Name}"]`);
    }

    if (!input) {
        return;
    }

    var validationId = `div#${$(input).attr('id')}_validation`;
    $(validationId).text(action.Message);

    setValidationError(input);
}

function actionTextbox(action, sender) {
    if (action.ID) {
        updateTextbox(action);
    }
    else {
        writeTextbox(action, sender);
    }
}

function updateTextbox(action) {
    if (!action.Data) {
        return;
    }

    if (action.AsJson) {
        action.Data = JSON.stringify(action.Data, null, 4);
    }

    var txtId = `input#${action.ID}`;
    if (action.Multiline) {
        txtId = `textarea#${action.ID}`;
    }

    var txt = $(txtId);
    txt.val(action.Data);
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

    for (var i = 0; i < rows.length; i++) {
        var row = [];
        var cols = $(rows[i]).find('td, th');

        for (var j = 0; j < cols.length; j++) {
            row.push(cols[j].innerText);
        }

        csv.push(row.join(","));
    }

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
    if (action.ID) {
        updateChart(action, sender);
    }
    else {
        writeChart(action, sender);
    }
}

var _charts = {};

function updateChart(action, sender) {
    if (!action.Data) {
        return;
    }

    if (!$.isArray(action.Data)) {
        action.Data = [action.Data];
    }

    if (action.Data.length <= 0) {
        return;
    }

    var canvas = $(`canvas#${action.ID}`)
    var _append = (canvas.attr('pode-append') == 'True');

    // apend new data, rather than rebuild the chart
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

    // axis themes
    var axesOpts = [];

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

    // dataset details
    Object.keys(yAxises).forEach((key, index) => {
        switch (chartType.toLowerCase()) {
            case 'line':
                yAxises[key].backgroundColor = palette[index % palette.length].replace(')', ', 0.2)');
                yAxises[key].borderColor = palette[index % palette.length];
                yAxises[key].borderWidth = 3;
                axesOpts = getChartAxesColours(theme);
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
                axesOpts = getChartAxesColours(theme);
                break;
        }
    });

    // make the chart
    var chart = new Chart(ctx, {
        type: chartType.toLowerCase(),

        data: {
            labels: xAxis,
            datasets: Object.values(yAxises)
        },

        options: {
            legend: {
                display: (Object.keys(yAxises)[0].toLowerCase() != 'default'),
                labels: {
                    fontColor: $('body').css('color')
                }
            },

            scales: {
                xAxes: axesOpts,
                yAxes: axesOpts
            }
        }
    });

    // save chart for later appending, or resetting
    _charts[action.ID] = {
        canvas: chart,
        append: _append
    };
}

function getChartAxesColours(theme) {
    switch (theme) {
        case 'dark':
            return [{
                gridLines: {
                    color: '#214981',
                    zeroLineColor: '#214981'
                },
                ticks: { fontColor: '#ccc' }
            }];

        case 'terminal':
            return [{
                gridLines: {
                    color: 'darkgreen',
                    zeroLineColor: 'darkgreen'
                },
                ticks: { fontColor: '#33ff00' }
            }];

        default:
            return [{
                gridLines: {
                    color: 'lightgrey',
                    zeroLineColor: 'lightgrey'
                },
                ticks: { fontColor: '#333' }
            }];
    }
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
        sender.after(`<canvas class="my-4 w-100" id="${chartId}" pode-chart-type="${action.ChartType}"></canvas>`);
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
        icon = `<span data-feather='${element.Icon.toLowerCase()}' class='mRight02'></span>`
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

    return `<span data-feather='${element.Name.toLowerCase()}' ${colour}></span>`;
}

function buildBadge(element) {
    return `<span id='${element.ID}' class='badge badge-${element.ColourType}'>${element.Value}</span>`;
}

function buildSpinner(element) {
    var colour = '';
    if (element.Colour) {
        colour = `style="color:${element.Colour};"`
    }

    return `<span class="spinner-border spinner-border-sm" role="status" ${colour}></span>`;
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

    if (action.Url.startsWith('/')) {
        action.Url = `${window.location.origin}${action.Url}`;
    }

    window.location = action.Url;
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
        badge.text(action.Value);
    }

    // change colour
    if (action.Colour) {
        badge.removeClass();
        badge.addClass(`badge badge-${action.ColourType}`);
    }
}

function actionTab(action) {
    if (!action) {
        return;
    }

    moveTab(action.ID ?? `tab_${action.Name}`);
}

function moveTab(tabId) {
    $(`a.nav-link#${tabId}`).click();
}