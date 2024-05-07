*&---------------------------------------------------------------------*
*& Report Z_01_08
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z_01_08 MESSAGE-ID S001
               NO STANDARD PAGE HEADING
               LINE-SIZE 90
               LINE-COUNT 8 .

INCLUDE Z_01_08TOP .
INCLUDE Z_01_08FORM .


" 初始化事件  ，  一些初始变量的赋值
INITIALIZATION .
  GV_RES = '待检查' .
  BUTTON1 = '分页签1' .
  BUTTON2 = '分页签2' .

  " SY-REPID 表示当前程序 ID
  MYTAB-PROG = SY-REPID .
  MYTAB-DYNNR = 3001 .
  MYTAB-ACTIVETAB = 'TAB1' .

" 选择界面的 PBO 事件， process before output
AT SELECTION-SCREEN OUTPUT .
  PERFORM MODIFY_SCREEN .


" 选择界面的 PAI 事件， process after input
AT SELECTION-SCREEN .

  CASE SY-DYNNR .
    WHEN 1000 .
      PERFORM SELECTION_SCREEN_PAI .

      CASE SY-UCOMM .
        WHEN 'PUSH1' .
          MYTAB-DYNNR = 3001 .
          MYTAB-ACTIVETAB = 'BUTTON1' .
        WHEN 'PUSH2' .
          MYTAB-DYNNR = 3002 .
          MYTAB-ACTIVETAB = 'BUTTON2' .
      ENDCASE .

  ENDCASE .


" 事件 START-OF-SELCTION
" 查询取数
START-OF-SELECTION .
  PERFORM GET_DATA .

" 事件 END-OF-SELECTION
END-OF-SELECTION .

  " SE80 中 右键点击程序 -》 创建 -》 GUI Status 和 GUI 标题
  " GUI-STATUS 名称为 'STATUS'
  " GUI 标题   名称为 'TITLE'

  SET PF-STATUS 'STATUS' .

  " 最后两个 字符串 分别对应  标题中的占位符 &1  和 &2
  SET TITLEBAR 'TITLE' WITH '太阳系' '数据' .


  IF GT_TOTAL IS NOT INITIAL .
    " 如果数据查询结果非空 , 显示数据
    PERFORM DISPLAY_DATA .
  ELSE .
    MESSAGE S001 DISPLAY LIKE 'E' .
  ENDIF .


" 事件 TOP-OF-PAGE
TOP-OF-PAGE .
  PERFORM TOP_OF_PAGE .


" 事件 AT LINE SELECTION
" 在一个界面上 进行双击时 触发， 在 GUI-STATUS 中设置双击
AT LINE-SELECTION .
  PERFORM LINE_SELECT .


" 在 LINE-SELECTION 事件期间 的 TOP-OF-PAGE 事件
TOP-OF-PAGE DURING LINE-SELECTION .

  CASE SY-UCOMM .
    WHEN 'SORTUP' OR 'SORTDOWN' .
      PERFORM TOP_OF_PAGE .
    WHEN 'OTHERS' .
  ENDCASE .


" 用户指令事件处理
AT USER-COMMAND .
  PERFORM USER_COMMAND .