/*************************************************************           
 ** File:   [usp_UpdateIntegrationEmailStatus]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used to Update IntegrationEmail Status
 ** Purpose:         
 ** Date:   18 Aug 2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------					--------------------------------          
    1    18 Aug 2025		Devendra Shekh			Created

************************************************************************/
CREATE     PROCEDURE [dbo].[usp_UpdateIntegrationEmailStatus]
	@IntegrationEmailID BIGINT = NULL,
    @EmailStatusId INT = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN
			 
			DECLARE  @PendingeEmailStatus INT = 1, @InProgressEmailStatus INT = 2, @CompletedEmailStatus INT = 3, @FailedEmailStatus INT = 4;
			DECLARE @TryLimit INT = 3;

			IF(@EmailStatusId = @FailedEmailStatus)
			BEGIN
				UPDATE IEM
				SET IEM.EmailStatusId = @EmailStatusId,
					IEM.UpdatedDate = GETUTCDATE()
				FROM [dbo].[IntegrationEmail] IEM WITH(NOLOCK)
				WHERE IEM.IntegrationEmailID = @IntegrationEmailID;
			END
			ELSE
			BEGIN
				UPDATE IEM
				SET IEM.EmailStatusId = CASE WHEN ISNULL(IEM.AttemptCount, 0) + 1 = @TryLimit AND @EmailStatusId != @CompletedEmailStatus THEN @FailedEmailStatus ELSE @EmailStatusId END,
					IEM.AttemptCount = CASE WHEN ISNULL(IEM.AttemptCount, 0) = 0 THEN 1 ELSE IEM.AttemptCount + 1 END,
					IEM.UpdatedDate = GETUTCDATE()
				FROM [dbo].[IntegrationEmail] IEM WITH(NOLOCK)
				WHERE IEM.IntegrationEmailID = @IntegrationEmailID;
			END
		END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)		= 'usp_UpdateIntegrationEmailStatus' 
		, @ProcedureParameters VARCHAR(3000)	= ''
		, @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
				@DatabaseName           = @DatabaseName
				, @AdhocComments          = @AdhocComments
				, @ProcedureParameters = @ProcedureParameters
				, @ApplicationName        =  @ApplicationName
				, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END