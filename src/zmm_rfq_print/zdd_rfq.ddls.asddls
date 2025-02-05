//@AbapCatalog.sqlViewName: 'ZDD_RFQS'
//@AbapCatalog.compiler.compareFilter: true
//@AbapCatalog.preserveKey: true
//@AccessControl.authorizationCheck: #NOT_REQUIRED
//@EndUserText.label: 'cds view for RFQ report'
//@Metadata.ignorePropagatedAnnotations: true


@EndUserText.label: 'I_SupplierQuotationItemTP CDS'
@Search.searchable: false
@ObjectModel.query.implementedBy: 'ABAP:ZCL_RFQSCREEN'
@UI.headerInfo: {typeName: 'RFQ PRINT'}
define view  entity zdd_rfq as select from I_SupplierQuotationItem_Api01
{
     @Search.defaultSearchElement: true
      @UI.selectionField   : [{ position:1 }]
      @UI.lineItem   : [{ position:1, label:'RequestForQuotation Num' }]
  key RequestForQuotation,


      @Search.defaultSearchElement: true
      @UI.selectionField   : [{ position:2 }]
      @UI.lineItem   : [{ position:2, label:'RequestForQuotationItem' }]
  key RequestForQuotationItem,
      
      
      @Search.defaultSearchElement: true
      @UI.selectionField   : [{ position:3 }]
      @UI.lineItem   : [{ position:3, label:'SupplierQuotation' }]
      SupplierQuotation,
      
      @Search.defaultSearchElement: true
      @UI.selectionField   : [{ position:4 }]
      @UI.lineItem   : [{ position:4, label:'SupplierQuotationItem' }]
      SupplierQuotationItem,
      
      @Search.defaultSearchElement: true
      @UI.selectionField   : [{ position:5 }]
      @UI.lineItem   : [{ position:5, label:'material' }]
      Material

}
