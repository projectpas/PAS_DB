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
    2    03/07/2025   Rajesh Gami	  Modified the table name as per new billing structure 	
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
				DECLARE @SOModuleId INT = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder')
				IF(@Opr = 1) -- Get Parent Data
				BEGIN
					SELECT 
						bi.[BillingInvoicingId] [SOBillingInvoicingId],
						bi.ReferenceId [SalesOrderId],
						bi.[InvoiceTypeId],
						bi.[InvoiceNo],
						bi.[CustomerId],
						bi.[InvoiceDate],
						bi.[PrintDate],
						bi.[EmployeeId],
						bi.[RevType],
						bi.[CurrencyId],
						bid.[SoldToCustomerId] [SoldToCustomerId],
						bid.[SoldToSiteId] [SoldToSiteId],
						bid.[ShipToCustomerId] [ShipToCustomerId],
						bid.[ShipToSiteId] [ShipToSiteId],
						bid.[ShipToAttention] [ShipToAttention],
						bid.SoldToCustomerId [BillToCustomerId],
						bid.[SoldToSiteId] [BillToSiteId],
						bid.SoldToAttention [BillToAttention],
						bi.[MasterCompanyId],
						bi.[InvoiceStatus],
						bi.[InvoiceFilePath],
						bi.[CreatedBy],
						bi.[CreatedDate],
						bi.[UpdatedBy],
						bi.[UpdatedDate]
					FROM DBO.BillingInvoicing bi WITH (NOLOCK)
					INNER JOIN dbo.BillingInvoicingDetails bid WITH(NOLOCK) on bid.BillingInvoicingId = bi.BillingInvoicingId
					LEFT JOIN DBO.BillingInvoicingItems bii WITH (NOLOCK) ON bii.[BillingInvoicingId] = bi.[BillingInvoicingId]
					WHERE bi.[BillingInvoicingId] IN(SELECT Item FROM dbo.SplitString(@sobillingInvoicingId, ',')) AND bi.ModuleId = @SOModuleId
				END
				ELSE -- Get Child Data
				BEGIN
					SELECT 
						bii.[BillingInvoicingItemId] [SOBillingInvoicingItemId],
						bii.[BillingInvoicingId] [SOBillingInvoicingId],
						bii.QtyBilled [NoofPieces],
						bii.SubReferenceId [SalesOrderPartId],
						bii.[ItemMasterId],
						bii.[MasterCompanyId],
						bii.[CreatedBy],
						bii.[UpdatedBy],
						bii.[CreatedDate],
						bii.[UpdatedDate],
						bii.[IsActive],
						bii.[IsDeleted],
						bii.[UnitPrice],
						bii.[ShippingId] [SalesOrderShippingId],
						bii.[PDFPath],
						bii.[StockLineId],
						bii.[VersionNo],
						bii.[IsVersionIncrease]
					FROM DBO.BillingInvoicing bi WITH (NOLOCK)
					LEFT JOIN DBO.BillingInvoicingItems bii WITH (NOLOCK) ON bii.[BillingInvoicingId] = bi.[BillingInvoicingId]
					WHERE bi.[BillingInvoicingId] IN(SELECT Item FROM dbo.SplitString(@sobillingInvoicingId, ','))  AND bi.ModuleId = @SOModuleId
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