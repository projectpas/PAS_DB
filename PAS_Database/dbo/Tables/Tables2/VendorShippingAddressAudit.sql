CREATE TABLE [dbo].[VendorShippingAddressAudit] (
    [AuditVendorShippingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorShippingAddressId]      BIGINT        NOT NULL,
    [VendorId]                     BIGINT        NOT NULL,
    [AddressId]                    BIGINT        NOT NULL,
    [IsPrimary]                    BIT           NOT NULL,
    [SiteName]                     VARCHAR (100) NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) NOT NULL,
    [IsActive]                     BIT           NOT NULL,
    [IsDeleted]                    BIT           NOT NULL,
    [ContactTagId]                 BIGINT        NULL,
    [Attention]                    VARCHAR (250) NULL,
    CONSTRAINT [PK_VendorShippingAddressAudit] PRIMARY KEY CLUSTERED ([AuditVendorShippingAddressId] ASC),
    CONSTRAINT [FK_VendorShippingAddressAudit_VendorShippingAddress] FOREIGN KEY ([VendorShippingAddressId]) REFERENCES [dbo].[VendorShippingAddress] ([VendorShippingAddressId])
);

