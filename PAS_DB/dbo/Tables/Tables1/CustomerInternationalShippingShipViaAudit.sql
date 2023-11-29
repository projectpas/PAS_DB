CREATE TABLE [dbo].[CustomerInternationalShippingShipViaAudit] (
    [CustomerInternationalShippingShipViaAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerInternationalShippingShipViaId]      BIGINT         NOT NULL,
    [CustomerInternationalShippingId]             BIGINT         NOT NULL,
    [CustomerId]                                  BIGINT         NOT NULL,
    [ShipVia]                                     VARCHAR (400)  NULL,
    [ShippingAccountInfo]                         VARCHAR (200)  NULL,
    [Memo]                                        NVARCHAR (MAX) NULL,
    [MasterCompanyId]                             INT            NOT NULL,
    [CreatedBy]                                   VARCHAR (256)  NULL,
    [UpdatedBy]                                   VARCHAR (256)  NULL,
    [CreatedDate]                                 DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                                 DATETIME2 (7)  NOT NULL,
    [IsActive]                                    BIT            NULL,
    [IsDeleted]                                   BIT            NULL,
    [IsPrimary]                                   BIT            DEFAULT ((0)) NULL,
    [ShipViaId]                                   BIGINT         NULL,
    CONSTRAINT [PK_ShippingViaDetailsAudit] PRIMARY KEY CLUSTERED ([CustomerInternationalShippingShipViaAuditId] ASC)
);



