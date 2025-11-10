@AbapCatalog.sqlViewName: 'ZUSETFUNC'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '0922 H10009 USE AMDP'
@Metadata.ignorePropagatedAnnotations: true
define view ZCDS_USE_TFUNC
with parameters
    p_carr: s_carr_id,
    p_conn: s_conn_id 
as select from ZPARAM_TFUNC(
    p_mandt: $session.client,
    p_carrid: $parameters.p_carr,
    p_connid: $parameters.p_conn
)
{
    *
}
