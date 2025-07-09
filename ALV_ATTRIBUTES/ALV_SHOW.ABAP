*&---------------------------------------------------------------------*
*& Report Z0619_MARA_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0619_MARA_H10009.

TYPES: BEGIN OF TY_MARA,

  MANDT TYPE MANDT,
  MATNR TYPE MATNR ,
  ERSDA TYPE ERSDA,
  CREATED_AT_TIME TYPE CREATED_AT_TIME,
  ERNAM TYPE ERNAM,
  LAEDA TYPE LAEDA,
  AENAM TYPE AENAM,
  VPSTA TYPE VPSTA,
  PSTAT TYPE PSTAT_D,
  MTART TYPE MTART,
  MBRSH TYPE MBRSH,
  MATKL TYPE MATKL,
  BISMT TYPE BISMT,
  MEINS TYPE MEINS,
  MAKTX TYPE MAKTX ,
  CHECK_BOX TYPE CHAR1,
  row_color          TYPE char4                  , "用来设置 行颜色
  cell_color         TYPE lvc_t_scol             , "用来设置 单元格颜色
  cell_style         TYPE lvc_t_styl             , "用来设置 单元格编辑

END OF TY_MARA.

DATA: GT_MARA TYPE TABLE OF TY_MARA,
      GS_MARA TYPE TY_MARA.

FIELD-SYMBOLS:  <FS_MARA> TYPE TY_MARA.



DATA: LT_FIELDCAT TYPE lvc_t_fcat,
      LS_FIELDCAT TYPE lvc_s_fcat.

DATA: lt_cellcolor TYPE lvc_t_scol,
      ls_cellcolor TYPE lvc_s_scol.



DATA LO_GRID TYPE REF TO CL_GUI_ALV_GRID.
DATA LS_STABLE TYPE LVC_S_STBL.
" 刷新 ALV 时候，设置 行 列 稳定
LS_STABLE-ROW = 'X'.
LS_STABLE-COL = 'X'.

DATA: LT_EVENT TYPE slis_t_event,
      LS_EVENT TYPE slis_alv_event.

" 设置可编辑字段 被编辑后 立刻触发修改的回调函数
DATA LS_SETTING TYPE LVC_S_GLAY.
LS_SETTING-EDT_CLL_CB = 'X'.


PERFORM SET_ALV_FIELDCAT.
PERFORM FORM_REGISTER_EVENT.

DATA: LS_LAYOUT TYPE lvc_s_layo.
LS_LAYOUT-ZEBRA = 'X'.       " 斑马条纹
LS_LAYOUT-CWIDTH_OPT = 'X'.  " 设置列优化
" 布局结构中的 特殊字段声明
LS_LAYOUT-info_fname     = 'ROW_COLOR'.  "行颜色代码的 字段名称
LS_LAYOUT-ctab_fname   = 'CELL_COLOR'. "单元格颜色内表 字段名称
LS_LAYOUT-STYLEFNAME = 'CELL_STYLE'.  " 单元格可编辑设置 字段名称

DATA(GV_CHECK_COLOR) = 'C300'.




SELECT
  MARA~MANDT ,
  MARA~MATNR  ,
  ERSDA ,
  CREATED_AT_TIME ,
  ERNAM ,
  LAEDA ,
  AENAM ,
  VPSTA ,
  PSTAT ,
  MTART ,
  MBRSH ,
  MATKL ,
  BISMT ,
  MEINS ,
  MAKTX
  FROM MARA
   JOIN MAKT
  ON MARA~MATNR = MAKT~MATNR
  AND MAKT~SPRAS = 1
  WHERE MAKT~MAKTX <> ''
  ORDER BY MARA~MATNR ASCENDING
  INTO CORRESPONDING FIELDS OF TABLE @GT_MARA
  UP TO 400 ROWS.



LOOP AT GT_MARA ASSIGNING <FS_MARA>.

  CLEAR: LS_CELLCOLOR, LT_CELLCOLOR.
