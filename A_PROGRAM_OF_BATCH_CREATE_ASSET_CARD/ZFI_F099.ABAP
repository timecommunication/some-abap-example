*&---------------------------------------------------------------------*
*& Report ZFI_F099
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZFI_F099.

TABLES: ANLA, T001, sscrfields, ZTFICO099 .


SELECTION-SCREEN BEGIN OF BLOCK BK1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:  P_CREATE RADIOBUTTON GROUP GRP DEFAULT 'X' USER-COMMAND rdgrp  ,
               P_QUERY RADIOBUTTON GROUP GRP  .
SELECTION-SCREEN END OF BLOCK BK1.


SELECTION-SCREEN BEGIN OF BLOCK BK2 WITH FRAME TITLE TEXT-002. " 创建
  PARAMETERS: p_file   LIKE rlgrap-filename MODIF ID M  .
SELECTION-SCREEN END OF BLOCK BK2 .


SELECTION-SCREEN BEGIN OF BLOCK BK3 WITH FRAME TITLE TEXT-003 . " 查询

  SELECT-OPTIONS: Q_BUKRS FOR ANLA-BUKRS MODIF ID Q .

  SELECT-OPTIONS:
    Q_ANLN1 FOR ANLA-ANLN1 MODIF ID Q ,
    Q_ERNAM FOR ZTFICO099-ERNAM DEFAULT  SY-UNAME MODIF ID Q ,
    Q_ZCDATE FOR ZTFICO099-ZCDATE MODIF ID Q ,
    Q_ZCTIME FOR ZTFICO099-ZCTIME MODIF ID Q .
SELECTION-SCREEN END OF BLOCK BK3 .



SELECTION-SCREEN: FUNCTION KEY 1.

INITIALIZATION.
  sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id = '@49@' quickinfo = '模板下载' icon_text = '模板下载' ).


***************** 文件下载相关变量 *********************
  DATA : lv_filename   TYPE string,
         lt_records    TYPE solix_tab,
         lv_xstring    TYPE xstring,
         lv_filelength TYPE i.

  DATA:  lv_rc       TYPE i,
         lv_path     TYPE string,
         lv_fullpath TYPE string,
         lv_objdata  TYPE wwwdatatab.

***************** 文件上传相关变量 *********************
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

  DATA RT_BUKRS TYPE RANGE OF BUKRS.

********* BAPI 相关变量 ********* START *********

  DATA:
        LS_KEY                  LIKE  BAPI1022_KEY,         "要创建的关键字字段
        LS_REFERENCE            LIKE  BAPI1022_REFERENCE,   "创建的参考资产
        LV_CREATESUBNUMBER      LIKE  BAPI1022_MISC-XSUBNO, "检查框 - 创建子编号
        LV_POSTCAP              LIKE  BAPI1022_MISC-POSTCAP, "标记：dynpro的资产资本化期后

        LV_CREATEGROUPASSET     LIKE  BAPI1022_MISC-XANLGR, "标识:资产是集团公司资产
        LV_TESTRUN              LIKE  BAPI1022_MISC-TESTRUN, "切换到编写 BAPI 的模拟会话
        LS_GENERALDATA          LIKE  BAPI1022_FEGLG001,    "逻辑字段组 001 - 通用数据
        LS_GENERALDATAX         LIKE  BAPI1022_FEGLG001X,
        LS_INVENTORY            LIKE  BAPI1022_FEGLG011,
        LS_INVENTORYX           LIKE  BAPI1022_FEGLG011X,
        LS_POSTINGINFORMATION   LIKE  BAPI1022_FEGLG002,
        LS_POSTINGINFORMATIONX  LIKE  BAPI1022_FEGLG002X,
        LS_TIMEDEPENDENTDATA    LIKE  BAPI1022_FEGLG003,
        LS_TIMEDEPENDENTDATAX   LIKE  BAPI1022_FEGLG003X,
        LS_ALLOCATIONS          LIKE  BAPI1022_FEGLG004,
        LS_ALLOCATIONSX         LIKE  BAPI1022_FEGLG004X,
        LS_ORIGIN               LIKE  BAPI1022_FEGLG009,
        LS_ORIGINX              LIKE  BAPI1022_FEGLG009X,
        LS_INVESTACCTASSIGNMNT  LIKE  BAPI1022_FEGLG010,
        LS_INVESTACCTASSIGNMNTX LIKE  BAPI1022_FEGLG010X,
        LS_NETWORTHVALUATION    LIKE  BAPI1022_FEGLG006,
        LS_NETWORTHVALUATIONX   LIKE  BAPI1022_FEGLG006X,
        LS_REALESTATE           LIKE  BAPI1022_FEGLG007,
        LS_REALESTATEX          LIKE  BAPI1022_FEGLG007X,
        LS_INSURANCE            LIKE  BAPI1022_FEGLG008,
        LS_INSURANCEX           LIKE  BAPI1022_FEGLG008X,
        LS_LEASING              LIKE  BAPI1022_FEGLG005,
        LS_LEASINGX             LIKE  BAPI1022_FEGLG005X,
        LS_GLO_TIME_DEP         LIKE  BAPI1022_GLO_TIME_DEP.
  "BAPI导出参数
  DATA:LV_COMPANYCODE  LIKE  BAPI1022_1-COMP_CODE, "公司代码
       LV_ASSET        LIKE  BAPI1022_1-ASSETMAINO, "主资产号
       LV_SUBNUMBER    LIKE  BAPI1022_1-ASSETSUBNO, "资产次级编号
       LS_ASSETCREATED LIKE  BAPI1022_REFERENCE,   "创建的参考资产
       LS_RETURN       LIKE  BAPIRET2.             "返回参数
  "BAPI表参数
  DATA: LT_DEPRECIATIONAREAS  LIKE  STANDARD TABLE OF BAPI1022_DEP_AREAS,
        LT_DEPRECIATIONAREASX LIKE  STANDARD TABLE OF BAPI1022_DEP_AREASX,
        LT_INVESTMENT_SUPPORT LIKE  STANDARD TABLE OF BAPI1022_INV_SUPPORT,
        LT_EXTENSIONIN        LIKE  STANDARD TABLE OF BAPIPAREX.

  DATA: LS_DEPRECIATIONAREAS  LIKE  BAPI1022_DEP_AREAS,
        LS_DEPRECIATIONAREASX LIKE  BAPI1022_DEP_AREASX,
        LS_INVESTMENT_SUPPORT LIKE  BAPI1022_INV_SUPPORT,
        LS_EXTENSIONIN        LIKE  BAPIPAREX.

  DATA GV_MEINS_INNER_CODE TYPE ANLA-MEINS .
  DATA: LS_ANLU                TYPE BAPI_TE_ANLU ,
        lv_message TYPE string .
********* BAPI 相关变量 ********* END *********



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
            ZHOLDER  TYPE CHAR1,
            ZROWID TYPE ZE_ROWID ,
            BUKRS  TYPE ANLA-BUKRS,
            ANLKL TYPE ANLA-ANLKL ,
            TXT50   TYPE ANLA-TXT50,
            TXA50   TYPE ANLA-TXA50 ,
            ANLHTXT  TYPE ANLH-ANLHTXT,
            SERNR TYPE ANLA-SERNR,
            MENGE TYPE ZE_MENGE ,
            MEINS TYPE MEINS ,
            KOSTL  TYPE ANLZ-KOSTL,
            PS_PSP_PNR2   TYPE CHAR24,
            KOSTLV   TYPE ANLZ-KOSTLV,
            KFZKZ   TYPE ANLZ-KFZKZ,

            ORD41   TYPE ANLA-ORD41,
            ORD42   TYPE ANLA-ORD42,
            GDLGRP   TYPE ANLA-GDLGRP,

            AIBN1   TYPE ANLA-AIBN1,
            AFASL TYPE AFASL ,

            NDJAR TYPE ZE_NDJAR ,
            NDPER TYPE ZE_NDPER ,

            ZZPFWJH   TYPE ANLU-ZZPFWJH,
            ZZCJH   TYPE ANLU-ZZCJH,
            ZZCFWZ   TYPE ANLU-ZZCFWZ,
            ZZAQFBM   TYPE ANLU-ZZAQFBM,
          END OF ty_file.
    DATA: LT_FILE TYPE TABLE OF TY_FILE.
    DATA LS_FILE TYPE TY_FILE .

********* EXCEL 读取变量 ********* END *********


********* CREATE ALV 变量 ********* START *********
    TYPES:BEGIN OF TY_CREATE_ALV,
            ZUUID TYPE CHAR16 ,
            ZROWID TYPE ZE_ROWID ,
            BUKRS  TYPE ANLA-BUKRS,
            ANLKL TYPE ANLA-ANLKL ,
            ANLN1 TYPE ANLA-ANLN1 ,
            ZRESULT TYPE ZE_RESULT ,
            TXT50   TYPE ANLA-TXT50,
            TXA50   TYPE ANLA-TXA50 ,
            ANLHTXT  TYPE ANLH-ANLHTXT,
            SERNR TYPE ANLA-SERNR,
            MENGE TYPE ZE_MENGE ,
            MEINS TYPE MEINS ,
            KOSTL  TYPE ANLZ-KOSTL,
            PS_PSP_PNR2   TYPE CHAR24,
            KOSTLV   TYPE ANLZ-KOSTLV,
            KFZKZ   TYPE ANLZ-KFZKZ,

            ORD41   TYPE ANLA-ORD41,
            ORD42   TYPE ANLA-ORD42,
            GDLGRP   TYPE ANLA-GDLGRP,
            AIBN1   TYPE ANLA-AIBN1,

            AFASL TYPE AFASL ,
            NDJAR TYPE ZE_NDJAR ,
            NDPER TYPE ZE_NDPER ,

            ZZPFWJH   TYPE ANLU-ZZPFWJH,
            ZZCJH   TYPE ANLU-ZZCJH,
            ZZCFWZ   TYPE ANLU-ZZCFWZ,
            ZZAQFBM   TYPE ANLU-ZZAQFBM,

            ERNAM TYPE ERNAM ,
            ZCDATE TYPE DATUM ,
            ZCTIME TYPE TIME ,

            ZMSGTYPE TYPE BAPI_MTYPE,
            ZMSGCLS TYPE SYMSGID ,
            ZMSGNUMBER TYPE ZSYMSGNO ,
            ZMSGTEXT TYPE BAPI_MSG ,
            CELL_COLOR         TYPE LVC_T_SCOL,
          END OF TY_CREATE_ALV .

    DATA GT_TABLE TYPE TABLE OF TY_CREATE_ALV .
    DATA GS_TABLE_CHECK TYPE TY_CREATE_ALV .

    TYPES: BEGIN OF TY_ZROWID ,
      ZROWID TYPE ZE_ROWID ,
      END OF TY_ZROWID .
********* CREATE ALV 变量 ********* END *********


    DATA GS_CREATE_RECORD TYPE ZTFICO099 .


