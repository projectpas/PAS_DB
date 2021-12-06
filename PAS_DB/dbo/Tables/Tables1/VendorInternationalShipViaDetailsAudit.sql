CREATE TABLE [dbo].[VendorInternationalShipViaDetailsAudit] (
    [AuditVendorInternationalShipViaDetailsId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorInternationalShipViaDetailsId]      BIGINT         NOT NULL,
    [VendorInternationalShippingId]            BIGINT         NOT NULL,
    [ShipVia]                                  VARCHAR (100)  NULL,
    [ShippingAccountInfo]                      VARCHAR (200)  NULL,
    [Memo]                                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]                          INT            NOT NULL,
    [IsPrimary]                                BIT            NOT NULL,
    [CreatedBy]                                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                                VARCHAR (256)  NOT NULL,
    [CreatedDate]                              DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                              DATETIME2 (7)  NOT NULL,
    [IsActive]                                 BIT            NOT NULL,
    [IsDeleted]                                BIT            NOT NULL,
    [ShipViaId]                                BIGINT         NULL,
    CONSTRAINT [PK_VendorInternationalShipViaDetailsAudit] PRIMARY KEY CLUSTERED ([AuditVendorInternationalShipViaDetailsId] ASC),
    CONSTRAINT [FK_VendorInternationalShipViaDetailsAudit_VendorInternationalShipViaDetails] FOREIGN KEY ([VendorInternationalShipViaDetailsId]) REFERENCES [dbo].[VendorInternationalShipViaDetails] ([VendorInternationalShipViaDetailsId])
);

