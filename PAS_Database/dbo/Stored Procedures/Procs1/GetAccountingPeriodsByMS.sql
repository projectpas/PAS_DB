--EXEC GetAccountingPeriodsByMS 1
CREATE PROCEDURE [dbo].[GetAccountingPeriodsByMS]
@EntityStructureId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
			SELECT DISTINCT AC.AccountingCalendarId,AC.PeriodName,AC.FromDate,AC.ToDate,AC.FiscalName,AC.FiscalYear,AC.IsAdjustPeriod FROM dbo.EntityStructureSetup ESS WITH(NOLOCK)
			INNER JOIN dbo.ManagementStructureLevel MSL WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
			INNER JOIN dbo.AccountingCalendar AC WITH(NOLOCK) ON MSL.LegalEntityId = AC.LegalEntityId
			where ESS.EntityStructureId = @EntityStructureId --AND AC.[Status]='Open'
			--AND (CAST(GETDATE() as date) >= AC.FromDate AND CAST(GETDATE() as date) >= AC.ToDate)
			AND AC.IsDeleted = 0 AND AC.FiscalYear=YEAR(GETDATE()) ORDER BY AC.AccountingCalendarId;
	END TRY    
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetAccountingPeriodsByMS' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EntityStructureId, '') + ''
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