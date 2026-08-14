/*************************************************************
 ** File:   [usp_GetILSConditionCodeMap]
 ** Author:   Nakul
 ** Description: This stored procedure is used to build a lookup of internal Condition code -> mapped ILS Condition code for a Master Company, used by the ILS CSV export
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

--EXEC [usp_GetILSConditionCodeMap] 1
**************************************************************/
CREATE   PROCEDURE dbo.usp_GetILSConditionCodeMap
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT orig.Description AS OriginalCode, mapped.Description AS MappedCode
		FROM dbo.ILSConditionMapping m WITH (NOLOCK)
		INNER JOIN dbo.Condition orig WITH (NOLOCK) ON orig.ConditionId = m.ConditionId
		INNER JOIN dbo.Condition mapped WITH (NOLOCK) ON mapped.ConditionId = m.ILSConditionId
		WHERE m.MasterCompanyId = @MasterCompanyId AND m.IsDeleted = 0 AND m.ILSConditionId IS NOT NULL
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GetILSConditionCodeMap'
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