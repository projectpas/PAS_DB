/*************************************************************           
 ** File:   [usp_GetSupportAssignmentMaster_ById]           
 ** Author:   Devendra Shekh
 ** Description: This SP is used to get the Support Assignment Master Data By MasterCompanyId
 ** Purpose:         
 ** Date:   07-Nov-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    07-Nov-2025		Devendra Shekh		Created

EXEC [DBO].[usp_GetSupportAssignmentMaster_ById] 1
EXEC [DBO].[usp_GetSupportAssignmentMaster_ById] 10
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetSupportAssignmentMaster_ById]
(
    @MasterCompanyId INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY 
		
		DECLARE @DemoMasterCompanyId INT;

		SELECT @DemoMasterCompanyId = [MasterCompanyId] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyCode] = 'DEMO';

		IF EXISTS(SELECT 1 FROM [dbo].[SupportAssignmentMaster] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [MasterCompanyId] = @MasterCompanyId)
		BEGIN
			SELECT [EmployeeId], [EmployeeEmail], [CC], [BCC], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
			FROM [dbo].[SupportAssignmentMaster] WITH (NOLOCK)
			WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [MasterCompanyId] = @MasterCompanyId;
		END
		ELSE
		BEGIN
			SELECT [EmployeeId], [EmployeeEmail], [CC], [BCC], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
			FROM [dbo].[SupportAssignmentMaster] WITH (NOLOCK)
			WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [MasterCompanyId] = @DemoMasterCompanyId;
		END

	END TRY
	BEGIN CATCH	
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GetSupportAssignmentMaster_ById'
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
	END CATCH
END