CREATE TABLE [dbo].[VendorPaymentMethodAudit] (
    [AuditVendorPaymentMethodId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [VendorPaymentMethodId]      TINYINT       NOT NULL,
    [Description]                VARCHAR (250) NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    CONSTRAINT [PK_VendorPaymentMethodAudit] PRIMARY KEY CLUSTERED ([AuditVendorPaymentMethodId] ASC),
    CONSTRAINT [FK_VendorPaymentMethodAudit_VendorPaymentMethod] FOREIGN KEY ([VendorPaymentMethodId]) REFERENCES [dbo].[VendorPaymentMethod] ([VendorPaymentMethodId])
);

