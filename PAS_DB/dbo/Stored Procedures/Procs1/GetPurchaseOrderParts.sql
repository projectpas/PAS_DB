
CREATE PROC [dbo].[GetPurchaseOrderParts]
@PurchaseOrderId  bigint
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		BEGIN		
		SELECT PP.[PurchaseOrderPartRecordId]
              ,PP.[PurchaseOrderId]
              ,PP.[ItemMasterId]
              --,PP.[SerialNumber]
              ,PP.[QuantityOrdered]
              ,PP.[QuantityBackOrdered]
              --,PP.[NonInventory]
              --,PP.[RequisitionedBy]
              --,PP.[RequisitionedDate]
              --,PP.[Approver]
              --,PP.[ApprovedDate]
              ,PP.[NeedByDate]
              ,PP.[ManufacturerId]
              --,PP.[Status]
              ,PP.[UOMId]
              ,PP.[UnitCost]
              ,PP.[DiscountPercent]
              ,PP.[DiscountAmount]
              ,PP.[ExtendedCost]
              ,PP.[ReportCurrencyId]
              ,PP.[FunctionalCurrencyId]
              ,PP.[ForeignExchangeRate]
              ,PP.[WorkOrderId]
              ,PP.[SubWorkOrderId]
              ,PP.[RepairOrderId]
              ,PP.[SalesOrderId]
              ,PP.[GlAccountId]
              ,PP.[Memo]
              ,PP.[POPartSplitUserTypeId]
              ,PP.[POPartSplitUserId]
              ,PP.[POPartSplitAddressId]
              ,PP.[POPartSplitAddress1]
              ,PP.[POPartSplitAddress2]
              ,PP.[POPartSplitAddress3]
              ,PP.[POPartSplitCity]
              ,PP.[POPartSplitState]
              ,PP.[POPartSplitPostalCode]
              ,PP.[POPartSplitCountryId]
              ,PP.[ManagementStructureId]
              ,PP.[MasterCompanyId]
              ,PP.[CreatedBy]
              ,PP.[UpdatedBy]
              ,PP.[CreatedDate]
              ,PP.[UpdatedDate]
              ,PP.[IsActive]
              ,PP.[isParent]
              ,PP.[ConditionId]
              --,PP.[Trace]
              ,PP.[ParentId]
              ,PP.[DiscountPerUnit]
              ,PP.[QuantityRejected]
              ,PP.[IsDeleted]
              ,PP.[AltEquiPartNumberId]
              ,PP.[VendorListPrice]
              ,PP.[PriorityId]
              ,PP.[POPartSplitCountryName]
              ,PP.[POPartSplitSiteId]
              ,PP.[POPartSplitSiteName] 		
		FROM PurchaseOrderPart PP WITH (NOLOCK) INNER JOIN PurchaseOrder PO WITH (NOLOCK)
		ON PP.PurchaseOrderId = PO.PurchaseOrderId
		WHERE PP.PurchaseOrderId = @PurchaseOrderId AND PO.IsDeleted = 0;
	END
	END TRY    
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPurchaseOrderParts' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderId, '') + ''
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