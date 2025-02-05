
CLASS zcl_rfq_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
    CLASS-DATA : access_token TYPE string .
    CLASS-DATA : xml_file TYPE string .
    TYPES :
      BEGIN OF struct,
        xdp_template TYPE string,
        xml_data     TYPE string,
        form_type    TYPE string,
        form_locale  TYPE string,
        tagged_pdf   TYPE string,
        embed_font   TYPE string,
      END OF struct."


    CLASS-METHODS :
      create_client
        IMPORTING url           TYPE string
        RETURNING VALUE(result) TYPE REF TO if_web_http_client
        RAISING   cx_static_check ,

      read_posts
        IMPORTING rfq_num         TYPE string
        RETURNING VALUE(result12) TYPE string
        RAISING   cx_static_check .
  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS lc_ads_render TYPE string VALUE '/ads.restapi/v1/adsRender/pdf'.
    CONSTANTS  lv1_url    TYPE string VALUE 'https://adsrestapi-formsprocessing.cfapps.jp10.hana.ondemand.com/v1/adsRender/pdf?templateSource=storageName&TraceLevel=2'  .
    CONSTANTS  lv2_url    TYPE string VALUE 'https://dev-tcul4uw9.authentication.jp10.hana.ondemand.com/oauth/token'  .
    CONSTANTS lc_storage_name TYPE string VALUE 'templateSource=storageName'.
    CONSTANTS lc_template_name TYPE string VALUE 'zmm_rfq_print/zmm_rfq_print'."'z/zpo_v2'."
*    CONSTANTS lc_template_name TYPE 'HDFC_CHECK/HDFC_MULTI_FINAL_CHECK'.

ENDCLASS.



CLASS zcl_rfq_print IMPLEMENTATION.


  METHOD create_client .
    DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
    result = cl_web_http_client_manager=>create_by_http_destination( dest ).

  ENDMETHOD .


  METHOD read_posts .


    TYPES : BEGIN OF ty_material,
              PurchaseOrder                 TYPE I_PurchaseOrderItemAPI01-PurchaseOrder,
              PurchaseOrderItem             TYPE I_PurchaseOrderItemAPI01-PurchaseOrderItem,

              SupplierQuotation             TYPE I_SupplierQuotationItemTP-SupplierQuotation,
              SupplierQuotationItem         TYPE I_SupplierQuotationItemTP-SupplierQuotationItem,
              requestforquotation(10)       TYPE c,
              RequestForQuotationItem(6)    TYPE c,
              Productcode(40)               TYPE c,
              safetystock                   TYPE i_productplantbasic-SafetyStockQuantity,
              productdesc(40)               TYPE c,
              orderquantity(15)             TYPE p DECIMALS 3,
              CreatedAt                     TYPE zrfqmatrix-created_at,
              GRNDate                       TYPE I_MaterialDocumentItem_2-PostingDate, " GRN Date
              QuantityInBaseUnit(13)        TYPE p DECIMALS 3,

              BusinessPartnerName1          TYPE I_Supplier-BusinessPartnerName1,
              BusinessPartnerName2          TYPE I_Supplier-BusinessPartnerName2,
              TradeName                     TYPE zi_dd_mat-TradeName,
              NetPriceAmount                TYPE I_PurchaseOrderItemAPI01-NetPriceAmount,
              cashdiscount1days             TYPE I_PurchaseOrderAPI01-CashDiscount1Days,
              planneddeliverydurationindays TYPE I_PurchaseOrderitemAPI01-PlannedDeliveryDurationInDays,
              PaymentTermsDescription       TYPE I_PaymentTermsText-PaymentTermsDescription,
              PurchaseOrderDate             TYPE I_PurchaseOrderAPI01-PurchaseOrderDate,
              landedcost                    TYPE I_PurchaseOrderItemAPI01-NetPriceAmount,
              freight                       TYPE I_PurchaseOrderItemAPI01-NetPriceAmount,
              avg_freight                   TYPE I_PurchaseOrderItemAPI01-NetPriceAmount,
              ReorderThresholdQuantity      TYPE I_ProductMRPArea-ReorderThresholdQuantity,
              matlwrhsstkqtyinmatlbaseunit  TYPE I_MaterialStock_2-matlwrhsstkqtyinmatlbaseunit,
            END OF ty_material.
    DATA : it_all_material  TYPE TABLE OF ty_material,
           wa_diff_material TYPE ty_material.
    DATA : it_diff_material TYPE TABLE OF ty_material.

    TYPES: BEGIN OF ty_main,
             SupplierQuotation             TYPE I_SupplierQuotationItemTP-SupplierQuotation,
             SupplierQuotationItem         TYPE I_SupplierQuotationItemTP-SupplierQuotationItem,
             freight                       TYPE I_supplierquotationprcelmnttp-ConditionBaseValue,
             avg_freight                   TYPE I_supplierquotationprcelmnttp-ConditionBaseValue,

             requestforquotation(10)       TYPE c,
             RequestForQuotationItem(6)    TYPE c,
             Material(40)                  TYPE c,
             ProductName(40)               TYPE c,
             Supplier(10)                  TYPE c,
             SupplierFullName(81)          TYPE c,
             orderquantity(15)             TYPE p DECIMALS 3,
             CreatedAt                     TYPE zrfqmatrix-created_at,
             netpaymentdays(5)             TYPE p DECIMALS 3,
             paymentterms(50)              TYPE c,
             grossamount(10)               TYPE p DECIMALS 2,
