/*************************************************************           
 ** File:   [USP_GetOldWorkOrderForBillingInvoicedData]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used GetOldWorkOrderForBillingInvoicedData
 ** Purpose:         
 ** Date:   13/12/2023  
          
 ** PARAMETERS: @WorkOrderId BIGINT
     
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    13/12/2023   AMIT GHEDIYA     Created
	2	 01/31/2024   Devendra Shekh	added isperforma Flage for WO
     
-- EXEC USP_GetOldWorkOrderForBillingInvoicedData 3788

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetOldWorkOrderForBillingInvoicedData]
	@WorkOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	
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
	Where WO.WorkOrderId = @WorkOrderId  AND WOBI.IsVersionIncrease=0
	AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0;

	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetOldWorkOrderForBillingInvoicedData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100))  													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
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