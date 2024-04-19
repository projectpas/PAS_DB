/*************************************************************           
 ** File:   [sp_GetCustomerInvoicedatabyInvoiceId]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer Invoicedataby InvoiceId   
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    04/18/2022   Subhash Saliya	Created
	2	 02/1/2024	  AMIT GHEDIYA		added isperforma Flage for SO
	3	 04/19/2024	  Devendra Shekh	added data for Exchange SO
	
 -- exec sp_GetCustomerInvoicedatabyInvoiceId 92,1    
**************************************************************/ 

CREATE Procedure [dbo].[sp_GetCustomerInvoicedatabyInvoiceId]
@InvoicingId BIGINT,
@isWorkOrder BIT,
@isExchange BIT
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			
			IF(@isWorkOrder =0 AND @isExchange = 0)
			BEGIN

				SELECT SOBI.SOBillingInvoicingId as InvoiceId,SOBI.InvoiceNo [InvoiceNo],
				SOBI.InvoiceStatus [InvoiceStatus],SOBI.InvoiceDate [InvoiceDate],SO.SalesOrderNumber [OrderNumber],
				C.Name [CustomerName],CT.CustomerTypeName [CustomerType],
				SOBI.GrandTotal [InvoiceAmt],
				IsWorkOrder=0,
				SOBI.SalesOrderId AS [ReferenceId]
				,(CON.FirstName +' '+ CON.LastName +' - '+ CON.WorkPhone) as ContactInfo
			    ,SO.CustomerContactId as  CustomerContactId
			   ,RMAC.RMAReasonId
			   ,RMAC.RMAReason
			   ,RMAC.RMAStatusId
			   ,RMAC.RMAStatus
			   ,RMAC.ValidDays
			   ,SOBI.MasterCompanyId
			   ,C.CustomerId
			   ,c.CustomerCode
			   ,SO.ManagementStructureId as ManagementStructureId
			   ,'0' as AddressCount
			   ,'0' as PartCount
			FROM [dbo].SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN [dbo].SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId
				LEFT JOIN [dbo].Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN [dbo].SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
				LEFT JOIN [dbo].CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN [dbo].CustomerContact CUN WITH (NOLOCK) ON CUN.CustomerContactId=SO.CustomerContactId
				LEFT JOIN [dbo].Contact CON WITH (NOLOCK) ON CON.ContactId=CUN.ContactId
				LEFT JOIN [dbo].RMACreditMemoSettings RMAC WITH (NOLOCK) ON so.MasterCompanyId = RMAC.MasterCompanyId
			    Where SOBI.SOBillingInvoicingId=@InvoicingId AND ISNULL(SOBI.IsProforma,0) = 0	

			END
			ELSE IF(@isExchange = 1)
			BEGIN

				SELECT ESOBI.SOBillingInvoicingId as InvoiceId,ESOBI.InvoiceNo [InvoiceNo],
				ESOBI.InvoiceStatus [InvoiceStatus],ESOBI.InvoiceDate [InvoiceDate],ESO.ExchangeSalesOrderNumber [OrderNumber],
				C.Name [CustomerName],CT.CustomerTypeName [CustomerType],
				ESOBI.GrandTotal [InvoiceAmt],
				IsWorkOrder = 0,
				ESOBI.ExchangeSalesOrderId AS [ReferenceId]
				,(CON.FirstName +' '+ CON.LastName +' - '+ CON.WorkPhone) as ContactInfo
			    ,ESO.CustomerContactId as  CustomerContactId
			   ,RMAC.RMAReasonId
			   ,RMAC.RMAReason
			   ,RMAC.RMAStatusId
			   ,RMAC.RMAStatus
			   ,RMAC.ValidDays
			   ,ESOBI.MasterCompanyId
			   ,C.CustomerId
			   ,c.CustomerCode
			   ,ESO.ManagementStructureId as ManagementStructureId
			   ,'0' as AddressCount
			   ,'0' as PartCount
			FROM [dbo].ExchangeSalesOrderBillingInvoicing ESOBI WITH (NOLOCK)
				LEFT JOIN [dbo].ExchangeSalesOrderPart ESOPN WITH (NOLOCK) ON ESOPN.ExchangeSalesOrderId = ESOBI.ExchangeSalesOrderId
				LEFT JOIN [dbo].Customer C WITH (NOLOCK) ON ESOBI.CustomerId = C.CustomerId
				LEFT JOIN [dbo].ExchangeSalesOrder ESO WITH (NOLOCK) ON ESOBI.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId
				LEFT JOIN [dbo].CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN [dbo].CustomerContact CUN WITH (NOLOCK) ON CUN.CustomerContactId = ESO.CustomerContactId
				LEFT JOIN [dbo].Contact CON WITH (NOLOCK) ON CON.ContactId=CUN.ContactId
				LEFT JOIN [dbo].RMACreditMemoSettings RMAC WITH (NOLOCK) ON ESO.MasterCompanyId = RMAC.MasterCompanyId
			    Where ESOBI.SOBillingInvoicingId=@InvoicingId AND ISNULL(ESO.IsVendor , 0) = 0

			END
			ELSE 
			BEGIN 

		      SELECT WOBI.BillingInvoicingId [InvoiceId],WOBI.InvoiceNo [InvoiceNo],
				WOBI.InvoiceStatus [InvoiceStatus],WOBI.InvoiceDate [InvoiceDate],WO.WorkOrderNum [OrderNumber],
				C.Name [CustomerName],CT.CustomerTypeName [CustomerType],
				WOBI.GrandTotal [InvoiceAmt],
				IsWorkOrder=1,
				WOBI.WorkOrderId AS [ReferenceId]
			   ,WOBI.ManagementStructureId as ManagementStructureId
			   ,(CON.FirstName +' '+ CON.LastName +' - '+ CON.WorkPhone) as ContactInfo
			   ,WO.CustomerContactId as  CustomerContactId
			   ,RMAC.RMAReasonId
			   ,RMAC.RMAReason
			   ,RMAC.RMAStatusId
			   ,RMAC.RMAStatus
			   ,RMAC.ValidDays
			   ,WOBI.MasterCompanyId
			   ,C.CustomerId
			   ,c.CustomerCode
			   ,'0' as AddressCount
			   ,'0' as PartCount
				FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN [dbo].Customer C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId
				LEFT JOIN [dbo].WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				LEFT JOIN [dbo].CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN [dbo].CustomerContact CUN WITH (NOLOCK) ON CUN.CustomerContactId=WO.CustomerContactId
				LEFT JOIN [dbo].Contact CON WITH (NOLOCK) ON CON.ContactId=CUN.ContactId
				LEFT JOIN [dbo].RMACreditMemoSettings RMAC WITH (NOLOCK) ON wo.MasterCompanyId = RMAC.MasterCompanyId
			    Where WOBI.BillingInvoicingId=@InvoicingId AND WOBI.IsVersionIncrease=0
			
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
              , @AdhocComments     VARCHAR(150)    = 'sp_GetCustomerInvoicedatabyInvoiceId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@InvoicingId, '') + '''
													   @Parameter18 = ' + ISNULL(CAST(@isWorkOrder AS varchar(10)) ,'') +''
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