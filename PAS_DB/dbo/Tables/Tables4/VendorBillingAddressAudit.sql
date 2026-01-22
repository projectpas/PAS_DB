CREATE TABLE [dbo].[VendorBillingAddressAudit] (
    [AuditVendorBillingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorBillingAddressId]      BIGINT        NOT NULL,
    [VendorId]                    BIGINT        NOT NULL,
    [AddressId]                   BIGINT        NOT NULL,
    [IsPrimary]                   BIT           NOT NULL,
    [SiteName]                    VARCHAR (100) NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) NOT NULL,
    [IsActive]                    BIT           NOT NULL,
    [IsDeleted]                   BIT           NOT NULL,
    [IsAddressForPayment]         BIT           NULL,
    [ContactTagId]                BIGINT        NULL,
    [Attention]                   VARCHAR (250) NULL,
    CONSTRAINT [PK_VendorBillingAddressAudit] PRIMARY KEY CLUSTERED ([AuditVendorBillingAddressId] ASC),
    CONSTRAINT [FK_VendorBillingAddressAudit_VendorBillingAddress] FOREIGN KEY ([VendorBillingAddressId]) REFERENCES [dbo].[VendorBillingAddress] ([VendorBillingAddressId])
);

