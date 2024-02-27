/*************************************************************           
 ** File:   [GetCustomerWiseLegalEntityData]
 ** Author: unknown
 ** Description: This stored procedure is used to Get CustomerWise LegalEntityData
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1					unknown			Created
	2	01/31/2024		Devendra Shekh	added isperforma Flage for WO
	3	02/1/2024		AMIT GHEDIYA	added isperforma Flage for SO
	4	19/2/2024		Devendra Shekh	REMOVED isperforma Flage for WO
	5	27/2/2024		AMIT GHEDIYA	REMOVED isperforma Flage for SO

************************************************************************/
-- EXEC [dbo].[GetCustomerWiseLegalEntityData] 68,'2022-04-25','2022-04-27'
CREATE   PROCEDURE [dbo].[GetCustomerWiseLegalEntityData]
@CustomerId bigint = null,
@StartDate datetime=null,
@EndDate datetime=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12,@SOAddessModuleID INT=10;
	;WITH CTE AS(
		select le.LegalEntityId,so.ManagementStructureId,so.CustomerId,LE.[Name],sobi.BillToSiteId AS 'BillToSiteId',aas.UserType AS 'UserType'
			from SalesOrder so
			INNER JOIN SalesOrderBillingInvoicing sobi WITH(NOLOCK) ON so.SalesOrderId = sobi.SalesOrderId 
			INNER JOIN SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.EntityMSID = so.ManagementStructureId AND soms.ModuleID=@SOMSModuleID
			INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			INNER JOIN AllAddress aas WITH(NOLOCK) ON aas.ReffranceId = so.SalesOrderId AND aas.ModuleId = @SOAddessModuleID AND aas.IsShippingAdd=0
			where sobi.InvoiceStatus = 'Invoiced' AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			group by so.ManagementStructureId,so.CustomerId,LE.[Name],le.LegalEntityId,sobi.BillToSiteId,aas.UserType
			
			UNION
			
			select le.LegalEntityId,wop.ManagementStructureId,WO.CustomerId,LE.[Name],wobi.SoldToSiteId AS 'BillToSiteId',1 AS 'UserType' from dbo.[WorkOrder] WO
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId
			   INNER JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.WorkOrderPartId = wop.ID and wobi.IsVersionIncrease=0
			   INNER JOIN WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.EntityMSID = wop.ManagementStructureId AND soms.ModuleID=@WOMSModuleID
			   INNER JOIN ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			   INNER JOIN LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			   where wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			   group by wop.ManagementStructureId,WO.CustomerId,LE.[Name],le.LegalEntityId,wobi.SoldToSiteId
	)
	--Select LegalEntityId AS ManagementStructureId,[Name] AS LegalEntityName,BillToSiteId,UserType from CTE
	--where CTE.CustomerId = @CustomerId
	--group by LegalEntityId,[Name],BillToSiteId,UserType
	Select LegalEntityId,ManagementStructureId,[Name] AS LegalEntityName,BillToSiteId,UserType from CTE
	where CTE.CustomerId = @CustomerId
	group by LegalEntityId,ManagementStructureId,[Name],BillToSiteId,UserType

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