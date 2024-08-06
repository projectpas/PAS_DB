/*************************************************************           
 ** File:   [GetAccIntegrationList]           
 ** Author:   Bhargav Saliya
 ** Description:  
 ** Purpose:         
 ** Date:   31-Jul-2024        
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    12/14/2020   Bhargav Saliya	 Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetAccIntegrationList]
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@IntegrationWith varchar(50)=null,
	@SyncRecords varchar(50)=null,
	@PendingSyncRecords varchar(50)=null,
	@TotalCount varchar(50)=null,
	@LastRun datetime=null,
	@Interval int=0,
	@ModuleName varchar(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,
	@MasterCompanyId bigint = NULL,
	@LastSycDate datetime=null
	


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

			IF OBJECT_ID('tempdb..#InsertedSyncRecords') IS NOT NULL
			DROP TABLE #InsertedSyncRecords

			CREATE TABLE #InsertedSyncRecords
			(
				ID BIGINT NOT NULL IDENTITY,
				[QuickBookCount] [bigint] NULL,
				[LastSycDate] [DateTime2] null,
				[STQuickBookCount] [bigint] NULL,
				[STLastSycDate] [DateTime2] null,
				[VQuickBookCount] [bigint] NULL,
				[VLastSycDate] [DateTime2] null,
				[MasterCompanyId] [int] NULL
			)

			INSERT #InsertedSyncRecords([QuickBookCount],[LastSycDate],[STQuickBookCount],[STLastSycDate],[VQuickBookCount],[VLastSycDate],[MasterCompanyId])
			SELECT 
					COUNT(C.QuickBooksCustomerId),MAX(C.LastSyncDate),
					COUNT(ST.QuickBooksStocklineId),MAX(ST.LastSyncDate),0,
					--COUNT(V.QuickBooksVendorId),MAX(V.LastSyncDate),
					ACI.[MasterCompanyId] 
			FROM  dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
			LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Customer')
			LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Stockline')
			LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Vendor')

			WHERE (ISNULL(C.QuickBooksCustomerId,0) > 0 OR ISNULL(ST.QuickBooksStocklineId,0) > 0)
			GROUP BY ACI.[MasterCompanyId]
	
			--SELECT * FROM #InsertedSyncRecords


			IF OBJECT_ID('tempdb..#InsertedPendingSyncRecords') IS NOT NULL
			DROP TABLE #InsertedPendingSyncRecords

			CREATE TABLE #InsertedPendingSyncRecords
			(
				ID BIGINT NOT NULL IDENTITY,
				[PendingSyncRecords] [bigint] NULL,
				[STPendingSyncRecords] [bigint] NULL,
				[VPendingSyncRecords] [bigint] NULL,
				[MasterCompanyId] [int] NULL
			)

			INSERT #InsertedPendingSyncRecords([PendingSyncRecords],[STPendingSyncRecords],[VPendingSyncRecords],[MasterCompanyId])
			SELECT --COUNT(C.IsUpdated),COUNT(ST.IsUpdated),COUNT(V.IsUpdated),
				1,1,1,
			ACI.[MasterCompanyId] FROM  dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
			LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Customer')
			LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Stockline')
			LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Vendor')
			WHERE (ISNULL(C.IsUpdated,0) = 1 OR ISNULL(ST.IsUpdated,0) = 1)
			GROUP BY ACI.[MasterCompanyId]

			--SELECT * FROM #InsertedPendingSyncRecords

			IF OBJECT_ID('tempdb..#InsertedTotalRecords') IS NOT NULL
			DROP TABLE #InsertedTotalRecords

			CREATE TABLE #InsertedTotalRecords
			(
				ID BIGINT NOT NULL IDENTITY,
				[TotalRecords] [bigint] NULL,
				[STTotalRecords] [bigint] NULL,
				[VTotalRecords] [bigint] NULL,
				[MasterCompanyId] [int] NULL
			)

			INSERT #InsertedTotalRecords([TotalRecords],[STTotalRecords],[VTotalRecords],[MasterCompanyId])
			SELECT COUNT(C.CustomerId),COUNT(ST.StocklineId),COUNT(ST.VendorId), ACI.[MasterCompanyId] FROM  dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
			LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Customer')
			LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Stockline')
			LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = (SELECT ModuleId fROM Module WHERE ModuleName='Vendor')
			--WHERE ISNULL(IsUpdated,0) = 1
			GROUP BY ACI.[MasterCompanyId]

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
						WHEN ACI.ModuleName = 'Customer' THEN CAST(SR.QuickBookCount AS varchar)
						WHEN ACI.ModuleName = 'Stockline' THEN CAST(SR.STQuickBookCount AS varchar)
						WHEN ACI.ModuleName = 'Vendor' THEN CAST(SR.VQuickBookCount AS varchar)
					else  0
					END  AS SyncRecords,
					CASE  
						WHEN ACI.ModuleName = 'Customer' THEN CAST(PSR.PendingSyncRecords AS varchar)
						WHEN ACI.ModuleName = 'Stockline' THEN CAST(PSR.STPendingSyncRecords AS varchar)
						WHEN ACI.ModuleName = 'Vendor' THEN CAST(PSR.VPendingSyncRecords AS varchar)
					else  0
					END  AS PendingSyncRecords,
					CASE  
						WHEN ACI.ModuleName = 'Customer' THEN CAST(TR.TotalRecords AS varchar)
						WHEN ACI.ModuleName = 'Stockline' THEN CAST(TR.STTotalRecords AS varchar)
						WHEN ACI.ModuleName = 'Vendor' THEN CAST(TR.VTotalRecords AS varchar)
					else  0
					END  AS TotalCount,
					--CAST(SR.QuickBookCount AS varchar) as SyncRecords,
					--CAST(PSR.PendingSyncRecords AS varchar) AS PendingSyncRecords,
					--CAST(TR.TotalRecords AS varchar) AS TotalCount,
					SR.LastSycDate,
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
					Where ((ACI.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR ACI.IsActive=@IsActive))
					AND ACI.MasterCompanyId=@MasterCompanyId	
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
					(ISNULL(@IntegrationWith,'') ='' OR cast(IntegrationWith as varchar) LIKE '%' + @IntegrationWith+'%') AND
					(ISNULL(@LastRun,'') ='' OR CAST(LastRun as Date)=CAST(@LastRun as date))AND
					(ISNULL(CAST(@Interval as varchar),'') ='' OR cast(Interval as varchar) LIKE '%' + CAST(@Interval as varchar)+'%') AND
					(ISNULL(@ModuleName,'') ='' OR ModuleName LIKE '%' + @ModuleName+'%') AND

					(ISNULL(@SyncRecords,'') ='' OR CAST(SyncRecords as varchar) = CAST(@SyncRecords as varchar))AND
					(ISNULL(@PendingSyncRecords,'') ='' OR CAST(PendingSyncRecords as varchar) = CAST(@PendingSyncRecords as varchar))AND
					(ISNULL(@TotalCount,'') ='' OR CAST(TotalCount as varchar)=CAST(@TotalCount as varchar))AND
					--(ISNULL(@TotalCount,'') ='' OR CAST(TotalCount as varchar)=CAST(@TotalCount as varchar))AND

					(ISNULL(@LastSycDate,'') ='' OR CAST(LastSycDate as date)=CAST(@LastSycDate as date)))
					)

			Select @Count = COUNT(AccountingIntegrationSettingsId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='LASTRUN')  THEN LastRun END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='INTERVAL')  THEN Interval END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='MODULENAME')  THEN ModuleName END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN LastSycDate END ASC,

            CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTRUN')  THEN LastRun END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='INTERVAL')  THEN Interval END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MODULENAME')  THEN ModuleName END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN LastSycDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetAccIntegrationList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@LastRun, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@Interval, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@ModuleName , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))  			                                           
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