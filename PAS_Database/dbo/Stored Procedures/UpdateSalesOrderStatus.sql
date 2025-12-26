/*************************************************************           
 ** File:   [UpdateSalesOrderStatus]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used to update Sales Order status Shipped/Invoiced
 ** Purpose:         
 ** Date:   19-11-2024
 ** PARAMETERS: @SalesOrderId BIGINT
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    19-11-2024   AMIT GHEDIYA		Created 
	2    05-12-2024   AMIT GHEDIYA		Updated logic for multiple stockline
	3    23-01-2025   Abhishek Jirawla	Updated logic to select Qty resquested instead of SalesOrderId	
	4    07-07-2025   Moin Bloch        Changed Old To New Billing Table
	5    21-07-2025   Rajesh Gami       Fixed: Get proper invoice count and based on that change the status
	6    23-07-2025   Rajesh Gami       Remove Transaction
	7    23-12-2024   AMIT GHEDIYA		Updated logic for one by one shipping so.
-- EXEC [UpdateSalesOrderStatus] 1316,11,1
************************************************************************/
CREATE      PROCEDURE [dbo].[UpdateSalesOrderStatus]
	@SalesOrderId BIGINT,
	@SalesOrderStatus BIGINT,
	@IsFromShipping BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
			DECLARE @SoPartDataCount BIGINT,
				@SoShippingCount BIGINT,
				@SalesOrderShippingId BIGINT,
				@SoShippingItemCount BIGINT,
				@SOBillingInvoicingId BIGINT,
				@SoBillingItemCount BIGINT, @InvoicedStatusId INT = (SELECT TOP 1 InvoiceStatusId FROM InvoiceStatus WHERE [Status] = 'Invoiced');

			DECLARE @SOModuleId INT
			SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

			SELECT @SoPartDataCount = ISNULL(SUM(QtyRequested), 0) FROM [DBO].[SalesOrderPartV1] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId AND ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0;

			IF(ISNULL(@IsFromShipping,0) > 0)
			BEGIN
				IF(ISNULL(@SoPartDataCount,0) > 0)
				BEGIN				
					SELECT @SalesOrderShippingId = [SalesOrderShippingId] FROM [DBO].[SalesOrderShipping] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId AND ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0;
					
					--Check for multiple shipping
					SELECT @SoShippingItemCount = ISNULL(SUM(QtyShipped), 0) FROM [DBO].[SalesOrderShippingItem] WITH(NOLOCK) WHERE [SalesOrderShippingId] IN (SELECT [SalesOrderShippingId] FROM [DBO].[SalesOrderShipping] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId AND ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0);
					IF(ISNULL(@SoShippingItemCount,0) >= ISNULL(@SoPartDataCount,0))
					BEGIN 
						 UPDATE [DBO].[SalesOrder]
						 SET StatusId = @SalesOrderStatus,UpdatedDate = GETUTCDATE(), StatusChangeDate = GETUTCDATE()
						 WHERE SalesOrderId = @SalesOrderId;
					END
					ELSE
					BEGIN 
						SELECT @SoShippingCount = COUNT([SalesOrderShippingId]) FROM [DBO].[SalesOrderShipping] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId AND ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0;
						
						IF(ISNULL(@SoShippingCount,0) > 0)
						BEGIN 
							--Check is all shipped or not
							IF(ISNULL(@SoPartDataCount,0) = ISNULL(@SoShippingCount,0))
							BEGIN 
								UPDATE [DBO].[SalesOrder]
								SET StatusId = @SalesOrderStatus,UpdatedDate = GETUTCDATE(), StatusChangeDate = GETUTCDATE()
								WHERE SalesOrderId = @SalesOrderId;
							END
						END
					END
				END
			END
			ELSE
			BEGIN
				IF(ISNULL(@SoPartDataCount,0) > 0)
				BEGIN
					 --Check for multiple billing
					SELECT @SoBillingItemCount =ISNULL(SUM(BII.QtyBilled), 0) FROM [DBO].[BillingInvoicingItems] BII WITH(NOLOCK) WHERE ISNULL(BII.IsVersionIncrease,0) = 0 AND ISNULL(BII.IsPerformaInvoice,0) = 0 AND [BillingInvoicingId] IN ( SELECT [BillingInvoicingId] FROM [DBO].[BillingInvoicing] BI WITH(NOLOCK) WHERE Bi.InvoiceStatusId = @InvoicedStatusId AND BI.[ReferenceId] = @SalesOrderId  AND BI.[ModuleId] = @SOModuleId AND ISNULL(BI.[IsActive],0) = 1 AND ISNULL(BI.[IsDeleted],0) = 0 AND ISNULL(BI.IsVersionIncrease,0) = 0 AND ISNULL(BI.IsPerformaInvoice,0) = 0);
					IF(@SoBillingItemCount > 0 AND ISNULL(@SoBillingItemCount,0) >= ISNULL(@SoPartDataCount,0))
					BEGIN
						 UPDATE [DBO].[SalesOrder]
						 SET StatusId = @SalesOrderStatus, UpdatedDate = GETUTCDATE(), StatusChangeDate = GETUTCDATE()
						 WHERE SalesOrderId = @SalesOrderId;
					END
				END
			END

			SELECT [SalesOrderId] AS [value] FROM [DBO].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId
	
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateSalesOrderStatus' 
              , @ProcedureParameters VARCHAR(3000)  = '@SalesOrderId = '''+ CAST(ISNULL(@SalesOrderId, '') AS varchar(100))													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END