*             ActualFreight(10)             TYPE p DECIMALS 2,
*             Averagereight(10)             TYPE p DECIMALS 2,
*             Insurance(10)                 TYPE p DECIMALS 2,
             quotationsubmissiondate       TYPE sy-datum,
             consumptiontaxctrlcode(16)    TYPE c,


             "New Logic Body
             BusinessPartnerName1          TYPE I_Supplier-BusinessPartnerName1,
             BusinessPartnerName2          TYPE I_Supplier-BusinessPartnerName2,
             TradeName                     TYPE zi_dd_mat-TradeName,
             schedulelineorderquantity     TYPE I_SupplierQuotationItemTP-ScheduleLineOrderQuantity,
             NetPriceAmount                TYPE I_PurchaseOrderItemAPI01-NetPriceAmount,
             LandedCost                    TYPE I_PurchaseOrderItemAPI01-NetPriceAmount,
             cashdiscount1days             TYPE I_PurchaseOrderAPI01-CashDiscount1Days,
             planneddeliverydurationindays TYPE I_PurchaseOrderitemAPI01-PlannedDeliveryDurationInDays,
             PaymentTermsDescription       TYPE I_PaymentTermsText-PaymentTermsDescription,
             PurchaseOrderDate             TYPE I_PurchaseOrderAPI01-PurchaseOrderDate,




           END OF ty_main.

    TYPES: BEGIN OF ty_stockdate,
             material                     TYPE I_MaterialStock_2-Material,
             plant                        TYPE I_MaterialStock_2-Plant,
             StorageLocation              TYPE I_MaterialStock_2-StorageLocation,
             Batch                        TYPE I_MaterialStock_2-Batch,
             Supplier                     TYPE I_MaterialStock_2-Supplier,
             SDDocument                   TYPE I_MaterialStock_2-SDDocument,
             matlwrhsstkqtyinmatlbaseunit TYPE I_MaterialStock_2-matlwrhsstkqtyinmatlbaseunit,
           END OF ty_stockdate.

    DATA : it_stockdate     TYPE TABLE OF ty_stockdate,
           wa_stockdate     TYPE ty_stockdate,
           it_stockdate_sum TYPE TABLE OF ty_stockdate.

    DATA : it_main TYPE TABLE OF ty_main,
           wa_main TYPE ty_main.
    DATA : it_main_diff TYPE TABLE OF ty_main,
           wa_main_diff TYPE ty_main.

    TYPES : BEGIN OF ty_last_details,
              Material                      TYPE I_MaterialDocumentItem_2-Material,
              PostingDate                   TYPE I_MaterialDocumentItem_2-PostingDate,
              QuantityInBaseUnit            TYPE I_MaterialDocumentItem_2-QuantityInBaseUnit,
              Supplier                      TYPE I_MaterialDocumentItem_2-Supplier,
              PurchaseOrder                 TYPE I_MaterialDocumentItem_2-PurchaseOrder,
              BusinessPartnerName1          TYPE I_Supplier-BusinessPartnerName1,
              BusinessPartnerName2          TYPE I_Supplier-BusinessPartnerName2,
              TradeName                     TYPE zi_dd_mat-TradeName,
              NetPriceAmount                TYPE I_PurchaseOrderItemAPI01-NetPriceAmount,
              cashdiscount1days             TYPE I_PurchaseOrderAPI01-CashDiscount1Days,
              planneddeliverydurationindays TYPE I_PurchaseOrderitemAPI01-PlannedDeliveryDurationInDays,
              PaymentTermsDescription       TYPE I_PaymentTermsText-PaymentTermsDescription,
              PurchaseOrderDate             TYPE I_PurchaseOrderAPI01-PurchaseOrderDate,
              landedcost                    TYPE I_PurchaseOrderItemAPI01-NetPriceAmount,
              freight                       TYPE i_purorditmpricingelementapi01-ConditionRateValue,
              avg_freight                   TYPE i_purorditmpricingelementapi01-ConditionRateValue,
            END OF ty_last_details.