"   如果物料组 不是 01 ，设置这个单元格为 红色
  IF <FS_MARA>-MATKL <> '01'.
    ls_cellcolor-fname = 'MATKL'.
    ls_cellcolor-color-col = '6'.
    ls_cellcolor-color-int = '1'.
    ls_cellcolor-color-inv = '0'.
    INSERT ls_cellcolor INTO TABLE lt_cellcolor.
  ENDIF.
  <FS_MARA>-CELL_COLOR = LT_CELLCOLOR.

"   如果 物料编码中 包含 6 ，设置这一行为 橙色
  IF <FS_MARA>-MATNR CS '6'.
    <FS_MARA>-ROW_COLOR = 'C711'.
  ENDIF.


ENDLOOP.





CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
 EXPORTING
*   I_INTERFACE_CHECK                 = ' '
*   I_BYPASSING_BUFFER                =
*   I_BUFFER_ACTIVE                   =
   I_CALLBACK_PROGRAM                = SY-REPID
   I_CALLBACK_PF_STATUS_SET          = 'PF_STATUS_SET'
   I_CALLBACK_USER_COMMAND           = 'USER_COMMAND'
*   I_CALLBACK_TOP_OF_PAGE            = ' '
*   I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*   I_CALLBACK_HTML_END_OF_LIST       = ' '
*   I_STRUCTURE_NAME                  =
*   I_BACKGROUND_ID                   = ' '
*   I_GRID_TITLE                      =
   I_GRID_SETTINGS                   = LS_SETTING
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
   IT_EVENTS                         = LT_EVENT
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
* EXCEPTIONS
*   PROGRAM_ERROR                     = 1
*   OTHERS                            = 2
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.

" 获取 ALV 对象实例
CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
*     EXPORTING
*       IR_SALV_FULLSCREEN_ADAPTER       =
     IMPORTING
*       ET_EXCLUDING                     =
*       E_REPID                          =
*       E_CALLBACK_PROGRAM               =
*       E_CALLBACK_ROUTINE               =
       E_GRID                           = LO_GRID
*       ET_FIELDCAT_LVC                  =
*       ER_TRACE                         =
*       E_FLG_NO_HTML                    =
*       ES_LAYOUT_KKBLO                  =
*       ES_SEL_HIDE                      =
*       ET_EVENT_EXIT                    =
*       ER_FORM_TOL                      =
*       ER_FORM_EOL                      =
              .




*&---------------------------------------------------------------------*
*& Form SET_ALV_FIELDCAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_ALV_FIELDCAT .


  LS_FIELDCAT-COL_POS = 10.
  LS_FIELDCAT-FIELDNAME = 'CHECK_BOX'.
  LS_FIELDCAT-COLTEXT = '选择'.
  LS_FIELDCAT-SCRTEXT_S = '选择'.
  LS_FIELDCAT-SCRTEXT_M = '选择'.
  LS_FIELDCAT-SCRTEXT_L = '选择'.
  " 设置为 选择框
  LS_FIELDCAT-CHECKBOX = 'X'. 
  LS_FIELDCAT-OUTPUTLEN = 1.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = ''.
  " 设置 选择框 为可编辑状态
  LS_FIELDCAT-EDIT = 'X'. 
*  LS_FIELDCAT-EMPHASIZE = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-COL_POS = 20.
  LS_FIELDCAT-FIELDNAME = 'MANDT'.
  LS_FIELDCAT-COLTEXT = '客户端'.
  LS_FIELDCAT-FIX_COLUMN = 'X'.
  LS_FIELDCAT-KEY = 'X'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-COL_POS = 30.
  LS_FIELDCAT-FIELDNAME = 'MATNR'.
  LS_FIELDCAT-COLTEXT = '物料编号'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = 'X'.