********* QUERY ALV 变量 ********* START *********
TYPES: BEGIN OF TY_QUERY_ALV ,
      ZUUID TYPE CHAR16 ,
      ZROWID TYPE ZE_ROWID,

      BUKRS  TYPE ANLA-BUKRS,
      BUTXT TYPE BUTXT ,
      ANLN1   TYPE ANLA-ANLN1,
      ZRESULT TYPE ZE_RESULT ,
      TXT50   TYPE ANLA-TXT50,
      TXA50   TYPE ANLA-TXA50 ,
      ANLHTXT  TYPE ANLH-ANLHTXT,
      SERNR TYPE ANLA-SERNR,
      MENGE   TYPE ANLA-MENGE,
      MEINS TYPE ANLA-MEINS ,

      KOSTL  TYPE ANLZ-KOSTL,
      LTEXT1 TYPE ZE_KLTXT1 ,
      PS_PSP_PNR2   TYPE CHAR24,
      POST1 TYPE ZE_PS_POST1 ,
      KOSTLV   TYPE ANLZ-KOSTLV,
      LTEXT2 TYPE ZE_KLTXT2 ,

      KFZKZ   TYPE ANLZ-KFZKZ,
      ORD41   TYPE ANLA-ORD41,
      ORDTX1  TYPE ZE_ORDTX1 ,
      ORD42   TYPE ANLA-ORD42,
      ORDTX2 TYPE ZE_ORDTX2 ,

      GDLGRP   TYPE ANLA-GDLGRP,
      GDLGRP_TXT TYPE ZE_GDLGRP_TXT ,

      AIBN1   TYPE ANLA-AIBN1,
      AFASL   TYPE AFASL ,
      NDJAR   TYPE ZE_NDJAR ,
      NDPER   TYPE ZE_NDPER ,
      ZZPFWJH   TYPE ANLU-ZZPFWJH,
      ZZCJH   TYPE ANLU-ZZCJH,
      ZZCFWZ   TYPE ANLU-ZZCFWZ,
      ZZAQFBM   TYPE ANLU-ZZAQFBM,
      ZAQFMS    TYPE ZTMM_AQF-ZAQFMS ,

      ERNAM TYPE ERNAM ,
      NAME_TEXTC1 TYPE ZE_NAME_TEXT ,
      ZCDATE TYPE ZE_DATUM ,
      ZCTIME TYPE ZDE_ZMTIME ,
      ZMSGTYPE TYPE BAPI_MTYPE,
      ZMSGCLS TYPE SYMSGID ,
      ZMSGNUMBER TYPE ZSYMSGNO ,
      ZMSGTEXT TYPE BAPI_MSG ,

      CELL_COLOR TYPE LVC_T_SCOL ,
      END OF TY_QUERY_ALV .

    DATA GT_QUERY_EXTEND  TYPE TABLE OF TY_QUERY_ALV .

********* QUERY ALV 变量 ********* END *********


*********  ALV 变量 ********* START *********

  DATA: LT_FIELDCAT TYPE lvc_t_fcat,
        LS_FIELDCAT TYPE lvc_s_fcat.

  DATA: LT_FIELDCAT_QUERY TYPE lvc_t_fcat,
        LS_FIELDCAT_QUERY TYPE lvc_s_fcat.

  DATA: LT_CELLCOLOR TYPE lvc_t_scol,
        LS_CELLCOLOR TYPE lvc_s_scol.

  DATA GV_COUNT TYPE I .
  DATA GT_listheader TYPE TABLE OF slis_listheader .
  DATA GS_listheader TYPE slis_listheader.

  DATA: LS_LAYOUT TYPE lvc_s_layo.
  LS_LAYOUT-ZEBRA = 'X'.
  LS_LAYOUT-CWIDTH_OPT = 'X'.
  LS_LAYOUT-CTAB_FNAME   = 'CELL_COLOR'.

  DATA: LS_VARIANT TYPE DISVARIANT .
  LS_VARIANT-REPORT = SY-REPID.

  DATA(GV_REPID) = SY-REPID.

  DATA: LT_EVENT TYPE slis_t_event,
        LS_EVENT TYPE slis_alv_event.

  DATA LS_SETTING TYPE LVC_S_GLAY.
  LS_SETTING-EDT_CLL_CB = 'X'.

  DATA LO_GRID TYPE REF TO CL_GUI_ALV_GRID.
  DATA LS_STABLE TYPE LVC_S_STBL.
  LS_STABLE-ROW = 'X'.
  LS_STABLE-COL = 'X'.

  DATA GV_TITLE TYPE LVC_TITLE .
*********  ALV 变量 ********* START *********





AT SELECTION-SCREEN.

  IF Q_BUKRS IS NOT INITIAL .
    SELECT BUKRS , BUTXT FROM T001 INTO TABLE @DATA(LT_BUKRS)
      WHERE BUKRS IN @Q_BUKRS .
     LOOP AT LT_BUKRS INTO DATA(LS_BUKRS).
       AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
        ID 'BUKRS' FIELD Q_BUKRS
        ID 'ACTVT' FIELD '03' .
      IF SY-SUBRC = 0 .
        APPEND VALUE #( sign = 'I' option = 'EQ' low = LS_BUKRS-BUKRS ) TO RT_BUKRS.
      ENDIF .
     ENDLOOP.

   ELSE.
     SELECT BUKRS , BUTXT FROM T001 INTO TABLE @LT_BUKRS .
     LOOP AT LT_BUKRS INTO LS_BUKRS.
       AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
        ID 'BUKRS' FIELD Q_BUKRS
        ID 'ACTVT' FIELD '03' .

     IF SY-SUBRC = 0 .
       APPEND VALUE #( sign = 'I' option = 'EQ' low = LS_BUKRS-BUKRS ) TO RT_BUKRS.
     ENDIF .
     ENDLOOP.

   ENDIF .


   IF sy-ucomm = 'FC01'.

    lv_filename = |资产卡片批量创建模板|.
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
    FROM wwwdata  WHERE srtf2 = 0 AND relid = 'MI' AND objid = 'ZFIR099'.
    IF sy-subrc EQ 0.
      TRANSLATE lv_fullpath TO UPPER CASE.
      DATA(LV_OFFSET) = strlen( LV_FULLPATH ) - 3 .
      IF LV_FULLPATH+LV_OFFSET(3) = 'XLS'.
        REPLACE 'XLS' WITH 'XLSX' INTO lv_fullpath.
      ENDIF.
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


AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    CASE SCREEN-GROUP1 .
      WHEN 'M'.
        IF P_CREATE IS NOT INITIAL .
          SCREEN-ACTIVE = 1.
        ELSE.
          SCREEN-ACTIVE = 0.
        ENDIF.
      WHEN 'Q'.
        IF P_CREATE IS NOT INITIAL .
          SCREEN-ACTIVE = 0.
        ELSE.
          SCREEN-ACTIVE = 1.
        ENDIF.
    ENDCASE .

    MODIFY SCREEN.
  ENDLOOP.






START-OF-SELECTION .

  IF P_CREATE IS NOT INITIAL .

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

    PERFORM DELETE_EMPTY_LINE .

    MOVE-CORRESPONDING  LT_FILE TO GT_TABLE .

    PERFORM DISPLAY_CREATE_ALV .

  ELSE .
    PERFORM DISPLAY_QUERY_ALV .
  ENDIF .





FORM READ_EXCEL_TO_LT_FILE .

    TRY.
        lo_xlsx_handler = cl_ehfnd_xlsx=>get_instance( ).
        lo_xlsx_doc     = lo_xlsx_handler->load_doc( lv_xstring ).
        lt_sheet_info   = lo_xlsx_doc->get_sheets( ).
        lv_sheets = lines( lt_sheet_info ).
*        WHILE lv_sheet_no <= lv_sheets.
*          lv_sheet_no = lv_sheet_no + 1.
        LV_SHEET_NO = 1 .
        WHILE lv_sheet_no <= 2 .
          lv_sheet_no = lv_sheet_no + 1.
          IF lv_sheet_no > 2.
            EXIT.
          ENDIF.
          lv_woksheet_name = lt_sheet_info[ lv_sheet_no ]-name.
          lo_sheet  = lo_xlsx_doc->get_sheet_by_id( lt_sheet_info[ lv_sheet_no ]-sheet_id ).
          CHECK NOT  lo_sheet  IS INITIAL.
          "解析excel
          lv_end_row  =  lo_sheet->get_last_row_number( ).
          lv_end_col  =  lo_sheet->get_last_column_number_in_row( 1 ).
          lv_start_row = 10.
          lv_start_col = 1.
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



FORM DELETE_EMPTY_LINE .
  DELETE LT_FILE WHERE ZROWID IS INITIAL  .
ENDFORM .


FORM SET_PF_STATUS USING RT_EXTAB TYPE SLIS_T_EXTAB.

  DATA RW_EXTAB LIKE LINE OF RT_EXTAB.
  IF GT_TABLE IS INITIAL OR P_CREATE IS INITIAL.
    CLEAR RT_EXTAB.
    RW_EXTAB-FCODE = 'CREATE'.
    APPEND RW_EXTAB TO RT_EXTAB.
    SET PF-STATUS 'GUI_STATUS' EXCLUDING RT_EXTAB.
  ELSE.
    SET PF-STATUS 'GUI_STATUS'.
  ENDIF.
ENDFORM.


FORM DISPLAY_CREATE_ALV .

  PERFORM SET_CREATE_ALV_LVC_COLUMNS .

  PERFORM SET_TOTAL_COUNT .

  GV_TITLE = GS_listheader-info .

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
   EXPORTING
*     I_INTERFACE_CHECK                 = ' '
*     I_BYPASSING_BUFFER                =
*     I_BUFFER_ACTIVE                   =
     I_CALLBACK_PROGRAM                = GV_REPID
     I_CALLBACK_PF_STATUS_SET          = 'SET_PF_STATUS'
     I_CALLBACK_USER_COMMAND           = 'USER_COMMAND'
*     I_CALLBACK_TOP_OF_PAGE            = ''
*     I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*     I_CALLBACK_HTML_END_OF_LIST       = ' '
*     I_STRUCTURE_NAME                  =
*     I_BACKGROUND_ID                   = ' '
     I_GRID_TITLE                      = GV_TITLE
     I_GRID_SETTINGS                   = LS_SETTING
     IS_LAYOUT_LVC                     = LS_LAYOUT
     IT_FIELDCAT_LVC                   = LT_FIELDCAT
*     IT_EXCLUDING                      =
*     IT_SPECIAL_GROUPS_LVC             =
*     IT_SORT_LVC                       =
*     IT_FILTER_LVC                     =
*     IT_HYPERLINK                      =
*     IS_SEL_HIDE                       =
*     I_DEFAULT                         = 'X'
     I_SAVE                            = 'A'
     IS_VARIANT                        = LS_VARIANT
     IT_EVENTS                         = LT_EVENT
*     IT_EVENT_EXIT                     =
*     IS_PRINT_LVC                      =
*     IS_REPREP_ID_LVC                  =
*     I_SCREEN_START_COLUMN             = 0
*     I_SCREEN_START_LINE               = 0
*     I_SCREEN_END_COLUMN               = 0
*     I_SCREEN_END_LINE                 = 0
*     I_HTML_HEIGHT_TOP                 =
*     I_HTML_HEIGHT_END                 =
*     IT_ALV_GRAPHICS                   =
*     IT_EXCEPT_QINFO_LVC               =
*   IMPORTING
*     E_EXIT_CAUSED_BY_CALLER           =
*     ES_EXIT_CAUSED_BY_USER            =
    TABLES
      T_OUTTAB                          = GT_TABLE
   EXCEPTIONS
     PROGRAM_ERROR                     = 1
     OTHERS                            = 2.

  IF SY-SUBRC <> 0.
*   Implement suitable error handling here
  ENDIF.
ENDFORM .


FORM DISPLAY_QUERY_ALV .

  PERFORM SET_QUERY_ALV_LVC_COLUMNS .

  PERFORM GET_QUERY_DATA .

  PERFORM SET_QUERY_COLOR .

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
   EXPORTING
*     I_INTERFACE_CHECK                 = ' '
*     I_BYPASSING_BUFFER                =
*     I_BUFFER_ACTIVE                   =
     I_CALLBACK_PROGRAM                = GV_REPID
     I_CALLBACK_PF_STATUS_SET          = 'SET_PF_STATUS'
     I_CALLBACK_USER_COMMAND           = 'USER_COMMAND'
*     I_CALLBACK_TOP_OF_PAGE            = ' '
*     I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*     I_CALLBACK_HTML_END_OF_LIST       = ' '
*     I_STRUCTURE_NAME                  =
*     I_BACKGROUND_ID                   = ' '
*     I_GRID_TITLE                      =
     I_GRID_SETTINGS                   = LS_SETTING
     IS_LAYOUT_LVC                     = LS_LAYOUT
     IT_FIELDCAT_LVC                   = LT_FIELDCAT_QUERY
