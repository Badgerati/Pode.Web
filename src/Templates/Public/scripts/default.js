$.expr[":"].icontains = $.expr.createPseudo(function(arg) {
    return function(elem) {
        return $(elem).text().toLowerCase().indexOf(arg.toLowerCase()) >= 0;
    };
});

(function () {
    feather.replace();
})();

$(document).ready(() => {
    loadTables();
    loadCharts();
    bindSidebarFilter();
    bindFormSubmits();
    bindButtons();
    bindTableFilters();
    bindTableExports();
    bindTableRefresh();
    bindChartRefresh();
    bindRangeValue();
    bindProgressValue();
    bindCollapse();
});

function bindTableSort(tableId) {
    $(`${tableId}[data-pode-sort='True'] thead th`).click(function() {
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

    $(`table${tableId}[data-pode-dynamic='True']`).each((i, e) => {
        $.ajax({
            url: `/components/table/${$(e).attr('id')}`,
            method: 'post',
            success: function(res) {
                loadComponents(res, $(e));
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

    $(`canvas${chartId}[data-pode-dynamic='True']`).each((i, e) => {
        $.ajax({
            url: `/components/chart/${$(e).attr('id')}`,
            method: 'post',
            success: function(res) {
                loadComponents(res, $(e));
            }
        });
    });
}

function loadComponents(components, sender) {
    if (!components) {
        return;
    }

    if (!$.isArray(components)) {
        components = [components];
    }

    components.forEach((comp) => {
        switch (comp.OutputType.toLowerCase()) {
            case 'table':
                outputTable(comp, sender);
                break;

            case 'chart':
                outputChart(comp, sender);
                break;

            case 'textbox':
                outputTextbox(comp, sender);
                break;

            case 'toast':
                newToast(comp);
                break;

            case 'validation':
                outputValidation(comp, sender);
                break;

            default:
                break;
        }
    });
}

function bindFormSubmits() {
    $("form.pode-component-form").submit(function(e) {
        e.preventDefault();
        e.stopPropagation();

        var form = $(e.target);
        var spinner = form.find('button span.spinner-border');

        form.find('.is-invalid').removeClass('is-invalid');
        spinner.show();

        $.ajax({
            url: form.attr('method'),
            method: form.attr('action'),
            data: form.serialize(),
            contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
            success: function(res) {
                spinner.hide();
                loadComponents(res, form);
            },
            error: function(err) {
                spinner.hide();
                console.log(err);
            }
        });
    });
}

function bindButtons() {
    $("button.pode-button").click(function(e) {
        e.preventDefault();
        var button = $(e.target);

        var dataValue = button.attr('pode-data-value');
        var data = `Value=${dataValue}`;

        if (!dataValue) {
            var form = button.closest('form');

            if (form) {
                data = form.serialize();
            }
        }

        var spinner = button.find('span.spinner-border');
        spinner.show();

        $.ajax({
            url: `/elements/button/${button.attr('id')}`,
            method: 'POST',
            data: data,
            contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
            success: function(res) {
                spinner.hide();
                loadComponents(res, button);
            },
            error: function(err) {
                spinner.hide();
                console.log(err);
            }
        });
    });
}

function bindTableFilters() {
    $("input.pode-table-filter").keyup(function(e) {
        e.preventDefault();

        var input = $(e.target);
        var tableId = input.attr('for');
        var value = input.val();

        $(`table#${tableId} tbody tr:not(:icontains('${value}'))`).hide();
        $(`table#${tableId} tbody tr:icontains('${value}')`).show();
    });
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

    $("table[data-pode-auto-refresh='True']").each((index, item) => {
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

    $("canvas[data-pode-auto-refresh='True']").each((index, item) => {
        setTimeout(() => {
            loadCharts($(item).attr('id'));
            setInterval(() => {
                loadCharts($(item).attr('id'));
            }, 60000);
        }, (60 - (new Date()).getSeconds()) * 1000);
    });
}

function outputTable(component, sender) {
    if (component.ID) {
        updateTable(component);
    }
    else {
        writeTable(component, sender);
    }
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

    tableHead.empty();
    var _value = '<tr>';
    keys.forEach((key) => {
        _value += `<th>${key}</th>`;
    });
    _value += '</tr>';
    tableHead.append(_value);

    tableBody.empty();
    component.Data.forEach((item) => {
        _value = '<tr>';
        keys.forEach((key) => {
            _value += `<td>${item[key]}</td>`;
        });
        _value += '</tr>'
        tableBody.append(_value);
    });

    bindTableSort(tableId);
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
            <table id="${tableId}" class="table table-striped table-sm" data-pode-sort="${component.Sort}">
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

function newToast(component) {
    var toastArea = $('div#toast-area');
    if (toastArea.length == 0) {
        return;
    }

    var toastCount = $('.toast').length;
    var toastId = `toast${toastCount + 1}`;

    toastArea.append(`
        <div id="${toastId}" class="toast" role="alert" aria-live="assertive" aria-atomic="true" data-delay="${component.Duration}">
            <div class="toast-header">
                <span data-feather='${component.Icon.toLowerCase()}'></span>
                <strong class="mr-auto mLeft05">${component.Title}</strong>
                <button type="button" class="ml-2 mb-1 close" data-dismiss="toast" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="toast-body">
                ${component.Message}
            </div>
        </div>
    `);

    feather.replace();

    $(`div#${toastId}`).on('hidden.bs.toast', function(e) {
        $(e.target).remove();
    })

    $(`div#${toastId}`).toast('show');
}

function outputValidation(component, sender) {
    var input = null;
    if (component.ID) {
        input = $(`#${component.ID}`);
    }
    else {
        input = sender.find(`[name="${component.Name}"]`);
    }

    var validationId = `div#${$(input).attr('id')}_validation`;
    $(validationId).text(component.Message);

    $(input).addClass('is-invalid');
}

function outputTextbox(component, sender) {
    if (component.ID) {
        updateTextbox(component);
    }
    else {
        writeTextbox(component, sender);
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

    if (component.Multiline) {
        txt = $(`textarea#${txtId}`);
        if (txt.length == 0) {
            element = `<pre><textarea class='form-control' id='${txtId}' rows='${component.Height}'></textarea></pre>`;
        }
    }
    else {
        txt = $(`input#${txtId}`);
        if (txt.length == 0) {
            element = `<input type='text' class='form-control' id='${txtId}'>`;
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

function outputChart(component, sender) {
    if (component.ID) {
        updateChart(component);
    }
    else {
        writeChart(component, sender);
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
    var _append = (canvas.attr('data-pode-append') == 'True');
    var _timeLabels = (canvas.attr('data-pode-time-labels') == 'True');

    if (_append && _charts[component.ID]) {
        var _chart = _charts[component.ID];
        var _max = canvas.attr('data-pode-max');

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
        var chartType = ($(`canvas#${component.ID}`).attr('data-pode-chart-type') || component.ChartType);

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
                color: '#ccc',
                zeroLineColor: '#ccc'
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
                    dataset.borderColor = '#444';
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
        card.append(`<canvas class="my-4 w-100" id="${chartId}" data-pode-chart-type="${component.ChartType}"></canvas>`);
    }

    // update
    component.ID = chartId;
    updateChart(component);
}

function getTimeString() {
    return (new Date()).toLocaleTimeString().split(':').slice(0,2).join(':');
}