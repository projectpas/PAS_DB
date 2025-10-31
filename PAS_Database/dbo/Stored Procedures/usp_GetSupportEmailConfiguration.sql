/*************************************************************           
 ** File:   [usp_GetSupportEmailConfiguration]           
 ** Author:   Devendra Shekh
 ** Description: This SP is used to get the SupportEmail Configuration 
 ** Purpose:         
 ** Date:   29-Oct-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    29-Oct-2025		Devendra Shekh		Created

EXEC [DBO].[usp_GetSupportEmailConfiguration] 1
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetSupportEmailConfiguration]
(
    @MasterCompanyId INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY 

		SELECT
			[SupportEmailConfigurationId],
			[SmtpUserEmail],
			[smtpserver],
			[SmtpEmailPassword],
			[SmtpPort],
			[UseSsl],
			[MasterCompanyId],
			[CreatedBy],
			[UpdatedBy],
			[CreatedDate],
			[UpdatedDate],
			[IsActive],
			[IsDeleted]
		FROM [dbo].[SupportEmailConfiguration] WITH (NOLOCK)
		WHERE [IsActive] = 1 AND [IsDeleted] = 0

	END TRY
	BEGIN CATCH	
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GetSupportEmailConfiguration'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(255))
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