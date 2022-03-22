CREATE TABLE [dbo].[VendorInternationalShippingAudit] (
    [AuditVendorInternationalShippingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorInternationalShippingId]      BIGINT          NOT NULL,
    [VendorId]                           BIGINT          NOT NULL,
    [ExportLicense]                      VARCHAR (200)   NULL,
    [StartDate]                          DATETIME2 (7)   NULL,
    [Amount]                             DECIMAL (18, 3) NULL,
    [IsPrimary]                          BIT             NULL,
    [Description]                        VARCHAR (250)   NULL,
    [ExpirationDate]                     DATETIME        NULL,
    [ShipToCountryId]                    SMALLINT        NULL,
    [MasterCompanyId]                    INT             NOT NULL,
    [CreatedBy]                          VARCHAR (256)   NULL,
    [UpdatedBy]                          VARCHAR (256)   NULL,
    [CreatedDate]                        DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   NOT NULL,
    [IsActive]                           BIT             NOT NULL,
    [IsDeleted]                          BIT             NOT NULL,
    CONSTRAINT [PK_VendorInternationalShippingAudit] PRIMARY KEY CLUSTERED ([AuditVendorInternationalShippingId] ASC),
    CONSTRAINT [FK_VendorInternationalShippingAudit_VendorInternationalShipping] FOREIGN KEY ([VendorInternationalShippingId]) REFERENCES [dbo].[VendorInternationalShipping] ([VendorInternationalShippingId])
);

