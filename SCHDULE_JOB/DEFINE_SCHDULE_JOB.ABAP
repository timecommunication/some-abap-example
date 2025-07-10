*&---------------------------------------------------------------------*
*& Report Z0707_CODE_JOB_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0707_CODE_JOB_H10009.

DATA: GV_JOBNUM TYPE BTCJOBCNT,
      GV_JOBNAME TYPE BTCJOB VALUE 'Z0707_D_IN_CODE_H10009'.

" 定义一个定时任务 
CALL FUNCTION 'JOB_OPEN'
  EXPORTING
*   DELANFREP              = ' '
*   JOBGROUP               = ' '
    JOBNAME                = GV_JOBNAME
*   SDLSTRTDT              = NO_DATE
*   SDLSTRTTM              = NO_TIME
*   JOBCLASS               =
*   CHECK_JOBCLASS         =
 IMPORTING
   JOBCOUNT               = GV_JOBNUM
*   INFO                   =
* CHANGING
*   RET                    =
 EXCEPTIONS
   CANT_CREATE_JOB        = 1
   INVALID_JOB_DATA       = 2
   JOBNAME_MISSING        = 3
   OTHERS                 = 4
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.


" 声明定时任务 对应的程序：Z0627_HTTP_QUERY_H10009
SUBMIT Z0627_HTTP_QUERY_H10009 VIA JOB GV_JOBNAME
  NUMBER GV_JOBNUM AND RETURN.


IF SY-SUBRC = 0.

  CALL FUNCTION 'JOB_CLOSE'
    EXPORTING
*     AT_OPMODE                         = ' '
*     AT_OPMODE_PERIODIC                = ' '
*     CALENDAR_ID                       = ' '
*     EVENT_ID                          = ' '
*     EVENT_PARAM                       = ' '
*     EVENT_PERIODIC                    = ' '
      JOBCOUNT                          = GV_JOBNUM
      JOBNAME                           = GV_JOBNAME
*     LASTSTRTDT                        = NO_DATE
*     LASTSTRTTM                        = NO_TIME
*     PRDDAYS                           = 0
*     PRDHOURS                          = 0
*     PRDMINS                           = 0
*     PRDMONTHS                         = 0
*     PRDWEEKS                          = 0
*     PREDJOB_CHECKSTAT                 = ' '
*     PRED_JOBCOUNT                     = ' '
*     PRED_JOBNAME                      = ' '
*     SDLSTRTDT                         = NO_DATE
*     SDLSTRTTM                         = NO_TIME
*     STARTDATE_RESTRICTION             = BTC_PROCESS_ALWAYS
     STRTIMMED                         = 'X'
*     TARGETSYSTEM                      = ' '
*     START_ON_WORKDAY_NOT_BEFORE       = SY-DATUM
*     START_ON_WORKDAY_NR               = 0
*     WORKDAY_COUNT_DIRECTION           = 0
*     RECIPIENT_OBJ                     =
*     TARGETSERVER                      = ' '
*     DONT_RELEASE                      = ' '
*     TARGETGROUP                       = ' '
*     DIRECT_START                      =
*     INHERIT_RECIPIENT                 =
*     INHERIT_TARGET                    =
*     REGISTER_CHILD                    = ABAP_FALSE
*     TIME_ZONE                         =
*     EMAIL_NOTIFICATION                =
*   IMPORTING
*     JOB_WAS_RELEASED                  =
*   CHANGING
*     RET                               =
   EXCEPTIONS
     CANT_START_IMMEDIATE              = 1
     INVALID_STARTDATE                 = 2
     JOBNAME_MISSING                   = 3
     JOB_CLOSE_FAILED                  = 4
     JOB_NOSTEPS                       = 5
     JOB_NOTEX                         = 6
     LOCK_FAILED                       = 7
     INVALID_TARGET                    = 8
     INVALID_TIME_ZONE                 = 9
     OTHERS                            = 10
            .
  IF SY-SUBRC <> 0.
