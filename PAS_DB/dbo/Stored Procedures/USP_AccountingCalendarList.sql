/*************************************************************           
 ** File:   [USP_AccountingCalendarList]           
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
    1    05/03/2022   Vishal Suthar Added Legal Entity
	2    30/08/2022   subhash saliya Changes ledger id
     
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_AccountingCalendarList]
@PageSize INT=10,
@PageNumber INT,
@SortColumn VARCHAR(50) = NULL,
@SortOrder INT,
@StatusID INT = 0,
@GlobalFilter VARCHAR(50) = '',
@Name VARCHAR(50) = '',
@Description	VARCHAR(100) = '',
@FiscalYear INT=NULL,
@Period		INT=NULL,
@PeriodName	VARCHAR(50) = '',
@FromDate DATETIME= NULL,
@ToDate	DATETIME=NULL,
@MasterCompanyId	INT

	AS
	BEGIN

		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		SET NOCOUNT ON;
			DECLARE @RecordFrom int;
		Declare @IsActive bit = 1
		Declare @Count Int;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
				
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			SET @SortColumn = Upper(@SortColumn)
		END

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					;With Result AS(
							SELECT Name,FiscalYear, min(AccountingCalendarId) as AccountingCalendarId_Min,
							max(AccountingCalendarId) as AccountingCalendarId_Max, LegalEntityId, ledgerId,max(Description) as Descriptionmax
							from AccountingCalendar WITH(NOLOCK)
							WHERE IsDeleted =0 AND IsActive=1 AND MasterCompanyId=@MasterCompanyId
							GROUP BY Name, FiscalYear, LegalEntityId, ledgerId
					), FinalResult AS(
					Select RS.AccountingCalendarId_Max AccountingCalendarId, RS.Name, RS.Descriptionmax as Description, AC_Max.FiscalName,RS.FiscalYear,
					AC_Max.Quater, AC_Max.Period, AC_Min.FromDate,AC_Max.ToDate, AC_Max.PeriodName, AC_Max.Notes, AC_Max.MasterCompanyId,AC_Max.CreatedBy,AC_Max.UpdatedBy,
					AC_Max.CreatedDate, AC_Max.UpdatedDate, AC_Max.IsActive, AC_Max.IsDeleted, AC_Max.Status, AC_Max.LegalEntityId,AC_Max.isUpdate,AC_Max.IsAdjustPeriod,
					AC_Max.NoOfPeriods, AC_Max.PeriodType, AC_Max.ledgerId, LE.Name LagalEntity,
					(select * from AccountingCalendar where  IsDeleted =0 AND IsActive=1 and Name=RS.Name AND FiscalYear = RS.FiscalYear for JSON PATH) as calendarListData
					from Result RS WITH(NOLOCK)
					inner join AccountingCalendar as AC_Min WITH(NOLOCK) on  AC_Min.AccountingCalendarId = RS.AccountingCalendarId_Min
					inner join AccountingCalendar as AC_Max WITH(NOLOCK) on  AC_Max.AccountingCalendarId = RS.AccountingCalendarId_Max
					inner join LegalEntity as LE WITH(NOLOCK) on  LE.LegalEntityId = RS.LegalEntityId
					WHERE AC_Max.IsDeleted = 0 AND AC_Max.IsActive = 1 AND AC_Max.MasterCompanyId = @MasterCompanyId
					),
					ResultCount AS(SELECT COUNT(AccountingCalendarId) AS totalItems FROM FinalResult)
					SELECT * INTO #TempResult from  FinalResult
					WHERE (
						(@GlobalFilter <> '' AND (
						(Name like '%' +@GlobalFilter+'%') OR
						(Description like '%' +@GlobalFilter+'%') OR
						(CAST (FiscalYear as varchar) like '%' +@GlobalFilter+'%') OR
						(CAST(Period as varchar) like '%' +@GlobalFilter+'%') OR
						(PeriodName like '%' +@GlobalFilter+'%') OR
						(FromDate like '%' +@GlobalFilter+'%') OR
						(ToDate like '%' +@GlobalFilter+'%') 
						))
						OR
						(@GlobalFilter='' AND
						(ISNULL(@Name,'') ='' OR Name like '%' + @Name+'%') AND
						(ISNULL(@Description,'') ='' OR Description like '%' + @Description+'%') AND
						(ISNULL(@FiscalYear,'') ='' OR CAST (FiscalYear as varchar) like '%' + CAST(@FiscalYear as varchar)+'%') AND
						(ISNULL(@Period,'') ='' OR CAST(Period as varchar) like '%' +CAST(@Period as varchar) +'%') AND
						(ISNULL(@PeriodName,'') ='' OR PeriodName like '%' + @PeriodName+'%') AND
						(ISNULL(@FromDate,'') ='' OR Cast(FromDate as Date)=Cast(@FromDate as date)) AND
						(ISNULL(@ToDate,'') ='' OR Cast(ToDate as Date)=Cast(@ToDate as date)) 
						))
						SELECT @Count = COUNT(AccountingCalendarId) from #TempResult			

					SELECT *, @Count As NumberOfItems FROM #TempResult
					ORDER BY  	
					CASE WHEN (@SortOrder=1 and @SortColumn='name')  THEN Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Description')  THEN Description END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='FiscalYear')  THEN FiscalYear END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Period')  THEN Period END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='PeriodName')  THEN PeriodName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='startDate')  THEN FromDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='endDate')  THEN ToDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='name')  THEN Name END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Description')  THEN Description END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='FiscalYear')  THEN FiscalYear END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Period')  THEN Period END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='PeriodName')  THEN PeriodName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='startDate')  THEN FromDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='endDate')  THEN ToDate END Desc

					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageSize, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageNumber,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@StatusID,'') + ', 
													   @Parameter6 = ' + ISNULL(@GlobalFilter,'') + ', 
													   @Parameter8 = ' + ISNULL(@Name,'') + ', 
													   @Parameter9 = ' + ISNULL(@Description,'') + ', 
													   @Parameter10 = ' + ISNULL(@FiscalYear,'') + ', 
													   @Parameter12 = ' + ISNULL(@Period,'') + ', 
													   @Parameter13 = ' + ISNULL(@PeriodName,'') + ', 
													   @Parameter14 = ' + ISNULL(@FromDate,'') + ',
													   @Parameter15 = ' + ISNULL(@ToDate,'') + ',
													   @Parameter16 = ' + ISNULL(@MasterCompanyId ,'') +''
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