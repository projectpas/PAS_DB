/*********************           
 ** File:   [USP_GetYearEndCloseList]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to get Year End Close List List
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:          

 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/12/2023   Hemant Saliya	 Created Procedure
	2    09/25/2023   Hemant Saliya	 Added Version Numver in List
	3    09/26/2023   Bhargav Saliya  Add One Field [BatchHeaderId]
	4    06/28/2024   Sahdev Saliya  Added Global Filters and Sorting (Revenue, Expenses, NetEarning, NetRevenue)

EXEC USP_GetYearEndCloseList @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=1,@GlobalFilter=N'',@Year=0,@VersionNumber=NULL,@LegalEntity=NULL,@Memo=NULL,@ExecuteDate=NULL,@YearEndDate=NULL,
@CreatedDate=NULL,@UpdatedDate=NULL,@CreatedBy=NULL,@UpdatedBy=NULL,@IsDeleted=0,@MasterCompanyId=1,@EmployeeId=2     
**********************/
CREATE   PROCEDURE [dbo].[USP_GetYearEndCloseList]
 -- Add the parameters for the stored procedure here  
	 @PageSize INT,  
	 @PageNumber INT, 
	 @SortColumn VARCHAR(50) = NULL,  
	 @SortOrder INT,  
	 @GlobalFilter VARCHAR(50) = '',  	
	 @Year VARCHAR(50) = NULL,  
	 @VersionNumber VARCHAR(50) = NULL,
	 @LegalEntity VARCHAR(100) = NULL,  
	 @Memo VARCHAR(100) = NULL,  
	 @ExecuteDate DATETIME = NULL,  
	 @YearEndDate DATETIME = NULL,  
	 @CreatedDate DATETIME = NULL,  
	 @UpdatedDate DATETIME = NULL,  
	 @CreatedBy VARCHAR(50) = NULL,  
	 @UpdatedBy VARCHAR(50) = NULL,  
	 @IsDeleted BIT = null, 
	 @MasterCompanyId VARCHAR(200) = NULL,  
	 @Revenue VARCHAR(50) = NULL,  
	 @Expenses VARCHAR(50) = NULL,
	 @NetEarning VARCHAR(50) = NULL,  
	 @NetRevenue VARCHAR(50) = NULL ,
	 @EmployeeId VARCHAR(200) = NULL	
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
    DECLARE @RecordFrom int;  
    DECLARE @IsActive bit=1  
    DECLARE @Count Int;  
    DECLARE @WorkOrderStatusId int;    
  
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
		DROP TABLE #TempResult   
    END  
  
    SET @RecordFrom = (@PageNumber-1)*@PageSize;  
    IF @IsDeleted is null  
    BEGIN  
		SET @IsDeleted = 0;
    END    
  
    IF (@GlobalFilter IS NULL OR @GlobalFilter = '')  
    BEGIN  
		SET @GlobalFilter= '';
    END   
  
    IF @SortColumn IS NULL
    BEGIN  
		SET @SortColumn = Upper('ExecuteDate')
		SET @SortOrder = -1
    END
    ELSE
    BEGIN   
		SET @SortColumn=Upper(@SortColumn)  
    END  
  
	DECLARE @EmpLegalEntiyId BIGINT = 0;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

	SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
	SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
	WHERE LE.LegalEntityId = @EmpLegalEntiyId;

	;WITH Result AS(  
       SELECT	
			[YearEndCloseProcessId], 
			[Year],	
			[VersionNumber],	
			[LegalEntity],
			[YearEndDate],
			CAST([Revenue] AS VARCHAR) AS [Revenue],
			CAST([Expenses] AS VARCHAR) AS [Expenses],
			CAST([NetEarning] AS VARCHAR) AS [NetEarning],
			[PreviousYearRevenue],
			CAST([NetRevenue] AS VARCHAR) AS [NetRevenue],
			UPPER ([Memo]) AS [Memo],
			[StartPeriodId],
			[EndPeriodId],
			[ExecuteDate],
			[MasterCompanyId],
			[CreatedBy],[UpdatedBy],
			[CreatedDate],[UpdatedDate],
			[IsActive],[IsDeleted]
       FROM dbo.YearEndCloseProcess WO WITH(NOLOCK)  
       WHERE ((WO.MasterCompanyId = @MasterCompanyId) AND (WO.IsDeleted = @IsDeleted) AND (@IsActive IS NULL OR WO.IsActive = @IsActive))  
        ), ResultCount AS(Select COUNT(YearEndCloseProcessId) AS totalItems FROM Result)  
        SELECT * INTO #TempResult from  Result  
        WHERE (  
        (@GlobalFilter <>'' AND (  
        ([Year] like '%' +@GlobalFilter+'%') OR  
		([VersionNumber] like '%' +@GlobalFilter+'%') OR  
		([LegalEntity] like '%' +@GlobalFilter+'%') OR  
	    ([Memo] like '%' +@GlobalFilter+'%') OR  
        (CreatedBy like '%' +@GlobalFilter+'%') OR  
        (Revenue like '%' +@GlobalFilter+'%') OR  
        (Expenses like '%' +@GlobalFilter+'%') OR  
        (NetEarning like '%' +@GlobalFilter+'%') OR  
        (NetRevenue like '%' +@GlobalFilter+'%') OR  
        (UpdatedBy like '%' +@GlobalFilter+'%')  
        ))  
        OR     
        (@GlobalFilter='' AND (IsNull(@Year,'') ='' OR [Year] like '%' + @Year+'%') AND  
		(IsNull(@LegalEntity,'') ='' OR LegalEntity like '%' + @LegalEntity+'%') AND  
		(IsNull(@VersionNumber,'') ='' OR VersionNumber like '%' + @VersionNumber+'%') AND  
		(IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%') AND  
        (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
        (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND
		(IsNull(@Revenue,'') ='' OR Revenue like '%' + @Revenue+'%') AND  
		(IsNull(@Expenses,'') ='' OR Expenses like '%' + @Expenses+'%') AND  
		(IsNull(@NetEarning,'') ='' OR NetEarning like '%' + @NetEarning+'%') AND  
        (IsNull(@NetRevenue,'') ='' OR NetRevenue like '%' + @NetRevenue+'%') AND  
        (IsNull(@ExecuteDate,'') ='' OR Cast(DBO.ConvertUTCtoLocal([ExecuteDate], @CurrntEmpTimeZoneDesc) as Date) = Cast(@ExecuteDate as date)) AND  
		(IsNull(@YearEndDate,'') ='' OR Cast(DBO.ConvertUTCtoLocal([YearEndDate], @CurrntEmpTimeZoneDesc) as Date) = Cast(@YearEndDate as date)) AND  
        (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
        (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date))  
        ))  
  
        SELECT @Count = COUNT(YearEndCloseProcessId) from #TempResult     
  
        SELECT *, @Count As NumberOfItems FROM #TempResult  
        ORDER BY    
        CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='EXECUTEDATE')  THEN ExecuteDate END ASC,  
		CASE WHEN (@SortOrder=1 AND @SortColumn='YEARENDDATE')  THEN YearEndDate END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
        CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
		CASE WHEN (@SortOrder=1 AND @SortColumn='YEAR')  THEN [Year] END ASC,  
		CASE WHEN (@SortOrder=1 AND @SortColumn='VERSIONNUMBER')  THEN [VersionNumber] END ASC,  
		CASE WHEN (@SortOrder=1 AND @SortColumn='LEGALENTITY')  THEN [LegalEntity] END ASC,  
		CASE WHEN (@SortOrder=1 AND @SortColumn='MEMO')  THEN [Memo] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='REVENUE')  THEN [Revenue] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='EXPENSES')  THEN [Expenses] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='NETEARNING')  THEN [NetEarning] END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='NETREVENUE')  THEN [NetRevenue] END ASC,
  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
	    CASE WHEN (@SortOrder=-1 AND @SortColumn='EXECUTEDATE')  THEN ExecuteDate END DESC,  
		CASE WHEN (@SortOrder=-1 AND @SortColumn='YEARENDDATE')  THEN YearEndDate END ASC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
        CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='YEAR')  THEN [Year] END DESC, 
		CASE WHEN (@SortOrder=-1 AND @SortColumn='VERSIONNUMBER')  THEN [VersionNumber] END DESC,  
		CASE WHEN (@SortOrder=-1 AND @SortColumn='LEGALENTITY')  THEN [LegalEntity] END DESC,  
		CASE WHEN (@SortOrder=-1 AND @SortColumn='MEMO')  THEN [Memo] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='REVENUE')  THEN [Revenue] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='EXPENSES')  THEN [Expenses] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='NETEARNING')  THEN [NetEarning] END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='NETREVENUE')  THEN [NetRevenue] END DESC
  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY  
  
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
    DROP TABLE #TempResult   
    END  
  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetYearEndCloseList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''',  
                @Parameter2 = ' + ISNULL(@PageSize,'') + ',   
                @Parameter3 = ' + ISNULL(@SortColumn,'') + ',   
                @Parameter4 = ' + ISNULL(@SortOrder,'') + ',   
                @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ',   
                @Parameter20 = ' + ISNULL(CAST(@ExecuteDate AS VARCHAR(50)) ,'') + ',   
                @Parameter21 = ' + ISNULL(CAST(@CreatedDate AS VARCHAR(50)) ,'') + ',   
                @Parameter22 = ' + ISNULL(CAST(@UpdatedDate AS VARCHAR(50)) ,'') + ',   
                @Parameter23 = ' + ISNULL(@CreatedBy,'') + ',   
                @Parameter24 = ' + ISNULL(@UpdatedBy,'') + ',   
                @Parameter25 = ' + ISNULL(CAST(@IsDeleted AS VARCHAR(50)) ,'') + ',   
                @Parameter26 = ' + ISNULL(@masterCompanyId,'') + ',   
                @Parameter27 = ' + ISNULL(@EmployeeId,'') + ''  
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