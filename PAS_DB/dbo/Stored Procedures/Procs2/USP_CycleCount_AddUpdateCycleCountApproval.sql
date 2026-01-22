/*************************************************************               
 ** File:   [USP_CycleCount_AddUpdateCycleCountApproval]               
 ** Author:   Moin Bloch
 ** Description:         
 ** Purpose:             
 ** Date:   29/10/2024            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author       Change Description                
 ** --   --------     -------      --------------------------------              
    1    29/10/2024   Moin Bloch   Created    
         
 EXEC USP_CycleCount_AddUpdateCycleCountApproval  
**************************************************************/
CREATE PROCEDURE [dbo].[USP_CycleCount_AddUpdateCycleCountApproval](@TableCycleCountApprovalType CycleCountApprovalType READONLY)  
AS 
BEGIN
		
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
	BEGIN TRY
	BEGIN TRANSACTION  
		BEGIN   
			DECLARE @SentForInternalApproval BIGINT = 1;
			DECLARE @SubmitInternalApproval BIGINT = 2;
			DECLARE @SentForCustomerApproval BIGINT = 3;
			DECLARE @SubmitCustomerApproval BIGINT = 4;
			DECLARE @ApprovedApproval AS BIGINT = 5;
			DECLARE @PendingStatus AS BIGINT; 
			    SET @PendingStatus = (SELECT [ApprovalStatusId] FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE [Name] = 'Pending');
			DECLARE @ApprovedStatus AS BIGINT; 
			    SET @ApprovedStatus = (SELECT [ApprovalStatusId] FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE [Name] = 'Approved');
			DECLARE @RejectedStatus AS BIGINT; 
			    SET @RejectedStatus = (SELECT [ApprovalStatusId] FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE [Name] = 'Rejected');
			DECLARE @WaitingForApprovalStatus AS BIGINT; 
			    SET @WaitingForApprovalStatus = (SELECT [ApprovalStatusId] FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE [Name] = 'Waiting for Approval');
			
			IF((SELECT COUNT(CycleCountApprovalId) FROM @TableCycleCountApprovalType) > 0 )
				BEGIN
					MERGE dbo.CycleCountApproval AS TARGET
					USING @TableCycleCountApprovalType AS SOURCE ON (TARGET.CycleCountId = SOURCE.CycleCountId AND 
					  												 TARGET.CycleCountApprovalId = SOURCE.CycleCountApprovalId) 
					WHEN MATCHED 
					THEN UPDATE
					SET 
					TARGET.[StatusId] = CASE WHEN  SOURCE.[ActionId] = @SentForInternalApproval THEN @WaitingForApprovalStatus ELSE SOURCE.[StatusId] END,
					TARGET.[Memo] = SOURCE.[Memo],
					TARGET.[UpdatedDate] = GETDATE(),
					TARGET.[UpdatedBy] = SOURCE.[UpdatedBy],
					TARGET.[SentDate] = CASE WHEN  SOURCE.[ActionId] = @SentForInternalApproval THEN SOURCE.[SentDate] ELSE TARGET.[SentDate] END,
					TARGET.[ActionId] = CASE WHEN  SOURCE.[ActionId] = @SentForInternalApproval THEN @SubmitInternalApproval WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @RejectedStatus THEN @SentForInternalApproval WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @ApprovedStatus THEN @ApprovedApproval ELSE TARGET.[ActionId] END,
					TARGET.[RejectedDate] = CASE WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @RejectedStatus THEN GETUTCDATE() WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @ApprovedStatus THEN NULL ELSE TARGET.[RejectedDate] END,
					TARGET.[RejectedBy] = CASE WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @RejectedStatus THEN SOURCE.[RejectedBy] WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @ApprovedStatus THEN NULL ELSE TARGET.[RejectedBy] END,
					TARGET.[ApprovedDate] = CASE WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @ApprovedStatus THEN GETUTCDATE() ELSE TARGET.[ApprovedDate] END,
					TARGET.[ApprovedById] = CASE WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @ApprovedStatus THEN SOURCE.[ApprovedById] ELSE TARGET.[ApprovedById] END,
					TARGET.[InternalSentToId] = CASE WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @ApprovedStatus THEN SOURCE.[InternalSentToId] ELSE TARGET.[InternalSentToId] END,
					TARGET.[InternalSentById] = CASE WHEN SOURCE.[ActionId] = @SubmitInternalApproval AND SOURCE.[StatusId] = @ApprovedStatus THEN SOURCE.[InternalSentById] ELSE TARGET.[InternalSentById] END

					WHEN NOT MATCHED BY TARGET
					THEN 
					INSERT ([CycleCountId], [CycleCountDetailId], [InternalSentToId], [InternalSentToName], [InternalSentById],
					        [SentDate], [ApprovedDate], [ApprovedById], [ApprovedByName], [RejectedDate], [RejectedBy], [RejectedByName], [StatusId], 
							[StatusName], [ActionId], [Memo], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]) 
					 VALUES (SOURCE.[CycleCountId],SOURCE.[CycleCountDetailId],SOURCE.[InternalSentToId],SOURCE.[InternalSentToName],SOURCE.[InternalSentById],
					         SOURCE.[SentDate],GETUTCDATE(),CASE WHEN SOURCE.[ApprovedById] = 0 THEN NULL ELSE SOURCE.[ApprovedById] END,SOURCE.[ApprovedByName],SOURCE.[RejectedDate],NULL,SOURCE.[RejectedByName],@WaitingForApprovalStatus,
					  	     SOURCE.[StatusName],@SubmitInternalApproval,SOURCE.[Memo],SOURCE.[MasterCompanyId],SOURCE.[CreatedBy],SOURCE.[UpdatedBy],GETUTCDATE(),GETUTCDATE(),1,0);
					
					END  
		COMMIT  TRANSACTION 			
	END
	END TRY  
	BEGIN CATCH      
		IF @@trancount > 0
		 DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorLine INT = ERROR_LINE();    
    -- Existing error handling
    RAISERROR('Unexpected Error Occurred in the database. Please let the support team know of the error number: %d', 16, 1, @ErrorNumber);
    ROLLBACK TRANSACTION;
    RETURN(1);
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CycleCount_AddUpdateCycleCountApproval' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''													   
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