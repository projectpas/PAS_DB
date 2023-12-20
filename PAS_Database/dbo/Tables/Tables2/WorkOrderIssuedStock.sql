CREATE TABLE [dbo].[WorkOrderIssuedStock] (
    [WOIssuedStockId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialsId] BIGINT        NOT NULL,
    [StockLIneId]          BIGINT        NOT NULL,
    [ConditionId]          BIGINT        NOT NULL,
    [ItemMasterId]         BIGINT        NOT NULL,
    [Quantity]             INT           NOT NULL,
    [AltPartMasterPartId]  BIGINT        NULL,
    [EquPartMasterPartId]  BIGINT        NULL,
    [IsAltPart]            BIT           NULL,
    [IsEquPart]            BIT           NULL,
    [IssuedById]           BIGINT        NOT NULL,
    [IssuedDate]           DATETIME2 (7) NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkOrderIssuedStock_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkOrderIssuedStock_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_WorkOrderIssuedStock_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_WorkOrderIssuedStock_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderIssuedStock] PRIMARY KEY CLUSTERED ([WOIssuedStockId] ASC),
    CONSTRAINT [FK_WorkOrderIssuedStock_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderIssuedStock_IssuedById] FOREIGN KEY ([IssuedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderIssuedStock_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderIssuedStock_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderIssuedStock_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_WorkOrderIssuedStock_WorkOrderMaterials] FOREIGN KEY ([WorkOrderMaterialsId]) REFERENCES [dbo].[WorkOrderMaterials] ([WorkOrderMaterialsId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderIssuedStockAudit]

   ON  [dbo].[WorkOrderIssuedStock]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderIssuedStockAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END