/*************************************************************   
** Author:  <Devendra Shekh>  
** Create date: <09/23/2024>  [mm/dd/yyyy]
** Description: <Save General Ledger Search Params>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	09/23/2024		Devendra Shekh			Created
** 2	11/28/2024		Abhishek Jirawla		Modified SP Added Transaction


declare @p1 dbo.GeneralLedgerSearchParamsType
insert into @p1 values(N'testUrlName','2024-08-23 00:00:00','2024-09-23 00:00:00',N'',N'',N'',N'',0,N'1,5,6,52,84',N'2,7,8,9',N'3,11,10',N'4,13,12',N'',N'',N'',N'',N'',N'',1,N'Jim Roberts')

exec dbo.USP_SaveGeneralLedgerSearchParams @tblType_GeneralLedgerSearchParamsType=@p1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_SaveModuleRolePermissions_ByRoleId]
	@UserRoleId BIGINT = NULL,
	@ModuleHierarchyMasterId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRANSACTION 
		BEGIN TRY
			BEGIN
				DECLARE @TotalRecords INT = 0, @CurrentRecordId INT = 0, @CurrentPermissionId INT = 0,@CurrentPermissionName VARCHAR(50), @IsSuperAdmin BIT = 0;
				DECLARE @AddPermissionId INT, @ViewPermissionId INT, @UpdatePermissionId INT, @DeletePermissionId INT, @DownloadPermissionId INT, @UploadPermissionId INT, @ReportPermissionId INT; 

				SET @AddPermissionId = (SELECT [PermissionID] FROM [dbo].[PermissionMaster] WITH(NOLOCK) WHERE UPPER([PermissionName]) IN ('ADD'));
				SET @ViewPermissionId = (SELECT [PermissionID] FROM [dbo].[PermissionMaster] WITH(NOLOCK) WHERE UPPER([PermissionName]) IN ('VIEW'));
				SET @UpdatePermissionId = (SELECT [PermissionID] FROM [dbo].[PermissionMaster] WITH(NOLOCK) WHERE UPPER([PermissionName]) IN ('UPDATE'));
				SET @DeletePermissionId = (SELECT [PermissionID] FROM [dbo].[PermissionMaster] WITH(NOLOCK) WHERE UPPER([PermissionName]) IN ('DELETE'));
				SET @DownloadPermissionId = (SELECT [PermissionID] FROM [dbo].[PermissionMaster] WITH(NOLOCK) WHERE UPPER([PermissionName]) IN ('DOWNLOAD'));
				SET @UploadPermissionId = (SELECT [PermissionID] FROM [dbo].[PermissionMaster] WITH(NOLOCK) WHERE UPPER([PermissionName]) IN ('UPLOAD'));
				SET @ReportPermissionId = (SELECT [PermissionID] FROM [dbo].[PermissionMaster] WITH(NOLOCK) WHERE UPPER([PermissionName]) IN ('Report'));
			
				IF OBJECT_ID('tempdb..#tmpPermissionMaster') IS NOT NULL
					DROP TABLE #tmpPermissionMaster

				CREATE TABLE #tmpPermissionMaster
				(
					[RecordId] INT IDENTITY(1,1),
					[PermissionID]	INT NULL,
					[PermissionName] VARCHAR(50) NULL,
					[UserRoleId] BIGINT NULL,
					[ModuleHierarchyMasterId] BIGINT NULL,
				)

				INSERT INTO #tmpPermissionMaster([PermissionID], [PermissionName], [UserRoleId], [ModuleHierarchyMasterId]) 
				SELECT [PermissionID], [PermissionName], @UserRoleId, @ModuleHierarchyMasterId FROM [dbo].[PermissionMaster] WITH(NOLOCK) WHERE [PermissionID] IN (@AddPermissionId, @ViewPermissionId, @UpdatePermissionId, @DeletePermissionId, @DownloadPermissionId, @UploadPermissionId, @ReportPermissionId);

				SELECT @TotalRecords = MAX(RecordId), @CurrentRecordId = MIN(RecordId) FROM #tmpPermissionMaster;

				MERGE INTO [dbo].[RolePermission] AS TARGET
						USING #tmpPermissionMaster AS SOURCE
						ON (TARGET.[PermissionID] = SOURCE.[PermissionID] AND TARGET.[UserRoleId] = SOURCE.[UserRoleId] AND TARGET.[ModuleHierarchyMasterId] = SOURCE.[ModuleHierarchyMasterId])
						WHEN NOT MATCHED BY TARGET THEN
							-- Insert new records where no match is found
							INSERT ([UserRoleId], [ModuleHierarchyMasterId], [CanAdd], [CanView], [CanUpdate], [CanDelete], [Reports], [CanUpload], [CanDownload], [PermissionID])
							VALUES (SOURCE.[UserRoleId], SOURCE.[ModuleHierarchyMasterId],
									CASE WHEN SOURCE.[PermissionID] = @AddPermissionId THEN 1 ELSE 0 END, 
									CASE WHEN SOURCE.[PermissionID] = @ViewPermissionId THEN 1 ELSE 0 END, 
									CASE WHEN SOURCE.[PermissionID] = @UpdatePermissionId THEN 1 ELSE 0 END, 
									CASE WHEN SOURCE.[PermissionID] = @DeletePermissionId THEN 1 ELSE 0 END, 
									CASE WHEN SOURCE.[PermissionID] = @ReportPermissionId THEN 1 ELSE 0 END, 
									CASE WHEN SOURCE.[PermissionID] = @UploadPermissionId THEN 1 ELSE 0 END, 
									CASE WHEN SOURCE.[PermissionID] = @DownloadPermissionId THEN 1 ELSE 0 END, 
									SOURCE.[PermissionID]);

				IF OBJECT_ID('tempdb..#tmpPermissionMaster') IS NOT NULL
					DROP TABLE #tmpPermissionMaster
			END
			COMMIT TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                ROLLBACK TRANSACTION
				  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_SaveModuleRolePermissions_ByRoleId' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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