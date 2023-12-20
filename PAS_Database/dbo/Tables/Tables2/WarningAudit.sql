CREATE TABLE [dbo].[WarningAudit] (
    [WarningAuditId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [WarningId]       BIGINT        NOT NULL,
    [Description]     VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_WarningAudit] PRIMARY KEY CLUSTERED ([WarningAuditId] ASC)
);

