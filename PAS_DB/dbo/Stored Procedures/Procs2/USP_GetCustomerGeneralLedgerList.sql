CREATE    PROCEDURE [DBO].[USP_GetCustomerGeneralLedgerList]  
(  
  @PageNumber int,      
  @PageSize int,      
  @SortColumn varchar(50)=null,      
  @SortOrder int,      
  @GlobalFilter varchar(50) = null,   
  @CustomerName varchar(50) = null,  
  @CustomerCode varchar(50) = null,  
  @Currency varchar(20) = null,  
  @CreditAmount varchar(20) = null,
  @DebitAmount varchar(20) = null,  
  @Amount varchar(20) = null,  
  @AccountingPeriod varchar(20) = null,  
  @MasterCompanyId bigint = NULL,  
  @CreatedDate datetime=null,      
  @UpdatedDate  datetime=null,      
  @UpdatedBy  varchar(50)=null  
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
  
  ;WITH Result AS(  
   SELECT   
    CL.CustomerId,C.Name 'CustomerName',SUM(ISNULL(CL.DebitAmount,0)) 'DebitAmount',SUM(ISNULL(CL.CreditAmount,0)) 'CreditAmount',
   SUM(ISNULL(CL.CreditAmount, 0)) - SUM(ISNULL(CL.DebitAmount,0)) 'Amount',B.UpdatedBy,B.UpdatedDate,B.CreatedDate,C.CustomerCode,
   CUR.Code 'Currency'
    FROM [dbo].CustomerGeneralLedger CL WITH(NOLOCK)
   LEFT JOIN [dbo].Customer C WITH(NOLOCK) ON CL.CustomerId = C.CustomerId
   LEFT JOIN [dbo].CustomerFinancial CF WITH(NOLOCK) ON C.CustomerId = CF.CustomerId
   LEFT JOIN [dbo].Currency CUR WITH(NOLOCK) ON CF.CurrencyId = CUR.CurrencyId
   OUTER APPLY(SELECT TOP 1 CL2.CustomerId,CL2.UpdatedBy,CL2.UpdatedDate,CL2.CreatedDate
   FROM [dbo].CustomerGeneralLedger CL2 WITH(NOLOCK)
   WHERE CL2.CustomerId = CL.CustomerId ORDER BY CL2.CustomerGeneralLedgerId DESC) B
   WHERE CL.MasterCompanyId = @MasterCompanyId  
   GROUP BY CL.CustomerId,C.Name,B.UpdatedBy,B.UpdatedDate,B.CreatedDate,C.CustomerCode,CUR.Code
  )  
  
  SELECT * INTO #TempResult FROM Result  
  WHERE(  
   (@GlobalFilter <>'' AND (  
   (CustomerName LIKE '%' +@GlobalFilter+'%') OR  
   (CustomerCode LIKE '%' +@GlobalFilter+'%') OR  
   (Currency LIKE '%' +@GlobalFilter+'%') OR  
   (CreditAmount LIKE '%' +@GlobalFilter+'%') OR      
   (DebitAmount LIKE '%' +@GlobalFilter+'%') OR      
   (Amount LIKE '%' +@GlobalFilter+'%') OR          
   (UpdatedBy LIKE '%' +@GlobalFilter+'%')       
  ))OR  
  (@GlobalFilter='' AND   
  (ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName+'%') AND        
  (ISNULL(@CustomerCode,'') ='' OR CustomerCode LIKE '%' + @CustomerCode+'%') AND        
  (ISNULL(@Currency,'') ='' OR Currency LIKE '%' + @Currency+'%') AND        
  (ISNULL(@CreditAmount,0) =0 OR CreditAmount LIKE '%' + @CreditAmount+'%') AND       
  (ISNULL(@DebitAmount,0) =0 OR DebitAmount LIKE '%' + @DebitAmount+'%') AND       
  (ISNULL(@Amount,0) =0 OR Amount LIKE '%' + @Amount+'%') AND       
  (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND      
  (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND      
  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))      
  )  
  
  Select @Count = COUNT(CustomerId) FROM #TempResult      
    
  SELECT *, @Count AS NumberOfItems FROM #TempResult      
  ORDER BY        
  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,      
  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,            
  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,      
  CASE WHEN (@SortOrder=1 AND @SortColumn='CustomerName')  THEN CustomerName END ASC,       
  CASE WHEN (@SortOrder=1 AND @SortColumn='CreditAmount')  THEN CreditAmount END ASC,  
  CASE WHEN (@SortOrder=1 AND @SortColumn='DebitAmount')  THEN DebitAmount END ASC,  
  CASE WHEN (@SortOrder=1 AND @SortColumn='Amount')  THEN Amount END ASC,  
  CASE WHEN (@SortOrder=1 AND @SortColumn='Currency')  THEN Currency END ASC,  
  CASE WHEN (@SortOrder=1 AND @SortColumn='CustomerCode')  THEN CustomerCode END ASC,  
      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,      
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,  
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreditAmount')  THEN CreditAmount END DESC,  
  CASE WHEN (@SortOrder=-1 AND @SortColumn='DebitAmount')  THEN DebitAmount END DESC,  
  CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount')  THEN Amount END DESC,  
  CASE WHEN (@SortOrder=-1 AND @SortColumn='Currency')  THEN Currency END DESC,  
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerCode')  THEN CustomerCode END DESC


  OFFSET @RecordFrom ROWS       
  FETCH NEXT @PageSize ROWS ONLY      
  
 END TRY  
 BEGIN CATCH  
  DECLARE @ErrorLogID INT      
    ,@DatabaseName VARCHAR(100) = db_name()      
    -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
    ,@AdhocComments VARCHAR(150) = 'USP_GetCustomerGeneralLedgerList'      
    ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))      
    + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))       
    + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))      
    + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))      
    + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))      
    + '@Parameter7 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100))      
    + '@Parameter8 = ''' + CAST(ISNULL(@CustomerCode, '') AS varchar(100))      
   + '@Parameter9 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))      
   + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))      
   + '@Parameter11 = ''' + CAST(ISNULL(@Currency  , '') AS varchar(100))      
   + '@Parameter12 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))      
   + '@Parameter13 = ''' + CAST(ISNULL(@CreditAmount , '') AS varchar(100))      
   + '@Parameter13 = ''' + CAST(ISNULL(@DebitAmount , '') AS varchar(100))      
   + '@Parameter13 = ''' + CAST(ISNULL(@Amount , '') AS varchar(100))      
   + '@Parameter13 = ''' + CAST(ISNULL(@AccountingPeriod, '') AS varchar(100))      
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