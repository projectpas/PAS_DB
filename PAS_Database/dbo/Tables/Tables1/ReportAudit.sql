CREATE TABLE [dbo].[ReportAudit] (
    [AuditReportId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [ReportId]        BIGINT         NOT NULL,
    [ReportName]      VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_ReportAudit] PRIMARY KEY CLUSTERED ([AuditReportId] ASC)
);

