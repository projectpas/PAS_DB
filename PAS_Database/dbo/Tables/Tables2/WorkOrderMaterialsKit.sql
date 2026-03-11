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
    [Quantity]                       DECIMAL (18, 6) CONSTRAINT [DF__WorkOrder__Quant__490B3760] DEFAULT ((0)) NULL,
    [UnitOfMeasureId]                BIGINT          NOT NULL,
    [UnitCost]                       DECIMAL (18, 6) CONSTRAINT [DF__WorkOrder__UnitC__2B6363DB] DEFAULT ((0)) NULL,
    [ExtendedCost]                   DECIMAL (18, 6) CONSTRAINT [DF__WorkOrder__Exten__2A6F3FA2] DEFAULT ((0)) NULL,
    [Memo]                           NVARCHAR (MAX)  NULL,
    [IsDeferred]                     BIT             DEFAULT ((0)) NULL,
    [QuantityReserved]               DECIMAL (18, 6) NULL,
    [QuantityIssued]                 DECIMAL (18, 6) NULL,
    [IssuedDate]                     DATETIME2 (7)   NULL,
    [ReservedDate]                   DATETIME2 (7)   NULL,
    [IsAltPart]                      BIT             NULL,
    [AltPartMasterPartId]            BIGINT          NULL,
    [IsFromWorkFlow]                 BIT             DEFAULT ((0)) NULL,
    [PartStatusId]                   INT             NULL,
    [UnReservedQty]                  DECIMAL (18, 6) NULL,
    [UnIssuedQty]                    DECIMAL (18, 6) NULL,
    [IssuedById]                     BIGINT          NULL,
    [ReservedById]                   BIGINT          NULL,
    [IsEquPart]                      BIT             NULL,
    [ParentWorkOrderMaterialsId]     BIGINT          NULL,
    [ItemMappingId]                  BIGINT          NULL,
    [TotalReserved]                  DECIMAL (18, 6) NULL,
    [TotalIssued]                    DECIMAL (18, 6) NULL,
    [TotalUnReserved]                DECIMAL (18, 6) NULL,
    [TotalUnIssued]                  DECIMAL (18, 6) NULL,
    [ProvisionId]                    INT             NOT NULL,
    [MaterialMandatoriesId]          INT             NULL,
    [WOPartNoId]                     BIGINT          DEFAULT ((0)) NOT NULL,
    [TotalStocklineQtyReq]           DECIMAL (18, 6) CONSTRAINT [DF__WorkOrder__Total__49FF5B99] DEFAULT ((0)) NULL,
    [QtyOnOrder]                     DECIMAL (18, 6) CONSTRAINT [DF__WorkOrder__QtyOn__4AF37FD2] DEFAULT ((0)) NULL,
    [QtyOnBkOrder]                   DECIMAL (18, 6) CONSTRAINT [DF__WorkOrder__QtyOn__4BE7A40B] DEFAULT ((0)) NULL,
    [POId]                           BIGINT          NULL,
    [PONum]                          VARCHAR (100)   NULL,
    [PONextDlvrDate]                 DATETIME        NULL,
    [QtyToTurnIn]                    DECIMAL (18, 6) NULL,
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
           ,GETUTCDATE()
           ,GETUTCDATE()
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