*     IT_EXCLUDING                      =
*     IT_SPECIAL_GROUPS_LVC             =
*     IT_SORT_LVC                       =
*     IT_FILTER_LVC                     =
*     IT_HYPERLINK                      =
*     IS_SEL_HIDE                       =
*     I_DEFAULT                         = 'X'
     I_SAVE                            = 'A'
     IS_VARIANT                        = LS_VARIANT
     IT_EVENTS                         = LT_EVENT
*     IT_EVENT_EXIT                     =
*     IS_PRINT_LVC                      =
*     IS_REPREP_ID_LVC                  =
*     I_SCREEN_START_COLUMN             = 0
*     I_SCREEN_START_LINE               = 0
*     I_SCREEN_END_COLUMN               = 0
*     I_SCREEN_END_LINE                 = 0
*     I_HTML_HEIGHT_TOP                 =
*     I_HTML_HEIGHT_END                 =
*     IT_ALV_GRAPHICS                   =
*     IT_EXCEPT_QINFO_LVC               =
*   IMPORTING
*     E_EXIT_CAUSED_BY_CALLER           =
*     ES_EXIT_CAUSED_BY_USER            =
    TABLES
      T_OUTTAB                          = GT_QUERY_EXTEND
   EXCEPTIONS
     PROGRAM_ERROR                     = 1
     OTHERS                            = 2.
  IF SY-SUBRC <> 0.
*   Implement suitable error handling here
  ENDIF.
ENDFORM .


FORM GET_QUERY_DATA .

  IF Q_BUKRS IS NOT INITIAL .

    SELECT * FROM ZTFICO099 INTO CORRESPONDING FIELDS OF TABLE @GT_QUERY_EXTEND
      WHERE BUKRS IN @Q_BUKRS
      AND ANLN1 IN @Q_ANLN1
      AND ERNAM IN @Q_ERNAM
      AND ZCDATE IN @Q_ZCDATE
      AND ZCTIME IN @Q_ZCTIME .

  ELSE.
    SELECT * FROM ZTFICO099 INTO CORRESPONDING FIELDS OF TABLE  @GT_QUERY_EXTEND
      WHERE BUKRS IN @RT_BUKRS
      AND ANLN1 IN @Q_ANLN1
      AND ERNAM IN @Q_ERNAM
      AND ZCDATE IN @Q_ZCDATE
      AND ZCTIME IN @Q_ZCTIME .
  ENDIF.
  SORT  GT_QUERY_EXTEND BY ZUUID DESCENDING BUKRS ASCENDING ANLN1 ASCENDING .
ENDFORM.


FORM USER_COMMAND USING R_UCOMM LIKE SY-UCOMM
                        RS_SELFIELD TYPE SLIS_SELFIELD.

  CASE R_UCOMM.

    WHEN '&IC1'.
      IF P_CREATE IS NOT INITIAL .

        READ TABLE GT_TABLE INTO DATA(GS_M_AS03) INDEX RS_SELFIELD-TABINDEX.
        IF SY-SUBRC = 0.

          IF RS_SELFIELD-FIELDNAME = 'ANLN1'.
            CHECK GS_M_AS03-ANLN1 IS NOT INITIAL.
            SET PARAMETER ID 'AN1' FIELD GS_M_AS03-ANLN1.
            SET PARAMETER ID 'BUK' FIELD GS_M_AS03-BUKRS.
            CALL TRANSACTION 'AS03' AND SKIP FIRST SCREEN.
          ENDIF.
        ENDIF.
      ELSE.
        READ TABLE GT_QUERY_EXTEND INTO DATA(GS_Q_AS03) INDEX RS_SELFIELD-TABINDEX.
        IF SY-SUBRC = 0.
          IF RS_SELFIELD-FIELDNAME = 'ANLN1'.
            CHECK GS_Q_AS03-ANLN1 IS NOT INITIAL.
            SET PARAMETER ID 'AN1' FIELD GS_Q_AS03-ANLN1.
            SET PARAMETER ID 'BUK' FIELD GS_Q_AS03-BUKRS.
            CALL TRANSACTION 'AS03' AND SKIP FIRST SCREEN.
          ENDIF.
        ENDIF.
      ENDIF.

    WHEN 'CREATE'.

      PERFORM CHECK_GT_TABLE_FIELD .

      READ TABLE GT_TABLE INTO DATA(LS_CHECK_UUID) INDEX 1 .
      IF LS_CHECK_UUID-ZUUID IS NOT INITIAL .
        MESSAGE '不能对已经上传的批次数据重复执行修改操作' TYPE 'E'.
      ENDIF.

      DATA GV_MODIFY_COUNT TYPE I .
      DATA GV_UUID_PATTERN TYPE STRING .
      DATA GV_UUID TYPE CHAR16 .

      LOOP AT GT_TABLE INTO DATA(LS_TABLE).
        AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
          ID 'BUKRS' FIELD LS_TABLE-BUKRS
          ID 'ACTVT' FIELD '03' .
        IF SY-SUBRC <> 0 .
          MESSAGE |您没有公司{ LS_TABLE-BUKRS }的权限| TYPE 'E' .
        ENDIF .
      ENDLOOP.

      PERFORM EN_LOCK .

*      GV_UUID_PATTERN = |{ LS_TABLE-BUKRS }{ SY-DATUM }%| .
      GV_UUID_PATTERN = |{ SY-DATUM }%| .
      SELECT SINGLE MAX( ZUUID ) INTO @DATA(GV_MAX_ZUUID) FROM ZTFICO099
          WHERE ZUUID LIKE @GV_UUID_PATTERN .

      IF GV_MAX_ZUUID IS INITIAL  .
*        GV_UUID = LS_TABLE-BUKRS && SY-DATUM && '0001' .
        GV_UUID = SY-DATUM && '00000001' .
      ELSE.
        GV_UUID = GV_MAX_ZUUID + 1 .
      ENDIF.

      LOOP AT GT_TABLE ASSIGNING FIELD-SYMBOL(<FS_UUID>)  .
        <FS_UUID>-ZUUID = GV_UUID .
      ENDLOOP.

      SELECT BUKRS, BUTXT FROM T001 INTO TABLE @DATA(LT_T001)
        FOR ALL ENTRIES IN @GT_TABLE
        WHERE BUKRS = @GT_TABLE-BUKRS .

      SELECT KOSTL, LTEXT AS LTEXT1 FROM CSKT INTO TABLE @DATA(LT_LTEXT1)
        FOR ALL ENTRIES IN @GT_TABLE
        WHERE KOSTL = @GT_TABLE-KOSTL
        AND SPRAS = '1'
        AND KOKRS = 'HNJT' .

      SELECT KOSTL AS KOSTLV, LTEXT AS LTEXT2 FROM CSKT INTO TABLE @DATA(LT_TEXT2)
        FOR ALL ENTRIES IN @GT_TABLE
        WHERE KOSTL = @GT_TABLE-KOSTLV
        AND SPRAS = '1'
        AND KOKRS = 'HNJT' .

      SELECT POSID, POST1 FROM PRPS INTO TABLE @DATA(LT_POSID)
        FOR ALL ENTRIES IN @GT_TABLE
        WHERE POSID = @GT_TABLE-PS_PSP_PNR2 .

      SELECT ORD4X, ORDTX AS ORDTX2 FROM T087T  INTO TABLE @DATA(LT_ORDTX2)
        FOR ALL ENTRIES IN @GT_TABLE
        WHERE ORD4X = @GT_TABLE-ORD42
        AND ORDNR = '2' .

      SELECT GDLGRP , GDLGRP_TXT FROM T087S INTO TABLE @DATA(LT_T087S)
        FOR ALL ENTRIES IN @GT_TABLE
        WHERE GDLGRP = @GT_TABLE-GDLGRP  .

      SELECT BUKRS, ZAQFBM , ZAQFMS FROM ZTMM_AQF INTO TABLE @DATA(LT_ZAQFMS)
        FOR ALL ENTRIES IN @GT_TABLE
        WHERE BUKRS = @GT_TABLE-BUKRS
        AND   ZAQFBM = @GT_TABLE-ZZAQFBM .


      SELECT ORD4X, ORDTX AS ORDTX1 FROM T087T INTO TABLE @DATA(LT_ORDTX1)
        FOR ALL ENTRIES IN @GT_TABLE
        WHERE ORD4X = @GT_TABLE-ORD41
        AND ORDNR = '1' .

      SELECT SINGLE NAME_TEXTC FROM USER_ADDR INTO  @DATA(LV_NAME_TEXTC)
        WHERE BNAME = @SY-UNAME .

      LOOP AT GT_TABLE ASSIGNING FIELD-SYMBOL(<FS_ITEM>) .
        "清空BAPI参数
        CLEAR:LS_KEY,
*          LS_REFERENCE,LV_CREATESUBNUMBER,LV_POSTCAP,LV_CREATEGROUPASSET,LV_TESTRUN,
        LS_GENERALDATA,LS_GENERALDATAX,
*          LS_INVENTORY,LS_INVENTORYX,LS_POSTINGINFORMATION, LS_POSTINGINFORMATIONX,
        LS_TIMEDEPENDENTDATA,LS_TIMEDEPENDENTDATAX,LS_ALLOCATIONS,LS_ALLOCATIONSX,LS_ORIGIN,LS_ORIGINX.
*        LS_INVESTACCTASSIGNMNT,LS_INVESTACCTASSIGNMNTX,LS_NETWORTHVALUATION,LS_NETWORTHVALUATIONX,LS_REALESTATE,LS_REALESTATEX,
*        LS_INSURANCE,LS_INSURANCEX,LS_LEASING,LS_LEASINGX,LS_GLO_TIME_DEP .

        CLEAR:LV_COMPANYCODE,LV_ASSET,LV_SUBNUMBER,LS_ASSETCREATED,LS_RETURN.

        CLEAR:LS_DEPRECIATIONAREAS,LS_DEPRECIATIONAREASX,
*          LS_INVESTMENT_SUPPORT,
          LS_EXTENSIONIN.

        FREE:LT_DEPRECIATIONAREAS,LT_DEPRECIATIONAREASX,
*          LT_INVESTMENT_SUPPORT,
          LT_EXTENSIONIN.


        LS_KEY-COMPANYCODE = <FS_ITEM>-BUKRS.

*        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*          EXPORTING
*            INPUT  = <FS_ITEM>-ANLKL
*          IMPORTING
*            OUTPUT = LS_GENERALDATA-ASSETCLASS. "资产分类
        LS_GENERALDATA-ASSETCLASS = <FS_ITEM>-ANLKL."资产分类
        LS_GENERALDATAX-ASSETCLASS = 'X'.

*      **** Required fields - General Mills *****
        LS_GENERALDATA-DESCRIPT = <FS_ITEM>-TXT50.
        LS_GENERALDATAX-DESCRIPT = 'X'.

        IF <FS_ITEM>-TXA50 IS NOT INITIAL .
          LS_GENERALDATA-DESCRIPT2 = <FS_ITEM>-TXA50.
          LS_GENERALDATAX-DESCRIPT2 = 'X'.
        ENDIF.

        IF <FS_ITEM>-ANLHTXT IS NOT INITIAL .
          LS_GENERALDATA-MAIN_DESCRIPT = <FS_ITEM>-ANLHTXT.
          LS_GENERALDATAX-MAIN_DESCRIPT = 'X'.
        ENDIF.

        IF <FS_ITEM>-SERNR IS NOT INITIAL .
          LS_GENERALDATA-SERIAL_NO = <FS_ITEM>-SERNR .
          LS_GENERALDATAX-SERIAL_NO = 'X'.
        ENDIF.

        IF <FS_ITEM>-MENGE IS NOT INITIAL .
          LS_GENERALDATA-QUANTITY = <FS_ITEM>-MENGE."数量
          LS_GENERALDATAX-QUANTITY = 'X'.
        ENDIF.

        IF <FS_ITEM>-MEINS IS NOT INITIAL .
          CLEAR GV_MEINS_INNER_CODE .
          CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
            EXPORTING
              input                = <FS_ITEM>-MEINS
             LANGUAGE             = SY-LANGU
           IMPORTING
             OUTPUT               = GV_MEINS_INNER_CODE
           EXCEPTIONS
             UNIT_NOT_FOUND       = 1
             OTHERS               = 2 .
          IF sy-subrc <> 0.
