CLASS zcl_crms4_btx_data_model_tool DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    METHODS save_header
      IMPORTING
        !it_header_guid TYPE crmt_object_guid_tab .
    CLASS-METHODS class_constructor .
    METHODS get_item
      IMPORTING
        !it_item_guid     TYPE crmt_object_guid_tab
      EXPORTING
        !et_orderadm_i_db TYPE crmt_orderadm_i_du_tab .
    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_instance) TYPE REF TO zcl_crms4_btx_data_model_tool .
  PROTECTED SECTION.
private section.

  types:
    BEGIN OF ty_convertor_instance,
        cls_name  TYPE crmt_object_name,
        convertor TYPE REF TO zif_crms4_btx_data_model,
      END OF ty_convertor_instance .
  types:
    tt_convertor_instance TYPE TABLE OF ty_convertor_instance WITH KEY cls_name .
  types:
    BEGIN OF ty_header_object_type,
        guid        TYPE crmt_object_guid,
        object_type TYPE crmt_subobject_category_db,
      END OF ty_header_object_type .
  types:
    tt_header_object_type TYPE TABLE OF ty_header_object_type WITH KEY guid .
  types:
    BEGIN OF ty_object_supported_component,
        object_type     TYPE crmt_subobject_category_db,
        supported_comps TYPE crmt_object_name_tab,
      END OF ty_object_supported_component .
  types:
    tt_object_supported_component TYPE TABLE OF ty_object_supported_component
            WITH KEY object_type .
  types:
    BEGIN OF ty_component_conv_cls,
        component TYPE crmt_object_name,
        conv_cls  TYPE string,
      END OF ty_component_conv_cls .
  types:
    tt_supported_components TYPE STANDARD TABLE OF crmt_object_name WITH KEY table_line .
  types:
    tt_component_conv_cls TYPE TABLE OF ty_component_conv_cls WITH KEY component .

  data MT_CONVERTOR_INST_BUFFER type tt_convertor_instance .
  data MT_COMPONENT_CONV_CLS type TT_COMPONENT_CONV_CLS .
  class-data SO_INSTANCE type ref to ZCL_CRMS4_BTX_DATA_MODEL_TOOL .
  data MT_HEADER_OBJECT_TYPE_BUF type TT_HEADER_OBJECT_TYPE .
  data MT_HEADER_SUPPORTED_COMPS type TT_OBJECT_SUPPORTED_COMPONENT .
  data MT_ITEM_SUPPORTED_COMPS type TT_OBJECT_SUPPORTED_COMPONENT .

  methods FETCH_ITEM_SUPPORTED_COMP
    importing
      !IT_ITEM_WRKT type CRMT_ORDERADM_I_WRKT .
  methods GET_HEADER_DB_TYPE
    importing
      !IV_HEADER_GUID type CRMT_OBJECT_GUID
    returning
      value(RV_DB_TYPE) type STRING .
  methods GET_HEADER_SUPPORTED_COMP
    importing
      !IV_HEADER_OBJECT_TYPE type CRMT_SUBOBJECT_CATEGORY_DB
    returning
      value(RT_HEADER_SUPPORTED_COMP) type CRMT_OBJECT_NAME_TAB .
  methods FETCH_HEADER_OBJECT_TYPE
    importing
      !IT_HEADER_GUID type CRMT_OBJECT_GUID_TAB .
  methods GET_HEADER_OBJECT_TYPE_BY_GUID
    importing
      !IV_HEADER_GUID type CRMT_OBJECT_GUID
    returning
      value(RV_OBJECT_TYPE) type CRMT_SUBOBJECT_CATEGORY_DB .
  methods CONV_S4_2_1ORDER_AND_FILL_BUFF
    importing
      !IT_OBJECTS type CRMT_OBJECT_NAME_TAB
    changing
      !CS_ITEM type ANY .
  methods GET_CONVERTOR_INSTANCE
    importing
      !IV_CLS_NAME type CRMT_OBJECT_NAME
    returning
      value(RO_CONVERTOR) type ref to ZIF_CRMS4_BTX_DATA_MODEL .
  methods FETCH_HEADER_SUPPORTED_COMP .
  methods SAVE_SINGLE_HEADER
    importing
      !IV_HEADER_GUID type CRMT_OBJECT_GUID .
  methods FETCH_COMPONENT_CONV_CLS .
  methods GET_CONV_CLS_NAME_BY_COMPONENT
    importing
      !IV_COMPONENT_NAME type CRMT_OBJECT_NAME
    returning
      value(RV_CLS_NAME) type CRMT_OBJECT_NAME .
  methods GET_UNSORTED_COMPONENT_LIST
    importing
      !IT_SORTED_COMP type CRMT_OBJECT_NAME_TAB
      !IV_HEADER type ABAP_BOOL default ABAP_TRUE
    returning
      value(RT_UNSORTED_COMP) type TT_SUPPORTED_COMPONENTS .
  methods SAVE_SINGLE_ITEMS
    importing
      !IV_HEADER_GUID type CRMT_OBJECT_GUID .
  methods GET_ITEM_SUPPORTED_COMP
    importing
      !IV_ITEM_OBJECT_TYPE type CRMT_SUBOBJECT_CATEGORY_DB
    returning
      value(RT_ITEM_SUPPORTED_COMP) type CRMT_OBJECT_NAME_TAB .
