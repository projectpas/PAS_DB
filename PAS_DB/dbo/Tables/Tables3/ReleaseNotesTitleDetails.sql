CREATE TABLE [dbo].[ReleaseNotesTitleDetails] (
    [TitleId]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [ReleaseNoteHeaderId] BIGINT         NOT NULL,
    [Title]               VARCHAR (1000) NOT NULL,
    [SprintName]          VARCHAR (256)  NULL,
    [TypeId]              BIGINT         NULL,
    [Description]         NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_ReleaseNotesTitleDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_ReleaseNotesTitleDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [DF_ReleaseNotesTitleDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_ReleaseNotesTitleDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ReleaseNotesDetails] PRIMARY KEY CLUSTERED ([TitleId] ASC),
    CONSTRAINT [FK_ReleaseNoteHeader] FOREIGN KEY ([ReleaseNoteHeaderId]) REFERENCES [dbo].[ReleaseNoteHeadersDetails] ([ReleaseNoteHeaderId])
);




GO
CREATE NONCLUSTERED INDEX [IX_ReleaseNotesTitleDetails_HeaderId_Active]
    ON [dbo].[ReleaseNotesTitleDetails]([ReleaseNoteHeaderId] ASC) WHERE ([IsActive]=(1) AND [IsDeleted]=(0));


