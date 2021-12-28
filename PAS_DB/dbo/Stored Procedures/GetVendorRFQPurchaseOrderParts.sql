


-- EXEC GetVendorRFQPurchaseOrderParts 10
CREATE PROCEDURE [dbo].[GetVendorRFQPurchaseOrderParts]
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
		      ,PP.[WorkOrderNo]
		      ,PP.[SubWorkOrderId]
		      ,PP.[SubWorkOrderNo]
		      ,PP.[SalesOrderId]
		      ,PP.[SalesOrderNo]
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
		  FROM [dbo].[VendorRFQPurchaseOrderPart] PP WITH (NOLOCK)
		  WHERE PP.[VendorRFQPurchaseOrderId] = @VendorRFQPurchaseOrderId AND PP.IsDeleted = 0;

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