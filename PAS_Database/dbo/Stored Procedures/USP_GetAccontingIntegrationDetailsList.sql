﻿/*************************************************************           
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
@LastRun=NULL,@ModuleName=NULL,@MasterCompanyId=1,@LastSycDate=NULL

**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetAccontingIntegrationDetailsList]
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
				LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId AND ISNULL(C.IsActive, 0) = 1 AND ISNULL(C.IsDeleted, 0) = 0
				LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId AND ISNULL(ST.IsActive, 0) = 1 AND ISNULL(ST.IsDeleted, 0) = 0
				LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId AND ISNULL(V.IsActive, 0) = 1 AND ISNULL(V.IsDeleted, 0) = 0
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
				LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId AND ISNULL(C.IsActive, 0) = 1 AND ISNULL(C.IsDeleted, 0) = 0
				LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId AND ISNULL(ST.IsActive, 0) = 1 AND ISNULL(ST.IsDeleted, 0) = 0
				LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId=ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId AND ISNULL(V.IsActive, 0) = 1 AND ISNULL(V.IsDeleted, 0) = 0
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
			SELECT [IntegrationId], COUNT(C.CustomerId),COUNT(ST.StocklineId),COUNT(V.VendorId), ACI.[MasterCompanyId] 
			FROM dbo.AccountingIntegrationSettings ACI WITH (NOLOCK)
				LEFT JOIN  dbo.Customer C  WITH (NOLOCK) ON C.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @CustomerModuleId AND ISNULL(C.IsActive, 0) = 1 AND ISNULL(C.IsDeleted, 0) = 0
				LEFT JOIN  dbo.Stockline ST  WITH (NOLOCK) ON ST.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @StocklineModuleId AND ISNULL(ST.IsActive, 0) = 1 AND ISNULL(ST.IsDeleted, 0) = 0
				LEFT JOIN  dbo.Vendor V  WITH (NOLOCK) ON V.MasterCompanyId = ACI.MasterCompanyId AND ACI.ModuleId = @VendorModuleId AND ISNULL(V.IsActive, 0) = 1 AND ISNULL(V.IsDeleted, 0) = 0
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
						WHEN ACI.ModuleId = @CustomerModuleId THEN ISNULL(SR.CustQuickBookCount, 0)
						WHEN ACI.ModuleId = @StocklineModuleId THEN ISNULL(SR.STQuickBookCount, 0)
						WHEN ACI.ModuleId = @VendorModuleId THEN ISNULL(SR.VQuickBookCount, 0)
					else  0
					END  AS SyncRecords,
					CASE  
						WHEN ACI.ModuleId = @CustomerModuleId  THEN ISNULL(PSR.CustPendingSyncRecords, 0)
						WHEN ACI.ModuleId = @StocklineModuleId THEN ISNULL(PSR.STPendingSyncRecords, 0)
						WHEN ACI.ModuleId = @VendorModuleId THEN ISNULL(PSR.VPendingSyncRecords, 0)
					else  0
					END  AS PendingSyncRecords,
					CASE  
						WHEN ACI.ModuleId = @CustomerModuleId  THEN ISNULL(TR.CustTotalRecords, 0)
						WHEN ACI.ModuleId = @StocklineModuleId THEN ISNULL(TR.STTotalRecords, 0)
						WHEN ACI.ModuleId = @VendorModuleId THEN ISNULL(TR.VTotalRecords, 0)
					else  0
					END  AS TotalCount,
					ISNULL(SR.CustQuickBookCount, 0) AS CustQuickBookCount,
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
					(ISNULL(@ModuleName,'') ='' OR ModuleName LIKE '%' + @ModuleName+'%') AND
					(ISNULL(@LastSycDate,'') ='' OR CAST(LastRun as date)=CAST(@LastSycDate as date))))

			Select @Count = COUNT(AccountingIntegrationSettingsId) FROM #TempResult			

			SELECT *, CASE WHEN ISNULL(TotalCount, 0) > 0 THEN (CAST(100.00 AS decimal(18,2)) - ((100 * CAST(ISNULL(PendingSyncRecords, 0) AS DECIMAL(18,2)))/CAST(ISNULL(TotalCount, 0) AS decimal(18,2)))) ELSE 0 END AS ProgressPercent , 
			@Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='LASTRUN')  THEN LastRun END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='MODULENAME')  THEN ModuleName END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END ASC,

            CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN IntegrationWith END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTRUN')  THEN LastRun END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MODULENAME')  THEN ModuleName END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN SyncRecords END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN PendingSyncRecords END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN TotalCount END DESC
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