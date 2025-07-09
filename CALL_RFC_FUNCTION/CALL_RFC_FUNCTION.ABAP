*&---------------------------------------------------------------------*
*& Report Z0624_RFC_QUERY_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0624_RFC_QUERY_H10009.

DATA: GT_PERSON TYPE TABLE OF ZTPERSON_H10009,
      GV_STATUS TYPE CHAR20.

DATA: LT_FIELDCAT TYPE lvc_t_fcat,
      LS_FIELDCAT TYPE lvc_s_fcat.
PERFORM SET_ALV_FIELDCAT.

PARAMETERS:

  P_USERID TYPE ZE_ZUSERID,
  P_NAME TYPE ZE_ZNAME,
  P_GENDER TYPE ZE_ZGENDER.


" 调用 RFC 函数 ZF_QUERY_PERSON_H10009 查询当前表中数据
" 在 事务码 SM59 中 配置好 RFC连接 Z120TO200_H10009
CALL FUNCTION 'ZF_QUERY_PERSON_H10009' DESTINATION 'Z120TO200_H10009'
 EXPORTING
   IV_ZUSERID       = P_USERID
   IV_ZNAME         = P_NAME
   IV_ZGENDER       = P_GENDER
 IMPORTING
   EV_STATUS        = GV_STATUS
 TABLES
   ET_PERSON        = GT_PERSON.

IF GV_STATUS = 'SUCCESS'.
  MESSAGE 'RFC 查询成功 ' TYPE 'S'.
ELSE.

  MESSAGE 'RFC 查询失败 ' TYPE 'E'.
ENDIF.



CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
 EXPORTING
*   I_INTERFACE_CHECK                 = ' '
*   I_BYPASSING_BUFFER                =
*   I_BUFFER_ACTIVE                   =
   I_CALLBACK_PROGRAM                = SY-REPID
   I_CALLBACK_PF_STATUS_SET          = 'SET_STATUS'
   I_CALLBACK_USER_COMMAND           = 'USER_COMMAND'
*   I_CALLBACK_TOP_OF_PAGE            = ' '
*   I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*   I_CALLBACK_HTML_END_OF_LIST       = ' '
*   I_STRUCTURE_NAME                  =
*   I_BACKGROUND_ID                   = ' '
*   I_GRID_TITLE                      =
*   I_GRID_SETTINGS                   =
*   IS_LAYOUT_LVC                     =
   IT_FIELDCAT_LVC                   =  LT_FIELDCAT
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
    T_OUTTAB                          = GT_PERSON
 EXCEPTIONS
   PROGRAM_ERROR                     = 1
   OTHERS                            = 2
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.



FORM SET_ALV_FIELDCAT .


  LS_FIELDCAT-COL_POS = 10.
  LS_FIELDCAT-FIELDNAME = 'ZUSERID'.
  LS_FIELDCAT-COLTEXT = '身份证'.
  LS_FIELDCAT-OUTPUTLEN = 18.
*  LS_FIELDCAT-FIX_COLUMN = 'X'.
*  LS_FIELDCAT-KEY = ''.
  LS_FIELDCAT-EDIT = 'X'.
*  LS_FIELDCAT-EMPHASIZE = ''.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-COL_POS = 20.
  LS_FIELDCAT-FIELDNAME = 'ZNAME'.
  LS_FIELDCAT-COLTEXT = '姓名'.
*  LS_FIELDCAT-FIX_COLUMN = 'X'.
*  LS_FIELDCAT-KEY = 'X'.
    LS_FIELDCAT-EDIT = 'X'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.


  LS_FIELDCAT-COL_POS = 30.
  LS_FIELDCAT-FIELDNAME = 'ZGENDER'.
  LS_FIELDCAT-COLTEXT = '性别'.
*  LS_FIELDCAT-FIX_COLUMN = ''.
*  LS_FIELDCAT-KEY = 'X'.
  LS_FIELDCAT-EDIT = 'X'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.
  CLEAR LS_FIELDCAT.
ENDFORM.

FORM SET_STATUS USING RT_EXTAB TYPE SLIS_T_EXTAB .
  SET PF-STATUS 'GUI_STATUS'.
ENDFORM.

FORM USER_COMMAND USING R_UCOMM LIKE SY-UCOMM
                        RS_SELFIELD TYPE SLIS_SELFIELD.
  CASE R_UCOMM.
    WHEN '&AM'.
      DATA GV_MODIFY_STATUS TYPE CHAR20.
      " 调用 RFC 函数 ZF_MODIFY_PERSON_H10009 修改当前表中数据
      CALL FUNCTION 'ZF_MODIFY_PERSON_H10009' DESTINATION 'Z120TO200_H10009'
       IMPORTING
         EV_STATUS       = GV_MODIFY_STATUS
       TABLES
         IT_PERSON       = GT_PERSON[]    .

      IF GV_MODIFY_STATUS = 'SUCCESS'.
        MESSAGE '保存成功' TYPE 'I'.
      ELSE.
        MESSAGE '保存失败' TYPE 'I'.
      ENDIF.
  ENDCASE.
ENDFORM.