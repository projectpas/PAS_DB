CREATE TABLE [dbo].[WorkOrderStockLineReserve] (
    [WOSReserveId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialsId] BIGINT        NOT NULL,
    [StockLIneId]          BIGINT        NOT NULL,
    [QtyReserved]          INT           NULL,
    [IsReserved]           BIT           NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkOrderStockLineReserve_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkOrderStockLineReserve_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_WorkOrderStockLineReserve_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_WorkOrderStockLineReserve_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ConditionId]          BIGINT        NULL,
    CONSTRAINT [PK_WorkOrderStockLineReserve] PRIMARY KEY CLUSTERED ([WOSReserveId] ASC),
    CONSTRAINT [FK_WorkOrderStockLineReserve_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderStockLineReserve_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_WorkOrderStockLineReserve_WorkOrderMaterials] FOREIGN KEY ([WorkOrderMaterialsId]) REFERENCES [dbo].[WorkOrderMaterials] ([WorkOrderMaterialsId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderStockLineReserveAudit]

   ON  [dbo].[WorkOrderStockLineReserve]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderStockLineReserveAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END