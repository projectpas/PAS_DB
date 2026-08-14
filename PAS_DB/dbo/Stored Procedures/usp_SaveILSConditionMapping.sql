/*************************************************************
 ** File:   [usp_SaveILSConditionMapping]
 ** Author:   Nakul
 ** Description: This stored procedure is used to insert or update a single Condition to ILS Condition mapping row for a Master Company
 ** Purpose:
 ** Date:   08/13/2026

 ** PARAMETERS: @ConditionId BIGINT, @ILSConditionId BIGINT, @MasterCompanyId INT, @UpdatedBy VARCHAR(256)

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    08/13/2026   Nakul		Created

--EXEC [usp_SaveILSConditionMapping] 9,15,1,'admin'
**************************************************************/
CREATE    PROCEDURE dbo.usp_SaveILSConditionMapping
	@ConditionId BIGINT,
	@ILSConditionId BIGINT = NULL,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF EXISTS (SELECT 1 FROM dbo.ILSConditionMapping WHERE ConditionId = @ConditionId AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0)
		BEGIN
			UPDATE dbo.ILSConditionMapping
			SET ILSConditionId = @ILSConditionId, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE()
			WHERE ConditionId = @ConditionId AND MasterCompanyId = @MasterCompanyId AND IsDeleted = 0
		END
		ELSE
		BEGIN
			INSERT INTO dbo.ILSConditionMapping (ConditionId, ILSConditionId, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsActive, IsDeleted)
			VALUES (@ConditionId, @ILSConditionId, @MasterCompanyId, @UpdatedBy, GETDATE(), @UpdatedBy, GETDATE(), 1, 0)
		END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_SaveILSConditionMapping'
		,@ProcedureParameters VARCHAR(3000) = '@ConditionId = ''' + CAST(ISNULL(@ConditionId, 0) AS VARCHAR(100))
			+ ''', @ILSConditionId = ''' + CAST(ISNULL(@ILSConditionId, 0) AS VARCHAR(100))
			+ ''', @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100))
			+ ''', @UpdatedBy = ''' + ISNULL(@UpdatedBy, '') + ''''
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