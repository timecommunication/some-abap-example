*&---------------------------------------------------------------------*
*& 包含               Z_01_08FORM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form SELECTION_SCREEN_PAI
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM selection_screen_pai .

    SELECT SINGLE CODE NAME
      FROM ZSTUDENT_TABLE
      INTO CORRESPONDING FIELDS OF GS_STUDENT
      WHERE CODE IN STUCODE .
  
    " 判断 语句返回码 SY-SUBRC ，0表示成功 ， 其他表示错误码
    IF SY-SUBRC = 0 .
      GV_RES = '存在' .
      MESSAGE S000 WITH '该学号存在' .
    ELSE .
      GV_RES = '不存在' .
      MESSAGE S000 WITH '该学号不存在' .
    ENDIF .
  
ENDFORM.
  

*&---------------------------------------------------------------------*
*& Form MODIFY_SCREEN
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM modify_screen .

    LOOP AT SCREEN .
        IF P_CHECK = 'X' .
        " 显示
        ELSE .
        " 隐藏
        IF SCREEN-GROUP1 = 'DEP' .
            SCREEN-INVISIBLE = 1.
            MODIFY SCREEN .
        ENDIF .
        ENDIF .
    ENDLOOP .

ENDFORM.


*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data .

    " 声明 SEX 字段的范围限制 内表
    RANGES R_SEX FOR GS_STUDENT-SEX .

    CLEAR: R_SEX, R_SEX[] .

    IF P_CHECK = 'X' .
        IF R_MALE = 'X' .
        " 性别 勾选 男
        R_SEX-SIGN = 'I' .        " I 包含 / E 不包含
        R_SEX-OPTION = 'EQ' .     " EQ 等于 / GE 大于等于 / BT 在 ...之间 /  ....
        R_SEX-LOW = 'M' .         " 小值
        APPEND R_SEX .
        ELSE .
        " 性别 勾选 女
        R_SEX-SIGN = 'I' .
        R_SEX-OPTION = 'EQ' .
        R_SEX-LOW = 'F' .
        APPEND R_SEX .
        ENDIF .
    ENDIF .

" 多表取数 - JOIN
    " INNER JOIN
*  SELECT A~CODE A~NAME A~SEX A~SCHOOL_CODE
*         B~SCHOOL_NAME
*    FROM ZSTUDENT_TABLE AS A INNER JOIN ZSCHOOL_TABLE AS B
*    ON A~SCHOOL_CODE = B~SCHOOL_CODE
*    INTO CORRESPONDING FIELDS OF TABLE GT_TOTAL
*    WHERE A~SCHOOL_CODE IN SCHCODE
*    AND A~CODE IN STUCODE
*    AND A~NAME IN STUNAME .


    " LEFT OUTER JOIN  左外连接
*    SELECT A~CODE A~NAME A~SEX A~SCHOOL_CODE
*           B~SCHOOL_NAME
*      FROM ZSTUDENT_TABLE AS A LEFT OUTER JOIN ZSCHOOL_TABLE AS B
*      ON A~SCHOOL_CODE = B~SCHOOL_CODE
*      INTO CORRESPONDING FIELDS OF TABLE GT_TOTAL
*      WHERE A~SCHOOL_CODE IN SCHCODE
*      AND A~CODE IN STUCODE
*      AND A~NAME IN STUNAME .


    " 多表查询流程
    SELECT CODE NAME SEX SCHOOL_CODE
        FROM ZSTUDENT_TABLE
        INTO CORRESPONDING FIELDS OF TABLE GT_STUDENT
        WHERE CODE IN STUCODE
        AND NAME IN STUNAME
        AND SCHOOL_CODE IN SCHCODE
        AND SEX IN R_SEX .

    IF GT_STUDENT IS NOT INITIAL .

        SELECT SCHOOL_CODE SCHOOL_NAME
        FROM ZSCHOOL_TABLE
        INTO CORRESPONDING FIELDS OF TABLE GT_SCHOOL
        FOR ALL ENTRIES IN GT_STUDENT
        WHERE SCHOOL_CODE = GT_STUDENT-SCHOOL_CODE .

        SORT GT_SCHOOL BY SCHOOL_CODE .

    ENDIF .

    LOOP AT GT_STUDENT INTO GS_STUDENT .

        CLEAR GS_TOTAL .
        MOVE-CORRESPONDING GS_STUDENT TO GS_TOTAL .
        " BINARY SEARCH 可以加快查找速度，使用之前必须排序
        READ TABLE GT_SCHOOL INTO GS_SCHOOL WITH KEY SCHOOL_CODE = GS_STUDENT-SCHOOL_CODE BINARY SEARCH .

        " 把学校表的学校名称 放入学生内表的对应字段中
        IF SY-SUBRC = 0 .
        GS_TOTAL-SCHOOL_NAME = GS_SCHOOL-SCHOOL_NAME .
        ELSE .
        ENDIF .
        APPEND GS_TOTAL TO GT_TOTAL .


    ENDLOOP .


