CREATE TABLE [dbo].[VendorStatusSettingsAudit] (
    [VendorStatusSettingsAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorStatusSettingsId]      BIGINT        NOT NULL,
    [Rating]                      VARCHAR (100) NULL,
    [OnTimeDelivery]              VARCHAR (100) NULL,
    [Description]                 VARCHAR (256) NULL,
    [StatusId]                    BIGINT        NULL,
    [IsAuditWarning]              BIT           NULL,
    [IsAuditRestriction]          BIT           NULL,
    [VarianceDays]                VARCHAR (100) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_VendorStatusSettingsAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_VendorStatusSettingsAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_VendorStatusSettingsAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_VendorStatusSettingsAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorStatusSettingsAudit] PRIMARY KEY CLUSTERED ([VendorStatusSettingsAuditId] ASC)
);

