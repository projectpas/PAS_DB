/*************************************************************             
 ** File:   [USP_GetAccountingCalendarYearDetails]             
 ** Author:  Hemant Saliya
 ** Description: This stored procedure is used to Close Acconting Calendor Year
 ** Purpose:           
 ** Date: 06/09/2023
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    06/09/2023   Hemant Saliya  Created
 ************************************************************** 
 EXEC USP_GetAccountingCalendarYearDetails '3,1,6'
**************************************************************/  

CREATE   PROCEDURE [dbo].[USP_GetAccountingCalendarYearDetails]
(
	@LegalEntityIds VARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		BEGIN

			SELECT DISTINCT  FiscalYear AS FiscalYear, MIN(AccountingCalendarId) FromPeriodId, MAX(AccountingCalendarId) ToPeriodId, MIN(FromDate) FromDate, MAX(ToDate) ToDate--, LegalEntityId
			FROM dbo.AccountingCalendar WITH(NOLOCK)
			WHERE LegalEntityId IN (SELECT ITEM FROM dbo.SplitString(@LegalEntityIds,',')) 
			GROUP BY FiscalYear--, LegalEntityId

		END
	END TRY
	BEGIN CATCH
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		---------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'USP_GetAccountingCalendarYearDetails' 
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
		, @ApplicationName VARCHAR(100) = 'PAS'
		---------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
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