CREATE TABLE [dbo].[VendorPaymentSettingMasterAudit] (
    [VendorPaymentSettingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorPaymentSettingId]      BIGINT        NOT NULL,
    [IsEnforceApproval]           BIT           NOT NULL,
    [Effectivedate]               DATETIME2 (7) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) NOT NULL,
    [IsActive]                    BIT           NOT NULL,
    [IsDeleted]                   BIT           NOT NULL,
    CONSTRAINT [PK_VendorPaymentSettingMasterAudit] PRIMARY KEY CLUSTERED ([VendorPaymentSettingAuditId] ASC)
);

