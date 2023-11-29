/*************************************************************           
 ** File:   [GetAccountingPeriodNameBasedOnId]           
 ** Author: Hemant Saliya 
 ** Description: This stored procedure is used retrieve accoount period Name
 ** Purpose:         
 ** Date:   06/21/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/21/2023   Hemant Saliya Created	
     
--EXEC [GetAccountingPeriodNameBasedOnId] '128'
**************************************************************/

CREATE   PROCEDURE dbo.GetAccountingPeriodNameBasedOnId
(
	@id VARCHAR(50) = NULL
)
AS
BEGIN
	BEGIN TRY
		SELECT UPPER(PeriodName) AS PeriodName FROM  dbo.AccountingCalendar WITH (NOLOCK) WHERE  AccountingCalendarId = @id
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
					  , @AdhocComments     VARCHAR(150)    = 'GetPeriodAndCurrecyForTrailBalance' 
					  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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