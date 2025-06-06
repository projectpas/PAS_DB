/*************************************************************           
 ** File:   [USP_ChangeWOQStatusAfterApproval]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Change WOQ Status After Approval
 ** Date:   20-May-2025        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    20-May-2025   Devendra Shekh		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ChangeWOQStatusAfterApproval]
@WorkOrderQuoteId BIGINT = NULL,
@UpdatedBy VARCHAR(256) = NULL,
@WOPartNoId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	
		DECLARE @ApprovedStatus INT = 5, @OpenStatus INT = 1;

		IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId)
		BEGIN
			IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId AND [QuoteStatusId] = @ApprovedStatus)
			BEGIN
				UPDATE wq
				SET 
					wq.QuoteStatusId = @OpenStatus,
					wq.UpdatedBy = @UpdatedBy,
					wq.UpdatedDate = GETUTCDATE()
				FROM [dbo].[WorkOrderQuote] wq WITH(NOLOCK)
				WHERE wq.WorkOrderQuoteId = @WorkOrderQuoteId AND wq.QuoteStatusId = @ApprovedStatus;
			END

			IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderApproval] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId AND [WorkOrderPartNoId] = @WOPartNoId AND [ApprovalActionId] = @ApprovedStatus)
			BEGIN
				UPDATE wa
				SET 
					wa.ApprovalActionId = 0,
					wa.InternalApprovedById = NULL,
					wa.InternalStatusId = NULL,
					wa.InternalApprovedDate = NULL,
					wa.CustomerApprovedById = NULL,
					wa.CustomerStatusId = NULL,
					wa.CustomerApprovedDate = NULL,
					wa.UpdatedBy = @UpdatedBy,
					wa.UpdatedDate = GETUTCDATE()
				FROM [dbo].[WorkOrderApproval] wa WITH(NOLOCK)
				WHERE wa.WorkOrderQuoteId = @WorkOrderQuoteId AND wa.WorkOrderPartNoId = @WOPartNoId AND wa.ApprovalActionId = @ApprovedStatus;
			END
		END

	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_ChangeWOQStatusAfterApproval' 
		, @ProcedureParameters VARCHAR(3000) = ''
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