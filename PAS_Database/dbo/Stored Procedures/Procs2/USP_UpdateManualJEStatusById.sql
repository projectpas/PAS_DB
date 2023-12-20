/*************************************************************           
 ** File:   [USP_UpdateManualJEStatusById]           
 ** Author: Satish Gohil
 ** Description: This stored procedure is used change manual JE status
 ** Purpose:         
 ** Date:   07/07/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/07/2023   Satish Gohil Created	
     
--EXEC [USP_GetTrailBalanceReportData] '1','1','134',1,0
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_UpdateManualJEStatusById]
(
	@ManualJournalHeaderId BIGINT,
	@UpdatedBy VARCHAR(100)
)
AS
BEGIN 
	BEGIN TRY
		DECLARE @COUNT INT = 0;
		DECLARE @ApprovalList INT = 0;
		DECLARE @PendingApprovalList INT = 0;
		DECLARE @StatusId INT = 0;

		SELECT @StatusId = ManualJournalStatusId FROM dbo.ManualJournalStatus WITH(NOLOCK) WHERE Name = 'Approved'
		SELECT @COUNT = COUNT(*) FROM dbo.ManualJournalDetails WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId
		SELECT @ApprovalList = COUNT(*) FROM dbo.ManualJournalApproval WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId
		SELECT @PendingApprovalList = COUNT(*) FROM dbo.ManualJournalApproval WITH(NOLOCK) WHERE ManualJournalHeaderId = @ManualJournalHeaderId AND ActionId <> @StatusId

		print(@COUNT);
		print(@ApprovalList);
		print(@PendingApprovalList);
		IF(@PendingApprovalList > 0)
		BEGIN
			UPDATE dbo.ManualJournalHeader SET ManualJournalStatusId = (SELECT ManualJournalStatusId FROM ManualJournalStatus WHERE Name = 'Pending'),
			UpdatedBy = @UpdatedBy,UpdatedDate = GETUTCDATE() WHERE ManualJournalHeaderId = @ManualJournalHeaderId
		END
		ELSE
		BEGIN 
			IF(@COUNT = @ApprovalList)
			BEGIN
				UPDATE dbo.ManualJournalHeader SET ManualJournalStatusId = (SELECT ManualJournalStatusId FROM ManualJournalStatus WHERE Name = 'Approved'),
				UpdatedBy = @UpdatedBy,UpdatedDate = GETUTCDATE()  WHERE ManualJournalHeaderId = @ManualJournalHeaderId
			END
			ELSE
			BEGIN
				UPDATE dbo.ManualJournalHeader SET ManualJournalStatusId = (SELECT ManualJournalStatusId FROM ManualJournalStatus WHERE Name = 'Pending'),
						UpdatedBy = @UpdatedBy,UpdatedDate = GETUTCDATE() WHERE ManualJournalHeaderId = @ManualJournalHeaderId
			END
		END
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
					  , @AdhocComments     VARCHAR(150)    = 'USP_UpdateManualJEStatusById'   
					  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManualJournalHeaderId, '') + ''  
					  , @ApplicationName VARCHAR(100) = 'PAS'  
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
	END CATCH
END