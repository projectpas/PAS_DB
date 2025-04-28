/*************************************************************               
 ** File:   [USP_Refresh_Customer_Vendor_ByModule]               
 ** Author: RAJESH GAMI 
 ** Description:  This Store Procedure use to  Refresh customer / vendor by module wise
 ** Purpose:             
 ** Date:   15 April 2025      
              
 ** RETURN VALUE:               
 **********************************************************               
 ** Refresh CreditLimit and Terms               
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    15 April 2025	RAJESH GAMI		CREATED 
    2    18 April 2025	Bhargav Saliya	Changes For RO, RFQ RO,RFQ Po,Non PO,VendorProformaInvoice,Exchange,SO,SOQ,Exchange Quote,Exchange,Speed Quote,CustomerRMA,Receiving Cust
 
 EXEC [USP_WO_Refresh_Customer] 4291,8646
 EXEC [USP_Refresh_Customer_Vendor_ByModule] 4291,0,8646,15,''  EXEC [USP_Refresh_Customer_Vendor_ByModule] 1122,0,6639,23,''
********************************************************************/ 

CREATE PROCEDURE [dbo].[USP_Refresh_Customer_Vendor_ByModule]
	@customerId BIGINT = 0,
	@vendorId BIGINT = 0,
	@referenceId BIGINT =0,
	@moduleId INT = 0,
	@module VARCHAR(50) =''
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION
			IF(@moduleId > 0)
			BEGIN
				DECLARE @RFQPOModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='VendorRFQPurchaseOrder')	
				DECLARE @RFQROModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='VendorRFQRepairOrder')
				DECLARE @POModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='PurchaseOrder')
				DECLARE @ROModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='RepairOrder')
				DECLARE @VendorRMAModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='VendorRMA')
				DECLARE @SOQModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='SalesQuote')
				DECLARE @SalesModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='SalesOrder')
				DECLARE @ExchangeQuoteModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='ExchangeQuote')
				DECLARE @ExchangeModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='ExchangeSalesOrder')
				DECLARE @SpeedQuoteModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='SpeedQuote')
				DECLARE @ReceivingCustomerModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='ReceivingCustomerWork')
				DECLARE @WOModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='WorkOrder')
				DECLARE @WOQModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='WOQuote')
				DECLARE @CustomerRMAModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='CustomerRMA')
				DECLARE @CreditMemoModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='CreditMemo')
				DECLARE @ReceivingReconciliationModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='ReceivingReconciliation')
				DECLARE @NonPOModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='NonPOInvoice')
				DECLARE @VendorPaymentModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='VendorPayment')
				DECLARE @VendorProformaInvoiceModuleId INT = (SELECT TOP 1 ModuleId FROM DBO.Module WITH(NOLOCK) WHERE ModuleName ='VendorProformaInvoice')
				IF(@customerId > 0)
				BEGIN
					DECLARE @CustomerName VARCHAR(100) = (SELECT TOP 1 C.[Name]	FROM [dbo].[Customer] C WITH(NOLOCK)   WHERE CustomerId = @customerId)

					IF(@moduleId = @WOModuleId) /***********>>>>>>> Work Order Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[Workorder] SET [CustomerName] = @CustomerName	  WHERE WorkorderId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[Workorder] W WITH (NOLOCK) WHERE WorkorderId = @referenceId 
					END

					ELSE IF(@moduleId = @SalesModuleId) /***********>>>>>>> Sales Order Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[SalesOrder] SET [CustomerName] = @CustomerName WHERE SalesOrderId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[SalesOrder] S WITH (NOLOCK) WHERE SalesOrderId = @referenceId 
					END

					ELSE IF(@moduleId = @SOQModuleId) /***********>>>>>>> Sales Order Quote Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[SalesOrderQuote] SET [CustomerName] = @CustomerName WHERE SalesOrderQuoteId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[SalesOrderQuote] Sq WITH (NOLOCK) WHERE SalesOrderQuoteId = @referenceId 
					END

					ELSE IF(@moduleId = @ExchangeQuoteModuleId) /***********>>>>>>> Exchange Quote Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[ExchangeQuote] SET [CustomerName] = @CustomerName WHERE ExchangeQuoteId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[ExchangeQuote] Sq WITH (NOLOCK) WHERE ExchangeQuoteId = @referenceId 
					END

					ELSE IF(@moduleId = @SpeedQuoteModuleId) /***********>>>>>>> Speed Quote Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[SpeedQuote] SET [CustomerName] = @CustomerName WHERE SpeedQuoteId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[SpeedQuote] Sq WITH (NOLOCK) WHERE SpeedQuoteId = @referenceId 
					END

					ELSE IF(@moduleId = @WOQModuleId) /***********>>>>>>> WO Quote Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[WorkOrderQuote] SET [CustomerName] = @CustomerName WHERE WorkOrderQuoteId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[WorkOrderQuote] RC WITH (NOLOCK) WHERE WorkOrderQuoteId = @referenceId 
					END

					ELSE IF(@moduleId = @CustomerRMAModuleId) /***********>>>>>>> CustomerRMA Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[CustomerRMAHeader] SET [CustomerName] = @CustomerName WHERE RMAHeaderId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[CustomerRMAHeader] RC WITH (NOLOCK) WHERE RMAHeaderId = @referenceId 
					END

					ELSE IF(@moduleId = @CreditMemoModuleId) /***********>>>>>>> Credit Memo Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[CreditMemo] SET [CustomerName] = @CustomerName WHERE CreditMemoHeaderId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[CreditMemo] C WITH (NOLOCK) WHERE CreditMemoHeaderId = @referenceId 
					END

					ELSE IF(@moduleId = @ExchangeModuleId) /***********>>>>>>> Exchange Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[ExchangeSalesOrder] SET [CustomerName] = @CustomerName WHERE ExchangeSalesOrderId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[ExchangeSalesOrder] C WITH (NOLOCK) WHERE ExchangeSalesOrderId = @referenceId 
					END

					ELSE IF(@moduleId = @ReceivingCustomerModuleId) /***********>>>>>>> Receiving Cust Customer Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[ReceivingCustomerWork] SET [CustomerName] = @CustomerName WHERE ReceivingCustomerWorkId = @referenceId AND CustomerId = @customerId			
						SELECT [CustomerName] [Name] FROM [dbo].[ReceivingCustomerWork] C WITH (NOLOCK) WHERE ReceivingCustomerWorkId = @referenceId 
					END
				END
				ELSE IF(@vendorId > 0)
				BEGIN
					DECLARE @VendorName VARCHAR(100) = (SELECT TOP 1 C.VendorName FROM [dbo].[Vendor] C WITH(NOLOCK)  WHERE VendorId = @vendorId)

					IF(@moduleId = @POModuleId)  /***********>>>>>>> Purchase Order Vendor name REFRESH  <<<<<<<************/
					BEGIN
						UPDATE [dbo].[PurchaseOrder] SET [VendorName] = @VendorName	 WHERE PurchaseOrderId = @referenceId AND VendorId = @vendorId
						SELECT VendorName [Name] FROM [dbo].[PurchaseOrder] W WITH (NOLOCK) WHERE PurchaseOrderId = @referenceId  
					END

					ELSE IF(@moduleId = @ROModuleId)  /***********>>>>>>> Repair Order Vendor name REFRESH  <<<<<<<************/
					BEGIN
						UPDATE [dbo].[RepairOrder] SET [VendorName] = @VendorName	 WHERE RepairOrderId = @referenceId AND VendorId = @vendorId
						SELECT VendorName [Name] FROM [dbo].[RepairOrder] W WITH (NOLOCK) WHERE RepairOrderId = @referenceId  
					END

					ELSE IF(@moduleId = @RFQPOModuleId)  /***********>>>>>>> Vendor RFQ PO Vendor name REFRESH  <<<<<<<************/
					BEGIN
						UPDATE [dbo].[VendorRFQPurchaseOrder] SET [VendorName] = @VendorName	 WHERE VendorRFQPurchaseOrderId = @referenceId AND VendorId = @vendorId
						SELECT VendorName [Name] FROM [dbo].[VendorRFQPurchaseOrder] W WITH (NOLOCK) WHERE VendorRFQPurchaseOrderId = @referenceId  
					END

					ELSE IF(@moduleId = @RFQROModuleId)  /***********>>>>>>> Vendor RFQ RO Vendor name REFRESH  <<<<<<<************/
					BEGIN
						UPDATE [dbo].[VendorRFQRepairOrder] SET [VendorName] = @VendorName	 WHERE VendorRFQRepairOrderId = @referenceId AND VendorId = @vendorId
						SELECT VendorName [Name] FROM [dbo].[VendorRFQRepairOrder] W WITH (NOLOCK) WHERE VendorRFQRepairOrderId = @referenceId  
					END

					ELSE IF(@moduleId = @ReceivingReconciliationModuleId)  /***********>>>>>>> Receiving ReConciliation Vendor name REFRESH  <<<<<<<************/
					BEGIN
						UPDATE [dbo].[ReceivingReconciliationHeader] SET [VendorName] = @VendorName	 WHERE ReceivingReconciliationId = @referenceId AND VendorId = @vendorId
						SELECT VendorName [Name] FROM [dbo].[ReceivingReconciliationHeader] W WITH (NOLOCK) WHERE ReceivingReconciliationId = @referenceId  
					END

					ELSE IF(@moduleId = @NonPOModuleId)  /***********>>>>>>> Non PO Vendor name REFRESH  <<<<<<<************/
					BEGIN
						UPDATE [dbo].[NonPOInvoiceHeader] SET [VendorName] = @VendorName	 WHERE NonPOInvoiceId = @referenceId AND VendorId = @vendorId
						SELECT VendorName [Name] FROM [dbo].[NonPOInvoiceHeader] W WITH (NOLOCK) WHERE NonPOInvoiceId = @referenceId  
					END

					ELSE IF(@moduleId = @VendorProformaInvoiceModuleId)  /***********>>>>>>> Vendor Proforma Invoice Vendor name REFRESH  <<<<<<<************/
					BEGIN
						UPDATE [dbo].[VendorProformaInvoiceHeader] SET [VendorName] = @VendorName	 WHERE VendorProformaInvoiceId = @referenceId AND VendorId = @vendorId
						SELECT VendorName [Name] FROM [dbo].[VendorProformaInvoiceHeader] VI WITH (NOLOCK) WHERE VendorProformaInvoiceId = @referenceId  
					END

					ELSE IF(@moduleId = @ExchangeModuleId) /***********>>>>>>> Exchange Vendor Name REFRESH <<<<<<<************/
					BEGIN
						UPDATE [dbo].[ExchangeSalesOrder] SET [CustomerName] = @VendorName	 WHERE ExchangeSalesOrderId = @referenceId AND CustomerId = @vendorId
						SELECT [CustomerName] [Name] FROM [dbo].[ExchangeSalesOrder] ES WITH (NOLOCK) WHERE ExchangeSalesOrderId = @referenceId  
					END
				END
			END	

		COMMIT  TRANSACTION

	END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Refresh_Customer_Vendor_ByModule' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@customerId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END