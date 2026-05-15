*&---------------------------------------------------------------------*
*& Report TRANSPORT_COPY_OF_REQUEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT TRANSPORT_COPY_OF_REQUEST.

TYPE-POOLS:trwbo,stms.

TABLES:e07t,e070.

DATA:lt_e071            TYPE tr_objects,
     lt_e071k           TYPE tr_keys,
     lt_users           TYPE scts_users,
     ls_request_header  TYPE trwbo_request_header,
     lt_request_headers TYPE TABLE OF trwbo_request_header.
DATA ls_syst TYPE syst.

DATA:ls_request_from TYPE trwbo_request_header,
     ls_request_to   TYPE trwbo_request_header,
     ls_e07t         TYPE e07t,
     ls_user         LIKE LINE OF lt_users.

DATA:es_request TYPE trwbo_request.


DATA f_msg_text(80).
DATA lt_request_infos TYPE stms_wbo_requests.
DATA ls_request_infos TYPE LINE OF stms_wbo_requests.

DATA s_transport_request TYPE e070.
DATA s_request_text TYPE e07t.

*************************************************

PARAMETERS p_trkorr TYPE trdyse01sn-tr_trkorr.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_trkorr.

  PERFORM value_trkorr.

START-OF-SELECTION.

  CONDENSE p_trkorr NO-GAPS.

  SELECT SINGLE *
    FROM e070
    INTO CORRESPONDING FIELDS OF ls_request_from
    WHERE trkorr EQ p_trkorr.

  ls_request_from-trkorr = p_trkorr.

  CALL FUNCTION 'TR_READ_REQUEST_WITH_TASKS'
    EXPORTING
      iv_trkorr          = p_trkorr
    IMPORTING
      et_request_headers = lt_request_headers
    EXCEPTIONS
      invalid_input      = 1
      OTHERS             = 2.

  LOOP AT lt_request_headers INTO ls_request_header
    WHERE NOT tarsystem IS INITIAL.
    ls_request_from-tarsystem = ls_request_header-tarsystem.
    EXIT.
  ENDLOOP.

* 获取请求号中的对象
  CALL FUNCTION 'TR_GET_OBJECTS_OF_REQ_AN_TASKS'
    EXPORTING
      is_request_header      = ls_request_from
      iv_condense_objectlist = 'X'
    IMPORTING
      et_objects             = lt_e071
      et_keys                = lt_e071k
    EXCEPTIONS
      invalid_input          = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    RAISE no_old_object.
  ENDIF.

  DELETE lt_e071 WHERE pgmid EQ 'CORR'.

  SELECT *
    INTO ls_e07t
    UP TO 1 ROWS
    FROM e07t
    WHERE trkorr EQ p_trkorr.
  ENDSELECT.

  CONCATENATE
    'Copy of'(010)
    p_trkorr '-'
    ls_e07t-as4text
    INTO ls_e07t-as4text
    SEPARATED BY space.

* create new request
  CALL FUNCTION 'TR_INSERT_REQUEST_WITH_TASKS'
    EXPORTING
      iv_type           = 'T'
      iv_text           = ls_e07t-as4text
      iv_target         = ls_request_from-tarsystem
      it_users          = lt_users
    IMPORTING
      es_request_header = ls_request_to
    EXCEPTIONS
      insert_failed     = 1
      enqueue_failed    = 2
      OTHERS            = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    PERFORM delete_new_request USING ls_request_to-trkorr.

    RAISE new_request.
  ENDIF.


* append object of old request to new request
  CALL FUNCTION 'TR_REQUEST_CHOICE'
    EXPORTING
      iv_suppress_dialog   = 'X'
      iv_request           = ls_request_to-trkorr
      it_e071              = lt_e071
      it_e071k             = lt_e071k
    IMPORTING
      es_request           = ls_request_to
    EXCEPTIONS
      invalid_request      = 1
      invalid_request_type = 2
      user_not_owner       = 3
      no_objects_appended  = 4
      enqueue_error        = 5
      cancelled_by_user    = 6
      recursive_call       = 7
      OTHERS               = 8.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    PERFORM delete_new_request USING ls_request_to-trkorr.
    RAISE append_objects.
  ENDIF.




*fill instance attribute  s_transport_request
  SELECT SINGLE * FROM e070 INTO s_transport_request
                  WHERE trkorr = ls_request_to-trkorr.

  IF sy-subrc <> 0.
    CALL FUNCTION 'TMS_MGR_READ_TRANSPORT_REQUEST'
      EXPORTING
        iv_request                 = ls_request_to-trkorr