* Implement suitable error handling here
    MESSAGE 'JOB ERROR' TYPE 'E'.
  ELSE.
    MESSAGE 'JOB SUCCESS' TYPE 'S'.
  ENDIF.

  WRITE: | FINISH { GV_JOBNAME } DEFINITION |.

ENDIF.



" 下面这个定义完任务后，修改了 任务 对应的用户名
CLEAR: GV_JOBNUM, GV_JOBNAME.
GV_JOBNAME = 'Z0707_D&M_IN_CODE_H10009'.

CALL FUNCTION 'JOB_OPEN'
  EXPORTING
*   DELANFREP              = ' '
*   JOBGROUP               = ' '
    JOBNAME                = GV_JOBNAME
*   SDLSTRTDT              = NO_DATE
*   SDLSTRTTM              = NO_TIME
*   JOBCLASS               =
*   CHECK_JOBCLASS         =
 IMPORTING
   JOBCOUNT               = GV_JOBNUM
*   INFO                   =
* CHANGING
*   RET                    =
 EXCEPTIONS
   CANT_CREATE_JOB        = 1
   INVALID_JOB_DATA       = 2
   JOBNAME_MISSING        = 3
   OTHERS                 = 4
          .

IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.


SUBMIT Z0627_HTTP_QUERY_H10009 VIA JOB GV_JOBNAME
  NUMBER GV_JOBNUM AND RETURN.

DATA: GS_JOBHEAD TYPE TBTCJOB,
      GT_JOBSTEP TYPE STANDARD TABLE OF TBTCSTEP.

CALL FUNCTION 'BP_JOB_READ'
  EXPORTING
    JOB_READ_JOBCOUNT           = GV_JOBNUM
    JOB_READ_JOBNAME            = GV_JOBNAME
    JOB_READ_OPCODE             = '20'
*   JOB_STEP_NUMBER             =
 IMPORTING
   JOB_READ_JOBHEAD            = GS_JOBHEAD
*   JOBLOG_ATTRIBUTES           =
*   EPP_ATTRIBUTES              =
*   EMAIL_NOTIFICATION          =
 TABLES
   JOB_READ_STEPLIST           = GT_JOBSTEP
*   SPOOL_ATTRIBUTES            =
* CHANGING
*   RET                         =
 EXCEPTIONS
   INVALID_OPCODE              = 1
   JOB_DOESNT_EXIST            = 2
   JOB_DOESNT_HAVE_STEPS       = 3
   OTHERS                      = 4
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.
" 修改用户名为：BASIS
GS_JOBHEAD-SDLUNAME = 'BASIS'.



CALL FUNCTION 'BP_JOB_MODIFY'
  EXPORTING
    DIALOG                           = 'N'
   JOBCOUNT                         = GV_JOBNUM
   JOBNAME                          = GV_JOBNAME
   NEW_JOBHEAD                      = GS_JOBHEAD
   OPCODE                           = '16'
*   RELEASE_STDT                     = INITIAL_STDT
*   RELEASE_TARGETSYSTEM             = ' '
*   SUPPRESS_RELEASE_CHECK           = ' '
*   ADK_MODE                         = FALSE
*   RECIPIENT_OBJ                    =
*   RELEASE_TARGETSERVER             = ' '
*   DONT_RELEASE                     = ' '
*   TARGETGROUP                      = ' '
*   DIRECT_START                     =
*   JOBCLASS                         =
*   EMAIL_NOTIFICATION               =
 IMPORTING
   MODIFIED_JOBHEAD                 = GS_JOBHEAD
  TABLES
    NEW_STEPLIST                     = GT_JOBSTEP
