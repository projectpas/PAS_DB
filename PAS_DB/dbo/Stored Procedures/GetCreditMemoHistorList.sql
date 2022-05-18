

/*************************************************************           
 ** File:   [GetCreditMemoHistorList]           
 ** Author:   MOIN BLOCH
 ** Description: Get Search Historical Data for Credit Memo List    
 ** Purpose:         
 ** Date:   15-MAR-2020        
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/15/2020   Moin Bloch Created

 EXECUTE [GetCreditMemoHistorList] 1
**************************************************************/ 

create PROCEDURE [dbo].[GetCreditMemoHistorList]	
@CreditMemoHeaderId bigint
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;
		BEGIN TRY
		SELECT [CreditMemoHeaderAuditId]
              ,[CreditMemoHeaderId]
              ,[CreditMemoNumber]
              ,[RMAHeaderId]
              ,[RMANumber]
              ,[InvoiceId]
              ,[InvoiceNumber]
              ,[InvoiceDate]
              ,[StatusId]
              ,[Status]
              ,[CustomerId]
              ,[CustomerName]
              ,[CustomerCode]
              ,[CustomerContactId]
              ,[CustomerContact]
              ,[CustomerContactPhone]
              ,[IsWarranty]
              ,[IsAccepted]
              ,[ReasonId]
              ,[Reason]
              ,[DeniedMemo]
              ,[RequestedById]
              ,[RequestedBy]
              ,[ApproverId]
              ,[ApprovedBy]
              ,[WONum]
              ,[WorkOrderId]
              ,[Originalwosonum]
              ,[Memo]
              ,[Notes]
              ,[ManagementStructureId]
              ,[IsEnforce]
              ,[MasterCompanyId]
              ,[CreatedBy]
              ,[UpdatedBy]
              ,[CreatedDate]
              ,[UpdatedDate]
              ,[IsActive]
              ,[IsDeleted]
              ,[IsWorkOrder]
              ,[DateApproved]
              ,[ReferenceId]
              ,[ReturnDate]
			  ,[CreatedDate] AS [IssueDate]  
          FROM [dbo].[CreditMemoAudit] WITH (NOLOCK) WHERE CreditMemoHeaderId=@CreditMemoHeaderId;

END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoHistorList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CreditMemoHeaderId, '') + ''
													  
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