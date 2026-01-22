CREATE TABLE [dbo].[VendorInternationlWirePaymentAudit] (
    [AuditVendorInternationalWirePaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorInternationalWirePaymentId]      BIGINT        NOT NULL,
    [VendorId]                              BIGINT        NOT NULL,
    [InternationalWirePaymentId]            BIGINT        NOT NULL,
    [MasterCompanyId]                       INT           NOT NULL,
    [CreatedBy]                             VARCHAR (256) NOT NULL,
    [UpdatedBy]                             VARCHAR (256) NOT NULL,
    [CreatedDate]                           DATETIME2 (7) NOT NULL,
    [UpdatedDate]                           DATETIME2 (7) NOT NULL,
    [IsActive]                              BIT           NOT NULL,
    [IsDeleted]                             BIT           NOT NULL,
    CONSTRAINT [PK_VendorInternationlWirePaymentAudit] PRIMARY KEY CLUSTERED ([AuditVendorInternationalWirePaymentId] ASC),
    CONSTRAINT [FK_VendorInternationlWirePaymentAudit_VendorInternationlWirePayment] FOREIGN KEY ([VendorInternationalWirePaymentId]) REFERENCES [dbo].[VendorInternationlWirePayment] ([VendorInternationalWirePaymentId])
);

