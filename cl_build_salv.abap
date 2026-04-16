*&---------------------------------------------------------------------*
*& Include          CL_BUILD_SALV
*&---------------------------------------------------------------------*

*** WRAP CLASS FOR CL_SALV_TABLE ***
CLASS lcl_build_salv DEFINITION.
  PUBLIC SECTION.
    METHODS:

    " Initializes the ALV wrapper.
    " ir_table must be a reference to the internal table to display.
    " iv_container_name is optional: provide it to embed the ALV in a custom container,
    " omit it for full-screen display.
    " Raises cx_sy_ref_is_initial if ir_table is not bound.
    constructor
      IMPORTING
        ir_table          TYPE REF TO data   "Reference to the internal table to display
        iv_container_name TYPE char30 OPTIONAL "Name of the custom container screen element (optional, full-screen if omitted)
      RAISING
        cx_sy_ref_is_initial,

    " Builds the ALV object (mo_alv).
    " Automatically delegates to build_in_container or build_no_container
    " depending on whether iv_container_name was provided in the constructor.
    " Must be called before any other method that accesses mo_alv.
    build
      RAISING
        cx_sy_ref_is_initial
        cx_salv_msg
        cx_root,

    " Displays the ALV on screen.
    " Must be called after build( ).
    display
      RAISING
        cx_sy_ref_is_initial,

    " Refreshes the ALV display after data changes in the underlying internal table.
    " Must be called after build( ).
    " iv_refresh_mode: if_salv_c_refresh=>full (default), soft, or none.
    " is_stable: set row/col = abap_true to keep the current scroll position after refresh.
    refresh
      IMPORTING
        iv_refresh_mode TYPE i               OPTIONAL "Default: if_salv_c_refresh=>full. Values: none(0), soft(1), full(2)"
        is_stable       TYPE lvc_s_stbl      OPTIONAL "row/col = abap_true to preserve scroll position after refresh"
      RAISING
        cx_sy_ref_is_initial,

    "can't use this method with a container. Only full-screen mode.
    " Sets the PF-STATUS and enabled toolbar functions for the ALV.
    " To create a custom PF-STATUS: SE41 -> copy program SAPLSALV_METADATA_STATUS, status SALV_TABLE_STANDARD.
    set_screen_status
      IMPORTING
        iv_pfstatus      TYPE sypfkey                                                   "PF-STATUS name (must exist in sy-repid)
        iv_set_functions LIKE cl_salv_table=>c_functions_all OPTIONAL   "If not provided, defaults to cl_salv_table=>c_functions_all. Possible values: cl_salv_table=>c_functions_all/c_functions_default/c_functions_none
      RAISING
        cx_sy_ref_is_initial,

    " Sets the row selection mode for the ALV.
    " Default is single-row selection.
    set_selection_mode
      IMPORTING
        iv_selection_mode LIKE if_salv_c_selection_mode=>single OPTIONAL "If not provided, defaults to if_salv_c_selection_mode=>single. Possible values: none, single, multiple, cell, row_column
      RAISING
        cx_sy_ref_is_initial,

    " Configures the ALV layout object (variant saving, default layout, initial layout).
    " The layout key is always built from sy-repid automatically.
    set_layout_settings
      IMPORTING
        iv_default          TYPE abap_bool                        DEFAULT abap_true  "abap_true = mark this layout as the default
        iv_save_restriction LIKE if_salv_c_layout=>restrict_none  OPTIONAL          "If not provided, defaults to if_salv_c_layout=>restrict_none. Possible values: restrict_none, restrict_user_dependant, restrict_layout_only
      RAISING
        cx_sy_ref_is_initial,

    " Configures general display settings: title, striped rows, column fitting.
    " NOTE: do NOT use iv_fit_column = abap_true together with set_optimize_columns( ) — they conflict.
    set_display_settings
      IMPORTING
        iv_title      TYPE lvc_title OPTIONAL                 "Title displayed above the ALV list (max 70 chars, full-screen only)
        iv_striped    TYPE abap_bool DEFAULT abap_true        "abap_true = alternating row colors for readability
        iv_fit_column TYPE abap_bool DEFAULT abap_true        "abap_true = auto-fit column widths to table size
      RAISING
        cx_sy_ref_is_initial,

    " Enables or disables all toolbar functions at once.
    " Use this for the common case where you just want everything on or off.
    " For fine-grained control over individual functions, use get_functions( ) instead.
    set_all_functions
      IMPORTING
        iv_enabled TYPE abap_bool DEFAULT abap_true "abap_true = enable all, abap_false = disable all
      RAISING
        cx_sy_ref_is_initial,

    " Returns the underlying CL_SALV_FUNCTIONS object so the caller can
    " enable or disable individual toolbar functions as needed.
    " Example usage:
    "   lo_salv->get_functions( )->set_sort_asc( abap_false ).
    "   lo_salv->get_functions( )->set_export( abap_true ).
    " Must be called after build( ).
    get_functions
      RETURNING
        VALUE(ro_functions) TYPE REF TO cl_salv_functions
      RAISING
        cx_sy_ref_is_initial,

    " Optimizes the width of all columns at once.
    " NOTE: do NOT use this together with set_fit_column_to_table_size( abap_true )
    " in set_display_settings( ) — they conflict. Use one or the other.
    " For per-column optimization, use get_columns( ) and call set_optimized( ) individually.
    set_optimize_columns
      IMPORTING
        iv_optimize TYPE abap_bool DEFAULT abap_true "abap_true = optimize all, abap_false = reset
      RAISING
        cx_sy_ref_is_initial,

    " Returns the underlying CL_SALV_COLUMNS_TABLE object for full column control.
    " Use this for per-column configuration: visibility, color, texts, output length,
    " icons, checkbox columns, technical flags, etc.
    " Typical usage:
    "   DATA(lo_col) = CAST cl_salv_column_table( lo_salv->get_columns( )->get_column( 'FIELDNAME' ) ).
    "   lo_col->set_visible( abap_false ).
    "   lo_col->set_color( ls_color ).
    "   lo_col->set_long_text( |My Label| ).
    " To enable a checkbox column:
    "   The field must already exist in the internal table TYPES definition as TYPE c LENGTH 1.
    "   DATA(lo_chk) = CAST cl_salv_column_table( lo_salv->get_columns( )->get_column( 'CHECKBOX' ) ).
    "   lo_chk->set_cell_type( if_salv_c_cell_type=>checkbox_hotspot ).
    " Must be called after build( ).
    get_columns
      RETURNING
        VALUE(ro_columns) TYPE REF TO cl_salv_columns_table
      RAISING
        cx_sy_ref_is_initial,

    " Returns the underlying CL_SALV_LAYOUT object for full layout control.
    " Use this for settings not covered by set_layout_settings( ), such as
    " set_initial_layout( ) to load a specific variant on startup.
    " Example usage:
    "   lo_salv->get_layout( )->set_initial_layout( '/MY_VARIANT' ).
    " Must be called after build( ).
    get_layout
      RETURNING
        VALUE(ro_layout) TYPE REF TO cl_salv_layout
      RAISING
        cx_sy_ref_is_initial,

    " Returns the CL_SALV_EVENTS_TABLE object so the caller can register
    " event handlers using the SET HANDLER statement.
    " Example usage:
    "   SET HANDLER lo_handler->on_double_click FOR lo_salv->get_events( ).
    "   SET HANDLER lo_handler->on_link_click   FOR lo_salv->get_events( ).
    " Common events: double_click, link_click, before_salv_function,
    "                after_salv_function, added_function, top_of_page.
    " Must be called after build( ).
    get_events
      RETURNING
        VALUE(ro_events) TYPE REF TO cl_salv_events_table
      RAISING
        cx_sy_ref_is_initial,

    " Enables or disables input editing for a single column via the extended grid API.
    " iv_enabled = abap_true  → cells in the column become input-ready.
    " iv_enabled = abap_false → column returns to read-only.
    " Must be called after build( ).
    set_column_editable
      IMPORTING
        iv_columnname TYPE lvc_fname         "Field name of the column to configure"
        iv_enabled    TYPE abap_bool DEFAULT abap_true "abap_true = editable, abap_false = read-only"
      RAISING
        cx_sy_ref_is_initial
        cx_salv_not_found,

    " Returns the list of fields (components) of the ALV internal table
    " using RTTI introspection. Useful for looping over columns dynamically.
    " Can be called at any time after the constructor — does not require build( ).
    get_alv_table_components
      RETURNING
        VALUE(et_alv) TYPE abap_compdescr_tab.

  PRIVATE SECTION.
    DATA: mr_table          TYPE REF TO data,          "Reference to the internal table to display
          mv_container_name TYPE char30,               "Container name for ALV display (empty = full-screen)
          mo_alv            TYPE REF TO cl_salv_table. "ALV table object, populated by build( )

    METHODS:
    " Builds the ALV inside a CL_GUI_CUSTOM_CONTAINER.
    " Used when mv_container_name is provided.
    build_in_container
      RAISING
        cx_sy_ref_is_initial
        cx_salv_msg
        cx_root,

    " Builds the ALV in full-screen mode (no container).
    " Used when mv_container_name is initial.
    build_no_container
      RAISING
        cx_salv_msg
        cx_root.

