CREATE TABLE [dbo].[SubWorkOrder] (
    [SubWorkOrderId]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]           BIGINT        NOT NULL,
    [SubWorkOrderNo]        VARCHAR (100) NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_SubWorkOrder_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_SubWorkOrder_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_SWO_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_SWO_IsDeleted] DEFAULT ((0)) NOT NULL,
    [WorkOrderPartNumberId] BIGINT        NULL,
    [OpenDate]              DATETIME2 (7) NOT NULL,
    [WorkOrderMaterialsId]  BIGINT        NOT NULL,
    [StockLineId]           BIGINT        NOT NULL,
    [SubWorkOrderStatusId]  BIGINT        NULL,
    CONSTRAINT [PK_SubWorkOrder] PRIMARY KEY CLUSTERED ([SubWorkOrderId] ASC),
    CONSTRAINT [FK_SubWorkOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrder_StockLineId] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_SubWorkOrder_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_SubWorkOrder_WorkOrderMaterials] FOREIGN KEY ([WorkOrderMaterialsId]) REFERENCES [dbo].[WorkOrderMaterials] ([WorkOrderMaterialsId]),
    CONSTRAINT [FK_SubWorkOrder_WorkOrderPartNumber] FOREIGN KEY ([WorkOrderPartNumberId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID]),
    CONSTRAINT [Unique_SubWorkOrder] UNIQUE NONCLUSTERED ([SubWorkOrderNo] ASC, [WorkOrderId] ASC, [MasterCompanyId] ASC)
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderAudit]

   ON  [dbo].[SubWorkOrder]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END