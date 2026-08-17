/*************************************************************
 ** File:   [usp_GetILSConditionMapping]
 ** Author:   Nakul
 ** Description: This stored procedure is used to retrieve the saved Condition to ILS Condition mappings for a Master Company
 ** Purpose:
 ** Date:   08/13/2026

 ** PARAMETERS: @MasterCompanyId INT

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    08/13/2026   Nakul		Created

--EXEC [usp_GetILSConditionMapping] 1
**************************************************************/
CREATE   PROCEDURE dbo.usp_GetILSConditionMapping
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT ILSConditionMappingId, ConditionId, ILSConditionId, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate
		FROM dbo.ILSConditionMapping WITH (NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId AND IsDeleted = 0
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GetILSConditionMapping'
		,@ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)) + ''''
		,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);
	END CATCH
END