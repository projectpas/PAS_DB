CREATE TABLE [dbo].[PurchaseOrderShipViaAudit] (
    [POShipViaAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [POShipViaId]       BIGINT          NOT NULL,
    [PurchaseOrderId]   BIGINT          NOT NULL,
    [UserType]          INT             NOT NULL,
    [ReferenceId]       BIGINT          NOT NULL,
    [ShipViaId]         BIGINT          NOT NULL,
    [ShippingCost]      DECIMAL (20, 3) NOT NULL,
    [HandlingCost]      DECIMAL (20, 3) NOT NULL,
    [IsOnlyPOShipVia]   BIT             NULL,
    [CreatedBy]         VARCHAR (256)   NOT NULL,
    [UpdatedBy]         VARCHAR (256)   NOT NULL,
    [CreatedDate]       DATETIME2 (7)   NOT NULL,
    [UpdatedDate]       DATETIME2 (7)   NOT NULL,
    [ShippingAccountNo] VARCHAR (100)   NULL,
    [ShipVia]           VARCHAR (100)   NULL,
    [IsActive]          BIT             NOT NULL,
    [MasterCompanyId]   INT             NOT NULL,
    [IsDeleted]         BIT             NOT NULL,
    [ShippingViaId]     BIGINT          NULL,
    CONSTRAINT [PK_POShipViaAudit] PRIMARY KEY CLUSTERED ([POShipViaAuditId] ASC)
);

