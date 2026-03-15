CREATE TABLE [dbo].[SubWorkOrderMaterialStockLine] (
    [SWOMStockLineId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderMaterialsId] BIGINT          NOT NULL,
    [StockLIneId]             BIGINT          NOT NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [ConditionId]             BIGINT          NOT NULL,
    [Quantity]                DECIMAL (18, 6) NULL,
    [QtyReserved]             DECIMAL (18, 6) NULL,
    [QtyIssued]               DECIMAL (18, 6) NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderMaterialStockLine_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderMaterialStockLine_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_SubWorkOrderMaterialStockLine_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_SubWorkOrderMaterialStockLine_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AltPartMasterPartId]     BIGINT          NULL,
    [EquPartMasterPartId]     BIGINT          NULL,
    [IsAltPart]               BIT             NULL,
    [IsEquPart]               BIT             NULL,
    [UnitCost]                DECIMAL (18, 6) NULL,
    [ExtendedCost]            DECIMAL (18, 6) NULL,
    [UnitPrice]               DECIMAL (18, 6) NULL,
    [ExtendedPrice]           DECIMAL (18, 6) NULL,
    [ProvisionId]             INT             DEFAULT ((2)) NOT NULL,
    [RepairOrderId]           BIGINT          NULL,
    [QuantityTurnIn]          DECIMAL (18, 6) CONSTRAINT [DF__SubWorkOr__Quant__416A1598] DEFAULT ((0)) NULL,
    [Figure]                  NVARCHAR (50)   NULL,
    [Item]                    NVARCHAR (50)   NULL,
    [ReferenceNumber]         VARCHAR (100)   NULL,
    [ReservedById]            BIGINT          NULL,
    [ReservedDate]            DATETIME2 (7)   NULL,
    [IssuedById]              BIGINT          NULL,
    [IssuedDate]              DATETIME2 (7)   NULL,
    CONSTRAINT [PK_SubWorkOrderMaterialStockLine] PRIMARY KEY CLUSTERED ([SWOMStockLineId] ASC),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLine_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLine_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLine_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLine_ProvisionId] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[Provision] ([ProvisionId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLine_RepairOrderId] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLine_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLine_SubWorkOrderMaterials] FOREIGN KEY ([SubWorkOrderMaterialsId]) REFERENCES [dbo].[SubWorkOrderMaterials] ([SubWorkOrderMaterialsId])
);








GO




CREATE TRIGGER [dbo].[Trg_SubWorkOrderMaterialStockLineAudit]

   ON  [dbo].[SubWorkOrderMaterialStockLine]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SubWorkOrderMaterialStockLineAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END