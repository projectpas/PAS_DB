-- EXEC [StatusUpdateForExpiredSpeedQuotes]
CREATE PROCEDURE [dbo].[StatusUpdateForExpiredSpeedQuotes]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
		BEGIN
			DROP TABLE #TempTable 
		END
		CREATE TABLE #TempTable(Id BIGINT)

		INSERT INTO #TempTable
		SELECT SpeedQuoteId FROM SpeedQuote WITH (NOLOCK)
									WHERE QuoteExpireDate < GETDATE()
									AND StatusId != 4
									AND StatusId != 6
										AND IsActive = 1
									AND IsDeleted = 0

		-- Speed Quote Status Update for expiry date
		UPDATE SpeedQuote SET StatusId = 6, StatusChangeDate = GETDATE(), UpdatedBy = 'PAS Service', UpdatedDate = GETDATE()
		WHERE SpeedQuoteId in (SELECT Id FROM #TempTable)

		DECLARE @id int
		DECLARE @pass varchar(100)

		DECLARE cur CURSOR FOR SELECT Id FROM #TempTable
		OPEN cur

		FETCH NEXT FROM cur INTO @id

		WHILE @@FETCH_STATUS = 0 BEGIN
			EXEC DBO.UpdateSpeedQuoteNameColumnsWithId @id
			FETCH NEXT FROM cur INTO @id
		END
		DROP TABLE #TempTable
		CLOSE cur    
		DEALLOCATE cur

	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'StatusUpdateForExpiredSpeedQuotes' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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