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

A grid also has an optional `-Width` parameter, and when this parameter isn't supplied the cells are all placed into one horizontal row. However, if you supply a `-Width` then this limits the number of cells that can be rendered on a row. For example if you pass 7 cells with a width of 3, then you'll end up with 3 rows: 2 rows of 3 cells and 1 row of 1 cell - the last row is padded to match match the width of the other rows.

### Vertical

You can render the cells of a grid vertically by either supplying `-Width 1` or by using the `-Vertical` switch on [`New-PodeWebGrid`](../../../Functions/Layouts/New-PodeWebGrid):

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

The above is useful if you want pure control over the grid layout. However, the following would also produce a 3x3 grid by just using the `-Width` parameter, and supplying all the cells to one grid:

```powershell
New-PodeWebGrid -Width 3 -Cells @(
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
    New-PodeWebCell -Content @(
        New-PodeWebImage -Source '/pode.web/images/icon.png' -Alignment Center
    )
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