***Header Table
    SELECT FROM zr_rfqmatrixcds AS a
    INNER JOIN I_RequestForQuotationItemTP AS b ON a~Requestforquotation = b~RequestForQuotation AND a~Productcode = b~Material
    FIELDS a~requestforquotation, a~Productcode, a~Orderquantity, "a~CreatedAt,
    b~RequestForQuotationItem
    WHERE b~requestforquotation = @rfq_num
    INTO CORRESPONDING FIELDS OF TABLE @it_all_material.

**
*For Product Description
    SELECT FROM zr_rfqmatrixcds AS a
    FIELDS a~Productdesc, a~Requestforquotation, a~Productcode, a~CreatedAt
    FOR ALL ENTRIES IN @it_diff_material
    WHERE Productcode = @it_diff_material-productcode AND Requestforquotation = @it_diff_material-requestforquotation
    INTO TABLE @DATA(it_temp).

    LOOP AT it_all_material INTO wa_diff_material.
      COLLECT wa_diff_material INTO it_diff_material.
    ENDLOOP.


*All different Material present on Table : it_diff_material
    SORT it_diff_material BY requestforquotation requestforquotationitem.

    DATA(lv_no_ALL_mat) = lines( it_all_material ).
    DATA(lv_no_diff_mat) = lines( it_DIFF_material ).

*For Order Quantity
    SELECT FROM zr_rfqmatrixcds AS a
    FIELDS a~Orderquantity  , a~Requestforquotation
    FOR ALL ENTRIES IN @it_DIFF_material
    WHERE Requestforquotation = @it_DIFF_material-requestforquotation
    INTO TABLE @DATA(it_dummy).



******************************** Last Purchase Details ****************************************
    SELECT FROM I_RequestForQuotationitemTP AS a
        LEFT JOIN I_SupplierQuotationItemTP AS b ON a~RequestForQuotation = b~RequestForQuotation
                   AND a~RequestForQuotationItem = b~RequestForQuotationItem
        LEFT JOIN I_MaterialDocumentItem_2 AS c ON b~Material = c~Material
        LEFT JOIN I_Supplier AS d ON c~Supplier = d~Supplier
        LEFT JOIN zi_dd_mat AS e ON b~Material = e~Mat
        LEFT JOIN I_PurchaseOrderItemAPI01 AS f ON c~PurchaseOrder = f~PurchaseOrder AND c~PurchaseOrderItem = f~PurchaseOrderItem
        LEFT JOIN I_PurchaseOrderAPI01 AS g ON f~PurchaseOrder = g~PurchaseOrder
        LEFT JOIN I_PaymentTermsText AS h ON g~PaymentTerms = h~PaymentTerms AND h~Language = 'E'
