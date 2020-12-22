$.expr[":"].icontains = $.expr.createPseudo(function(arg) {
    return function(elem) {
        return $(elem).text().toLowerCase().indexOf(arg.toLowerCase()) >= 0;
    };
});

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
    loadTables();
    loadCharts();
    loadAutoCompletes();

    bindSidebarFilter();
    bindMenuToggle();

    bindFormSubmits();
    bindButtons();
    bindCodeCopy();
    bindCodeEditors();

    bindTableFilters();
    bindTableExports();
    bindTableRefresh();

    bindChartRefresh();
    bindRangeValue();
    bindProgressValue();
    bindModalSubmits();

    bindPageGroupCollapse();
    bindCardCollapse();

    bindTimers();
});

function bindCodeEditors() {
    if ($('.code-editor').length == 0) {
        return;
    }

    var src = $('script[role="monaco"]').attr('src');
    require.config({ paths: { 'vs': src.substring(0, src.lastIndexOf('/')) }});

    require(["vs/editor/editor.main"], function() {
        $('.code-editor').each((i, e) => {
            var editor = monaco.editor.create(e, {
                value: '',
                language: $(e).attr('pode-language'),
                theme: $(e).attr('pode-theme')
            });
        });
    });
}

function bindCardCollapse() {
    $('button.pode-card-collapse').click(function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = $(e.currentTarget);
        button.find('.feather-eye').toggle();
        button.find('.feather-eye-off').toggle();

        button.closest('.card').find('.card-body').slideToggle();
    });
}

function bindTimers() {
    $('span.pode-timer').each((i, e) => {
        var interval = $(e).attr('pode-interval');
        var id = $(e).attr('id');

        invokeTimer(id);

        setInterval(() => {
            invokeTimer(id);
        }, interval);
    });
}

function invokeTimer(timerId) {
    $.ajax({
        url: `/components/timer/${timerId}`,
        method: 'post',
        success: function(res) {
            invokeActions(res);
        },
        error: function(err) {
            console.log(err);
        }
    });
}

function bindMenuToggle() {
    $('button#menu-toggle').click(function(e) {
        e.preventDefault();
        e.stopPropagation();

        $('nav#sidebarMenu').toggleClass('hide');
        $('main[role="main"]').toggleClass('fullscreen');
    });
}

