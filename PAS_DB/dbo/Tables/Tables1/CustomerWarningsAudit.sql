CREATE TABLE [dbo].[CustomerWarningsAudit] (
    [CustomerWarningsAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerWarningsId]      BIGINT        NOT NULL,
    [CustomerId]              BIGINT        NOT NULL,
    [IsAllow]                 BIT           NOT NULL,
    [IsWarning]               BIT           NOT NULL,
    [IsRestrict]              BIT           NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) NOT NULL,
    [IsActive]                BIT           NOT NULL,
    [IsDeleted]               BIT           NOT NULL,
    CONSTRAINT [PK_CustomerWarningsAudit] PRIMARY KEY CLUSTERED ([CustomerWarningsAuditId] ASC),
    CONSTRAINT [FK_CustomerWarningsAudit_CustomerWarnings] FOREIGN KEY ([CustomerWarningsId]) REFERENCES [dbo].[CustomerWarnings] ([CustomerWarningsId])
);

