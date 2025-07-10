*&---------------------------------------------------------------------*
*& Report Z0704_EVENT_JOB_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0704_EVENT_JOB_H10009.

" 触发 ZEVENT_0704_H10009 这个事件，与 这个事件相关联的 定时任务也会执行
" 事件 在 SM62 中创建
CALL FUNCTION 'BP_EVENT_RAISE'
  EXPORTING
    EVENTID                      = 'ZEVENT_0704_H10009'
*   EVENTPARM                    = ' '
*   TARGET_INSTANCE              = ' '
*   TARGET_MODE                  = ' '
 EXCEPTIONS
   BAD_EVENTID                  = 1
   EVENTID_DOES_NOT_EXIST       = 2
   EVENTID_MISSING              = 3
   RAISE_FAILED                 = 4
   OTHERS                       = 5
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
  WRITE: 'FAILED TO TRIGGER EVENT'.
ELSE.
  WRITE: 'EVENT TRIGGERED'.
ENDIF.