*        left join I_ProductMRPArea as i on i~Product = b~Material
        FIELDS
        "a~RequestForQuotation, a~RequestForQuotationItem ,
        b~SupplierQuotation, b~SupplierQuotationItem,
        c~Material, c~PostingDate, c~QuantityInBaseUnit , c~Supplier , c~PurchaseOrder, d~BusinessPartnerName1, d~BusinessPartnerName2,
        e~TradeName, f~NetPriceAmount, f~PlannedDeliveryDurationInDays, f~PurchaseOrder AS PurchaseOrder1, f~PurchaseOrderItem,
         g~CashDiscount1Days, g~PurchaseOrderDate,
          h~PaymentTermsDescription
*          i~ReorderThresholdQuantity
        WHERE  a~requestforquotation = @rfq_num  AND c~GoodsMovementType = '101' "'6000000054'
        INTO TABLE @DATA(it_PO_QTY_DATE).
*    SORT it_po_qty_date BY PostingDate DESCENDING.
    SORT it_po_qty_date BY PostingDate DESCENDING Material ASCENDING .

    DELETE ADJACENT DUPLICATES FROM it_po_qty_date COMPARING material.

*"FREIGHT
*    SELECT PU, SupplierQuotationItem, ConditionBaseValue
*    FROM I_SupplierQuotationPrcElmntTP
*    WHERE ConditionType IN ('ZFR1', 'ZFR2', 'ZFR3')
*    INTO TABLE @DATA(lt_qUO_freight).
*
*" Fetch Average Freight Data for Condition Types ZGT1, ZGT2
*SELECT SupplierQuotation, SupplierQuotationItem, ConditionBaseValue
*    FROM I_SupplierQuotationPrcElmntTP
*    WHERE ConditionType IN ('ZGT1', 'ZGT2')
*    INTO TABLE @DATA(lt_QUO_avg_freight).






*Transposing & Maintaining Header Table
    LOOP AT it_DIFF_material INTO wa_DIFF_material.
      READ TABLE it_dummy INTO DATA(wa_dummy) WITH KEY Requestforquotation = wa_DIFF_material-requestforquotation.
      IF sy-subrc EQ 0.
        wa_DIFF_material-orderquantity = wa_dummy-Orderquantity.
      ENDIF.
      " this transposing for
      READ TABLE it_temp INTO DATA(wa_temp) WITH KEY Requestforquotation = wa_DIFF_material-requestforquotation
                                                      Productcode =  wa_diff_material-productcode.
      IF sy-subrc EQ 0.
        wa_DIFF_material-productdesc = wa_temp-Productdesc.
        wa_diff_material-createdat = wa_temp-CreatedAt.
      ENDIF.
      " this transposing for last purchasing date & quantity
      READ TABLE it_po_qty_date INTO DATA(wa_po_qty_date) WITH KEY Material = wa_diff_material-productcode.

      IF sy-subrc EQ 0.
        wa_DIFF_material-GRNDate = wa_po_qty_date-PostingDate.
        wa_diff_material-quantityinbaseunit = wa_po_qty_date-QuantityInBaseUnit. "Supply Quotation QTY
        """""""""""""""""""""""" NEW """"""""""""""""""""""""""""""""""""""
        wa_DIFF_material-tradename  = wa_po_qty_date-TradeName.
        wa_diff_material-businesspartnername1 = wa_po_qty_date-BusinessPartnerName1.
        wa_DIFF_material-businesspartnername2 = wa_po_qty_date-BusinessPartnerName2.
        wa_diff_material-netpriceamount = wa_po_qty_date-NetPriceAmount.

        wa_DIFF_material-cashdiscount1days = wa_po_qty_date-CashDiscount1Days.
        wa_diff_material-paymenttermsdescription = wa_po_qty_date-PaymentTermsDescription.

        wa_DIFF_material-purchaseorderdate = wa_po_qty_date-PurchaseOrderDate.
        wa_diff_material-planneddeliverydurationindays = wa_po_qty_date-PlannedDeliveryDurationInDays. " lead time