function bindTablePagination() {
    $('nav .pagination a.page-link').click(function(e) {
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

    // define any table paging
    var data = '';
    if (pageNumber || pageAmount) {
        pageNumber = (pageNumber ?? 1);
        pageAmount = (pageAmount ?? 20);
        data = `PageNumber=${pageNumber}&PageAmount=${pageAmount}`;
    }

    // things get funky here if we have a table with a 'for' attr
    // if so, we need to serialize the form, and then send the request to the form instead
    var table = $(`table#${tableId}`);
    var url = `/components/table/${tableId}`;

    if (table.attr('for')) {
        var form = $(`#${table.attr('for')}`);
        if (data) {
            data += '&';
        }

        data += form.serialize();
        url = form.attr('method');
    }

    // invoke and load table content
    $.ajax({
        url: url,
        method: 'post',
        data: data,
        contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
        success: function(res) {
            invokeActions(res, table);
        },
        error: function(err) {
            console.log(err);
        }
    });
}

function loadAutoCompletes() {
    $(`input[pode-autocomplete='True']`).each((i, e) => {
        $.ajax({
            url: `/elements/autocomplete/${$(e).attr('id')}`,
            method: 'post',
            success: function(res) {
                $(e).autocomplete({ source: res.Values });
            },
            error: function(err) {
                console.log(err);
            }
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
    var url = `/components/chart/${chartId}`;

    if (chart.attr('for')) {
        var form = $(`#${chart.attr('for')}`);
        if (data) {
            data += '&';
        }

        data += form.serialize();
        url = form.attr('method');
    }

    $.ajax({
        url: url,
        method: 'post',
        data: data,
        contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
        success: function(res) {
            invokeActions(res, $(`canvas#${chartId}`));
        },
        error: function(err) {
            console.log(err);
        }
    });
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
    $("form.pode-component-form").submit(function(e) {
        e.preventDefault();
        e.stopPropagation();

        var form = $(e.target);
        var spinner = form.find('button span.spinner-border');

        form.find('.is-invalid').removeClass('is-invalid');
        if (spinner) {
            spinner.show();
        }

        $.ajax({
            url: form.attr('method'),
            method: form.attr('action'),
            data: form.serialize(),
            contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
            success: function(res) {
                if (spinner) {
                    spinner.hide();
                }
                invokeActions(res, form);
            },
            error: function(err) {
                if (spinner) {
                    spinner.hide();
                }
                console.log(err);
            }
        });
    });
}

function bindModalSubmits() {
    $("div.modal-footer button.pode-modal-submit").click(function(e) {
        e.preventDefault();
        e.stopPropagation();

        // get the button
        var button = $(e.target);
        if (button.prop('nodeName').toLowerCase() != 'button') {
            button = button.closest('button');
        }

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
            form.find('.is-invalid').removeClass('is-invalid');
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
        $.ajax({
            url: url,
            method: 'POST',
            data: formData,
            contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
            success: function(res) {
                if (spinner) {
                    spinner.hide();
                }
                invokeActions(res, (form ?? button));
            },
            error: function(err) {
                if (spinner) {
                    spinner.hide();
                }
                console.log(err);
            }
        });
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
    $('pre button.pode-code-copy').click(function(e) {
        var value = $(e.target).closest('pre').find('code').text().trim();
        navigator.clipboard.writeText(value);
    });
}

function bindButtons() {
    $("button.pode-button").click(function(e) {
        e.preventDefault();
        e.stopPropagation();

        var button = $(e.target);
        if (button.prop('nodeName').toLowerCase() != 'button') {
            button = button.closest('button');
        }

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

        $.ajax({
            url: `/elements/button/${button.attr('id')}`,
            method: 'POST',
            data: data,
            contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
            success: function(res) {
                if (spinner) {
                    spinner.hide();
                }
                invokeActions(res, button);
            },
            error: function(err) {
                if (spinner) {
                    spinner.hide();
                }
                console.log(err);
            }
        });
    });
}

function bindTableFilters() {
    $("input.pode-table-filter").keyup(function(e) {
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
    $("input.pode-nav-filter").keyup(function(e) {
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
    $("button.pode-table-export").click(function(e) {
        e.preventDefault();

        var input = $(e.target);
        var tableId = input.attr('for');

        exportTableAsCSV(tableId);
    });
}

function bindTableRefresh() {
    $("button.pode-table-refresh").click(function(e) {
        e.preventDefault();
        loadTable($(e.target).attr('for'));
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

function bindChartRefresh() {
    $("button.pode-chart-refresh").click(function(e) {
        e.preventDefault();
        loadChart($(e.target).attr('for'));
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

function updateTable(component, sender) {
    if (!component.Data) {
        return;
    }

    // convert data to array
    if (!$.isArray(component.Data)) {
        component.Data = [component.Data];
    }

    // do nothing if no data
    if (component.Data.length <= 0) {
        return;
    }

    // get data keys for table columns
    var keys = Object.keys(component.Data[0]);

    // get custom column meta - for widths etc
    var columns = {};
    if (component.Columns) {
        columns = component.Columns;
    }

    // table meta
    var tableId = `table#${component.ID}`;
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

    component.Data.forEach((item) => {
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
        var paging = table.closest('.card-body').find('nav ul');
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
        pageActive = (1 == component.Paging.Number ? 'active' : '');
        paging.append(`
            <li class="page-item">
                <a class="page-link ${pageActive}" href="#">1</a>
            </li>`);

        // ...
        if (component.Paging.Number > 4) {
            paging.append(`
                <li class="page-item">
                    <a class="page-link disabled" href="#">...</a>
                </li>`);
        }

        // pages
        for (var i = (component.Paging.Number - 2); i <= (component.Paging.Number + 2); i++) {
            if (i <= 1 || i >= component.Paging.Max) {
                continue;
            }

            pageActive = (i == component.Paging.Number ? 'active' : '');
            paging.append(`
                <li class="page-item">
                    <a class="page-link ${pageActive}" href="#">${i}</a>
                </li>`);
        }

        // ...
        if (component.Paging.Number < component.Paging.Max - 3) {
            paging.append(`
                <li class="page-item">
                    <a class="page-link disabled" href="#">...</a>
                </li>`);
        }

        // last page
        if (component.Paging.Max > 1) {
            pageActive = (component.Paging.Max == component.Paging.Number ? 'active' : '');
            paging.append(`
                <li class="page-item">
                    <a class="page-link ${pageActive}" href="#">${component.Paging.Max}</a>
                </li>`);
        }

        // next
        paging.append(`
            <li class="page-item">
                <a class="page-link page-arrows page-next" href="#" aria-label="Next" pode-max="${component.Paging.Max}">
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

function writeTable(component, sender) {
    var senderId = getId(sender);
    var tableId = `table_${senderId}`;

    // card
    var card = sender.closest('.card-body');

    // create table
    var table = $(`table#${tableId}`);
    if (table.length == 0) {
        card.append(`
            <table id="${tableId}" class="table table-striped table-sm" pode-sort="${component.Sort}">
                <thead></thead>
                <tbody></tbody>
            </table>
        `);
    }

    // update
    component.ID = tableId;
    updateTable(component, sender);
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

    $(input).addClass('is-invalid');
}

function actionTextbox(action, sender) {
    if (action.ID) {
        updateTextbox(action);
    }
    else {
        writeTextbox(action, sender);
    }
}

function updateTextbox(component) {
    if (!component.Data) {
        return;
    }

    if (component.AsJson) {
        component.Data = JSON.stringify(component.Data, null, 4);
    }

    var txtId = `input#${component.ID}`;
    if (component.Multiline) {
        txtId = `textarea#${component.ID}`;
    }

    var txt = $(txtId);
    txt.val(component.Data);
}

function writeTextbox(component, sender) {
    var senderId = getId(sender);
    var txtId = `txt_${senderId}`;

    // create textbox
    var element = null;
    var txt = null;

    // default attrs
    var readOnly = '';
    if (component.ReadOnly) {
        readOnly ='readonly';
    }

    if (component.Multiline) {
        txt = $(`textarea#${txtId}`);
        if (txt.length == 0) {
            element = `<textarea class='form-control' id='${txtId}' rows='${component.Height}' ${readOnly}></textarea>`;
        }
    }
    else {
        txt = $(`input#${txtId}`);
        if (txt.length == 0) {
            element = `<input type='text' class='form-control' id='${txtId}' ${readOnly}>`;
        }
    }

    if (element) {
        if (component.Preformat) {
            element = `<pre>${element}</pre>`;
        }

        var card = sender.closest('.card-body');
        card.append(element);
    }

    // update
    component.ID = txtId;
    updateTextbox(component);
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

    // download
    var tableName = $(`table#${tableId}`).attr('name').replace(' ', '_');
    downloadCSV(csv.join("\n"), `${tableName}.csv`);
}

function downloadCSV(csv, filename) {
    // the csv file
    var csvFile = new Blob([csv], {type: "text/csv"});

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

function updateChart(component, sender) {
    if (!component.Data) {
        return;
    }

    if (!$.isArray(component.Data)) {
        component.Data = [component.Data];
    }

    if (component.Data.length <= 0) {
        return;
    }

    var canvas = $(`canvas#${component.ID}`)
    var _append = (canvas.attr('pode-append') == 'True');

    // apend new data, rather than rebuild the chart
    if (_append && _charts[component.ID]) {
        appendToChart(canvas, component);
    }

    // build the chart
    else {
        createTheChart(canvas, component, sender);
    }
}

function appendToChart(canvas, component) {
    var _chart = _charts[component.ID];
    var _max = canvas.attr('pode-max');
    var _timeLabels = (canvas.attr('pode-time-labels') == 'True');

    // labels (x-axis)
    component.Data.forEach((item) => {
        if (_timeLabels) {
            _chart.canvas.data.labels.push(getTimeString());
        }
        else {
            _chart.canvas.data.labels.push(item.Key);
        }
    });

    _chart.canvas.data.labels = truncateArray(_chart.canvas.data.labels, _max);

    // data (y-axis)
    component.Data.forEach((item) => {
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

function createTheChart(canvas, component, sender) {
    // remove chart
    var _chart = _charts[component.ID];
    if (_chart) {
        _chart.canvas.destroy();
    }

    // get the chart's canvas and type
    var ctx = document.getElementById(component.ID).getContext('2d');
    var chartType = (canvas.attr('pode-chart-type') || component.ChartType);
    var theme = $('body').attr('pode-theme');
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
    component.Data.forEach((item) => {
        if (_timeLabels) {
            xAxis = xAxis.concat(getTimeString());
        }
        else {
            xAxis = xAxis.concat(item.Key);
        }
    });

    // y-axis labels - need to support datasets
    var yAxises = {};
    component.Data[0].Values.forEach((item) => {
        yAxises[item.Key] = {
            data: [],
            label: item.Key
        };
    });

    component.Data.forEach((item) => {
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
    _charts[component.ID] = {
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

function writeChart(component, sender) {
    var senderId = getId(sender);
    var chartId = `chart_${senderId}`;

    // card
    var card = sender.closest('.card-body');

    // create canvas
    var canvas = $(`canvas#${chartId}`);
    if (canvas.length == 0) {
        card.append(`<canvas class="my-4 w-100" id="${chartId}" pode-chart-type="${component.ChartType}"></canvas>`);
    }

    // update
    component.ID = chartId;
    updateChart(component, sender);
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
    return `<span data-feather='${element.Name.toLowerCase()}'></span>`;
}

function buildBadge(element) {
    return `<span id='${element.ID}' class='badge badge-${element.ColourType}'>${element.Value}</span>`;
}

function buildSpinner(element) {
    return `<span class="spinner-border spinner-border-sm" role="status"></span>`;
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