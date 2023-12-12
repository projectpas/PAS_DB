CREATE TABLE [dbo].[MASTERTABLEYESNO] (
    [Id]              BIGINT         NOT NULL,
    [Value]           NVARCHAR (100) NOT NULL,
    [MasterCompanyId] INT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_MASTERTABLEYESNO_ID] PRIMARY KEY CLUSTERED ([Id] ASC)
);

