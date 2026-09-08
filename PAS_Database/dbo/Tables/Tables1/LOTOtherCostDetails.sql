CREATE TABLE [dbo].[LOTOtherCostDetails] (
    [LotOtherCostDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LotId]                BIGINT          NOT NULL,
    [LotNumber]            VARCHAR (200)   NULL,
    [ReconciledFreight]    DECIMAL (18, 2) NULL,
    [UnReconciledFreight]  DECIMAL (18, 2) NULL,
    [ManualAdjFreight]     DECIMAL (18, 2) NULL,
    [TotalFreight]         DECIMAL (18, 2) NULL,
    [ReconciledCharges]    DECIMAL (18, 2) NULL,
    [UnReconciledCharges]  DECIMAL (18, 2) NULL,
    [ManualAdjCharges]     DECIMAL (18, 2) NULL,
    [TotalOtherCost]       DECIMAL (18, 2) NULL,
    [StocklineId]          BIGINT          NULL,
    [StocklineNumber]      VARCHAR (100)   NULL,
    [ItemMasterId]         BIGINT          NULL,
    [PartNumber]           VARCHAR (200)   NULL,
    [PartDescription]      VARCHAR (MAX)   NULL,
    [ManufacturerId]       BIGINT          NULL,
    [ManufacturerName]     VARCHAR (200)   NULL,
    [ConditionId]          BIGINT          NULL,
    [Condition]            VARCHAR (200)   NULL,
    [IsNA]                 BIT             CONSTRAINT [DF_LOTOtherCostDetails_IsNA] DEFAULT ((0)) NOT NULL,
    [ModuleId]             INT             NULL,
    [ModuleName]           VARCHAR (100)   NULL,
    [ReferenceId]          BIGINT          NULL,
    [ReferenceNumber]      VARCHAR (100)   NULL,
    [ReferenceDate]        DATETIME2 (7)   NULL,
    [PostedDate]           DATETIME2 (7)   NULL,
    [Memo]                 NVARCHAR (MAX)  NULL,
    [MasterCompanyId]      INT             CONSTRAINT [DF_LOTOtherCostDetails_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NULL,
    [CreatedDate]          DATETIME2 (7)   NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   NULL,
    [IsActive]             BIT             CONSTRAINT [DF_LOTOtherCostDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [DF_LOTOtherCostDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LOTOtherCostDetails] PRIMARY KEY CLUSTERED ([LotOtherCostDetailId] ASC),
    CONSTRAINT [FK_LOTOtherCostDetails_Lot] FOREIGN KEY ([LotId]) REFERENCES [dbo].[Lot] ([LotId]),
    CONSTRAINT [FK_LOTOtherCostDetails_Stockline] FOREIGN KEY ([StocklineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_LOTOtherCostDetails_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_LOTOtherCostDetails_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId])
);




GO
-- [PN-17853] Audit trigger: mirrors the established Details+Audit pattern (see ReceivingReconciliationDetails.sql /
-- Trg_ReceivingReconciliationDetailsAudit) used elsewhere in this codebase for entity-specific detail tables.
-- NOTE: like that reference trigger, INSERTED is empty on a DELETE, so a hard DELETE is not captured here -
-- this table only ever gets soft-deleted (IsDeleted=1) via the app, so that is not expected to matter in practice.
CREATE TRIGGER [dbo].[Trg_LOTOtherCostDetailsAudit]
   ON  [dbo].[LOTOtherCostDetails]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO LOTOtherCostDetailsAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
GO
-- [PN-17853] Supports the Other Cost tab's manual-rows lookup (by LotId) done inside
-- USP_Lot_GetAllLotViewsByLotId_Filter's OtherCost branch, and the Add popup's per-Lot part list.
CREATE NONCLUSTERED INDEX [IX_LOTOtherCostDetails_LotId]
    ON [dbo].[LOTOtherCostDetails]([LotId] ASC)
    INCLUDE([StocklineId], [ItemMasterId], [TotalFreight], [TotalOtherCost], [IsDeleted]);
