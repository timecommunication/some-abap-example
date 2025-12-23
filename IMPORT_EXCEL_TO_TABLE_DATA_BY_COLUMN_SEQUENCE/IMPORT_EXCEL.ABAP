
********* EXCEL 读取变量 ********* START *********

    DATA: lv_filecontent   TYPE xstring,
          lv_sheets        TYPE i,
          lv_sheet_no      TYPE i ,
          lv_woksheet_name TYPE string,
          lo_excel_ref     TYPE REF TO cl_fdt_xl_spreadsheet.
    DATA: lo_xlsx_handler TYPE REF TO cl_ehfnd_xlsx,
          lv_error_text   TYPE string,
          lo_xlsx_doc     TYPE REF TO if_ehfnd_xlsx_doc,
          lt_sheet_info   TYPE cl_ehfnd_xlsx=>gty_th_sheet_info,
          lo_sheet        TYPE REF TO if_ehfnd_xlsx_sheet.
    "get the content of excel.
    TYPES: BEGIN OF ly_column,
             column TYPE i,
             name   TYPE string,
           END OF ly_column.

    DATA: lt_columns TYPE STANDARD TABLE OF ly_column WITH EMPTY KEY,
          lo_tab_ref TYPE REF TO data,
          lo_struct  TYPE REF TO cl_abap_structdescr.

    DATA:lv_start_row  TYPE i,
         lv_start_col  TYPE i,
         lv_end_row    TYPE i,
         lv_end_col    TYPE i,
         lv_row_id     TYPE i,
         lv_col_id     TYPE i,
         lv_col_table  TYPE i,
         lv_cell_value TYPE string.


    FIELD-SYMBOLS: <fs_table> TYPE any,
                   <fs_value> TYPE any.

    TYPES:BEGIN OF ty_file,
             Z1 TYPE CHAR1 ,
             ZNAME TYPE CHAR20 ,
             ZAGE TYPE I ,
          END OF ty_file.
    DATA: LT_FILE TYPE TABLE OF TY_FILE.
    DATA LS_FILE TYPE TY_FILE .

********* EXCEL 读取变量 ********* END *********

***************** 文件上传相关变量 *********************
  DATA lv_filename   TYPE string .
  DATA lv_filelength TYPE i .
  DATA lv_xstring    TYPE xstring .
  DATA lt_records    TYPE solix_tab .

  DATA: lv_init_directory TYPE string,
        lv_title          TYPE string,
        lv_extension      TYPE string,
*        lv_filename       TYPE string,
        lv_filter         TYPE string,
        lv_encoding       TYPE abap_bool,
        lv_multiselection TYPE abap_bool.
  DATA: cv_file_table    TYPE filetable,
        cv_rc            TYPE i,
        cv_user_action   TYPE i,
        cv_file_encoding TYPE abap_encoding.



PARAMETERS: p_file   LIKE rlgrap-filename MODIF ID M  .


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  lv_title     = '选择文件'.
  lv_extension   = '.xlsx'.
  lv_filter    = cl_gui_frontend_services=>filetype_excel.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title            = lv_title
      default_extension       = lv_extension
      default_filename        = lv_filename
      file_filter             = lv_filter
      with_encoding           = lv_encoding
      initial_directory       = lv_init_directory
      multiselection          = lv_multiselection

    CHANGING
      file_table              = cv_file_table
      rc                      = cv_rc
      user_action             = cv_user_action
      file_encoding           = cv_file_encoding
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
  ).
  IF sy-subrc = 0 AND cv_rc = 1.
    READ TABLE cv_file_table INTO P_FILE INDEX 1 .
  ENDIF.



LV_FILENAME = P_FILE.

