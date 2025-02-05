CLASS zpo_adobexml_dr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZPO_ADOBEXML_DR IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA: purchaseorder TYPE i_purchaseorderapi01-PurchaseOrder.
    purchaseorder = '80000003'.

*******************************************************************************Header Select Query

    SELECT SINGLE
    a~PurchaseOrder,
    a~supplier,
    a~PurchaseOrderdate,
    b~companycodename,
*    c~HouseNumber,
*    c~StreetName,
*    c~CityName,
*    c~PhoneNumber,
*    c~FaxNumber,
    d~SupplierName,
    d~BPAddrStreetName,
*    d~STREETPREFIXNAME1,
*    d~CITYNAME,
    d~BUSINESSPARTNERPANNUMBER,
    d~POSTALCODE,
    d~TAXNUMBER3,
    e~RegionName

    FROM i_purchaseorderapi01 AS a
    LEFT JOIN i_companycode AS b ON a~CompanyCode = b~CompanyCode
*    LEFT JOIN I_Address AS c ON c~ADDRESSID = b~ADDRESSID
    LEFT JOIN i_supplier AS d ON d~Supplier = a~Supplier
    LEFT JOIN i_regiontext AS e ON  e~REGION = d~REGION


    WHERE a~PurchaseOrder = @purchaseorder
    INTO  @DATA(WA).


*******************************************************************************ITEM Select Query

SELECT
a~SupplierMaterialNumber,
* a~YY1_HSCODE_PDI,
a~BASEUNIT,
* a~SCHEDULELINEORDERQUANTITY,
a~NETPRICEAMOUNT
FROM I_PurchaseOrderItemAPI01 AS a
INTO TABLE @DATA(IT).

*out->write( WA ).
*OUT->WRITE( IT ).


*******************************************************************************Header XML
*CONCATENATE WA-Housenumber WA-CityName WA-StreetName into WA-Housenumber.
*CONCATENATE WA-BPADDRSTREETNAME WA-STREETPREFIXNAME1 WA-CITYNAME WA-POSTALCODE WA-RegionName into WA-BPAddrStreetName.
DATA(HEADER_XML) =
|<FORM>| &&
|<HEADER>| &&
|<COMPANYNAME>{ WA-CompanyCodeName }</COMPANYNAME>| &&
*|<COMPANYADDRESS>{ WA-HouseNumber }</COMPANYADDRESS>| &&
*|<PHONENUMBER>{ WA-PhoneNumber }</PHONENUMBER>| &&
*|<FAX>{ WA-FaxNumber }</FAX>| &&
|<DOCNO>{ WA-PurchaseOrder }</DOCNO>| &&
|<VENDORNAME>{ WA-SupplierName }</VENDORNAME>| &&
|<VENDORADDRESS>{ WA-BPAddrStreetName }</VENDORADDRESS>| &&
|<PARTYCODE>{ WA-Supplier }</PARTYCODE>| &&
|<PANNUMBER>{ WA-BUSINESSPARTNERPANNUMBER }</PANNUMBER>| &&
|<GSTIN>{ WA-TAXNUMBER3 }</GSTIN>| &&
|<P.O.NUMBER>{ WA-PurchaseOrder }</P.O.NUMBER>| &&
|<P.O.DATE>{ WA-PurchaseOrderDate }</P.O.DATE>| &&
|</HEADER>|.


*******************************************************************************ITEM XML


LOOP AT IT INTO DATA(WA_ITEM).
DATA(ITEM_XML) =
|<ITEM>| &&
|<DESCRIPTION>{ WA_ITEM-SupplierMaterialNumber }</DESCRIPTION>| &&
*|<HSCODE>{ WA_ITEM-YY1_HSCODE_PDI }</HSCODE>| &&
|<UOM>{ WA_ITEM-BaseUnit }</UOM>| &&
*|<QTY>{ WA_ITEM-SCHEDULELINEORDERQUANTITY }</QTY>| &&
|<RATEPERUNIT>{ WA_ITEM-NetPriceAmount }</RATEPERUNIT>| &&
|</ITEM>| &&
|</FORM>|.
ENDLOOP.

CONCATENATE HEADER_XML ITEM_XML INTO HEADER_XML.
out->write( HEADER_XML ).
  ENDMETHOD.
ENDCLASS.
