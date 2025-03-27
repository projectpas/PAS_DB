CREATE TABLE [dbo].[ByPassRequestUrl] (
    [ByPassRequestUrlId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [URLPattern]         NVARCHAR (255) NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_ByPassRequestUrl_CreatedDate] DEFAULT (getutcdate()) NULL,
    [CreatedBy]          VARCHAR (50)   NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_ByPassRequestUrl_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedBy]          VARCHAR (50)   NULL,
    CONSTRAINT [PK_ByPassRequestUrl] PRIMARY KEY CLUSTERED ([ByPassRequestUrlId] ASC)
);

