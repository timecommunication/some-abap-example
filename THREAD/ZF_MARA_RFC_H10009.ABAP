FUNCTION ZF_MARA_RFC_H10009.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(IV_OFFSET) TYPE  I OPTIONAL
*"     VALUE(IV_UPTO) TYPE  I OPTIONAL
*"  TABLES
*"      T_MARA TYPE  ZMARA_H10009 OPTIONAL
*"----------------------------------------------------------------------
" 查询 MARA 表中数据
  SELECT
    MARA~MATNR ,
    MARA~ERSDA ,
    MAKT~MAKTX
    FROM MARA
    JOIN MAKT
    ON MARA~MATNR = MAKT~MATNR
    AND MAKT~SPRAS = '1'
    ORDER BY MARA~MATNR
    INTO TABLE @T_MARA
    UP TO @IV_UPTO ROWS
    OFFSET @IV_OFFSET.


ENDFUNCTION.