* Implement suitable error handling here
          ENDIF.

          LS_GENERALDATA-BASE_UOM = GV_MEINS_INNER_CODE ."单位
          LS_GENERALDATAX-BASE_UOM = 'X'.
        ENDIF.

*        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*          EXPORTING
*            INPUT  = <LW_DATA>-KOSTL
*          IMPORTING
*            OUTPUT = LS_TIMEDEPENDENTDATA-COSTCENTER. "成本中心
        IF <FS_ITEM>-KOSTL IS NOT INITIAL .
          LS_TIMEDEPENDENTDATA-COSTCENTER = <FS_ITEM>-KOSTL.
          LS_TIMEDEPENDENTDATAX-COSTCENTER = 'X'.
        ENDIF.

        IF <FS_ITEM>-PS_PSP_PNR2 IS NOT INITIAL .
          LS_TIMEDEPENDENTDATA-WBS_ELEMENT_COST = <FS_ITEM>-PS_PSP_PNR2 .
          LS_TIMEDEPENDENTDATAX-WBS_ELEMENT_COST = 'X'.
        ENDIF.

*       Cost center responsible for asset
*        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*          EXPORTING
*            INPUT  = <LW_DATA>-KOSTLV
*          IMPORTING
*            OUTPUT = LS_TIMEDEPENDENTDATA-RESP_CCTR. "责任成本中心
        IF <FS_ITEM>-KOSTLV IS NOT INITIAL .
          LS_TIMEDEPENDENTDATA-RESP_CCTR = <FS_ITEM>-KOSTLV.
          LS_TIMEDEPENDENTDATAX-RESP_CCTR = 'X'.
        ENDIF.

        IF <FS_ITEM>-KFZKZ IS NOT INITIAL .
          LS_TIMEDEPENDENTDATA-PLATE_NO = <FS_ITEM>-KFZKZ.
          LS_TIMEDEPENDENTDATAX-LICENSE_PLATE_NO = 'X'.
        ENDIF.


        IF <FS_ITEM>-ord41 IS NOT INITIAL .
          ls_allocations-evalgroup1        = <FS_ITEM>-ord41.
          ls_allocationsx-evalgroup1       = abap_true.
        ENDIF.

        IF <FS_ITEM>-ord42 IS NOT INITIAL .
          ls_allocations-evalgroup2        = <FS_ITEM>-ord42.
          ls_allocationsx-evalgroup2       = abap_true.
        ENDIF.

        IF <FS_ITEM>-GDLGRP IS NOT INITIAL .
          ls_allocations-EVALGROUP5        = <FS_ITEM>-GDLGRP.
          ls_allocationsx-EVALGROUP5       = abap_true.
        ENDIF.

        IF <FS_ITEM>-AIBN1 IS NOT INITIAL .
          ls_origin-ORIG_ASSET              = <FS_ITEM>-AIBN1 .  "原始资产 卡片号
          ls_originx-ORIG_ASSET             = abap_true.
        ENDIF.

*********** 折旧范围 相关 ******* START *********
        CLEAR: LS_DEPRECIATIONAREAS, LS_DEPRECIATIONAREASX .
        LS_DEPRECIATIONAREAS-DEP_KEY = <FS_ITEM>-AFASL .
        LS_DEPRECIATIONAREASX-DEP_KEY = 'X'.

        LS_DEPRECIATIONAREAS-AREA = '01' .
        LS_DEPRECIATIONAREASX-AREA = '01' .

        IF <FS_ITEM>-NDPER IS NOT INITIAL .
          LS_DEPRECIATIONAREAS-ULIFE_YRS = <FS_ITEM>-NDJAR .
          LS_DEPRECIATIONAREASX-ULIFE_YRS = 'X' .
        ENDIF.

        IF <FS_ITEM>-NDPER IS NOT INITIAL .
          LS_DEPRECIATIONAREAS-ULIFE_PRDS = <FS_ITEM>-NDPER .
          LS_DEPRECIATIONAREASX-ULIFE_PRDS = 'X' .
        ENDIF.

        APPEND LS_DEPRECIATIONAREAS TO LT_DEPRECIATIONAREAS .
        APPEND LS_DEPRECIATIONAREASX TO LT_DEPRECIATIONAREASX .



*********** 折旧范围 相关 ******* END *********


        "供应商科目编号(其他关键字)
*        LS_ORIGIN-VENDOR_NO = <LW_DATA>-LIFNR.
*        LS_ORIGINX-VENDOR_NO = 'X'.

        "增强字段传值
          CLEAR LS_ANLU.
          IF <FS_ITEM>-ZZPFWJH IS NOT INITIAL
            OR <FS_ITEM>-ZZCJH IS NOT INITIAL
            OR <FS_ITEM>-ZZCFWZ IS NOT INITIAL
            OR <FS_ITEM>-ZZAQFBM IS NOT INITIAL .

            IF <FS_ITEM>-ZZPFWJH IS NOT INITIAL .
              LS_ANLU-ZZPFWJH = <FS_ITEM>-ZZPFWJH.
            ENDIF.

            IF <FS_ITEM>-ZZCJH IS NOT INITIAL .
              LS_ANLU-ZZCJH = <FS_ITEM>-ZZCJH .
            ENDIF.

            IF <FS_ITEM>-ZZCFWZ IS NOT INITIAL .
              LS_ANLU-ZZCFWZ = <FS_ITEM>-ZZCFWZ .
            ENDIF.

            IF <FS_ITEM>-ZZAQFBM IS NOT INITIAL .
              LS_ANLU-ZZAQFBM = <FS_ITEM>-ZZAQFBM .
            ENDIF.

            LS_EXTENSIONIN-STRUCTURE = 'BAPI_TE_ANLU'.
            LS_EXTENSIONIN-VALUEPART1 = LS_ANLU.
            APPEND LS_EXTENSIONIN TO LT_EXTENSIONIN.

          ENDIF.

        CALL FUNCTION 'BAPI_FIXEDASSET_CREATE1'
          EXPORTING
            KEY                  = LS_KEY
*            REFERENCE            = LS_REFERENCE
*            CREATESUBNUMBER      = LV_CREATESUBNUMBER
*            POSTCAP              = LV_POSTCAP
*            CREATEGROUPASSET     = LV_CREATEGROUPASSET
*            TESTRUN              = LV_TESTRUN
            GENERALDATA          = LS_GENERALDATA
            GENERALDATAX         = LS_GENERALDATAX
*            INVENTORY            = LS_INVENTORY
*            INVENTORYX           = LS_INVENTORYX
*            POSTINGINFORMATION   = LS_POSTINGINFORMATION
*            POSTINGINFORMATIONX  = LS_POSTINGINFORMATIONX
            TIMEDEPENDENTDATA    = LS_TIMEDEPENDENTDATA
            TIMEDEPENDENTDATAX   = LS_TIMEDEPENDENTDATAX
            ALLOCATIONS          = LS_ALLOCATIONS
            ALLOCATIONSX         = LS_ALLOCATIONSX
            ORIGIN               = LS_ORIGIN
            ORIGINX              = LS_ORIGINX
*            INVESTACCTASSIGNMNT  = LS_INVESTACCTASSIGNMNT
*            INVESTACCTASSIGNMNTX = LS_INVESTACCTASSIGNMNTX
*            NETWORTHVALUATION    = LS_NETWORTHVALUATION
*            NETWORTHVALUATIONX   = LS_NETWORTHVALUATIONX
*            REALESTATE           = LS_REALESTATE
*            REALESTATEX          = LS_REALESTATEX
*            INSURANCE            = LS_INSURANCE
*            INSURANCEX           = LS_INSURANCEX
*            LEASING              = LS_LEASING
*            LEASINGX             = LS_LEASINGX
*            GLO_TIME_DEP         = LS_GLO_TIME_DEP
          IMPORTING
            COMPANYCODE          = LV_COMPANYCODE
            ASSET                = LV_ASSET
            SUBNUMBER            = LV_SUBNUMBER
            ASSETCREATED         = LS_ASSETCREATED
            RETURN               = LS_RETURN
          TABLES
            DEPRECIATIONAREAS    = LT_DEPRECIATIONAREAS
            DEPRECIATIONAREASX   = LT_DEPRECIATIONAREASX
*            INVESTMENT_SUPPORT   = LT_INVESTMENT_SUPPORT
            EXTENSIONIN          = LT_EXTENSIONIN.

        IF SY-SUBRC = 0 .

          <FS_ITEM>-ZMSGTYPE = LS_RETURN-TYPE .
          IF <FS_ITEM>-ZMSGTYPE = 'E' .
            <FS_ITEM>-ZRESULT = '失败' .
          ELSE.
            <FS_ITEM>-ZRESULT = '成功' .
          ENDIF.

          IF ls_return-type EQ 'S'.

            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                wait = 'X'.  "等待提交完成，避免并发问题

            CALL FUNCTION 'MESSAGE_TEXT_BUILD'
              EXPORTING
                msgid               = ls_return-id       "消息类
                msgnr               = ls_return-number   "消息号
                msgv1               = ls_return-message_v1 "消息变量1
                msgv2               = ls_return-message_v2 "消息变量2
                msgv3               = ls_return-message_v3 "消息变量3
                msgv4               = ls_return-message_v4 "消息变量4
              IMPORTING
                message_text_output = lv_message.        "拼接后的消息文本

           <FS_ITEM>-ANLN1 = LS_RETURN-MESSAGE_V1 .

          ELSE.
*            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            "拼接失败消息
            CALL FUNCTION 'MESSAGE_TEXT_BUILD'
              EXPORTING
                msgid               = ls_return-id
                msgnr               = ls_return-number
                msgv1               = ls_return-message_v1
                msgv2               = ls_return-message_v2
                msgv3               = ls_return-message_v3
                msgv4               = ls_return-message_v4
              IMPORTING
                message_text_output = lv_message.

          ENDIF.

          <FS_ITEM>-ZMSGCLS = LS_RETURN-ID.
          <FS_ITEM>-ZMSGNUMBER = LS_RETURN-NUMBER .
          <FS_ITEM>-ZMSGTEXT = LV_MESSAGE .
          <FS_ITEM>-ERNAM = SY-UNAME .
          <FS_ITEM>-ZCDATE = SY-DATUM .
          <FS_ITEM>-ZCTIME = SY-UZEIT .

        ELSE .
          <FS_ITEM>-ZMSGTYPE = 'E'.
          <FS_ITEM>-ZMSGTEXT = 'Unknown' .
          <FS_ITEM>-ZRESULT = '失败' .
        ENDIF.

        IF <FS_ITEM>-ZMSGTYPE = 'E' .
          CLEAR: LS_CELLCOLOR, LT_CELLCOLOR.
          ls_cellcolor-fname = 'ZRESULT'.
          ls_cellcolor-color-col = '6'.
          ls_cellcolor-color-int = '0'.
          ls_cellcolor-color-inv = '0'.

          INSERT ls_cellcolor INTO TABLE lt_cellcolor.
          <FS_ITEM>-CELL_COLOR = LT_CELLCOLOR.
        ENDIF.

        MOVE-CORRESPONDING <FS_ITEM> TO GS_CREATE_RECORD .

*        SELECT SINGLE BUTXT FROM T001 INTO GS_CREATE_RECORD-BUTXT
*          WHERE BUKRS = GS_CREATE_RECORD-BUKRS .

        READ TABLE LT_T001 WITH KEY BUKRS = GS_CREATE_RECORD-BUKRS INTO DATA(LS_BUTXT) .
        IF SY-SUBRC = 0.
          GS_CREATE_RECORD-BUTXT = LS_BUTXT-BUTXT .
        ENDIF.