"   设置为 热键 ， 可跳转其他事务
  LS_FIELDCAT-HOTSPOT = 'X'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-COL_POS = 31.
  LS_FIELDCAT-FIELDNAME = 'MAKTX'.
  LS_FIELDCAT-COLTEXT = '物料描述'.
  LS_FIELDCAT-FIX_COLUMN = ''.
"   设置为 可编辑
  LS_FIELDCAT-EDIT = 'X'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 40.
  LS_FIELDCAT-FIELDNAME = 'ERSDA'.
  LS_FIELDCAT-COLTEXT = '创建日期'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-COL_POS = 50.
  LS_FIELDCAT-FIELDNAME = 'CREATED_AT_TIME'.
  LS_FIELDCAT-COLTEXT = '创建时间'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 51.
  LS_FIELDCAT-FIELDNAME = 'MATKL'.
  LS_FIELDCAT-COLTEXT = '物料组'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.



  LS_FIELDCAT-COL_POS = 52.
  LS_FIELDCAT-FIELDNAME = 'BISMT'.
  LS_FIELDCAT-COLTEXT = '旧物料号'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 60.
  LS_FIELDCAT-FIELDNAME = 'ERNAM'.
  LS_FIELDCAT-COLTEXT = '负责创建对象的人员姓名'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
*  LS_FIELDCAT-EDIT = 'X'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 70.
  LS_FIELDCAT-FIELDNAME = 'LAEDA'.
  LS_FIELDCAT-COLTEXT = '上次更改的日期'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 80.
  LS_FIELDCAT-FIELDNAME = 'AENAM'.
  LS_FIELDCAT-COLTEXT = '更改对象的人员姓名'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 90.
  LS_FIELDCAT-FIELDNAME = 'VPSTA'.
  LS_FIELDCAT-COLTEXT = '维护全部物料状态'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 100.
  LS_FIELDCAT-FIELDNAME = 'PSTAT'.
  LS_FIELDCAT-COLTEXT = '维护状态'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 110.
  LS_FIELDCAT-FIELDNAME = 'LVORM'.
  LS_FIELDCAT-COLTEXT = '在客户级标记要删除的物料'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = 120.
  LS_FIELDCAT-FIELDNAME = 'MTART'.
  LS_FIELDCAT-COLTEXT = '物料类型'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-COL_POS = 130.
  LS_FIELDCAT-FIELDNAME = 'MBRSH'.
  LS_FIELDCAT-COLTEXT = '行业'.
  LS_FIELDCAT-FIX_COLUMN = ''.
  LS_FIELDCAT-KEY = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.






ENDFORM.

*&---------------------------------------------------------------------*
*& Form PF_STATUS_SET
*&---------------------------------------------------------------------*
*& 设置 GUI STATUS 菜单的函数
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM PF_STATUS_SET USING RT_EXTAB TYPE SLIS_T_EXTAB .
  SET PF-STATUS 'GUI_STATUS'.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form USER_COMMAND
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM USER_COMMAND USING R_UCOMM LIKE SY-UCOMM
                        RS_SELFIELD TYPE SLIS_SELFIELD.

  CASE R_UCOMM.
    WHEN '&IC1'.
    "   单击事件 处理，判断是否是 物料编码 被点击，
    "    如果是， 跳转 MM03 事务中 查看数据
      READ TABLE GT_MARA INTO GS_MARA INDEX RS_SELFIELD-TABINDEX.
      IF SY-SUBRC = 0.
        IF RS_SELFIELD-FIELDNAME = 'MATNR'.
          SET PARAMETER ID 'MXX' FIELD 'K'.
          SET PARAMETER ID 'MAT' FIELD GS_MARA-MATNR.
          CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
        ENDIF.
      ENDIF.

    WHEN '&AHI'.
      MESSAGE '你好' TYPE 'I'.

   ENDCASE.

ENDFORM.



