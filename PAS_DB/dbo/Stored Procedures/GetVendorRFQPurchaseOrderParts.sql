/*************************************************************                 
 ** File:  [GetVendorRFQPurchaseOrderParts]                 
 ** Author:  Moin Bloch      
 ** Description: This stored procedure is used to Get vendor RFQ PO Part List      
 ** Purpose:               
 ** Date:   04/01/2022              
                
 ** PARAMETERS: @VendorRFQPurchaseOrderId bigint,      
               
 ** RETURN VALUE:                 
 **************************************************************                 
 ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change Description                  
 ** --   --------     -------  --------------------------------                
    1    04/01/2022  Moin Bloch     Created      
	2    04/12/2023  Moin Bloch     UPdated (Added Traceable & Tagged fields)  
           
-- EXEC [GetVendorRFQPurchaseOrderParts] 33     
************************************************************************/      
      
CREATE    PROCEDURE [dbo].[GetVendorRFQPurchaseOrderParts]      
@VendorRFQPurchaseOrderId bigint      
AS      
BEGIN      
 SET NOCOUNT ON;      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 BEGIN TRY      
  BEGIN      
  SELECT PP.[VendorRFQPOPartRecordId]      
        ,PP.[VendorRFQPurchaseOrderId]      
        ,PP.[ItemMasterId]      
        ,PP.[PartNumber]      
        ,PP.[PartDescription]      
        ,PP.[StockType]      
        ,PP.[ManufacturerId]      
        ,PP.[Manufacturer]      
        ,PP.[PriorityId]      
        ,PP.[Priority]      
        ,PP.[NeedByDate]      
        ,PP.[PromisedDate]      
        ,PP.[ConditionId]      
        ,PP.[Condition]      
        ,PP.[QuantityOrdered]      
        ,PP.[UnitCost]      
        ,PP.[ExtendedCost]      
        ,PP.[WorkOrderId]      
        --,PP.[WorkOrderNo]    
  --,WorkOrderRefNumber.newdata as WorkOrderNo  
  ,(CASE WHEN COUNT(PP.VendorRFQPOPartRecordId) > 1 AND MAX(WorkOrderRefNumber.newdata) = 'Multiple' Then 'Multiple' ELse MAX(WorkOrderRefNumber.newdata) End)  as 'WorkOrderNo'      
        ,(CASE WHEN COUNT(PP.VendorRFQPOPartRecordId) > 1 AND MAX(SalesOrderRefNumber.newdata) = 'Multiple' Then 'Multiple' ELse MAX(SalesOrderRefNumber.newdata) End)  as 'SalesOrderNo'  
        ,(CASE WHEN COUNT(PP.VendorRFQPOPartRecordId) > 1 AND MAX(SubWorkOrderRefNumber.newdata) = 'Multiple' Then 'Multiple' ELse  MAX(SubWorkOrderRefNumber.newdata) End)  as 'SubWorkOrderNo'      
        ,PP.[SubWorkOrderId]      
        --,PP.[SubWorkOrderNo]      
        ,PP.[SalesOrderId]      
        --,PP.[SalesOrderNo]      
        ,PP.[ManagementStructureId]      
        ,PP.[Level1]      
        ,PP.[Level2]      
        ,PP.[Level3]      
        ,PP.[Level4]      
        ,PP.[Memo]      
        ,PP.[MasterCompanyId]      
        ,PP.[CreatedBy]      
        ,PP.[UpdatedBy]      
        ,PP.[CreatedDate]      
        ,PP.[UpdatedDate]      
        ,PP.[IsActive]      
        ,PP.[IsDeleted]      
     ,PP.[PurchaseOrderId]      
     ,PP.[PurchaseOrderNumber]      
     ,PP.[UOMId]      
     ,PP.[UnitOfMeasure]
	 ,PP.[TraceableTo]
	 ,PP.[TraceableToName]
	 ,PP.[TraceableToType]
	 ,PP.[TagTypeId]
	 ,PP.[TaggedBy]
	 ,PP.[TaggedByType]
	 ,PP.[TaggedByName]
	 ,PP.[TaggedByTypeName]
	 ,PP.[TagDate]
     ,PO.[CreatedDate] AS POCreatedDate      
     ,PO.[Status] AS POStatus      
     ,POMSD.[EntityMSID] AS EntityStructureId      
     ,POMSD.[LastMSLevel] AS LastMSLevel      
     ,POMSD.[AllMSlevels] AS AllMSlevels      
    FROM [dbo].[VendorRFQPurchaseOrderPart] PP WITH (NOLOCK)       
    LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON PP.PurchaseOrderId = PO.PurchaseOrderId      
    JOIN [dbo].[PurchaseOrderManagementStructureDetails] POMSD ON PP.VendorRFQPOPartRecordId = POMSD.ReferenceID AND POMSD.ModuleID = 21      
  
  
 OUTER APPLY(      
   select DISTINCT   stuff((select ',' + t2.WorkOrderNum from VendorRFQPurchaseOrderPartReference t left join WorkOrder t2 with(nolock) on t.ReferenceId = t2.WorkOrderId   and t.ModuleId = 1 WHERE VendorRFQPOPartRecordId = PP.VendorRFQPOPartRecordId    
for xml path(''),TYPE).value('.','varchar(max)') , 1,1,'') as newdata   from VendorRFQPurchaseOrderPartReference WHERE VendorRFQPOPartRecordId = PP.VendorRFQPOPartRecordId   
    ) AS WorkOrderRefNumber   
      OUTER APPLY(      
   select DISTINCT   stuff((select ',' + s.SalesOrderNumber from VendorRFQPurchaseOrderPartReference t left join SalesOrder s with(nolock) on t.ReferenceId = s.SalesOrderId   and t.ModuleId = 3 WHERE VendorRFQPOPartRecordId = PP.VendorRFQPOPartRecordId 
   for xml path(''),TYPE).value('.','varchar(max)') , 1,1,'') as newdata   from VendorRFQPurchaseOrderPartReference WHERE VendorRFQPOPartRecordId = PP.VendorRFQPOPartRecordId   
    ) AS SalesOrderRefNumber   
   
      OUTER APPLY(      
   select DISTINCT   stuff((select ',' + sw.SubWorkOrderNo from VendorRFQPurchaseOrderPartReference t left join SubWorkOrder sw with(nolock) on t.ReferenceId = sw.SubWorkOrderId   and t.ModuleId = 5 WHERE VendorRFQPOPartRecordId = PP.VendorRFQPOPartRecordId    for xml path(''),TYPE).value('.','varchar(max)') , 1,1,'') as newdata   from VendorRFQPurchaseOrderPartReference WHERE VendorRFQPOPartRecordId = PP.VendorRFQPOPartRecordId    
    ) AS SubWorkOrderRefNumber   
  
    
    WHERE PP.[VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND PP.IsDeleted = 0      
  
 GROUP BY PP.VendorRFQPOPartRecordId,PP.VendorRFQPurchaseOrderId,PP.ItemMasterId,PP.PartNumber,PP.PartDescription,PP.StockType,PP.ManufacturerId,PP.Manufacturer,PP.PriorityId,PP.Priority,PP.NeedByDate,PP.PromisedDate,PP.ConditionId,PP.Condition,PP.QuantityOrdered,PP.UnitCost,PP.ExtendedCost,PP.WorkOrderId,PP.SubWorkOrderId,PP.SalesOrderId,PP.ManagementStructureId,PP.Level1,PP.Level2,PP.Level3,PP.Level4,PP.Memo,PP.MasterCompanyId,PP.CreatedBy,PP.CreatedDate,PP.UpdatedBy,PP.UpdatedDate,PP.IsActive,
 PP.IsDeleted,PP.PurchaseOrderId,PP.PurchaseOrderNumber,PP.UOMId,PP.UnitOfMeasure,
 [TraceableTo],[TraceableToName],[TraceableToType],[TagTypeId],[TaggedBy],[TaggedByType],[TaggedByName],[TaggedByTypeName] ,[TagDate],
 PO.CreatedDate,PO.Status,POMSD.EntityMSID,POMSD.LastMSLevel,POMSD.AllMSlevels  
   
 END      
 END TRY          
 BEGIN CATCH      
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
            , @AdhocComments     VARCHAR(150)    = 'GetVendorRFQPurchaseOrderParts'       
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQPurchaseOrderId, '') + ''      
            , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
            exec spLogException       
                    @DatabaseName           = @DatabaseName      
                    , @AdhocComments          = @AdhocComments      
                    , @ProcedureParameters = @ProcedureParameters      
                    , @ApplicationName        =  @ApplicationName      
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;      
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)      
            RETURN(1);      
 END CATCH      
END