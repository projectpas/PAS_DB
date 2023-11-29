
CREATE     PROCEDURE [dbo].[AccountingCalendar_HistoryById]
@AccReferenceId int,
@TableName varchar(100),
@PeriodName varchar(256)
 
--select * from AccountingCalendarHistory

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					ACC.[AccountingCalendarHistoryId],
					ACC.[ReferenceId] as [ReferenceId],
					ACC.[PeriodName],
					ACC.[TableName],
					ACC.[StatusName],
					ACC.[LegalEntityId],
					ACC.[LegalEntityName],
					ACC.[ledgerId],
					ACC.[ledgerName],
					ACC.[MasterCompanyId],
					ACC.[CreatedBy],
					ACC.[UpdatedBy],
					ACC.[CreatedDate],
					ACC.[UpdatedDate],
					ACC.[IsActive]
				FROM [DBO].AccountingCalendarHistory ACC WITH (NOLOCK) 
				
				WHERE ACC.ReferenceId = @AccReferenceId and @TableName = ACC.[TableName] and @PeriodName=ACC.[PeriodName] order by AccountingCalendarHistoryId desc
			
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AccountingCalendar_HistoryById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AccReferenceId, '')+'@Parameter2 = '''+ ISNULL(@TableName, '')+'@Parameter3 = '''+ ISNULL(@PeriodName, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END