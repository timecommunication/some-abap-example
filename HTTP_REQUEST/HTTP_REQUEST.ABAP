*&---------------------------------------------------------------------*
*& Report Z0627_HTTP_QUERY_H10009
*&---------------------------------------------------------------------*
*& 这个程序在 CLIENT 120 中 发送请求
*&---------------------------------------------------------------------*
REPORT Z0627_HTTP_QUERY_H10009.
TABLES: sscrfields.
DATA: lv_url TYPE string.

DATA: lv_response TYPE string,
      message     TYPE string.

DATA: json_ser TYPE REF TO cl_trex_json_serializer.

DATA: lo_http_client  TYPE REF TO if_http_client.

DATA: lv_appid     TYPE string,
      lv_secret    TYPE string,
      lv_data      TYPE string,
      lv_appkey    TYPE string,
      lv_appsecret TYPE string,
      lv_timestamp TYPE string.

DATA: lv_json_str TYPE string.
DATA: LT_PERSON TYPE TABLE OF ZTPERSON_H10009.


SELECTION-SCREEN BEGIN OF BLOCK BK1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
  P_USERID TYPE ZE_ZUSERID,
  P_NAME TYPE ZE_ZNAME,
  P_GENDER TYPE ZE_ZGENDER.
SELECTION-SCREEN END OF BLOCK BK1.



SELECTION-SCREEN BEGIN OF BLOCK BK2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
  PUSERID TYPE ZE_ZUSERID,
  PNAME TYPE ZE_ZNAME,
  PGENDER TYPE ZE_ZGENDER.
SELECTION-SCREEN END OF BLOCK BK2.

SELECTION-SCREEN: FUNCTION KEY 1.


INITIALIZATION.
  sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id = ICON_MODIFICATION_CREATE
                                            quickinfo = '使用 POST 请求创建 & 修改人员数据'
                                            icon_text = '使用 POST 请求创建 & 修改人员数据' ).
"  CLIENT 200 中的 HTTP 服务地址
  CONSTANTS CV_URL TYPE STRING VALUE 'http://172.16.113.100:8000/sap/bc/zhttp_h10009?sap-client=200'.
  CALL METHOD cl_http_client=>create_by_url
    EXPORTING
      url                = CV_URL  "外部接口地址
    IMPORTING
      client             = lo_http_client
    EXCEPTIONS
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      OTHERS             = 4.


" 如果 需要设置密码认证 在这里设置
*  CALL METHOD lo_http_client->authenticate(
*    EXPORTING
*      username = ''
*      password = ''
*  ).




" 设置 请求头
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'Content-Type'
      value = 'application/json;charset=utf-8'.


AT SELECTION-SCREEN.

  IF SY-UCOMM = 'FC01'.
    lv_json_str = '[{' &&
                  '"ZUSERID":"' && PUSERID && '",' &&
                  '"ZNAME":"' && PNAME && '",' &&
                  '"ZGENDER":"' && PGENDER && '"' &&
                 '}]'.
    DATA(lv_len) = strlen( lv_json_str ).
    CALL METHOD lo_http_client->request->set_cdata
      EXPORTING
        data   = lv_json_str
        offset = 0
        length = lv_len.
    "设定调用服务 POST 请求
    lo_http_client->request->set_method( if_http_request=>co_request_method_POST ).
    "发送请求
    lo_http_client->send(  EXCEPTIONS http_communication_failure = 1
      http_invalid_state         = 2 ).
    IF sy-subrc <> 0.
      "操作失败，获取失败原因
      lo_http_client->get_last_error( IMPORTING message = message ).
      EXIT.
    ENDIF.
    "读取远程服务返回的处理过结果
    lo_http_client->receive( EXCEPTIONS http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3 ).
    DATA(lv_respon) = lo_http_client->response->get_cdata( ).
    IF LV_RESPON CS '成功'.
      MESSAGE LV_RESPON TYPE 'S'.
    ELSE.
      MESSAGE LV_RESPON TYPE 'E'.
    ENDIF.

  ENDIF.




START-OF-SELECTION.




*    "设置待传输内容

lv_json_str = '[{' &&
              '"ZUSERID":"' && P_USERID && '",' &&
              '"ZNAME":"' && P_NAME && '",' &&
              '"ZGENDER":"' && P_GENDER && '"' &&
             '}]'.
DATA(lv_len) = strlen( lv_json_str ).
CALL METHOD lo_http_client->request->set_cdata
  EXPORTING
    data   = lv_json_str
    offset = 0
    length = lv_len.



"设定调用服务 GET 请求
lo_http_client->request->set_method( if_http_request=>co_request_method_get ).

"发送请求
lo_http_client->send(  EXCEPTIONS http_communication_failure = 1
  http_invalid_state         = 2 ).

IF sy-subrc <> 0.
  "操作失败，获取失败原因
  lo_http_client->get_last_error( IMPORTING message = message ).
  EXIT.
ENDIF.
*
"读取远程服务返回的处理过结果。
lo_http_client->receive( EXCEPTIONS http_communication_failure = 1
  http_invalid_state         = 2
  http_processing_failed     = 3 ).

DATA(lv_respon) = lo_http_client->response->get_cdata( ).

"json转abap
 /ui2/cl_json=>deserialize( EXPORTING json = lv_respon
                            CHANGING data = LT_PERSON ).

WRITE lv_respon.
SKIP.

LOOP AT LT_PERSON INTO DATA(LS_PERSON).
  WRITE: '身份证：', LS_PERSON-ZUSERID,
         ' 姓名：', LS_PERSON-ZNAME,
         '性别：', LS_PERSON-ZGENDER, /.
ENDLOOP.




*
"认证
*lo_http_client->propertytype_logon_popup = lo_http_client->co_disabled.

*设置header
*    CALL METHOD lo_http_client->request->set_header_field
*      EXPORTING
*        name  = 'appid'
*        value = lv_appid.


"设定传输请求内容格式以及编码格式
*  lo_http_client->request->set_content_type( content_type = 'application/json; charset=utf-8' ).


*

*IF sy-subrc <> 0 .
*  "lv_subrc = sy-subrc.
*  lo_http_client->get_last_error( IMPORTING message = message ).
**    code = 0.
**      EXIT.
*ELSE.
*  "读取返回返回内容
**    CLEAR lv_respon.
**    code = 1.
**  DATA(lv_respon) = lo_http_client->response->get_cdata( ).
**      ev_respon = lv_respon.
**      /ui2/cl_json=>deserialize( EXPORTING json = lv_respon assoc_arrays = abap_true
**      CHANGING data = ls_redata ). "ls_exp是返回参数结构
*ENDIF.