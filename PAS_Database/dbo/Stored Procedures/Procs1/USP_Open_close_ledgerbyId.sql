
/*************************************************************           
 ** File:   [USP_Open_close_ledgerbyId]           
 ** Author: 
 ** Description: This stored procedure is used to populate Calendar Listing.    
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    30/08/2022   subhash saliya Changes ledger id
    -- exec USP_Open_close_ledgerbyId 1,1,2022 
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_Open_close_ledgerbyId]
@LegalEntityId INT,
@ledgerId INT,
@FiscalYear int = NULL

AS
	BEGIN

		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		SET NOCOUNT ON;
		DECLARE @RecordFrom int;
		Declare @IsActive bit = 1
		Declare @Count Int;
		Declare @PageSize Int =10

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					;With Result AS(
							SELECT Name,FiscalYear, min(AccountingCalendarId) as AccountingCalendarId_Min,
							max(AccountingCalendarId) as AccountingCalendarId_Max, LegalEntityId, ledgerId,max(Description) as Descriptionmax
							from AccountingCalendar WITH(NOLOCK)
							WHERE IsDeleted =0 AND IsActive=1 AND ledgerId=@ledgerId and LegalEntityId=@LegalEntityId and FiscalYear=@FiscalYear
							GROUP BY Name, FiscalYear, LegalEntityId, ledgerId
					), FinalResult AS(
					Select RS.AccountingCalendarId_Max AccountingCalendarId, RS.Name, RS.Descriptionmax as Description, AC_Max.FiscalName,RS.FiscalYear,
					AC_Max.Quater, AC_Max.Period, AC_Min.FromDate,AC_Max.ToDate, AC_Max.PeriodName, AC_Max.Notes, AC_Max.MasterCompanyId,AC_Max.CreatedBy,AC_Max.UpdatedBy,
					AC_Max.CreatedDate, AC_Max.UpdatedDate, AC_Max.IsActive, AC_Max.IsDeleted, AC_Max.Status, AC_Max.LegalEntityId,AC_Max.isUpdate,AC_Max.IsAdjustPeriod,
					AC_Max.NoOfPeriods, AC_Max.PeriodType, AC_Max.ledgerId, LE.Name LagalEntity,
					(select * from AccountingCalendar where  IsDeleted =0 AND IsActive=1 and Name=RS.Name AND FiscalYear = RS.FiscalYear and ledgerId=@ledgerId and LegalEntityId=@LegalEntityId and FiscalYear=@FiscalYear order by Period asc for JSON PATH) as calendarListData
					from Result RS WITH(NOLOCK)
					inner join AccountingCalendar as AC_Min WITH(NOLOCK) on  AC_Min.AccountingCalendarId = RS.AccountingCalendarId_Min
					inner join AccountingCalendar as AC_Max WITH(NOLOCK) on  AC_Max.AccountingCalendarId = RS.AccountingCalendarId_Max
					inner join LegalEntity as LE WITH(NOLOCK) on  LE.LegalEntityId = RS.LegalEntityId
					WHERE AC_Max.IsDeleted = 0 AND AC_Max.IsActive = 1 and AC_Max.ledgerId=@ledgerId and AC_Max.LegalEntityId=@LegalEntityId and AC_Max.FiscalYear=@FiscalYear
					),
					ResultCount AS(SELECT COUNT(AccountingCalendarId) AS totalItems FROM FinalResult)
					SELECT * INTO #TempResult from  FinalResult  

					SELECT *, @Count As NumberOfItems FROM #TempResult
					ORDER BY  	
					 1  Desc

					
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH 

		IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AccountingCalendarList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '+ ISNULL(@ledgerId, '') + ', 
													   @Parameter2 = ' + ISNULL(@LegalEntityId,'') + ', 
													   @Parameter3 = ' + ISNULL(@FiscalYear,'') + '' 
												
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH  
END