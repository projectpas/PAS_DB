CREATE TABLE [dbo].[WorkOrderMaterials] (
    [WorkOrderMaterialsId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]        BIGINT          NOT NULL,
    [ItemMasterId]               BIGINT          NOT NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMaterials_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMaterials_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT             CONSTRAINT [WorkOrderMaterials_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             CONSTRAINT [WorkOrderMaterials_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TaskId]                     BIGINT          NOT NULL,
    [ConditionCodeId]            BIGINT          NOT NULL,
    [ItemClassificationId]       BIGINT          NOT NULL,
    [Quantity]                   INT             DEFAULT ((0)) NOT NULL,
    [UnitOfMeasureId]            BIGINT          NOT NULL,
    [UnitCost]                   DECIMAL (20, 2) DEFAULT ((0)) NOT NULL,
    [ExtendedCost]               DECIMAL (20, 2) DEFAULT ((0)) NOT NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [IsDeferred]                 BIT             DEFAULT ((0)) NULL,
    [QuantityReserved]           INT             NULL,
    [QuantityIssued]             INT             NULL,
    [IssuedDate]                 DATETIME2 (7)   NULL,
    [ReservedDate]               DATETIME2 (7)   NULL,
    [IsAltPart]                  BIT             NULL,
    [AltPartMasterPartId]        BIGINT          NULL,
    [IsFromWorkFlow]             BIT             DEFAULT ((0)) NULL,
    [PartStatusId]               INT             NULL,
    [UnReservedQty]              INT             NULL,
    [UnIssuedQty]                INT             NULL,
    [IssuedById]                 BIGINT          NULL,
    [ReservedById]               BIGINT          NULL,
    [IsEquPart]                  BIT             NULL,
    [ParentWorkOrderMaterialsId] BIGINT          NULL,
    [ItemMappingId]              BIGINT          NULL,
    [TotalReserved]              INT             NULL,
    [TotalIssued]                INT             NULL,
    [TotalUnReserved]            INT             NULL,
    [TotalUnIssued]              INT             NULL,
    [ProvisionId]                INT             NOT NULL,
    [MaterialMandatoriesId]      INT             NULL,
    [WOPartNoId]                 BIGINT          DEFAULT ((0)) NOT NULL,
    [TotalStocklineQtyReq]       INT             DEFAULT ((0)) NOT NULL,
    [QtyOnOrder]                 INT             DEFAULT ((0)) NULL,
    [QtyOnBkOrder]               INT             DEFAULT ((0)) NULL,
    [POId]                       BIGINT          NULL,
    [PONum]                      VARCHAR (100)   NULL,
    [PONextDlvrDate]             DATETIME        NULL,
    [QtyToTurnIn]                INT             NULL,
    [Figure]                     NVARCHAR (50)   NULL,
    [Item]                       NVARCHAR (50)   NULL,
    [EquPartMasterPartId]        BIGINT          NULL,
    [isfromsubWorkOrder]         BIT             NULL,
    [ExpectedSerialNumber]       VARCHAR (30)    NULL,
    CONSTRAINT [PK_WorkOrderMaterials] PRIMARY KEY CLUSTERED ([WorkOrderMaterialsId] ASC),
    CONSTRAINT [FK_WorkOrderMaterials_Condition] FOREIGN KEY ([ConditionCodeId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderMaterials_IssuedById] FOREIGN KEY ([IssuedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderMaterials_ItemClassification] FOREIGN KEY ([ItemClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_WorkOrderMaterials_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderMaterials_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderMaterials_MaterialMandatoriesId] FOREIGN KEY ([MaterialMandatoriesId]) REFERENCES [dbo].[MaterialMandatories] ([Id]),
    CONSTRAINT [FK_WorkOrderMaterials_Provision] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[Provision] ([ProvisionId]),
    CONSTRAINT [FK_WorkOrderMaterials_ReservedById] FOREIGN KEY ([ReservedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderMaterials_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderMaterials_UnitOfMeasure] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_WorkOrderMaterials_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderMaterials_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO

CREATE TRIGGER [dbo].[Trg_WorkOrderMaterialsAudit]

   ON  [dbo].[WorkOrderMaterials]

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE @ItemMasterId BIGINT,@TaskId BIGINT,@ConditionId BIGINT,@MaterialMandatoriesId BIGINT,

	@ProvisionId BIGINT,@ItemClassificationId BIGINT,@UOMId BIGINT, @StockLineId BIGINT  



	DECLARE @TaskName VARCHAR(256),@PartNum VARCHAR(256),@PartDesc VARCHAR(256),@Condition VARCHAR(256),

	@RequestType  VARCHAR(256),@Provision  VARCHAR(256),@ItemClassification  VARCHAR(256),@UOM  VARCHAR(256),@StockType VARCHAR(256) 



	SELECT @ItemMasterId=ItemMasterId,@TaskId=TaskId,@ConditionId=ConditionCodeId,@MaterialMandatoriesId =MaterialMandatoriesId ,

	@ProvisionId=ProvisionId,@ItemClassificationId=ItemClassificationId,@UOMId=UnitOfMeasureId

	

	FROM INSERTED

	

	SELECT @PartNum=partnumber,@PartDesc=PartDescription,

	@StockType= CASE WHEN  IsDER IS NOT NULL OR IsDER=1 THEN 'DER' 

				WHEN IsPma IS NOT NULL OR IsPma=1 THEN 'PMA'

				WHEN IsDER IS NOT NULL OR IsDER=1 THEN 'DER' ELSE '' END

	FROM ItemMaster WHERE ItemMasterId=@ItemMasterId



	SELECT @TaskName=Description FROM Task WHERE TaskId=@TaskId

	 

	SELECT @Condition=Description FROM Condition WHERE ConditionId=@ConditionId



	SELECT @RequestType=Name FROM MaterialMandatories WHERE Id=@MaterialMandatoriesId



	SELECT @Provision=Description FROM Provision WHERE ProvisionId=@ProvisionId



	SELECT @ItemClassification=Description FROM ItemClassification WHERE ItemClassificationId=@ItemClassificationId



	SELECT @UOM=ShortName FROM UnitOfMeasure WHERE UnitOfMeasureId=@UOMId



	INSERT INTO [dbo].[WorkOrderMaterialsAudit] ([WorkOrderMaterialsId],[WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],[MasterCompanyId]

      ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[TaskId],[ConditionCodeId],[ItemClassificationId]

      ,[Quantity],[UnitOfMeasureId],[UnitCost],[ExtendedCost],[Memo],[IsDeferred],[QuantityReserved],[QuantityIssued],[IssuedDate]

      ,[ReservedDate],[IsAltPart],[AltPartMasterPartId],[IsFromWorkFlow],[PartStatusId],[UnReservedQty],[UnIssuedQty]

      ,[IssuedById],[ReservedById],[IsEquPart],[ParentWorkOrderMaterialsId],[ItemMappingId],[TotalReserved]

      ,[TotalIssued],[TotalUnReserved],[TotalUnIssued],[ProvisionId],[MaterialMandatoriesId],[WOPartNoId]

	  ,[TotalStocklineQtyReq], [QtyOnOrder],[QtyOnBkOrder] ,[POId], [PONum], [PONextDlvrDate]

      ,TaskName,PartNum,PartDescription,Condition,RequestType,Provision,ItemClassification,UOM,StockType,Figure,Item) 

    SELECT [WorkOrderMaterialsId]

      ,[WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]

      ,[IsActive],[IsDeleted],[TaskId],[ConditionCodeId],[ItemClassificationId],[Quantity],[UnitOfMeasureId],[UnitCost]

      ,[ExtendedCost],[Memo],[IsDeferred],[QuantityReserved],[QuantityIssued],[IssuedDate],[ReservedDate],[IsAltPart],[AltPartMasterPartId]

      ,[IsFromWorkFlow],[PartStatusId],[UnReservedQty],[UnIssuedQty],[IssuedById],[ReservedById],[IsEquPart],[ParentWorkOrderMaterialsId]

      ,[ItemMappingId],[TotalReserved],[TotalIssued],[TotalUnReserved],[TotalUnIssued],[ProvisionId],[MaterialMandatoriesId],[WOPartNoId]

	  ,[TotalStocklineQtyReq], [QtyOnOrder],[QtyOnBkOrder] ,[POId], [PONum], [PONextDlvrDate]

      ,@TaskName,@PartNum,@PartDesc,@Condition,@RequestType,@Provision,@ItemClassification,@UOM,@StockType,Figure,Item

	FROM INSERTED 

	SET NOCOUNT ON;



END