/*************************************************************
 ** File:        [CopyModuleHierarchyMaster]
 ** Author:
 ** Description: Script to copy data from ModuleHierarchyMaster table
 **              in a source database to the target (current) database.
 **              Preserves original Id values via IDENTITY_INSERT.
 **              Existing rows (matched by Id) are updated; new rows are inserted.
 ** Purpose:     Cross-database data migration for ModuleHierarchyMaster
 ** Date:        04/23/2026
 **
 ** USAGE:
 **   1. Set @SourceDB to the name of the source SQL Server database.
 **   2. Both databases must reside on the same SQL Server instance.
 **      For a remote server, replace [$(SourceDB)].[dbo].[ModuleHierarchyMaster]
 **      with the four-part linked-server name:
 **        [LinkedServerName].[SourceDatabaseName].[dbo].[ModuleHierarchyMaster]
 **   3. Run this script while connected to the TARGET database.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author    Change Description
 ** --   ----------   -------   --------------------------------
    1    04/23/2026             Created
 *************************************************************/

-- ============================================================
-- CONFIGURATION: set the source database name here
-- ============================================================
DECLARE @SourceDB NVARCHAR(128) = N'SourceDatabaseName';   -- <-- change this

-- ============================================================
-- Dynamic SQL is required because database names cannot be
-- parameterised in static T-SQL identifiers.
-- ============================================================
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;

        -- Allow explicit values for the IDENTITY column
        SET IDENTITY_INSERT [dbo].[ModuleHierarchyMaster] ON;

        MERGE [dbo].[ModuleHierarchyMaster] AS [Target]
        USING (
            SELECT
                [Id],
                [Name],
                [ParentId],
                [IsPage],
                [DisplayOrder],
                [ModuleCode],
                [IsMenu],
                [ModuleIcon],
                [RouterLink],
                [PermissionConstant],
                [IsCreateMenu],
                [ModuleId],
                [ListParentId],
                [IsReport],
                [ShowAsTopMenu],
                [NewModuleIcon],
                [NewMenuName],
                [ImgClass],
                [IsMobileMenu],
                [MobileMenuName],
                [MobileMenuSequence]
            FROM [' + @SourceDB + N'].[dbo].[ModuleHierarchyMaster] WITH (NOLOCK)
        ) AS [Source]
        ON [Target].[Id] = [Source].[Id]

        -- Update rows that already exist in the target
        WHEN MATCHED THEN
            UPDATE SET
                [Target].[Name]               = [Source].[Name],
                [Target].[ParentId]           = [Source].[ParentId],
                [Target].[IsPage]             = [Source].[IsPage],
                [Target].[DisplayOrder]       = [Source].[DisplayOrder],
                [Target].[ModuleCode]         = [Source].[ModuleCode],
                [Target].[IsMenu]             = [Source].[IsMenu],
                [Target].[ModuleIcon]         = [Source].[ModuleIcon],
                [Target].[RouterLink]         = [Source].[RouterLink],
                [Target].[PermissionConstant] = [Source].[PermissionConstant],
                [Target].[IsCreateMenu]       = [Source].[IsCreateMenu],
                [Target].[ModuleId]           = [Source].[ModuleId],
                [Target].[ListParentId]       = [Source].[ListParentId],
                [Target].[IsReport]           = [Source].[IsReport],
                [Target].[ShowAsTopMenu]      = [Source].[ShowAsTopMenu],
                [Target].[NewModuleIcon]      = [Source].[NewModuleIcon],
                [Target].[NewMenuName]        = [Source].[NewMenuName],
                [Target].[ImgClass]           = [Source].[ImgClass],
                [Target].[IsMobileMenu]       = [Source].[IsMobileMenu],
                [Target].[MobileMenuName]     = [Source].[MobileMenuName],
                [Target].[MobileMenuSequence] = [Source].[MobileMenuSequence]

        -- Insert rows that do not yet exist in the target
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                [Id],
                [Name],
                [ParentId],
                [IsPage],
                [DisplayOrder],
                [ModuleCode],
                [IsMenu],
                [ModuleIcon],
                [RouterLink],
                [PermissionConstant],
                [IsCreateMenu],
                [ModuleId],
                [ListParentId],
                [IsReport],
                [ShowAsTopMenu],
                [NewModuleIcon],
                [NewMenuName],
                [ImgClass],
                [IsMobileMenu],
                [MobileMenuName],
                [MobileMenuSequence]
            )
            VALUES (
                [Source].[Id],
                [Source].[Name],
                [Source].[ParentId],
                [Source].[IsPage],
                [Source].[DisplayOrder],
                [Source].[ModuleCode],
                [Source].[IsMenu],
                [Source].[ModuleIcon],
                [Source].[RouterLink],
                [Source].[PermissionConstant],
                [Source].[IsCreateMenu],
                [Source].[ModuleId],
                [Source].[ListParentId],
                [Source].[IsReport],
                [Source].[ShowAsTopMenu],
                [Source].[NewModuleIcon],
                [Source].[NewMenuName],
                [Source].[ImgClass],
                [Source].[IsMobileMenu],
                [Source].[MobileMenuName],
                [Source].[MobileMenuSequence]
            );

        SET IDENTITY_INSERT [dbo].[ModuleHierarchyMaster] OFF;

    COMMIT TRANSACTION;
    PRINT ''ModuleHierarchyMaster data copied successfully.'';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SET IDENTITY_INSERT [dbo].[ModuleHierarchyMaster] OFF;

    DECLARE @ErrorMessage  NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT            = ERROR_SEVERITY();
    DECLARE @ErrorState    INT            = ERROR_STATE();

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
';

EXEC sp_executesql @SQL;
