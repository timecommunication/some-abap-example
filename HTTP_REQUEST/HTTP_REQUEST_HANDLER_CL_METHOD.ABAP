  method IF_HTTP_EXTENSION~HANDLE_REQUEST.
"  这个方法是 CLIENT 200 中 ZCL0627_HTTP_H10009 类
"   中的 IF_HTTP_EXTENSION~HANDLE_REQUEST 方法的实现
" 用来处理 HTTP 请求

  TYPES:
           BEGIN OF TY_PERSON,
             ZUSERID TYPE ZE_ZUSERID,
             ZNAME TYPE ZE_ZNAME,
             ZGENDER TYPE ZE_ZGENDER,
           END OF TY_PERSON.

    DATA: lt_data TYPE TABLE OF ZTPERSON_H10009,
          lt_PERSON  TYPE TABLE OF TY_PERSON,
          ls_PERSON  TYPE TY_PERSON.

    DATA: R_ZUSERID  TYPE RANGE OF ZE_ZUSERID,
          RS_ZUSERID LIKE LINE OF R_ZUSERID,
          R_ZNAME TYPE RANGE OF ZE_ZNAME,
          RS_ZNAME LIKE LINE OF R_ZNAME,
          R_ZGENDER TYPE RANGE OF ZE_ZGENDER,
          RS_ZGENDER LIKE LINE OF R_ZGENDER.

    DATA: lt_form_fields   TYPE tihttpnvp, "请求url参数
          lt_header_fields TYPE tihttpnvp, "请求头部数据
          lv_method        TYPE string,    "请求类型
          lv_request       TYPE string,    "请求json数据
          lv_response      TYPE string.    "返回json数据

    "请求类型
    lv_method = server->request->get_method(  ).

    "请求url参数
    server->request->get_form_fields( CHANGING fields = lt_form_fields ).

    "请求头部数据
    server->request->get_header_fields( CHANGING fields = lt_header_fields ).

    "请求json数据
    lv_request = server->request->get_cdata( ).

    "json转 ABAP内表
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request
                               CHANGING data = lt_PERSON ).

    "将内表数据转成 range 用作查询条件
    LOOP AT LT_PERSON INTO LS_PERSON.
      IF LS_PERSON-ZUSERID IS NOT INITIAL.
        RS_ZUSERID-SIGN = 'I'.
        RS_ZUSERID-OPTION = 'EQ'.
        RS_ZUSERID-LOW = LS_PERSON-ZUSERID.
        APPEND RS_ZUSERID TO R_ZUSERID.
      ENDIF.
      IF LS_PERSON-ZNAME IS NOT INITIAL.
        RS_ZNAME-SIGN = 'I'.
        RS_ZNAME-OPTION = 'EQ'.
        RS_ZNAME-LOW = LS_PERSON-ZNAME.
        APPEND RS_ZNAME TO R_ZNAME.
      ENDIF.
      IF LS_PERSON-ZGENDER IS NOT INITIAL.
        RS_ZGENDER-SIGN = 'I'.
        RS_ZGENDER-OPTION = 'EQ'.
        RS_ZGENDER-LOW = LS_PERSON-ZGENDER.
        APPEND RS_ZGENDER TO R_ZGENDER.
      ENDIF.
*      lrs_mat-sign = 'I'.
*      lrs_mat-option = 'EQ'.
*      lrs_mat-low = ls_mat-matnr.
*      APPEND lrs_mat TO lr_mat.
    ENDLOOP.


    CASE lv_method.

      WHEN 'GET'.

        SELECT ZUSERID ZNAME ZGENDER INTO CORRESPONDING FIELDS OF TABLE lt_data
          FROM ZTPERSON_H10009
          UP TO 10 ROWS
           WHERE ZUSERID IN R_ZUSERID
           AND ZNAME IN R_ZNAME
           AND ZGENDER IN R_ZGENDER.
*               WHERE spras = sy-langu
*               AND matnr IN lr_mat.

        "abap内表 转换json 字符串
        /ui2/cl_json=>serialize( EXPORTING data   = lt_data
                                 RECEIVING r_json = lv_response ).

        "返回json数据给调用端
        server->response->set_cdata( EXPORTING data = lv_response ).

        "请求响应
        server->response->set_status( code = 200 reason = 'OK' ).


      WHEN OTHERS.

        "如果不是get请求，则返回错误
        server->response->set_status( code = 405 reason = 'ERROR' ).


    ENDCASE.

*    TYPES: BEGIN OF ty_data,
*             matnr TYPE matnr,
*             maktx TYPE maktx,
*           END OF ty_data,
*
*           BEGIN OF ty_mat,
*             matnr TYPE matnr,
*           END OF ty_mat.
*
*    DATA: lt_data TYPE TABLE OF ty_data,
*          lt_mat  TYPE TABLE OF ty_mat,
*          ls_mat  TYPE ty_mat.
*
*    DATA: lr_mat  TYPE RANGE OF matnr,
*          lrs_mat LIKE LINE OF lr_mat.
*
*    DATA: lt_form_fields   TYPE tihttpnvp, "请求url参数
*          lt_header_fields TYPE tihttpnvp, "请求头部数据
*          lv_method        TYPE string,    "请求类型
*          lv_request       TYPE string,    "请求json数据
*          lv_response      TYPE string.    "返回json数据
*
*    "请求类型
*    lv_method = server->request->get_method(  ).
*
*    "请求url参数
*    server->request->get_form_fields( CHANGING fields = lt_form_fields ).
*
*    "请求头部数据
*    server->request->get_header_fields( CHANGING fields = lt_header_fields ).
*
*    "请求json数据
*    lv_request = server->request->get_cdata( ).
*
*    "json转abap
*    /ui2/cl_json=>deserialize( EXPORTING json = lv_request
*                               CHANGING data = lt_mat ).
*
*    "将内表数据转成range用作查询条件
*    LOOP AT lt_mat INTO ls_mat.
*      lrs_mat-sign = 'I'.
*      lrs_mat-option = 'EQ'.
*      lrs_mat-low = ls_mat-matnr.
*      APPEND lrs_mat TO lr_mat.
*    ENDLOOP.
*
*    CASE lv_method.
*      WHEN 'GET'.
*
*        SELECT matnr maktx INTO CORRESPONDING FIELDS OF TABLE lt_data
*               FROM makt
*               UP TO 10 ROWS
*               WHERE spras = sy-langu
*               AND matnr IN lr_mat.
*
*        "abap转换json
*        /ui2/cl_json=>serialize( EXPORTING data   = lt_data
*                                 RECEIVING r_json = lv_response ).
*
*        "返回json数据给调用端
*        server->response->set_cdata( EXPORTING data = lv_response ).
*
*        "请求响应
*        server->response->set_status( code = 200 reason = 'OK' ).
*      WHEN OTHERS.
*
*        "如果不是get请求，则返回错误
*        server->response->set_status( code = 405 reason = 'ERROR' ).
*
*
*    ENDCASE.

  endmethod.