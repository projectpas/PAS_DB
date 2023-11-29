/*************************************************************           
 ** File:   [sp_GetCustomerInvoicedatabyInvoiceId]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer Invoicedataby InvoiceId   
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/18/2022   Subhash Saliya Created
	
 -- exec sp_GetCustomerInvoicedatabyInvoiceId 92,1    
**************************************************************/ 

CREATE Procedure [dbo].[sp_GetCustomerInvoicedatabyInvoiceId]
@InvoicingId bigint,
@isWorkOrder bit
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			
			if(@isWorkOrder =0)
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
			FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId
				LEFT JOIN Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
				LEFT JOIN CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN CustomerContact CUN WITH (NOLOCK) ON CUN.CustomerContactId=SO.CustomerContactId
				LEFT JOIN Contact CON WITH (NOLOCK) ON CON.ContactId=CUN.ContactId
				LEFT JOIN RMACreditMemoSettings RMAC WITH (NOLOCK) ON so.MasterCompanyId = RMAC.MasterCompanyId
			    Where SOBI.SOBillingInvoicingId=@InvoicingId		


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
				LEFT JOIN Customer C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId
				LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				LEFT JOIN CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN CustomerContact CUN WITH (NOLOCK) ON CUN.CustomerContactId=WO.CustomerContactId
				LEFT JOIN Contact CON WITH (NOLOCK) ON CON.ContactId=CUN.ContactId
				LEFT JOIN RMACreditMemoSettings RMAC WITH (NOLOCK) ON wo.MasterCompanyId = RMAC.MasterCompanyId
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