
DATA: GT_APPR_TABLE TYPE REF TO DATA,
      GS_APPR_TABLE TYPE REF TO DATA.
FIELD-SYMBOLS: <GFS_APPR> TYPE STANDARD  TABLE ,
               <GFS_APPR_ADD_ROW> TYPE ANY .
DATA(GV_TABLE_NAME) = 'ZTMM_APPR'.

" 对于固定的表结构 ZTMM_APPR 
" 如果想在程序运行时，给 ZTMM_APPR 类型的内表添加新的一列 ，
" 比如 CELL_STYLE 这个 LVC_T_STYL 类型的字段 
" 可以使用如下的方法：

DATA: lo_struct TYPE REF TO cl_abap_structdescr,
      lo_new_struct TYPE REF TO cl_abap_structdescr,
      lt_components TYPE abap_component_tab,
      ls_component TYPE abap_componentdescr.
DATA: lo_lvc_t_styl TYPE REF TO cl_abap_tabledescr.


* 获取原结构
lo_struct ?= cl_abap_typedescr=>describe_by_name( GV_TABLE_NAME ).
lt_components = lo_struct->get_components( ).

* 添加新字段
ls_component-name = 'CELL_STYLE'.
*ls_component-type = cl_abap_elemdescr=>get_string( ).
lo_lvc_t_styl ?= cl_abap_tabledescr=>describe_by_name( 'LVC_T_STYL' ).
ls_component-type = lo_lvc_t_styl.


INSERT ls_component INTO TABLE lt_components.

* 创建新结构
lo_new_struct = cl_abap_structdescr=>create( lt_components ).

* 创建新内表类型
DATA(lo_table_type) = cl_abap_tabledescr=>create( lo_new_struct ).

* 创建 内表 数据对象
" <gfs_appr> 内表 中 会包含 CELL_STYLE 这一列字段
CREATE DATA gt_appr_table TYPE HANDLE lo_table_type.
ASSIGN gt_appr_table->* TO <gfs_appr>.

* 创建 结构 数据对象
" <GFS_APPR_ADD_ROW> 结构中 会包含 CELL_STYLE 这个字段
CREATE DATA GS_APPR_TABLE TYPE HANDLE LO_NEW_STRUCT.
ASSIGN GS_APPR_TABLE->* TO <GFS_APPR_ADD_ROW> .