*        SELECT SINGLE LTEXT FROM CSKT INTO GS_CREATE_RECORD-LTEXT1
*          WHERE KOSTL = GS_CREATE_RECORD-KOSTL
*          AND SPRAS = '1'
*          AND KOKRS = 'HNJT' .

        READ TABLE LT_LTEXT1 WITH KEY KOSTL = GS_CREATE_RECORD-KOSTL INTO DATA(LS_LTEXT1) .
        IF SY-SUBRC = 0.
          GS_CREATE_RECORD-LTEXT1 = LS_LTEXT1-LTEXT1 .
        ENDIF.

*        SELECT SINGLE LTEXT FROM CSKT INTO GS_CREATE_RECORD-LTEXT2
*          WHERE KOSTL = GS_CREATE_RECORD-KOSTLV
*          AND SPRAS = '1'
*          AND KOKRS = 'HNJT' .

        READ TABLE LT_TEXT2 WITH KEY KOSTLV = GS_CREATE_RECORD-KOSTLV INTO DATA(LS_LTEXT2) .
        IF SY-SUBRC = 0.
          GS_CREATE_RECORD-LTEXT2 = LS_LTEXT2-LTEXT2 .
        ENDIF.

*        SELECT SINGLE POST1 FROM PRPS INTO GS_CREATE_RECORD-POST1
*          WHERE POSID = GS_CREATE_RECORD-PS_PSP_PNR2 .

        READ TABLE LT_POSID WITH KEY POSID = GS_CREATE_RECORD-PS_PSP_PNR2 INTO DATA(LS_POSID) .
        IF SY-SUBRC = 0.
          GS_CREATE_RECORD-POST1 = LS_POSID-POST1 .
        ENDIF.

*        SELECT SINGLE ORDTX FROM T087T  INTO GS_CREATE_RECORD-ORDTX2
*          WHERE ORD4X = GS_CREATE_RECORD-ORD42
*          AND ORDNR = '2' .

        READ TABLE LT_ORDTX2 WITH KEY ORD4X = GS_CREATE_RECORD-ORD42 INTO DATA(LS_ORDTX2) .
        IF SY-SUBRC = 0 .
          GS_CREATE_RECORD-ORDTX2 = LS_ORDTX2-ORDTX2 .
        ENDIF.

*        SELECT SINGLE GDLGRP_TXT FROM T087S INTO GS_CREATE_RECORD-GDLGRP_TXT
*          WHERE GDLGRP = GS_CREATE_RECORD-GDLGRP  .

        READ TABLE LT_T087S WITH KEY GDLGRP = GS_CREATE_RECORD-GDLGRP INTO DATA(LS_T087S) .
        IF SY-SUBRC = 0 .
          GS_CREATE_RECORD-GDLGRP_TXT = LS_T087S-GDLGRP_TXT .
        ENDIF.

*        SELECT SINGLE ZAQFMS FROM ZTMM_AQF INTO GS_CREATE_RECORD-ZAQFMS
*          WHERE BUKRS = GS_CREATE_RECORD-BUKRS
*          AND   ZAQFBM = GS_CREATE_RECORD-ZZAQFBM .
        READ TABLE LT_ZAQFMS WITH KEY BUKRS = GS_CREATE_RECORD-BUKRS ZAQFBM = GS_CREATE_RECORD-ZZAQFBM
          INTO DATA(LS_ZAQFMS) .
        IF SY-SUBRC = 0.
          GS_CREATE_RECORD-ZAQFMS = LS_ZAQFMS-ZAQFMS .
        ENDIF.

*        SELECT SINGLE ORD4X FROM T087T INTO GS_CREATE_RECORD-ORDTX1
*          WHERE ORD4X = GS_CREATE_RECORD-ORD41
*          AND ORDNR = '1' .
        READ TABLE LT_ORDTX1 WITH KEY ORD4X = GS_CREATE_RECORD-ORD41 INTO DATA(LS_ORDTX1) .
        IF SY-SUBRC = 0 .
          GS_CREATE_RECORD-ORDTX1 = LS_ORDTX1-ORDTX1 .
        ENDIF.

*        SELECT SINGLE NAME_TEXTC FROM USER_ADDR INTO GS_CREATE_RECORD-NAME_TEXTC1
*          WHERE BNAME = GS_CREATE_RECORD-ERNAM .
        GS_CREATE_RECORD-NAME_TEXTC1 = LV_NAME_TEXTC .

        MODIFY ZTFICO099 FROM GS_CREATE_RECORD  .
        COMMIT WORK .

      ENDLOOP .


      PERFORM DE_LOCK .

      IF LO_GRID IS INITIAL.
        CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
*         EXPORTING
*           IR_SALV_FULLSCREEN_ADAPTER       =
         IMPORTING
*           ET_EXCLUDING                     =
*           E_REPID                          =
*           E_CALLBACK_PROGRAM               =
*           E_CALLBACK_ROUTINE               =
           E_GRID                           = LO_GRID
*           ET_FIELDCAT_LVC                  =
*           ER_TRACE                         =
*           E_FLG_NO_HTML                    =
*           ES_LAYOUT_KKBLO                  =
*           ES_SEL_HIDE                      =
*           ET_EVENT_EXIT                    =
*           ER_FORM_TOL                      =
*           ER_FORM_EOL                      =
                  .
      ENDIF.

      CALL METHOD LO_GRID->REFRESH_TABLE_DISPLAY
        EXPORTING
            IS_STABLE = LS_STABLE.



  ENDCASE .


ENDFORM .


