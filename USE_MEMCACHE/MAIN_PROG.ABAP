*&---------------------------------------------------------------------*
*& Report Z0702_MAIN_PROG_H10009
*&---------------------------------------------------------------------*
*& 调用子程序中 缓存写入的过程 ，在这个程序中读取缓存，输出在 ALV 中
*&---------------------------------------------------------------------*
REPORT Z0702_MAIN_PROG_H10009.

DATA GT_DATA TYPE REF TO DATA.

DATA: GV_DATA TYPE REF TO DATA.
FIELD-SYMBOLS: <GFS_DATA_TABLE> TYPE TABLE,
               <GFS_DATA> TYPE DATA.

TYPES: BEGIN OF TY_MARA,
  MATNR TYPE MATNR,
  ERSDA TYPE ERSDA,
  MAKTX TYPE MAKTX,
  END OF TY_MARA.

TYPES: BEGIN OF TY_MARA_BUKRS,
  INCLUDE TYPE TY_MARA,
  BUKRS TYPE BUKRS,
END OF TY_MARA_BUKRS.

DATA: GT_MARA TYPE TABLE OF TY_MARA ,
      GT_MARA_20 TYPE TABLE OF TY_MARA,
      GT_MARA_8 TYPE TABLE OF TY_MARA.
" DEMO_INDX_TABLE 是 SAP 的一个系统表，正式场景中用 INDX 表
DATA WA_INDX TYPE DEMO_INDX_TABLE.

DATA GV_TITLE TYPE LVC_TITLE.

DATA: LT_FIELDCAT TYPE lvc_t_fcat,
      LS_FIELDCAT TYPE lvc_s_fcat.


DATA: LS_LAYOUT TYPE lvc_s_layo.
LS_LAYOUT-ZEBRA = 'X'.
LS_LAYOUT-CWIDTH_OPT = 'X'.


CALL METHOD CL_SALV_BS_RUNTIME_INFO=>SET
  EXPORTING
    DISPLAY        = ABAP_FALSE
    METADATA       = ABAP_FALSE
    DATA           = ABAP_TRUE
*    STRUCTURE      =
*    STRUCTURE_LINE =
    .

" 调用 Z0702_SUBPROG_MARA_H10009 这个 ALV 程序，对 参数 P_NUM 传入 10 ， AND RETURN 表示返回当前主程序
SUBMIT Z0702_SUBPROG_MARA_H10009 WITH P_NUM = 10 AND RETURN.

************** 从 ALV 程序中 获取内表数据 **********************
TRY.

*  TRY.
  CALL METHOD CL_SALV_BS_RUNTIME_INFO=>GET_DATA_REF
    IMPORTING
      R_DATA            = GV_DATA
*      R_DATA_LINE       =
*      R_DATA_DESCR      =
*      R_DATA_LINE_DESCR =
      .
*    CATCH CX_SALV_BS_SC_RUNTIME_INFO.
*  ENDTRY.
    ASSIGN GV_DATA->* TO <GFS_DATA>.

  CATCH CX_SALV_BS_SC_RUNTIME_INFO.
    MESSAGE 'UNABLE TO GET ALV DATA' TYPE 'E'.
ENDTRY.

CALL METHOD CL_SALV_BS_RUNTIME_INFO=>CLEAR_ALL.

MOVE-CORRESPONDING <GFS_DATA> TO GT_MARA.

***************************************************************

" 调用 Z0702_SUBPROG_MARA_H10009 程序中的 FILL_MAKTX_FIELD 子例程
PERFORM FILL_MAKTX_FIELD(Z0702_SUBPROG_MARA_H10009) CHANGING GT_MARA.

" 调用 Z0702_SUBPROG_MARA_H10009 程序中的 EXPORT_20_ROWS_TO_DATABASE 子例程
PERFORM EXPORT_20_ROWS_TO_DATABASE(Z0702_SUBPROG_MARA_H10009).

" 从缓存表中 导入 20 条数据
IMPORT TAB = GT_MARA_20 FROM DATABASE DEMO_INDX_TABLE(SQ) TO WA_INDX ID 'ZMEM_MARA_20'.

APPEND LINES OF GT_MARA_20 TO GT_MARA.


