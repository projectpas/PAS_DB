CREATE TABLE [dbo].[WorkOrderMaterialStockLine] (
    [WOMStockLineId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialsId] BIGINT          NOT NULL,
    [StockLineId]          BIGINT          NOT NULL,
    [ItemMasterId]         BIGINT          NOT NULL,
    [ConditionId]          BIGINT          NOT NULL,
    [Quantity]             INT             CONSTRAINT [DF_WorkOrderMaterialStockLine_Quantity] DEFAULT ((0)) NULL,
    [QtyReserved]          INT             CONSTRAINT [DF_WorkOrderMaterialStockLine_QtyReserved] DEFAULT ((0)) NULL,
    [QtyIssued]            INT             CONSTRAINT [DF_WorkOrderMaterialStockLine_QtyIssued] DEFAULT ((0)) NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMaterialStockLine_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMaterialStockLine_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT             CONSTRAINT [DF_WorkOrderMaterialStockLine_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [DF_WorkOrderMaterialStockLine_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AltPartMasterPartId]  BIGINT          NULL,
    [EquPartMasterPartId]  BIGINT          NULL,
    [IsAltPart]            BIT             NULL,
    [IsEquPart]            BIT             NULL,
    [UnitCost]             DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMaterialStockLine_UnitCost] DEFAULT ((0)) NULL,
    [ExtendedCost]         DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMaterialStockLine_ExtendedCost] DEFAULT ((0)) NULL,
    [UnitPrice]            DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMaterialStockLine_UnitPrice] DEFAULT ((0)) NULL,
    [ExtendedPrice]        DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMaterialStockLine_ExtendedPrice] DEFAULT ((0)) NULL,
    [ProvisionId]          INT             DEFAULT ((1)) NOT NULL,
    [RepairOrderId]        BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderMaterialStockLine] PRIMARY KEY CLUSTERED ([WOMStockLineId] ASC),
    CONSTRAINT [FK_WorkOrderMaterialStockLine_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderMaterialStockLine_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderMaterialStockLine_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderMaterialStockLine_ProvisionId] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[Provision] ([ProvisionId]),
    CONSTRAINT [FK_WorkOrderMaterialStockLine_RepairOrderId] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_WorkOrderMaterialStockLine_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_WorkOrderMaterialStockLine_WorkOrderMaterials] FOREIGN KEY ([WorkOrderMaterialsId]) REFERENCES [dbo].[WorkOrderMaterials] ([WorkOrderMaterialsId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderMaterialStockLineAudit]

   ON  [dbo].[WorkOrderMaterialStockLine]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderMaterialStockLineAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END