ENDCLASS.

CLASS lcl_build_salv IMPLEMENTATION.

  METHOD constructor.
    " Validate that the table reference is bound before storing it.
    IF ir_table IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    mr_table          = ir_table.
    mv_container_name = iv_container_name.
  ENDMETHOD.

  METHOD build.
    " Delegate to the appropriate build strategy based on whether
    " a container name was provided at construction time.
    IF mv_container_name IS INITIAL.
      me->build_no_container( ).
    ELSE.
      me->build_in_container( ).
    ENDIF.
  ENDMETHOD.

  METHOD display.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    mo_alv->display( ).
  ENDMETHOD.

  METHOD refresh.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Default to full refresh if caller did not provide a mode.
    " Note: none(0) is initial — treated as full, but calling refresh( none ) is pointless anyway.
    DATA(lv_refresh_mode) = COND #(
        WHEN iv_refresh_mode IS INITIAL THEN if_salv_c_refresh=>full
        ELSE iv_refresh_mode ).

    mo_alv->refresh(
        s_stable     = is_stable
        refresh_mode = lv_refresh_mode ).
  ENDMETHOD.

  METHOD build_in_container.
    DATA: lo_container        TYPE REF TO cl_gui_custom_container, "Custom container instance for the ALV
          lv_name_c           TYPE c LENGTH 30,                    "Container name as TYPE C for cl_gui_custom_container
          lv_name_string      TYPE string.                         "Container name as TYPE string for cl_salv_table=>factory

    " Defensive check: container name must be set when calling this method.
    IF mv_container_name IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " cl_gui_custom_container expects TYPE C, cl_salv_table=>factory expects TYPE string.
    " Convert mv_container_name (char30) into both required types upfront.
    lv_name_c      = mv_container_name.
    lv_name_string = mv_container_name.

    " Dereference the generic table pointer into a typed field symbol.
    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.
    ASSIGN mr_table->* TO <lt_table>.

    TRY.
        " Instantiate the custom container bound to the screen element.
        CREATE OBJECT lo_container
            EXPORTING
            container_name = lv_name_c.

        " Create the SALV table object embedded in the custom container.
        CALL METHOD cl_salv_table=>factory
            EXPORTING
            r_container    = lo_container
            container_name = lv_name_string
            IMPORTING
            r_salv_table   = mo_alv
            CHANGING
            t_table        = <lt_table>.

        CATCH cx_salv_msg INTO DATA(lx_salv).
            RAISE EXCEPTION lx_salv.   "Re-raise the concrete instance — cx_salv_msg is abstract
        CATCH cx_root INTO DATA(lx_root).
            RAISE EXCEPTION lx_root.   "Re-raise the concrete instance — cx_root is abstract
    ENDTRY.
  ENDMETHOD.

  METHOD build_no_container.
    " Dereference the generic table pointer into a typed field symbol.
    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.
    ASSIGN mr_table->* TO <lt_table>.

    TRY.
        " Create the SALV table object in full-screen mode (no container).
        CALL METHOD cl_salv_table=>factory
            IMPORTING
            r_salv_table = mo_alv
            CHANGING
            t_table      = <lt_table>.
        CATCH cx_salv_msg INTO DATA(lx_salv).
            RAISE EXCEPTION lx_salv.   "Re-raise the concrete instance — cx_salv_msg is abstract
        CATCH cx_root INTO DATA(lx_root).
            RAISE EXCEPTION lx_root.   "Re-raise the concrete instance — cx_root is abstract
    ENDTRY.
  ENDMETHOD.

  METHOD set_screen_status.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " set_screen_status is only supported in full-screen mode.
    " Raises cx_sy_ref_is_initial as a misuse signal if called when a container is in use.
    IF mv_container_name IS NOT INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Default to c_functions_all if the caller did not provide a value.
    " Note: c_functions_default cannot be distinguished from "not provided" since both are initial.
    " If you need c_functions_default explicitly, pass it directly.
    DATA(lv_set_functions) = COND #(
        WHEN iv_set_functions IS INITIAL THEN cl_salv_table=>c_functions_all
        ELSE iv_set_functions ).

    mo_alv->set_screen_status(
        pfstatus      = iv_pfstatus
        report        = sy-repid
        set_functions = lv_set_functions ).
  ENDMETHOD.

  METHOD set_selection_mode.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    DATA(lv_selection_mode) = COND #(
        WHEN iv_selection_mode IS INITIAL THEN if_salv_c_selection_mode=>single
        ELSE iv_selection_mode ).

    mo_alv->get_selections( )->set_selection_mode( lv_selection_mode ).
  ENDMETHOD.

  METHOD set_layout_settings.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    DATA(lo_layout) = mo_alv->get_layout( ).

    " The layout key identifies the program that owns the variant — always sy-repid.
    DATA(ls_key) = VALUE salv_s_layout_key( report = sy-repid ).
    lo_layout->set_key( ls_key ).
    DATA(lv_save_restriction) = COND #(
        WHEN iv_save_restriction IS INITIAL THEN if_salv_c_layout=>restrict_none
        ELSE iv_save_restriction ).

    lo_layout->set_default( iv_default ).
    lo_layout->set_save_restriction( lv_save_restriction ).

  ENDMETHOD.

  METHOD set_display_settings.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    DATA(lo_settings) = mo_alv->get_display_settings( ).
    lo_settings->set_list_header( iv_title ).           "Title above the ALV (visible in full-screen mode only)
    lo_settings->set_striped_pattern( iv_striped ).     "Alternating row colors
    lo_settings->set_fit_column_to_table_size( iv_fit_column ). "Auto-fit column widths to table width
  ENDMETHOD.

  METHOD set_optimize_columns.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Optimize all column widths in one call.
    " Avoid combining with set_fit_column_to_table_size( abap_true ) — use one or the other.
    mo_alv->get_columns( )->set_optimize( iv_optimize ).
  ENDMETHOD.

  METHOD get_columns.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Return the CL_SALV_COLUMNS_TABLE object for per-column configuration.
    " The returned reference points to the same object owned by mo_alv —
    " any changes take effect immediately, no further set call is needed.
    " Cast individual columns to CL_SALV_COLUMN_TABLE to access table-specific methods
    " (e.g. set_cell_type, set_color, set_icon) not available on the base class.
    ro_columns = CAST cl_salv_columns_table( mo_alv->get_columns( ) ).
  ENDMETHOD.

  METHOD set_all_functions.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Enable or disable all toolbar functions at once.
    " Pass abap_false to completely lock down the toolbar (e.g. display-only ALV).
    mo_alv->get_functions( )->set_all( iv_enabled ).
  ENDMETHOD.

  METHOD get_functions.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Return the CL_SALV_FUNCTIONS object so the caller can configure
    " individual toolbar functions independently of set_all_functions( ).
    " The returned reference points to the same object owned by mo_alv —
    " any changes take effect immediately, no further set call is needed.
    ro_functions = mo_alv->get_functions( ).
  ENDMETHOD.

  METHOD get_layout.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Return the CL_SALV_LAYOUT object for full layout control.
    " The returned reference points to the same object owned by mo_alv —
    " any changes take effect immediately, no further set call is needed.
    ro_layout = mo_alv->get_layout( ).
  ENDMETHOD.

  METHOD get_events.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Return the CL_SALV_EVENTS_TABLE object so the caller can register
    " event handlers with SET HANDLER. The returned reference points to
    " the same object owned by mo_alv — handlers registered on it are
    " active immediately.
    ro_events = mo_alv->get_event( ). "get_event( ) already returns cl_salv_events_table directly — no CAST needed
  ENDMETHOD.

  METHOD get_alv_table_components.
    " Use RTTI to introspect the structure of the ALV internal table
    " and return its list of field descriptors (name, type, length, etc.).
    DATA: lo_alv_t_descr TYPE REF TO cl_abap_tabledescr,  "Table description object
          lo_alv_s_descr TYPE REF TO cl_abap_structdescr. "Structure description object (line type)

    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.
    ASSIGN mr_table->* TO <lt_table>.

    lo_alv_t_descr ?= cl_abap_typedescr=>describe_by_data( <lt_table> ).
    lo_alv_s_descr ?= lo_alv_t_descr->get_table_line_type( ).
    et_alv = lo_alv_s_descr->components.
  ENDMETHOD.

  METHOD set_column_editable.
    " Guard: mo_alv must be initialized via build( ) before calling this method.
    IF mo_alv IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_ref_is_initial.
    ENDIF.

    " Navigate the extended grid API chain and configure editability for the column.
    " Raises cx_salv_not_found if iv_columnname does not exist in the ALV columns.
    mo_alv->extended_grid_api( )->editable_restricted( )->set_attributes_for_columnname(
        columnname              = iv_columnname
        all_cells_input_enabled = iv_enabled ).
  ENDMETHOD.

ENDCLASS.
