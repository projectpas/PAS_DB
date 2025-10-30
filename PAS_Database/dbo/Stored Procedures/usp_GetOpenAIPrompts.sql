/*************************************************************           
 ** File:   [usp_GetOpenAIPrompts]           
 ** Author:   Devendra Shekh
 ** Description: This SP is used to get the Open AI Prompt By Name
 ** Purpose:         
 ** Date:   29-Oct-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    29-Oct-2025		Devendra Shekh		Created

EXEC [DBO].[usp_GetOpenAIPrompts] 1, 'SupportTicket'
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetOpenAIPrompts]
(
    @MasterCompanyId INT = NULL,
    @Name VARCHAR(100) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY 

		SELECT
			[PromptId],
			[Name],
			[PromptText],
			[Model],
			[APIUrl],
			[MasterCompanyId],
			[CreatedBy],
			[CreatedDate],
			[UpdatedBy],
			[UpdatedDate],
			[IsDeleted],
			[IsActive]
		FROM [dbo].[OpenAIPrompt] WITH (NOLOCK)
		WHERE [Name] = @Name AND [IsActive] = 1 AND [IsDeleted] = 0

	END TRY
	BEGIN CATCH	
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GetOpenAIPrompts'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(255))
			+ '@Parameter2 = ''' + CAST(ISNULL(@Name, '') as varchar(100)) 
		,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END