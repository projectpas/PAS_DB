
/*************************************************************           
 ** File:   [GetAllChieldManagmentStructureDetailsByManagementStructureId]           
 ** Author:   Hemant Saliya
 ** Description: This Stored Procedure is used Get Labor OHSettings By ManagementStructureId    
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/20/2020   Hemant Saliya Created

DECLARE @ManagementStructureIds as VARCHAR(500)

EXEC dbo.GetAllChieldManagmentStructureDetailsByManagementStructureId 90,
      @ManagementStructureIds = @ManagementStructureIds OUTPUT
SELECT @ManagementStructureIds

--EXEC [GetAllChieldManagmentStructureDetailsByManagementStructureId] 90
**************************************************************/

CREATE PROCEDURE [dbo].[GetAllChieldManagmentStructureDetailsByManagementStructureId]
	@ManagementStructureId INT,
	@ManagementStructureIds VARCHAR(500) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
				BEGIN
					DROP TABLE #ManagmetnStrcture
				END

				CREATE TABLE #ManagmetnStrcture (
					ID BIGINT NOT NULL IDENTITY,
					ManagementStructureId BIGINT NULL,
					IsCheck BIT DEFAULT 0)

				INSERT INTO #ManagmetnStrcture (ManagementStructureId,IsCheck)
				SELECT @ManagementStructureId, 1

				INSERT INTO #ManagmetnStrcture (ManagementStructureId)
				SELECT *
				FROM dbo.udfGetMSByMSId(@ManagementStructureId)

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
					FROM dbo.udfGetMSByMSId(@SMSID)

					SET @SMSID = 0;

					UPDATE #ManagmetnStrcture
					SET IsCheck = 1
					WHERE ID = @CNT

					SELECT TOP 1 @CNT = ID, @SMSID = ManagementStructureId
					FROM #ManagmetnStrcture
					WHERE IsCheck = 0
					ORDER BY ID
				END

				SET @ManagementStructureIds = '';

				Select @ManagementStructureIds = @ManagementStructureIds + CAST(Ms.ManagementStructureId AS VARCHAR(20)) + ', '
				FROM dbo.ManagementStructure MS WITH (NOLOCK)
				INNER JOIN #ManagmetnStrcture TMS ON MS.ManagementStructureId = TMS.ManagementStructureId

				IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
				BEGIN
					DROP TABLE #ManagmetnStrcture
				END
			END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;

			IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
			BEGIN
				DROP TABLE #ManagmetnStrcture
			END

			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetAllChieldManagmentStructureDetailsByManagementStructureId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManagementStructureId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END