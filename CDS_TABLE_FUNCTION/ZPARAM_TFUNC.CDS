@EndUserText.label: 'AMDP'
define table function ZPARAM_TFUNC
with parameters 
    @Environment.systemField: #CLIENT
    p_mandt: s_mandt,
    p_carrid: s_carr_id,
    p_connid: s_conn_id
returns {
  mandt : s_mandt;
  carrid : s_carr_id;
  connid: s_conn_id;
  carrname: s_carrname;
  url: s_carrurl;
  
}
implemented by method zcl_tfunc_amdp_cls=>get_scarr_for_cds;