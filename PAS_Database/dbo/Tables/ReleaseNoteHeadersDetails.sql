CREATE TABLE [dbo].[ReleaseNoteHeadersDetails] (
    [ReleaseNoteHeaderId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SprintName]          VARCHAR (256)  NOT NULL,
    [SprinDescription]    NVARCHAR (MAX) NOT NULL,
    [ReleaseDate]         DATETIME2 (7)  NULL,
    [FileName]            NVARCHAR (500) NULL,
    [DocumentPath]        NVARCHAR (500) NULL,
    [MasterCompanyId]     INT            NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_ReleaseNoteHeadersDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_ReleaseNoteHeadersDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [DF_ReleaseNoteHeadersDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_ReleaseNoteHeadersDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ReleaseNoteHeadersDetails] PRIMARY KEY CLUSTERED ([ReleaseNoteHeaderId] ASC)
);


GO
CREATE   TRIGGER [dbo].[TRG_SyncReleaseNoteHeaderAcrossCompanies]
ON [dbo].[ReleaseNoteHeadersDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF CAST(SESSION_CONTEXT(N'InReleaseNoteHeaderSync') AS BIT) = 1
        RETURN;
    EXEC sys.sp_set_session_context @key = N'InReleaseNoteHeaderSync', @value = 1, @read_only = 0;

    BEGIN TRY
        DECLARE @TargetDBName VARCHAR(128);
        DECLARE @sql NVARCHAR(MAX);

        IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            DECLARE @SprintName NVARCHAR(200), @SprinDescription NVARCHAR(MAX), @ReleaseDate DATETIME,
                    @FileName NVARCHAR(300), @DocumentPath NVARCHAR(500), @CreatedBy NVARCHAR(100), @UpdatedBy NVARCHAR(100);
            DECLARE row_cursor CURSOR LOCAL FAST_FORWARD FOR
                SELECT SprintName, SprinDescription, ReleaseDate, [FileName], DocumentPath, CreatedBy, UpdatedBy
                FROM inserted;
            OPEN row_cursor;
            FETCH NEXT FROM row_cursor INTO @SprintName, @SprinDescription, @ReleaseDate, @FileName, @DocumentPath, @CreatedBy, @UpdatedBy;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE company_cursor CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DBName
                    FROM dbo.MasterCompany
                    WHERE IsActive = 1
                          AND ISNULL(IsDeleted, 0) = 0
                          AND DBName IS NOT NULL
                          AND DBName <> DB_NAME();
                OPEN company_cursor;
                FETCH NEXT FROM company_cursor INTO @TargetDBName;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SET @sql = N'
                        UPDATE RHD SET
                            RHD.SprinDescription = @P_SprinDescription,
                            RHD.ReleaseDate = @P_ReleaseDate,
                            RHD.[FileName] = @P_FileName,
                            RHD.DocumentPath = @P_DocumentPath,
                            RHD.UpdatedBy = @P_UpdatedBy,
                            RHD.UpdatedDate = GETUTCDATE()
                        FROM ' + QUOTENAME(@TargetDBName) + N'.dbo.ReleaseNoteHeadersDetails RHD
                        WHERE RHD.SprintName = @P_SprintName;
                        IF @@ROWCOUNT = 0
                        BEGIN
                            INSERT INTO ' + QUOTENAME(@TargetDBName) + N'.dbo.ReleaseNoteHeadersDetails
                                (SprintName, SprinDescription, ReleaseDate, [FileName], DocumentPath,
                                 CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
                            VALUES
                                (@P_SprintName, @P_SprinDescription, @P_ReleaseDate, @P_FileName, @P_DocumentPath,
                                 @P_CreatedBy, @P_UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
                        END';
                    EXEC sp_executesql @sql,
                        N'@P_SprintName NVARCHAR(200), @P_SprinDescription NVARCHAR(MAX), @P_ReleaseDate DATETIME,
                          @P_FileName NVARCHAR(300), @P_DocumentPath NVARCHAR(500), @P_CreatedBy NVARCHAR(100), @P_UpdatedBy NVARCHAR(100)',
                        @P_SprintName = @SprintName, @P_SprinDescription = @SprinDescription, @P_ReleaseDate = @ReleaseDate,
                        @P_FileName = @FileName, @P_DocumentPath = @DocumentPath, @P_CreatedBy = @CreatedBy, @P_UpdatedBy = @UpdatedBy;
                    FETCH NEXT FROM company_cursor INTO @TargetDBName;
                END
                CLOSE company_cursor;
                DEALLOCATE company_cursor;
                FETCH NEXT FROM row_cursor INTO @SprintName, @SprinDescription, @ReleaseDate, @FileName, @DocumentPath, @CreatedBy, @UpdatedBy;
            END
            CLOSE row_cursor;
            DEALLOCATE row_cursor;
        END
        ELSE IF EXISTS (SELECT 1 FROM deleted)
        BEGIN
            DELETE FROM dbo.ReleaseNotesTitleDetails
            WHERE ReleaseNoteHeaderId IN (SELECT ReleaseNoteHeaderId FROM deleted);

            -- FIX: DELETE - remove the matching header row from every other active company DB.
            DECLARE @DelSprintName NVARCHAR(200);
            DECLARE del_row_cursor CURSOR LOCAL FAST_FORWARD FOR
                SELECT SprintName FROM deleted;
            OPEN del_row_cursor;
            FETCH NEXT FROM del_row_cursor INTO @DelSprintName;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE del_company_cursor CURSOR LOCAL FAST_FORWARD FOR
                    SELECT DBName
                    FROM dbo.MasterCompany
                    WHERE IsActive = 1
                          AND ISNULL(IsDeleted, 0) = 0
                          AND DBName IS NOT NULL
                          AND DBName <> DB_NAME();
                OPEN del_company_cursor;
                FETCH NEXT FROM del_company_cursor INTO @TargetDBName;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    SET @sql = N'DELETE FROM ' + QUOTENAME(@TargetDBName) + N'.dbo.ReleaseNoteHeadersDetails WHERE SprintName = @P_SprintName;';
                    EXEC sp_executesql @sql, N'@P_SprintName NVARCHAR(200)', @P_SprintName = @DelSprintName;
                    FETCH NEXT FROM del_company_cursor INTO @TargetDBName;
                END
                CLOSE del_company_cursor;
                DEALLOCATE del_company_cursor;
                FETCH NEXT FROM del_row_cursor INTO @DelSprintName;
            END
            CLOSE del_row_cursor;
            DEALLOCATE del_row_cursor;
        END

        EXEC sys.sp_set_session_context @key = N'InReleaseNoteHeaderSync', @value = 0, @read_only = 0;
    END TRY
    BEGIN CATCH
        -- IMPORTANT: swallow/log rather than re-throw - a sync failure to one
        -- target DB must not roll back the source company's own successful save.
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
        EXEC spLogException @DatabaseName = @DatabaseName, @AdhocComments = 'TRG_SyncReleaseNoteHeaderAcrossCompanies',
             @ProcedureParameters = '', @ApplicationName = 'PAS', @ErrorLogID = @ErrorLogID OUTPUT;
        EXEC sys.sp_set_session_context @key = N'InReleaseNoteHeaderSync', @value = 0, @read_only = 0;
    END CATCH
END