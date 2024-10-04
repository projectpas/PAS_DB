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
** 2	10/03/2024		Devendra Shekh			Modified to Save Employee Mapping


declare @p1 dbo.GeneralLedgerSearchParamsType
insert into @p1 values(N'generaltestTemplate','2024-08-23 00:00:00','2024-09-23 00:00:00',N'',N'',N'',N'',0,N'1,5,6,52,84',N'2,7,8,9',N'3,11,10',N'4,13,12',N'',N'',N'',N'',N'',N'',1,N'Jim Roberts')

exec dbo.USP_SaveGeneralLedgerSearchParams @tblType_GeneralLedgerSearchParamsType=@p1,@UserRoleId=1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_SaveGeneralLedgerSearchParams]
	@tblType_GeneralLedgerSearchParamsType [GeneralLedgerSearchParamsType] READONLY,
	@UserRoleId BIGINT = NULL,
	@CurrentUserEmployeeId BIGINT = NULL,
	@UserName VARCHAR(256) = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN

				DECLARE @GeneralLedgerSearchParamsId BIGINT = 0;
				DECLARE @ModuleHierarchyMasterId BIGINT = 0;
				DECLARE @SaveSearchTabId BIGINT = 0;
				DECLARE @UserlName VARCHAR(500) = NULL;
				DECLARE @MasterCompanyId INT = 0;

				SELECT @SaveSearchTabId = Id FROM dbo.[ModuleHierarchyMaster] WITH(NOLOCK) WHERE [Name]='Save Search' AND [ParentId] = (SELECT Id FROM dbo.[ModuleHierarchyMaster] WHERE UPPER([Name]) = 'ACCOUNTING' AND [ParentId] IS NULL);

				INSERT INTO [dbo].[GeneralLedgerSearchParams] 
						(UrlName, FromEffectiveDate, ToEffectiveDate, FromJournalId, ToJournalId, FromGLAccount, ToGLAccount, EmployeeId, 
						Level1, Level2, Level3, Level4, Level5, Level6, Level7, Level8, Level9, Level10, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsActive, IsDeleted) 
				SELECT	UrlName, FromEffectiveDate, ToEffectiveDate, FromJournalId, ToJournalId, FromGLAccount, ToGLAccount, EmployeeId, 
						Level1, Level2, Level3, Level4, Level5, Level6, Level7, Level8, Level9, Level10, MasterCompanyId, CreatedBy, GETUTCDATE(), CreatedBy, GETUTCDATE(), 1, 0
				FROM @tblType_GeneralLedgerSearchParamsType

				SET @GeneralLedgerSearchParamsId = SCOPE_IDENTITY();

				SELECT @MasterCompanyId = [MasterCompanyId], @UserlName = [CreatedBy] FROM [dbo].[GeneralLedgerSearchParams] WITH(NOLOCK) WHERE [GeneralLedgerSearchParamsId] = @GeneralLedgerSearchParamsId;

				EXEC [USP_SaveGeneralLedgerEmployeeMappingData] @GeneralLedgerSearchParamsId, @CurrentUserEmployeeId, @MasterCompanyId, @UserlName;
				--SELECT @UrlName = [UrlName] FROM [dbo].[GeneralLedgerSearchParams] WITH(NOLOCK) WHERE [GeneralLedgerSearchParamsId] = @GeneralLedgerSearchParamsId;

				--IF NOT EXISTS (SELECT Id FROM dbo.[ModuleHierarchyMaster] WHERE [Name] = @UrlName AND [ParentId] = (SELECT Id FROM dbo.[ModuleHierarchyMaster] WHERE [Name]='Save Search' AND [ParentId] = (SELECT Id FROM dbo.[ModuleHierarchyMaster] WHERE UPPER([Name]) = 'ACCOUNTING' AND [ParentId] IS NULL)))
				--BEGIN
				--	INSERT [dbo].[ModuleHierarchyMaster] ([Name], [ParentId], [IsPage], [DisplayOrder], [ModuleCode], [IsMenu], [ModuleIcon], [RouterLink], [PermissionConstant], [IsCreateMenu], [ModuleId], [ListParentId], [IsReport], [ShowAsTopMenu], [NewModuleIcon], [NewMenuName])
				--	VALUES (@UrlName, (SELECT Id FROM dbo.[ModuleHierarchyMaster] WHERE [Name]='Save Search' AND [ParentId] = (SELECT Id FROM dbo.[ModuleHierarchyMaster] WHERE UPPER([Name]) = 'ACCOUNTING' AND [ParentId] IS NULL)), 1, 1, NULL, 1, NULL, '/accountmodule/accountpages/app-general-ledger-search-template/save-search/' + CAST(@GeneralLedgerSearchParamsId AS VARCHAR), @UrlName + '_Search_Template', 0, (SELECT Id FROM [dbo].[ModuleHierarchyMaster] WITH(NOLOCK) WHERE [ParentId] IS NULL AND UPPER([Name]) = 'ACCOUNTING'), NULL, 0, 0, '', '')
				
				--	SET @ModuleHierarchyMasterId = SCOPE_IDENTITY();
				--END

				--IF(ISNULL(@ModuleHierarchyMasterId, 0) > 0 AND ISNULL(@UserRoleId, 0) > 0)
				--BEGIN
				--	EXEC [USP_SaveModuleRolePermissions_ByRoleId] @UserRoleId, @ModuleHierarchyMasterId;
				--END

			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveGeneralLedgerSearchParams' 
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