ENDCLASS.



CLASS ZCL_CRMS4_BTX_DATA_MODEL_TOOL IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL=>CLASS_CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD class_constructor.
    so_instance = NEW #( ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->CONV_S4_2_1ORDER_AND_FILL_BUFF
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_OBJECTS                     TYPE        CRMT_OBJECT_NAME_TAB
* | [<-->] CS_ITEM                        TYPE        ANY
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD conv_s4_2_1order_and_fill_buff.
    DATA: lv_wrk_structure_name TYPE string,
          lr_wrk_structure      TYPE REF TO data,
          lt_convert_class      TYPE TABLE OF zcrmc_objects,
          lo_convertor          TYPE REF TO zif_crms4_btx_data_model.

    FIELD-SYMBOLS: <ls_wrk_structure> TYPE any.

    SELECT name conv_class INTO CORRESPONDING FIELDS OF TABLE lt_convert_class FROM zcrmc_objects
       FOR ALL ENTRIES IN it_objects WHERE name = it_objects-table_line.

    LOOP AT it_objects ASSIGNING FIELD-SYMBOL(<lv_object>).

      READ TABLE lt_convert_class ASSIGNING FIELD-SYMBOL(<cls_name>) WITH KEY
          name = <lv_object>.
      lo_convertor = get_convertor_instance( iv_cls_name = <cls_name>-conv_class ).

      CALL METHOD lo_convertor->get_wrk_structure_name
        RECEIVING
          rv_wrk_structure_name = lv_wrk_structure_name.
      CREATE DATA lr_wrk_structure TYPE (lv_wrk_structure_name).
      ASSIGN lr_wrk_structure->* TO <ls_wrk_structure>.
      CALL METHOD lo_convertor->convert_s4_to_1o
        EXPORTING
          is_workarea = cs_item
        IMPORTING
          es_workarea = <ls_wrk_structure>.
      CALL METHOD lo_convertor->put_to_db_buffer
        EXPORTING
          is_wrk_structure = <ls_wrk_structure>.

    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->FETCH_COMPONENT_CONV_CLS
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD fetch_component_conv_cls.
    DATA: lt_missing_comp  TYPE crmt_object_name_tab,
          lt_zcrmc_objects TYPE TABLE OF zcrmc_objects.

    LOOP AT mt_header_supported_comps ASSIGNING FIELD-SYMBOL(<comp>).
      LOOP AT <comp>-supported_comps ASSIGNING FIELD-SYMBOL(<component>).
        READ TABLE mt_component_conv_cls WITH KEY component = <component>
           TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          INSERT <component> INTO TABLE lt_missing_comp.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    SELECT name conv_class INTO CORRESPONDING FIELDS OF TABLE lt_zcrmc_objects
        FROM zcrmc_objects FOR ALL ENTRIES IN lt_missing_comp
          WHERE name = lt_missing_comp-table_line.

    LOOP AT lt_zcrmc_objects ASSIGNING FIELD-SYMBOL(<missing_comp>).
      APPEND INITIAL LINE TO mt_component_conv_cls ASSIGNING FIELD-SYMBOL(<new_buffer>).
      <new_buffer>-component = <missing_comp>-name.
      <new_buffer>-conv_cls = <missing_comp>-conv_class.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->FETCH_HEADER_OBJECT_TYPE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_HEADER_GUID                 TYPE        CRMT_OBJECT_GUID_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD fetch_header_object_type.
    DATA: lt_header_buffer_miss TYPE crmt_object_guid_tab,
          lt_header_shadow      TYPE TABLE OF zcrms4d_btx.
    LOOP AT it_header_guid ASSIGNING FIELD-SYMBOL(<guid>).
      READ TABLE mt_header_object_type_buf WITH KEY guid = <guid> TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND <guid> TO lt_header_buffer_miss.
      ENDIF.
    ENDLOOP.

    CHECK lt_header_buffer_miss IS NOT INITIAL.

    SELECT * INTO TABLE lt_header_shadow FROM zcrms4d_btx FOR ALL ENTRIES IN lt_header_buffer_miss
        WHERE order_guid = lt_header_buffer_miss-table_line.

    LOOP AT lt_header_shadow ASSIGNING FIELD-SYMBOL(<header_shadow>).
      APPEND INITIAL LINE TO mt_header_object_type_buf ASSIGNING FIELD-SYMBOL(<new_buffer>).
      <new_buffer> = VALUE #( guid = <header_shadow>-order_guid
                               object_type = <header_shadow>-object_type ).
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->FETCH_HEADER_SUPPORTED_COMP
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD fetch_header_supported_comp.
    DATA: lt_missed_header_object TYPE TABLE OF crmt_subobject_category_db,
          lt_zcrmc_object_ass     TYPE TABLE OF zcrmc_object_ass.

    LOOP AT mt_header_object_type_buf ASSIGNING FIELD-SYMBOL(<header_buf>).
      READ TABLE mt_header_supported_comps WITH KEY object_type = <header_buf>-object_type
        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND <header_buf>-object_type TO lt_missed_header_object.
      ENDIF.
    ENDLOOP.

    CHECK lt_missed_header_object IS NOT INITIAL.
    SORT lt_missed_header_object.
    DELETE ADJACENT DUPLICATES FROM lt_missed_header_object.

    SELECT * INTO TABLE lt_zcrmc_object_ass FROM zcrmc_object_ass FOR ALL ENTRIES IN
         lt_missed_header_object WHERE subobj_category = lt_missed_header_object-table_line.
    CHECK sy-subrc = 0.

    LOOP AT lt_missed_header_object ASSIGNING FIELD-SYMBOL(<missing>).
      APPEND INITIAL LINE TO mt_header_supported_comps ASSIGNING FIELD-SYMBOL(<new_buffer>).
      <new_buffer>-object_type = <missing>.
      LOOP AT lt_zcrmc_object_ass ASSIGNING FIELD-SYMBOL(<header_supported>)
          WHERE subobj_category = <missing>.
        APPEND <header_supported>-name TO <new_buffer>-supported_comps.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->FETCH_ITEM_SUPPORTED_COMP
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_ITEM_WRKT                   TYPE        CRMT_ORDERADM_I_WRKT
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD fetch_item_supported_comp.
    DATA: lt_missed_item_object_type TYPE TABLE OF crmt_subobject_category_db,
          lt_item_supported_compo    TYPE TABLE OF zcrmc_obj_assi_i.

    LOOP AT it_item_wrkt ASSIGNING FIELD-SYMBOL(<item>).
      READ TABLE mt_item_supported_comps WITH KEY object_type = <item>-object_type
       TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND <item>-object_type TO lt_missed_item_object_type.
      ENDIF.
    ENDLOOP.

    SORT lt_missed_item_object_type.
    DELETE ADJACENT DUPLICATES FROM lt_missed_item_object_type.
    CHECK lt_missed_item_object_type IS NOT INITIAL.

    SELECT * INTO TABLE lt_item_supported_compo FROM zcrmc_obj_assi_i
        FOR ALL ENTRIES IN lt_missed_item_object_type WHERE
      subobj_category = lt_missed_item_object_type-table_line.

    LOOP AT lt_missed_item_object_type ASSIGNING FIELD-SYMBOL(<miss_item_obj_type>).
      APPEND INITIAL LINE TO mt_item_supported_comps ASSIGNING FIELD-SYMBOL(<new_buffer>).
      <new_buffer>-object_type = <miss_item_obj_type>.
      LOOP AT lt_item_supported_compo ASSIGNING FIELD-SYMBOL(<support_comp>)
          WHERE subobj_category = <miss_item_obj_type>.
        APPEND <support_comp>-name TO <new_buffer>-supported_comps.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->GET_CONVERTOR_INSTANCE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_CLS_NAME                    TYPE        CRMT_OBJECT_NAME
