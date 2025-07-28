FUNCTION ZMM_CONV_NUMC_TO_CHINESE.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(PI_MONEY) TYPE  MSEG-DMBTR OPTIONAL
*"     VALUE(PI_WAERS) TYPE  WAERS OPTIONAL
*"  EXPORTING
*"     REFERENCE(PO_CHINESE) TYPE  CHAR100
*"----------------------------------------------------------------------

" 一个可以把 数字 转换为 中文大写数字 的函数

  IF PI_MONEY = 0.
    PO_CHINESE = '零'.
    EXIT.
  ENDIF.
  DATA:MONEY_STR(21).
  MONEY_STR = PI_MONEY.
  IF MONEY_STR CN '0123456789. '.
*    RAISE WRONG_MONEY.
  ENDIF.
  DATA:I TYPE I.
  IF MONEY_STR CS '.'.
    I = SY-FDPOS + 1.
    MONEY_STR+SY-FDPOS = MONEY_STR+I.
  ENDIF.
  CONDENSE MONEY_STR NO-GAPS.
  DATA:UNITS_OFF TYPE I,
       CURNT_OFF TYPE I.
  DATA:LASTD TYPE N,CURNTD TYPE N.
  DATA:CWORD(2),WEIGHT(2).
  DATA:UNITS(30) VALUE '分角元拾佰仟万拾佰仟亿拾佰仟万',
       DIGTS(20) VALUE '零壹贰叁肆伍陆柒捌玖'.
  IF PI_WAERS = 'USD'
  OR PI_WAERS = 'EUR'.
    UNITS = '分拾元拾佰仟万拾佰仟亿拾佰仟万'.
  ENDIF.

* clear:po_chinese,units_off.
  LASTD = 0.
  CURNT_OFF = STRLEN( MONEY_STR ) - 1.
  WHILE CURNT_OFF >= 0.
    CURNTD = MONEY_STR+CURNT_OFF(1).
    CWORD = DIGTS+CURNTD(1).

    WEIGHT = UNITS+UNITS_OFF(1).

    IF CURNTD = 0.             "Current digit is 0
      IF UNITS_OFF = 2 OR UNITS_OFF = 6 OR UNITS_OFF = 10.
        CLEAR:CWORD.
        IF CURNT_OFF = 0.
          CLEAR:WEIGHT.
        ENDIF.
      ELSEIF LASTD = 0.
        CLEAR:CWORD,WEIGHT.
      ELSE.
        CLEAR:WEIGHT.
      ENDIF.
    ENDIF.
    CONCATENATE CWORD WEIGHT PO_CHINESE INTO PO_CHINESE.
    LASTD = CURNTD.
    SUBTRACT 1 FROM CURNT_OFF.
    ADD 1 TO UNITS_OFF.
  ENDWHILE.
  IF PO_CHINESE NS '分'.
    CONCATENATE PO_CHINESE '整' INTO PO_CHINESE.
  ELSE.
    CWORD = PO_CHINESE.
    IF CWORD = '零'.
      SHIFT PO_CHINESE BY 1 PLACES.
    ENDIF.
  ENDIF.

ENDFUNCTION.