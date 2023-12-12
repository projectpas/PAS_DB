CREATE TABLE [dbo].[PurchaseOrderPart] (
    [PurchaseOrderPartRecordId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderId]           BIGINT          NOT NULL,
    [ItemMasterId]              BIGINT          NOT NULL,
    [PartNumber]                VARCHAR (250)   NULL,
    [PartDescription]           VARCHAR (MAX)   NULL,
    [AltEquiPartNumberId]       BIGINT          NULL,
    [AltEquiPartNumber]         VARCHAR (250)   NULL,
    [AltEquiPartDescription]    VARCHAR (MAX)   NULL,
    [StockType]                 VARCHAR (50)    NULL,
    [ManufacturerId]            BIGINT          NOT NULL,
    [Manufacturer]              VARCHAR (250)   NULL,
    [PriorityId]                BIGINT          CONSTRAINT [DF__PurchaseO__Prior__7961F3F3] DEFAULT ((0)) NOT NULL,
    [Priority]                  VARCHAR (50)    NULL,
    [NeedByDate]                DATETIME2 (7)   NOT NULL,
    [ConditionId]               BIGINT          NULL,
    [Condition]                 VARCHAR (256)   NULL,
    [QuantityOrdered]           INT             CONSTRAINT [PurchaseOrderPart_QuantityOrdered] DEFAULT ((0)) NOT NULL,
    [QuantityBackOrdered]       INT             CONSTRAINT [PurchaseOrderPart_QuantityBackOrdered] DEFAULT ((0)) NOT NULL,
    [QuantityRejected]          INT             CONSTRAINT [PurchaseOrderPart_QuantityRejected] DEFAULT ((0)) NULL,
    [VendorListPrice]           DECIMAL (18, 2) CONSTRAINT [PurchaseOrderPart_VendorListPrice] DEFAULT ((0)) NOT NULL,
    [DiscountPercent]           BIGINT          CONSTRAINT [PurchaseOrderPart_DiscountPercent] DEFAULT ((0)) NULL,
    [DiscountPerUnit]           DECIMAL (18, 2) CONSTRAINT [PurchaseOrderPart_DiscountPerUnit] DEFAULT ((0)) NOT NULL,
    [DiscountAmount]            DECIMAL (18, 2) CONSTRAINT [PurchaseOrderPart_DiscountAmount] DEFAULT ((0)) NOT NULL,
    [UnitCost]                  DECIMAL (18, 2) CONSTRAINT [PurchaseOrderPart_UnitCost] DEFAULT ((0)) NOT NULL,
    [ExtendedCost]              DECIMAL (18, 2) CONSTRAINT [PurchaseOrderPart_ExtendedCost] DEFAULT ((0)) NOT NULL,
    [FunctionalCurrencyId]      INT             NOT NULL,
    [FunctionalCurrency]        VARCHAR (50)    NULL,
    [ForeignExchangeRate]       DECIMAL (18, 2) CONSTRAINT [PurchaseOrderPart_ForeignExchangeRate] DEFAULT ((0)) NOT NULL,
    [ReportCurrencyId]          INT             NOT NULL,
    [ReportCurrency]            VARCHAR (50)    NULL,
    [WorkOrderId]               BIGINT          NULL,
    [WorkOrderNo]               VARCHAR (250)   NULL,
    [SubWorkOrderId]            BIGINT          NULL,
    [SubWorkOrderNo]            VARCHAR (250)   NULL,
    [RepairOrderId]             BIGINT          NULL,
    [ReapairOrderNo]            VARCHAR (250)   NULL,
    [SalesOrderId]              BIGINT          NULL,
    [SalesOrderNo]              VARCHAR (250)   NULL,
    [ItemTypeId]                INT             NULL,
    [ItemType]                  VARCHAR (250)   NULL,
    [GlAccountId]               BIGINT          NOT NULL,
    [GLAccount]                 VARCHAR (250)   NULL,
    [UOMId]                     BIGINT          NOT NULL,
    [UnitOfMeasure]             VARCHAR (25)    NULL,
    [ManagementStructureId]     BIGINT          NOT NULL,
    [Level1]                    VARCHAR (200)   NULL,
    [Level2]                    VARCHAR (200)   NULL,
    [Level3]                    VARCHAR (200)   NULL,
    [Level4]                    VARCHAR (200)   NULL,
    [ParentId]                  BIGINT          NULL,
    [isParent]                  BIT             NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [POPartSplitUserTypeId]     INT             NULL,
    [POPartSplitUserType]       VARCHAR (100)   NULL,
    [POPartSplitUserId]         BIGINT          NULL,
    [POPartSplitUser]           VARCHAR (100)   NULL,
    [POPartSplitSiteId]         BIGINT          NULL,
    [POPartSplitSiteName]       VARCHAR (500)   NULL,
    [POPartSplitAddressId]      BIGINT          NULL,
    [POPartSplitAddress1]       VARCHAR (100)   NULL,
    [POPartSplitAddress2]       VARCHAR (100)   NULL,
    [POPartSplitAddress3]       VARCHAR (100)   NULL,
    [POPartSplitCity]           VARCHAR (50)    NULL,
    [POPartSplitState]          VARCHAR (50)    NULL,
    [POPartSplitPostalCode]     VARCHAR (20)    NULL,
    [POPartSplitCountryId]      INT             NULL,
    [POPartSplitCountryName]    VARCHAR (200)   NULL,
    [MasterCompanyId]           INT             NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [PurchaseOrderPart_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF__PurchaseO__IsDel__6BBB7E0D] DEFAULT ((0)) NOT NULL,
    [DiscountPercentValue]      DECIMAL (18, 2) CONSTRAINT [PurchaseOrderPart_DiscountPercentValue] DEFAULT ((0)) NULL,
    [EstDeliveryDate]           DATETIME2 (7)   NULL,
    [ExchangeSalesOrderId]      BIGINT          NULL,
    [ExchangeSalesOrderNo]      VARCHAR (250)   NULL,
    [ManufacturerPN]            VARCHAR (150)   NULL,
    [AssetModel]                VARCHAR (30)    NULL,
    [AssetClass]                VARCHAR (50)    NULL,
    [IsLotAssigned]             BIT             NULL,
    [LotId]                     BIGINT          NULL,
    [WorkOrderMaterialsId]      BIGINT          NULL,
    [VendorRFQPOPartRecordId]   BIGINT          NULL,
    [TraceableTo]               BIGINT          NULL,
    [TraceableToName]           VARCHAR (250)   NULL,
    [TraceableToType]           INT             NULL,
    [TagTypeId]                 BIGINT          NULL,
    [TaggedBy]                  BIGINT          NULL,
    [TaggedByType]              INT             NULL,
    [TaggedByName]              VARCHAR (250)   NULL,
    [TaggedByTypeName]          VARCHAR (250)   NULL,
    [TagDate]                   DATETIME2 (7)   NULL,
    CONSTRAINT [PK_PurchaseOrderPart] PRIMARY KEY CLUSTERED ([PurchaseOrderPartRecordId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrder_PurchaseOrderPart] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId]),
    CONSTRAINT [FK_PurchaseOrderPart_Currency] FOREIGN KEY ([FunctionalCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_PurchaseOrderPart_Currency1] FOREIGN KEY ([ReportCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_PurchaseOrderPart_FunctionalCurrencyId] FOREIGN KEY ([FunctionalCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_PurchaseOrderPart_GlAccount] FOREIGN KEY ([GlAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_PurchaseOrderPart_GlAccountId] FOREIGN KEY ([GlAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_PurchaseOrderPart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_PurchaseOrderPart_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_PurchaseOrderPart_PurchaseOrder] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [dbo].[PurchaseOrder] ([PurchaseOrderId]),
    CONSTRAINT [FK_PurchaseOrderPart_RepairOrderId] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_PurchaseOrderPart_ReportCurrencyId] FOREIGN KEY ([ReportCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_PurchaseOrderPart_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_PurchaseOrderPart_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


-- =============================================

create TRIGGER [dbo].[Trg_PurchaseOrderPartAudit]

   ON  [dbo].[PurchaseOrderPart]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO PurchaseOrderPartAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END