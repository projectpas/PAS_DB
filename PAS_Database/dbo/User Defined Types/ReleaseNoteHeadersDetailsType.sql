CREATE TYPE [dbo].[ReleaseNoteHeadersDetailsType] AS TABLE (
    [ReleaseNoteHeaderId] BIGINT         NULL,
    [SprintName]          NVARCHAR (256) NULL,
    [SprinDescription]    NVARCHAR (MAX) NULL,
    [ReleaseDate]         DATETIME2 (7)  NULL,
    [FileName]            NVARCHAR (500) NULL,
    [DocumentPath]        NVARCHAR (500) NULL,
    [MasterCompanyId]     INT            NULL,
    [CreatedBy]           VARCHAR (256)  NULL,
    [UpdatedBy]           VARCHAR (256)  NULL,
    [CreatedDate]         DATETIME2 (7)  NULL,
    [UpdatedDate]         DATETIME2 (7)  NULL,
    [IsActive]            BIT            NULL,
    [IsDeleted]           BIT            NULL);

