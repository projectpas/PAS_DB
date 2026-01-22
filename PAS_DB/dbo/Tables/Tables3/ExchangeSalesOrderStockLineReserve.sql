CREATE TABLE [dbo].[ExchangeSalesOrderStockLineReserve] (
    [SOSReserveId]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]     BIGINT        NOT NULL,
    [ExchangeSalesOrderPartId] BIGINT        NOT NULL,
    [StockLIneId]              BIGINT        NOT NULL,
    [ConditionId]              BIGINT        NULL,
    [QtyReserved]              INT           NULL,
    [IsReserved]               BIT           NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderStockLineReserve_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderStockLineReserve_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_ExchangeSalesOrderStockLineReserve_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF_ExchangeSalesOrderStockLineReserve_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeSalesOrderStockLineReserve] PRIMARY KEY CLUSTERED ([SOSReserveId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderStockLineReserve_ExchangeSalesOrder] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId]),
    CONSTRAINT [FK_ExchangeSalesOrderStockLineReserve_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeSalesOrderStockLineReserve_Stockline] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderStockLineReserveAudit]

   ON  [dbo].[ExchangeSalesOrderStockLineReserve]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeSalesOrderStockLineReserveAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END