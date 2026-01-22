/*************************************************************             
 ** File:   [UpdateBatchDetailsById]             
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Update Batch Details By Id  
 ** Purpose:           
 ** Date:   04/01/2024
            
 ** PARAMETERS: @JournalBatchHeaderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    04/01/2024  Moin Bloch     Created  
	
-- EXEC UpdateBatchDetailsById 3  
************************************************************************/  
CREATE   PROCEDURE [dbo].[UpdateBatchDetailsById]  
@JournalBatchHeaderId bigint,  
@AccountingCalendarId bigint,
@UpdatedBy varchar(50)
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			DECLARE @PeriodName VARCHAR(50) = '';
			SELECT @PeriodName = [PeriodName] FROM [dbo].[AccountingCalendar] WITH(NOLOCK) WHERE [AccountingCalendarId] = @AccountingCalendarId;

			UPDATE [dbo].[BatchHeader]
			   SET [AccountingPeriodId] = @AccountingCalendarId
			      ,[AccountingPeriod] = @PeriodName		 
				  ,[UpdatedBy] = @UpdatedBy  
				  ,[UpdatedDate] = GETUTCDATE()
			 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

			UPDATE [dbo].[BatchDetails]
			   SET [AccountingPeriodId] = @AccountingCalendarId
				  ,[AccountingPeriod] = @PeriodName		 
				  ,[UpdatedBy] = @UpdatedBy  
				  ,[UpdatedDate] = GETUTCDATE()				 
			 WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;
		END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateBatchDetailsById' 
			, @ProcedureParameters VARCHAR(3000)  = '@JournalBatchHeaderId = ''' + CAST(ISNULL(@JournalBatchHeaderId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END