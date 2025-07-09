*&---------------------------------------------------------------------*
*& Report Z0618_PERSON_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0618_PERSON_H10009.

TYPES: BEGIN OF TY_PERSON,
  ZUSERID TYPE ZE_ZUSERID,
  ZNAME TYPE ZE_ZNAME,
  ZGENDER TYPE ZE_ZGENDER,
  END OF TY_PERSON.

DATA: GT_PERSON TYPE TABLE OF TY_PERSON,
      GS_PERSON TYPE TY_PERSON.


DATA GS_MODIFY_PERSON TYPE ZTPERSON_H10009.

DATA : lv_filename   TYPE string,
           lt_records    TYPE solix_tab,
           lv_xstring    TYPE xstring,
           lv_filelength TYPE i.


PARAMETERS: p_file   LIKE rlgrap-filename.

TABLES: sscrfields.
" 在选择屏幕中 添加一个按钮 功能码为：FC01
SELECTION-SCREEN: FUNCTION KEY 1.

INITIALIZATION.
" 设置按钮的图标 和 名称
  sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id = '@49@' quickinfo = '借阅人模板下载' icon_text = '借阅人模板下载' ).

AT SELECTION-SCREEN.
  IF sy-ucomm = 'FC01'.
    DATA:lv_rc       TYPE i,
         lv_filename TYPE string,
         lv_path     TYPE string,
         lv_fullpath TYPE string,
         lv_objdata  TYPE wwwdatatab.

    lv_filename = |借阅人批导入模板-H10009|.
    cl_gui_frontend_services=>file_save_dialog(
     EXPORTING
     window_title           = '保存批导入模板'
      default_extension     =  'XLSX'    	"默认保存文件格式
      default_file_name     = lv_filename   "默认文件名称
     CHANGING
      filename              = lv_filename   "默认文件名称
      path                  = lv_path       "文件路径
      fullpath              = lv_fullpath   "文件路径
     EXCEPTIONS
      cntl_error            =  1
      error_no_gui          =  2
      not_supported_by_gui  =  3
      OTHERS                =  4 ).
    CHECK lv_fullpath IS NOT INITIAL.
    FREE:lv_objdata,lv_rc.
    SELECT SINGLE relid objid INTO CORRESPONDING FIELDS OF lv_objdata
    " 模板通过 SMW0 中提前上传好 二进制数据，OBJID 为 Z0618_H10009
    FROM wwwdata  WHERE srtf2 = 0 AND relid = 'MI' AND objid = 'Z0618_H10009'.
    IF sy-subrc EQ 0.
      TRANSLATE lv_fullpath TO UPPER CASE.
      REPLACE 'XLS' WITH 'XLSX' INTO lv_fullpath.

      CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
        EXPORTING
          key         = lv_objdata
          destination = CONV localfile( lv_fullpath )     " 'C:\Temp\test************.xls' .
        IMPORTING
          rc          = lv_rc.

      IF lv_rc = 0.
        MESSAGE '模板下载成功' TYPE if_mmpur_constants_general=>msg_success.
      ELSE.
        MESSAGE '模板下载失败' TYPE if_mmpur_constants_general=>msg_success DISPLAY LIKE if_mmpur_constants_general=>msg_error.
      ENDIF.
    ELSE.
    ENDIF.
  ENDIF.



**********************************************************************
" 文件路径选择框 点击搜索帮助时候 弹出文件选择对话框
" 选择文件后 文件路径 赋值给 P_FILE
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
*    PERFORM frm_select_file CHANGING  p_file.


  DATA:
        lv_init_directory TYPE string,
        lv_title          TYPE string,
        lv_extension      TYPE string,
        lv_filename       TYPE string,
        lv_filter         TYPE string,
        lv_encoding       TYPE abap_bool,
        lv_multiselection TYPE abap_bool.
  DATA: cv_file_table    TYPE filetable,
        cv_rc            TYPE i,
        cv_user_action   TYPE i,
        cv_file_encoding TYPE abap_encoding.


  lv_title     = '选择文件'."TEXT-001.
  lv_extension   = '.xlsx'."TEXT-003.


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



START-OF-SELECTION.


*    lv_filename = 'C:\Users\A\Desktop\借阅人数据导入模板-H10009.xlsx'.
     LV_FILENAME = P_FILE.
    " 上传文件到 SAP 中  
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

" 准备 读取 EXCEL 文件内容 
    DATA :
*          lv_filename      TYPE string,
        lv_filecontent   TYPE xstring,
        lv_sheets        TYPE i,
        lv_sheet_no      TYPE i,
        lv_woksheet_name TYPE string,
        lo_excel_ref     TYPE REF TO cl_fdt_xl_spreadsheet.