*       IV_TARGET_SYSTEM           =
*       IV_DOCU_ONLY               =
*       IV_HEADER_ONLY             =
*       IV_MONITOR                 = 'X'
*       IV_VERBOSE                 =
*       IS_QUEUE                   =
*       IT_REQUESTS                =
      IMPORTING
        et_request_infos           = lt_request_infos
      EXCEPTIONS
        read_config_failed         = 1
        table_of_requests_is_empty = 2
        system_not_available       = 3
        OTHERS                     = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*     MESSAGE e806(tr) WITH if_transport_request RAISING not_exists.
    ELSE.
      LOOP AT lt_request_infos INTO ls_request_infos WHERE e070-trkorr IS NOT INITIAL..
        MOVE ls_request_infos-e07t TO s_request_text.
        MOVE ls_request_infos-e070 TO s_transport_request.
        EXIT.
      ENDLOOP.
      IF sy-subrc IS NOT INITIAL.
        MESSAGE e806(tr) WITH p_trkorr RAISING not_exists.
      ENDIF.
    ENDIF.


  ELSE.
*fill instance attribute S_REQUEST_TEXT
    SELECT SINGLE * FROM e07t
                    INTO s_request_text
                    WHERE trkorr = ls_request_to-trkorr.
  ENDIF.

  WRITE ls_request_to-trkorr.

* release new request
  CALL FUNCTION 'TR_RELEASE_REQUEST'
    EXPORTING
      iv_trkorr                  = ls_request_to-trkorr
      iv_dialog                  = 'X'
*     IV_AS_BACKGROUND_JOB       = ' '
*     IV_SUCCESS_MESSAGE         = 'X'
      iv_display_export_log      = ' '
* IMPORTING
*     ES_REQUEST                 =
*     ET_DELETED_TASKS           =
    EXCEPTIONS
      cts_initialization_failure = 1
      enqueue_failed             = 2
      no_authorization           = 3
      invalid_request            = 4
      request_already_released   = 5
      repeat_too_early           = 6
      object_check_error         = 7
      docu_missing               = 8
      db_access_error            = 9
      action_aborted_by_user     = 10
      export_failed              = 11
      OTHERS                     = 12.
  IF sy-subrc <> 0.
    ls_syst = sy.
    PERFORM delete_new_request USING ls_request_to-trkorr.
    MESSAGE ID ls_syst-msgid TYPE 'S' NUMBER ls_syst-msgno
           WITH ls_syst-msgv1 ls_syst-msgv2 ls_syst-msgv3 ls_syst-msgv4  RAISING release_request.
  ELSE.
    MESSAGE i888(sabapdocu) WITH '复制的请求号' ls_request_to-trkorr '已经释放'.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  delete_new_request
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM delete_new_request USING p_trkorr.
  CALL FUNCTION 'TR_DELETE_COMM'
    EXPORTING
      wi_dialog                     = ' '
      wi_trkorr                     = p_trkorr
*   IMPORTING
*     ET_DELETED_TASKS              =
    EXCEPTIONS
      file_access_error             = 1
      order_already_released        = 2
      order_contains_c_member       = 3
      order_contains_locked_entries = 4
      order_is_refered              = 5
      repair_order                  = 6
      user_not_owner                = 7
      delete_was_cancelled          = 8
      ordernumber_empty             = 9
      tr_enqueue_failed             = 10
      objects_free_but_still_locks  = 11
      order_lock_failed             = 12
      no_authorization              = 13
      wrong_client                  = 14
      project_still_referenced      = 15
      successors_already_released   = 16
      OTHERS                        = 17.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM. "delete_new_request
*&---------------------------------------------------------------------*
*&      Form  VALUE_TRKORR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM value_trkorr .
  DATA: lv_trfunctions LIKE  trpari-w_longstat,
        lv_trstatus    LIKE  trpari-w_longstat,
        lv_trkorr      TYPE  e070-trkorr,
        ls_dynpfield   LIKE dynpread,
        lt_dynpfields  LIKE dynpread    OCCURS 0.

  CALL FUNCTION 'TR_F4_REQUESTS'
    EXPORTING
      iv_username         = space
      iv_trkorr_pattern   = lv_trkorr
      iv_trfunctions      = lv_trfunctions
      iv_trstatus         = lv_trstatus
    IMPORTING
      ev_selected_request = lv_trkorr.
  p_trkorr = lv_trkorr.
ENDFORM. " VALUE_TRKORR