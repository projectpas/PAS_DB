CREATE TABLE [dbo].[CycleCountSettingMasterAudit] (
    [CycleCountSettingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CycleCountSettingId]      BIGINT        NOT NULL,
    [IsEnforceApproval]        BIT           CONSTRAINT [DF_CycleCountSettingMasterAudit_IsEnforceApproval] DEFAULT ((0)) NOT NULL,
    [StatusId]                 BIGINT        NOT NULL,
    [Effectivedate]            DATETIME2 (7) NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_CycleCountSettingMasterAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_CycleCountSettingMasterAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_CycleCountSettingMasterAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF_CycleCountSettingMasterAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CycleCountSettingMasterAudit] PRIMARY KEY CLUSTERED ([CycleCountSettingAuditId] ASC),
    CONSTRAINT [FK_CycleCountSettingMasterAudit_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