*&---------------------------------------------------------------------*
*& Form FORM_REGISTER_EVENT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
" ALV 事件 注册函数，数据被修改时触发 HANDLE_DATA_CHANGING 子例程
FORM FORM_REGISTER_EVENT .
  LS_EVENT-NAME = SLIS_EV_DATA_CHANGED.
  LS_EVENT-FORM = 'HANDLE_DATA_CHANGING'.
  APPEND LS_EVENT TO LT_EVENT.
ENDFORM.



*&---------------------------------------------------------------------*
*& Form HANDLE_DATA_CHANGING
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM HANDLE_DATA_CHANGING USING P_DATA_CHANGED TYPE REF TO cl_alv_changed_data_protocol.

  DATA: LT_CHANGE TYPE lvc_t_modi,
        LS_CHANGE  TYPE lvc_s_modi.

" 声明 设置单元格是否可编辑的 结构 和 内表
  DATA:gwa_edit TYPE lvc_s_styl,
       git_edit TYPE lvc_t_styl.


" 获取到 ALV 实例，后面用于刷新 ALV
  IF LO_GRID IS INITIAL.
    CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
*     EXPORTING
*       IR_SALV_FULLSCREEN_ADAPTER       =
     IMPORTING
*       ET_EXCLUDING                     =
*       E_REPID                          =
*       E_CALLBACK_PROGRAM               =
*       E_CALLBACK_ROUTINE               =
       E_GRID                           = LO_GRID
*       ET_FIELDCAT_LVC                  =
*       ER_TRACE                         =
*       E_FLG_NO_HTML                    =
*       ES_LAYOUT_KKBLO                  =
*       ES_SEL_HIDE                      =
*       ET_EVENT_EXIT                    =
*       ER_FORM_TOL                      =
*       ER_FORM_EOL                      =
              .
    ENDIF.

" 获取被修改的 单元格数据
  LT_CHANGE = p_data_changed->mt_mod_cells.

  LOOP AT LT_CHANGE INTO LS_CHANGE.
    CLEAR: GWA_EDIT, GIT_EDIT.
    IF LS_CHANGE-fieldname = 'CHECK_BOX'.
      READ TABLE GT_MARA INDEX LS_CHANGE-ROW_ID INTO GS_MARA.
      IF sy-subrc = 0.
        IF GS_MARA-CHECK_BOX = abap_false. " 原来为空，已经修改为 true
        "   如果 这一行的选择框 被选中 将 ERNAM 单元格 设置为 可编辑
          gwa_edit-fieldname = 'ERNAM'.
          gwa_edit-style = cl_gui_alv_grid=>mc_style_enabled."设置为可编辑
*          GS_MARA-ROW_COLOR = GV_CHECK_COLOR.
          APPEND GWA_EDIT TO GIT_EDIT.
          GS_MARA-CELL_STYLE = GIT_EDIT.
          MODIFY GT_MARA FROM GS_MARA INDEX LS_CHANGE-ROW_ID  .

        ELSE.
*          CLEAR GS_MARA-ROW_COLOR.
          CLEAR: gwa_edit.
          gwa_edit-fieldname = 'ERNAM'.
          gwa_edit-style = cl_gui_alv_grid=>mc_style_disabled."设置为不可编辑
          APPEND GWA_EDIT TO GIT_EDIT.
          GS_MARA-CELL_STYLE = GIT_EDIT.
          MODIFY GT_MARA FROM GS_MARA INDEX LS_CHANGE-ROW_ID  .
*          MESSAGE | { LS_CHANGE-row_id } - { GS_TABLE-ANLN1 } F | TYPE 'S' DISPLAY LIKE 'W'.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.




*  CALL METHOD lo_grid->set_frontend_fieldcatalog
*    EXPORTING
*      it_fieldcatalog = LT_FIELDCAT.


" 修改数据后 刷新 ALV 显示
  CALL METHOD LO_GRID->REFRESH_TABLE_DISPLAY
    EXPORTING
        IS_STABLE = LS_STABLE
        i_soft_refresh = 'X'..

ENDFORM.