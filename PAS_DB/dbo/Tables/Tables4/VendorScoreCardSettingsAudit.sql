CREATE TABLE [dbo].[VendorScoreCardSettingsAudit] (
    [VendorScoreCardSettingsAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorScoreCardSettingsId]      BIGINT        NOT NULL,
    [Rating]                         VARCHAR (100) NULL,
    [OnTimeDelivery]                 VARCHAR (100) NULL,
    [Description]                    VARCHAR (100) NULL,
    [StatusId]                       BIGINT        NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_VendorScoreCardSettingsAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_VendorScoreCardSettingsAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT           CONSTRAINT [DF_VendorScoreCardSettingsAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [DF_VendorScoreCardSettingsAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorScoreCardSettingsAudit] PRIMARY KEY CLUSTERED ([VendorScoreCardSettingsAuditId] ASC)
);

