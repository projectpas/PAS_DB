Create view [dbo].[StocklinePurchaseHistory] as
select distinct
IT.Description as ItemType,
PO.purchaseordernumber as #ofPO,
pop.ExtendedCost as Amount,
CNDN.description as Cond,
PO.vendorname as Vendor,
VNDR.createdby as CreatedBy,
VNDR.createddate as DateCreated,
POP.CreatedDate as POCreateDate,
VNDRCLS.classificationname as Classification
from stockline STL
LEFT JOIN Itemtype IT ON STL.itemtypeid=IT.itemtypeid
LEFT JOIN PurchaseOrder PO ON STL.PurchaseOrderId=PO.PurchaseOrderId
LEFT JOIN PurchaseOrderPart POP ON PO.PurchaseOrderId=POP.PurchaseOrderId
LEFT JOIN Vendor VNDR ON STL.VendorId=VNDR.VendorId
LEFT JOIN Condition CNDN ON STL.ConditionId=CNDN.ConditionId
LEFT JOIN ClassificationMapping CM ON VNDR.VendorId=CM.ModuleId
LEFT JOIN VendorClassification VNDRCLS ON CM.ClasificationId=VNDRCLS.VendorClassificationId