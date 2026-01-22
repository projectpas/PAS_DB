CREATE TABLE [dbo].[ExchangeSalesOrderUnReservedStock] (
    [SOUnReservedStockId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]     BIGINT        NOT NULL,
    [ExchangeSalesOrderPartId] BIGINT        NOT NULL,
    [StockLIneId]              BIGINT        NOT NULL,
    [ConditionId]              BIGINT        NOT NULL,
    [ItemMasterId]             BIGINT        NOT NULL,
    [Quantity]                 INT           NOT NULL,
    [AltPartMasterPartId]      BIGINT        NULL,
    [EquPartMasterPartId]      BIGINT        NULL,
    [IsAltPart]                BIT           NULL,
    [IsEquPart]                BIT           NULL,
    [UnReservedById]           BIGINT        NOT NULL,
    [UnReservedDate]           DATETIME2 (7) NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderUnReservedStock_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderUnReservedStock_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_ExchangeSalesOrderUnReservedStock_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF_ExchangeSalesOrderUnReservedStock_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeSalesOrderUnReservedStock] PRIMARY KEY CLUSTERED ([SOUnReservedStockId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderUnReservedStock_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_ExchangeSalesOrderUnReservedStock_Employee] FOREIGN KEY ([UnReservedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ExchangeSalesOrderUnReservedStock_ExchangeSalesOrder] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId]),
    CONSTRAINT [FK_ExchangeSalesOrderUnReservedStock_ExchangeSalesOrderPart] FOREIGN KEY ([ExchangeSalesOrderPartId]) REFERENCES [dbo].[ExchangeSalesOrderPart] ([ExchangeSalesOrderPartId]),
    CONSTRAINT [FK_ExchangeSalesOrderUnReservedStock_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ExchangeSalesOrderUnReservedStock_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeSalesOrderUnReservedStock_Stockline] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderUnReservedStockAudit]

   ON  [dbo].[ExchangeSalesOrderUnReservedStock]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeSalesOrderUnReservedStockAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END