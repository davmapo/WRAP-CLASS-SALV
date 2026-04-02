# LCL_BUILD_SALV — ABAP SALV Wrapper Class

A lightweight wrapper around `CL_SALV_TABLE` that simplifies the setup of ALV grids in ABAP programs.
It reduces boilerplate by exposing clean, opinionated methods for the most common configuration tasks,
while still allowing full access to the underlying SAP SALV objects for advanced use cases.

---

## Table of Contents

- [Overview](#overview)
- [Setup](#setup)
- [Display Modes](#display-modes)
- [Method Reference](#method-reference)
  - [constructor](#constructor)
  - [build](#build)
  - [display](#display)
  - [refresh](#refresh)
  - [set_screen_status](#set_screen_status)
  - [set_selection_mode](#set_selection_mode)
  - [set_layout_settings](#set_layout_settings)
  - [get_layout](#get_layout)
  - [set_display_settings](#set_display_settings)
  - [set_all_functions](#set_all_functions)
  - [get_functions](#get_functions)
  - [set_optimize_columns](#set_optimize_columns)
  - [get_columns](#get_columns)
  - [get_events](#get_events)
  - [set_column_editable](#set_column_editable)
  - [get_alv_table_components](#get_alv_table_components)
- [Typical Call Order](#typical-call-order)
- [Full Example Program](#full-example-program)

---

## Overview

The class lives in the Include `CL_BUILD_SALV` and is defined as a local class `lcl_build_salv`.
It holds a reference to the internal table and to the `CL_SALV_TABLE` instance (`mo_alv`),
and wraps the most frequently used SALV configuration steps into dedicated methods.

**Two display modes are supported:**
- **Full-screen** — no container needed, call `build( )` without providing a container name
- **Container-embedded** — provide the name of a custom container screen element in the constructor

---

## Setup

Copy the Include into your program and add it to the TOP Include or directly before your main logic.
The class is instantiated by passing a reference to the internal table you want to display.

```abap
DATA: lt_data TYPE TABLE OF my_structure.
DATA: lo_salv TYPE REF TO lcl_build_salv.

" Fill lt_data here...

lo_salv = NEW lcl_build_salv( ir_table = REF #( lt_data ) ).
lo_salv->build( ).
lo_salv->display( ).
```

---

## Display Modes

### Full-screen mode
```abap
lo_salv = NEW lcl_build_salv( ir_table = REF #( lt_data ) ).
```

### Container-embedded mode
```abap
lo_salv = NEW lcl_build_salv(
    ir_table          = REF #( lt_data )
    iv_container_name = 'MY_CONTAINER' ).  " Name of custom control in Screen Painter
```

> **Note:** Some methods (`set_screen_status`) are only available in full-screen mode.
> Calling them in container mode raises `cx_sy_ref_is_initial`.

---

## Method Reference

---

### `constructor`

Initializes the wrapper. Must be called first.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ir_table` | `REF TO data` | Yes | Reference to the internal table to display |
| `iv_container_name` | `string` | No | Name of the custom container screen element. Omit for full-screen mode |

**Raises:** `cx_sy_ref_is_initial` if `ir_table` is not bound.

---

### `build`

Creates the `CL_SALV_TABLE` instance. Automatically uses container or full-screen mode
based on whether `iv_container_name` was provided in the constructor.

Must be called before any other method that accesses the ALV object.

**Raises:** `cx_sy_ref_is_initial`, `cx_salv_msg`, `cx_root`

---

### `display`

Renders the ALV on screen. Must be called after `build( )`.

**Raises:** `cx_sy_ref_is_initial` if `build( )` was not called first.

---

### `refresh`

Refreshes the ALV display to reflect changes made to the underlying internal table.
Must be called after `build( )`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iv_refresh_mode` | `salv_de_refresh` | `if_salv_c_refresh=>full` | Refresh depth. Values: `none` (0), `soft` (1 — visible cells only), `full` (2 — full repaint) |
| `is_stable` | `lvc_s_stbl` | — (optional) | Set `row`/`col` = `abap_true` to preserve the current scroll position after refresh |

```abap
" Full refresh, scroll position preserved
lo_salv->refresh(
    is_stable = VALUE #( row = abap_true col = abap_true ) ).

" Soft refresh (faster), scroll position preserved
lo_salv->refresh(
    iv_refresh_mode = if_salv_c_refresh=>soft
    is_stable       = VALUE #( row = abap_true col = abap_true ) ).
```

**Raises:** `cx_sy_ref_is_initial` if `build( )` was not called first.

---

### `set_screen_status`

> **Full-screen mode only.** Raises `cx_sy_ref_is_initial` if called in container mode.

Sets the PF-STATUS and the set of enabled toolbar functions.

To create a custom PF-STATUS: `SE41` → copy program `SAPLSALV_METADATA_STATUS`, status `SALV_TABLE_STANDARD`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iv_pfstatus` | `LIKE sy-pfkey` | — (required) | Name of the PF-STATUS to activate |
| `iv_set_functions` | `salv_de_function` | `cl_salv_table=>c_functions_all` (default if omitted) | Toolbar functions to enable. Possible values: `cl_salv_table=>c_functions_all`, `c_functions_default`, `c_functions_none`. Note: `c_functions_default` (space) cannot be distinguished from "not provided" — pass it explicitly if needed |

**Raises:** `cx_sy_ref_is_initial`

---

### `set_selection_mode`

Sets the row selection behavior of the ALV grid.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iv_selection_mode` | `salv_de_selection_mode` | `if_salv_c_selection_mode=>single` | Selection mode. Possible values: `none`, `single`, `multiple`, `cell`, `row_column` |

**Raises:** `cx_sy_ref_is_initial`

---

### `set_layout_settings`

Configures layout variant saving. The layout key (`sy-repid`) is always set automatically.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iv_default` | `abap_bool` | `abap_true` | Mark the layout as default |
| `iv_save_restriction` | `LIKE if_salv_c_layout=>restrict_none` | `if_salv_c_layout=>restrict_none` (default if omitted) | Who can save layouts. Values: `restrict_none`, `restrict_user_dependant`, `restrict_layout_only` |

> To set an initial layout variant, use `get_layout( )->set_initial_layout( )` after calling `set_layout_settings( )`.

**Raises:** `cx_sy_ref_is_initial`

---

### `set_display_settings`

Configures the ALV title, striped rows, and column width fitting.

> **Note:** Do not use `iv_fit_column = abap_true` together with `set_optimize_columns( )` — they conflict. Use one or the other.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iv_title` | `lvc_title` | — (optional) | Title displayed above the ALV (max 70 chars, full-screen only) |
| `iv_striped` | `abap_bool` | `abap_true` | Enable alternating row colors |
| `iv_fit_column` | `abap_bool` | `abap_true` | Auto-fit column widths to table size |

**Raises:** `cx_sy_ref_is_initial`

---

### `set_all_functions`

Enables or disables all toolbar functions at once.
For fine-grained control over individual functions, use `get_functions( )` instead.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iv_enabled` | `abap_bool` | `abap_true` | `abap_true` = enable all, `abap_false` = disable all |

**Raises:** `cx_sy_ref_is_initial`

---

### `get_layout`

Returns the underlying `CL_SALV_LAYOUT` object for full layout control.
Use this for settings not covered by `set_layout_settings( )`, such as loading a specific variant on startup.
Changes take effect immediately.

**Returns:** `REF TO cl_salv_layout`

**Raises:** `cx_sy_ref_is_initial`

```abap
lo_salv->set_layout_settings( ).
lo_salv->get_layout( )->set_initial_layout( '/MY_VARIANT' ).
```

---

### `get_functions`

Returns the underlying `CL_SALV_FUNCTIONS` object for granular toolbar control.
Changes take effect immediately — no additional method call needed.

**Returns:** `REF TO cl_salv_functions`

**Raises:** `cx_sy_ref_is_initial`

```abap
lo_salv->get_functions( )->set_sort_asc( abap_false ).
lo_salv->get_functions( )->set_export( abap_true ).
```

---

### `set_optimize_columns`

Optimizes the width of all columns at once.

> **Note:** Do not combine with `iv_fit_column = abap_true` in `set_display_settings( )`. Use one or the other.
> For per-column optimization, use `get_columns( )` and call `set_optimized( )` on individual columns.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iv_optimize` | `abap_bool` | `abap_true` | `abap_true` = optimize all columns |

**Raises:** `cx_sy_ref_is_initial`

---

### `get_columns`

Returns the underlying `CL_SALV_COLUMNS_TABLE` object for full per-column control.
Changes take effect immediately.

To access table-specific methods (color, cell type, icon, etc.), cast the individual column
to `CL_SALV_COLUMN_TABLE`.

**Returns:** `REF TO cl_salv_columns_table`

**Raises:** `cx_sy_ref_is_initial`

```abap
" Configure a single column
DATA(lo_columns) = lo_salv->get_columns( ).
DATA(lo_col)     = CAST cl_salv_column_table( lo_columns->get_column( 'FIELDNAME' ) ).
lo_col->set_visible( abap_false ).
lo_col->set_long_text( |My Label| ).

" Enable a checkbox column
" NOTE: the field must already exist in the internal table type as TYPE c LENGTH 1 (or abap_bool).
" Example type: TYPES: BEGIN OF ty_row, ... checkbox TYPE c LENGTH 1, ... END OF ty_row.
DATA(lo_chk) = CAST cl_salv_column_table( lo_columns->get_column( 'CHECKBOX' ) ).
lo_chk->set_cell_type( if_salv_c_cell_type=>checkbox_hotspot ).
```

---

### `get_events`

Returns the `CL_SALV_EVENTS_TABLE` object to register event handlers via `SET HANDLER`.
Handlers registered on the returned object are active immediately.

**Returns:** `REF TO cl_salv_events_table`

**Raises:** `cx_sy_ref_is_initial`

```abap
SET HANDLER lo_handler->on_double_click FOR lo_salv->get_events( ).
SET HANDLER lo_handler->on_link_click   FOR lo_salv->get_events( ).
```

**Common events:** `double_click`, `link_click`, `before_salv_function`, `after_salv_function`, `added_function`, `top_of_page`

---

### `set_column_editable`

Enables or disables cell editing for a single column via the extended grid API.
Must be called after `build( )`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `iv_columnname` | `lvc_fname` | — (required) | Field name of the column to configure |
| `iv_enabled` | `abap_bool` | `abap_true` | `abap_true` = cells become input-ready, `abap_false` = read-only |

```abap
" Make a column editable
lo_salv->set_column_editable( iv_columnname = 'VALUT' ).

" Return it to read-only
lo_salv->set_column_editable( iv_columnname = 'VALUT' iv_enabled = abap_false ).
```

**Raises:** `cx_sy_ref_is_initial` if `build( )` was not called first, `cx_salv_not_found` if the column does not exist.

---

### `get_alv_table_components`

Returns the list of fields (components) of the ALV internal table using RTTI introspection.
Useful for looping over all columns dynamically without hardcoding field names.

Can be called at any time after the constructor — does not require `build( )`.

**Returns:** `abap_compdescr_tab` — table of field descriptors (name, type, length, etc.)

```abap
DATA(lo_columns) = lo_salv->get_columns( ).
LOOP AT lo_salv->get_alv_table_components( ) ASSIGNING FIELD-SYMBOL(<fs_field>).
    DATA(lo_col) = CAST cl_salv_column_table( lo_columns->get_column( <fs_field>-name ) ).
    lo_col->set_optimized( abap_true ).
ENDLOOP.
```

---

## Typical Call Order

```abap
" 1. Instantiate
lo_salv = NEW lcl_build_salv( ir_table = REF #( lt_data ) ).

" 2. Build (mandatory before anything else)
lo_salv->build( ).

" 3. Configure (any order, all optional)
lo_salv->set_screen_status( iv_pfstatus = 'ZMY_STATUS' ).
lo_salv->set_selection_mode( if_salv_c_selection_mode=>multiple ).
lo_salv->set_layout_settings( ).
lo_salv->set_display_settings( iv_title = 'My Report' ).
lo_salv->set_all_functions( ).
lo_salv->set_optimize_columns( ).

" 4. Register event handlers (optional)
SET HANDLER lo_handler->on_double_click FOR lo_salv->get_events( ).

" 5. Display
lo_salv->display( ).
```

---

## Full Example Program

The following example demonstrates all features of the class in a single full-screen ABAP report.

```abap
*&---------------------------------------------------------------------*
*& Report  Z_EXAMPLE_SALV_WRAPPER
*&---------------------------------------------------------------------*
REPORT z_example_salv_wrapper.

" Include the wrapper class
INCLUDE cl_build_salv.

*----------------------------------------------------------------------*
* Data types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_employee,
    emp_id    TYPE n LENGTH 6,
    name      TYPE char40,
    dept      TYPE char20,
    salary    TYPE p DECIMALS 2,
    active    TYPE abap_bool,
END OF ty_employee.

*----------------------------------------------------------------------*
* Global data
*----------------------------------------------------------------------*
DATA: gt_employees TYPE TABLE OF ty_employee,
      go_salv      TYPE REF TO lcl_build_salv.

*----------------------------------------------------------------------*
* Event handler class
*----------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_double_click
        FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column,

      on_before_function
        FOR EVENT before_salv_function OF cl_salv_events
        IMPORTING e_salv_function.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_double_click.
    MESSAGE |Double-clicked: row { row }, column { column }| TYPE 'I'.
  ENDMETHOD.

  METHOD on_before_function.
    " Intercept toolbar actions if needed
    CASE e_salv_function.
      WHEN 'ZDELETE'.
        " Custom logic before delete
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Initialization — fill demo data
*----------------------------------------------------------------------*
INITIALIZATION.
  gt_employees = VALUE #(
      ( emp_id = '000001' name = 'Mario Rossi'    dept = 'IT'      salary = '3500.00' active = abap_true  )
      ( emp_id = '000002' name = 'Laura Bianchi'  dept = 'Finance' salary = '4200.00' active = abap_true  )
      ( emp_id = '000003' name = 'Carlo Verdi'    dept = 'HR'      salary = '2900.00' active = abap_false )
      ( emp_id = '000004' name = 'Anna Neri'      dept = 'IT'      salary = '3800.00' active = abap_true  ) ).

*----------------------------------------------------------------------*
* Start of selection — build and display the ALV
*----------------------------------------------------------------------*
START-OF-SELECTION.

  TRY.

      "--- 1. Instantiate the wrapper (full-screen mode, no container) ---
      go_salv = NEW lcl_build_salv( ir_table = REF #( gt_employees ) ).

      "--- 2. Build the ALV object ---
      go_salv->build( ).

      "--- 3. PF-STATUS (full-screen only) ---
      " Requires a custom GUI status named 'ZEMP_STATUS' in this program.
      " Copy from SE41: program SAPLSALV_METADATA_STATUS, status SALV_TABLE_STANDARD.
      go_salv->set_screen_status(
          iv_pfstatus      = 'ZEMP_STATUS'
          iv_set_functions = cl_salv_table=>c_functions_all ).

      "--- 4. Selection mode ---
      go_salv->set_selection_mode( if_salv_c_selection_mode=>multiple ).

      "--- 5. Layout settings ---
      go_salv->set_layout_settings(
          iv_default          = abap_true
          iv_save_restriction = if_salv_c_layout=>restrict_user_dependant ).

      "--- 6. Display settings ---
      go_salv->set_display_settings(
          iv_title      = 'Employee List'
          iv_striped    = abap_true
          iv_fit_column = abap_true ).

      "--- 7. Toolbar functions ---
      go_salv->set_all_functions( abap_true ).
      " For fine-grained control use get_functions( ) — available methods depend
      " on your SAP release (e.g. set_sort_asc, set_find, set_layout, set_graphics).
      " Check SE24 -> CL_SALV_FUNCTIONS for the exact method list.

      "--- 8. Column configuration ---
      DATA(lo_columns) = go_salv->get_columns( ).

      LOOP AT go_salv->get_alv_table_components( ) ASSIGNING FIELD-SYMBOL(<fs_field>).
        TRY.
            DATA(lo_col) = CAST cl_salv_column_table(
                lo_columns->get_column( <fs_field>-name ) ).

            CASE <fs_field>-name.
              WHEN 'EMP_ID'.
                lo_col->set_visible( abap_false ).          " Hide column
              WHEN 'DEPT'.
                lo_col->set_short_text( 'Dept.' ).          " Rename labels
                lo_col->set_medium_text( 'Department' ).
                lo_col->set_long_text( 'Department' ).
              WHEN 'SALARY'.
                lo_col->set_color( VALUE lvc_s_colo( col = '5' int = '1' inv = '0' ) ). " Green
            ENDCASE.

            lo_col->set_optimized( abap_true ).             " Optimize width for every column

          CATCH cx_salv_not_found.
        ENDTRY.
      ENDLOOP.

      "--- 9. Register event handlers ---
      SET HANDLER lcl_handler=>on_double_click   FOR go_salv->get_events( ).
      SET HANDLER lcl_handler=>on_before_function FOR go_salv->get_events( ).

      "--- 10. Display ---
      go_salv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
    CATCH cx_sy_ref_is_initial INTO DATA(lx_ref).
      MESSAGE 'ALV object not initialized.' TYPE 'E'.
    CATCH cx_root INTO DATA(lx_root).
      MESSAGE lx_root->get_text( ) TYPE 'E'.
  ENDTRY.
```

> **Container-embedded variant:** to embed the ALV in a screen, pass `iv_container_name` in the
> constructor and call `build( )` + configuration methods in the `PBO` module of the screen.
> Do **not** call `set_screen_status( )` in container mode.

```abap
" In PBO module:
go_salv = NEW lcl_build_salv(
    ir_table          = REF #( gt_employees )
    iv_container_name = 'MY_CONTAINER' ).
go_salv->build( ).
go_salv->set_display_settings( iv_title = 'Employees' ).
go_salv->set_all_functions( ).
go_salv->display( ).

" After data change:
go_salv->refresh(
    is_stable = VALUE #( row = abap_true col = abap_true ) ).
```
