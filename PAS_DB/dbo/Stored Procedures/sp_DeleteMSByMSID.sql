
-- exec [sp_DeleteMSByEmployee] 71,1
--exec [sp_SaveMSByEmployee] 86,1
CREATE PROCEDURE [dbo].[sp_DeleteMSByMSID] @MSID BIGINT
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
			,IsCheck BIT DEFAULT 0
			)

		INSERT INTO #ManagmetnStrcture (
			ManagementStructureId
			,IsCheck
			)
		SELECT @MSID
			,1

		INSERT INTO #ManagmetnStrcture (ManagementStructureId)
		SELECT *
		FROM dbo.udfGetMSByMSId(@MSID)

		DECLARE @CNT AS INT = 0;
		DECLARE @SMSID AS INT = 0;

		SELECT TOP 1 @CNT = ID
			,@SMSID = ManagementStructureId
		FROM #ManagmetnStrcture
		WHERE IsCheck = 0
		ORDER BY ID

		WHILE (@SMSID > 0)
		BEGIN
			INSERT INTO #ManagmetnStrcture (ManagementStructureId)
			SELECT *
			FROM dbo.udfGetMSByMSId(@SMSID)

			--SELECT * from dbo.udfGetMSByMSId(@SMSID)
			SET @SMSID = 0;

			UPDATE #ManagmetnStrcture
			SET IsCheck = 1
			WHERE ID = @CNT

			SELECT TOP 1 @CNT = ID
				,@SMSID = ManagementStructureId
			FROM #ManagmetnStrcture
			WHERE IsCheck = 0
			ORDER BY ID
		END

		UPDATE dbo.ManagementStructure
		SET IsDeleted = 1
		FROM dbo.ManagementStructure MS WITH(NOLOCK)
		INNER JOIN #ManagmetnStrcture TMS ON MS.ManagementStructureId = TMS.ManagementStructureId

		SELECT @MSID

		IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
		BEGIN
			DROP TABLE #ManagmetnStrcture
		END

COMMIT  TRANSACTION

END TRY    
BEGIN CATCH      
IF @@trancount > 0
	PRINT 'ROLLBACK'
	ROLLBACK TRANSACTION;

	IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
	BEGIN
	DROP TABLE #ManagmetnStrcture 
	END

	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
  , @AdhocComments     VARCHAR(150)    = 'sp_DeleteMSByMSID' 
  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@MSID, '') as Varchar(100)) 
  , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------PLEASE DO NOT EDIT BELOW----------------------------------------

  exec spLogException 
           @DatabaseName           = @DatabaseName
         , @AdhocComments          = @AdhocComments
         , @ProcedureParameters    = @ProcedureParameters
         , @ApplicationName        =  @ApplicationName
         , @ErrorLogID             = @ErrorLogID OUTPUT ;
  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
  RETURN(1);
END CATCH

IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
BEGIN
	DROP TABLE #ManagmetnStrcture
END
END