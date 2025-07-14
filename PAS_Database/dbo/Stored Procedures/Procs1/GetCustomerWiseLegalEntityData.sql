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
	6	05/4/2024		Devendra Shekh	duplicate LegalEntity issue resolved
	7	30/06/2025		Devendra Shekh	Modified (Billing Table Changes for WO)
	8	30/06/2025		Rajesh Gami		Modified (Billing Invoicing Table Changes for SO as per new structure)
	9	10/07/2025		Devendra Shekh	Modified (added CreditMemo Union)
************************************************************************/
-- EXEC [dbo].[GetCustomerWiseLegalEntityData] 3398,'2024-03-26','2024-04-05'
-- EXEC [dbo].[GetCustomerWiseLegalEntityData] 3401,'2024-03-26','2024-04-05'
CREATE   PROCEDURE [dbo].[GetCustomerWiseLegalEntityData]
@CustomerId bigint = null,
@StartDate datetime=null,
@EndDate datetime=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	DECLARE @SOMSModuleID INT = 17,@WOMSModuleID INT = 12,@SOAddessModuleID INT=10,@CMMSModuleID INT = 61;
	DECLARE @WOModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder');
	DECLARE @SubModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN');
	DECLARE @SOModuleId BIGINT = (SELECT [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder');

	;WITH CTE AS(
		SELECT le.LegalEntityId,so.ManagementStructureId,so.CustomerId,LE.[Name],invd.SoldToSiteId AS 'BillToSiteId',aas.UserType AS 'UserType'
			FROM dbo.SalesOrder so
			INNER JOIN dbo.BillingInvoicing sobi WITH(NOLOCK) ON so.SalesOrderId = sobi.ReferenceId  and ISNULL(sobi.IsVersionIncrease,0)=0 
			INNER JOIN dbo.BillingInvoicingDetails invd WITH (NOLOCK) ON sobi.BillingInvoicingId = invd.BillingInvoicingId
			INNER JOIN dbo.SalesOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.EntityMSID = so.ManagementStructureId AND soms.ModuleID=@SOMSModuleID
			INNER JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			INNER JOIN dbo.LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			INNER JOIN dbo.AllAddress aas WITH(NOLOCK) ON aas.ReffranceId = so.SalesOrderId AND aas.ModuleId = @SOAddessModuleID AND aas.IsShippingAdd=0
			WHERE sobi.InvoiceStatus = 'Invoiced' AND CAST(sobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date) AND sobi.ModuleId = @SOModuleId
			GROUP BY so.ManagementStructureId,so.CustomerId,LE.[Name],le.LegalEntityId,invd.SoldToSiteId,aas.UserType
			
			UNION
			
			SELECT le.LegalEntityId,wop.ManagementStructureId,WO.CustomerId,LE.[Name],invd.SoldToSiteId AS 'BillToSiteId',1 AS 'UserType' FROM dbo.[WorkOrder] WO
			   INNER JOIN dbo.[WorkOrderPartNumber] wop WITH (NOLOCK) ON WO.WorkOrderId = wop.WorkOrderId
			   INNER JOIN dbo.BillingInvoicingItems wobii WITH(NOLOCK) on wop.ID = wobii.SubReferenceId AND wobii.SubModuleId = @SubModuleId AND wobii.ModuleId = @WOModuleId
			   INNER JOIN dbo.BillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobii.SubReferenceId = wop.ID and wobi.IsVersionIncrease=0 AND wobi.ModuleId = @WOModuleId
			   INNER JOIN dbo.BillingInvoicingDetails invd WITH (NOLOCK) ON wobi.BillingInvoicingId = invd.BillingInvoicingId
			   INNER JOIN dbo.WorkOrderManagementStructureDetails soms WITH(NOLOCK) ON soms.EntityMSID = wop.ManagementStructureId AND soms.ModuleID=@WOMSModuleID
			   INNER JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = soms.Level1Id
			   INNER JOIN dbo.LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			   WHERE wobi.InvoiceStatus = 'Invoiced' and wobi.IsVersionIncrease=0 AND CAST(wobi.PostedDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			   GROUP BY wop.ManagementStructureId,WO.CustomerId,LE.[Name],le.LegalEntityId,invd.SoldToSiteId

			   UNION

			   SELECT le.LegalEntityId,CM.ManagementStructureId,CM.CustomerId,LE.[Name],cba.CustomerBillingAddressId AS 'BillToSiteId',1 AS 'UserType' 
			   FROM dbo.CreditMemo CM
			   INNER JOIN dbo.CustomerBillingAddress cba WITH(NOLOCK) ON cba.CustomerId = CM.CustomerId AND cba.IsPrimary = 1
			   INNER JOIN dbo.RMACreditMemoManagementStructureDetails cmms WITH(NOLOCK) ON cmms.ReferenceID = CM.CreditMemoHeaderId AND cmms.EntityMSID = CM.ManagementStructureId AND cmms.ModuleID = @CMMSModuleID
			   INNER JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) ON msl.ID = cmms.Level1Id
			   INNER JOIN dbo.LegalEntity le WITH(NOLOCK) ON le.LegalEntityId = msl.LegalEntityId
			   WHERE CM.[Status] = 'Posted' AND CAST(CM.InvoiceDate AS date) BETWEEN CAST(@StartDate as date) and CAST(@EndDate as date)
			   GROUP BY CM.ManagementStructureId,CM.CustomerId,LE.[Name],le.LegalEntityId,cba.CustomerBillingAddressId
	)
	--Select LegalEntityId AS ManagementStructureId,[Name] AS LegalEntityName,BillToSiteId,UserType from CTE
	--where CTE.CustomerId = @CustomerId
	--group by LegalEntityId,[Name],BillToSiteId,UserType
	Select LegalEntityId,MAX(ManagementStructureId) AS ManagementStructureId,[Name] AS LegalEntityName,BillToSiteId,UserType from CTE
	where CTE.CustomerId = @CustomerId
	group by LegalEntityId,[Name],BillToSiteId,UserType

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