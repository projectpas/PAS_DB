CREATE TABLE [dbo].[ManualJournalSettingMasterAudit] (
    [AuditManualJournalSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManualJournalSettingId]      BIGINT        NOT NULL,
    [IsEnforceApproval]           BIT           CONSTRAINT [DF_ManualJournalSettingMasterAudit_IsEnforceApproval] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ManualJournalSettingMasterAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ManualJournalSettingMasterAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_ManualJournalSettingMasterAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_ManualJournalSettingMasterAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Effectivedate]               DATETIME2 (7) NULL,
    CONSTRAINT [PK_ManualJournalSettingMasterAudit] PRIMARY KEY CLUSTERED ([AuditManualJournalSettingId] ASC)
);

