CREATE TABLE [dbo].[VendorRFQPurchaseOrderPart] (
    [VendorRFQPOPartRecordId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorRFQPurchaseOrderId] BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NOT NULL,
    [PartNumber]               VARCHAR (250)   NULL,
    [PartDescription]          VARCHAR (MAX)   NULL,
    [StockType]                VARCHAR (50)    NULL,
    [ManufacturerId]           BIGINT          NOT NULL,
    [Manufacturer]             VARCHAR (250)   NULL,
    [PriorityId]               BIGINT          CONSTRAINT [DF__VendorRFQPurchaseOrderPart__Prior__7961F3F3] DEFAULT ((0)) NOT NULL,
    [Priority]                 VARCHAR (50)    NULL,
    [NeedByDate]               DATETIME2 (7)   NOT NULL,
    [PromisedDate]             DATETIME2 (7)   NULL,
    [ConditionId]              BIGINT          NULL,
    [Condition]                VARCHAR (256)   NULL,
    [QuantityOrdered]          INT             CONSTRAINT [VendorRFQPurchaseOrderPart_QuantityOrdered] DEFAULT ((0)) NOT NULL,
    [UnitCost]                 DECIMAL (18, 2) CONSTRAINT [VendorRFQPurchaseOrderPart_UnitCost] DEFAULT ((0)) NOT NULL,
    [ExtendedCost]             DECIMAL (18, 2) CONSTRAINT [VendorRFQPurchaseOrderPart_ExtendedCost] DEFAULT ((0)) NOT NULL,
    [WorkOrderId]              BIGINT          NULL,
    [WorkOrderNo]              VARCHAR (250)   NULL,
    [SubWorkOrderId]           BIGINT          NULL,
    [SubWorkOrderNo]           VARCHAR (250)   NULL,
    [SalesOrderId]             BIGINT          NULL,
    [SalesOrderNo]             VARCHAR (250)   NULL,
    [ManagementStructureId]    BIGINT          NOT NULL,
    [Level1]                   VARCHAR (200)   NULL,
    [Level2]                   VARCHAR (200)   NULL,
    [Level3]                   VARCHAR (200)   NULL,
    [Level4]                   VARCHAR (200)   NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [MasterCompanyId]          INT             NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [VendorRFQPurchaseOrderPart_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF__VendorRFQPurchaseOrderPart__IsDel__6BBB7E0D] DEFAULT ((0)) NOT NULL,
    [PurchaseOrderId]          BIGINT          NULL,
    [PurchaseOrderNumber]      VARCHAR (50)    NULL,
    [UOMId]                    BIGINT          NULL,
    [UnitOfMeasure]            VARCHAR (50)    NULL,
    CONSTRAINT [PK_VendorRFQPurchaseOrderPart] PRIMARY KEY CLUSTERED ([VendorRFQPOPartRecordId] ASC),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_ManagementStructureId] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_Manufacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_ManufacturerId] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_VendorRFQPurchaseOrderPart_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO





CREATE TRIGGER [dbo].[TrgVendorRFQPurchaseOrderPartAudit]
   ON  [dbo].[VendorRFQPurchaseOrderPart]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO VendorRFQPurchaseOrderPartAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END