" 从 SAP 缓存中导入 内表数据
IMPORT GT_MARA_8 FROM MEMORY ID 'ZMEM_MARA_8'.

APPEND LINES OF GT_MARA_8 TO GT_MARA.


" 设置 BUK 字段缓存 值 为 1000
SET PARAMETER ID 'BUK' FIELD '1000'.
CALL TRANSACTION 'Z0702_H10009' AND  SKIP FIRST SCREEN.
" 从 BTX 字段缓存 中取值给 LV_BUKTXT
GET PARAMETER ID 'BTX' FIELD DATA(LV_BUKTXT).

GV_TITLE = |{ LV_BUKTXT } 物料数据 |.

PERFORM SET_ALV_LVC_COLUMNS.

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
 EXPORTING
*   I_INTERFACE_CHECK                 = ' '
*   I_BYPASSING_BUFFER                =
*   I_BUFFER_ACTIVE                   =
*   I_CALLBACK_PROGRAM                = ' '
*   I_CALLBACK_PF_STATUS_SET          = ' '
*   I_CALLBACK_USER_COMMAND           = ' '
*   I_CALLBACK_TOP_OF_PAGE            = ' '
*   I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*   I_CALLBACK_HTML_END_OF_LIST       = ' '
*   I_STRUCTURE_NAME                  = ' '
*   I_BACKGROUND_ID                   = ' '
   I_GRID_TITLE                      = GV_TITLE
*   I_GRID_SETTINGS                   =
   IS_LAYOUT_LVC                     = LS_LAYOUT
   IT_FIELDCAT_LVC                   = LT_FIELDCAT
*   IT_EXCLUDING                      =
*   IT_SPECIAL_GROUPS_LVC             =
*   IT_SORT_LVC                       =
*   IT_FILTER_LVC                     =
*   IT_HYPERLINK                      =
*   IS_SEL_HIDE                       =
*   I_DEFAULT                         = 'X'
*   I_SAVE                            = ' '
*   IS_VARIANT                        =
*   IT_EVENTS                         =
*   IT_EVENT_EXIT                     =
*   IS_PRINT_LVC                      =
*   IS_REPREP_ID_LVC                  =
*   I_SCREEN_START_COLUMN             = 0
*   I_SCREEN_START_LINE               = 0
*   I_SCREEN_END_COLUMN               = 0
*   I_SCREEN_END_LINE                 = 0
*   I_HTML_HEIGHT_TOP                 =
*   I_HTML_HEIGHT_END                 =
*   IT_ALV_GRAPHICS                   =
*   IT_EXCEPT_QINFO_LVC               =
* IMPORTING
*   E_EXIT_CAUSED_BY_CALLER           =
*   ES_EXIT_CAUSED_BY_USER            =
  TABLES
    T_OUTTAB                          = GT_MARA
 EXCEPTIONS
   PROGRAM_ERROR                     = 1
   OTHERS                            = 2
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.


FORM SET_ALV_LVC_COLUMNS.


  LS_FIELDCAT-COL_POS = 1.
  LS_FIELDCAT-FIELDNAME = 'MATNR'.
  LS_FIELDCAT-COLTEXT = '物料编码'.
*  LS_FIELDCAT-REF_TABLE = ''.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
*  LS_FIELDCAT-OUTPUTLEN = 4.
*  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 2.
  LS_FIELDCAT-FIELDNAME = 'ERSDA'.
  LS_FIELDCAT-COLTEXT = '创建日期'.
*  LS_FIELDCAT-REF_TABLE = ''.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
*  LS_FIELDCAT-OUTPUTLEN = 4.
*  LS_FIELDCAT-FIX_COLUMN = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 3.
  LS_FIELDCAT-FIELDNAME = 'MAKTX'.
  LS_FIELDCAT-COLTEXT = '物料描述'.
*  LS_FIELDCAT-REF_TABLE = ''.
*  LS_FIELDCAT-REF_FIELD = 'BUKRS'.
*  LS_FIELDCAT-OUTPUTLEN = 4.
*  LS_FIELDCAT-FIX_COLUMN = 'X'.
*  LS_FIELDCAT-EMPHASIZE = 'C110'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

ENDFORM.