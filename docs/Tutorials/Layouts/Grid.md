# Grid

A grid layout is an array of cells with content, equally spaced in size, that can be either horizontal or vertical in orientation.

The cells take an array of content, that can be either other layouts or raw elements.

## Usage

To create a grid you use [`New-PodeWebGrid`](../../../Functions/Layouts/New-PodeWebGrid), and supply it an array of `-Cells` using [`New-PodeWebCell`](../../../Functions/Layouts/New-PodeWebCell). The cells themselves accept an array of `-Content`.

For example, the below renders a 3 celled horizontal grid of centered images:

```powershell
New-PodeWebGrid -Cells @(
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
)
```

Which would look like below:

![grid_hori_cells](../../../images/grid_hori_cells.png)

### Vertical

You can render the cells of a grid vertically by use the `-Vertical` switch on [`New-PodeWebGrid`](../../../Functions/Layouts/New-PodeWebGrid):

```powershell
New-PodeWebGrid -Vertical -Cells @(
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
)
```

Which would look like below:

![grid_vert_cells](../../../images/grid_vert_cells.png)

## Grids in Grids

You can put grids within grids to render a multi-dimensional grid/cell layout. For example, to create a 3x3 grid of cells with images:

```powershell
New-PodeWebGrid -Cells @(
    New-PodeWebCell -Content @(
        New-PodeWebGrid -Vertical -Cells @(
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
        )
    )
    New-PodeWebCell -Content @(
        New-PodeWebGrid -Vertical -Cells @(
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
        )
    )
    New-PodeWebCell -Content @(
        New-PodeWebGrid -Vertical -Cells @(
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
            New-PodeWebCell -Content @(
                New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
            )
        )
    )
)
```

Which would look like below:

![grid_multi_cells](../../../images/grid_multi_cells.png)
