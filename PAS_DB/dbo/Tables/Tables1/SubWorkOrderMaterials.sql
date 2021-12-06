CREATE TABLE [dbo].[SubWorkOrderMaterials] (
    [SubWorkOrderMaterialsId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                   BIGINT          NOT NULL,
    [SubWorkOrderId]                BIGINT          NOT NULL,
    [SubWOPartNoId]                 BIGINT          NOT NULL,
    [ItemMasterId]                  BIGINT          NOT NULL,
    [TaskId]                        BIGINT          NOT NULL,
    [ConditionCodeId]               BIGINT          NOT NULL,
    [ItemClassificationId]          BIGINT          NOT NULL,
    [Quantity]                      INT             DEFAULT ((0)) NOT NULL,
    [UnitOfMeasureId]               BIGINT          NOT NULL,
    [UnitCost]                      DECIMAL (20, 2) DEFAULT ((0)) NOT NULL,
    [ExtendedCost]                  DECIMAL (20, 2) DEFAULT ((0)) NOT NULL,
    [Price]                         DECIMAL (20, 2) NULL,
    [ExtendedPrice]                 DECIMAL (20, 2) NULL,
    [Memo]                          NVARCHAR (MAX)  NULL,
    [IsDeferred]                    BIT             DEFAULT ((0)) NULL,
    [QuantityReserved]              INT             NULL,
    [QuantityIssued]                INT             NULL,
    [IssuedDate]                    DATETIME2 (7)   NULL,
    [ReservedDate]                  DATETIME2 (7)   NULL,
    [IsAltPart]                     BIT             NULL,
    [AltPartMasterPartId]           BIGINT          NULL,
    [IsFromWorkFlow]                BIT             DEFAULT ((0)) NULL,
    [PartStatusId]                  INT             NULL,
    [IssuedById]                    BIGINT          NULL,
    [ReservedById]                  BIGINT          NULL,
    [IsEquPart]                     BIT             NULL,
    [ParentSubWorkOrderMaterialsId] BIGINT          NULL,
    [ItemMappingId]                 BIGINT          NULL,
    [TotalReserved]                 INT             NULL,
    [TotalIssued]                   INT             NULL,
    [ProvisionId]                   INT             NOT NULL,
    [MaterialMandatoriesId]         INT             NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderMaterials_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderMaterials_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [SubWorkOrderMaterials_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [SubWorkOrderMaterials_DC_Delete] DEFAULT ((0)) NOT NULL,
    [QuantityTurnIn]                INT             NULL,
    [Condition]                     VARCHAR (50)    NULL,
    [UOM]                           VARCHAR (50)    NULL,
    [ItemClassification]            VARCHAR (100)   NULL,
    [Provision]                     VARCHAR (50)    NULL,
    [TaskName]                      VARCHAR (50)    NULL,
    [Site]                          VARCHAR (50)    NULL,
    [WareHouse]                     VARCHAR (50)    NULL,
    [Locations]                     VARCHAR (50)    NULL,
    [Shelf]                         VARCHAR (50)    NULL,
    [Bin]                           VARCHAR (50)    NULL,
    [TotalStocklineQtyReq]          INT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWorkOrderMaterials] PRIMARY KEY CLUSTERED ([SubWorkOrderMaterialsId] ASC),
    CONSTRAINT [FK_SubWorkOrderMaterials_Condition] FOREIGN KEY ([ConditionCodeId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_ItemClassification] FOREIGN KEY ([ItemClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_MaterialMandatories] FOREIGN KEY ([MaterialMandatoriesId]) REFERENCES [dbo].[MaterialMandatories] ([Id]),
    CONSTRAINT [FK_SubWorkOrderMaterials_Provision] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[Provision] ([ProvisionId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_SubWOPartNo] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_UnitOfMeasure] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_SubWorkOrderMaterials_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderMaterialsAudit]

   ON  [dbo].[SubWorkOrderMaterials]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderMaterialsAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END