CREATE   PROCEDURE [dbo].[USP_GetExchangeRateList]  
(  
  @PageNumber int,      
  @PageSize int,      
  @SortColumn varchar(50)=null,      
  @SortOrder int,     
  @StatusId int,
  @GlobalFilter varchar(50) = null,   
  @FromCurrencyName varchar(50) = null,    
  @ToCurrencyName varchar(20) = null,  
  @ConversionRate varchar(20) = null,  
  @CurrencyRateDate varchar(50) = null,
  @CurrencyTypeName varchar(50) = null,
  @MasterCompanyId bigint = NULL,  
  @CreatedDate datetime=null,		
  @UpdatedDate  datetime=null,      
  @CreatedBy  varchar(50)=null,      
  @UpdatedBy  varchar(50)=null,
  @IsDeleted bit= null      
)  
AS  
BEGIN  
 SET NOCOUNT ON;      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED       
 BEGIN TRY  
  DECLARE @RecordFrom int;      
  DECLARE @IsActive bit=1      
  DECLARE @Count Int;      
  SET @RecordFrom = (@PageNumber-1)*@PageSize;      
  IF @SortColumn IS NULL      
  BEGIN      
   SET @SortColumn=UPPER('CreatedDate')      
  END       
  Else      
  BEGIN       
   SET @SortColumn=UPPER(@SortColumn)      
  END      
  
  IF @IsDeleted is null      
	Begin      
		Set @IsDeleted=0      
	End      
	
   IF(@StatusId=0)  
  BEGIN  
   SET @IsActive=0;  
  END  
  ELSE IF(@StatusId=1)  
  BEGIN  
   SET @IsActive=1;  
  END  
  ELSE  
  BEGIN  
   SET @IsActive=NULL;  
  END   

  ;WITH Result AS(  
   SELECT 
   ROW_NUMBER() OVER(PARTITION BY M.CurrencyTypeId,M.FromCurrencyId,M.ToCurrencyId ORDER BY M.CreatedDate DESC) RowNo,
   M.CurrencyConversionId,M.CurrencyTypeId,M.FromCurrencyId,CT.Name 'CurrencyTypeName',
   CURR.Code 'FromCurrencyName',M.ToCurrencyId,CURRE.Code 'ToCurrencyName',
   M.CurrencyRateDate,M.ConversionRate,M.MasterCompanyId, M.CreatedBy,M.UpdatedBy,
   M.CreatedDate,M.UpdatedDate,M.IsActive,M.IsDeleted
   FROM dbo.CurrencyConversion M WITH(NOLOCK)
   LEFT JOIN dbo.CurrencyType CT WITH(NOLOCK) ON M.CurrencyTypeId = CT.CurrencyTypeId
   LEFT JOIN dbo.Currency CURR WITH(NOLOCK) ON M.FromCurrencyId = CURR.CurrencyId
   LEFT JOIN dbo.Currency CURRE WITH(NOLOCK) ON M.ToCurrencyId = CURRE.CurrencyId
   WHERE ((M.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR M.IsActive = @IsActive)) AND M.MasterCompanyId = @MasterCompanyId  
  )  
   SELECT *,CASE WHEN RowNo = 1 THEN 1 ELSE 0 END AS IsDefault INTO #TempTableData FROM Result 
  SELECT * INTO #TempResult FROM #TempTableData  
  WHERE(  
   (@GlobalFilter <>'' AND (  
   (CurrencyTypeName LIKE '%' +@GlobalFilter+'%') OR      
   (FromCurrencyName LIKE '%' +@GlobalFilter+'%') OR      
   (ToCurrencyName LIKE '%' +@GlobalFilter+'%') OR      
   (ConversionRate LIKE '%' +@GlobalFilter+'%') OR      
   (CreatedBy LIKE '%' +@GlobalFilter+'%') OR      
   (UpdatedBy LIKE '%' +@GlobalFilter+'%')       
  )) OR  
  (@GlobalFilter='' AND   
   (ISNULL(@CurrencyTypeName,'') ='' OR CurrencyTypeName LIKE '%' + @CurrencyTypeName+'%') AND       
  (ISNULL(@FromCurrencyName,'') ='' OR FromCurrencyName LIKE '%' + @FromCurrencyName+'%') AND       
  (ISNULL(@ToCurrencyName,'') ='' OR ToCurrencyName LIKE '%' + @ToCurrencyName+'%') AND       
  (ISNULL(@CurrencyRateDate,'') ='' OR CAST(CurrencyRateDate as Date) = CAST(@CurrencyRateDate AS Date)) AND       
  (ISNULL(@ConversionRate,'') ='' OR CAST(ConversionRate AS varchar(50)) LIKE '%' + @ConversionRate+'%') AND       
  (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND      
  (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND      
  (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND      
  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))      
  )  
  
  Select @Count = COUNT(CurrencyConversionId) FROM #TempResult      
    
  SELECT *, @Count AS NumberOfItems FROM #TempResult      
  ORDER BY        
  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,      
  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,      
  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,      
  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,      
  CASE WHEN (@SortOrder=1 AND @SortColumn='FromCurrencyName')  THEN FromCurrencyName END ASC,  
  CASE WHEN (@SortOrder=1 AND @SortColumn='ToCurrencyName')  THEN ToCurrencyName END ASC,      
  CASE WHEN (@SortOrder=1 AND @SortColumn='CurrencyRateDate')  THEN CurrencyRateDate END ASC,      
  CASE WHEN (@SortOrder=1 AND @SortColumn='ConversionRate')  THEN ConversionRate END ASC, 
  CASE WHEN (@SortOrder=1 AND @SortColumn='CurrencyTypeName')  THEN CurrencyTypeName END ASC, 
    
      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='FromCurrencyName')  THEN FromCurrencyName END DESC,  
  CASE WHEN (@SortOrder=-1 AND @SortColumn='ToCurrencyName')  THEN ToCurrencyName END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CurrencyRateDate')  THEN CurrencyRateDate END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='ConversionRate')  THEN ConversionRate END DESC,
   CASE WHEN (@SortOrder=-1 AND @SortColumn='CurrencyTypeName')  THEN CurrencyTypeName END DESC
  
  OFFSET @RecordFrom ROWS       
  FETCH NEXT @PageSize ROWS ONLY      
  
 END TRY  
 BEGIN CATCH  
  DECLARE @ErrorLogID INT      
    ,@DatabaseName VARCHAR(100) = db_name()      
    -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
    ,@AdhocComments VARCHAR(150) = 'USP_GetExchangeRateList'      
    ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))      
    + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))       
    + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))      
    + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))      
    + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))      
    + '@Parameter7 = ''' + CAST(ISNULL(@FromCurrencyName, '') AS varchar(100))      
    + '@Parameter8 = ''' + CAST(ISNULL(@ToCurrencyName, '') AS varchar(100))      
   + '@Parameter9 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))      
   + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))      
   + '@Parameter11 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))      
   + '@Parameter12 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))      
   + '@Parameter13 = ''' + CAST(ISNULL(@CurrencyRateDate , '') AS varchar(100))      
   + '@Parameter14 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))    
  ,@ApplicationName VARCHAR(100) = 'PAS'      
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
    EXEC spLogException @DatabaseName = @DatabaseName      
  ,@AdhocComments = @AdhocComments      
  ,@ProcedureParameters = @ProcedureParameters      
  ,@ApplicationName = @ApplicationName      
  ,@ErrorLogID = @ErrorLogID OUTPUT;      
      
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)      
      
    RETURN (1);    
 END CATCH  
END