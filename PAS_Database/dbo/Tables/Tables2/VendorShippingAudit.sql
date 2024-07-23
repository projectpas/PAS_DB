CREATE TABLE [dbo].[VendorShippingAudit] (
    [AuditVendorShippingId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorShippingId]        BIGINT         NOT NULL,
    [VendorId]                BIGINT         NOT NULL,
    [IsPrimary]               BIT            NOT NULL,
    [VendorShippingAddressId] BIGINT         NOT NULL,
    [ShipVia]                 VARCHAR (400)  NULL,
    [ShippingAccountInfo]     VARCHAR (200)  NULL,
    [ShippingId]              VARCHAR (50)   NULL,
    [ShippingURL]             VARCHAR (50)   NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  NOT NULL,
    [IsActive]                BIT            NOT NULL,
    [IsDeleted]               BIT            NOT NULL,
    [ShipViaId]               BIGINT         NULL,
    [ShippingTermsId]         BIGINT         NULL,
    CONSTRAINT [PK_VendorShippingAudit] PRIMARY KEY CLUSTERED ([AuditVendorShippingId] ASC),
    CONSTRAINT [FK_VendorShippingAudit_VendorShipping] FOREIGN KEY ([VendorShippingId]) REFERENCES [dbo].[VendorShipping] ([VendorShippingId])
);



