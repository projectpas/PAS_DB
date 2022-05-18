


/*************************************************************           
 ** File:   [GetCreditMemoById]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get Credit Memo Details
 ** Purpose:         
 ** Date:   18/04/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/04/2022  Moin Bloch     Created
     
-- EXEC GetCreditMemoById 7
************************************************************************/
CREATE PROCEDURE [dbo].[GetCreditMemoById]
@CreditMemoHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

	Declare @ModuleID int = 61
	SELECT CM.[CreditMemoHeaderId]
      ,CM.[CreditMemoNumber]
      ,CM.[RMAHeaderId]
      ,CM.[RMANumber]
      ,CM.[InvoiceId]
      ,CM.[InvoiceNumber]
      ,CM.[InvoiceDate]
      ,CM.[StatusId]
      ,CM.[Status]
      ,CM.[CustomerId]
      ,CM.[CustomerName]
      ,CM.[CustomerCode]
      ,CM.[CustomerContactId]
      ,CM.[CustomerContact]
      ,CM.[CustomerContactPhone]
      ,CM.[IsWarranty]
      ,CM.[IsAccepted]
      ,CM.[ReasonId]
	  ,CM.[Reason]
      ,CM.[DeniedMemo]
      ,CM.[RequestedById]
      ,CM.[RequestedBy]
      ,CM.[ApproverId]
      ,CM.[ApprovedBy]
      ,CM.[WONum]
      ,CM.[WorkOrderId]
      ,CM.[Originalwosonum]
      ,CM.[Memo]
      ,CM.[Notes]
      ,CM.[ManagementStructureId]
      ,CM.[IsEnforce]
      ,CM.[MasterCompanyId]
      ,CM.[CreatedBy]
      ,CM.[UpdatedBy]
      ,CM.[CreatedDate]
      ,CM.[UpdatedDate]
      ,CM.[IsActive]
      ,CM.[IsDeleted]
	  ,MS.[LastMSLevel]
      ,MS.[AllMSlevels]
	  ,CR.[CreditMemoDetailId]
	  ,CM.[IsWorkOrder]
	  ,CM.[ReferenceId]
	  ,CM.[ReturnDate]
  FROM [dbo].[CreditMemo] CM WITH (NOLOCK) 
	   INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MS WITH (NOLOCK) ON CM.CreditMemoHeaderId = MS.ReferenceID AND MS.ModuleID = @ModuleID
	   OUTER APPLY (SELECT TOP 1 CreditMemoDetailId FROM  CreditMemoDetails CD WITH (NOLOCK) WHERE CD.CreditMemoHeaderId = CM.CreditMemoHeaderId) CR 
  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId;

END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CreditMemoHeaderId, '') + ''
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