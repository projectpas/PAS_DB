---------------------------------------------------------------------------------------------------
--- exec sp_UpdateManualJournalDetail 214
CREATE Procedure [dbo].[sp_UpdateManualJournalDetail]
@ManualJournalHeaderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN
		UPDATE dbo.ManualJournalApproval SET ApprovedById = null , ApprovedDate = null , ApprovedByName = null
		Where ManualJournalHeaderId = @ManualJournalHeaderId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WHERE Name  =  'Approved') 


		UPDATE dbo.ManualJournalApproval SET RejectedBy = null , RejectedDate =  null , RejectedByName = null
		Where ManualJournalHeaderId = @ManualJournalHeaderId and StatusId != (select ApprovalStatusId from  dbo.ApprovalStatus WHERE Name  =  'Rejected') 

		UPDATE dbo.ManualJournalApproval
		SET ApprovedByName = AE.FirstName + ' ' + AE.LastName,
			RejectedByName = RE.FirstName + ' ' + RE.LastName,
			StatusName = ASS.Description,
			InternalSentToName = (INST.FirstName + ' ' + INST.LastName)
		FROM dbo.ManualJournalApproval PA
			 LEFT JOIN dbo.Employee AE on PA.ApprovedById = AE.EmployeeId
			 LEFT JOIN DBO.Employee INST WITH (NOLOCK) ON INST.EmployeeId = PA.InternalSentToId
			 LEFT JOIN dbo.Employee RE on PA.RejectedBy = RE.EmployeeId
			 LEFT JOIN dbo.ApprovalStatus ASS on PA.StatusId = ASS.ApprovalStatusId

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_UpdateManualJournalDetail' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManualJournalHeaderId, '') + ''
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