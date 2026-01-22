CREATE TABLE [dbo].[VendorProformaInvoiceSettingMasterAudit] (
    [VendorProformaInvoiceSettingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorProformaInvoiceSettingId]      BIGINT        NOT NULL,
    [IsEnforceApproval]                   BIT           NOT NULL,
    [Effectivedate]                       DATETIME2 (7) NULL,
    [MasterCompanyId]                     INT           NOT NULL,
    [CreatedBy]                           VARCHAR (256) NOT NULL,
    [CreatedDate]                         DATETIME2 (7) CONSTRAINT [DF_VendorProformaInvoiceSettingMasterAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                           VARCHAR (256) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7) CONSTRAINT [DF_VendorProformaInvoiceSettingMasterAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                            BIT           CONSTRAINT [DF_VendorProformaInvoiceSettingMasterAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT           CONSTRAINT [DF_VendorProformaInvoiceSettingMasterAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorProformaInvoiceSettingMasterAudit] PRIMARY KEY CLUSTERED ([VendorProformaInvoiceSettingAuditId] ASC)
);