*    lv_filename    = is_file-file_name.
*    lv_filecontent = is_file-file_content.


DATA: lo_xlsx_handler TYPE REF TO cl_ehfnd_xlsx,
      lv_error_text   TYPE string,
      lo_xlsx_doc     TYPE REF TO if_ehfnd_xlsx_doc,
      lt_sheet_info   TYPE cl_ehfnd_xlsx=>gty_th_sheet_info,
      lo_sheet        TYPE REF TO if_ehfnd_xlsx_sheet.

      TRY.
          lo_xlsx_handler = cl_ehfnd_xlsx=>get_instance( ).
          lo_xlsx_doc     = lo_xlsx_handler->load_doc(
*            lv_filecontent
            LV_XSTRING
            ).
          lt_sheet_info   = lo_xlsx_doc->get_sheets( ).
          lv_sheets = lines( lt_sheet_info ).
          WHILE lv_sheet_no <= lv_sheets.
            lv_sheet_no = lv_sheet_no + 1.

            " 只读取EXCEL 中 的 SHEET1
            IF lv_sheet_no > 1.
              EXIT.
            ENDIF.

            lv_woksheet_name = lt_sheet_info[ lv_sheet_no ]-name.
            lo_sheet  = lo_xlsx_doc->get_sheet_by_id( lt_sheet_info[ lv_sheet_no ]-sheet_id ).
            CHECK NOT  lo_sheet  IS INITIAL.

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

            lv_end_row  =  lo_sheet->get_last_row_number( ).
            lv_end_col  =  lo_sheet->get_last_column_number_in_row( 1 ).
            
            " 从第4行 第2列 开始读取数据
            lv_start_row = 4.
            lv_start_col = 2.

*            CHECK iv_sheet_no = 1.
            "获取行结构字段
            " 这里 GT_PERSON 的字段 要和 EXCEL 中 第一行的 各个字段能对应
            CREATE DATA lo_tab_ref LIKE LINE OF GT_PERSON.
            lo_struct ?= cl_abap_typedescr=>describe_by_data_ref( lo_tab_ref ). "获取内表的 components
            DATA(lt_components) = lo_struct->get_components( ).
            lv_col_id = lv_start_col.
            DO lv_end_col TIMES.
              "获取第一行列字段名称
              lv_cell_value = lo_sheet->get_cell_content(  iv_row = 1
                                                          iv_column = lv_col_id ).
              IF line_exists( lt_components[ name = lv_cell_value ] ).
                APPEND INITIAL LINE TO lt_columns ASSIGNING FIELD-SYMBOL(<fs_column>).
                <fs_column>-column     = lv_col_id.
                <fs_column>-name       = lv_cell_value.
                DELETE lt_components WHERE name = lv_cell_value.
              ENDIF.
              lv_col_id = lv_col_id + 1.
            ENDDO.
            "按照字段对应获取数据
            CLEAR lv_row_id.
            lv_row_id    = lv_start_row.
            WHILE lv_row_id <= lv_end_row.
              APPEND INITIAL LINE TO GT_PERSON ASSIGNING <fs_table>.
              LOOP AT lt_columns REFERENCE INTO DATA(lo_columns).
                lv_cell_value = lo_sheet->get_cell_content( iv_row    = lv_row_id
                                                                 iv_column = lo_columns->*-column ).
                CHECK NOT lv_cell_value IS INITIAL.
                ASSIGN COMPONENT lo_columns->*-name OF STRUCTURE <fs_table> TO <fs_value>.
                <fs_value> = lv_cell_value.
              ENDLOOP.
              lv_row_id = lv_row_id + 1.
              UNASSIGN <fs_table>.
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

      IF lv_error_text IS NOT INITIAL.
*        APPEND VALUE #(  type = 'E' message = lv_error_text )  TO et_message.
        MESSAGE e001(00) RAISING file_open_error WITH lv_error_text.
      ENDIF.



" 展示刚才录入的数据
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
 EXPORTING
*   I_INTERFACE_CHECK                 = ' '
*   I_BYPASSING_BUFFER                = ' '
*   I_BUFFER_ACTIVE                   = ' '
   I_CALLBACK_PROGRAM                = SY-REPID
   I_CALLBACK_PF_STATUS_SET          = 'PF_STATUS_SET'
   I_CALLBACK_USER_COMMAND           = 'USER_COMMAND'
*   I_CALLBACK_TOP_OF_PAGE            = ' '
*   I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*   I_CALLBACK_HTML_END_OF_LIST       = ' '
   I_STRUCTURE_NAME                  = 'ZTPERSON_H10009'