*        wa_DIFF_material-reorderthresholdquantity = wa_po_qty_date-ReorderThresholdQuantity.
        wa_diff_material-purchaseorder = wa_po_qty_date-purchaseorder1.
        wa_diff_material-purchaseorderitem = wa_po_qty_date-PurchaseOrderItem.
        wa_diff_material-supplierquotation = wa_po_qty_date-SupplierQuotation.
        wa_diff_material-supplierquotationitem = wa_po_qty_date-SupplierQuotationItem.

*        " tradename, bpname1 & bpname2 & netprice amount & CASHDISCOUNT1DAYS(Credit days) PAYMENTTERMS & PURCHASEORDERDATE &
* PLANNEDDELIVERYDURATIONINDAYS(Lead Time)
      ENDIF.

      MODIFY it_DIFF_material FROM wa_DIFF_material.
      CLEAR : wa_dummy, wa_DIFF_material, wa_temp, wa_po_qty_date.

    ENDLOOP.

    """"""""""""""""""""Code For Minimum Stock Qty """""""""""""""""""""""""""""""""""""""""""""""""
    SELECT
       product,
       SafetyStockquantity
  FROM I_ProductPlantBasic
  FOR ALL ENTRIES IN @it_DIFF_material
  WHERE Product = @it_DIFF_material-productcode
  INTO TABLE @DATA(it_safetystock).

    """"""""""""""""""""Code For Reorder Level """""""""""""""""""""""""""""""""""""""""""""""""
    SELECT
       product,
       ReorderThresholdQuantity
  FROM I_ProductMRPArea
  FOR ALL ENTRIES IN @it_DIFF_material
  WHERE Product = @it_DIFF_material-productcode
  INTO TABLE @DATA(it_reorderlevel).

    """"""""""""""""""""Code For Stock as on Date """""""""""""""""""""""""""""""""""""""""""""""""
    SELECT
       material,
       plant,
       StorageLocation,
        Batch,
        Supplier,
        SDDocument,
       matlwrhsstkqtyinmatlbaseunit
  FROM I_MaterialStock_2
  FOR ALL ENTRIES IN @it_DIFF_material
  WHERE material = @it_DIFF_material-productcode
  INTO TABLE @it_stockdate.
    SORT it_stockdate_sum BY material.
    LOOP AT it_stockdate INTO wa_stockdate.
      wa_stockdate-plant = ''.
      wa_stockdate-storagelocation = ''.
      wa_stockdate-batch = ''.
      COLLECT wa_stockdate INTO it_stockdate_sum.
      CLEAR wa_stockdate.
    ENDLOOP.
    SORT it_stockdate BY material.



    "FREIGHT Last Purchase Details
    SELECT purchaseOrder, purchaseOrderItem, ConditionRateValue
    FROM i_purorditmpricingelementapi01
    WHERE ConditionType IN ('ZFR1', 'ZFR2', 'ZFR3')
    INTO TABLE @DATA(lt_last_freight).

    " Fetch Average Freight Last Purchase Details Data for Condition Types ZGT1, ZGT2
    SELECT purchaseOrder, purchaseOrderItem, ConditionRateValue
        FROM i_purorditmpricingelementapi01
        WHERE ConditionType IN ('ZGT1', 'ZGT2')
        INTO TABLE @DATA(lt_last_avg_freight).

