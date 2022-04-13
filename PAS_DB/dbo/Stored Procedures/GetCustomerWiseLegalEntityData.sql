-- EXEC [dbo].[GetCustomerWiseLegalEntityData] 17
CREATE PROCEDURE [dbo].[GetCustomerWiseLegalEntityData]
	@CustomerId bigint = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	;WITH CTE AS(
		select so.ManagementStructureId,so.CustomerId,LE.[Name]
			from SalesOrder so
			INNER JOIN SalesOrderBillingInvoicing sobi WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId
			INNER JOIN SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.EntityMSID = so.ManagementStructureId AND soms.ModuleID=17
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			where sobi.InvoiceStatus = 'Invoiced'
			group by so.ManagementStructureId,so.CustomerId,LE.[Name]
			
			UNION ALL
			
			select wop.ManagementStructureId,WO.CustomerId,LE.[Name] from dbo.[WorkOrder] WO
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			   INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID
			   INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.EntityMSID = wop.ManagementStructureId AND soms.ModuleID=12
			   INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			   INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			   where wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0
			   group by wop.ManagementStructureId,WO.CustomerId,LE.[Name]
	)
	Select ManagementStructureId,[Name] AS LegalEntityName from CTE
	where CTE.CustomerId = @CustomerId
	group by ManagementStructureId,[Name]

	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCustomerWiseLegalEntityData' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@CustomerId AS VARCHAR(10)), '') + ''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END