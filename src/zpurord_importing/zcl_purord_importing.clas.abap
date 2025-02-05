CLASS zcl_purord_importing DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
*    INTERFACES if_oo_adt_classrun.
    CLASS-METHODS :
*      create_client
*        IMPORTING url           TYPE string
*        RETURNING VALUE(result) TYPE REF TO if_web_http_client
*        RAISING   cx_static_check ,

      read_posts
        IMPORTING lv_PO2       TYPE string
        RETURNING VALUE(result12) TYPE string
        RAISING   cx_static_check .
  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS lc_template_name TYPE string VALUE 'zpo_import/zpo_import'."'zpo/zpo_v2'."
ENDCLASS.



CLASS zcl_purord_importing IMPLEMENTATION.

  METHOD read_posts .

*******************************************************************************Header Select Query

 SELECT SINGLE
    a~PurchaseOrder,
    a~supplier,
    a~PurchaseOrderdate,
    a~YY1_QUOTATION_DATE_PO_PDH,
    a~YY1_QUOTATION_NO_PDH,
    b~companycodename,
    c~HouseNumber,
    c~StreetName,
    c~CityName,
    d~SupplierName,
    d~BPAddrStreetName,
    d~CityName AS cn,
    d~BUSINESSPARTNERPANNUMBER,
    d~POSTALCODE,
    d~TAXNUMBER3,
    e~RegionName,
    g~businesspartnername,
    h~CreationDate
  FROM i_purchaseorderapi01 AS a
  LEFT JOIN i_companycode AS b ON a~CompanyCode = b~CompanyCode
  LEFT JOIN I_Address_2 AS c ON c~ADDRESSID = b~ADDRESSID
  LEFT JOIN i_supplier AS d ON d~Supplier = a~Supplier
  LEFT JOIN i_regiontext AS e ON e~REGION = d~REGION
  LEFT JOIN i_Businesspartner AS g ON g~BusinessPartner = d~Supplier
  LEFT JOIN I_SUPPLIERQUOTATIONTP AS h ON h~Supplier = a~Supplier

  WHERE a~PurchaseOrder = @lv_po2
  INTO  @DATA(WA).


*******************************************************************************ITEM Select Query

  SELECT
    a~YY1_HSCODE_PDI,
    a~BASEUNIT,
    a~OrderQuantity,
    a~NETPRICEAMOUNT,
    a~DocumentCurrency,
    a~YY1_PackingMode_PDI,
    b~ProductName
  FROM I_PurchaseOrderItemAPI01 AS a
  LEFT JOIN i_producttext As b ON b~Product = a~Material
  WHERE a~PurchaseOrder = @lv_po2
  INTO TABLE @DATA(IT).


  SELECT SINGLE
    a~purchaseorder,
    a~YY1_DELIVERYTEXT_PDH,
    a~YY1_ITEMTEXT_PDH,
    b~PaymentTermsName,
    e~CountryName,
    d~ValidityEndDate
  FROM I_PurchaseOrderAPI01 AS a
  LEFT JOIN I_PAYMENTTERMSTEXT AS b ON b~PaymentTerms = a~PaymentTerms
  LEFT JOIN I_SUPPLIER AS c ON c~Supplier = a~Supplier
  LEFT JOIN I_PurchaseOrderTP_2 AS d ON d~PurchaseOrder = a~PurchaseOrder
  LEFT JOIN I_CountryText AS e ON e~Country = c~Country
  WHERE a~PurchaseOrder = @lv_po2
  INTO @DATA(wa2).

*******************************************************************************Header XML
data : vendor_add type char256 .
data : comp_add type char256.
CONCATENATE wa-HouseNumber wa-CityName wa-StreetName INTO comp_add SEPARATED BY space.
CONCATENATE wa-BPAddrStreetName wa-businesspartnername wa-cn wa-POSTALCODE wa-RegionName INTO vendor_add SEPARATED BY space.
DATA(main_xml) =
|<FORM>| &&
|<PurchaseOrderNode>| &&
|<HEADER>| &&
|<COMPANYNAME>{ wa-companycodename }</COMPANYNAME>| &&
|<COMPANYADDRESS>{ comp_add }</COMPANYADDRESS>| &&
|<DOCNO>{ wa-PurchaseOrder }</DOCNO>| &&
|<VENDORNAME>{ wa-SupplierName }</VENDORNAME>| &&
|<VENDORADDRESS>{ vendor_add }</VENDORADDRESS>| &&
|<PARTYCODE>{ wa-Supplier }</PARTYCODE>| &&
|<PANNUMBER>{ wa-BUSINESSPARTNERPANNUMBER }</PANNUMBER>| &&
|<GSTIN>{ wa-TAXNUMBER3 }</GSTIN>| &&
|<P.O.NUMBER>{ wa-PurchaseOrder }</P.O.NUMBER>| &&
|<P.O.DATE>{ wa-PurchaseOrderDate }</P.O.DATE>| &&
|<QUOTATION.NO>{ wa-YY1_QUOTATION_NO_PDH }</QUOTATION.NO>| &&
|<QUOTATION.DATE>{ wa-YY1_QUOTATION_DATE_PO_PDH }</QUOTATION.DATE>| &&
|</HEADER>| &&
|<PurchaseOrderItems>|.


*******************************************************************************ITEM XML


LOOP AT IT INTO DATA(WA_ITEM).
DATA(item_xml) =
|<PurchaseOrderItemNode>| &&
|<DESCRIPTION>{ wa_item-ProductName }</DESCRIPTION>| &&
|<PACKINGMODE>{ wa_item-YY1_PackingMode_PDI }</PACKINGMODE>| &&
|<HSCODE>{ wa_item-YY1_HSCODE_PDI }</HSCODE>| &&
|<UOM>{ wa_item-BaseUnit }</UOM>| &&
|<QTY>{ wa_item-OrderQuantity }</QTY>| &&
|<RATEPERUNIT>{ wa_item-NetPriceAmount }</RATEPERUNIT>| &&
|<CURRENCY>{ wa_item-DocumentCurrency }</CURRENCY>| &&
|</PurchaseOrderItemNode>|.
clear wa_item.
CONCATENATE MAIN_XML ITEM_XML INTO MAIN_XML.
ENDLOOP.


*******************************************************************************FOOTER XML

*CONCATENATE WA2-house_num1 WA2-street WA2-city1 WA2-post_code1 into WA2-house_num1.
DATA(footer_xml) =
|</PurchaseOrderItems>| &&
|<FOOTER>| &&
|<PAYMENTTERMS>{ wa2-PaymentTermsName }</PAYMENTTERMS>| &&
|<COUNTRYOFORIGIN>{ wa2-CountryName }</COUNTRYOFORIGIN>| &&
|<MODEOFDISPATCH>{ wa2-YY1_DELIVERYTEXT_PDH }</MODEOFDISPATCH>| &&
|<SHIPPINGTERMS>{ wa2-YY1_ITEMTEXT_PDH }</SHIPPINGTERMS>| &&
|<ORDERVALIDITY>{ wa2-ValidityEndDate }</ORDERVALIDITY>| &&
|</FOOTER>| &&
|</PurchaseOrderNode>| &&
|</FORM>|.
CONCATENATE MAIN_XML FOOTER_XML INTO MAIN_XML.

*out->write(  MAIN_XML ).

    CALL METHOD ycl_test_adobe2=>getpdf(
      EXPORTING
        xmldata  = main_xml
        template = lc_template_name
      RECEIVING
        result   = result12 ).

  ENDMETHOD.
ENDCLASS.