**
*****************************************For Line Item Table *****************************************
    SELECT FROM I_RequestForQuotationitemTP AS a
    LEFT JOIN I_SupplierQuotationItemTP AS b ON a~RequestForQuotation = b~RequestForQuotation
               AND a~RequestForQuotationItem = b~RequestForQuotationItem
    LEFT JOIN I_SupplierQuotationTP AS c ON b~SupplierQuotation = c~SupplierQuotation
    LEFT JOIN I_Supplier AS d ON c~Supplier = d~Supplier
    LEFT JOIN I_ProductText AS e ON a~Material = e~Product
    LEFT JOIN I_PaymentTermsText AS f ON f~PaymentTerms = c~PaymentTerms AND f~Language = 'E'
    LEFT JOIN zi_dd_mat AS g ON a~Material = g~Mat
     FIELDS  a~requestforquotation, a~RequestForQuotationItem,a~Material,
    b~SupplierQuotation, b~SupplierQuotationItem, b~ScheduleLineOrderQuantity,
            c~CashDiscount1Days, "c~NetPaymentDays,
            c~PaymentTerms,
            b~NetPriceAmount, "b~GrossAmount,
            d~Supplier, d~BusinessPartnerName1, d~BusinessPartnerName2,
            e~ProductName,
            f~PaymentTermsDescription,
            g~TradeName
    WHERE  a~requestforquotation = @rfq_num
    INTO CORRESPONDING FIELDS OF TABLE @it_main.
    DELETE it_main WHERE netpriceamount EQ '0.010' .
    DELETE it_main WHERE netpriceamount EQ '0.01' .
    DELETE it_main WHERE netpriceamount EQ '1.00'.
    SORT it_main BY requestforquotation requestforquotationitem.
    "FREIGHT
    SELECT SupplierQuotation, SupplierQuotationItem, ConditionBaseValue
    FROM I_SupplierQuotationPrcElmntTP
    WHERE ConditionType IN ('ZFR1', 'ZFR2', 'ZFR3')
    INTO TABLE @DATA(lt_qUO_freight).

    " Fetch Average Freight Data for Condition Types ZGT1, ZGT2
    SELECT SupplierQuotation, SupplierQuotationItem, ConditionBaseValue
        FROM I_SupplierQuotationPrcElmntTP
        WHERE ConditionType IN ('ZGT1', 'ZGT2')
        INTO TABLE @DATA(lt_QUO_avg_freight).

    LOOP AT it_main INTO wa_main.


      READ TABLE lt_quo_freight INTO DATA(wa_quo_freight) WITH KEY SupplierQuotation = wa_main-supplierquotation
                                                                   SupplierQuotationItem = wa_main-supplierquotationitem.
      IF sy-subrc EQ 0.
        wa_main-freight = wa_quo_freight-ConditionBaseValue.
      ENDIF.

      READ TABLE lt_QUO_avg_freight INTO DATA(wa_QUO_avg_freight) WITH KEY SupplierQuotation = wa_main-supplierquotation
                                                                   SupplierQuotationItem = wa_main-supplierquotationitem.
      IF sy-subrc EQ 0.
        wa_main-avg_freight = wa_QUO_avg_freight-ConditionBaseValue.
      ENDIF.
      wa_main-landedcost = wa_main-netpriceamount + wa_main-avg_freight + wa_main-freight.
      "+ wa_main-actualfreight + wa_main-averagereight + wa_main-insurance.
      MODIFY it_main FROM wa_main.
      CLEAR : wa_main.
    ENDLOOP.


    LOOP AT it_diff_material INTO wa_diff_material.


      READ TABLE lt_last_freight INTO DATA(wa_last_freight) WITH KEY PurchaseOrder = wa_diff_material-purchaseorder
                                                                   PurchaseOrderItem = wa_diff_material-purchaseorderitem.
      IF sy-subrc EQ 0.
        wa_diff_material-freight = wa_last_freight-ConditionRateValue.
      ENDIF.

      READ TABLE lt_last_avg_freight INTO DATA(wa_last_avg_freight) WITH KEY PurchaseOrder = wa_diff_material-purchaseorder
                                                                   PurchaseOrderItem = wa_diff_material-purchaseorderitem.
      IF sy-subrc EQ 0.
        wa_diff_material-avg_freight = wa_last_avg_freight-ConditionRateValue.
      ENDIF.

      READ TABLE it_safetystock INTO DATA(wa_safetystock) WITH KEY Product = wa_diff_material-productcode.
      IF sy-subrc EQ 0.
        wa_diff_material-safetystock = wa_safetystock-SafetyStockQuantity.
      ENDIF.

      READ TABLE it_reorderlevel INTO DATA(wa_reorderlevel) WITH KEY Product = wa_diff_material-productcode.
      IF sy-subrc EQ 0.
        wa_diff_material-reorderthresholdquantity = wa_reorderlevel-ReorderThresholdQuantity.
      ENDIF.

      READ TABLE it_stockdate_sum INTO DATA(wa_stockdate_sum) WITH KEY material = wa_diff_material-productcode.
      IF sy-subrc EQ 0.
        wa_diff_material-matlwrhsstkqtyinmatlbaseunit = wa_stockdate_sum-matlwrhsstkqtyinmatlbaseunit.
      ENDIF.

      wa_diff_material-landedcost = wa_diff_material-netpriceamount + wa_diff_material-avg_freight + wa_diff_material-freight."
      " + wa_main-insurance.
      "+ wa_main-cashdiscount1days.
      MODIFY it_diff_material FROM wa_diff_material.
      CLEAR : wa_diff_material.
    ENDLOOP.



    DATA : lv_xml TYPE string.
    lv_xml = '<Form><MaterialTable>'.
    LOOP AT  it_DIFF_material INTO wa_DIFF_material.
      SHIFT wa_diff_material-productcode LEFT DELETING LEADING '0'.
      DATA(lv_material_data) = |<MaterialWiseData>| &&
      |<REQUESTFORQUOTATION>{ WA_diff_material-requestforquotation }</REQUESTFORQUOTATION>| &&
      |<REQUESTFORQUOTATIONITEM>{ WA_diff_material-requestforquotationitem }</REQUESTFORQUOTATIONITEM>| &&
      |<PRODUCTCODE>{ wa_DIFF_material-productcode }</PRODUCTCODE>| &&
      |<productdesc>{ wa_DIFF_material-productdesc }</productdesc>| &&
      |<ORDERQUANTITY>{ wa_DIFF_material-orderquantity }</ORDERQUANTITY> | &&
      |<LASTGRNDATE>{ wa_DIFF_material-GRNDate }</LASTGRNDATE> | &&
      |<quantityinbaseunit>{ wa_DIFF_material-quantityinbaseunit }</quantityinbaseunit> | &&
      |<LP_RfqDate>{ wa_DIFF_material-createdat }</LP_RfqDate> | &&
