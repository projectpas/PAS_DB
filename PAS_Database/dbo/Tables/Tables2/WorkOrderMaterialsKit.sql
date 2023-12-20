CREATE TABLE [dbo].[WorkOrderMaterialsKit] (
    [WorkOrderMaterialsKitId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialsKitMappingId] BIGINT          NOT NULL,
    [WorkOrderId]                    BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]            BIGINT          NOT NULL,
    [ItemMasterId]                   BIGINT          NOT NULL,
    [MasterCompanyId]                INT             NOT NULL,
    [CreatedBy]                      VARCHAR (256)   NOT NULL,
    [UpdatedBy]                      VARCHAR (256)   NOT NULL,
    [CreatedDate]                    DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMaterialsKit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMaterialsKit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT             CONSTRAINT [WorkOrderMaterialsKit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT             CONSTRAINT [WorkOrderMaterialsKit_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TaskId]                         BIGINT          NOT NULL,
    [ConditionCodeId]                BIGINT          NOT NULL,
    [ItemClassificationId]           BIGINT          NOT NULL,
    [Quantity]                       INT             DEFAULT ((0)) NOT NULL,
    [UnitOfMeasureId]                BIGINT          NOT NULL,
    [UnitCost]                       DECIMAL (20, 2) DEFAULT ((0)) NOT NULL,
    [ExtendedCost]                   DECIMAL (20, 2) DEFAULT ((0)) NOT NULL,
    [Memo]                           NVARCHAR (MAX)  NULL,
    [IsDeferred]                     BIT             DEFAULT ((0)) NULL,
    [QuantityReserved]               INT             NULL,
    [QuantityIssued]                 INT             NULL,
    [IssuedDate]                     DATETIME2 (7)   NULL,
    [ReservedDate]                   DATETIME2 (7)   NULL,
    [IsAltPart]                      BIT             NULL,
    [AltPartMasterPartId]            BIGINT          NULL,
    [IsFromWorkFlow]                 BIT             DEFAULT ((0)) NULL,
    [PartStatusId]                   INT             NULL,
    [UnReservedQty]                  INT             NULL,
    [UnIssuedQty]                    INT             NULL,
    [IssuedById]                     BIGINT          NULL,
    [ReservedById]                   BIGINT          NULL,
    [IsEquPart]                      BIT             NULL,
    [ParentWorkOrderMaterialsId]     BIGINT          NULL,
    [ItemMappingId]                  BIGINT          NULL,
    [TotalReserved]                  INT             NULL,
    [TotalIssued]                    INT             NULL,
    [TotalUnReserved]                INT             NULL,
    [TotalUnIssued]                  INT             NULL,
    [ProvisionId]                    INT             NOT NULL,
    [MaterialMandatoriesId]          INT             NULL,
    [WOPartNoId]                     BIGINT          DEFAULT ((0)) NOT NULL,
    [TotalStocklineQtyReq]           INT             DEFAULT ((0)) NOT NULL,
    [QtyOnOrder]                     INT             DEFAULT ((0)) NULL,
    [QtyOnBkOrder]                   INT             DEFAULT ((0)) NULL,
    [POId]                           BIGINT          NULL,
    [PONum]                          VARCHAR (100)   NULL,
    [PONextDlvrDate]                 DATETIME        NULL,
    [QtyToTurnIn]                    INT             NULL,
    [Figure]                         NVARCHAR (50)   NULL,
    [Item]                           NVARCHAR (50)   NULL,
    CONSTRAINT [PK_WorkOrderMaterialsKit] PRIMARY KEY CLUSTERED ([WorkOrderMaterialsKitId] ASC)
);


GO

CREATE   TRIGGER [dbo].[Trg_WorkOrderMaterialsKitAudit]
   ON  [dbo].[WorkOrderMaterialsKit]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN

	INSERT INTO [dbo].[WorkOrderMaterialsKitAudit]
           ([WorkOrderMaterialsKitId]
           ,[WorkOrderMaterialsKitMappingId]
           ,[WorkOrderId]
           ,[WorkFlowWorkOrderId]
           ,[ItemMasterId]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[TaskId]
           ,[ConditionCodeId]
           ,[ItemClassificationId]
           ,[Quantity]
           ,[UnitOfMeasureId]
           ,[UnitCost]
           ,[ExtendedCost]
           ,[Memo]
           ,[IsDeferred]
           ,[QuantityReserved]
           ,[QuantityIssued]
           ,[IssuedDate]
           ,[ReservedDate]
           ,[IsAltPart]
           ,[AltPartMasterPartId]
           ,[IsFromWorkFlow]
           ,[PartStatusId]
           ,[UnReservedQty]
           ,[UnIssuedQty]
           ,[IssuedById]
           ,[ReservedById]
           ,[IsEquPart]
           ,[ParentWorkOrderMaterialsId]
           ,[ItemMappingId]
           ,[TotalReserved]
           ,[TotalIssued]
           ,[TotalUnReserved]
           ,[TotalUnIssued]
           ,[ProvisionId]
           ,[MaterialMandatoriesId]
           ,[WOPartNoId]
           ,[TotalStocklineQtyReq]
           ,[QtyOnOrder]
           ,[QtyOnBkOrder]
           ,[POId]
           ,[PONum]
           ,[PONextDlvrDate]
           ,[QtyToTurnIn]
           ,[Figure]
           ,[Item])
     SELECT
            [WorkOrderMaterialsKitId]
           ,[WorkOrderMaterialsKitMappingId]
           ,[WorkOrderId]
           ,[WorkFlowWorkOrderId]
           ,[ItemMasterId]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[TaskId]
           ,[ConditionCodeId]
           ,[ItemClassificationId]
           ,[Quantity]
           ,[UnitOfMeasureId]
           ,[UnitCost]
           ,[ExtendedCost]
           ,[Memo]
           ,[IsDeferred]
           ,[QuantityReserved]
           ,[QuantityIssued]
           ,[IssuedDate]
           ,[ReservedDate]
           ,[IsAltPart]
           ,[AltPartMasterPartId]
           ,[IsFromWorkFlow]
           ,[PartStatusId]
           ,[UnReservedQty]
           ,[UnIssuedQty]
           ,[IssuedById]
           ,[ReservedById]
           ,[IsEquPart]
           ,[ParentWorkOrderMaterialsId]
           ,[ItemMappingId]
           ,[TotalReserved]
           ,[TotalIssued]
           ,[TotalUnReserved]
           ,[TotalUnIssued]
           ,[ProvisionId]
           ,[MaterialMandatoriesId]
           ,[WOPartNoId]
           ,[TotalStocklineQtyReq]
           ,[QtyOnOrder]
           ,[QtyOnBkOrder]
           ,[POId]
           ,[PONum]
           ,[PONextDlvrDate]
           ,[QtyToTurnIn]
           ,[Figure]
           ,[Item]
		FROM INSERTED

	INSERT INTO WorkOrderMaterialsKitAudit
	SELECT * FROM DELETED

	SET NOCOUNT ON;
END