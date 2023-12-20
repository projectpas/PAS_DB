/*************************************************************             
 ** File: [PROCCheckAccountingCalanderDate]             
 ** Author:   
 ** Description: This stored procedure is used to Check Accounting Calander Date
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            	
	1    11/01/2023   Moin Bloch    CREATED	

	EXEC [dbo].[PROCCheckAccountingCalanderDate] 168
**************************************************************/  
CREATE   PROCEDURE [dbo].[PROCCheckAccountingCalanderDate]
@ReceivingReconciliationId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @AccountingCalendarId BIGINT = 0;
		DECLARE @CurrentDate DATE = GETUTCDATE();
		DECLARE @FromDate DATE = NULL;
		DECLARE @ToDate DATE = NULL;

		SELECT @AccountingCalendarId = [AccountingCalendarId] 
		  FROM [dbo].[ReceivingReconciliationHeader] WITH(NOLOCK)
		 WHERE [ReceivingReconciliationId] = @ReceivingReconciliationId 
		  
		SELECT [AccountingCalendarId] 
		  FROM [dbo].[AccountingCalendar] WITH(NOLOCK)
		 WHERE [AccountingCalendarId] = @AccountingCalendarId
		   AND @CurrentDate BETWEEN [FromDate] AND [ToDate];

	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'PROCCheckAccountingCalanderDate' 
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReceivingReconciliationId, '') AS VARCHAR(100))  
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