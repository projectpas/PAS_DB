/*************************************************************           
 ** File:   [USP_GetAccontingIntegrationDetailsList]           
 ** Author:    HEMANT SALIYA
 ** Description:  
 ** Purpose:         
 ** Date:   07-AUG-2024        
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------  
	1    08/06/2020   HEMANT SALIYA	     CREATED
	2    29/10/2024   Devendra Shekh	 Modified(added RedirectUrl,IntigrationStatus to select)
	3    11/11/2024   Devendra Shekh	 Modified(resolved column filter issue)
	4    12/11/2024   Devendra Shekh	 Modified(added LastSycDate to select)
	5    17/12/2024   Devendra Shekh	 Modified(added Changes for Credit Terms)
	6	 03/02/2025	  Devendra Shekh	 Modified (Using [AccountingModule] table for Accounting Modules)
	7	 17/02/2025	  Devendra Shekh	 Modified (added @IsDeleted param and using [DisplayTitle] for ModuleName)
	8	 20/02/2025	  Devendra Shekh	 Modified (reading missing Details for remaining modules)
	9	 05/03/2025	  Abhishek Jirawla   Modified to add the calculation columns in the table to optimize the SP


EXEC USP_GetAccontingIntegrationDetailsList @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@StatusID=1,@GlobalFilter=N'',@IntegrationWith=NULL,
@LastRun=NULL,@ModuleName=NULL,@MasterCompanyId=1,@LastSycDate=NULL,@IsDeleted=NULL

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAccontingIntegrationDetailsList]
	@PageNumber int,
	@PageSize int,
	@SortColumn VARCHAR(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter VARCHAR(50) = null,
	@IntegrationWith VARCHAR(50)=null,
	@LastRun datetime=null,
	@ModuleName VARCHAR(50)=null,
	@MasterCompanyId bigint = NULL,
	@LastSycDate datetime=null,
	@IntigrationStatus VARCHAR(50)=null,
	@ProgressPercent decimal(9,2) = NULL,
	@Interval int = NULL,
	@TotalCount int = NULL,
	@PendingSyncRecords int = NULL,
	@SyncRecords int = NULL,
	@IsDeleted bit = NUll
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT=1
		DECLARE @Count INT;
		DECLARE @IntegrationId INT;

		SET @RecordFrom = (@PageNumber-1) * @PageSize;
			
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
				ACI.AccountingIntegrationSettingsId, 
				ACI.IntegrationId,
				ACI.IntegrationWith,
				ACI.LastRun,
				ACI.Interval,
				ACI.ModuleId,
				ACI.[DisplayTitle] AS ModuleName,
				ACI.MasterCompanyId,	
				ACI.SyncRecords,
				ACI.PendingSyncRecords,
				ACI.TotalRecords AS TotalCount,
				ACI.CreatedDate,
				ACI.CreatedBy,
				ACI.UpdatedDate,
				ACI.UpdatedBy,
				ACI.IsActive,
				ACI.IsDeleted,
				ACS.RedirectUrl,
				'Connect' AS [IntigrationStatus],
				ACI.LastRun AS LastSycDate,
				ISNULL(ACI.AllowBulkSync, 0) AS AllowBulkSync
		FROM dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
				LEFT JOIN dbo.AccountingIntegrationSetup ACS WITH (NOLOCK) ON ACS.MasterCompanyId = ACI.MasterCompanyId AND ACS.IntegrationId = ACI.IntegrationId
		WHERE	ACI.MasterCompanyId = @MasterCompanyId --AND ( AND (@IsActive IS NULL OR ACI.IsActive = @IsActive))
				AND (@IsDeleted IS NULL OR @IsDeleted = ACI.IsDeleted)
		), ResultCount AS(SELECT COUNT(AccountingIntegrationSettingsId) AS totalItems FROM Result)
		SELECT * INTO #TempResult FROM  Result
		WHERE ((@GlobalFilter <>'' AND ((IntegrationWith LIKE '%' +@GlobalFilter+'%') OR
			    (LastRun LIKE '%' +@GlobalFilter+'%') OR	
				(Interval LIKE '%' +@GlobalFilter+'%') OR
				(ModuleName LIKE '%' +@GlobalFilter+'%') OR
				(SyncRecords LIKE '%' +@GlobalFilter+'%') OR
				(PendingSyncRecords LIKE '%' +@GlobalFilter+'%') OR
				(TotalCount LIKE '%' +@GlobalFilter+'%') OR
				(IntigrationStatus LIKE '%' +@GlobalFilter+'%'))) OR   
				(@GlobalFilter='' AND (ISNULL(@IntegrationWith,'') ='' OR IntegrationWith LIKE '%' + @IntegrationWith+'%') AND
				(ISNULL(@LastRun,'') ='' OR CAST(LastRun as Date)=CAST(@LastRun as date))AND
				(ISNULL(@ModuleName,'') ='' OR ModuleName LIKE '%' + @ModuleName + '%') AND	
				(ISNULL(@IntigrationStatus,'') ='' OR IntigrationStatus LIKE '%' + @IntigrationStatus + '%') AND
				(ISNULL(@SyncRecords,'') ='' OR CAST(SyncRecords AS VARCHAR) LIKE '%' + CAST(@SyncRecords AS VARCHAR) + '%') AND	
				(ISNULL(@PendingSyncRecords,'') ='' OR CAST(PendingSyncRecords AS VARCHAR) LIKE '%' + CAST(@PendingSyncRecords AS VARCHAR) + '%') AND	
				(ISNULL(@TotalCount,'') ='' OR CAST(TotalCount AS VARCHAR) LIKE '%' + CAST(@TotalCount AS VARCHAR) + '%') AND
				(ISNULL(@LastSycDate,'') ='' OR CAST(LastSycDate as Date)=CAST(@LastSycDate as date))AND
				(ISNULL(@Interval,'') ='' OR CAST(Interval as VARCHAR)=CAST(@Interval as VARCHAR))))

		Select @Count = COUNT(AccountingIntegrationSettingsId) FROM #TempResult			

		SELECT	* ,CASE WHEN ISNULL(TotalCount, 0) > 0 THEN (CAST(100.00 AS decimal(18,2)) - ((100 * CAST(ISNULL(PendingSyncRecords, 0) AS DECIMAL(18,2)))/CAST(ISNULL(TotalCount, 0) AS decimal(18,2)))) ELSE 0 END AS ProgressPercent
		INTO #FinalResult FROM #TempResult

		SELECT *,
		@Count AS NumberOfItems FROM #FinalResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='LASTRUN')  THEN LastRun END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='MODULENAME')  THEN ModuleName END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='INTIGRATIONSTATUS')  THEN IntigrationStatus END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='INTERVAL')  THEN Interval END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='PROGRESSPERCENT')  THEN ProgressPercent END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='LASTSYCDATE')  THEN LastSycDate END ASC,

        CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTRUN')  THEN LastRun END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='MODULENAME')  THEN ModuleName END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='INTIGRATIONSTATUS')  THEN IntigrationStatus END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='INTERVAL')  THEN Interval END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='PROGRESSPERCENT')  THEN ProgressPercent END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTSYCDATE')  THEN LastSycDate END DESC
		OFFSET @RecordFrom ROWS 
		FETCH NEXT @PageSize ROWS ONLY
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetAccontingIntegrationDetailsList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@LastRun, '') AS VARCHAR(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@ModuleName , '') AS VARCHAR(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@masterCompanyID, '') AS VARCHAR(100))  			                                           
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