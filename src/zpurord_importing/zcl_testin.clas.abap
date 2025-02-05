CLASS zcl_testin DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_testin IMPLEMENTATION.

METHOD if_oo_adt_classrun~main.

  DATA: result12 TYPE string.

  " Retrieve Purchase Order Header Information
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
  WHERE a~PurchaseOrder = '1300000000'
  INTO @DATA(wa).

  " Retrieve Purchase Order Items
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
  WHERE a~PurchaseOrder = '1300000000'
  INTO TABLE @DATA(it).

  " Retrieve Payment Terms
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
  WHERE a~PurchaseOrder = '1300000000'
  INTO @DATA(wa2).

  " Concatenate addresses
  DATA: vendor_add TYPE char256,
        comp_add   TYPE char256.

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

  " Add XML for each Purchase Order Item
  LOOP AT it INTO DATA(wa_item).
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
    CONCATENATE main_xml item_xml INTO main_xml.
  ENDLOOP.

  " Construct XML Footer
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

  CONCATENATE main_xml footer_xml INTO main_xml.


*   out->write( main_xml ).


   CALL METHOD ycl_test_adobe2=>getpdf(
     EXPORTING
       xmldata  = main_xml
       template = 'zpo_import/zpo_import'
     RECEIVING
       result   = result12 ).

ENDMETHOD.

ENDCLASS.