ENDFORM.
  
  
*&---------------------------------------------------------------------*
*& Form DISPLAY_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_data .

    LOOP AT GT_TOTAL INTO GS_TOTAL .
        WRITE: /1 SY-VLINE NO-GAP ,(10) GS_TOTAL-CODE NO-GAP CENTERED ,
                SY-VLINE NO-GAP ,(20) GS_TOTAL-NAME NO-GAP CENTERED ,
                SY-VLINE NO-GAP ,(5) GS_TOTAL-SEX NO-GAP CENTERED ,
                SY-VLINE NO-GAP ,(10) GS_TOTAL-SCHOOL_CODE NO-GAP CENTERED ,
                SY-VLINE NO-GAP ,(30) GS_TOTAL-SCHOOL_NAME NO-GAP CENTERED ,
                SY-VLINE NO-GAP .

    "  从位置1 开始输出 81 单位长度的 横线
    " SY-ULINE 表示横线 ， SY-VLINE 表示竖线
        WRITE: /1(81) SY-ULINE .
    ENDLOOP .

ENDFORM.
  
  
*&---------------------------------------------------------------------*
*& Form TOP_OF_PAGE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM top_of_page .
    FORMAT COLOR 3 ON . "颜色背景
        WRITE: /1(81) '学生信息表' .
    FORMAT COLOR 3 OFF .

    WRITE: /1(81) SY-ULINE .

    FORMAT COLOR 6 INVERSE ON .
        WRITE: /1 SY-VLINE NO-GAP , (10) '学号' NO-GAP CENTERED ,
                SY-VLINE NO-GAP , (20) '姓名' NO-GAP CENTERED ,
                SY-VLINE NO-GAP , (5) '性别' NO-GAP CENTERED ,
                SY-VLINE NO-GAP , (10) '学校代码' NO-GAP CENTERED ,
                SY-VLINE NO-GAP , (30) '学校名称' NO-GAP CENTERED ,
                SY-VLINE NO-GAP .
    FORMAT COLOR 6 INVERSE OFF .

    WRITE: /1(81) SY-ULINE .

ENDFORM.
  
  
*&---------------------------------------------------------------------*
*& Form LINE_SELECT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM line_select .
    " 显示学校详细信息

    DATA: LV_FIELD(30) , LV_VALUE(30) .

    " 获取光标所 点击的字段 和 字段值
    GET CURSOR FIELD LV_FIELD VALUE LV_VALUE .

    CHECK LV_FIELD = 'GS_TOTAL-SCHOOL_CODE' .

    " 判断 学校编号 是否存在
    SELECT SINGLE *
        FROM ZSCHOOL_TABLE
        WHERE SCHOOL_CODE = LV_VALUE .

    IF SY-SUBRC = 0 .
        WRITE: / '学校信息详情' .

        WRITE: / '学校编号：' , ZSCHOOL_TABLE-SCHOOL_CODE ,
                / '学校名称：' , ZSCHOOL_TABLE-SCHOOL_NAME ,
                / '学校地址：' , ZSCHOOL_TABLE-ADDRESS .
    ELSE .
        MESSAGE E000 WITH '不存在' .
    ENDIF .


ENDFORM.
  
  
*&---------------------------------------------------------------------*
*& Form USER_COMMAND
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM user_command .

    " 判断 function-code ,确定点击的按钮
    CASE SY-UCOMM .
        WHEN 'BACK' .
        LEAVE TO SCREEN 0 . " 返回上一个屏幕
        WHEN 'EXIT' OR 'CANCEL' .
        LEAVE PROGRAM .

        WHEN 'SORTUP' .
        SY-LSIND = SY-LSIND - 1 .   " 列表索引页.  自减1 在当前屏幕输入
        PERFORM SORT_LIST USING 'UP' .  " 传入参数 UP
        WHEN 'SORTDOWN' .
        SY-LSIND = SY-LSIND - 1 .
        PERFORM SORT_LIST USING 'DOWN' .
        WHEN 'DOWNLOAD' .
        MESSAGE S000 WITH '下载成功' .
        WHEN OTHERS .
    ENDCASE .


ENDFORM.
  
  
*&---------------------------------------------------------------------*
*& Form SORT_LIST
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&---------------------------------------------------------------------*
FORM sort_list  USING P_FLAG.

    DATA LV_FIELD(30) .
    DATA LV_FIELD_NAME(30) .

    DATA LT_FIELD TYPE TABLE OF CHAR30 .

    " 获取光标所点击字段
    GET CURSOR FIELD LV_FIELD .

    " 截取 LV_FIELD 变量 的 前 8 位，
    " 判断是否 等于 GS_TOTAL
    " 如果是 继续执行 ； 否则 子例程 结束

    CHECK LV_FIELD+0(8) = 'GS_TOTAL' .

    " 截取 字段名
    LV_FIELD_NAME = LV_FIELD+9(*) .

    IF P_FLAG = 'UP' .
        " ( ) 表示取变量的值
        SORT GT_TOTAL BY (LV_FIELD_NAME) .
    ELSEIF P_FLAG = 'DOWN' .
        SORT GT_TOTAL BY (LV_FIELD_NAME) .
    ENDIF .

    " 输出结果
    PERFORM DISPLAY_DATA .

ENDFORM.