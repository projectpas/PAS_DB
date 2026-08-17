/*************************************************************
 ** File:   [usp_GetILSConditions]
 ** Author:   Nakul
 ** Description: This stored procedure is used to retrieve the list of Conditions flagged as valid ILS marketplace conditions, scoped by Master Company
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

--EXEC [usp_GetILSConditions] 1
**************************************************************/
CREATE    PROCEDURE dbo.usp_GetILSConditions
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT ConditionId, Description, Code, Memo, SequenceNo
		FROM dbo.vw_ILSConditions
		WHERE MasterCompanyId = @MasterCompanyId
		ORDER BY SequenceNo
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GetILSConditions'
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