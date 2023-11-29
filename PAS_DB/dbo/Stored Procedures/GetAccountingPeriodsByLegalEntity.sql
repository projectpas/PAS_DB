/*************************************************************             
 ** File:   [GetAccountingPeriodsByLegalEntity]             
 ** Author: Hemant Saliya  
 ** Description: This stored procedure is used to Get income statement(actual) report Data 
 ** Purpose: Initial Draft           
 ** Date: 08/08/2023  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    08/08/2023   Hemant Saliya  Created

************************************************************************
EXEC [GetAccountingPeriodsByLegalEntity] 1
************************************************************************/
CREATE   PROCEDURE [dbo].[GetAccountingPeriodsByLegalEntity]
@LegalEntityId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
			SELECT DISTINCT AC.AccountingCalendarId, AC.PeriodName, AC.FromDate, AC.ToDate,AC.FiscalName, AC.FiscalYear,  AC.[Period],
						LEAD(AC.AccountingCalendarId) OVER (ORDER BY AC.FromDate) As AccountingCalendarIdNext ,
						LEAD(AC.PeriodName) OVER (ORDER BY AC.FromDate) As PeriodNameNext,
						LEAD(AC.FromDate) OVER (ORDER BY AC.FromDate) As FromDateNext ,
						LEAD(AC.ToDate) OVER (ORDER BY AC.FromDate) as ToDateNext,
						LEAD(AC.FiscalName) OVER (ORDER BY AC.FromDate) as FiscalNameNext,
						LEAD(AC.FiscalYear) OVER (ORDER BY AC.FromDate) as FiscalYearNext 
			FROM dbo.EntityStructureSetup ESS WITH(NOLOCK)
				JOIN dbo.ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
				JOIN dbo.AccountingCalendar AC WITH(NOLOCK) ON MSL.LegalEntityId = AC.LegalEntityId
			WHERE AC.LegalEntityId = @LegalEntityId AND AC.IsDeleted = 0 --AND AC.FiscalYear >= YEAR(GETDATE()) 
			GROUP BY  AC.AccountingCalendarId, AC.PeriodName, AC.FromDate, AC.ToDate, AC.FiscalName, AC.FiscalYear, AC.[Period]
			ORDER BY AC.FiscalYear DESC, AC.[Period] ASC;
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetAccountingPeriodsByLegalEntity' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LegalEntityId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END