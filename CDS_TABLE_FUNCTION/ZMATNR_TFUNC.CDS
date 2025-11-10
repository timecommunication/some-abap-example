@EndUserText.label: 'TFUNC'
define table function ZMATNR_TFUNC
//with parameters parameter_name : parameter_type
returns {
  mandt : abap.clnt;
  matnr : matnr;
  maktx : maktx;
  
}
implemented by method zcl_matnr_func_cds=>MATNR_DESC;