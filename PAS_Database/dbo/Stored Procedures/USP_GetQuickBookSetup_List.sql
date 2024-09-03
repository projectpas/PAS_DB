/*************************************************************           
 ** File:   [USP_GetQuickBookSetup_List]           
 ** Author:    Devendra Shekh
 ** Description:  get quickBook setup list data
 ** Purpose:         
 ** Date:   02-SEP-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    09/02/2024   Devendra Shekh	     CREATED

exec USP_GetQuickBookSetup_List @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@StatusID=1,@GlobalFilter=N'',@ClientId=NULL,@ClientSecret=NULL,
@RedirectUrl=NULL,@Environment=NULL,@CreatedBy=NULL,@UpdatedBy=NULL,@CreatedDate=NULL,@UpdatedDate=NULL,@IsDeleted=0,@MasterCompanyId=1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetQuickBookSetup_List]
	@PageSize INT,
	@PageNumber INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@StatusID INT = NULL,
	@GlobalFilter VARCHAR(50) = NULL,
	@ClientId VARCHAR(500) = NULL,
	@ClientSecret VARCHAR(500) = NULL,
	@RedirectUrl VARCHAR(5000) = NULL,
	@Environment VARCHAR(200) = NULL,
	@CreatedBy VARCHAR(256) = NULL,
	@UpdatedBy VARCHAR(256) = NULL,
	@CreatedDate DATETIME2 = NULL,
	@UpdatedDate DATETIME2 = NULL,
	@IsDeleted bit = NULL,
	@APIKey VARCHAR(500) = NULL,
	@IsEnabled VARCHAR(25) = NULL,
	@MasterCompanyId INT
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT=1
		DECLARE @Count INT;

		IF(@StatusID = 0)
		BEGIN
			SET @IsActive = 0;
		END
		ELSE IF(@StatusID = 1)
		BEGIN
			SET @IsActive = 1;
		END
		ELSE
		BEGIN
			SET @IsActive = NULL;
		END

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
				ACI.AccountingIntegrationSetupId, 
				ACI.IntegrationId,
				ISNULL(ACI.ClientId, '') AS 'ClientId',
				ISNULL(ACI.ClientSecret, '') AS 'ClientSecret',
				ISNULL(ACI.RedirectUrl, '') AS 'RedirectUrl',
				ISNULL(ACI.Environment, '') AS 'Environment',
				ISNULL(ACI.APIKey, '') AS 'APIKey',
				CASE WHEN ISNULL(ACI.IsEnabled, 0) = 0 THEN 'NO' ELSE 'YES' END AS 'IsEnabled',
				ACI.MasterCompanyId,			
				ACI.CreatedDate,
				ACI.CreatedBy,
				ACI.UpdatedDate,
				ACI.UpdatedBy,
				ACI.IsActive,
				ACI.IsDeleted
		FROM dbo.AccountingIntegrationSetup ACI WITH (NOLOCK)
		WHERE	ACI.MasterCompanyId = @MasterCompanyId
				AND (@IsActive IS NULL OR ACI.IsActive = @IsActive) AND (@IsDeleted IS NULL OR ACI.IsDeleted = @IsDeleted)
		)
		SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((ClientId LIKE '%' +@GlobalFilter+'%') OR
			        (ClientSecret LIKE '%' +@GlobalFilter+'%') OR	
					(RedirectUrl LIKE '%' +@GlobalFilter+'%') OR
					(Environment LIKE '%' +@GlobalFilter+'%') OR
					(APIKey LIKE '%' +@GlobalFilter+'%') OR
					(IsEnabled LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@ClientId,'') ='' OR ClientId LIKE '%' + @ClientId+'%') AND
					(ISNULL(@ClientSecret,'') ='' OR ClientSecret LIKE '%' + @ClientSecret+'%') AND
					(ISNULL(@RedirectUrl,'') ='' OR RedirectUrl LIKE '%' + @RedirectUrl+'%') AND
					(ISNULL(@Environment,'') ='' OR Environment LIKE '%' + @Environment+'%') AND
					(ISNULL(@APIKey,'') ='' OR APIKey LIKE '%' + @APIKey+'%') AND
					(ISNULL(@IsEnabled,'') ='' OR UPPER(IsEnabled) LIKE '%' + UPPER(@IsEnabled)+'%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					)
		Select @Count = COUNT(AccountingIntegrationSetupId) FROM #TempResult;	

		SELECT *, @Count AS NumberOfItems FROM #TempResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='ClientId')  THEN ClientId END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='ClientSecret')  THEN ClientSecret END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='RedirectUrl')  THEN RedirectUrl END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='Environment')  THEN Environment END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='APIKey')  THEN APIKey END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='IsEnabled')  THEN IsEnabled END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,

		CASE WHEN (@SortOrder=-1 AND @SortColumn='ClientId')  THEN ClientId END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ClientSecret')  THEN ClientSecret END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='RedirectUrl')  THEN RedirectUrl END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='Environment')  THEN Environment END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='APIKey')  THEN APIKey END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='IsEnabled')  THEN IsEnabled END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC
		OFFSET @RecordFrom ROWS 
		FETCH NEXT @PageSize ROWS ONLY

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetQuickBookSetup_List'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@ClientId, '') AS VARCHAR(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@ClientSecret , '') AS VARCHAR(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@RedirectUrl , '') AS VARCHAR(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@Environment , '') AS VARCHAR(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@CreatedBy , '') AS VARCHAR(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@UpdatedBy , '') AS VARCHAR(100))
			   + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS VARCHAR(100))
			   + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedDate , '') AS VARCHAR(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@masterCompanyID, '') AS VARCHAR(100))  			                                           
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