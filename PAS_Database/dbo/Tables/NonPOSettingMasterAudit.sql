CREATE TABLE [dbo].[NonPOSettingMasterAudit] (
    [NonPOSettingAuditId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [NonPOSettingId]              BIGINT        NOT NULL,
    [IsEnforceNonPoApproval]      BIT           NOT NULL,
    [Effectivedate]               DATETIME2 (7) NULL,
    [IsRestrictInvoiceFutureDate] BIT           NOT NULL,
    [DefaultGlAccountId]          BIGINT        NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_NonPOSettingMasterAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_NonPOSettingMasterAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_NonPOSettingMasterAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_NonPOSettingMasterAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [UnitOfMeasureId]             BIGINT        NULL,
    [Quantity]                    INT           NULL,
    CONSTRAINT [PK_NonPOSettingMasterAudit] PRIMARY KEY CLUSTERED ([NonPOSettingAuditId] ASC)
);





