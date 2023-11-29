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
    1    03/15/2020   Moin Bloch	Created
	1    09/06/2023   AMIT GHEDIYA	Updated for Reason display from standalonecm.

 EXECUTE [GetCreditMemoHistorList] 1
**************************************************************/ 

CREATE     PROCEDURE [dbo].[GetCreditMemoHistorList]	
	@CreditMemoHeaderId bigint
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;
		BEGIN TRY

		DECLARE @IsStandAloneCM INT;
		
		SELECT @IsStandAloneCM = IsStandAloneCM FROM [dbo].[CreditMemo] WITH (NOLOCK) WHERE CreditMemoHeaderId = @CreditMemoHeaderId
		
		IF(@IsStandAloneCM > 0)
		BEGIN
			SELECT SACMA.[StandAloneCreditMemoDetailAuditId] AS CreditMemoHeaderAuditId
              ,CMA.[CreditMemoHeaderId]
              ,CMA.[CreditMemoNumber]
              ,CMA.[RMAHeaderId]
              ,CMA.[RMANumber]
              ,CMA.[InvoiceId]
              ,CMA.[InvoiceNumber]
              ,ISNULL(CMA.[InvoiceDate],'') AS InvoiceDate
              ,CMA.[StatusId]
              ,CMA.[Status]
              ,CMA.[CustomerId]
              ,CMA.[CustomerName]
              ,CMA.[CustomerCode]
              ,CMA.[CustomerContactId]
              ,CMA.[CustomerContact]
              ,CMA.[CustomerContactPhone]
              ,CMA.[IsWarranty]
              ,CMA.[IsAccepted]
              ,CMA.[ReasonId]
			  ,SACMA.[Reason]
              ,CMA.[DeniedMemo]
              ,CMA.[RequestedById]
              ,CMA.[RequestedBy]
              ,CMA.[ApproverId]
              ,CMA.[ApprovedBy]
              ,CMA.[WONum]
              ,CMA.[WorkOrderId]
              ,CMA.[Originalwosonum]
              ,CMA.[Memo]
              ,CMA.[Notes]
              ,CMA.[ManagementStructureId]
              ,CMA.[IsEnforce]
              ,CMA.[MasterCompanyId]
              ,CMA.[CreatedBy]
              ,CMA.[UpdatedBy]
              ,CMA.[CreatedDate]
              ,CMA.[UpdatedDate]
              ,CMA.[IsActive]
              ,CMA.[IsDeleted]
              ,CMA.[IsWorkOrder]
              ,CMA.[DateApproved]
              ,CMA.[ReferenceId]
              ,CMA.[ReturnDate]
			  ,CMA.[CreatedDate] AS [IssueDate]  
          FROM [dbo].[StandAloneCreditMemoDetailsaudit] SACMA WITH (NOLOCK) 
		  LEFT JOIN [dbo].[CreditMemo] CMA WITH (NOLOCK) ON SACMA.CreditMemoHeaderId = CMA.CreditMemoHeaderId
		  WHERE SACMA.CreditMemoHeaderId = @CreditMemoHeaderId;
		END
		ELSE
		BEGIN
			SELECT CMA.[CreditMemoHeaderAuditId]
              ,CMA.[CreditMemoHeaderId]
              ,CMA.[CreditMemoNumber]
              ,CMA.[RMAHeaderId]
              ,CMA.[RMANumber]
              ,CMA.[InvoiceId]
              ,CMA.[InvoiceNumber]
              ,ISNULL(CMA.[InvoiceDate],'') AS InvoiceDate
              ,CMA.[StatusId]
              ,CMA.[Status]
              ,CMA.[CustomerId]
              ,CMA.[CustomerName]
              ,CMA.[CustomerCode]
              ,CMA.[CustomerContactId]
              ,CMA.[CustomerContact]
              ,CMA.[CustomerContactPhone]
              ,CMA.[IsWarranty]
              ,CMA.[IsAccepted]
              ,CMA.[ReasonId]
			  ,CMA.[Reason]
              ,CMA.[DeniedMemo]
              ,CMA.[RequestedById]
              ,CMA.[RequestedBy]
              ,CMA.[ApproverId]
              ,CMA.[ApprovedBy]
              ,CMA.[WONum]
              ,CMA.[WorkOrderId]
              ,CMA.[Originalwosonum]
              ,CMA.[Memo]
              ,CMA.[Notes]
              ,CMA.[ManagementStructureId]
              ,CMA.[IsEnforce]
              ,CMA.[MasterCompanyId]
              ,CMA.[CreatedBy]
              ,CMA.[UpdatedBy]
              ,CMA.[CreatedDate]
              ,CMA.[UpdatedDate]
              ,CMA.[IsActive]
              ,CMA.[IsDeleted]
              ,CMA.[IsWorkOrder]
              ,CMA.[DateApproved]
              ,CMA.[ReferenceId]
              ,CMA.[ReturnDate]
			  ,CMA.[CreatedDate] AS [IssueDate]  
          FROM [dbo].[CreditMemoAudit] CMA WITH (NOLOCK) 
		  WHERE CMA.CreditMemoHeaderId=@CreditMemoHeaderId;
		END

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