CREATE TABLE [dbo].[WorkOrderMaterialStockLineKit] (
    [WorkOrderMaterialStockLineKitId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialsKitId]         BIGINT          NOT NULL,
    [StockLineId]                     BIGINT          NOT NULL,
    [ItemMasterId]                    BIGINT          NOT NULL,
    [ConditionId]                     BIGINT          NOT NULL,
    [Quantity]                        INT             CONSTRAINT [DF_WorkOrderMaterialStockLineKit_Quantity] DEFAULT ((0)) NULL,
    [QtyReserved]                     INT             CONSTRAINT [DF_WorkOrderMaterialStockLineKit_QtyReserved] DEFAULT ((0)) NULL,
    [QtyIssued]                       INT             CONSTRAINT [DF_WorkOrderMaterialStockLineKit_QtyIssued] DEFAULT ((0)) NULL,
    [MasterCompanyId]                 INT             NOT NULL,
    [CreatedBy]                       VARCHAR (256)   NOT NULL,
    [UpdatedBy]                       VARCHAR (256)   NOT NULL,
    [CreatedDate]                     DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMaterialStockLineKit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMaterialStockLineKit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                        BIT             CONSTRAINT [DF_WorkOrderMaterialStockLineKit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT             CONSTRAINT [DF_WorkOrderMaterialStockLineKit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AltPartMasterPartId]             BIGINT          NULL,
    [EquPartMasterPartId]             BIGINT          NULL,
    [IsAltPart]                       BIT             NULL,
    [IsEquPart]                       BIT             NULL,
    [UnitCost]                        DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMaterialStockLineKit_UnitCost] DEFAULT ((0)) NULL,
    [ExtendedCost]                    DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMaterialStockLineKit_ExtendedCost] DEFAULT ((0)) NULL,
    [UnitPrice]                       DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMaterialStockLineKit_UnitPrice] DEFAULT ((0)) NULL,
    [ExtendedPrice]                   DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMaterialStockLineKit_ExtendedPrice] DEFAULT ((0)) NULL,
    [ProvisionId]                     INT             DEFAULT ((1)) NOT NULL,
    [RepairOrderId]                   BIGINT          NULL,
    [QuantityTurnIn]                  INT             DEFAULT ((0)) NULL,
    [Figure]                          NVARCHAR (50)   NULL,
    [Item]                            NVARCHAR (50)   NULL,
    [RepairOrderPartRecordId]         BIGINT          NULL,
    [ReferenceNumber]                 VARCHAR (100)   NULL,
    CONSTRAINT [PK_WorkOrderMaterialStockLineKit] PRIMARY KEY CLUSTERED ([WorkOrderMaterialStockLineKitId] ASC)
);




GO

CREATE   TRIGGER [dbo].[Trg_WorkOrderMaterialStockLineKitAudit]
   ON  [dbo].[WorkOrderMaterialStockLineKit]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN

	INSERT INTO [dbo].[WorkOrderMaterialStockLineKitAudit]
           ([WorkOrderMaterialStockLineKitId]
           ,[WorkOrderMaterialsKitId]
           ,[StockLineId]
           ,[ItemMasterId]
           ,[ConditionId]
           ,[Quantity]
           ,[QtyReserved]
           ,[QtyIssued]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[AltPartMasterPartId]
           ,[EquPartMasterPartId]
           ,[IsAltPart]
           ,[IsEquPart]
           ,[UnitCost]
           ,[ExtendedCost]
           ,[UnitPrice]
           ,[ExtendedPrice]
           ,[ProvisionId]
           ,[RepairOrderId]
           ,[QuantityTurnIn]
           ,[Figure]
           ,[Item]
           ,[RepairOrderPartRecordId])
     SELECT
            [WorkOrderMaterialStockLineKitId]
           ,[WorkOrderMaterialsKitId]
           ,[StockLineId]
           ,[ItemMasterId]
           ,[ConditionId]
           ,[Quantity]
           ,[QtyReserved]
           ,[QtyIssued]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[AltPartMasterPartId]
           ,[EquPartMasterPartId]
           ,[IsAltPart]
           ,[IsEquPart]
           ,[UnitCost]
           ,[ExtendedCost]
           ,[UnitPrice]
           ,[ExtendedPrice]
           ,[ProvisionId]
           ,[RepairOrderId]
           ,[QuantityTurnIn]
           ,[Figure]
           ,[Item]
           ,[RepairOrderPartRecordId]
	FROM INSERTED

	INSERT INTO WorkOrderMaterialStockLineKitAudit
	SELECT * FROM DELETED

	SET NOCOUNT ON;
END