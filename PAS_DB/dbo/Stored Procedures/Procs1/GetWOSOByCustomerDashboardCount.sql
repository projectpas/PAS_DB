
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.GetWOSOByCustomerDashboardCount   (source: PAS_DB/dbo/Stored Procedures/Procs1/GetWOSOByCustomerDashboardCount.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [GetWOSOByCustomerDashboardCount]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used get work order and sales order count based on customer  
 ** Purpose:         
 ** Date:   08/17/2023      
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/17/2023   Vishal Suthar Created
	2	 02/1/2024	  AMIT GHEDIYA	added isperforma Flage for SO
	3    10/16/2024	  Abhishek Jirawla	Implemented the new tables for SalesOrderQuotePart related tables
    4    07-07-2025   Moin Bloch        Changed Old To New Billing Table
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
-- EXEC [GetWOSOByCustomerDashboardCount] 1
**************************************************************/
CREATE     PROCEDURE [dbo].[GetWOSOByCustomerDashboardCount]
	@MasterCompanyId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
			BEGIN
			    DECLARE @SOModuleId INT
				SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

				SELECT UPPER(IM.partnumber) AS PN, UPPER(IM.PartDescription) AS PNDescription, 
				UPPER(IM.ItemGroup) AS ItemGroup, UPPER(CON.Memo) AS Condition, UPPER(C.Name) AS Customer, SOB.InvoiceDate,
				UPPER(SO.SalesOrderNumber) SONum, UPPER(SO.SalesPersonName) AS SalesPersonName, (SOPC.UnitSalesPrice * SOP.QtyOrder) AS SalesAmount, SOPC.UnitCostExtended AS Cost, 
				(SOPC.UnitSalesPrice - SOPC.UnitCostExtended) AS MarginAmount, 
				CASE WHEN ISNULL(SOPC.UnitSalesPrice, 0) > 0 THEN (((ISNULL(SOPC.UnitSalesPrice, 0) - ISNULL(SOPC.UnitCostExtended, 0)) / ISNULL(SOPC.UnitSalesPrice, 0)) * 100)
				ELSE 0 END AS MarginPercentage
				FROM DBO.SalesOrder SO WITH (NOLOCK) 
				LEFT JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
				LEFT JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId=SOP.SalesOrderPartId and SOPC.IsDeleted=0
				LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
				 AND ISNULL(IM.IsNonStock,0) = 0
				 LEFT JOIN DBO.Condition CON WITH (NOLOCK) ON SOP.ConditionId = CON.ConditionId
				LEFT JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				LEFT JOIN DBO.BillingInvoicing SOB WITH (NOLOCK) ON SOB.ReferenceId = SOP.SalesOrderId AND ISNULL(SOB.IsPerformaInvoice,0) = 0  AND SOB.[ModuleId] = @SOModuleId
				Where SO.MasterCompanyId = @MasterCompanyId
				AND IM.partnumber <> ''
			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWODashboardDataCount' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END