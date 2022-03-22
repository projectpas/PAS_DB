CREATE TABLE [dbo].[CustomerDomensticShippingShipViaAudit] (
    [CustomerDomensticShippingShipViaAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerDomensticShippingShipViaId]      BIGINT         NOT NULL,
    [CustomerId]                              BIGINT         NOT NULL,
    [CustomerDomensticShippingId]             BIGINT         NOT NULL,
    [IsPrimary]                               BIT            CONSTRAINT [DF__CustomerS__IsPri__19F67EB2] DEFAULT ((0)) NOT NULL,
    [ShipVia]                                 VARCHAR (30)   NULL,
    [ShippingAccountInfo]                     VARCHAR (200)  NULL,
    [Memo]                                    NVARCHAR (MAX) NULL,
    [MasterCompanyId]                         INT            NOT NULL,
    [CreatedBy]                               VARCHAR (256)  NOT NULL,
    [UpdatedBy]                               VARCHAR (256)  NOT NULL,
    [CreatedDate]                             DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                             DATETIME2 (7)  NOT NULL,
    [IsActive]                                BIT            CONSTRAINT [CustomerShippingAudit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                               BIT            CONSTRAINT [CustomerShippingAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ShipViaId]                               BIGINT         NULL,
    CONSTRAINT [PK_CustomerShippingAudit] PRIMARY KEY CLUSTERED ([CustomerDomensticShippingShipViaAuditId] ASC),
    CONSTRAINT [FK_CustomerShippingAudit_CustomerShipping] FOREIGN KEY ([CustomerDomensticShippingShipViaId]) REFERENCES [dbo].[CustomerDomensticShippingShipVia] ([CustomerDomensticShippingShipViaId])
);

