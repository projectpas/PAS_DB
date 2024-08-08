/*************************************************************           
 ** File:   [GetAccIntegrationList]           
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


EXEC USP_GetAccontingIntegrationDetailsList @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@StatusID=1,@GlobalFilter=N'',@IntegrationWith=NULL,
@SyncRecords=NULL,@PendingSyncRecords=NULL,@TotalCount=NULL,@LastRun=NULL,@Interval=NULL,@ModuleName=NULL,@CreatedDate='2024-08-08 16:35:03.670',
@UpdatedDate='2024-08-08 16:35:03.670',@CreatedBy=NULL,@UpdatedBy=NULL,@IsDeleted=0,@MasterCompanyId=1,@LastSycDate=NULL

**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetAccontingIntegrationDetailsList]
	@PageNumber int,
	@PageSize int,
	@SortColumn VARCHAR(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter VARCHAR(50) = null,
	@IntegrationWith VARCHAR(50)=null,
	--@SyncRecords VARCHAR(50)=null,
	--@PendingSyncRecords VARCHAR(50)=null,
	--@TotalCount VARCHAR(50)=null,
	@LastRun datetime=null,
	--@Interval int=0,
	@ModuleName VARCHAR(50)=null,
    --@CreatedDate datetime=null,
    --@UpdatedDate  datetime=null,
	--@CreatedBy  VARCHAR(50)=null,
	--@UpdatedBy  VARCHAR(50)=null,
    --@IsDeleted bit= null,
	@MasterCompanyId bigint = NULL,
	@LastSycDate datetime=null

AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT=1
		DECLARE @Count INT;
		DECLARE @CustomerModuleId INT;
		DECLARE @StocklineModuleId INT;
		DECLARE @VendorModuleId INT;
		DECLARE @IntegrationId INT;

		SELECT @CustomerModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE UPPER(ModuleName) = 'CUSTOMER'
		SELECT @StocklineModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'STOCKLINE'
		SELECT @VendorModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE UPPER(ModuleName) = 'VENDOR'

		SET @RecordFrom = (@PageNumber-1) * @PageSize;
			
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		Else
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END
		

			IF OBJECT_ID('tempdb..#InsertedSyncRecords') IS NOT NULL
			DROP TABLE #InsertedSyncRecords

			CREATE TABLE #InsertedSyncRecords
			(
				ID BIGINT NOT NULL IDENTITY,
				[IntegrationId] [INT] NULL,
				[CustQuickBookCount] [BIGINT] NULL,
				[CustLastSycDate] [DateTime2] null,
				[STQuickBookCount] [BIGINT] NULL,
				[STLastSycDate] [DateTime2] null,
				[VQuickBookCount] [BIGINT] NULL,
				[VLastSycDate] [DateTime2] null,
				[MasterCompanyId] [INT] NULL
			)

			INSERT #InsertedSyncRecords([CustQuickBookCount],[CustLastSycDate],[STQuickBookCount],[STLastSycDate],[VQuickBookCount],[VLastSycDate],
			[MasterCompanyId],[IntegrationId])
			SELECT  COUNT(C.QuickBooksReferenceId),MAX(C.LastSyncDate),
					COUNT(ST.QuickBooksReferenceId),MAX(ST.LastSyncDate),
					COUNT(V.QuickBooksReferenceId),MAX(V.LastSyncDate),
					ACI.[MasterCompanyId], ACI.IntegrationId 
			FROM  dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
				LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId 
				LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId 
				LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId
			WHERE (ISNULL(C.QuickBooksReferenceId,0) > 0 OR ISNULL(ST.QuickBooksReferenceId,0) > 0 OR ISNULL(V.QuickBooksReferenceId,0) > 0)
			GROUP BY ACI.[MasterCompanyId], ACI.IntegrationId

			--SELECT * FROM #InsertedSyncRecords
	
			IF OBJECT_ID('tempdb..#InsertedPendingSyncRecords') IS NOT NULL
			DROP TABLE #InsertedPendingSyncRecords

			CREATE TABLE #InsertedPendingSyncRecords
			(
				ID BIGINT NOT NULL IDENTITY,
				[IntegrationId] [INT] NULL,
				[CustPendingSyncRecords] [BIGINT] NULL,
				[STPendingSyncRecords] [BIGINT] NULL,
				[VPendingSyncRecords] [BIGINT] NULL,
				[MasterCompanyId] [INT] NULL
			)

			INSERT #InsertedPendingSyncRecords([IntegrationId],[CustPendingSyncRecords],[STPendingSyncRecords],[VPendingSyncRecords],[MasterCompanyId])
			SELECT ACI.IntegrationId, COUNT(C.IsUpdated),COUNT(ST.IsUpdated),COUNT(V.IsUpdated), ACI.[MasterCompanyId] FROM  dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
				LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId
				LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId
				LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId
			WHERE (ISNULL(C.IsUpdated,0) = 1 OR ISNULL(ST.IsUpdated,0) = 1 OR ISNULL(V.IsUpdated,0) = 1)
			GROUP BY ACI.[MasterCompanyId] , ACI.IntegrationId

			--SELECT * FROM #InsertedPendingSyncRecords

			IF OBJECT_ID('tempdb..#InsertedTotalRecords') IS NOT NULL
			DROP TABLE #InsertedTotalRecords

			CREATE TABLE #InsertedTotalRecords
			(
				ID BIGINT NOT NULL IDENTITY,
				[IntegrationId] [INT] NULL,
				[CustTotalRecords] [BIGINT] NULL,
				[STTotalRecords] [BIGINT] NULL,
				[VTotalRecords] [BIGINT] NULL,
				[MasterCompanyId] [int] NULL
			)

			INSERT #InsertedTotalRecords([IntegrationId],[CustTotalRecords],[STTotalRecords],[VTotalRecords],[MasterCompanyId])
			SELECT [IntegrationId], COUNT(C.CustomerId),COUNT(ST.StocklineId),COUNT(ST.VendorId), ACI.[MasterCompanyId] 
			FROM dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
				LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId
				LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId
				LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId
			GROUP BY ACI.[MasterCompanyId], ACI.IntegrationId

			--SELECT * FROM #InsertedTotalRecords
		
		   ;WITH Result AS(
			SELECT	
					ACI.AccountingIntegrationSettingsId, 
					ACI.IntegrationId,
					ACI.IntegrationWith,
					ACI.LastRun,
					ACI.Interval,
					ACI.ModuleId,
					ACI.ModuleName,
					ACI.MasterCompanyId,			
					CASE  
						WHEN ACI.ModuleId = @CustomerModuleId THEN CAST(SR.CustQuickBookCount AS VARCHAR(20))
						WHEN ACI.ModuleId = @StocklineModuleId THEN CAST(SR.STQuickBookCount AS VARCHAR(20))
						WHEN ACI.ModuleId = @VendorModuleId THEN CAST(SR.VQuickBookCount AS VARCHAR(20))
					else  0
					END  AS SyncRecords,
					CASE  
						WHEN ACI.ModuleId = @CustomerModuleId  THEN CAST(PSR.CustPendingSyncRecords AS VARCHAR(20))
						WHEN ACI.ModuleId = @StocklineModuleId THEN CAST(PSR.STPendingSyncRecords AS VARCHAR(20))
						WHEN ACI.ModuleId = @VendorModuleId THEN CAST(PSR.VPendingSyncRecords AS VARCHAR(20))
					else  0
					END  AS PendingSyncRecords,
					CASE  
						WHEN ACI.ModuleId = @CustomerModuleId  THEN CAST(TR.CustTotalRecords AS VARCHAR(20))
						WHEN ACI.ModuleId = @StocklineModuleId THEN CAST(TR.STTotalRecords AS VARCHAR(20))
						WHEN ACI.ModuleId = @VendorModuleId THEN CAST(TR.VTotalRecords AS VARCHAR(20))
					else  0
					END  AS TotalCount,
					--CAST(SR.QuickBookCount AS VARCHAR) as SyncRecords,
					--CAST(PSR.PendingSyncRecords AS VARCHAR) AS PendingSyncRecords,
					--CAST(TR.TotalRecords AS VARCHAR) AS TotalCount,
					SR.CustQuickBookCount,
					ACI.CreatedDate,
					ACI.CreatedBy,
					ACI.UpdatedDate,
					ACI.UpdatedBy,
					ACI.IsActive,
					ACI.IsDeleted
			FROM dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
					LEFT JOIN #InsertedSyncRecords SR WITH (NOLOCK) ON SR.MasterCompanyId = ACI.MasterCompanyId 
					LEFT JOIN #InsertedPendingSyncRecords PSR WITH (NOLOCK) ON PSR.MasterCompanyId = ACI.MasterCompanyId
					LEFT JOIN #InsertedTotalRecords TR WITH (NOLOCK) ON TR.MasterCompanyId = ACI.MasterCompanyId
			WHERE ACI.MasterCompanyId = @MasterCompanyId --AND ( AND (@IsActive IS NULL OR ACI.IsActive = @IsActive))
			), ResultCount AS(SELECT COUNT(AccountingIntegrationSettingsId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE (
			(@GlobalFilter <>'' AND
					(IntegrationWith LIKE '%' +@GlobalFilter+'%') OR
					((LastRun LIKE '%' +@GlobalFilter+'%' ) OR
					(Interval LIKE '%' +@GlobalFilter+'%') OR
					(ModuleName LIKE '%' +@GlobalFilter+'%') OR
					(SyncRecords LIKE '%' +@GlobalFilter+'%') OR
					(PendingSyncRecords LIKE '%' +@GlobalFilter+'%') OR
					(TotalCount LIKE '%' +@GlobalFilter+'%') 
					))
					OR   
					(@GlobalFilter='' AND 
					(ISNULL(@IntegrationWith,'') ='' OR cast(IntegrationWith as VARCHAR) LIKE '%' + @IntegrationWith+'%') AND
					(ISNULL(@LastRun,'') ='' OR CAST(LastRun as Date)=CAST(@LastRun as date))AND
					--(ISNULL(CAST(@Interval as VARCHAR),'') ='' OR cast(Interval as VARCHAR) LIKE '%' + CAST(@Interval as VARCHAR)+'%') AND
					(ISNULL(@ModuleName,'') ='' OR ModuleName LIKE '%' + @ModuleName+'%') AND

					--(ISNULL(@SyncRecords,'') ='' OR CAST(SyncRecords as VARCHAR) = CAST(@SyncRecords as VARCHAR))AND
					--(ISNULL(@PendingSyncRecords,'') ='' OR CAST(PendingSyncRecords as VARCHAR) = CAST(@PendingSyncRecords as VARCHAR))AND
					--(ISNULL(@TotalCount,'') ='' OR CAST(TotalCount as VARCHAR)=CAST(@TotalCount as VARCHAR))AND
					--(ISNULL(@TotalCount,'') ='' OR CAST(TotalCount as VARCHAR)=CAST(@TotalCount as VARCHAR))AND

					(ISNULL(@LastSycDate,'') ='' OR CAST(LastRun as date)=CAST(@LastSycDate as date)))
					)

			Select @Count = COUNT(AccountingIntegrationSettingsId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='LASTRUN')  THEN LastRun END ASC,
			--CASE WHEN (@SortOrder=1 AND @SortColumn='INTERVAL')  THEN Interval END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='MODULENAME')  THEN ModuleName END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END ASC,
			--CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN CusLastSycDate END ASC,

            CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTRUN')  THEN LastRun END DESC,
			--CASE WHEN (@SortOrder=-1 AND @SortColumn='INTERVAL')  THEN Interval END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MODULENAME')  THEN ModuleName END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END DESC
			--CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN CusLastSycDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetAccIntegrationList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@LastRun, '') AS VARCHAR(100))
			   --+ '@Parameter8 = ''' + CAST(ISNULL(@Interval, '') AS VARCHAR(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@ModuleName , '') AS VARCHAR(100))
			  --+ '@Parameter17 = ''' + CAST(ISNULL(@CreatedDate , '') AS VARCHAR(100))
			 -- + '@Parameter18 = ''' + CAST(ISNULL(@UpdatedDate , '') AS VARCHAR(100))
			 -- + '@Parameter19 = ''' + CAST(ISNULL(@CreatedBy  , '') AS VARCHAR(100))
			  --+ '@Parameter20 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS VARCHAR(100))
			  --+ '@Parameter21 = ''' + CAST(ISNULL(@IsDeleted , '') AS VARCHAR(100))
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