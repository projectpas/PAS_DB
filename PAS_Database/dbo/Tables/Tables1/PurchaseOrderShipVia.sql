CREATE TABLE [dbo].[PurchaseOrderShipVia] (
    [POShipViaId]       BIGINT          IDENTITY (1, 1) NOT NULL,
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
    [ShipVia]           VARCHAR (400)   NULL,
    [IsActive]          BIT             DEFAULT ((1)) NOT NULL,
    [MasterCompanyId]   INT             NOT NULL,
    [IsDeleted]         BIT             DEFAULT ((0)) NOT NULL,
    [ShippingViaId]     BIGINT          NULL,
    CONSTRAINT [PK_PurchaseOrderShipVia] PRIMARY KEY CLUSTERED ([POShipViaId] ASC),
    CONSTRAINT [FK_PurchaseOrderShipVia_PurchaseOrder] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [dbo].[PurchaseOrder] ([PurchaseOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_PurchaseOrderShipViaAudit]

   ON  [dbo].[PurchaseOrderShipVia]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO PurchaseOrderShipViaAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END