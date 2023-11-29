CREATE TABLE [dbo].[RepairOrderPart] (
    [RepairOrderPartRecordId]    BIGINT          IDENTITY (1, 1) NOT NULL,
    [RepairOrderId]              BIGINT          NOT NULL,
    [ItemMasterId]               BIGINT          NOT NULL,
    [PartNumber]                 VARCHAR (250)   NULL,
    [PartDescription]            VARCHAR (MAX)   NULL,
    [AltEquiPartNumberId]        BIGINT          NULL,
    [AltEquiPartNumber]          VARCHAR (250)   NULL,
    [AltEquiPartDescription]     VARCHAR (MAX)   NULL,
    [StockType]                  VARCHAR (50)    NULL,
    [ManufacturerId]             BIGINT          NULL,
    [Manufacturer]               VARCHAR (250)   NULL,
    [PriorityId]                 BIGINT          CONSTRAINT [DF__RepairOrd__Prior__7A56182C] DEFAULT ((0)) NOT NULL,
    [Priority]                   VARCHAR (50)    NULL,
    [NeedByDate]                 DATETIME2 (7)   NOT NULL,
    [ConditionId]                BIGINT          NULL,
    [Condition]                  VARCHAR (256)   NULL,
    [QuantityOrdered]            INT             NOT NULL,
    [QuantityBackOrdered]        INT             NULL,
    [QuantityRejected]           INT             NULL,
    [VendorListPrice]            DECIMAL (18, 2) NOT NULL,
    [DiscountPercent]            DECIMAL (20, 2) NULL,
    [DiscountPerUnit]            DECIMAL (20, 2) NULL,
    [DiscountAmount]             DECIMAL (20, 2) NULL,
    [UnitCost]                   DECIMAL (20, 2) NULL,
    [ExtendedCost]               DECIMAL (20, 2) NULL,
    [FunctionalCurrencyId]       INT             NOT NULL,
    [FunctionalCurrency]         VARCHAR (50)    NULL,
    [ForeignExchangeRate]        DECIMAL (18, 2) NOT NULL,
    [ReportCurrencyId]           INT             NOT NULL,
    [ReportCurrency]             VARCHAR (50)    NULL,
    [StockLineId]                BIGINT          NULL,
    [StockLineNumber]            VARCHAR (50)    NULL,
    [ControlId]                  VARCHAR (50)    NULL,
    [ControlNumber]              VARCHAR (50)    NULL,
    [PurchaseOrderNumber]        VARCHAR (50)    NULL,
    [WorkOrderId]                BIGINT          NULL,
    [WorkOrderNo]                VARCHAR (250)   NULL,
    [SubWorkOrderId]             BIGINT          NULL,
    [SubWorkOrderNo]             VARCHAR (250)   NULL,
    [SalesOrderId]               BIGINT          NULL,
    [SalesOrderNo]               VARCHAR (250)   NULL,
    [ItemTypeId]                 INT             NULL,
    [ItemType]                   VARCHAR (100)   NULL,
    [GlAccountId]                BIGINT          NOT NULL,
    [GLAccount]                  VARCHAR (250)   NULL,
    [UOMId]                      BIGINT          NULL,
    [UnitOfMeasure]              VARCHAR (250)   NULL,
    [ManagementStructureId]      BIGINT          NOT NULL,
    [Level1]                     VARCHAR (200)   NULL,
    [Level2]                     VARCHAR (200)   NULL,
    [Level3]                     VARCHAR (200)   NULL,
    [Level4]                     VARCHAR (200)   NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [ParentId]                   BIGINT          NULL,
    [IsParent]                   BIT             NULL,
    [RoPartSplitUserTypeId]      INT             NULL,
    [RoPartSplitUserType]        VARCHAR (200)   NULL,
    [RoPartSplitUserId]          BIGINT          NULL,
    [RoPartSplitUser]            VARCHAR (200)   NULL,
    [RoPartSplitSiteId]          BIGINT          NULL,
    [RoPartSplitSiteName]        VARCHAR (200)   NULL,
    [RoPartSplitAddressId]       BIGINT          NULL,
    [RoPartSplitAddress1]        VARCHAR (200)   NULL,
    [RoPartSplitAddress2]        VARCHAR (200)   NULL,
    [RoPartSplitAddress3]        VARCHAR (200)   NULL,
    [RoPartSplitCity]            VARCHAR (50)    NULL,
    [RoPartSplitStateOrProvince] VARCHAR (50)    NULL,
    [RoPartSplitPostalCode]      VARCHAR (20)    NULL,
    [RoPartSplitCountryId]       INT             NULL,
    [RoPartSplitCountry]         VARCHAR (200)   NULL,
    [MasterCompanyId]            INT             NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   NULL,
    [IsActive]                   BIT             CONSTRAINT [DF__RepairOrd__IsAct__00CA12DE] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             CONSTRAINT [DF__RepairOrd__IsDel__34563A8A] DEFAULT ((0)) NOT NULL,
    [RevisedPartId]              BIGINT          NULL,
    [RevisedPartNumber]          VARCHAR (250)   NULL,
    [WorkPerformedId]            BIGINT          NULL,
    [WorkPerformed]              VARCHAR (250)   NULL,
    [EstRecordDate]              DATETIME2 (7)   NULL,
    [VendorQuoteNoId]            BIGINT          NULL,
    [VendorQuoteNo]              VARCHAR (250)   NULL,
    [VendorQuoteDate]            DATETIME2 (7)   NULL,
    [ACTailNum]                  VARCHAR (250)   NULL,
    [QuantityReserved]           INT             DEFAULT ((0)) NULL,
    [IsAsset]                    BIT             DEFAULT ((0)) NULL,
    [SerialNumber]               VARCHAR (30)    NULL,
    [ManufacturerPN]             VARCHAR (150)   NULL,
    [AssetModel]                 VARCHAR (30)    NULL,
    [AssetClass]                 VARCHAR (50)    NULL,
    [IsLotAssigned]              BIT             NULL,
    [LotId]                      BIGINT          NULL,
    CONSTRAINT [PK_RepairOrderpart] PRIMARY KEY CLUSTERED ([RepairOrderPartRecordId] ASC),
    CONSTRAINT [FK_RepairOrderPart_FunctionalCurrency] FOREIGN KEY ([FunctionalCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_RepairOrderPart_GlAccount] FOREIGN KEY ([GlAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_RepairOrderPart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_RepairOrderPart_PriorityId] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_RepairOrderPart_RepairOrderPart] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_RepairOrderPart_ReportCurrency] FOREIGN KEY ([ReportCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_RepairOrderPart_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_RepairOrderPart_SubWorkOrderId] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_RepairOrderPart_WorkOrderId] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);








GO


-- =============================================

create TRIGGER [dbo].[Trg_RepairOrderPartAudit]

   ON  [dbo].[RepairOrderPart]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO RepairOrderPartAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END