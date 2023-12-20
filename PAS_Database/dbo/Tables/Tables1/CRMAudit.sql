CREATE TABLE [dbo].[CRMAudit] (
    [CRMAuditId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [CRMId]           BIGINT          NOT NULL,
    [CustomerId]      BIGINT          NOT NULL,
    [ReportId]        BIGINT          NULL,
    [YTDRevenueTY]    DECIMAL (18, 2) NULL,
    [YTDRevenueLY]    DECIMAL (18, 2) NULL,
    [CreditLimit]     DECIMAL (18, 2) NULL,
    [CreditTermsId]   INT             NULL,
    [DSO]             VARCHAR (256)   NULL,
    [Warnings]        VARCHAR (256)   NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   NOT NULL,
    [IsActive]        BIT             NOT NULL,
    [IsDeleted]       BIT             NOT NULL,
    CONSTRAINT [PK_CRMAudit] PRIMARY KEY CLUSTERED ([CRMAuditId] ASC),
    CONSTRAINT [FK_CRMAudit_CRM] FOREIGN KEY ([CRMId]) REFERENCES [dbo].[CRM] ([CRMId])
);

