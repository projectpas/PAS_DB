﻿
CREATE    PROCEDURE [dbo].[Get_ShippingConfigureList]  
(  
  @PageNumber int,    
  @PageSize int,    
  @SortColumn varchar(50)=null,    
  @SortOrder int,    
  @StatusID int,    
  @GlobalFilter varchar(50) = null,    
  @Shipvia varchar(50)=null,    
  @ShippingAccountNumber varchar(50)=null,    
  @ApiKey varchar(100)=null,    
  @SecretKey varchar(100)=null,    
     @CreatedDate datetime=null,    
     @UpdatedDate  datetime=null,    
  @CreatedBy  varchar(50)=null,    
  @UpdatedBy  varchar(50)=null,    
  @IsDeleted bit= null,    
  @MasterCompanyId bigint = NULL,
  @IsAuthReq varchar(10) = NULL
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
    IF @IsDeleted IS NULL    
    BEGIN    
     SET @IsDeleted=0    
    END        
    IF @SortColumn IS NULL    
    BEGIN    
     SET @SortColumn=UPPER('CreatedDate')    
    END     
    Else    
    BEGIN     
     SET @SortColumn=UPPER(@SortColumn)    
    END    
    IF @StatusID=0    
    BEGIN     
     SET @IsActive=0    
    END     
    ELSE IF @StatusID=1    
    BEGIN     
     SET @IsActive=1    
    END     
    ELSE IF @StatusID=2    
    BEGIN     
     SET @IsActive=NULL    
    END    
  
    ;WITH Result AS(  
    SELECT   
    SC.ShippingConfigureId,S.NAME 'shippingvia',  
    SC.ShippingAccountNumber 'ShippingAccountNumber',
	CASE WHEN SC.IsAuthReq =1 THEN 'Yes' ELSE 'No' END 'IsAuthReq',
    SC.APIKey, SC.SecretKey,  
    SC.MasterCompanyId,  
    SC.CreatedBy,SC.CreatedDate,SC.UpdatedBy,  
    SC.UpdatedDate,SC.IsActive,SC.IsDeleted  
    FROM DBO.ShippingConfigure SC WITH(NOLOCK)  
    LEFT JOIN DBO.ShippingVia S WITH(NOLOCK) ON SC.ShippingViaId = S.ShippingViaId  
    Where ((SC.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR SC.IsActive=@IsActive))    
    AND SC.MasterCompanyId=@MasterCompanyId     
    ), ResultCount AS(SELECT COUNT(ShippingConfigureId) AS totalItems FROM Result)    
      
    SELECT * INTO #TempResult FROM  Result    
     WHERE (    
     (@GlobalFilter <>'' AND ((shippingvia LIKE '%' +@GlobalFilter+'%' ) OR   
    (APIKey LIKE '%' +@GlobalFilter+'%') OR 
	(IsAuthReq LIKE '%' +@GlobalFilter+'%') OR 
    (SecretKey LIKE '%' +@GlobalFilter+'%') OR    
    (ShippingAccountNumber LIKE '%' +@GlobalFilter+'%') OR    
    (CreatedBy LIKE '%' +@GlobalFilter+'%') OR    
    (UpdatedBy LIKE '%' +@GlobalFilter+'%')     
    ))    
    OR       
    (@GlobalFilter='' AND (ISNULL(@Shipvia,'') ='' OR shippingvia LIKE '%' + @Shipvia+'%') AND     
    (ISNULL(@ShippingAccountNumber,'') ='' OR ShippingAccountNumber LIKE '%' + @ShippingAccountNumber+'%') AND    
    (ISNULL(@ApiKey,'') ='' OR APIKey LIKE '%' + @ApiKey+'%') AND
	(ISNULL(@IsAuthReq,'') ='' OR IsAuthReq LIKE '%' + @IsAuthReq+'%') AND
    (ISNULL(@SecretKey,'') ='' OR SecretKey LIKE '%' + @SecretKey+'%') AND    
    (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND    
    (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND    
    (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND    
    (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))    
    )    
    
  
  Select @Count = COUNT(ShippingConfigureId) FROM #TempResult       
    
    SELECT *, @Count AS NumberOfItems FROM #TempResult    
    ORDER BY      
    CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,    
    CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,    
    CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,    
    CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,    
    CASE WHEN (@SortOrder=1 AND @SortColumn='shippingvia')  THEN shippingvia END ASC,
    CASE WHEN (@SortOrder=1 AND @SortColumn='ShippingAccountNumber')  THEN ShippingAccountNumber END ASC,    
    CASE WHEN (@SortOrder=1 AND @SortColumn='APIKey')  THEN APIKey END ASC,    
    CASE WHEN (@SortOrder=1 AND @SortColumn='SecretKey')  THEN SecretKey END ASC,  
    
    CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,    
    CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,    
    CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,    
    CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,    
    CASE WHEN (@SortOrder=-1 AND @SortColumn='shippingvia')  THEN shippingvia END DESC,	
    CASE WHEN (@SortOrder=-1 AND @SortColumn='ShippingAccountNumber')  THEN ShippingAccountNumber END DESC,    
    CASE WHEN (@SortOrder=-1 AND @SortColumn='APIKey')  THEN APIKey END DESC  ,  
    CASE WHEN (@SortOrder=-1 AND @SortColumn='SecretKey')  THEN SecretKey END DESC    
    OFFSET @RecordFrom ROWS     
    FETCH NEXT @PageSize ROWS ONLY    
  
  END TRY  
  BEGIN CATCH  
   DECLARE @ErrorLogID INT    
   ,@DatabaseName VARCHAR(100) = db_name()    
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
   ,@AdhocComments VARCHAR(150) = 'GetCustomerList'    
   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))    
      + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))     
      + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))    
      + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))    
      + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS varchar(100))    
      + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))    
      + '@Parameter7 = ''' + CAST(ISNULL(@Shipvia, '') AS varchar(100))    
      + '@Parameter8 = ''' + CAST(ISNULL(@ShippingAccountNumber, '') AS varchar(100))    
     + '@Parameter9 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))    
     + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))    
     + '@Parameter11 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))    
     + '@Parameter12 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))    
     + '@Parameter13 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))    
     + '@Parameter14 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))  
	 + '@Parameter15 = ''' + CAST(ISNULL(@IsAuthReq, '') AS varchar(100)) 
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