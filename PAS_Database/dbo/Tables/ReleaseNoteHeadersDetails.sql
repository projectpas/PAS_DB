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

