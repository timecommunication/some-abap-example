*&---------------------------------------------------------------------*
*& Report Z0702_SUBPROG_BUKRS_H10009
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z0702_SUBPROG_BUKRS_H10009.

PARAMETERS: P_BUKRS TYPE BUKRS MEMORY ID BUK .

SELECT SINGLE  BUTXT FROM T001
  WHERE BUKRS = @P_BUKRS
  INTO @DATA(LV_BUKRS) .

SET PARAMETER ID 'BTX' FIELD LV_BUKRS.