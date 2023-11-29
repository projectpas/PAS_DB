/*************************************************************           
 ** File:   [sp_GetCustomerInvoicedatabyInvoiceId]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer Invoicedataby InvoiceId   
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    1    04/18/2022   Subhash 		  Saliya Created
	2	 23/06/2023   Ayesha Sultana  Alter - Added Receiver Num in Customer RMA History
	
 -- exec sp_GetCustomerInvoicedatabyInvoiceId 92,1    
**************************************************************/ 

CREATE Procedure [dbo].[USP_GetCustomerRmaHeaderAuditData]
@RMAHeaderId bigint,
@ModuleID int
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
			


		    SELECT [RMAHeaderId]
			  ,CRM.[RMANumber]
			  ,CRM.[CustomerId]
			  ,CRM.[CustomerName]
			  ,CRM.[CustomerCode]
			  ,CRM.[CustomerContactId]
			  ,CRM.[ContactInfo]
			  ,CRM.[OpenDate]
			  ,CRM.[InvoiceId]
			  ,CRM.[InvoiceNo]
			  ,CRM.[InvoiceDate]
			  ,CRM.[RMAStatusId]
			  ,CRM.[RMAStatus]
			  ,CRM.[Iswarranty]
			  ,CRM.[ValidDate]
			  ,CRM.[RequestedId]
			  ,CRM.[Requestedby]
			  ,CRM.[ApprovedbyId]
			  ,CRM.[Approvedby]
			  ,CRM.[ApprovedDate]
			  ,CRM.[ReturnDate]
			  ,CRM.[WorkOrderId]
			  ,CRM.[WorkOrderNum]
			  ,CRM.[ReceiverNum]
			  ,CRM.[ManagementStructureId]
			  ,CRM.[Notes]
			  ,CRM.[Memo]
			  ,CRM.[MasterCompanyId]
			  ,CRM.[CreatedBy]
			  ,CRM.[UpdatedBy]
			  ,CRM.[CreatedDate]
			  ,CRM.[UpdatedDate]
			  ,CRM.[IsActive]
			  ,CRM.[IsDeleted]
			  ,CRM.[isWorkOrder]
			  ,CRM.ReferenceId
			  ,MSD.LastMSLevel
			  ,MSD.AllMSlevels
		  FROM [dbo].[CustomerRMAHeaderAudit] CRM  WITH (NOLOCK) 
		  INNER JOIN dbo.RMACreditMemoManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = CRM.RMAHeaderId

		  WHERE  RMAHeaderId =@RMAHeaderId 
         END
			
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCustomerRmaHeaderAuditData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RMAHeaderId, '') + ''
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