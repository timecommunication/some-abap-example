*&---------------------------------------------------------------------*
*& Report Z0630_NATIVESQL_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0630_NATIVESQL_H10009.

PARAMETERS:
  p_1 RADIOBUTTON GROUP ra1,
  p_2 RADIOBUTTON GROUP ra1
*  p_3 RADIOBUTTON GROUP ra1,
*  p_4 RADIOBUTTON GROUP ra1
  .

DATA: BEGIN OF gs_temp,
        ZUSERID TYPE ZE_ZUSERID,
        ZNAME TYPE ZE_ZNAME,
        ZGENDER TYPE ZE_ZGENDER,
      END OF gs_temp.
DATA: gt_temp LIKE TABLE OF gs_temp.
DATA conn TYPE dbcon-con_name.

*INITIALIZATION.
*  %_p_1_%_app_%-text = 'SELECT方式一:DO循环读取游标,添加内表'.
*  %_p_2_%_app_%-text = 'SELECT方式二:通过例程添加内表'.
*  %_p_3_%_app_%-text = 'UPDATE:更新表内容'.
*  %_p_4_%_app_%-text = 'INSERT:写入表内容'.

START-OF-SELECTION.
" CONN 为空时 默认使用 SAP 数据库
  conn = ''.

"   如果使用 外部 SQL 连接，需要使用这段，事务码 DBCO 中 配置好连接，这里使用
  "检查连接是否已经打开
*  EXEC SQL.
*    SET CONNECTION :conn
*  ENDEXEC.
*  IF sy-subrc <> 0. "如果连接没有打开, 打开连接
*    EXEC SQL.
*      CONNECT TO :conn
*    ENDEXEC.
*  ENDIF.

*两种方式: 方式一性能好于方式二
  CASE 'X'.
    WHEN p_1.
      PERFORM frm_method_1. "SELECT方式一:DO循环读取游标,添加内表'.
    WHEN p_2.
      PERFORM frm_method_2. "SELECT方式二:通过例程添加内表'.
*    WHEN p_3.
*      PERFORM frm_update.
*    WHEN p_4.
*      PERFORM frm_insert.
  ENDCASE.

  "关闭数据库连接
*  EXEC SQL.
*    DISCONNECT :CONN
*  ENDEXEC.

*输出结果
  CASE 'X'.
    WHEN p_1 OR p_2.
      cl_demo_output=>display( gt_temp ).
  ENDCASE.





*&---------------------------------------------------------------------*
*& Form FRM_METHOD_1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_method_1 .
  DATA: ls_temp LIKE gs_temp,
        lt_temp LIKE TABLE OF ls_temp.

  "执行SQL语句:通过open dbcur打开游标
  EXEC SQL.
    OPEN dbcur FOR
    SELECT ZUSERID,ZNAME, ZGENDER FROM ZTPERSON_H10009
  ENDEXEC.
  "循环通过游标读取记录
  " 两种赋值方式:
  " 1.按字段顺序赋值,select 字段与 INTO 字段顺序必须一致
  "   FETCH NEXT dbcur INTO :ls_TEMP-ZZTNO,:LS_TEMP-WERKS
  " 2.按结构整体赋值:select 字段必须与结构字段顺序一致,且字段长度一致.
  "   FETCH NEXT dbcur INTO :ls_TEMP
  DO 10 TIMES.
    EXEC SQL.
      FETCH NEXT dbcur INTO :ls_TEMP-ZUSERID,:LS_TEMP-ZNAME, :LS_TEMP-ZGENDER
    ENDEXEC.
    IF sy-subrc <> 0.
      EXIT.
    ELSE.
      APPEND ls_temp TO lt_temp.
    ENDIF.
  ENDDO.
  "关闭游标
  EXEC SQL.
    CLOSE dbcur
  ENDEXEC.
  gt_temp[] = lt_temp[].
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_METHOD_2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_method_2 .

"**注意:工作区 gs_temp 内表 gt_temp 必须是全局变量

  EXEC SQL PERFORMING frm_fill_data.
    SELECT top 10 ZUSERID,ZNAME, ZGENDER FROM ZTPERSON_H10009 INTO :GS_TEMP
  ENDEXEC.

ENDFORM.

FORM frm_fill_data.
  APPEND gs_temp TO gt_temp.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_UPDATE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_update .
  DATA: lv_werks(4).
  lv_werks = '1002'.
  EXEC SQL.
    UPDATE ZTTEMP SET WERKS = :LV_WERKS
     WHERE WERKS = '1003'.
  ENDEXEC.
  IF sy-subrc = 0.
*提交数据更新
    EXEC SQL.
      COMMIT WORK
    ENDEXEC.
    DATA: lv_msg(50).
    lv_msg = '更新成功记录数:' && sy-dbcnt .
    cl_demo_output=>display(  lv_msg ).
  ELSE.
    cl_demo_output=>display( '更新失败' ).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_INSERT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_insert .
  DATA: lv_werks(4).
  lv_werks = '1002'.
  EXEC SQL.
    INSERT INTO ZTTEMP VALUES ('4502',:LV_WERKS)
  ENDEXEC.
  IF sy-subrc = 0.
*提交数据更新
    EXEC SQL.
      COMMIT WORK
    ENDEXEC.
    DATA: lv_msg(50).
    lv_msg = '写入成功记录数:' && sy-dbcnt .
    cl_demo_output=>display(  lv_msg ).
  ELSE.
    cl_demo_output=>display( '写入失败' ).
  ENDIF.
ENDFORM.