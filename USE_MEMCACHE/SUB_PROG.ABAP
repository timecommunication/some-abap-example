*&---------------------------------------------------------------------*
*& Report Z0702_SUBPROG_MARA_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0702_SUBPROG_MARA_H10009.

TYPES: BEGIN OF TY_MARA,
  MATNR TYPE MATNR,
  ERSDA TYPE ERSDA,
  MAKTX TYPE MAKTX,
  END OF TY_MARA.

DATA GT_MARA_8 TYPE TABLE OF TY_MARA.

PARAMETERS: P_NUM TYPE I.


SELECT * FROM MARA
  ORDER BY MATNR
  INTO TABLE @DATA(LT_MATNR)
   UP TO @P_NUM ROWS
  OFFSET 200.

PERFORM EXPORT_8_ROWS_TO_MEM.

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
   I_STRUCTURE_NAME                  = 'MARA'
*   I_BACKGROUND_ID                   = ' '
*   I_GRID_TITLE                      =
*   I_GRID_SETTINGS                   =
*   IS_LAYOUT_LVC                     =
*   IT_FIELDCAT_LVC                   =
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
    T_OUTTAB                          = LT_MATNR
* EXCEPTIONS
*   PROGRAM_ERROR                     = 1
*   OTHERS                            = 2
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.







FORM FILL_MAKTX_FIELD CHANGING CT_MATNR   .
" 填充 物料描述 字段
  IF CT_MATNR IS INITIAL.
    RETURN.
  ENDIF.

  DATA LT_MATNR TYPE TABLE OF TY_MARA.
  DATA LT_MAKTX TYPE TABLE OF TY_MARA.

  LT_MATNR = CT_MATNR.

  SORT LT_MATNR BY MATNR .
  SELECT MATNR, MAKTX FROM MAKT
    FOR ALL ENTRIES IN @LT_MATNR
    WHERE MATNR = @LT_MATNR-MATNR
    AND SPRAS = '1'
    INTO  TABLE @DATA(LT_MAKT).
  LOOP AT LT_MATNR ASSIGNING FIELD-SYMBOL(<FS_MATNR>).
    READ TABLE LT_MAKT INTO DATA(LS_MAKT) WITH KEY MATNR = <FS_MATNR>-MATNR.
    IF SY-SUBRC = 0.
      <FS_MATNR>-MAKTX = LS_MAKT-MAKTX.
    ENDIF.
  ENDLOOP.
  CT_MATNR = LT_MATNR.
ENDFORM.



" EXPORT TO DATABASE
FORM EXPORT_20_ROWS_TO_DATABASE.
  DATA WA_INDX TYPE DEMO_INDX_TABLE.
  DATA LT_MARA_20 TYPE TABLE OF TY_MARA.
  SELECT MATNR , ERSDA FROM MARA
    ORDER BY MATNR
    INTO TABLE @LT_MARA_20
     UP TO 20 ROWS OFFSET 1000.

  PERFORM FILL_MAKTX_FIELD CHANGING LT_MARA_20.
  " 导入内表数据到 DEMO_INDX_TABLE 缓存表中
  EXPORT TAB = LT_MARA_20 TO DATABASE DEMO_INDX_TABLE(SQ) FROM WA_INDX ID  'ZMEM_MARA_20'.

ENDFORM.


" EXPORT TO  MEMORY
FORM EXPORT_8_ROWS_TO_MEM.
  SELECT MARA~MATNR , MARA~ERSDA , MAKT~MAKTX
  FROM MARA
  JOIN MAKT
  ON MARA~MATNR = MAKT~MATNR
  AND MAKT~SPRAS = '1'
  ORDER BY MARA~MATNR
  INTO TABLE @GT_MARA_8
  UP TO 8 ROWS
  OFFSET 800.
" 导入 内表数据到 SAP缓存中
  EXPORT GT_MARA_8 TO MEMORY ID 'ZMEM_MARA_8'.
ENDFORM.