*        " tradename, bpname1 & bpname2 & netprice amount & CASHDISCOUNT1DAYS(Credit days) PAYMENTTERMS & PURCHASEORDERDATE &
* PLANNEDDELIVERYDURATIONINDAYS(Lead Time)
      |<LP_Tradename>{ wa_DIFF_material-tradename }</LP_Tradename>| &&
      |<LP_businesspartnername1>{ wa_DIFF_material-businesspartnername1 }</LP_businesspartnername1>| &&
      |<LP_businesspartnername2>{ wa_DIFF_material-businesspartnername2 }</LP_businesspartnername2>| &&
      |<LP_NetpriceAmount>{ wa_DIFF_material-netpriceamount }</LP_NetpriceAmount>| &&
      |<LP_CashDiscount1Days>{ wa_DIFF_material-cashdiscount1days }</LP_CashDiscount1Days>| &&
      |<LP_PURCHASEORDERDATE>{ wa_DIFF_material-purchaseorderdate }</LP_PURCHASEORDERDATE>| &&
      |<LP_PLANNEDDELIVERYDURATIONINDAYS>{ wa_DIFF_material-planneddeliverydurationindays }</LP_PLANNEDDELIVERYDURATIONINDAYS>| &&
      |<LP_PaymentTermsDescription>{ wa_DIFF_material-paymenttermsdescription }</LP_PaymentTermsDescription>| &&
      |<LP_TradeName>{ wa_DIFF_material-tradename }</LP_TradeName>| &&
      |<LP_LandedCost>{ wa_DIFF_material-landedcost }</LP_LandedCost>| &&
      |<LP_Freight>{ wa_DIFF_material-freight }</LP_Freight>| &&
      |<LP_reorderthresholdquantity>{ wa_DIFF_material-reorderthresholdquantity }</LP_reorderthresholdquantity>| &&
      |<LP_MinimumStockQuant>{ wa_DIFF_material-safetystock }</LP_MinimumStockQuant>| &&
      |<LP_StockDate>{ wa_DIFF_material-matlwrhsstkqtyinmatlbaseunit }</LP_StockDate>| &&
      |<LP_AVG_Freight>{ wa_DIFF_material-avg_freight }</LP_AVG_Freight>|.
