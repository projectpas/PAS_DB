CREATE TABLE [dbo].[VendorProformaInvoiceSettingMaster] (
    [VendorProformaInvoiceSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [IsEnforceApproval]              BIT           NOT NULL,
    [Effectivedate]                  DATETIME2 (7) NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_VendorProformaInvoiceSettingMaster_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_VendorProformaInvoiceSettingMaster_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                       BIT           CONSTRAINT [DF_VendorProformaInvoiceSettingMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [DF_VendorProformaInvoiceSettingMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorProformaInvoiceSettingMaster] PRIMARY KEY CLUSTERED ([VendorProformaInvoiceSettingId] ASC)
);

