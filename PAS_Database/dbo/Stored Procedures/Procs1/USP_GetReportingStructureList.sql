/*************************************************************               
 ** File:   [USP_GetReportingStructureList]               
 ** Author:     
 ** Description: This stored procedure is used GetReportingStructureList    
 ** Purpose:             
 ** Date:          
              
 ** PARAMETERS:
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date				Author				Change Description                
 ** --   --------			-------				--------------------------------              
	1    ***********		Unknown				Created  
	2    11/10/2022			Devendra Shekh		added active/inactive filter, and isactive field to select  
	3    27 Nov 2023		BHARGAV SALIYA		UTC Date Changes
	4    06-March-2025		Divyesh Kathiriya	Update CreatedDate and UpdateDate based on Employee time zone 

************************************************************************/    
CREATE    PROCEDURE [dbo].[USP_GetReportingStructureList]    
(    
  @PageNumber int,        
  @PageSize int,        
  @SortColumn varchar(50)=null,        
  @SortOrder int,        
  @GlobalFilter varchar(50) = null,     
  @StatusId int = NULL,  
  @ReportName varchar(50) = null,    
  @ReportDescription varchar(50) = null,    
  @VersionNumber varchar(20) = null, 
  @EmployeeId varchar(200)=null,
  @MasterCompanyId bigint = NULL,    
  @CreatedDate datetime=null,        
  @UpdatedDate  datetime=null,        
  @CreatedBy  varchar(50)=null,        
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
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
		SELECT 
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],  -- Prefer Employee's TimeZone description if available
					LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
				)
			FROM 
				dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN 
				dbo.TimeZone ETZ WITH (NOLOCK) 
				ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN 
				dbo.LegalEntity LE WITH (NOLOCK) 
				ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN 
				dbo.TimeZone LTZ WITH (NOLOCK) 
				ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE 
				E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee 
    
 ;WITH Result AS(    
 SELECT     
 ReportingStructureId,ReportName,ReportDescription,IsVersionIncrease,    
 VersionNumber,MasterCompanyId,CreatedBy,UpdatedBy,
 CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
	CASE WHEN CAST(CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
 ELSE (CAST(CreatedDate AS DATETIME)) END CreatedDate,
 CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
	CASE WHEN CAST(UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
 ELSE (CAST(UpdatedDate AS DATETIME)) END UpdatedDate, 
 IsDefault,IsActive  
 FROM ReportingStructure WITH(NOLOCK)    
 WHERE MasterCompanyId = @MasterCompanyId AND (@IsActive IS NULL OR IsActive=@IsActive)  
 )    
    
 SELECT * INTO #TempResult FROM Result    
 WHERE(    
  (@GlobalFilter <>'' AND (    
  (ReportName LIKE '%' +@GlobalFilter+'%') OR        
  (ReportDescription LIKE '%' +@GlobalFilter+'%') OR        
  (VersionNumber LIKE '%' +@GlobalFilter+'%') OR        
  (CreatedBy LIKE '%' +@GlobalFilter+'%') OR        
  (UpdatedBy LIKE '%' +@GlobalFilter+'%')         
  )) OR    
  (@GlobalFilter='' AND     
  (ISNULL(@ReportName,'') ='' OR ReportName LIKE '%' + @ReportName+'%') AND         
  (ISNULL(@ReportDescription,'') ='' OR ReportDescription LIKE '%' + @ReportDescription+'%') AND         
  (ISNULL(@VersionNumber,'') ='' OR VersionNumber LIKE '%' + @VersionNumber+'%') AND         
  (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND        
  (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND        
  (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND        
  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))        
  )    
    
 Select @Count = COUNT(ReportingStructureId) FROM #TempResult        
      
 SELECT *, @Count AS NumberOfItems FROM #TempResult        
 ORDER BY          
  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='ReportName')  THEN ReportName END ASC,    
  CASE WHEN (@SortOrder=1 AND @SortColumn='ReportDescription')  THEN ReportDescription END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='VersionNumber')  THEN VersionNumber END ASC,      
    
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReportName')  THEN ReportName END DESC,    
  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReportDescription')  THEN ReportDescription END DESC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='VersionNumber')  THEN VersionNumber END DESC        
  OFFSET @RecordFrom ROWS         
  FETCH NEXT @PageSize ROWS ONLY        
    
 END TRY    
 BEGIN CATCH    
  DECLARE @ErrorLogID INT        
    ,@DatabaseName VARCHAR(100) = db_name()        
    -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
    ,@AdhocComments VARCHAR(150) = 'USP_GetReportingStructureList'        
    ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))        
    + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))         
    + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))        
    + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))        
    + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))        
    + '@Parameter7 = ''' + CAST(ISNULL(@ReportName, '') AS varchar(100))        
    + '@Parameter8 = ''' + CAST(ISNULL(@ReportDescription, '') AS varchar(100))        
   + '@Parameter9 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))        
   + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))        
   + '@Parameter11 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))        
   + '@Parameter12 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))        
   + '@Parameter13 = ''' + CAST(ISNULL(@VersionNumber , '') AS varchar(100))        
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