*        && |</MaterialWiseData>|.
      CONCATENATE lv_xml lv_material_data INTO lv_xml.

      CONCATENATE lv_xml  '<SupplierTable>' INTO lv_xml.


      LOOP AT it_main INTO wa_main.
        SHIFT wa_main-material LEFT DELETING LEADING '0'.
        IF wa_diff_material-requestforquotation EQ wa_main-requestforquotation AND wa_diff_material-requestforquotationitem EQ wa_main-requestforquotationitem.
          DATA(lv_supplier_data) = |<SupplierWiseData>| &&
         |<REQUESTFORQUOTATION>{ wa_main-requestforquotation }</REQUESTFORQUOTATION>| &&
         |<PRODUCTCODE>{ wa_main-material }</PRODUCTCODE>| &&
         |<PRODUCTNAME> { wa_main-ProductName }</PRODUCTNAME>| &&
         |<VENDORCODE>{ wa_main-supplier }</VENDORCODE>| &&
         |<VENDORNNAME>{ wa_main-supplierfullname }</VENDORNNAME>| &&
         |<ORDERQUANTITY>{ wa_main-orderquantity }</ORDERQUANTITY>| &&
         |<GrossAmount>{ wa_main-grossamount }</GrossAmount>| &&
         |<NetAmount>{ wa_main-netpriceamount }</NetAmount>| &&
         |<TradeName>{ wa_main-tradename }</TradeName>| &&
         |<CASHDISCOUNT1DAYS>{ wa_main-cashdiscount1days }</CASHDISCOUNT1DAYS>| &&
         |<NETPAYMENTDAYS>{ wa_main-netpaymentdays }</NETPAYMENTDAYS>| &&
         |<PAYMENTTERMS>{ wa_main-paymenttermsdescription }</PAYMENTTERMS>| &&
         |<QUOTATIONSUBMISSIONDATE>{ wa_main-quotationsubmissiondate }</QUOTATIONSUBMISSIONDATE>| &&
          |<QUO_businesspartnername1>{ wa_main-businesspartnername1 }</QUO_businesspartnername1>| &&
          |<QUO_businesspartnername2>{ wa_main-businesspartnername2 }</QUO_businesspartnername2>| &&
          |<QUO_Tradename>{ wa_main-tradename }</QUO_Tradename>| &&
          |<QUO_QuotationQty>{ wa_main-schedulelineorderquantity }</QUO_QuotationQty>| &&
          |<QUO_NetAmount>{ wa_main-netpriceamount }</QUO_NetAmount>| &&
          |<Quo_LandedCost>{ wa_main-landedcost }</Quo_LandedCost>| &&
          |<QUO_CashDiscount_CreditDays>{ wa_main-cashdiscount1days }</QUO_CashDiscount_CreditDays>| &&
          |<QUO_PaymentTermsDescription>{ wa_main-paymenttermsdescription }</QUO_PaymentTermsDescription>| &&
          |<QUO_Freight>{ wa_main-freight }</QUO_Freight>| &&
          |<QUO_AVG_Freight>{ wa_main-avg_freight }</QUO_AVG_Freight>| &&
         |</SupplierWiseData>|.

          CONCATENATE lv_xml lv_supplier_data INTO lv_xml.

        ENDIF.
      ENDLOOP.

*        CONCATENATE lv_xml lv_material_data INTO lv_xml.
      CONCATENATE lv_xml '</SupplierTable>' INTO lv_xml.
      CONCATENATE lv_xml '</MaterialWiseData>' INTO lv_xml.
    ENDLOOP.

    CONCATENATE lv_xml '</MaterialTable></Form>' INTO lv_xml.
    REPLACE ALL OCCURRENCES OF '&' IN lv_xml WITH 'and'.
    REPLACE ALL OCCURRENCES OF '&' IN lv_xml WITH 'and'.
    CALL METHOD ycl_test_adobe2=>getpdf(
      EXPORTING
        xmldata  = lv_xml
        template = lc_template_name
      RECEIVING
        result   = result12 ).


  ENDMETHOD .
ENDCLASS.



