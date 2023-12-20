CREATE TABLE [dbo].[ReportMaster] (
    [ModuleId]    BIGINT         NOT NULL,
    [ReportTitle] NVARCHAR (100) NOT NULL,
    [SPname]      NVARCHAR (200) NOT NULL,
    [BredCum]     NVARCHAR (200) NOT NULL,
    CONSTRAINT [PK_ReportMaster] PRIMARY KEY CLUSTERED ([ModuleId] ASC)
);

