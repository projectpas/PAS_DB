/*************************************************************                 
 ** File:   [USP_GetIntegrationEmailList]                 
 ** Author:   Moin Bloch
 ** Description: Get Stockline As of Now Job List
 ** Purpose:               
 ** Date:    10/09/2025     
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change	Description                  
 ** --   --------     -------  ------	--------------------------                
    1    10/09/2025   Moin Bloch   	    Created      

-- EXEC USP_GetStocklineAsofNowJobList 
**************************************************************/                   
CREATE   PROCEDURE [dbo].[USP_GetStocklineAsofNowJobList]
@PageSize INT,        
@PageNumber INT,        
@SortColumn VARCHAR(50) = NULL,   
@SortOrder INT = NULL,  
@GlobalFilter VARCHAR(50) = NULL,        
@FileName NVARCHAR(100) = NULL, 
@TotalInventory VARCHAR(50) = NULL,
@JobDate DATETIME = NULL,
@NextRunDate DATETIME = NULL,
@CreatedDate DATETIME = NULL,
@MasterCompanyId INT = NULL, 
@ReportType INT = NULL,
@EmployeeId BIGINT = NULL,      
@IsDeleted BIT = NULL      
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      
             
	DECLARE @RecordFrom INT;       
	DECLARE @IsActive BIT = 1        
	DECLARE @Count INT;  
	DECLARE @HeadersIdValue VARCHAR(MAX);
		
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
	FROM [dbo].[Employee] E WITH (NOLOCK) 
	LEFT JOIN [dbo].[TimeZone] ETZ WITH (NOLOCK) ON E.[TimeZoneId] = ETZ.[TimeZoneId]
	LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON E.[LegalEntityId] = LE.[LegalEntityId]
	LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK) ON LE.[TimeZoneId] = LTZ.[TimeZoneId]
	WHERE E.[EmployeeId] = @EmployeeId;

	SET @RecordFrom = (@PageNumber - 1) * @PageSize;      
	   
	IF(@GlobalFilter IS NULL)      
	BEGIN      
		SET @GlobalFilter='';      
	END      
	   
	IF @SortColumn IS NULL        
	BEGIN        
		SET @SortColumn = 'STOCKLINEASOFNOWJOBID'        
	END         
	ELSE        
	BEGIN         
		SET @SortColumn = UPPER(@SortColumn)        
	END    	

	SELECT COUNT(1) OVER () AS [NumberOfItems]	  
		  ,IE.[StocklineAsofNowJobId]	
		  ,IE.[Name] [FileName]
		  ,IE.[Path]	
		  ,IE.[JobDate]	
		  ,IE.[NextRunDate]
		  ,IE.[MasterCompanyId]	
		  ,ISNULL(IE.[TotalInventory],0) [TotalInventory]
		  ,(CAST(DBO.ConvertUTCtoLocal(IE.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) [CreatedDate]		  
  FROM [dbo].[StocklineAsofNowJobDetails] IE WITH(NOLOCK)	    
   WHERE (IE.MasterCompanyId = @MasterCompanyId) AND (IE.[ReportType] = @ReportType)	
    AND ((@GlobalFilter <>'' 
	AND ((IE.[Name] LIKE '%' + @GlobalFilter+'%') OR 
	     (CAST([TotalInventory] AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%') 	
	)) OR           
	(@GlobalFilter='' AND 	
	(ISNULL(@FileName,'') ='' OR [Name] LIKE '%' + @FileName +'%') AND
	(@JobDate IS NULL OR CAST([JobDate] AS DATE) = CAST(@JobDate AS DATE)) AND    
	(@NextRunDate IS NULL OR CAST([NextRunDate] AS DATE) = CAST(@NextRunDate AS DATE)) AND    
	(@CreatedDate IS NULL OR CAST([CreatedDate] AS DATE) = CAST(@CreatedDate AS DATE)) AND 	
	(ISNULL(@TotalInventory, '') = '' OR CAST([TotalInventory] AS VARCHAR(50)) LIKE '%' + @TotalInventory + '%') 	
	))   
	ORDER BY          
	CASE WHEN (@SortOrder=1  AND @SortColumn='STOCKLINEASOFNOWJOBID') THEN [StocklineAsofNowJobId] END ASC,        
	CASE WHEN (@SortOrder=1  AND @SortColumn='NAME')  THEN [Name] END ASC,   
	CASE WHEN (@SortOrder=1  AND @SortColumn='JOBDATE')  THEN [JobDate] END ASC,	
	CASE WHEN (@SortOrder=1  AND @SortColumn='NEXTRUNDATE')  THEN [NextRunDate] END ASC,	
	CASE WHEN (@SortOrder=1  AND @SortColumn='CREATEDDATE')  THEN IE.[CreatedDate] END ASC,	
	CASE WHEN (@SortOrder=1  AND @SortColumn='TOTALINVENTORY')  THEN [TotalInventory] END ASC,	

	CASE WHEN (@SortOrder=-1 AND @SortColumn='STOCKLINEASOFNOWJOBID') THEN [StocklineAsofNowJobId] END DESC, 
	CASE WHEN (@SortOrder=-1 AND @SortColumn='NAME')  THEN [Name] END DESC,   
	CASE WHEN (@SortOrder=-1 AND @SortColumn='JOBDATE')  THEN [JobDate] END DESC,	
	CASE WHEN (@SortOrder=-1 AND @SortColumn='NEXTRUNDATE')  THEN [NextRunDate] END DESC,	
	CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN IE.[CreatedDate] END DESC,
	CASE WHEN (@SortOrder=-1  AND @SortColumn='TOTALINVENTORY')  THEN [TotalInventory] END DESC	
	OFFSET @RecordFrom ROWS         
	FETCH NEXT @PageSize ROWS ONLY   
	    
      
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_GetIntegrationEmailList'       
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))      
      + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))       
      + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))      
      + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))      
      + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))     
     + '@Parameter16 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))      
     + '@Parameter17 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100))       
     + '@Parameter18 = ''' + CAST(ISNULL(@IsDeleted  , '') AS varchar(100))                
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