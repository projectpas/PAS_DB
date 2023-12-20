CREATE TABLE [dbo].[WorkOrderReservedStock] (
    [WOReservedStockId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialsId] BIGINT        NOT NULL,
    [StockLIneId]          BIGINT        NOT NULL,
    [ConditionId]          BIGINT        NOT NULL,
    [ItemMasterId]         BIGINT        NOT NULL,
    [Quantity]             INT           NOT NULL,
    [AltPartMasterPartId]  BIGINT        NULL,
    [EquPartMasterPartId]  BIGINT        NULL,
    [IsAltPart]            BIT           NULL,
    [IsEquPart]            BIT           NULL,
    [ReservedById]         BIGINT        NOT NULL,
    [ReservedDate]         DATETIME2 (7) NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkOrderReservedStock_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkOrderReservedStock_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_WorkOrderReservedStock_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_WorkOrderReservedStock_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderReservedStock] PRIMARY KEY CLUSTERED ([WOReservedStockId] ASC),
    CONSTRAINT [FK_WorkOrderReservedStock_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderReservedStock_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderReservedStock_ReservedById] FOREIGN KEY ([ReservedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderReservedStock_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_WorkOrderReservedStock_WorkOrderMaterials] FOREIGN KEY ([WorkOrderMaterialsId]) REFERENCES [dbo].[WorkOrderMaterials] ([WorkOrderMaterialsId]),
    CONSTRAINT [FK_WorkOrderReservedStockk_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderReservedStockAudit]

   ON  [dbo].[WorkOrderReservedStock]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderReservedStockAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END