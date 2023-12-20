CREATE TABLE [dbo].[ItemMasterSettingsAudit] (
    [ItemMasterSettingsAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterSettingsId]      BIGINT        NOT NULL,
    [GlAccountId]               BIGINT        NOT NULL,
    [GLAccount]                 VARCHAR (100) NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (50)  NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_ItemMasterSettingsAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_ItemMasterSettingsAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [DF__ItemMasterSettingsAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [DF__ItemMasterSettingsAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ItemMasterSettingsAudit] PRIMARY KEY CLUSTERED ([ItemMasterSettingsAuditId] ASC)
);

