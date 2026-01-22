/*************************************************************               
 ** File:   [PROCAddUpdatePurchaseApproval]               
 ** Author:   SHREY CHANDEGARA    
 ** Description:         
 ** Purpose:             
 ** Date:   21/08/2024            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author   Change Description                
 ** --   --------     -------   --------------------------------              
    1    21/08/2024    SHREY CHANDEGARA  Created    
         
 EXECUTE PROCAddUpdatePurchaseApproval  
**************************************************************/
CREATE   PROCEDURE [dbo].[PROCAddUpdatePurchaseApproval](@TablePurchaseOrderApprovalType PurchaseOrderApprovalType READONLY)  
AS 
BEGIN
		
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
	BEGIN TRY
	BEGIN TRANSACTION  
		BEGIN   
			DECLARE @SentForInternalApproval AS BIGINT; SET @SentForInternalApproval = 1;
			DECLARE @SubmitInternalApproval AS BIGINT; SET @SubmitInternalApproval = 2;
			DECLARE @SentForCustomerApproval AS BIGINT; SET @SentForCustomerApproval =  3;
			DECLARE @SubmitCustomerApproval AS BIGINT; SET @SubmitCustomerApproval = 4;
			DECLARE @ApprovedApproval AS BIGINT; SET @ApprovedApproval = 5;
			DECLARE @PendingStatus AS BIGINT; SET @PendingStatus = (SELECT ApprovalStatusId FROM ApprovalStatus WHERE [Name] = 'Pending');
			DECLARE @ApprovedStatus AS BIGINT; SET @ApprovedStatus = (SELECT ApprovalStatusId FROM ApprovalStatus WHERE [Name] = 'Approved');
			DECLARE @RejectedStatus AS BIGINT; SET @RejectedStatus = (SELECT ApprovalStatusId FROM ApprovalStatus WHERE [Name] = 'Rejected');
			DECLARE @WaitingForApprovalStatus AS BIGINT; SET @WaitingForApprovalStatus = (SELECT ApprovalStatusId FROM ApprovalStatus WHERE [Name] = 'Waiting for Approval');
			IF((SELECT COUNT(PurchaseOrderApprovalId) FROM @TablePurchaseOrderApprovalType) > 0 )
				BEGIN
					MERGE dbo.PurchaseOrderApproval AS TARGET
					USING @TablePurchaseOrderApprovalType AS SOURCE ON (TARGET.PurchaseOrderId = SOURCE.PurchaseOrderId AND 
					  															 TARGET.PurchaseOrderApprovalId = SOURCE.PurchaseOrderApprovalId) 
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
					INSERT
						   ([PurchaseOrderId],[PurchaseOrderPartId],[Memo],[SentDate],[ApprovedDate],[ApprovedById],[ApprovedByName],[RejectedDate],[RejectedBy],[RejectedByName]
						   ,[StatusId] ,[StatusName],[ActionId] ,[MasterCompanyId],[CreatedBy] ,[UpdatedBy] ,[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[InternalSentToId]
						   ,[InternalSentToName],[InternalSentById])
					 VALUES(SOURCE.[PurchaseOrderId],SOURCE.[PurchaseOrderPartId],SOURCE.[Memo],SOURCE.[SentDate],GETUTCDATE(),CASE WHEN SOURCE.[ApprovedById] = 0 THEN NULL ELSE SOURCE.[ApprovedById] END,SOURCE.[ApprovedByName],SOURCE.[RejectedDate],NULL,
							SOURCE.[RejectedByName],@WaitingForApprovalStatus,SOURCE.[StatusName],@SubmitInternalApproval,SOURCE.[MasterCompanyId],SOURCE.[CreatedBy],SOURCE.[UpdatedBy],GETDATE(),
							GETDATE(),1,0,SOURCE.[InternalSentToId],SOURCE.[InternalSentToName],SOURCE.[InternalSentById]);
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

    PRINT 'Error Number: ' + CAST(@ErrorNumber AS VARCHAR);
    PRINT 'Error Message: ' + @ErrorMessage;
    PRINT 'Error Severity: ' + CAST(@ErrorSeverity AS VARCHAR);
    PRINT 'Error State: ' + CAST(@ErrorState AS VARCHAR);
    PRINT 'Error Line: ' + CAST(@ErrorLine AS VARCHAR);
    
    -- Existing error handling
    RAISERROR('Unexpected Error Occurred in the database. Please let the support team know of the error number: %d', 16, 1, @ErrorNumber);
    ROLLBACK TRANSACTION;
    RETURN(1);
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'PROCAddUpdatePurchaseApproval' 
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