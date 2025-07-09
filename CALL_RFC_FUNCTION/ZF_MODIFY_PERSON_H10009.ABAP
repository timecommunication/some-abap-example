FUNCTION ZF_MODIFY_PERSON_H10009.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  EXPORTING
*"     VALUE(EV_STATUS) TYPE  CHAR20
*"  TABLES
*"      IT_PERSON TYPE  ZTTPERSON_H10009 OPTIONAL
*"----------------------------------------------------------------------


  MODIFY ZTPERSON_H10009 FROM TABLE IT_PERSON.
  IF SY-SUBRC = 0.
    EV_STATUS = 'SUCCESS'.
  ELSE.
    EV_STATUS = 'FAILED'.
  ENDIF.




ENDFUNCTION.