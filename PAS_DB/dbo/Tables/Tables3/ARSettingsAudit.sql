CREATE TABLE [dbo].[ARSettingsAudit] (
    [ARSettingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ARSettingId]      BIGINT        NOT NULL,
    [TradeARAccount]   BIGINT        NOT NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    [IsActive]         BIT           NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    CONSTRAINT [PK_ARSettingsAudit] PRIMARY KEY CLUSTERED ([ARSettingAuditId] ASC)
);

