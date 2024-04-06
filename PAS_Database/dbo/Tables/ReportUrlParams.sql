CREATE TABLE [dbo].[ReportUrlParams] (
    [Id]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [ReportURL]       VARCHAR (MAX) NULL,
    [ReportName]      VARCHAR (100) NULL,
    [MasterCompanyId] BIGINT        NOT NULL,
    [CreatedBy]       VARCHAR (30)  NOT NULL,
    [CreatedDate]     DATETIME      NOT NULL,
    CONSTRAINT [PK_ReportUrlParams] PRIMARY KEY CLUSTERED ([Id] ASC)
);

