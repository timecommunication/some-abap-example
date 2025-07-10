*&---------------------------------------------------------------------*
*& Report Z0709_BDC_VA02_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0709_BDC_VA02_H10009.

DATA GV_NUM TYPE CHAR2 .

DATA: bdcdata TYPE TABLE OF bdcdata WITH HEADER LINE,
      MSGtab TYPE TABLE OF bdcmsgcoll WITH HEADER LINE.


PARAMETERS:
  P_VBELN TYPE VBAK-VBELN DEFAULT '8000001261',
  P_POSNR TYPE POSNR DEFAULT 1,
  P_KWMENG TYPE KWMENG.

GV_NUM  = |{ P_POSNR ALPHA = IN WIDTH = 2 }|.



PERFORM APPEND_BDCDATA USING P_VBELN GV_NUM P_KWMENG.

" 对事务使用 BDC 
" MODE : N 表示 后台模式， A 表示前台模式
" UPDATE: S 表示 异步更新,  S 表示同步更新
CALL TRANSACTION 'VA02' USING BDCDATA
        MODE 'N' UPDATE 'S'
        MESSAGES INTO MSGTAB.

LOOP AT MSGTAB INTO DATA(WA_MSG).
  WRITE: / WA_MSG-MSGSPRA, WA_MSG-MSGID,
           WA_MSG-MSGNR, WA_MSG-MSGV1, WA_MSG-MSGV2.
ENDLOOP.





*&---------------------------------------------------------------------*
*& Form APPEND_BDCDATA
*&---------------------------------------------------------------------*
*& 传入对应的 BDC 屏幕 和 字段参数
*&---------------------------------------------------------------------*
*& -->  P_VBELN
*& -->  P_GVNUM
*& -->  P_KWMENG
*&---------------------------------------------------------------------*
FORM APPEND_BDCDATA USING P_VBELN  P_GVNUM P_KWMENG.

  DATA(LV_NUM) = |RV45A-KWMENG({ P_GVNUM })|.
  DATA(LV_KWMENG) = |{ P_KWMENG }|.
  DATA(LV_VBELN) = |{ P_VBELN }|.

  SELECT SINGLE VBELN, KUNNR, VDATU, CROSSITEM_PRC_DATE FROM VBAK
    WHERE VBELN = @P_VBELN
    INTO @DATA(LS_VBAK).


  CLEAR: BDCDATA , BDCDATA[], MSGTAB, MSGTAB[].


  PERFORM APPEND_SCREEN USING 'SAPMV45A' '0102'.
  PERFORM APPEND_FIELDS USING 'BDC_OKCODE' '=SUCH'.
  PERFORM APPEND_FIELDS USING 'VBAK-VBELN' LV_VBELN.


  PERFORM APPEND_SCREEN USING 'SAPMV45A' '4001'.
  PERFORM APPEND_FIELDS USING 'BDC_OKCODE' '/00'.
  PERFORM APPEND_FIELDS USING: 'KUAGV-KUNNR' LS_VBAK-KUNNR,
          'KUWEV-KUNNR' LS_VBAK-KUNNR,
          'RV45A-KETDAT' LS_VBAK-VDATU,
          'RV45A-KPRGBZ' 'D',
          LV_NUM LV_KWMENG .


  PERFORM APPEND_SCREEN USING 'SAPMV45A' '4001'.
  PERFORM APPEND_FIELDS USING 'BDC_OKCODE' '=SICH'.
  PERFORM APPEND_FIELDS USING: 'KUAGV-KUNNR' LS_VBAK-KUNNR ,
        'KUWEV-KUNNR' LS_VBAK-KUNNR,
        'RV45A-KETDAT' LS_VBAK-VDATU,
        'RV45A-KPRGBZ' 'D',
        'VBKD-PRSDT' LS_VBAK-CROSSITEM_PRC_DATE.



  PERFORM APPEND_SCREEN USING 'SAPLSPO1' '0500'.
  PERFORM APPEND_FIELDS USING 'BDC_OKCODE' '=OPT1'.

ENDFORM.



*&---------------------------------------------------------------------*
*& Form APPEND_SCREEN
*&---------------------------------------------------------------------*
*& 屏幕信息
*&---------------------------------------------------------------------*
*& -->  PROGRAM
*& -->  DYNPRO
*&---------------------------------------------------------------------*
FORM APPEND_SCREEN USING PROGRAM DYNPRO .
  CLEAR bdcdata.
  bdcdata-program = program.
  bdcdata-dynpro = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form APPEND_FIELDS
*&---------------------------------------------------------------------*
*& 字段信息
*&---------------------------------------------------------------------*
*& -->  FNAM
*& -->  FVAL
*&---------------------------------------------------------------------*
FORM APPEND_FIELDS USING FNAM FVAL .
  CLEAR bdcdata.
  bdcdata-fnam = FNAM.
  bdcdata-fval = fval.
  APPEND bdcdata.
ENDFORM.