FORM SET_CREATE_ALV_LVC_COLUMNS .

  LS_FIELDCAT-FIELDNAME = 'ZUUID'.
  LS_FIELDCAT-COLTEXT = '更新操作编码'.
  LS_FIELDCAT-SCRTEXT_S = '更新操作编码'.
  LS_FIELDCAT-SCRTEXT_M = '更新操作编码'.
  LS_FIELDCAT-SCRTEXT_L = '更新操作编码'.
  LS_FIELDCAT-OUTPUTLEN = 16.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'ZROWID'.
  LS_FIELDCAT-COLTEXT = '唯一性号码'.
  LS_FIELDCAT-SCRTEXT_S = '唯一性号码'.
  LS_FIELDCAT-SCRTEXT_M = '唯一性号码'.
  LS_FIELDCAT-SCRTEXT_L = '唯一性号码'.
  LS_FIELDCAT-OUTPUTLEN = 8.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'BUKRS'.
  LS_FIELDCAT-COLTEXT = '公司代码'.
  LS_FIELDCAT-SCRTEXT_S = '公司代码'.
  LS_FIELDCAT-SCRTEXT_M = '公司代码'.
  LS_FIELDCAT-SCRTEXT_L = '公司代码'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 4.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.



  LS_FIELDCAT-FIELDNAME = 'ANLKL'.
  LS_FIELDCAT-COLTEXT = '资产大类'.
  LS_FIELDCAT-SCRTEXT_S = '资产大类'.
  LS_FIELDCAT-SCRTEXT_M = '资产大类'.
  LS_FIELDCAT-SCRTEXT_L = '资产大类'.
  LS_FIELDCAT-OUTPUTLEN = 8.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'ANLN1'.
  LS_FIELDCAT-COLTEXT = '资产编码'.
  LS_FIELDCAT-SCRTEXT_S = '资产编码'.
  LS_FIELDCAT-SCRTEXT_M = '资产编码'.
  LS_FIELDCAT-SCRTEXT_L = '资产编码'.
  LS_FIELDCAT-OUTPUTLEN = 12.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
  LS_FIELDCAT-HOTSPOT = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZRESULT'.
  LS_FIELDCAT-COLTEXT = '操作结果'.
  LS_FIELDCAT-SCRTEXT_S = '操作结果'.
  LS_FIELDCAT-SCRTEXT_M = '操作结果'.
  LS_FIELDCAT-SCRTEXT_L = '操作结果'.
  LS_FIELDCAT-OUTPUTLEN = 10.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.



  LS_FIELDCAT-FIELDNAME = 'TXT50'.
  LS_FIELDCAT-COLTEXT = '资产描述'.
  LS_FIELDCAT-SCRTEXT_S = '资产描述'.
  LS_FIELDCAT-SCRTEXT_M = '资产描述'.
  LS_FIELDCAT-SCRTEXT_L = '资产描述'.
  LS_FIELDCAT-OUTPUTLEN = 50.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'TXA50'.
  LS_FIELDCAT-COLTEXT = '附加描述(规格型号)'.
  LS_FIELDCAT-SCRTEXT_S = '附加描述(规格型号)'.
  LS_FIELDCAT-SCRTEXT_M = '附加描述(规格型号)'.
  LS_FIELDCAT-SCRTEXT_L = '附加描述(规格型号)'.
  LS_FIELDCAT-OUTPUTLEN = 50.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 6.
  LS_FIELDCAT-FIELDNAME = 'ANLHTXT'.
  LS_FIELDCAT-COLTEXT = '资产主号文本'.
  LS_FIELDCAT-SCRTEXT_S = '资产主号文本'.
  LS_FIELDCAT-SCRTEXT_M = '资产主号文本'.
  LS_FIELDCAT-SCRTEXT_L = '资产主号文本'.
  LS_FIELDCAT-OUTPUTLEN = 50 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 7.
  LS_FIELDCAT-FIELDNAME = 'SERNR'.
  LS_FIELDCAT-COLTEXT = '序列号(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_S = '序列号(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_M = '序列号(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_L = '序列号(旧系统资产卡片号)'.
  LS_FIELDCAT-OUTPUTLEN = 18 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'MENGE'.
  LS_FIELDCAT-COLTEXT = '数量'.
  LS_FIELDCAT-SCRTEXT_S = '数量'.
  LS_FIELDCAT-SCRTEXT_M = '数量'.
  LS_FIELDCAT-SCRTEXT_L = '数量'.
  LS_FIELDCAT-OUTPUTLEN = 18 .
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'MEINS'.
  LS_FIELDCAT-COLTEXT = '单位'.
  LS_FIELDCAT-SCRTEXT_S = '单位'.
  LS_FIELDCAT-SCRTEXT_M = '单位'.
  LS_FIELDCAT-SCRTEXT_L = '单位'.
  LS_FIELDCAT-OUTPUTLEN = 3 .
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'KOSTL'.
  LS_FIELDCAT-COLTEXT = '成本中心'.
  LS_FIELDCAT-SCRTEXT_S = '成本中心'.
  LS_FIELDCAT-SCRTEXT_M = '成本中心'.
  LS_FIELDCAT-SCRTEXT_L = '成本中心'.
  LS_FIELDCAT-OUTPUTLEN = 10 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'PS_PSP_PNR2'.
  LS_FIELDCAT-COLTEXT = 'WBS 要素 '.
  LS_FIELDCAT-SCRTEXT_S = 'WBS 要素 '.
  LS_FIELDCAT-SCRTEXT_M = 'WBS 要素 '.
  LS_FIELDCAT-SCRTEXT_L = 'WBS 要素 '.
  LS_FIELDCAT-OUTPUTLEN = 24.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'KOSTLV'.
  LS_FIELDCAT-COLTEXT = '责任成本中心'.
  LS_FIELDCAT-SCRTEXT_S = '责任成本中心'.
  LS_FIELDCAT-SCRTEXT_M = '责任成本中心'.
  LS_FIELDCAT-SCRTEXT_L = '责任成本中心'.
  LS_FIELDCAT-OUTPUTLEN = 10 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'KFZKZ'.
  LS_FIELDCAT-COLTEXT = '执照牌号'.
  LS_FIELDCAT-SCRTEXT_S = '执照牌号'.
  LS_FIELDCAT-SCRTEXT_M = '执照牌号'.
  LS_FIELDCAT-SCRTEXT_L = '执照牌号'.
  LS_FIELDCAT-OUTPUTLEN = 15 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ORD41'.
  LS_FIELDCAT-COLTEXT = '增加方式'.
  LS_FIELDCAT-SCRTEXT_S = '增加方式'.
  LS_FIELDCAT-SCRTEXT_M = '增加方式'.
  LS_FIELDCAT-SCRTEXT_L = '增加方式'.
  LS_FIELDCAT-OUTPUTLEN = 4.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ORD42'.
  LS_FIELDCAT-COLTEXT = '税法折旧组'.
  LS_FIELDCAT-SCRTEXT_S = '税法折旧组'.
  LS_FIELDCAT-SCRTEXT_M = '税法折旧组'.
  LS_FIELDCAT-SCRTEXT_L = '税法折旧组'.
  LS_FIELDCAT-OUTPUTLEN = 3 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'GDLGRP'.
  LS_FIELDCAT-COLTEXT = '资产分类(小类)'.
  LS_FIELDCAT-SCRTEXT_S = '资产分类(小类)'.
  LS_FIELDCAT-SCRTEXT_M = '资产分类(小类)'.
  LS_FIELDCAT-SCRTEXT_L = '资产分类(小类)'.
  LS_FIELDCAT-OUTPUTLEN = 8 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 15 .
  LS_FIELDCAT-FIELDNAME = 'AIBN1'.
  LS_FIELDCAT-COLTEXT = '原始资产(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_S = '原始资产(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_M = '原始资产(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_L = '原始资产(旧系统资产卡片号)'.
  LS_FIELDCAT-OUTPUTLEN = 12 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'AFASL'.
  LS_FIELDCAT-COLTEXT = '折旧码'.
  LS_FIELDCAT-SCRTEXT_S = '折旧码'.
  LS_FIELDCAT-SCRTEXT_M = '折旧码'.
  LS_FIELDCAT-SCRTEXT_L = '折旧码'.
  LS_FIELDCAT-OUTPUTLEN = 4 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'NDJAR'.
  LS_FIELDCAT-COLTEXT = '资产使用年限（年）'.
  LS_FIELDCAT-SCRTEXT_S = '资产使用年限（年）'.
  LS_FIELDCAT-SCRTEXT_M = '资产使用年限（年）'.
  LS_FIELDCAT-SCRTEXT_L = '资产使用年限（年）'.
  LS_FIELDCAT-OUTPUTLEN = 3 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'NDPER'.
  LS_FIELDCAT-COLTEXT = '资产使用月份（月）'.
  LS_FIELDCAT-SCRTEXT_S = '资产使用月份（月）'.
  LS_FIELDCAT-SCRTEXT_M = '资产使用月份（月）'.
  LS_FIELDCAT-SCRTEXT_L = '资产使用月份（月）'.
  LS_FIELDCAT-OUTPUTLEN = 3 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZZPFWJH'.
  LS_FIELDCAT-COLTEXT = '集团招标文号'.
  LS_FIELDCAT-SCRTEXT_S = '集团招标文号'.
  LS_FIELDCAT-SCRTEXT_M = '集团招标文号'.
  LS_FIELDCAT-SCRTEXT_L = '集团招标文号'.
  LS_FIELDCAT-OUTPUTLEN = 40 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 17 .
  LS_FIELDCAT-FIELDNAME = 'ZZCJH'.
  LS_FIELDCAT-COLTEXT = '车架号'.
  LS_FIELDCAT-SCRTEXT_S = '车架号'.
  LS_FIELDCAT-SCRTEXT_M = '车架号'.
  LS_FIELDCAT-SCRTEXT_L = '车架号'.
  LS_FIELDCAT-OUTPUTLEN = 17.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZZCFWZ'.
  LS_FIELDCAT-COLTEXT = '资产存放位置'.
  LS_FIELDCAT-SCRTEXT_S = '资产存放位置'.
  LS_FIELDCAT-SCRTEXT_M = '资产存放位置'.
  LS_FIELDCAT-SCRTEXT_L = '资产存放位置'.
  LS_FIELDCAT-OUTPUTLEN = 60 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZZAQFBM'.
  LS_FIELDCAT-COLTEXT = '专项储备编码'.
  LS_FIELDCAT-SCRTEXT_S = '专项储备编码'.
  LS_FIELDCAT-SCRTEXT_M = '专项储备编码'.
  LS_FIELDCAT-SCRTEXT_L = '专项储备编码'.
  LS_FIELDCAT-OUTPUTLEN = 10 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZMSGTYPE'.
  LS_FIELDCAT-COLTEXT = '消息标识'.
  LS_FIELDCAT-SCRTEXT_S = '消息标识'.
  LS_FIELDCAT-SCRTEXT_M = '消息标识'.
  LS_FIELDCAT-SCRTEXT_L = '消息标识'.
  LS_FIELDCAT-OUTPUTLEN = 1.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZMSGCLS'.
  LS_FIELDCAT-COLTEXT = '消息类'.
  LS_FIELDCAT-SCRTEXT_S = '消息类'.
  LS_FIELDCAT-SCRTEXT_M = '消息类'.
  LS_FIELDCAT-SCRTEXT_L = '消息类'.
  LS_FIELDCAT-OUTPUTLEN = 20.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZMSGNUMBER'.
  LS_FIELDCAT-COLTEXT = '消息编号'.
  LS_FIELDCAT-SCRTEXT_S = '消息编号'.
  LS_FIELDCAT-SCRTEXT_M = '消息编号'.
  LS_FIELDCAT-SCRTEXT_L = '消息编号'.
  LS_FIELDCAT-OUTPUTLEN = 3.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 26 .
  LS_FIELDCAT-FIELDNAME = 'ZMSGTEXT'.
  LS_FIELDCAT-COLTEXT = '消息文本'.
  LS_FIELDCAT-SCRTEXT_S = '消息文本'.
  LS_FIELDCAT-SCRTEXT_M = '消息文本'.
  LS_FIELDCAT-SCRTEXT_L = '消息文本'.
  LS_FIELDCAT-OUTPUTLEN = 220.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LOOP AT LT_FIELDCAT ASSIGNING FIELD-SYMBOL(<FS_FIELDCAT>) .
    <FS_FIELDCAT>-COL_POS = SY-TABIX .
  ENDLOOP.
ENDFORM .


FORM SET_TOTAL_COUNT .
  CLEAR: GS_listheader, GV_COUNT .
  DESCRIBE TABLE GT_TABLE LINES GV_COUNT .
  GS_listheader-typ  = 'H'.
  GS_listheader-info = |资产卡片批量创建  -  条目总数: { GV_COUNT }|.

  APPEND GS_listheader TO GT_listheader.
ENDFORM .


FORM CHECK_GT_TABLE_FIELD .

    SELECT * FROM T087T
      FOR ALL ENTRIES IN @GT_TABLE
      WHERE ORDNR = '2'
      AND ORD4X = @GT_TABLE-ORD42

      AND SPRAS = '1'
      INTO TABLE @DATA(GT_ORD42) .
    SORT GT_ORD42 BY ORD4X .

    SELECT * FROM T087S
      FOR ALL ENTRIES IN @GT_TABLE
      WHERE SPRAS = '1'
      AND GDLGRP = @GT_TABLE-GDLGRP
      INTO TABLE @DATA(GT_GDLGRP) .
    SORT GT_GDLGRP BY GDLGRP .


    SELECT * FROM ZTMM_AQF
      FOR ALL ENTRIES IN @GT_TABLE
      WHERE ZAQFBM = @GT_TABLE-ZZAQFBM
      AND BUKRS = @GT_TABLE-BUKRS
      INTO TABLE @DATA(GT_ZZAQFB) .
    SORT GT_ZZAQFB BY ZAQFBM .

    SELECT * FROM T087T
      FOR ALL ENTRIES IN @GT_TABLE
      WHERE ORDNR = '1'
      AND ORD4X = @GT_TABLE-ORD41
      AND SPRAS = '1'
      INTO TABLE @DATA(GT_ORD41) .
    SORT GT_ORD41 BY ORD4X .

    SELECT * FROM PRPS
      FOR ALL ENTRIES IN @GT_TABLE
      WHERE POSID = @GT_TABLE-PS_PSP_PNR2
      INTO TABLE @DATA(GT_POSID) .
    SORT GT_POSID BY POSID .

  DATA LT_HASH  TYPE HASHED TABLE OF TY_ZROWID WITH UNIQUE KEY ZROWID .
  DATA LS_HASH TYPE TY_ZROWID .

  LOOP AT GT_TABLE INTO GS_TABLE_CHECK .

    CLEAR LS_HASH .
    LS_HASH-ZROWID = GS_TABLE_CHECK-ZROWID .
    INSERT LS_HASH INTO TABLE LT_HASH .
    IF SY-SUBRC <> 0.
      MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 重复出现 请修改后再操作 | TYPE 'E'.
    ENDIF.

    IF GS_TABLE_CHECK-BUKRS IS INITIAL .
      MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中没有填写 公司代码 | TYPE 'E' .
    ENDIF.

    IF GS_TABLE_CHECK-ANLKL IS INITIAL .
      MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中没有填写 资产大类 | TYPE 'E' .
    ENDIF.

    IF GS_TABLE_CHECK-TXT50 IS INITIAL .
      MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中没有填写 资产描述 | TYPE 'E' .
    ENDIF.

    IF GS_TABLE_CHECK-AFASL IS INITIAL .
      MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中没有填写 折旧码 | TYPE 'E' .
    ENDIF.

    IF GS_TABLE_CHECK-NDJAR IS INITIAL AND GS_TABLE_CHECK-NDPER IS INITIAL .
      MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中没有填写 资产使用年限（年）/（月） | TYPE 'E' .
    ENDIF.


    IF GS_TABLE_CHECK-PS_PSP_PNR2 IS NOT INITIAL .
      READ TABLE GT_POSID WITH KEY POSID = GS_TABLE_CHECK-PS_PSP_PNR2 TRANSPORTING NO FIELDS .
      IF SY-SUBRC <> 0.
        MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中 WBS元素 { GS_TABLE_CHECK-PS_PSP_PNR2 } 不存在| TYPE 'E' .
      ENDIF.
    ENDIF.

    IF GS_TABLE_CHECK-ORD41 IS NOT INITIAL .
      READ TABLE GT_ORD41 WITH KEY ORD4X = GS_TABLE_CHECK-ORD41 TRANSPORTING NO FIELDS .
      IF SY-SUBRC <> 0.
        MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中 增加方式 { GS_TABLE_CHECK-ZZAQFBM } 不存在| TYPE 'E' .
      ENDIF.
    ENDIF.

    IF GS_TABLE_CHECK-ORD42 IS NOT INITIAL.
      READ TABLE GT_ORD42 WITH  KEY ORD4X = GS_TABLE_CHECK-ORD42 TRANSPORTING NO FIELDS .
      IF SY-SUBRC <> 0.
        MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中 税法折旧组 { GS_TABLE_CHECK-ORD42 } 不存在| TYPE 'E'.
      ENDIF.
    ENDIF.

    IF GS_TABLE_CHECK-GDLGRP IS NOT INITIAL .
      READ TABLE GT_GDLGRP WITH KEY GDLGRP = GS_TABLE_CHECK-GDLGRP TRANSPORTING NO FIELDS .
      IF SY-SUBRC <> 0.
        MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中 资产分类(小类) { GS_TABLE_CHECK-ORD42 } 不存在| TYPE 'E'.
      ENDIF.
    ENDIF.

    IF GS_TABLE_CHECK-ZZAQFBM IS NOT INITIAL .
      READ TABLE GT_ZZAQFB WITH KEY ZAQFBM = GS_TABLE_CHECK-ZZAQFBM TRANSPORTING NO FIELDS .
      IF SY-SUBRC <> 0.
        MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中 专项储备编码 { GS_TABLE_CHECK-ZZAQFBM } 不存在| TYPE 'E' .
      ENDIF.
    ENDIF.


****************** 检查 AS01 屏幕中 必填的字段  **** START  ************

    SELECT SINGLE   ANKA~ANLKL , ANKA~FELEI
      FROM  ANKA WHERE ANLKL = @GS_TABLE_CHECK-ANLKL
      INTO @DATA(GS_ANKA_FELEI) .

    SELECT SINGLE AFAPL FROM T093C WHERE BUKRS = @GS_TABLE_CHECK-BUKRS
      INTO @DATA(GV_T093C_AFAPL).


    SELECT BDATU , FELEI FROM ANKB
      WHERE ANLKL = @GS_ANKA_FELEI-ANLKL
      AND AFAPL = @GV_T093C_AFAPL
      AND ( AFABE = '01' OR AFABE = '30' )
      INTO TABLE @DATA(GT_ANKB_FELEI) .
    SORT GT_ANKB_FELEI BY BDATU DESCENDING .
    READ TABLE GT_ANKB_FELEI INDEX 1 INTO DATA(GS_ANKB_FELEI) .

    SELECT FEGTB, FEGRU FROM T082G
      WHERE FMUSS = 'X'
      AND FELEI = @GS_ANKA_FELEI-FELEI OR FELEI = @GS_ANKB_FELEI-FELEI
      INTO TABLE @DATA(GT_T082G) .

    SELECT TABNM , FLDNM FROM T082F
      FOR ALL ENTRIES IN @GT_T082G
      WHERE FEGTB = @GT_T082G-FEGTB
      AND FEGRU = @GT_T082G-FEGRU
      INTO TABLE @DATA(GT_T082F) .

    CLEAR GS_ANKB_FELEI .

    DELETE GT_T082F WHERE FLDNM = 'BUKRS'  OR FLDNM = 'ANLKL'
      OR FLDNM = 'TXT50' OR FLDNM = 'AFASL' OR FLDNM = 'NDJAR' OR FLDNM = 'NDPER' .


    LOOP AT GT_T082F INTO DATA(GS_T082F) .
      DATA(LV_FIELD_STR) = GS_T082F-FLDNM .
      DATA LV_FIELD_TEXT TYPE AS4TEXT .


      ASSIGN COMPONENT LV_FIELD_STR OF  STRUCTURE GS_TABLE_CHECK TO FIELD-SYMBOL(<FS_FIELD>).
      IF sy-subrc = 0.
        IF GS_TABLE_CHECK-(LV_FIELD_STR) IS INITIAL .
          SELECT SINGLE AS4LOCAL, AS4VERS, ROLLNAME
            FROM DD03L
            WHERE TABNAME = 'ZTFICO099'
            AND FIELDNAME = @LV_FIELD_STR
            INTO  @DATA(LS_ELEMENT) .
          SELECT SINGLE DDTEXT FROM DD04T
            WHERE AS4LOCAL = @LS_ELEMENT-AS4LOCAL
            AND AS4VERS = @LS_ELEMENT-AS4VERS
            AND DDLANGUAGE = '1'
            AND ROLLNAME = @LS_ELEMENT-ROLLNAME
            INTO @LV_FIELD_TEXT .
          MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中没有填写 { LV_FIELD_TEXT } 字段 | TYPE 'E' .
        ENDIF.
      ENDIF.

    ENDLOOP.

****************** 检查 AS01 屏幕中 必填的字段  **** END  ************


    IF GS_TABLE_CHECK-GDLGRP IS NOT INITIAL .

     DATA GV_ANLKL_CHECK TYPE ANLKL .
     DATA GV_ANLKL_COND TYPE STRING .

    GV_ANLKL_CHECK = GS_TABLE_CHECK-ANLKL .

    GV_ANLKL_COND = COND #( WHEN GV_ANLKL_CHECK(1) EQ 'B' THEN 'A' && GV_ANLKL_CHECK+1(3) && '%' ELSE GV_ANLKL_CHECK(4) && '%' ) .

     SELECT * FROM T087G INTO TABLE @DATA(GT_T087G)
       WHERE GDLGRP LIKE @GV_ANLKL_COND .
     IF SY-SUBRC <> 0.
        GV_ANLKL_COND = 'Z%'.
        SELECT * FROM T087G INTO TABLE @GT_T087G
          WHERE GDLGRP LIKE @GV_ANLKL_COND .
     ENDIF.

     READ TABLE GT_T087G WITH KEY GDLGRP = GS_TABLE_CHECK-GDLGRP  TRANSPORTING  NO FIELDS .
     IF SY-SUBRC <> 0.
       MESSAGE |唯一性号码 { GS_TABLE_CHECK-ZROWID } 对应数据中|
        && | 资产分类(小类) { GS_TABLE_CHECK-GDLGRP } 不属于资产类 { GV_ANLKL_CHECK } | TYPE 'E' .
     ENDIF.

   ENDIF.



  ENDLOOP.

ENDFORM .



FORM SET_QUERY_ALV_LVC_COLUMNS .

  CLEAR LS_FIELDCAT.
  LS_FIELDCAT-FIELDNAME = 'ZUUID'.
  LS_FIELDCAT-COLTEXT = '更新操作编码'.
  LS_FIELDCAT-SCRTEXT_S = '更新操作编码'.
  LS_FIELDCAT-SCRTEXT_M = '更新操作编码'.
  LS_FIELDCAT-SCRTEXT_L = '更新操作编码'.
  LS_FIELDCAT-OUTPUTLEN = 16.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZROWID'.
  LS_FIELDCAT-COLTEXT = '唯一性号码'.
  LS_FIELDCAT-SCRTEXT_S = '唯一性号码'.
  LS_FIELDCAT-SCRTEXT_M = '唯一性号码'.
  LS_FIELDCAT-SCRTEXT_L = '唯一性号码'.
  LS_FIELDCAT-OUTPUTLEN = 8.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'BUKRS'.
  LS_FIELDCAT-COLTEXT = '公司代码'.
  LS_FIELDCAT-SCRTEXT_S = '公司代码'.
  LS_FIELDCAT-SCRTEXT_M = '公司代码'.
  LS_FIELDCAT-SCRTEXT_L = '公司代码'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 4.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'BUTXT'.
  LS_FIELDCAT-COLTEXT = '公司名称'.
  LS_FIELDCAT-SCRTEXT_S = '公司名称'.
  LS_FIELDCAT-SCRTEXT_M = '公司名称'.
  LS_FIELDCAT-SCRTEXT_L = '公司名称'.
  LS_FIELDCAT-OUTPUTLEN = 25.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'ANLKL'.
  LS_FIELDCAT-COLTEXT = '资产大类'.
  LS_FIELDCAT-SCRTEXT_S = '资产大类'.
  LS_FIELDCAT-SCRTEXT_M = '资产大类'.
  LS_FIELDCAT-SCRTEXT_L = '资产大类'.
  LS_FIELDCAT-OUTPUTLEN = 8.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'ANLN1'.
  LS_FIELDCAT-COLTEXT = '资产编码'.
  LS_FIELDCAT-SCRTEXT_S = '资产编码'.
  LS_FIELDCAT-SCRTEXT_M = '资产编码'.
  LS_FIELDCAT-SCRTEXT_L = '资产编码'.
  LS_FIELDCAT-OUTPUTLEN = 12.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
  LS_FIELDCAT-HOTSPOT = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'ZRESULT'.
  LS_FIELDCAT-COLTEXT = '操作结果'.
  LS_FIELDCAT-SCRTEXT_S = '操作结果'.
  LS_FIELDCAT-SCRTEXT_M = '操作结果'.
  LS_FIELDCAT-SCRTEXT_L = '操作结果'.
  LS_FIELDCAT-OUTPUTLEN = 10.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY .
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'TXT50'.
  LS_FIELDCAT-COLTEXT = '资产描述'.
  LS_FIELDCAT-SCRTEXT_S = '资产描述'.
  LS_FIELDCAT-SCRTEXT_M = '资产描述'.
  LS_FIELDCAT-SCRTEXT_L = '资产描述'.
  LS_FIELDCAT-OUTPUTLEN = 50.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 6 .
  LS_FIELDCAT-FIELDNAME = 'TXA50'.
  LS_FIELDCAT-COLTEXT = '附加描述(规格型号)'.
  LS_FIELDCAT-SCRTEXT_S = '附加描述(规格型号)'.
  LS_FIELDCAT-SCRTEXT_M = '附加描述(规格型号)'.
  LS_FIELDCAT-SCRTEXT_L = '附加描述(规格型号)'.
  LS_FIELDCAT-OUTPUTLEN = 50.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'ANLHTXT'.
  LS_FIELDCAT-COLTEXT = '资产主号文本'.
  LS_FIELDCAT-SCRTEXT_S = '资产主号文本'.
  LS_FIELDCAT-SCRTEXT_M = '资产主号文本'.
  LS_FIELDCAT-SCRTEXT_L = '资产主号文本'.
  LS_FIELDCAT-OUTPUTLEN = 50.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'SERNR'.
  LS_FIELDCAT-COLTEXT = '序列号(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_S = '序列号(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_M = '序列号(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_L = '序列号(旧系统资产卡片号)'.
  LS_FIELDCAT-OUTPUTLEN = 18.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'MENGE'.
  LS_FIELDCAT-COLTEXT = '数量'.
  LS_FIELDCAT-SCRTEXT_S = '数量'.
  LS_FIELDCAT-SCRTEXT_M = '数量'.
  LS_FIELDCAT-SCRTEXT_L = '数量'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 18 .
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'MEINS'.
  LS_FIELDCAT-COLTEXT = '单位'.
  LS_FIELDCAT-SCRTEXT_S = '单位'.
  LS_FIELDCAT-SCRTEXT_M = '单位'.
  LS_FIELDCAT-SCRTEXT_L = '单位'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 3 .
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.



*  LS_FIELDCAT-COL_POS = 10 .
  LS_FIELDCAT-FIELDNAME = 'KOSTL'.
  LS_FIELDCAT-COLTEXT = '成本中心'.
  LS_FIELDCAT-SCRTEXT_S = '成本中心'.
  LS_FIELDCAT-SCRTEXT_M = '成本中心'.
  LS_FIELDCAT-SCRTEXT_L = '成本中心'.
  LS_FIELDCAT-OUTPUTLEN = 10.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'LTEXT1'.
  LS_FIELDCAT-COLTEXT = '成本中心描述'.
  LS_FIELDCAT-SCRTEXT_S = '成本中心描述'.
  LS_FIELDCAT-SCRTEXT_M = '成本中心描述'.
  LS_FIELDCAT-SCRTEXT_L = '成本中心描述'.
  LS_FIELDCAT-OUTPUTLEN = 40.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'PS_PSP_PNR2'.
  LS_FIELDCAT-COLTEXT = 'WBS 要素 '.
  LS_FIELDCAT-SCRTEXT_S = 'WBS 要素 '.
  LS_FIELDCAT-SCRTEXT_M = 'WBS 要素 '.
  LS_FIELDCAT-SCRTEXT_L = 'WBS 要素 '.
  LS_FIELDCAT-OUTPUTLEN = 24.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'POST1'.
  LS_FIELDCAT-COLTEXT = 'WBS要素描述'.
  LS_FIELDCAT-SCRTEXT_S = 'WBS要素描述'.
  LS_FIELDCAT-SCRTEXT_M = 'WBS要素描述'.
  LS_FIELDCAT-SCRTEXT_L = 'WBS要素描述'.
  LS_FIELDCAT-OUTPUTLEN = 40.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'KOSTLV'.
  LS_FIELDCAT-COLTEXT = '责任成本中心'.
  LS_FIELDCAT-SCRTEXT_S = '责任成本中心'.
  LS_FIELDCAT-SCRTEXT_M = '责任成本中心'.
  LS_FIELDCAT-SCRTEXT_L = '责任成本中心'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 10.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 13 .
  LS_FIELDCAT-FIELDNAME = 'LTEXT2'.
  LS_FIELDCAT-COLTEXT = '责任成本中心描述'.
  LS_FIELDCAT-SCRTEXT_S = '责任成本中心描述'.
  LS_FIELDCAT-SCRTEXT_M = '责任成本中心描述'.
  LS_FIELDCAT-SCRTEXT_L = '责任成本中心描述'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 40.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 16 .
  LS_FIELDCAT-FIELDNAME = 'KFZKZ'.
  LS_FIELDCAT-COLTEXT = '执照牌号'.
  LS_FIELDCAT-SCRTEXT_S = '执照牌号'.
  LS_FIELDCAT-SCRTEXT_M = '执照牌号'.
  LS_FIELDCAT-SCRTEXT_L = '执照牌号'.
  LS_FIELDCAT-OUTPUTLEN = 10.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'ORD41'.
  LS_FIELDCAT-COLTEXT = '增加方式'.
  LS_FIELDCAT-SCRTEXT_S = '增加方式'.
  LS_FIELDCAT-SCRTEXT_M = '增加方式'.
  LS_FIELDCAT-SCRTEXT_L = '增加方式'.
  LS_FIELDCAT-OUTPUTLEN = 4.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 28 .
  LS_FIELDCAT-FIELDNAME = 'ORDTX1'.
  LS_FIELDCAT-COLTEXT = '增加方式描述'.
  LS_FIELDCAT-SCRTEXT_S = '增加方式描述'.
  LS_FIELDCAT-SCRTEXT_M = '增加方式描述'.
  LS_FIELDCAT-SCRTEXT_L = '增加方式描述'.
  LS_FIELDCAT-OUTPUTLEN = 30.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 17 .
  LS_FIELDCAT-FIELDNAME = 'ORD42'.
  LS_FIELDCAT-COLTEXT = '税法折旧组'.
  LS_FIELDCAT-SCRTEXT_S = '税法折旧组'.
  LS_FIELDCAT-SCRTEXT_M = '税法折旧组'.
  LS_FIELDCAT-SCRTEXT_L = '税法折旧组'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 4.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 18 .
  LS_FIELDCAT-FIELDNAME = 'ORDTX2'.
  LS_FIELDCAT-COLTEXT = '税法折旧组描述'.
  LS_FIELDCAT-SCRTEXT_S = '税法折旧组描述'.
  LS_FIELDCAT-SCRTEXT_M = '税法折旧组描述'.
  LS_FIELDCAT-SCRTEXT_L = '税法折旧组描述'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 30.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 19 .
  LS_FIELDCAT-FIELDNAME = 'GDLGRP'.
  LS_FIELDCAT-COLTEXT = '资产分类(小类)'.
  LS_FIELDCAT-SCRTEXT_S = '资产分类(小类)'.
  LS_FIELDCAT-SCRTEXT_M = '资产分类(小类)'.
  LS_FIELDCAT-SCRTEXT_L = '资产分类(小类)'.
  LS_FIELDCAT-OUTPUTLEN = 8.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 20 .
  LS_FIELDCAT-FIELDNAME = 'GDLGRP_TXT'.
  LS_FIELDCAT-COLTEXT = '资产小类描述'.
  LS_FIELDCAT-SCRTEXT_S = '资产小类描述'.
  LS_FIELDCAT-SCRTEXT_M = '资产小类描述'.
  LS_FIELDCAT-SCRTEXT_L = '资产小类描述'.
  LS_FIELDCAT-OUTPUTLEN = 50.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'AIBN1'.
  LS_FIELDCAT-COLTEXT = '原始资产(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_S = '原始资产(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_M = '原始资产(旧系统资产卡片号)'.
  LS_FIELDCAT-SCRTEXT_L = '原始资产(旧系统资产卡片号)'.
  LS_FIELDCAT-OUTPUTLEN = 12.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'AFASL'.
  LS_FIELDCAT-COLTEXT = '折旧码'.
  LS_FIELDCAT-SCRTEXT_S = '折旧码'.
  LS_FIELDCAT-SCRTEXT_M = '折旧码'.
  LS_FIELDCAT-SCRTEXT_L = '折旧码'.
  LS_FIELDCAT-OUTPUTLEN = 4 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-FIELDNAME = 'NDJAR'.
  LS_FIELDCAT-COLTEXT = '资产使用年限（年）'.
  LS_FIELDCAT-SCRTEXT_S = '资产使用年限（年）'.
  LS_FIELDCAT-SCRTEXT_M = '资产使用年限（年）'.
  LS_FIELDCAT-SCRTEXT_L = '资产使用年限（年）'.
  LS_FIELDCAT-OUTPUTLEN = 3 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'NDPER'.
  LS_FIELDCAT-COLTEXT = '资产使用月份（月）'.
  LS_FIELDCAT-SCRTEXT_S = '资产使用月份（月）'.
  LS_FIELDCAT-SCRTEXT_M = '资产使用月份（月）'.
  LS_FIELDCAT-SCRTEXT_L = '资产使用月份（月）'.
  LS_FIELDCAT-OUTPUTLEN = 3 .
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 22 .
  LS_FIELDCAT-FIELDNAME = 'ZZPFWJH'.
  LS_FIELDCAT-COLTEXT = '集团招标文号'.
  LS_FIELDCAT-SCRTEXT_S = '集团招标文号'.
  LS_FIELDCAT-SCRTEXT_M = '集团招标文号'.
  LS_FIELDCAT-SCRTEXT_L = '集团招标文号'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 40.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 23 .
  LS_FIELDCAT-FIELDNAME = 'ZZCJH'.
  LS_FIELDCAT-COLTEXT = '车架号'.
  LS_FIELDCAT-SCRTEXT_S = '车架号'.
  LS_FIELDCAT-SCRTEXT_M = '车架号'.
  LS_FIELDCAT-SCRTEXT_L = '车架号'.
  LS_FIELDCAT-OUTPUTLEN = 17.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 24 .
  LS_FIELDCAT-FIELDNAME = 'ZZCFWZ'.
  LS_FIELDCAT-COLTEXT = '资产存放位置'.
  LS_FIELDCAT-SCRTEXT_S = '资产存放位置'.
  LS_FIELDCAT-SCRTEXT_M = '资产存放位置'.
  LS_FIELDCAT-SCRTEXT_L = '资产存放位置'.
  LS_FIELDCAT-OUTPUTLEN = 60.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 25 .
  LS_FIELDCAT-FIELDNAME = 'ZZAQFBM'.
  LS_FIELDCAT-COLTEXT = '专项储备编码'.
  LS_FIELDCAT-SCRTEXT_S = '专项储备编码'.
  LS_FIELDCAT-SCRTEXT_M = '专项储备编码'.
  LS_FIELDCAT-SCRTEXT_L = '专项储备编码'.
  LS_FIELDCAT-OUTPUTLEN = 10.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 26 .
  LS_FIELDCAT-FIELDNAME = 'ZAQFMS'.
  LS_FIELDCAT-COLTEXT = '专项储备编码描述'.
  LS_FIELDCAT-SCRTEXT_S = '专项储备编码描述'.
  LS_FIELDCAT-SCRTEXT_M = '专项储备编码描述'.
  LS_FIELDCAT-SCRTEXT_L = '专项储备编码描述'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 60.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ERNAM'.
  LS_FIELDCAT-COLTEXT = '创建人'.
  LS_FIELDCAT-SCRTEXT_S = '创建人'.
  LS_FIELDCAT-SCRTEXT_M = '创建人'.
  LS_FIELDCAT-SCRTEXT_L = '创建人'.
  LS_FIELDCAT-OUTPUTLEN = 12.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 32 .
  LS_FIELDCAT-FIELDNAME = 'NAME_TEXTC1'.
  LS_FIELDCAT-COLTEXT = '创建人名称'.
  LS_FIELDCAT-SCRTEXT_S = '创建人名称'.
  LS_FIELDCAT-SCRTEXT_M = '创建人名称'.
  LS_FIELDCAT-SCRTEXT_L = '创建人名称'.
  LS_FIELDCAT-OUTPUTLEN = 80.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

*  LS_FIELDCAT-COL_POS = 33 .
  LS_FIELDCAT-FIELDNAME = 'ZCDATE'.
  LS_FIELDCAT-COLTEXT = '创建日期'.
  LS_FIELDCAT-SCRTEXT_S = '创建日期'.
  LS_FIELDCAT-SCRTEXT_M = '创建日期'.
  LS_FIELDCAT-SCRTEXT_L = '创建日期'.
  LS_FIELDCAT-OUTPUTLEN = 8.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


*  LS_FIELDCAT-COL_POS = 34 .
  LS_FIELDCAT-FIELDNAME = 'ZCTIME'.
  LS_FIELDCAT-COLTEXT = '创建时间'.
  LS_FIELDCAT-SCRTEXT_S = '创建时间'.
  LS_FIELDCAT-SCRTEXT_M = '创建时间'.
  LS_FIELDCAT-SCRTEXT_L = '创建时间'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 6.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT..




  LS_FIELDCAT-FIELDNAME = 'ZMSGTYPE'.
  LS_FIELDCAT-COLTEXT = '消息标识'.
  LS_FIELDCAT-SCRTEXT_S = '消息标识'.
  LS_FIELDCAT-SCRTEXT_M = '消息标识'.
  LS_FIELDCAT-SCRTEXT_L = '消息标识'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 1.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZMSGCLS'.
  LS_FIELDCAT-COLTEXT = '消息类'.
  LS_FIELDCAT-SCRTEXT_S = '消息类'.
  LS_FIELDCAT-SCRTEXT_M = '消息类'.
  LS_FIELDCAT-SCRTEXT_L = '消息类'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 20.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.



  LS_FIELDCAT-FIELDNAME = 'ZMSGNUMBER'.
  LS_FIELDCAT-COLTEXT = '消息编号'.
  LS_FIELDCAT-SCRTEXT_S = '消息编号'.
  LS_FIELDCAT-SCRTEXT_M = '消息编号'.
  LS_FIELDCAT-SCRTEXT_L = '消息编号'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 3.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-FIELDNAME = 'ZMSGTEXT'.
  LS_FIELDCAT-COLTEXT = '消息文本'.
  LS_FIELDCAT-SCRTEXT_S = '消息文本'.
  LS_FIELDCAT-SCRTEXT_M = '消息文本'.
  LS_FIELDCAT-SCRTEXT_L = '消息文本'.
*  LS_FIELDCAT-REF_TABLE = 'ANLA'.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
  LS_FIELDCAT-OUTPUTLEN = 220.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT_QUERY.
  CLEAR LS_FIELDCAT.

  LOOP AT LT_FIELDCAT_QUERY ASSIGNING FIELD-SYMBOL(<FS_FIELDCAT>) .
    <FS_FIELDCAT>-COL_POS = SY-TABIX .
  ENDLOOP.


ENDFORM .



FORM SET_QUERY_COLOR .
  CLEAR: LS_CELLCOLOR, LT_CELLCOLOR.
  LOOP AT GT_QUERY_EXTEND ASSIGNING FIELD-SYMBOL(<FS_QUERY>).
    IF <FS_QUERY>-ZMSGTYPE = 'E' .
      ls_cellcolor-fname = 'ZRESULT'.
      ls_cellcolor-color-col = '6'.
      ls_cellcolor-color-int = '0'.
      ls_cellcolor-color-inv = '0'.
      INSERT ls_cellcolor INTO TABLE lt_cellcolor.
      <FS_QUERY>-CELL_COLOR = LT_CELLCOLOR.
    ENDIF.
  ENDLOOP.
ENDFORM .


FORM EN_LOCK .

  CALL FUNCTION 'ENQUEUE_EZFIR099LOCK'
   EXPORTING
     MODE_ZTFICO099       = 'X'
     BUKRS                = '0000'
*     X_BUKRS              = ' '
     _SCOPE               = '3'
*     _WAIT                = ' '
*     _COLLECT             = ' '
   EXCEPTIONS
     FOREIGN_LOCK         = 1
     SYSTEM_FAILURE       = 2
     OTHERS               = 3.
  IF sy-subrc <> 0.
    MESSAGE |其他人正在使用批量创建程序，请稍后再试 | TYPE 'E'.
  ENDIF.
ENDFORM .


FORM DE_LOCK.
  CALL FUNCTION 'DEQUEUE_EZFIR099LOCK'
   EXPORTING
     MODE_ZTFICO099       = 'X'
     BUKRS                = '0000'
     X_BUKRS              = ' '
     _SCOPE               = '3'
     _SYNCHRON            = ' '
     _COLLECT             = ' '.
  IF sy-subrc <> 0.
    MESSAGE | 解锁失败 | TYPE 'E'.
  ENDIF.
ENDFORM .