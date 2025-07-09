*&---------------------------------------------------------------------*
*& Report Z0630_CLASSSQL_H10009
*&---------------------------------------------------------------------*
*& 使用对象的方式 连接 操作 数据库
*&---------------------------------------------------------------------*
REPORT Z0630_CLASSSQL_H10009.

DATA: BEGIN OF gs_temp,
        ZUSERID TYPE ZE_ZUSERID,
        ZNAME TYPE ZE_ZNAME,
        ZGENDER TYPE ZE_ZGENDER,
      END OF gs_temp.
DATA: gt_temp LIKE TABLE OF gs_temp.
DATA conn TYPE dbcon-con_name.
DATA: gv_sql TYPE string.

START-OF-SELECTION.
  gv_sql = 'SELECT ZUSERID, ZNAME, ZGENDER FROM ZTPERSON_H10009'.
  PERFORM frm_get_data_adbc_simple.

*  PERFORM frm_get_data_adbc.


  cl_demo_output=>display( gt_temp ).



*&---------------------------------------------------------------------*
*& Form FRM_GET_DATA_ADBC
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_get_data_adbc .
  DATA: r_adbc_conn   TYPE REF TO  cl_sql_connection,
        r_adbc_query  TYPE REF TO  cl_sql_statement,
        r_metadata    TYPE REF TO  data,
        it_metadata   TYPE         adbc_rs_metadata_descr_tab,
        lv_len        TYPE         i,
        lv_off        TYPE         i,
        wa_metadata   LIKE LINE OF it_metadata,
        r_adbc_result TYPE REF TO  cl_sql_result_set,
        r_tabletype   TYPE REF TO  cl_abap_tabledescr,
        r_cxadbc      TYPE REF TO  cx_dba_adbc,
        r_cxsql       TYPE REF TO  cx_sql_exception,
        tabix_n(4)    TYPE n,
        column_names  TYPE HASHED TABLE OF adbc_name WITH UNIQUE KEY table_line.
  DATA:         lv_stmt_type      TYPE string.
  DATA:
    ex_structdescr TYPE REF TO  cl_abap_structdescr,
    ex_result_ref  TYPE REF TO data.
*获取sql语句的类型
  lv_stmt_type = cl_hdb_sql_executor=>get_statement_type( gv_sql ).
*创建默认数据库的链接对象
* '' 空表示 连接 SAP 数据库
  r_adbc_conn    = cl_db6_con=>get_connection( '' ).
*创建一个查询对象
  r_adbc_query   = r_adbc_conn->create_statement( ).
*基于sql语句创建一个结果对象
  r_adbc_result  = r_adbc_query->execute_query( gv_sql  ).
*获取结果集合的字段名
  it_metadata = r_adbc_result->get_metadata( ).
*使用结果集合的字段信息,创建一个数据对象-结构
  r_metadata = r_adbc_result->get_struct_ref( md_tab = it_metadata   p_strict = abap_false ).
*创建一个数据对象-内表
  ex_structdescr ?= cl_abap_typedescr=>describe_by_data_ref( r_metadata ).
  r_tabletype     = cl_abap_tabledescr=>create( p_line_type  = ex_structdescr
                                                p_table_kind = cl_abap_tabledescr=>tablekind_std ).

  CREATE DATA ex_result_ref TYPE HANDLE r_tabletype.
*传递结果集一个数据对象-内表
  r_adbc_result->set_param_table( itab_ref = ex_result_ref ).
*获取数据内容
  r_adbc_result->next_package( EXPORTING upto = 100 ).
*关闭连接
  r_adbc_result->close( ).
*赋值数据到内表
  FIELD-SYMBOLS: <fs_itab> TYPE STANDARD TABLE.
  ASSIGN ex_result_ref->* TO <fs_itab>.
  MOVE-CORRESPONDING <fs_itab> TO gt_temp.
ENDFORM.

FORM frm_get_data_adbc_simple .
  DATA: r_adbc_conn   TYPE REF TO  cl_sql_connection,
        r_adbc_query  TYPE REF TO  cl_sql_statement,
        r_metadata    TYPE REF TO  data,
        it_metadata   TYPE         adbc_rs_metadata_descr_tab,
        lv_len        TYPE         i,
        lv_off        TYPE         i,
        wa_metadata   LIKE LINE OF it_metadata,
        r_adbc_result TYPE REF TO  cl_sql_result_set,
        r_tabletype   TYPE REF TO  cl_abap_tabledescr,
        r_cxadbc      TYPE REF TO  cx_dba_adbc,
        r_cxsql       TYPE REF TO  cx_sql_exception,
        tabix_n(4)    TYPE n,
        column_names  TYPE HASHED TABLE OF adbc_name WITH UNIQUE KEY table_line.
  DATA:         lv_stmt_type      TYPE string.
  DATA:
    ex_structdescr TYPE REF TO  cl_abap_structdescr,
    ex_result_ref  TYPE REF TO data.

*创建默认数据库的链接对象
* '' 空表示 连接 SAP 数据库
  r_adbc_conn    = cl_db6_con=>get_connection( '' ).
*创建一个查询对象
  r_adbc_query   = r_adbc_conn->create_statement( ).
*基于sql语句创建一个结果对象
  r_adbc_result  = r_adbc_query->execute_query( gv_sql  ).

*定义
  DATA: lr_ref LIKE REF TO gt_temp.
  CREATE DATA lr_ref .
*传递结果集一个数据对象-内表
  r_adbc_result->set_param_table( itab_ref = lr_ref ).
*获取数据内容
  r_adbc_result->next_package( EXPORTING upto = 100 ).
*关闭连接
  r_adbc_result->close( ).
*赋值数据到内表

  gt_temp = lr_ref->*.
ENDFORM.