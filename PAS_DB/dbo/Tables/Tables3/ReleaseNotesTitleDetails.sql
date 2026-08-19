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

