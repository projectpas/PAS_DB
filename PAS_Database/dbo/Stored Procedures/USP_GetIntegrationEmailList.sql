/*************************************************************                 
 ** File:   [USP_GetIntegrationEmailList]                 
 ** Author:   Moin Bloch
 ** Description: Get Integration Email List         
 ** Purpose:               
 ** Date:    29/07/2025        
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change	Description                  
 ** --   --------     -------  ------	--------------------------                
    1    29/07/2025   Moin Bloch   	    Created      
	2    11/08/2025   Moin Bloch   	    Added IsRead,EmailPath,Subject 
	3    12/08/2025   Moin Bloch   	    Added Subject 

-- EXEC USP_GetIntegrationEmailList 10,1,'',-1,'','','',1,1,2,0 
**************************************************************/                   
CREATE   PROCEDURE [dbo].[USP_GetIntegrationEmailList]
@PageSize INT,        
@PageNumber INT,        
@SortColumn VARCHAR(50) = NULL,   
@SortOrder INT = NULL,  
@GlobalFilter VARCHAR(50) = NULL,        
@Subject VARCHAR(500) = NULL,
@EmailBody NVARCHAR(MAX) = NULL, 
@EmailSection INT = NULL,   
@EmailReadBy NVARCHAR(640) = NULL, 
@MasterCompanyId INT = NULL,  
@EmployeeId BIGINT,      
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
		SET @SortColumn = 'IntegrationEmailID'        
	End         
	ELSE        
	BEGIN         
		SET @SortColumn = UPPER(@SortColumn)        
	END    
	
	IF @EmailReadBy = '' OR @EmailReadBy = 'All'
	BEGIN         
		SET @EmailReadBy = NULL
	END  

	
	SELECT COUNT(1) OVER () AS [NumberOfItems]
		  ,IE.[IntegrationEmailID]
		  ,IE.[Subject]
		  ,IE.[EmailBody]
		  ,IE.[ToEmail]
		  ,IE.[FromEmail]
		  ,IE.[CC]
		  ,IE.[BCC]
		  ,IE.[EmailReadBy]
		  ,IE.[ReferenceId]
		  ,IE.[ModuleId]
		  ,IE.[EmailStatus]
		  ,IE.[HasAttachments]
		  ,IE.[EmailSection]
		  ,IE.[MasterCompanyId]
		  ,IE.[CreatedBy]
		  ,IE.[UpdatedBy]		  
		  ,(CAST(DBO.ConvertUTCtoLocal(IE.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) [CreatedDate]
		  ,IE.[UpdatedDate]
		  ,IE.[IsActive]
		  ,IE.[IsDeleted]	
		  ,ISNULL(IE.[IsRead],0) [IsRead]
		  ,IE.[EmailPath]
		  ,CR.[RfqId]
  FROM [dbo].[IntegrationEmail] IE WITH(NOLOCK)	    
  LEFT JOIN [dbo].[CustomerRfq] CR WITH(NOLOCK) ON IE.[CustomerRfqId] = CR.[CustomerRfqId]
  WHERE ((IE.MasterCompanyId = @MasterCompanyId) 
    AND (IE.IsDeleted = 0) 	
	AND (IE.[IsActive] = 1)
	AND (@EmailReadBy IS NULL OR IE.[EmailReadBy]=@EmailReadBy)   
    AND (IE.[EmailSection] = @EmailSection)) 				     
	AND ((@GlobalFilter <>'' 
	AND ((IE.[FromEmail] LIKE '%' + @GlobalFilter+'%') OR        
	     (IE.[Subject] LIKE '%' + @GlobalFilter+'%') OR   
		 (CR.[RfqId] LIKE '%' + @GlobalFilter+'%') OR   
		 (IE.[EmailBody] LIKE '%' +@GlobalFilter+'%'))) OR           
	(@GlobalFilter='' AND 	
	(ISNULL(@Subject,'') ='' OR [FromEmail] LIKE '%' + @Subject +'%') AND  
	(ISNULL(@EmailBody,'') ='' OR [EmailBody] LIKE '%' + @EmailBody +'%')))         				
	ORDER BY          
	CASE WHEN (@SortOrder=1 AND @SortColumn='IntegrationEmailID') THEN [IntegrationEmailID] END ASC,        
	CASE WHEN (@SortOrder=1 AND @SortColumn='FromEmail')  THEN [FromEmail] END ASC,   
	CASE WHEN (@SortOrder=1 AND @SortColumn='Subject')  THEN [Subject] END ASC,   
	CASE WHEN (@SortOrder=1 AND @SortColumn='EmailBody')  THEN [EmailBody] END ASC,   
	CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN IE.[CreatedDate] END ASC,
	CASE WHEN (@SortOrder=1  AND @SortColumn='RfqId') THEN [RfqId] END ASC,
	CASE WHEN (@SortOrder=-1 AND @SortColumn='IntegrationEmailID') THEN [IntegrationEmailID] END DESC, 
	CASE WHEN (@SortOrder=-1 AND @SortColumn='FromEmail')  THEN [FromEmail] END DESC,   
	CASE WHEN (@SortOrder=-1 AND @SortColumn='Subject')  THEN [Subject] END DESC,        
	CASE WHEN (@SortOrder=-1 AND @SortColumn='EmailBody')  THEN [EmailBody] END DESC,
	CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN IE.[CreatedDate] END DESC,	
	CASE WHEN (@SortOrder=-1 AND @SortColumn='RfqId')  THEN [RfqId] END DESC	

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