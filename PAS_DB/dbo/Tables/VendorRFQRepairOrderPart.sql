CREATE TABLE [dbo].[VendorRFQRepairOrderPart] (
    [VendorRFQROPartRecordId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorRFQRepairOrderId]  BIGINT          NOT NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [PartNumber]              VARCHAR (250)   NULL,
    [PartDescription]         VARCHAR (MAX)   NULL,
    [AltEquiPartNumberId]     BIGINT          NULL,
    [AltEquiPartNumber]       VARCHAR (250)   NULL,
    [AltEquiPartDescription]  VARCHAR (MAX)   NULL,
    [RevisedPartId]           BIGINT          NULL,
    [RevisedPartNumber]       VARCHAR (250)   NULL,
    [StockType]               VARCHAR (50)    NULL,
    [ManufacturerId]          BIGINT          NOT NULL,
    [Manufacturer]            VARCHAR (250)   NULL,
    [PriorityId]              BIGINT          CONSTRAINT [DF__VendorRFQRepairOrderPart__Prior__7A56182C] DEFAULT ((0)) NOT NULL,
    [Priority]                VARCHAR (50)    NULL,
    [NeedByDate]              DATETIME2 (7)   NOT NULL,
    [PromisedDate]            DATETIME2 (7)   NULL,
    [ConditionId]             BIGINT          NOT NULL,
    [Condition]               VARCHAR (256)   NULL,
    [WorkPerformedId]         BIGINT          NULL,
    [WorkPerformed]           VARCHAR (250)   NULL,
    [QuantityOrdered]         INT             NOT NULL,
    [UnitCost]                DECIMAL (20, 2) NULL,
    [ExtendedCost]            DECIMAL (20, 2) NULL,
    [WorkOrderId]             BIGINT          NULL,
    [WorkOrderNo]             VARCHAR (250)   NULL,
    [SubWorkOrderId]          BIGINT          NULL,
    [SubWorkOrderNo]          VARCHAR (250)   NULL,
    [SalesOrderId]            BIGINT          NULL,
    [SalesOrderNo]            VARCHAR (250)   NULL,
    [ItemTypeId]              INT             NULL,
    [ItemType]                VARCHAR (100)   NULL,
    [UOMId]                   BIGINT          NULL,
    [UnitOfMeasure]           VARCHAR (250)   NULL,
    [ManagementStructureId]   BIGINT          NOT NULL,
    [Level1]                  VARCHAR (200)   NULL,
    [Level2]                  VARCHAR (200)   NULL,
    [Level3]                  VARCHAR (200)   NULL,
    [Level4]                  VARCHAR (200)   NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [MasterCompanyId]         INT             NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   NULL,
    [IsActive]                BIT             CONSTRAINT [DF__VendorRFQRepairOrderPart__IsAct__00CA12DE] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF__VendorRFQRepairOrderPart__IsDel__34563A8A] DEFAULT ((0)) NOT NULL,
    [RepairOrderId]           BIGINT          NULL,
    [RepairOrderNumber]       VARCHAR (50)    NULL,
    [TraceableTo]             BIGINT          NULL,
    [TraceableToName]         VARCHAR (250)   NULL,
    [TraceableToType]         INT             NULL,
    [TagTypeId]               BIGINT          NULL,
    [TaggedBy]                BIGINT          NULL,
    [TaggedByType]            INT             NULL,
    [TaggedByName]            VARCHAR (250)   NULL,
    [TaggedByTypeName]        VARCHAR (250)   NULL,
    [TagDate]                 DATETIME2 (7)   NULL,
    CONSTRAINT [PK_VendorRFQRepairOrderPart] PRIMARY KEY CLUSTERED ([VendorRFQROPartRecordId] ASC),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_Manufacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_PriorityId] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_RepairOrderPart] FOREIGN KEY ([VendorRFQRepairOrderId]) REFERENCES [dbo].[VendorRFQRepairOrder] ([VendorRFQRepairOrderId]),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_SubWorkOrderId] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_VendorRFQRepairOrderPart_WorkOrderId] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);








GO





CREATE TRIGGER [dbo].[TrgVendorRFQRepairOrderPartAudit]
   ON [dbo].[VendorRFQRepairOrderPart]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO [dbo].[VendorRFQRepairOrderPartAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END