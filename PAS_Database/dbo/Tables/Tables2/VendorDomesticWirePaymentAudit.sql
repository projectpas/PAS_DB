CREATE TABLE [dbo].[VendorDomesticWirePaymentAudit] (
    [AuditVendorDomesticWirePaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorDomesticWirePaymentId]      BIGINT        NOT NULL,
    [VendorId]                         BIGINT        NOT NULL,
    [DomesticWirePaymentId]            BIGINT        NOT NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NOT NULL,
    [UpdatedBy]                        VARCHAR (256) NOT NULL,
    [CreatedDate]                      DATETIME2 (7) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) NOT NULL,
    [IsActive]                         BIT           NOT NULL,
    [IsDeleted]                        BIT           NOT NULL,
    CONSTRAINT [PK_VendorDomesticWirePaymentAudit] PRIMARY KEY CLUSTERED ([AuditVendorDomesticWirePaymentId] ASC),
    CONSTRAINT [FK_VendorDomesticWirePaymentAudit_VendorDomesticWirePayment] FOREIGN KEY ([VendorDomesticWirePaymentId]) REFERENCES [dbo].[VendorDomesticWirePayment] ([VendorDomesticWirePaymentId])
);

