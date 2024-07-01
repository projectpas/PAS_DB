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
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    05/03/2022   Vishal Suthar    Added Legal Entity  
    2    30/08/2022   subhash saliya   Changes ledger id  
	3    01/07/2024   Moin Bloch       Fix Legalentity Filter Issue
       
**************************************************************/  
CREATE    PROCEDURE [dbo].[USP_AccountingCalendarList]  
@PageSize INT=10,  
@PageNumber INT = NULL,   
@SortColumn VARCHAR(50) = NULL,  
@SortOrder INT = NULL,  
@StatusID INT = 0,  
@GlobalFilter VARCHAR(50) = '',  
@Name VARCHAR(50) = '',  
@LegalEntity VARCHAR(50) = '',  
@Description VARCHAR(100) = '',  
@FiscalYear INT=NULL,  
@Period  INT=NULL,  
@PeriodName VARCHAR(50) = '',  
@FromDate DATETIME= NULL,  
@ToDate DATETIME=NULL,  
@MasterCompanyId INT = NULL 
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
   SET @SortColumn = UPPER('CreatedDate')  
  END   
  ELSE  
  BEGIN   
   SET @SortColumn = UPPER(@SortColumn)  
  END  
  IF(@SortColumn = 'LEGALENTITYNAME')
  BEGIN   
   SET @SortColumn = UPPER('LEGALENTITY')  
  END 
  
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
     ;With Result AS(  
       SELECT MAX([Name]) as [Name],
	          FiscalYear,
			  MIN(AccountingCalendarId) AS AccountingCalendarId_Min,  
              MAX(AccountingCalendarId) AS AccountingCalendarId_Max, 
			  LegalEntityId, 
			  MAX(ledgerId) AS ledgerId,
			  MAX([Description]) AS Descriptionmax,  
              MAX(StartDate) AS StartDate,
			  MAX(EndDate) AS EndDate,
			  IsCalendarMethod AS IsCalendarMethod
       from dbo.AccountingCalendar WITH(NOLOCK)  
       WHERE IsDeleted =0 AND IsActive=1 AND MasterCompanyId=@MasterCompanyId  
       GROUP BY FiscalYear, LegalEntityId,IsCalendarMethod  
     ), FinalResult AS(  
     SELECT RS.AccountingCalendarId_Max AccountingCalendarId, 
	        RS.[Name], 
			RS.Descriptionmax AS [Description], 
			AC_Max.FiscalName,RS.FiscalYear,  
            AC_Max.Quater, 
			AC_Max.[Period],
			RS.StartDate AS FromDate,
			RS.EndDate AS ToDate,
			AC_Max.PeriodName, 
			AC_Max.Notes, 
			AC_Max.MasterCompanyId,
			AC_Max.CreatedBy,
			AC_Max.UpdatedBy,  
			AC_Max.CreatedDate, 
			AC_Max.UpdatedDate, 
			AC_Max.IsActive, 
			AC_Max.IsDeleted, 
			AC_Max.[Status], 
			AC_Max.LegalEntityId,
			AC_Max.isUpdate,
	 		AC_Max.IsAdjustPeriod,  
            APR.[Name] AS NoOfPeriods,
			AC_Max.NoOfPeriods AS NoOfPeriodid ,
			AC_Max.PeriodType, 
			AC_Max.ledgerId, 
			LE.[Name] LegalEntity,  
           (SELECT * FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE  IsDeleted =0 AND IsActive=1 and LegalEntityId=RS.LegalEntityId AND FiscalYear = RS.FiscalYear order by AccountingCalendar.Period asc for JSON PATH) as calendarListData,
	 RS.IsCalendarMethod
     FROM Result RS WITH(NOLOCK)  
     INNER JOIN dbo.AccountingCalendar AS AC_Min WITH(NOLOCK) ON  AC_Min.AccountingCalendarId = RS.AccountingCalendarId_Min  
     INNER JOIN dbo.AccountingCalendar AS AC_Max WITH(NOLOCK) ON  AC_Max.AccountingCalendarId = RS.AccountingCalendarId_Max  
     INNER JOIN dbo.LegalEntity AS LE WITH(NOLOCK) ON  LE.LegalEntityId = RS.LegalEntityId  
     INNER JOIN dbo.AccountingPeriodStatus AS APR WITH(NOLOCK) ON  APR.Id = AC_Max.NoOfPeriods  
     WHERE AC_Max.IsDeleted = 0 AND AC_Max.IsActive = 1 AND AC_Max.MasterCompanyId = @MasterCompanyId  
     ),  
     ResultCount AS(SELECT COUNT(AccountingCalendarId) AS totalItems FROM FinalResult)  
     SELECT * INTO #TempResult FROM  FinalResult  
     WHERE (  
      (@GlobalFilter <> '' AND (  
      ([Name] LIKE '%' +@GlobalFilter+'%') OR  
      ([Description] LIKE '%' +@GlobalFilter+'%') OR  
      (CAST (FiscalYear AS VARCHAR) LIKE '%' +@GlobalFilter+'%') OR  
      (CAST([Period] AS VARCHAR) LIKE '%' +@GlobalFilter+'%') OR  
      (PeriodName LIKE '%' +@GlobalFilter+'%') OR  
      (FromDate LIKE '%' +@GlobalFilter+'%') OR  
      (ToDate LIKE '%' +@GlobalFilter+'%') OR   
	  (LegalEntity LIKE '%' +@GlobalFilter+'%')  
      ))  
      OR  
      (@GlobalFilter='' AND  
      (ISNULL(@Name,'') ='' OR [Name] LIKE '%' + @Name+'%') AND  
	  (ISNULL(@LegalEntity,'') ='' OR LegalEntity LIKE '%' + @LegalEntity+'%') AND  
      (ISNULL(@Description,'') ='' OR [Description] LIKE '%' + @Description+'%') AND  
      (ISNULL(@FiscalYear,'') ='' OR CAST (FiscalYear AS VARCHAR) LIKE '%' + CAST(@FiscalYear AS VARCHAR)+'%') AND  
      (ISNULL(@Period,'') ='' OR CAST([Period] AS VARCHAR) LIKE '%' + CAST(@Period AS VARCHAR) +'%') AND  
      (ISNULL(@PeriodName,'') ='' OR PeriodName LIKE '%' + @PeriodName+'%') AND  
      (ISNULL(@FromDate,'') ='' OR CAST(FromDate AS DATE) = CAST(@FromDate AS DATE)) AND  
      (ISNULL(@ToDate,'') ='' OR CAST(ToDate AS DATE) = CAST(@ToDate AS DATE))   
      ))  
      SELECT @Count = COUNT(AccountingCalendarId) FROM #TempResult     
  
     SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY     
     CASE WHEN (@SortOrder=1 AND @SortColumn='name')  THEN [Name] END ASC, 
	 CASE WHEN (@SortOrder=1 AND @SortColumn='LegalEntity')  THEN LegalEntity END ASC, 
     CASE WHEN (@SortOrder=1 AND @SortColumn='Description')  THEN [Description] END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='FiscalYear')  THEN FiscalYear END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='Period')  THEN [Period] END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='PeriodName')  THEN PeriodName END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='startDate')  THEN FromDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='endDate')  THEN ToDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,  
  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='name')  THEN [Name] END DESC,  
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='LegalEntity')  THEN LegalEntity END DESC, 
     CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='FiscalYear')  THEN FiscalYear END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='Period')  THEN [Period] END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='PeriodName')  THEN PeriodName END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='startDate')  THEN FromDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='endDate')  THEN ToDate END DESC  
  
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
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName   =  @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
        END CATCH    
END