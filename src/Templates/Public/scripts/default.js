$.expr[":"].icontains = $.expr.createPseudo(function(arg) {
    return function(elem) {
        return $(elem).text().toLowerCase().indexOf(arg.toLowerCase()) >= 0;
    };
});

(function () {
    feather.replace();
})();
(function () {
    $('[data-toggle="tooltip"]').tooltip();
})();
(function () {
    hljs.initHighlightingOnLoad();
})();

$(document).ready(() => {
    loadTables();
    loadCharts();
    loadAutoCompletes();

    bindSidebarFilter();
    bindFormSubmits();
    bindButtons();
    bindTableFilters();
    bindTableExports();
    bindTableRefresh();
    bindChartRefresh();
    bindRangeValue();
    bindProgressValue();
    bindModalSubmits();
    bindCollapse();
});

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

function bindCollapse() {
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

function loadTables(tableId) {
    if (tableId && !tableId.startsWith('#')) {
        tableId = `#${tableId}`;
    }

    if (!tableId) {
        tableId = '';
    }

    $(`table${tableId}[pode-dynamic='True']`).each((i, e) => {
        $.ajax({
            url: `/components/table/${$(e).attr('id')}`,
            method: 'post',
            success: function(res) {
                invokeActions(res, $(e));
            }
        });
    });
}

function loadAutoCompletes() {
    $(`input[pode-autocomplete='True']`).each((i, e) => {
        $.ajax({
            url: `/elements/autocomplete/${$(e).attr('id')}`,
            method: 'post',
            success: function(res) {
                $(e).autocomplete({ source: res.Values });
            }
        });
    });
}

function loadCharts(chartId) {
    if (chartId && !chartId.startsWith('#')) {
        chartId = `#${chartId}`;
    }

    if (!chartId) {
        chartId = '';
    }

    $(`canvas${chartId}[pode-dynamic='True']`).each((i, e) => {
        $.ajax({
            url: `/components/chart/${$(e).attr('id')}`,
            method: 'post',
            success: function(res) {
                invokeActions(res, $(e));
            }
        });
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
                html += getButton(ele);
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
        loadTables($(e.target).attr('for'));
    });

    $("table[pode-auto-refresh='True']").each((index, item) => {
        setTimeout(() => {
            loadTables($(item).attr('id'));
            setInterval(() => {
                loadTables($(item).attr('id'));
            }, 60000);
        }, (60 - (new Date()).getSeconds()) * 1000);
    });
}

function bindChartRefresh() {
    $("button.pode-chart-refresh").click(function(e) {
        e.preventDefault();
        loadCharts($(e.target).attr('for'));
    });

    $("canvas[pode-auto-refresh='True']").each((index, item) => {
        setTimeout(() => {
            loadCharts($(item).attr('id'));
            setInterval(() => {
                loadCharts($(item).attr('id'));
            }, 60000);
        }, (60 - (new Date()).getSeconds()) * 1000);
    });
}

function actionTable(action, sender) {
    switch (action.Operation.toLowerCase()) {
        case 'output':
            if (action.ID) {
                updateTable(action);
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

    loadTables(action.ID);
}

function updateTable(component) {
    if (!component.Data) {
        return;
    }

    if (!$.isArray(component.Data)) {
        component.Data = [component.Data];
    }

    if (component.Data.length <= 0) {
        return;
    }

    var keys = Object.keys(component.Data[0]);

    var tableId = `table#${component.ID}`;
    var tableHead = $(`${tableId} thead`);
    var tableBody = $(`${tableId} tbody`);

    // is there a data column?
    var dataColumn = $(tableId).attr('pode-data-column');

    // headers
    tableHead.empty();

    var _value = '<tr>';
    keys.forEach((key) => {
        _value += `<th>${key}</th>`;
    });
    _value += '</tr>';

    tableHead.append(_value);

    // body
    tableBody.empty();

    component.Data.forEach((item) => {
        _value = `<tr pode-data-value="${item[dataColumn]}">`;

        keys.forEach((key) => {
            _value += `<td>`;

            if ($.isArray(item[key])) {
                _value += buildElements(item[key]);
            }
            else {
                _value += item[key];
            }

            _value += `</td>`;
        });
        _value += '</tr>'
        tableBody.append(_value);
    });

    // binds
    feather.replace();
    $('[data-toggle="tooltip"]').tooltip();
    bindTableSort(tableId);
    bindButtons();

    // filter
    filterTable($(tableId).closest('div.card-body').find('input.pode-table-filter'));

    // clickable rows
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
    updateTable(component);
}

function getId(element) {
    return $(element).attr('id');
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
    var text = $(`span#${action.ID}.pode-text`);
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
            element = `<pre><textarea class='form-control' id='${txtId}' rows='${component.Height}' ${readOnly}></textarea></pre>`;
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
        updateChart(action);
    }
    else {
        writeChart(action, sender);
    }
}

var _charts = {};

function updateChart(component) {
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
    var _timeLabels = (canvas.attr('pode-time-labels') == 'True');

    if (_append && _charts[component.ID]) {
        var _chart = _charts[component.ID];
        var _max = canvas.attr('pode-max');

        // labels
        component.Data.forEach((item) => {
            if (_timeLabels) {
                _chart.data.labels.push(getTimeString());
            }
            else {
                _chart.data.labels.push(item.Key);
            }
        });

        if (_max > 0 && _chart.data.labels.length > _max) {
            _chart.data.labels = _chart.data.labels.slice(_chart.data.labels.length - _max, _chart.data.labels.length);
        }

        // data
        component.Data.forEach((item) => {
            _chart.data.datasets[0].data.push(item.Value);
        });

        if (_max > 0 && _chart.data.datasets[0].data.length > _max) {
            _chart.data.datasets[0].data = _chart.data.datasets[0].data.slice(_chart.data.datasets[0].data.length - _max, _chart.data.datasets[0].data.length);
        }

        // re-render
        _chart.update();
    }

    else {
        var xAxis = [];
        component.Data.forEach((item) => {
            if (_timeLabels) {
                xAxis = xAxis.concat(getTimeString());
            }
            else {
                xAxis = xAxis.concat(item.Key);
            }
        });

        var yAxis = [];
        component.Data.forEach((item) => {
            yAxis = yAxis.concat(item.Value);
        });

        var ctx = document.getElementById(component.ID).getContext('2d');
        var chartType = ($(`canvas#${component.ID}`).attr('pode-chart-type') || component.ChartType);

        var palette = [
            'rgb(255, 159, 64)',
            'rgb(255, 99, 132)',
            'rgb(255, 205, 86)',
            'rgb(0, 163, 51)',
            'rgb(54, 162, 235)',
            'rgb(153, 102, 255)',
            'rgb(201, 203, 207)'
        ]

        var isDark = $('body.pode-dark').length > 0;

        var dataset = {};

        var axesOpts = [];
        var axesDarkOpts = [{
            gridLines: {
                color: '#214981',
                zeroLineColor: '#214981'
            },
            ticks: { fontColor: '#ccc' }
        }];

        switch (chartType.toLowerCase()) {
            case 'line':
                dataset = {
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgb(54, 162, 235)',
                    borderWidth: 3,
                    pointBackgroundColor: '#007bff'
                }

                if (isDark) {
                    axesOpts = axesDarkOpts;
                }
                break;

            case 'doughnut':
            case 'pie':
                dataset = {
                    backgroundColor: function(context) {
                        return palette[context.dataIndex % palette.length];
                    }
                }

                if (isDark) {
                    dataset.borderColor = '#214981';
                }
                break;

            case 'bar':
                dataset = {
                    backgroundColor: function(context) {
                        return palette[context.dataIndex % palette.length].replace(')', ', 0.6)');
                    },
                    borderColor: function(context) {
                        return palette[context.dataIndex % palette.length];
                    },
                    borderWidth: 1
                }

                if (isDark) {
                    axesOpts = axesDarkOpts;
                }
                break;
        }

        dataset.data = yAxis;

        var chart = new Chart(ctx, {
            type: chartType.toLowerCase(),

            data: {
                labels: xAxis,
                datasets: [dataset]
            },

            options: {
                legend: {
                    display: false
                },

                scales: {
                    xAxes: axesOpts,
                    yAxes: axesOpts
                }
            }
        });

        if (_append) {
            _charts[component.ID] = chart;
        }
    }
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
    updateChart(component);
}

function getTimeString() {
    return (new Date()).toLocaleTimeString().split(':').slice(0,2).join(':');
}

function getButton(element) {
    var icon = '';
    if (element.Icon) {
        icon = `<span data-feather='${element.Icon.toLowerCase()}' class='mRight02'></span>`
    }

    if (element.IconOnly) {
        return `<button type='button' class='btn btn-icon-only pode-button' id='${element.ID}' pode-data-value='${element.DataValue}' title='${element.Name}' data-toggle='tooltip'>${icon}</button>`;
    }

    return `<button type='button' class='btn btn-primary pode-button' id='${element.ID}' pode-data-value='${element.DataValue}'>
        <span class='spinner-border spinner-border-sm' role='status' aria-hidden='true' style='display: none'></span>
        ${icon}${element.Name}
    </button>`;
}