*   I_BACKGROUND_ID                   = ' '
*   I_GRID_TITLE                      =
*   I_GRID_SETTINGS                   =
*   IS_LAYOUT                         =
*   IT_FIELDCAT                       =
*   IT_EXCLUDING                      =
*   IT_SPECIAL_GROUPS                 =
*   IT_SORT                           =
*   IT_FILTER                         =
*   IS_SEL_HIDE                       =
*   I_DEFAULT                         = 'X'
*   I_SAVE                            = ' '
*   IS_VARIANT                        =
*   IT_EVENTS                         =
*   IT_EVENT_EXIT                     =
*   IS_PRINT                          =
*   IS_REPREP_ID                      =
*   I_SCREEN_START_COLUMN             = 0
*   I_SCREEN_START_LINE               = 0
*   I_SCREEN_END_COLUMN               = 0
*   I_SCREEN_END_LINE                 = 0
*   I_HTML_HEIGHT_TOP                 = 0
*   I_HTML_HEIGHT_END                 = 0
*   IT_ALV_GRAPHICS                   =
*   IT_HYPERLINK                      =
*   IT_ADD_FIELDCAT                   =
*   IT_EXCEPT_QINFO                   =
*   IR_SALV_FULLSCREEN_ADAPTER        =
*   O_PREVIOUS_SRAL_HANDLER           =
*   O_COMMON_HUB                      =
* IMPORTING
*   E_EXIT_CAUSED_BY_CALLER           =
*   ES_EXIT_CAUSED_BY_USER            =
  TABLES
    T_OUTTAB                          = GT_PERSON
* EXCEPTIONS
*   PROGRAM_ERROR                     = 1
*   OTHERS                            = 2
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.

" 使用 EXCEL 中的数据，修改或添加对应的表数据
LOOP AT GT_PERSON INTO GS_PERSON.
  MOVE-CORRESPONDING GS_PERSON TO GS_MODIFY_PERSON.
  MODIFY ZTPERSON_H10009 FROM GS_MODIFY_PERSON.
ENDLOOP.


*******************





FORM PF_STATUS_SET USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'GUI_STATUS' .
ENDFORM.



FORM USER_COMMAND USING R_UCOMM LIKE SY-UCOMM
                        RS_SELFIELD TYPE SLIS_SELFIELD.
  CASE R_UCOMM.
    WHEN 'G_DOWNLOAD'.

      DATA: lv_selected_folder_SAVE TYPE string,
      lv_complete_path_SAVE   TYPE STRING.
*      lv_titulo          TYPE string.

      CALL METHOD cl_gui_frontend_services=>directory_browse
        EXPORTING
          window_title    = '选择保存路径'
          initial_folder  = 'C:\'
        CHANGING
          selected_folder = lv_selected_folder_SAVE
        EXCEPTIONS
          cntl_error      = 1
          error_no_gui    = 2
          OTHERS          = 3.
      CHECK NOT lv_selected_folder_SAVE IS INITIAL.

      CONCATENATE lv_selected_folder_SAVE '\使用GUI_DOWNOLAD下载.xls' INTO lv_complete_path_SAVE.

      DATA:BEGIN OF t_fieldnames  OCCURS 0,
             name TYPE char20,
           END OF t_fieldnames.

      t_fieldnames-name = '身份证'.
      APPEND t_fieldnames.

      t_fieldnames-name = '姓名'.
      APPEND t_fieldnames.

      t_fieldnames-name = '性别'.
      APPEND t_fieldnames.

      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
