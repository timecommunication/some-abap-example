*&---------------------------------------------------------------------*
*& Report Z0703_THREAD_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0703_THREAD_H10009.
" 每个线程 查询 10000 行数据
CONSTANTS C_BATCH_ROWS TYPE I VALUE 10000.

DATA: GV_TASK_ID TYPE CHAR30,
      GV_OFFSET TYPE I.

DATA: GT_MARA TYPE TABLE OF ZROW_MARA_H10009,
      GT_MARA_TMP TYPE TABLE OF ZROW_MARA_H10009.

DATA: GV_START TYPE I,
      GV_END TYPE I.

SELECT SINGLE COUNT( MATNR ) FROM MARA INTO @DATA(GV_MARA_TOTAL).


START-OF-SELECTION .


WHILE GV_OFFSET < GV_MARA_TOTAL.

  GV_TASK_ID = |Z0703_THREAD_H10009_<{ GV_OFFSET }>|.
" 创建一个新线程，分配任务ID: GV_TASK_ID，
" 线程执行完后 执行 PERFORMING COLLECT_LT_MARA 函数
  CALL FUNCTION 'ZF_MARA_RFC_H10009'
    STARTING NEW TASK GV_TASK_ID
    PERFORMING COLLECT_LT_MARA ON END OF TASK

   EXPORTING
     IV_OFFSET       = GV_OFFSET
     IV_UPTO         = C_BATCH_ROWS
   TABLES
     T_MARA          = GT_MARA_TMP .



  ADD C_BATCH_ROWS TO GV_OFFSET.
  GV_START += 1.

ENDWHILE.


END-OF-SELECTION .

" 等待 所有线程 执行完成后 ，再继续执行，在 ALV 中 显示所有数据
WAIT UNTIL GV_START = GV_END .

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
   I_STRUCTURE_NAME                  = 'ZROW_MARA_H10009'
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
    T_OUTTAB                          = GT_MARA
 EXCEPTIONS
   PROGRAM_ERROR                     = 1
   OTHERS                            = 2
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.





*&---------------------------------------------------------------------*
*& Form COLLECT_LT_MARA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&
*& 当线程执行完 后 执行这个 回调函数
*&---------------------------------------------------------------------*
FORM COLLECT_LT_MARA  USING TASKNAME.

  DATA LT_MARA TYPE TABLE OF ZROW_MARA_H10009.

  RECEIVE RESULTS FROM FUNCTION 'ZF_MARA_RFC_H10009'
    TABLES
      T_MARA = LT_MARA.

  APPEND LINES OF LT_MARA TO GT_MARA.

  GV_END += 1.

ENDFORM.