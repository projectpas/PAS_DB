CREATE TABLE [dbo].[VendorCheckPaymentAudit] (
    [AuditVendorCheckPaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorCheckPaymentId]      BIGINT        NOT NULL,
    [VendorId]                  BIGINT        NOT NULL,
    [CheckPaymentId]            BIGINT        NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    CONSTRAINT [PK_VendorCheckPaymentAudit] PRIMARY KEY CLUSTERED ([AuditVendorCheckPaymentId] ASC),
    CONSTRAINT [FK_VendorCheckPaymentAudit_VendorCheckPayment] FOREIGN KEY ([VendorCheckPaymentId]) REFERENCES [dbo].[VendorCheckPayment] ([VendorCheckPaymentId])
);

