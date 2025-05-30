CREATE TYPE [dbo].[ReleaseNoteTitlesType] AS TABLE (
    [TitleId]             BIGINT          NULL,
    [ReleaseNoteHeaderId] BIGINT          NULL,
    [Title]               NVARCHAR (1000) NULL,
    [SprintName]          NVARCHAR (256)  NULL,
    [TypeId]              BIGINT          NULL,
    [TitleDescription]    NVARCHAR (MAX)  NULL,
    [MasterCompanyId]     INT             NULL,
    [CreatedBy]           NVARCHAR (256)  NULL,
    [UpdatedBy]           NVARCHAR (256)  NULL,
    [CreatedDate]         DATETIME2 (7)   NULL,
    [UpdatedDate]         DATETIME2 (7)   NULL,
    [IsActive]            BIT             NULL,
    [IsDeleted]           BIT             NULL);

