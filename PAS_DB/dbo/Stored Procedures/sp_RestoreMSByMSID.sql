
-- exec [sp_DeleteMSByEmployee] 71,1
--exec [sp_SaveMSByEmployee] 86,1
CREATE PROCEDURE [dbo].[sp_RestoreMSByMSID] @MSID BIGINT
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

BEGIN TRY
BEGIN TRANSACTION

		IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
		BEGIN
			DROP TABLE #ManagmetnStrcture
		END

		CREATE TABLE #ManagmetnStrcture (
			ID BIGINT NOT NULL IDENTITY
			,ManagementStructureId BIGINT NULL
			,IsCheck BIT DEFAULT 0)

		INSERT INTO #ManagmetnStrcture (
			ManagementStructureId
			,IsCheck)
		SELECT @MSID, 1

		INSERT INTO #ManagmetnStrcture (ManagementStructureId)
		SELECT *
		FROM dbo.udfGetMSByMSIdALL(@MSID)

		DECLARE @CNT AS INT = 0;
		DECLARE @SMSID AS INT = 0;

		SELECT TOP 1 @CNT = ID, @SMSID = ManagementStructureId
		FROM #ManagmetnStrcture
		WHERE IsCheck = 0
		ORDER BY ID

		WHILE (@SMSID > 0)
		BEGIN
			INSERT INTO #ManagmetnStrcture (ManagementStructureId)
			SELECT *
			FROM dbo.udfGetMSByMSIdALL(@SMSID)

			SET @SMSID = 0;

			UPDATE #ManagmetnStrcture
			SET IsCheck = 1
			WHERE ID = @CNT

			SELECT TOP 1 @CNT = ID, @SMSID = ManagementStructureId
			FROM #ManagmetnStrcture
			WHERE IsCheck = 0
			ORDER BY ID
		END

		UPDATE dbo.ManagementStructure
		SET IsDeleted = 0
		FROM dbo.ManagementStructure MS WITH(NOLOCK)
		INNER JOIN #ManagmetnStrcture TMS ON MS.ManagementStructureId = TMS.ManagementStructureId

		SELECT @MSID

		IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
		BEGIN
			DROP TABLE #ManagmetnStrcture
		END

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION

		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'sp_RestoreMSByMSID'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + ISNULL(@MSID, '')
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
		
		IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
		BEGIN
			DROP TABLE #ManagmetnStrcture
		END

	END CATCH
END

IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
BEGIN
	DROP TABLE #ManagmetnStrcture
END