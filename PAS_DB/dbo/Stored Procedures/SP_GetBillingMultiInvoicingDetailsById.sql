/*************************************************************           
 ** File:   [SP_GetBillingMultiInvoicingDetailsById]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used get multiple billing invoice.
 ** Purpose:         
 ** Date:   02/11/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    1    02/11/2023   Amit Ghediya	  Created	

	-- EXEC [dbo].[SP_GetBillingMultiInvoicingDetailsById] '23,24',2
     
**************************************************************/

CREATE     Procedure [dbo].[SP_GetBillingMultiInvoicingDetailsById]
	@sobillingInvoicingId  VARCHAR(MAX),
	@Opr  INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF(@Opr = 1) -- Get Parent Data
				BEGIN
					SELECT 
						bi.[SOBillingInvoicingId],
						bi.[SalesOrderId],
						bi.[InvoiceTypeId],
						bi.[InvoiceNo],
						bi.[CustomerId],
						bi.[InvoiceDate],
						bi.[PrintDate],
						bi.[ShipDate],
						bi.[EmployeeId],
						bi.[RevType],
						bi.[CurrencyId],
						bi.[SoldToCustomerId],
						bi.[SoldToSiteId],
						bi.[ShipToCustomerId],
						bi.[ShipToSiteId],
						bi.[ShipToAttention],
						bi.[BillToCustomerId],
						bi.[BillToSiteId],
						bi.[BillToAttention],
						bi.[AvailableCredit],
						bi.[MasterCompanyId],
						bi.[InvoiceStatus],
						bi.[InvoiceFilePath],
						bi.[CreatedBy],
						bi.[CreatedDate],
						bi.[UpdatedBy],
						bi.[UpdatedDate]
					FROM DBO.SalesOrderBillingInvoicing bi WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem bii WITH (NOLOCK) ON bii.[SOBillingInvoicingId] = bi.[SOBillingInvoicingId]
					WHERE bi.[SOBillingInvoicingId] IN(SELECT Item FROM dbo.SplitString(@sobillingInvoicingId, ','))
				END
				ELSE -- Get Child Data
				BEGIN
					SELECT 
						bii.[SOBillingInvoicingItemId],
						bii.[SOBillingInvoicingId],
						bii.[NoofPieces],
						bii.[SalesOrderPartId],
						bii.[ItemMasterId],
						bii.[MasterCompanyId],
						bii.[CreatedBy],
						bii.[UpdatedBy],
						bii.[CreatedDate],
						bii.[UpdatedDate],
						bii.[IsActive],
						bii.[IsDeleted],
						bii.[UnitPrice],
						bii.[SalesOrderShippingId],
						bii.[PDFPath],
						bii.[StockLineId],
						bii.[VersionNo],
						bii.[IsVersionIncrease]
					FROM DBO.SalesOrderBillingInvoicing bi WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem bii WITH (NOLOCK) ON bii.[SOBillingInvoicingId] = bi.[SOBillingInvoicingId]
					WHERE bi.[SOBillingInvoicingId] IN(SELECT Item FROM dbo.SplitString(@sobillingInvoicingId, ','))
				END
				
			END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SP_GetBillingMultiInvoicingDetailsById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@sobillingInvoicingId, '') + ''
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