* | [<-()] RO_CONVERTOR                   TYPE REF TO ZIF_CRMS4_BTX_DATA_MODEL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_convertor_instance.
    READ TABLE mt_convertor_inst_buffer ASSIGNING FIELD-SYMBOL(<convertor>) WITH KEY cls_name = iv_cls_name.
    IF sy-subrc = 0.
      ro_convertor = <convertor>-convertor.
      RETURN.
    ENDIF.

    CREATE OBJECT ro_convertor TYPE (iv_cls_name).
    APPEND INITIAL LINE TO mt_convertor_inst_buffer ASSIGNING FIELD-SYMBOL(<new_convertor>).
    <new_convertor> = VALUE ty_convertor_instance( cls_name = iv_cls_name convertor = ro_convertor ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->GET_CONV_CLS_NAME_BY_COMPONENT
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_COMPONENT_NAME              TYPE        CRMT_OBJECT_NAME
* | [<-()] RV_CLS_NAME                    TYPE        CRMT_OBJECT_NAME
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_conv_cls_name_by_component.
    READ TABLE mt_component_conv_cls ASSIGNING FIELD-SYMBOL(<buffer>)
     WITH KEY component = iv_component_name.
    rv_cls_name = <buffer>-conv_cls.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->GET_HEADER_DB_TYPE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_HEADER_GUID                 TYPE        CRMT_OBJECT_GUID
* | [<-()] RV_DB_TYPE                     TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_header_db_type.
    DATA(lv_object_type) = get_header_object_type_by_guid( iv_header_guid ).
    DATA: ls_zcrmc_subob_cat TYPE zcrmc_subob_cat.

    SELECT SINGLE * INTO ls_zcrmc_subob_cat FROM zcrmc_subob_cat
       WHERE subobj_category = lv_object_type.
    ASSERT sy-subrc = 0.
    rv_db_type = 'ZCRMS4D_' && ls_zcrmc_subob_cat-acronym && '_H'.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->GET_HEADER_OBJECT_TYPE_BY_GUID
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_HEADER_GUID                 TYPE        CRMT_OBJECT_GUID
* | [<-()] RV_OBJECT_TYPE                 TYPE        CRMT_SUBOBJECT_CATEGORY_DB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_header_object_type_by_guid.
    READ TABLE mt_header_object_type_buf ASSIGNING FIELD-SYMBOL(<header_type>)
     WITH KEY guid = iv_header_guid.
    CHECK sy-subrc = 0.

    rv_object_type = <header_type>-object_type.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->GET_HEADER_SUPPORTED_COMP
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_HEADER_OBJECT_TYPE          TYPE        CRMT_SUBOBJECT_CATEGORY_DB
* | [<-()] RT_HEADER_SUPPORTED_COMP       TYPE        CRMT_OBJECT_NAME_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_header_supported_comp.
    READ TABLE mt_header_supported_comps ASSIGNING FIELD-SYMBOL(<supported>)
     WITH KEY object_type = iv_header_object_type.

    CHECK sy-subrc = 0.

    rt_header_supported_comp = <supported>-supported_comps.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL=>GET_INSTANCE
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RO_INSTANCE                    TYPE REF TO ZCL_CRMS4_BTX_DATA_MODEL_TOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_instance.
    ro_instance = so_instance.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->GET_ITEM
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_ITEM_GUID                   TYPE        CRMT_OBJECT_GUID_TAB
* | [<---] ET_ORDERADM_I_DB               TYPE        CRMT_ORDERADM_I_DU_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_item.
    DATA: lt_btx_i   TYPE TABLE OF zcrms4d_btx_i,
          lt_acronym TYPE TABLE OF zcrmc_sub_cat_i,
          lr_dbtab   TYPE REF TO data,
          lt_objects TYPE crmt_object_name_tab.

    FIELD-SYMBOLS: <lt_dbtab>         TYPE ANY TABLE.

    CHECK it_item_guid IS NOT INITIAL.

    SELECT  * INTO TABLE lt_btx_i FROM zcrms4d_btx_i FOR ALL ENTRIES IN
       it_item_guid WHERE item_guid = it_item_guid-table_line.

    CHECK sy-subrc = 0.

    SELECT * FROM zcrmc_sub_cat_i INTO TABLE lt_acronym
       FOR ALL ENTRIES IN lt_btx_i
         WHERE subobj_category = lt_btx_i-object_type.

* Jerry 2017-04-21 14:21PM for POC, I assume all items belong to the same item table
* Jerry 2017-04-25 9:21AM - one order can have multiple item with different item object type!!!
* this scenario needs to be enhanced later!!
    ASSERT lines( lt_acronym ) = 1.
    READ TABLE lt_btx_i INTO DATA(ls_btx_i) INDEX 1.

    READ TABLE lt_acronym ASSIGNING FIELD-SYMBOL(<acronym>) INDEX 1.

    DATA(lv_dbtab_name) = 'ZCRMS4D_' && <acronym>-acronym && '_I'.

    CREATE DATA lr_dbtab TYPE TABLE OF (lv_dbtab_name).
    ASSIGN lr_dbtab->* TO <lt_dbtab>.

    SELECT  * FROM (lv_dbtab_name) INTO TABLE <lt_dbtab> FOR ALL ENTRIES IN
        it_item_guid WHERE guid = it_item_guid-table_line.

    CHECK sy-subrc = 0.

* Get all possible components for the given header object type
    SELECT name FROM zcrmc_obj_assi_i INTO TABLE lt_objects WHERE subobj_category = ls_btx_i-object_type.

    LOOP AT <lt_dbtab> ASSIGNING FIELD-SYMBOL(<ls_dbtab>).
      conv_s4_2_1order_and_fill_buff( EXPORTING it_objects = lt_objects
                           CHANGING cs_item = <ls_dbtab> ).
      APPEND <ls_dbtab> TO et_orderadm_i_db.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->GET_ITEM_SUPPORTED_COMP
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ITEM_OBJECT_TYPE            TYPE        CRMT_SUBOBJECT_CATEGORY_DB
* | [<-()] RT_ITEM_SUPPORTED_COMP         TYPE        CRMT_OBJECT_NAME_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_item_supported_comp.
    READ TABLE mt_item_supported_comps ASSIGNING FIELD-SYMBOL(<supported>)
     WITH KEY object_type = iv_item_object_type.

    CHECK sy-subrc = 0.

    rt_item_supported_comp = <supported>-supported_comps.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->GET_UNSORTED_COMPONENT_LIST
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_SORTED_COMP                 TYPE        CRMT_OBJECT_NAME_TAB
* | [--->] IV_HEADER                      TYPE        ABAP_BOOL (default =ABAP_TRUE)
* | [<-()] RT_UNSORTED_COMP               TYPE        TT_SUPPORTED_COMPONENTS
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_unsorted_component_list.
    DATA: lv_line TYPE crmt_object_name.
    rt_unsorted_comp = it_sorted_comp.
    IF iv_header = abap_true.
      DELETE rt_unsorted_comp WHERE table_line = 'ORDERADM_H'.
      lv_line = 'ORDERADM_H'.
    ELSE.
      DELETE rt_unsorted_comp WHERE table_line = 'ORDERADM_I'.
      lv_line = 'ORDERADM_I'.
    ENDIF.

    INSERT lv_line INTO rt_unsorted_comp INDEX 1.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->SAVE_HEADER
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_HEADER_GUID                 TYPE        CRMT_OBJECT_GUID_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD save_header.
    fetch_header_object_type( it_header_guid ).
    fetch_header_supported_comp( ).
    fetch_component_conv_cls( ).
    LOOP AT it_header_guid ASSIGNING FIELD-SYMBOL(<guid>).
      save_single_header( <guid> ).
      save_single_items( <guid> ).
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->SAVE_SINGLE_HEADER
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_HEADER_GUID                 TYPE        CRMT_OBJECT_GUID
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD save_single_header.

    DATA: lr_to_insert_db TYPE REF TO data,
          lr_to_update_db TYPE REF TO data,
          lr_to_delete_db TYPE REF TO data.

    FIELD-SYMBOLS: <to_insert> TYPE ANY TABLE,
                   <to_update> TYPE ANY TABLE,
                   <to_delete> TYPE ANY TABLE.

    DATA(lv_object_type) = get_header_object_type_by_guid( iv_header_guid ).
    DATA(lt_header_supported_comp) = get_header_supported_comp( lv_object_type ).
    DATA(lt_unsorted) = get_unsorted_component_list( lt_header_supported_comp ).
    DATA(lv_comp_db_name) = get_header_db_type( iv_header_guid ).

    CREATE DATA lr_to_insert_db TYPE TABLE OF (lv_comp_db_name).
    ASSIGN lr_to_insert_db->* TO <to_insert>.

    CREATE DATA lr_to_update_db TYPE TABLE OF (lv_comp_db_name).
    ASSIGN lr_to_update_db->* TO <to_update>.

    CREATE DATA lr_to_delete_db TYPE TABLE OF (lv_comp_db_name).
    ASSIGN lr_to_delete_db->* TO <to_delete>.
    LOOP AT lt_unsorted ASSIGNING FIELD-SYMBOL(<component>).
      DATA(lv_conv_cls) = get_conv_cls_name_by_component( <component> ).
      CHECK lv_conv_cls IS NOT INITIAL.

      DATA(lo_convertor) = get_convertor_instance( lv_conv_cls ).

      CALL METHOD lo_convertor->convert_1o_to_s4
        EXPORTING
          iv_ref_guid  = iv_header_guid
          iv_ref_kind  = 'A'
        CHANGING
          ct_to_insert = <to_insert>
          ct_to_update = <to_update>
          ct_to_delete = <to_delete>.
    ENDLOOP.

    CALL FUNCTION 'ZCRM_SRVO_H_UPDATE_DU'
      EXPORTING
        it_to_insert = <to_insert>
        it_to_update = <to_update>
        it_to_delete = <to_delete>.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CRMS4_BTX_DATA_MODEL_TOOL->SAVE_SINGLE_ITEMS
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_HEADER_GUID                 TYPE        CRMT_OBJECT_GUID
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD save_single_items.
    DATA: lt_orderadm_i_wrk TYPE crmt_orderadm_i_wrkt,
          lt_objects        TYPE crmt_object_name_tab.
    CALL FUNCTION 'CRM_ORDERADM_I_READ_OB'
      EXPORTING
        iv_header         = iv_header_guid
      IMPORTING
        et_orderadm_i_wrk = lt_orderadm_i_wrk
      EXCEPTIONS
        OTHERS            = 0.

    fetch_item_supported_comp( lt_orderadm_i_wrk ).
    "fetch_item_conv_class( lt_orderadm_i_wrk ).
    LOOP AT lt_orderadm_i_wrk ASSIGNING FIELD-SYMBOL(<ls_orderadm_i_wrk>).
* Check if the item has really changed. How this is done: discussed below

* First identify the target structure, depending on the item object type
*  SELECT SINGLE acronym FROM crmc_subob_cat_i
*    INTO lv_acronym
*    WHERE subobj_category = <ls_orderadm_i_wrk>-object_type.
*  lv_struc_name = 'LS_' && lv_acronym && '_I'.
*  lv_table_name = 'LT_' && lv_acronym && '_I'.
*  ASSIGN (lv_struc_name) TO <ls_struc>.
*  ASSIGN (lv_table_name) TO <lt_table>.

      DATA(lt_item_supported_comp) = get_item_supported_comp( <ls_orderadm_i_wrk>-object_type ).
      DATA(lt_unsorted) = get_unsorted_component_list( it_sorted_comp = lt_item_supported_comp
                                                       iv_header      = abap_false ).

      LOOP AT lt_unsorted ASSIGNING FIELD-SYMBOL(<lv_object>).
*    CLEAR lv_conv_class.
*    SELECT SINGLE conv_class FROM crmc_objects
*      INTO lv_conv_class
*      WHERE name = <lv_object>.
*    CHECK lv_conv_class IS NOT INITIAL.
*    CALL METHOD (lv_conv_class)=>if_crms4_btx_data_model~convert_1o_to_s4
*      CHANGING
*          <ls_struc>.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.