GO
CREATE   TRIGGER [dbo].[TRG_SyncReleaseNoteTitleAcrossCompanies]
ON [dbo].[ReleaseNotesTitleDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Prevent re-entry when records are inserted/updated/deleted
        -- by this synchronization process.
        IF CAST(SESSION_CONTEXT(N'InReleaseNoteSync') AS BIT) = 1
            RETURN;
        -- Set re-entry flag
        EXEC sys.sp_set_session_context
            @key = N'InReleaseNoteSync',
            @value = 1,
            @read_only = 0;

        DECLARE @TargetDBName VARCHAR(128);
        DECLARE @sql NVARCHAR(MAX);

        IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            -- INSERT or UPDATE: unchanged from the original trigger.
            DECLARE @SprintName NVARCHAR(200),
                    @Title NVARCHAR(300),
                    @TypeName NVARCHAR(100),
                    @TitleDescription NVARCHAR(MAX),
                    @CreatedBy NVARCHAR(100),
                    @UpdatedBy NVARCHAR(100),
                    @MasterCompanyId BIGINT;
            DECLARE row_cursor CURSOR LOCAL FAST_FORWARD FOR
                SELECT
                    i.SprintName,
                    i.Title,
                    WT.WorkType AS TypeName,
                    i.[Description],
                    i.CreatedBy,
                    i.UpdatedBy,
                    i.MasterCompanyId
                FROM inserted i
                LEFT JOIN dbo.WorkType WT
                    ON i.TypeId = WT.WorkTypeId;
            OPEN row_cursor;
            FETCH NEXT FROM row_cursor
            INTO
                @SprintName,
                @Title,
                @TypeName,
                @TitleDescription,
                @CreatedBy,
                @UpdatedBy,
                @MasterCompanyId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF @TypeName IS NOT NULL
                BEGIN
                    DECLARE company_cursor CURSOR LOCAL FAST_FORWARD FOR
                        SELECT DBName
                        FROM dbo.MasterCompany
                        WHERE IsActive = 1
                          AND ISNULL(IsDeleted, 0) = 0
                          AND NULLIF(LTRIM(RTRIM(DBName)), '') IS NOT NULL
                          AND DBName <> DB_NAME();
                    OPEN company_cursor;
                    FETCH NEXT FROM company_cursor
                    INTO @TargetDBName;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        SET @sql = N'
                            DECLARE @TargetHeaderId BIGINT,
                                    @TargetTypeId BIGINT;
                            -- Get Release Note Header in target database
                            SELECT @TargetHeaderId = ReleaseNoteHeaderId
                            FROM ' + QUOTENAME(@TargetDBName) + N'.dbo.ReleaseNoteHeadersDetails
                            WHERE SprintName = @P_SprintName;
                            -- Get WorkTypeId in target database
                            SELECT @TargetTypeId = WorkTypeId
                            FROM ' + QUOTENAME(@TargetDBName) + N'.dbo.WorkType
                            WHERE WorkType = @P_TypeName;
                            IF @TargetHeaderId IS NOT NULL
                               AND @TargetTypeId IS NOT NULL
                            BEGIN
                                -- Update existing title
                                UPDATE RND
                                SET
                                    RND.[Description] = @P_TitleDescription,
                                    RND.MasterCompanyId = @P_MasterCompanyId,
                                    RND.UpdatedBy = @P_UpdatedBy,
                                    RND.UpdatedDate = GETUTCDATE()
                                FROM ' + QUOTENAME(@TargetDBName) + N'.dbo.ReleaseNotesTitleDetails RND
                                WHERE RND.SprintName = @P_SprintName
                                  AND RND.Title = @P_Title
                                  AND RND.TypeId = @TargetTypeId;
                                -- Insert if title does not exist
                                IF @@ROWCOUNT = 0
                                BEGIN
                                    INSERT INTO ' + QUOTENAME(@TargetDBName) + N'.dbo.ReleaseNotesTitleDetails
                                    (
                                        ReleaseNoteHeaderId,
                                        Title,
                                        SprintName,
                                        TypeId,
                                        [Description],
                                        MasterCompanyId,
                                        CreatedBy,
                                        UpdatedBy,
                                        CreatedDate,
                                        UpdatedDate,
                                        IsActive,
                                        IsDeleted
                                    )
                                    VALUES
                                    (
                                        @TargetHeaderId,
                                        @P_Title,
                                        @P_SprintName,
                                        @TargetTypeId,
                                        @P_TitleDescription,
                                        @P_MasterCompanyId,
                                        @P_CreatedBy,
                                        @P_UpdatedBy,
                                        GETUTCDATE(),
                                        GETUTCDATE(),
                                        1,
                                        0
                                    );
                                END
                            END';
                        EXEC sys.sp_executesql
                            @sql,
                            N'@P_SprintName NVARCHAR(200),
                              @P_Title NVARCHAR(300),
                              @P_TypeName NVARCHAR(100),
                              @P_TitleDescription NVARCHAR(MAX),
                              @P_CreatedBy NVARCHAR(100),
                              @P_UpdatedBy NVARCHAR(100),
                              @P_MasterCompanyId BIGINT',
                            @P_SprintName = @SprintName,
                            @P_Title = @Title,
                            @P_TypeName = @TypeName,
                            @P_TitleDescription = @TitleDescription,
                            @P_CreatedBy = @CreatedBy,
                            @P_UpdatedBy = @UpdatedBy,
                            @P_MasterCompanyId = @MasterCompanyId;
                        FETCH NEXT FROM company_cursor
                        INTO @TargetDBName;
                    END
                    CLOSE company_cursor;
                    DEALLOCATE company_cursor;
                END
                FETCH NEXT FROM row_cursor
                INTO
                    @SprintName,
                    @Title,
                    @TypeName,
                    @TitleDescription,
                    @CreatedBy,
                    @UpdatedBy,
                    @MasterCompanyId;
            END
            CLOSE row_cursor;
            DEALLOCATE row_cursor;
        END
        ELSE IF EXISTS (SELECT 1 FROM deleted)
        BEGIN
            -- FIX: DELETE - remove the matching title row from every other active company DB.
            DECLARE @DelSprintName NVARCHAR(200),
                    @DelTitle NVARCHAR(300),
                    @DelTypeName NVARCHAR(100);
            DECLARE del_row_cursor CURSOR LOCAL FAST_FORWARD FOR
                SELECT
                    d.SprintName,
                    d.Title,
                    WT.WorkType AS TypeName
                FROM deleted d
                LEFT JOIN dbo.WorkType WT
                    ON d.TypeId = WT.WorkTypeId;
            OPEN del_row_cursor;
            FETCH NEXT FROM del_row_cursor INTO @DelSprintName, @DelTitle, @DelTypeName;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF @DelTypeName IS NOT NULL
                BEGIN
                    DECLARE del_company_cursor CURSOR LOCAL FAST_FORWARD FOR
                        SELECT DBName
                        FROM dbo.MasterCompany
                        WHERE IsActive = 1
                          AND ISNULL(IsDeleted, 0) = 0
                          AND NULLIF(LTRIM(RTRIM(DBName)), '') IS NOT NULL
                          AND DBName <> DB_NAME();
                    OPEN del_company_cursor;
                    FETCH NEXT FROM del_company_cursor INTO @TargetDBName;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        SET @sql = N'
                            DECLARE @TargetTypeId BIGINT;
                            SELECT @TargetTypeId = WorkTypeId
                            FROM ' + QUOTENAME(@TargetDBName) + N'.dbo.WorkType
                            WHERE WorkType = @P_TypeName;
                            IF @TargetTypeId IS NOT NULL
                            BEGIN
                                DELETE FROM ' + QUOTENAME(@TargetDBName) + N'.dbo.ReleaseNotesTitleDetails
                                WHERE SprintName = @P_SprintName
                                  AND Title = @P_Title
                                  AND TypeId = @TargetTypeId;
                            END';
                        EXEC sys.sp_executesql
                            @sql,
                            N'@P_SprintName NVARCHAR(200), @P_Title NVARCHAR(300), @P_TypeName NVARCHAR(100)',
                            @P_SprintName = @DelSprintName,
                            @P_Title = @DelTitle,
                            @P_TypeName = @DelTypeName;
                        FETCH NEXT FROM del_company_cursor INTO @TargetDBName;
                    END
                    CLOSE del_company_cursor;
                    DEALLOCATE del_company_cursor;
                END
                FETCH NEXT FROM del_row_cursor INTO @DelSprintName, @DelTitle, @DelTypeName;
            END
            CLOSE del_row_cursor;
            DEALLOCATE del_row_cursor;
        END

        -- Clear re-entry flag after successful synchronization
        EXEC sys.sp_set_session_context
            @key = N'InReleaseNoteSync',
            @value = 0,
            @read_only = 0;
    END TRY
    BEGIN CATCH
        DECLARE @SyncError NVARCHAR(4000);
        SET @SyncError = CONCAT(
            'Err ', ERROR_NUMBER(),
            ' Line ', ERROR_LINE(),
            ': ', ERROR_MESSAGE()
        );
        EXEC sys.sp_set_session_context
            @key = N'SyncTriggerError',
            @value = @SyncError,
            @read_only = 0;
        -- Clear re-entry flag
        EXEC sys.sp_set_session_context
            @key = N'InReleaseNoteSync',
            @value = 0,
            @read_only = 0;
    END CATCH
END