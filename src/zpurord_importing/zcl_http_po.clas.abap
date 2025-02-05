CLASS zcl_http_po DEFINITION

  PUBLIC

  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_http_service_extension.

    METHODS: get_html RETURNING VALUE(ui_html) TYPE string,
      post_html IMPORTING lv_PO TYPE string RETURNING VALUE(html) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.

CLASS zcl_http_po IMPLEMENTATION.

  METHOD if_http_service_extension~handle_request.

    DATA(req_method) = request->get_method( ).

    CASE req_method.

      WHEN CONV string( if_web_http_client=>get ).
        " Handle GET request

        response->set_text( get_html( ) ).

      WHEN CONV string( if_web_http_client=>post ).
        " Handle POST request

        DATA(lv_PO) = request->get_form_field( `PO` ).

        response->set_text( post_html( lv_PO ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD get_html.

    SELECT FROM i_purchaseorderapi01
    FIELDS PurchaseOrder, supplier, PurchaseOrderdate
  INTO TABLE @DATA(it).

    DATA count TYPE string.

    count = lines( it ).

    ui_html = |<html><head><title>General Information</title></head><body style="margin:0 ;background-color:#495767;">|.

    CONCATENATE ui_html
                 '<form action="/sap/bc/http/sap/ZCL_HTTP_PO" method="POST">'
                 '<label style = "color:white;font-size:17px" for="PO">Print Document Number</label>'
                 '<input style="font-size:17px;padding:2px 3px;background:transparent;border:1px solid white;margin:4px;color: white;" type="text" id="PO" name="PO" required>'
                 '<input style="font-size:14px;background-color:#1b8dec;padding:5px 17px;border-radius: 6px;cursor:pointer;border:none;color:white;font-weight:700;" type="submit" value="Print">'
                 '</form>'
               '</body></html>' INTO ui_html.
  ENDMETHOD.


  METHOD post_html.

    DATA lv_po2 TYPE string.
    DATA lv_po4 TYPE string.

    DATA(lv_poo) = strlen( lv_Po ).

    IF ( lv_poo < 10 ).
      CONCATENATE '0' lv_po INTO lv_po4.
      SELECT SINGLE FROM i_purchaseorderapi01

        FIELDS PurchaseOrder

        WHERE PurchaseOrder = @lv_po4
        INTO @lv_PO2.
    ELSE.
      SELECT SINGLE FROM i_purchaseorderapi01

      FIELDS PurchaseOrder

      WHERE PurchaseOrder = @lv_po
      INTO @lv_PO2.
    ENDIF.


*    IF lv_po IS NOT INITIAL.
    IF lv_poo = 10.
      TRY.
          DATA(pdf_content) = zcl_purord_importing=>read_posts( lv_po2 = lv_po ).
*            DATA(pdf_content) = zcl_purord_importing=>read_posts( LV_PO2 = '0500000014' ).

          html = |{ pdf_content }|.
*           html = |<html><body><iframe src="data:application/pdf;base64,{ pdf_content }" width="100%" height="600px"></iframe></body></html>|.

        CATCH cx_static_check INTO DATA(er).
          html = |Purchase Order does not exist: { er->get_longtext( ) }|.
      ENDTRY.
*    ELSEif lv_po4 is not INITIAL.
    ELSEIF lv_poo < 10.
      TRY.
          pdf_content = zcl_purord_importing=>read_posts( lv_po2 = lv_po4 ).

          html = |{ pdf_content }|.

        CATCH cx_static_check INTO er.
          html = |Purchase Order does not exist: { er->get_longtext( ) }|.
      ENDTRY.

    ELSE.
      html = |Purchase Order not found|.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