CALL FUNCTION 'GUI_UPLOAD'
  EXPORTING
    filename                = lv_filename
    filetype                = 'BIN'
  IMPORTING
    filelength              = lv_filelength
    header                  = lv_xstring
  TABLES
    data_tab                = lt_records
  EXCEPTIONS
    file_open_error         = 1
    file_read_error         = 2
    no_batch                = 3
    gui_refuse_filetransfer = 4
    invalid_type            = 5
    no_authority            = 6
    unknown_error           = 7
    bad_data_format         = 8
    header_not_allowed      = 9
    separator_not_allowed   = 10
    header_too_long         = 11
    unknown_dp_error        = 12
    access_denied           = 13
    dp_out_of_memory        = 14
    disk_full               = 15
    dp_timeout              = 16
    OTHERS                  = 17.

" 转换二进制数据 到 XSTRING 类型
CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
  EXPORTING
    input_length = lv_filelength
  IMPORTING
    buffer       = lv_xstring
  TABLES
    binary_tab   = lt_records
  EXCEPTIONS
    failed       = 1
    OTHERS       = 2.




PERFORM READ_EXCEL_TO_LT_FILE .

cl_demo_output=>display( LT_FILE ).


FORM READ_EXCEL_TO_LT_FILE .

    TRY.
        lo_xlsx_handler = cl_ehfnd_xlsx=>get_instance( ).
        lo_xlsx_doc     = lo_xlsx_handler->load_doc( lv_xstring ).
        lt_sheet_info   = lo_xlsx_doc->get_sheets( ).
        lv_sheets = lines( lt_sheet_info ).
*        WHILE lv_sheet_no <= lv_sheets.
*          lv_sheet_no = lv_sheet_no + 1.
        LV_SHEET_NO = 0 .
        WHILE lv_sheet_no <= 1 .
          lv_sheet_no = lv_sheet_no + 1.
          IF lv_sheet_no > 1.
            EXIT.
          ENDIF.
          lv_woksheet_name = lt_sheet_info[ lv_sheet_no ]-name.
          lo_sheet  = lo_xlsx_doc->get_sheet_by_id( lt_sheet_info[ lv_sheet_no ]-sheet_id ).
          CHECK NOT  lo_sheet  IS INITIAL.
          "解析excel
          lv_end_row  =  lo_sheet->get_last_row_number( ).
          lv_end_col  =  lo_sheet->get_last_column_number_in_row( 1 ).
          lv_start_row = 2 .
          lv_start_col = 1 .
          "按照顺序获取数据
          CLEAR lv_col_id.
          lv_row_id = lv_start_row.
          WHILE lv_row_id <= lv_end_row.
            lv_col_id = lv_start_col.
            lv_col_table = 1.

            APPEND INITIAL LINE TO lt_file ASSIGNING <fs_table>.

            DO lv_end_col TIMES.
              lv_cell_value = lo_sheet->get_cell_content(
                EXPORTING
                  iv_row    = lv_row_id
                  iv_column = lv_col_id ).

              ASSIGN COMPONENT lv_col_id OF STRUCTURE <fs_table> TO <fs_value>.
              lv_col_table = lv_col_table + 1.
              lv_col_id = lv_col_id + 1.
              <fs_value> = lv_cell_value.
            ENDDO.
            CLEAR :lv_col_id.
            UNASSIGN <fs_table>.
            lv_row_id = lv_row_id + 1.
          ENDWHILE.

        ENDWHILE.
      CATCH cx_openxml_format INTO DATA(lo_openxml_format).
        lv_error_text = lo_openxml_format->get_text( ).
      CATCH cx_openxml_not_found INTO DATA(lo_openxml_not_found).
        lv_error_text = lo_openxml_not_found->get_text( ).
      CATCH cx_openxml_not_allowed INTO DATA(lo_openxml_not_allowed).
        lv_error_text = lo_openxml_not_allowed->get_text( ).
      CATCH cx_dynamic_check INTO DATA(lo_dynamic_check).
        lv_error_text = lo_dynamic_check->get_text( ).
    ENDTRY.
ENDFORM .