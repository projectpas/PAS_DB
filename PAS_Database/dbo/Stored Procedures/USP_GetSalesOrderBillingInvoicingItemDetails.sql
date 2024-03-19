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
 
EXEC USP_GetSalesOrderBillingInvoicingItemDetails 10

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
					UnitPrice [DECIMAL](18,2) NULL,
				);

				SELECT SOP.UnitSalesPricePerUnit AS UnitPrice,
					   SOP.ItemMasterId
				FROM dbo.SalesOrder SO WITH(NOLOCK) 
					JOIN dbo.SalesOrderPart SOP WITH(NOLOCK) ON  SO.SalesOrderId = SOP.SalesOrderId
					LEFT JOIN dbo.SalesOrderFreight SOF WITH(NOLOCK) ON  SOP.SalesOrderPartId = SOP.SalesOrderPartId
					LEFT JOIN dbo.SalesOrderCharges SOC WITH(NOLOCK) ON  SOP.SalesOrderPartId = SOP.SalesOrderPartId
				WHERE SOP.SalesOrderPartId = @SalesOrderPartId



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