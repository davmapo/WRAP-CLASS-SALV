# LCL_BUILD_SALV — Classe Wrapper ABAP per SALV

Un wrapper leggero attorno a `CL_SALV_TABLE` che semplifica la configurazione delle ALV grid nei programmi ABAP.
Riduce il codice ripetitivo esponendo metodi puliti per le operazioni di configurazione più comuni,
mantenendo allo stesso tempo l'accesso completo agli oggetti SAP SALV sottostanti per i casi avanzati.

---

## Indice

- [Panoramica](#panoramica)
- [Installazione](#installazione)
- [Modalità di Visualizzazione](#modalità-di-visualizzazione)
- [Riferimento Metodi](#riferimento-metodi)
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
  - [get_alv_table_components](#get_alv_table_components)
- [Ordine di Chiamata Tipico](#ordine-di-chiamata-tipico)
- [Programma di Esempio Completo](#programma-di-esempio-completo)

---

## Panoramica

La classe risiede nell'Include `CL_BUILD_SALV` ed è definita come classe locale `lcl_build_salv`.
Mantiene un riferimento alla tabella interna e all'istanza di `CL_SALV_TABLE` (`mo_alv`),
e incapsula i passi di configurazione SALV più frequenti in metodi dedicati.

**Sono supportate due modalità di visualizzazione:**
- **Full-screen** — nessun container necessario, chiamare `build( )` senza fornire un nome container
- **Container incorporato** — fornire il nome di un elemento screen custom container nel costruttore

---

## Installazione

Copiare l'Include nel proprio programma e aggiungerlo al TOP Include o direttamente prima della logica principale.
La classe viene istanziata passando un riferimento alla tabella interna da visualizzare.

```abap
DATA: lt_data TYPE TABLE OF my_structure.
DATA: lo_salv TYPE REF TO lcl_build_salv.

" Riempire lt_data qui...

lo_salv = NEW lcl_build_salv( ir_table = REF #( lt_data ) ).
lo_salv->build( ).
lo_salv->display( ).
```

---

## Modalità di Visualizzazione

### Modalità full-screen
```abap
lo_salv = NEW lcl_build_salv( ir_table = REF #( lt_data ) ).
```

### Modalità container incorporato
```abap
lo_salv = NEW lcl_build_salv(
    ir_table          = REF #( lt_data )
    iv_container_name = 'MY_CONTAINER' ).  " Nome del custom control in Screen Painter
```

> **Nota:** Alcuni metodi (`set_screen_status`) sono disponibili solo in modalità full-screen.
> Chiamarli in modalità container solleva `cx_sy_ref_is_initial`.

---

## Riferimento Metodi

---

### `constructor`

Inizializza il wrapper. Deve essere chiamato per primo.

| Parametro | Tipo | Obbligatorio | Descrizione |
|-----------|------|--------------|-------------|
| `ir_table` | `REF TO data` | Sì | Riferimento alla tabella interna da visualizzare |
| `iv_container_name` | `string` | No | Nome dell'elemento screen custom container. Omettere per la modalità full-screen |

**Solleva:** `cx_sy_ref_is_initial` se `ir_table` non è legato.

---

### `build`

Crea l'istanza di `CL_SALV_TABLE`. Usa automaticamente la modalità container o full-screen
in base al fatto che `iv_container_name` sia stato fornito nel costruttore.

Deve essere chiamato prima di qualsiasi altro metodo che accede all'oggetto ALV.

**Solleva:** `cx_sy_ref_is_initial`, `cx_salv_msg`, `cx_root`

---

### `display`

Visualizza la ALV sullo schermo. Deve essere chiamato dopo `build( )`.

**Solleva:** `cx_sy_ref_is_initial` se `build( )` non è stato chiamato prima.

---

### `refresh`

Aggiorna la visualizzazione ALV per riflettere le modifiche apportate alla tabella interna sottostante.
Deve essere chiamato dopo `build( )`.

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `iv_refresh_mode` | `salv_de_refresh` | `if_salv_c_refresh=>full` | Profondità del refresh. Valori: `none` (0), `soft` (1 — solo celle visibili), `full` (2 — ridisegno completo) |
| `is_stable` | `lvc_s_stbl` | — (opzionale) | Impostare `row`/`col` = `abap_true` per preservare la posizione di scroll dopo il refresh |

```abap
" Full refresh, posizione di scroll preservata
lo_salv->refresh(
    is_stable = VALUE #( row = abap_true col = abap_true ) ).

" Soft refresh (più veloce), posizione di scroll preservata
lo_salv->refresh(
    iv_refresh_mode = if_salv_c_refresh=>soft
    is_stable       = VALUE #( row = abap_true col = abap_true ) ).
```

**Solleva:** `cx_sy_ref_is_initial` se `build( )` non è stato chiamato prima.

---

### `set_screen_status`

> **Solo modalità full-screen.** Solleva `cx_sy_ref_is_initial` se chiamato in modalità container.

Imposta il PF-STATUS e l'insieme delle funzioni toolbar abilitate.

Per creare un PF-STATUS personalizzato: `SE41` → copiare il programma `SAPLSALV_METADATA_STATUS`, status `SALV_TABLE_STANDARD`.

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `iv_pfstatus` | `LIKE sy-pfkey` | — (obbligatorio) | Nome del PF-STATUS da attivare |
| `iv_set_functions` | `salv_de_function` | `cl_salv_table=>c_functions_all` (default se omesso) | Funzioni toolbar da abilitare. Valori possibili: `cl_salv_table=>c_functions_all`, `c_functions_default`, `c_functions_none`. Nota: `c_functions_default` (spazio) non è distinguibile da "non fornito" — passarlo esplicitamente se necessario |

**Solleva:** `cx_sy_ref_is_initial`

---

### `set_selection_mode`

Imposta il comportamento di selezione delle righe della ALV grid.

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `iv_selection_mode` | `salv_de_selection_mode` | `if_salv_c_selection_mode=>single` | Modalità di selezione. Valori possibili: `none`, `single`, `multiple`, `cell`, `row_column` |

**Solleva:** `cx_sy_ref_is_initial`

---

### `set_layout_settings`

Configura il salvataggio delle varianti di layout. La chiave layout (`sy-repid`) viene sempre impostata automaticamente.

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `iv_default` | `abap_bool` | `abap_true` | Contrassegna il layout come predefinito |
| `iv_save_restriction` | `LIKE if_salv_c_layout=>restrict_none` | `if_salv_c_layout=>restrict_none` (default se omesso) | Chi può salvare i layout. Valori: `restrict_none`, `restrict_user_dependant`, `restrict_layout_only` |

> Per impostare un layout iniziale, usare `get_layout( )->set_initial_layout( )` dopo aver chiamato `set_layout_settings( )`.

**Solleva:** `cx_sy_ref_is_initial`

---

### `set_display_settings`

Configura il titolo della ALV, le righe alternate e l'adattamento della larghezza delle colonne.

> **Nota:** Non usare `iv_fit_column = abap_true` insieme a `set_optimize_columns( )` — sono in conflitto. Usare uno o l'altro.

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `iv_title` | `lvc_title` | — (opzionale) | Titolo visualizzato sopra la ALV (max 70 caratteri, solo modalità full-screen) |
| `iv_striped` | `abap_bool` | `abap_true` | Abilita la colorazione alternata delle righe |
| `iv_fit_column` | `abap_bool` | `abap_true` | Adatta automaticamente la larghezza delle colonne alla dimensione della tabella |

**Solleva:** `cx_sy_ref_is_initial`

---

### `set_all_functions`

Abilita o disabilita tutte le funzioni della toolbar in una sola chiamata.
Per un controllo granulare sulle singole funzioni, usare invece `get_functions( )`.

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `iv_enabled` | `abap_bool` | `abap_true` | `abap_true` = abilita tutto, `abap_false` = disabilita tutto |

**Solleva:** `cx_sy_ref_is_initial`

---

### `get_layout`

Restituisce l'oggetto `CL_SALV_LAYOUT` sottostante per il controllo completo del layout.
Usarlo per le impostazioni non coperte da `set_layout_settings( )`, come il caricamento di una variante specifica all'avvio.
Le modifiche hanno effetto immediato.

**Restituisce:** `REF TO cl_salv_layout`

**Solleva:** `cx_sy_ref_is_initial`

```abap
lo_salv->set_layout_settings( ).
lo_salv->get_layout( )->set_initial_layout( '/MY_VARIANT' ).
```

---

### `get_functions`

Restituisce l'oggetto `CL_SALV_FUNCTIONS` sottostante per il controllo granulare della toolbar.
Le modifiche hanno effetto immediato — non è necessaria nessuna chiamata aggiuntiva.

**Restituisce:** `REF TO cl_salv_functions`

**Solleva:** `cx_sy_ref_is_initial`

```abap
lo_salv->get_functions( )->set_sort_asc( abap_false ).
lo_salv->get_functions( )->set_export( abap_true ).
```

---

### `set_optimize_columns`

Ottimizza la larghezza di tutte le colonne in una sola chiamata.

> **Nota:** Non combinare con `iv_fit_column = abap_true` in `set_display_settings( )`. Usare uno o l'altro.
> Per l'ottimizzazione per singola colonna, usare `get_columns( )` e chiamare `set_optimized( )` sulle singole colonne.

| Parametro | Tipo | Default | Descrizione |
|-----------|------|---------|-------------|
| `iv_optimize` | `abap_bool` | `abap_true` | `abap_true` = ottimizza tutte le colonne |

**Solleva:** `cx_sy_ref_is_initial`

---

### `get_columns`

Restituisce l'oggetto `CL_SALV_COLUMNS_TABLE` sottostante per il controllo completo per-colonna.
Le modifiche hanno effetto immediato.

Per accedere ai metodi specifici della tabella (colore, tipo cella, icona, ecc.), fare il cast della singola colonna
a `CL_SALV_COLUMN_TABLE`.

**Restituisce:** `REF TO cl_salv_columns_table`

**Solleva:** `cx_sy_ref_is_initial`

```abap
" Configurare una singola colonna
DATA(lo_columns) = lo_salv->get_columns( ).
DATA(lo_col)     = CAST cl_salv_column_table( lo_columns->get_column( 'FIELDNAME' ) ).
lo_col->set_visible( abap_false ).
lo_col->set_long_text( |La mia etichetta| ).

" Abilitare una colonna checkbox
" NOTA: il campo deve già esistere nel tipo della tabella interna come TYPE c LENGTH 1 (o abap_bool).
" Esempio tipo: TYPES: BEGIN OF ty_riga, ... checkbox TYPE c LENGTH 1, ... END OF ty_riga.
DATA(lo_chk) = CAST cl_salv_column_table( lo_columns->get_column( 'CHECKBOX' ) ).
lo_chk->set_cell_type( if_salv_c_cell_type=>checkbox_hotspot ).
```

---

### `get_events`

Restituisce l'oggetto `CL_SALV_EVENTS_TABLE` per registrare gli handler degli eventi tramite `SET HANDLER`.
Gli handler registrati sull'oggetto restituito sono attivi immediatamente.

**Restituisce:** `REF TO cl_salv_events_table`

**Solleva:** `cx_sy_ref_is_initial`

```abap
SET HANDLER lo_handler->on_double_click FOR lo_salv->get_events( ).
SET HANDLER lo_handler->on_link_click   FOR lo_salv->get_events( ).
```

**Eventi comuni:** `double_click`, `link_click`, `before_salv_function`, `after_salv_function`, `added_function`, `top_of_page`

---

### `get_alv_table_components`

Restituisce la lista dei campi (componenti) della tabella interna ALV tramite introspezione RTTI.
Utile per ciclare su tutte le colonne dinamicamente senza hardcodare i nomi dei campi.

Può essere chiamato in qualsiasi momento dopo il costruttore — non richiede `build( )`.

**Restituisce:** `abap_compdescr_tab` — tabella di descrittori di campo (nome, tipo, lunghezza, ecc.)

```abap
DATA(lo_columns) = lo_salv->get_columns( ).
LOOP AT lo_salv->get_alv_table_components( ) ASSIGNING FIELD-SYMBOL(<fs_field>).
    DATA(lo_col) = CAST cl_salv_column_table( lo_columns->get_column( <fs_field>-name ) ).
    lo_col->set_optimized( abap_true ).
ENDLOOP.
```

---

## Ordine di Chiamata Tipico

```abap
" 1. Istanziare
lo_salv = NEW lcl_build_salv( ir_table = REF #( lt_data ) ).

" 2. Build (obbligatorio prima di tutto il resto)
lo_salv->build( ).

" 3. Configurare (qualsiasi ordine, tutti opzionali)
lo_salv->set_screen_status( iv_pfstatus = 'ZMY_STATUS' ).
lo_salv->set_selection_mode( if_salv_c_selection_mode=>multiple ).
lo_salv->set_layout_settings( ).
lo_salv->set_display_settings( iv_title = 'Il mio report' ).
lo_salv->set_all_functions( ).
lo_salv->set_optimize_columns( ).

" 4. Registrare gli handler degli eventi (opzionale)
SET HANDLER lo_handler->on_double_click FOR lo_salv->get_events( ).

" 5. Visualizzare
lo_salv->display( ).
```

---

## Programma di Esempio Completo

Il seguente esempio dimostra tutte le funzionalità della classe in un singolo report ABAP full-screen.

```abap
*&---------------------------------------------------------------------*
*& Report  Z_EXAMPLE_SALV_WRAPPER
*&---------------------------------------------------------------------*
REPORT z_example_salv_wrapper.

" Include della classe wrapper
INCLUDE cl_build_salv.

*----------------------------------------------------------------------*
* Tipi di dato
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_employee,
    emp_id    TYPE n LENGTH 6,
    name      TYPE char40,
    dept      TYPE char20,
    salary    TYPE p DECIMALS 2,
    active    TYPE abap_bool,
END OF ty_employee.

*----------------------------------------------------------------------*
* Dati globali
*----------------------------------------------------------------------*
DATA: gt_employees TYPE TABLE OF ty_employee,
      go_salv      TYPE REF TO lcl_build_salv.

*----------------------------------------------------------------------*
* Classe handler degli eventi
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
    MESSAGE |Doppio click: riga { row }, colonna { column }| TYPE 'I'.
  ENDMETHOD.

  METHOD on_before_function.
    " Intercettare le azioni della toolbar se necessario
    CASE e_salv_function.
      WHEN 'ZDELETE'.
        " Logica personalizzata prima dell'eliminazione
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Initialization — caricamento dati demo
*----------------------------------------------------------------------*
INITIALIZATION.
  gt_employees = VALUE #(
      ( emp_id = '000001' name = 'Mario Rossi'    dept = 'IT'      salary = '3500.00' active = abap_true  )
      ( emp_id = '000002' name = 'Laura Bianchi'  dept = 'Finance' salary = '4200.00' active = abap_true  )
      ( emp_id = '000003' name = 'Carlo Verdi'    dept = 'HR'      salary = '2900.00' active = abap_false )
      ( emp_id = '000004' name = 'Anna Neri'      dept = 'IT'      salary = '3800.00' active = abap_true  ) ).

*----------------------------------------------------------------------*
* Start of selection — costruzione e visualizzazione della ALV
*----------------------------------------------------------------------*
START-OF-SELECTION.

  TRY.

      "--- 1. Istanziare il wrapper (modalità full-screen, nessun container) ---
      go_salv = NEW lcl_build_salv( ir_table = REF #( gt_employees ) ).

      "--- 2. Costruire l'oggetto ALV ---
      go_salv->build( ).

      "--- 3. PF-STATUS (solo full-screen) ---
      " Richiede un GUI status personalizzato 'ZEMP_STATUS' in questo programma.
      " Copiare da SE41: programma SAPLSALV_METADATA_STATUS, status SALV_TABLE_STANDARD.
      go_salv->set_screen_status(
          iv_pfstatus      = 'ZEMP_STATUS'
          iv_set_functions = cl_salv_table=>c_functions_all ).

      "--- 4. Modalità di selezione ---
      go_salv->set_selection_mode( if_salv_c_selection_mode=>multiple ).

      "--- 5. Impostazioni layout ---
      go_salv->set_layout_settings(
          iv_default          = abap_true
          iv_save_restriction = if_salv_c_layout=>restrict_user_dependant ).

      "--- 6. Impostazioni di visualizzazione ---
      go_salv->set_display_settings(
          iv_title      = 'Lista Dipendenti'
          iv_striped    = abap_true
          iv_fit_column = abap_true ).

      "--- 7. Funzioni toolbar ---
      go_salv->set_all_functions( abap_true ).
      " Per controllo granulare usa get_functions( ) — i metodi disponibili dipendono
      " dalla release SAP (es. set_sort_asc, set_find, set_layout, set_graphics).
      " Verificare in SE24 -> CL_SALV_FUNCTIONS per l'elenco esatto dei metodi.

      "--- 8. Configurazione colonne ---
      DATA(lo_columns) = go_salv->get_columns( ).

      LOOP AT go_salv->get_alv_table_components( ) ASSIGNING FIELD-SYMBOL(<fs_field>).
        TRY.
            DATA(lo_col) = CAST cl_salv_column_table(
                lo_columns->get_column( <fs_field>-name ) ).

            CASE <fs_field>-name.
              WHEN 'EMP_ID'.
                lo_col->set_visible( abap_false ).          " Nasconde la colonna
              WHEN 'DEPT'.
                lo_col->set_short_text( 'Rep.' ).           " Rinomina le etichette
                lo_col->set_medium_text( 'Reparto' ).
                lo_col->set_long_text( 'Reparto' ).
              WHEN 'SALARY'.
                lo_col->set_color( VALUE lvc_s_colo( col = '5' int = '1' inv = '0' ) ). " Verde
            ENDCASE.

            lo_col->set_optimized( abap_true ).             " Ottimizza larghezza per ogni colonna

          CATCH cx_salv_not_found.
        ENDTRY.
      ENDLOOP.

      "--- 9. Registrare gli handler degli eventi ---
      SET HANDLER lcl_handler=>on_double_click   FOR go_salv->get_events( ).
      SET HANDLER lcl_handler=>on_before_function FOR go_salv->get_events( ).

      "--- 10. Visualizzare ---
      go_salv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'E'.
    CATCH cx_sy_ref_is_initial INTO DATA(lx_ref).
      MESSAGE 'Oggetto ALV non inizializzato.' TYPE 'E'.
    CATCH cx_root INTO DATA(lx_root).
      MESSAGE lx_root->get_text( ) TYPE 'E'.
  ENDTRY.
```

> **Variante container incorporato:** per incorporare la ALV in uno screen, passare `iv_container_name` nel
> costruttore e chiamare `build( )` e i metodi di configurazione nel modulo `PBO` dello screen.
> **Non** chiamare `set_screen_status( )` in modalità container.

```abap
" Nel modulo PBO:
go_salv = NEW lcl_build_salv(
    ir_table          = REF #( gt_employees )
    iv_container_name = 'MY_CONTAINER' ).
go_salv->build( ).
go_salv->set_display_settings( iv_title = 'Dipendenti' ).
go_salv->set_all_functions( ).
go_salv->display( ).

" Dopo una modifica ai dati:
go_salv->refresh(
    is_stable = VALUE #( row = abap_true col = abap_true ) ).
```