*         filename   = 'C:\Users\A\Desktop\使用GUI_DOWNOLAD下载.txt'
          filename   = lv_complete_path_SAVE
          filetype   = 'DAT'
          "这里一般用DAT，如果用ASC则1000-不会显示为-1000，而dat会显示为-1000，如果用DBF则不会有缩进，即字符前面的空格会被除去,而且字符的前导0也会输出。
          codepage   = '8404'
        TABLES
          data_tab   = GT_PERSON
          fieldnames = t_fieldnames.

    WHEN 'S_DOWNLOAD'.
      TYPE-POOLS: soi,ole2.
      DATA: lo_application TYPE  ole2_object,
            lo_workbook    TYPE  ole2_object,
            lo_workbooks   TYPE  ole2_object,
            lo_range       TYPE  ole2_object,
            lo_worksheet   TYPE  ole2_object,
            lo_worksheets  TYPE  ole2_object,
            lo_column      TYPE  ole2_object,
            lo_row         TYPE  ole2_object,
            lo_cell        TYPE  ole2_object,
            lo_font        TYPE ole2_object.



      DATA: lo_cellstart  TYPE ole2_object,
            lo_cellend    TYPE ole2_object,
            lo_selection  TYPE ole2_object,
            lo_validation TYPE ole2_object.

      DATA: lv_selected_folder TYPE string,
            lv_complete_path   TYPE char256,
            lv_titulo          TYPE string.

      CALL METHOD cl_gui_frontend_services=>directory_browse
        EXPORTING
          window_title    = lv_titulo
          initial_folder  = 'C:\'
        CHANGING
          selected_folder = lv_selected_folder
        EXCEPTIONS
          cntl_error      = 1
          error_no_gui    = 2
          OTHERS          = 3.
      CHECK NOT lv_selected_folder IS INITIAL.

      CREATE OBJECT lo_application 'Excel.Application'.
      CALL METHOD OF lo_application 'Workbooks' = lo_workbooks.
      CALL METHOD OF lo_workbooks 'Add' = lo_workbook.
      SET PROPERTY OF lo_application 'Visible' = 1.

      GET PROPERTY OF lo_application 'ACTIVESHEET' = lo_worksheet.


      DATA: lo_descr TYPE REF TO cl_abap_structdescr,
      lt_components TYPE abap_component_tab,
      lv_col_cnt TYPE i.

      lo_descr ?= cl_abap_typedescr=>describe_by_data( GT_PERSON[ 1 ] ).
      lt_components = lo_descr->get_components( ).
      lv_col_cnt = lines( lt_components ).

    " 设置 身份证  这一个字段在 EXCEL 中的显示长度为 20，否则会让身份证号按科学计数法显示
      CALL METHOD OF lo_application 'COLUMNS' = lo_column
        EXPORTING
          #1 = 1.  "the column number

      SET PROPERTY OF lo_column 'ColumnWidth' = 20.
      SET PROPERTY OF lo_column 'NumberFormat' = '@'.

      " 数据写入 EXCEL
      LOOP AT GT_PERSON INTO DATA(ls_data).
        DATA(lv_tabix) = sy-tabix + 1.

        DO LV_COL_CNT TIMES.
          DATA(lv_index) = sy-index.
          ASSIGN COMPONENT sy-index OF STRUCTURE ls_data TO FIELD-SYMBOL(<lv_value>).
          CALL METHOD OF lo_application 'Cells' = lo_cell
            EXPORTING #1 = lv_tabix
                      #2 = lv_index.

*        DATA(LV_FIELDTEXT2) = |'{ <lv_value> }|.

          SET PROPERTY OF lo_cell 'Value' = <lv_value>.
        ENDDO.
      ENDLOOP.

      lv_tabix = 1.
      lv_index = 1.

*      DEFINE macro_set_field.
*        CALL METHOD OF lo_application 'Cells' = lo_cell
*          EXPORTING #1 = lv_tabix
*                    #2 = lv_index.
*        SET PROPERTY OF lo_cell 'Value' = &1.
*        ADD 1 TO lv_index.
*      END-OF-DEFINITION.

      DATA:lt_table TYPE  ddfields.

      CALL FUNCTION 'CATSXT_GET_DDIC_FIELDINFO'
        EXPORTING
          im_structure_name = 'ZTPERSON_H10009'
        IMPORTING
          ex_ddic_info      = lt_table
        EXCEPTIONS
          failed            = 1
          OTHERS            = 2.

      DELETE  LT_TABLE WHERE FIELDNAME = 'MANDT'.

      LOOP AT lt_table INTO DATA(ls_table).
*        DATA(LV_FIELDTEXT) = |'{ ls_table-fieldtext }|.
        CALL METHOD OF lo_application 'Cells' = lo_cell
          EXPORTING #1 = lv_tabix
                    #2 = lv_index.
*        SET PROPERTY OF lo_cell 'ColumnWidth' = 30.
*        SET PROPERTY OF lo_cell 'NumberFormat' = '@'.
        SET PROPERTY OF lo_cell 'Value' =  ls_table-fieldtext .
        ADD 1 TO lv_index.

*        macro_set_field:ls_table-fieldtext.

      ENDLOOP.


      INSERT ls_data INTO GT_PERSON INDEX 1.

      CONCATENATE lv_selected_folder '\借阅人数据OLE下载' INTO lv_complete_path.

      CALL METHOD OF lo_workbook 'SaveAs'
        EXPORTING
          #1 = lv_complete_path.
      IF sy-subrc <> 0.
        MESSAGE '下载 EXCEL 文件失败' TYPE 'E'.
      ELSE.
        MESSAGE '下载 EXCEL 文件成功' TYPE 'S'.
      ENDIF.

      CALL METHOD OF lo_application 'QUIT'.
      FREE OBJECT lo_worksheet.
      FREE OBJECT lo_workbook.
      FREE OBJECT lo_application.

  ENDCASE.

ENDFORM.