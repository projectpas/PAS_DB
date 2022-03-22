CREATE TABLE [dbo].[VendorPaymentAudit] (
    [AuditVendorPaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorPaymentId]      BIGINT        NOT NULL,
    [VendorId]             BIGINT        NOT NULL,
    [DefaultPaymentMethod] TINYINT       NOT NULL,
    [BankName]             VARCHAR (100) NULL,
    [BankAddressId]        BIGINT        NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    CONSTRAINT [PK_VendorPaymentAudit] PRIMARY KEY CLUSTERED ([AuditVendorPaymentId] ASC),
    CONSTRAINT [FK_VendorPaymentAudit_VendorPayment] FOREIGN KEY ([VendorPaymentId]) REFERENCES [dbo].[VendorPayment] ([VendorPaymentId])
);

