CREATE TABLE [dbo].[NonPOSettingMaster] (
    [NonPOSettingId]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [IsEnforceNonPoApproval]      BIT           NOT NULL,
    [Effectivedate]               DATETIME2 (7) NULL,
    [IsRestrictInvoiceFutureDate] BIT           NULL,
    [DefaultGlAccountId]          BIGINT        NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_NonPOSettingMaster_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_NonPOSettingMaster_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_NonPOSettingMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_NonPOSettingMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_NonPOSettingMaster] PRIMARY KEY CLUSTERED ([NonPOSettingId] ASC)
);