* CHANGING
*   RET                              =
*   EMSG                             =
 EXCEPTIONS
   CANT_DERELEASE_JOB               = 1
   CANT_ENQ_JOB                     = 2
   CANT_READ_JOBDATA                = 3
   CANT_RELEASE_JOB                 = 4
   CANT_SET_JOBSTATUS_IN_DB         = 5
   CANT_START_JOB_IMMEDIATELY       = 6
   CANT_UPDATE_JOBDATA              = 7
   EVENTCNT_GENERATION_ERROR        = 8
   INVALID_DIALOG_TYPE              = 9
   INVALID_NEW_JOBDATA              = 10
   INVALID_NEW_JOBSTATUS            = 11
   INVALID_OPCODE                   = 12
   INVALID_STARTDATE                = 13
   JOB_EDIT_FAILED                  = 14
   JOB_MODIFY_CANCELED              = 15
   JOB_NOT_MODIFIABLE_ANYMORE       = 16
   NOTHING_TO_DO                    = 17
   NO_BATCH_ON_TARGET_HOST          = 18
   NO_BATCH_SERVER_FOUND            = 19
   NO_BATCH_WP_FOR_JOBCLASS         = 20
   NO_MODIFY_PRIVILEGE_GIVEN        = 21
   NO_RELEASE_PRIVILEGE_GIVEN       = 22
   NO_STARTDATE_NO_RELEASE          = 23
   TARGET_HOST_NOT_DEFINED          = 24
   TGT_HOST_CHK_HAS_FAILED          = 25
   INVALID_TARGETGROUP              = 26
   CONFLICTING_TARGETS              = 27
   OTHERS                           = 28
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
ENDIF.



CALL FUNCTION 'JOB_CLOSE'
  EXPORTING
*   AT_OPMODE                         = ' '
*   AT_OPMODE_PERIODIC                = ' '
*   CALENDAR_ID                       = ' '
*   EVENT_ID                          = ' '
*   EVENT_PARAM                       = ' '
*   EVENT_PERIODIC                    = ' '
    JOBCOUNT                          = GV_JOBNUM
    JOBNAME                           = GV_JOBNAME
*   LASTSTRTDT                        = NO_DATE
*   LASTSTRTTM                        = NO_TIME
*   PRDDAYS                           = 0
*   PRDHOURS                          = 0
*   PRDMINS                           = 0
*   PRDMONTHS                         = 0
*   PRDWEEKS                          = 0
*   PREDJOB_CHECKSTAT                 = ' '
*   PRED_JOBCOUNT                     = ' '
*   PRED_JOBNAME                      = ' '
*   SDLSTRTDT                         = NO_DATE
*   SDLSTRTTM                         = NO_TIME
*   STARTDATE_RESTRICTION             = BTC_PROCESS_ALWAYS
   STRTIMMED                         = 'X'
*   TARGETSYSTEM                      = ' '
*   START_ON_WORKDAY_NOT_BEFORE       = SY-DATUM
*   START_ON_WORKDAY_NR               = 0
*   WORKDAY_COUNT_DIRECTION           = 0
*   RECIPIENT_OBJ                     =
*   TARGETSERVER                      = ' '
*   DONT_RELEASE                      = ' '
*   TARGETGROUP                       = ' '
*   DIRECT_START                      =
*   INHERIT_RECIPIENT                 =
*   INHERIT_TARGET                    =
*   REGISTER_CHILD                    = ABAP_FALSE
*   TIME_ZONE                         =
*   EMAIL_NOTIFICATION                =
* IMPORTING
*   JOB_WAS_RELEASED                  =
* CHANGING
*   RET                               =
 EXCEPTIONS
   CANT_START_IMMEDIATE              = 1
   INVALID_STARTDATE                 = 2
   JOBNAME_MISSING                   = 3
   JOB_CLOSE_FAILED                  = 4
   JOB_NOSTEPS                       = 5
   JOB_NOTEX                         = 6
   LOCK_FAILED                       = 7
   INVALID_TARGET                    = 8
   INVALID_TIME_ZONE                 = 9
   OTHERS                            = 10
          .
IF SY-SUBRC <> 0.
* Implement suitable error handling here
  MESSAGE 'JOB ERROR' TYPE 'E'.
ELSE.
  MESSAGE 'JOB SUCCESS' TYPE 'S'.
  WRITE: /, | FINISH { GV_JOBNAME } DEFINITION |.
ENDIF.