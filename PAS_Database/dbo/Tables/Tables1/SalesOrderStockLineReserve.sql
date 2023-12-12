CREATE TABLE [dbo].[SalesOrderStockLineReserve] (
    [SOSReserveId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]     BIGINT        NOT NULL,
    [SalesOrderPartId] BIGINT        NOT NULL,
    [StockLIneId]      BIGINT        NOT NULL,
    [ConditionId]      BIGINT        NULL,
    [QtyReserved]      INT           NULL,
    [IsReserved]       BIT           NOT NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) CONSTRAINT [DF_SalesOrderStockLineReserve_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) CONSTRAINT [DF_SalesOrderStockLineReserve_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT           CONSTRAINT [SOSLR_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT           CONSTRAINT [SOSLR_DC_Deleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderStockLineReserve] PRIMARY KEY CLUSTERED ([SOSReserveId] ASC),
    CONSTRAINT [FK_SalesOrderStockLineReserve_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderStockLineReserve_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SalesOrderStockLineReserve_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO




CREATE TRIGGER [dbo].[Trg_SalesOrderStockLineReserveAudit]

   ON  [dbo].[SalesOrderStockLineReserve]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SalesOrderStockLineReserveAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END