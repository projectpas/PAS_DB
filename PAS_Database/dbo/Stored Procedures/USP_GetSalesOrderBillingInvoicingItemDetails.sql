/*************************************************************               
** File:   [USP_GetSalesOrderBillingInvoicingItemDetails]              
** Author:   Hemant Saliya  
** Description: This procedre is used to Get SalesOrder Billing Invoicing Item Details  
** Purpose:             
** Date:   18/03/2024  
**************************************************************               
** Change History               
**************************************************************               
** PR   Date         Author				Change Description                
** --   --------     -------			--------------------------------              
 1   18/03/2024		Hemant Saliya		Created 
 2   17/10/2024		Vishal Suthar		Modified to make use of new SO part tables
 
EXEC USP_GetSalesOrderBillingInvoicingItemDetails 1

**************************************************************/   
CREATE   PROCEDURE [dbo].[USP_GetSalesOrderBillingInvoicingItemDetails](    
 @SalesOrderPartId BIGINT = NULL 
)  
AS    
BEGIN  
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	 SET NOCOUNT ON;    
		 BEGIN TRY  
			 BEGIN

				IF OBJECT_ID(N'tempdb..#SalesOrderBillingInvoicingItem') IS NOT NULL
				BEGIN
					DROP TABLE #SalesOrderBillingInvoicingItem
				END

				CREATE TABLE #SalesOrderBillingInvoiceChildList(
					SalesOrderPartId [BIGINT] NOT NULL,
					ItemMasterId [BIGINT] NULL,
					ConditionId [BIGINT] NULL,
					StocklineId [BIGINT] NULL,
					UnitPrice [DECIMAL](18,2) NULL
				);

				INSERT INTO #SalesOrderBillingInvoiceChildList(SalesOrderPartId, ItemMasterId, ConditionId, StocklineId, UnitPrice)
				SELECT SOP.SalesOrderPartId, SOP.ItemMasterId, SOP.ConditionId, Stk.StockLineId, SOPC.UnitSalesPrice AS UnitPrice					   
				FROM dbo.SalesOrder SO WITH(NOLOCK) 
					JOIN dbo.SalesOrderPartV1 SOP WITH(NOLOCK) ON  SO.SalesOrderId = SOP.SalesOrderId
					LEFT JOIN dbo.SalesOrderStocklineV1 Stk WITH(NOLOCK) ON Stk.SalesOrderPartId = SOP.SalesOrderPartId
					LEFT JOIN dbo.SalesOrderPartCost SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
					LEFT JOIN dbo.SalesOrderFreight SOF WITH(NOLOCK) ON  SOF.SalesOrderPartId = SOP.SalesOrderPartId
					LEFT JOIN dbo.SalesOrderCharges SOC WITH(NOLOCK) ON  SOC.SalesOrderPartId = SOP.SalesOrderPartId
				WHERE SOP.SalesOrderPartId = @SalesOrderPartId

				SELECT * FROM #SalesOrderBillingInvoiceChildList

			END
			 
		 END TRY  
	  BEGIN CATCH  
		  DECLARE @ErrorLogID INT    
		  ,@DatabaseName VARCHAR(100) = db_name()        
		  -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
		  ,@AdhocComments VARCHAR(150) = 'USP_GetReportingStructureList'        
		  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderPartId, '') AS varchar(MAX))        
		  ,@ApplicationName VARCHAR(100) = 'PAS'        
		  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
		  EXEC spLogException @DatabaseName = @DatabaseName        
		  ,@AdhocComments = @AdhocComments        
		  ,@ProcedureParameters = @ProcedureParameters        
		  ,@ApplicationName = @ApplicationName        
		  ,@ErrorLogID = @ErrorLogID OUTPUT;        
        
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)        
        
	  RETURN (1);     
	 END CATCH  
END