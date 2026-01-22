/*************************************************************           
 ** File:   [GetPeriodAndCurrecyForTrailBalance]           
 ** Author: Satish Gohil
 ** Description: This stored procedure is used retrieve accoount period and currecy
 ** Purpose:         
 ** Date:   06/21/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/21/2023   Satish Gohil Created	
     
--EXEC [GetPeriodAndCurrecyForTrailBalance] '1','1','133',1,0
**************************************************************/

CREATE   PROCEDURE dbo.GetPeriodAndCurrecyForTrailBalance
(
	@id VARCHAR(50) = NULL,
	@id3 VARCHAR(50) = NULL
)
AS
BEGIN
	BEGIN TRY
		DECLARE @AccoutPeriod VARCHAR(50),@Currency VARCHAR(50);

		SELECT @AccoutPeriod = PeriodName FROM  dbo.AccountingCalendar WITH (NOLOCK) WHERE  AccountingCalendarId = @id
		SELECT @Currency = Code FROM  dbo.Currency WITH (NOLOCK) WHERE  CurrencyId = @id3

		SELECT @AccoutPeriod 'PeriodName',@Currency 'Currency'

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