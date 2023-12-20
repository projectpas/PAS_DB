CREATE TABLE [dbo].[SubWorkOrderStockLineReserve] (
    [SWOSReserveId]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderMaterialsId] BIGINT        NOT NULL,
    [StockLIneId]             BIGINT        NOT NULL,
    [QtyReserved]             INT           NULL,
    [IsReserved]              BIT           NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderStockLineReserve_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderStockLineReserve_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_SubWorkOrderStockLineReserve_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_SubWorkOrderStockLineReserve_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ConditionId]             BIGINT        NULL,
    CONSTRAINT [PK_SubWorkOrderStockLineReserve] PRIMARY KEY CLUSTERED ([SWOSReserveId] ASC),
    CONSTRAINT [FK_SubWorkOrderStockLineReserve_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SubWorkOrderStockLineReserve_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderStockLineReserve_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_SubWorkOrderStockLineReserve_SubWorkOrderMaterials] FOREIGN KEY ([SubWorkOrderMaterialsId]) REFERENCES [dbo].[SubWorkOrderMaterials] ([SubWorkOrderMaterialsId])
);


GO




CREATE TRIGGER [dbo].[Trg_SubWorkOrderStockLineReserveAudit]

   ON  [dbo].[SubWorkOrderStockLineReserve]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SubWorkOrderStockLineReserveAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END