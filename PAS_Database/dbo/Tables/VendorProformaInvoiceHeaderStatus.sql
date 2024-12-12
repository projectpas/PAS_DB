CREATE TABLE [dbo].[VendorProformaInvoiceHeaderStatus] (
    [VendorProformaInvoiceHeaderStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]                         VARCHAR (256) NOT NULL,
    [MasterCompanyId]                     INT           NOT NULL,
    [CreatedBy]                           VARCHAR (256) NOT NULL,
    [CreatedDate]                         VARCHAR (256) NOT NULL,
    [UpdatedBy]                           VARCHAR (256) NOT NULL,
    [UpdatedDate]                         VARCHAR (256) NOT NULL,
    [IsActive]                            BIT           CONSTRAINT [VendorProformaInvoiceHeaderStatus_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT           CONSTRAINT [DF_VendorProformaInvoiceHeaderStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorProformaInvoiceHeaderStatus] PRIMARY KEY CLUSTERED ([VendorProformaInvoiceHeaderStatusId] ASC)
);

