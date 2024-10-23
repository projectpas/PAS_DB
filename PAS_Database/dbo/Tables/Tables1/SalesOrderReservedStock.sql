CREATE TABLE [dbo].[SalesOrderReservedStock] (
    [SOReservedStockId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]        BIGINT        NOT NULL,
    [SalesOrderPartId]    BIGINT        NOT NULL,
    [StockLIneId]         BIGINT        NOT NULL,
    [ConditionId]         BIGINT        NOT NULL,
    [ItemMasterId]        BIGINT        NOT NULL,
    [Quantity]            INT           NOT NULL,
    [AltPartMasterPartId] BIGINT        NULL,
    [EquPartMasterPartId] BIGINT        NULL,
    [IsAltPart]           BIT           NULL,
    [IsEquPart]           BIT           NULL,
    [ReservedById]        BIGINT        NOT NULL,
    [ReservedDate]        DATETIME2 (7) NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_SalesOrderReservedStock_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_SalesOrderReservedStock_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_SalesOrderReservedStock_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_SalesOrderReservedStock_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderReservedStock] PRIMARY KEY CLUSTERED ([SOReservedStockId] ASC),
    CONSTRAINT [FK_SalesOrderReservedStock_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SalesOrderReservedStock_Employee] FOREIGN KEY ([ReservedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderReservedStock_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SalesOrderReservedStock_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderReservedStock_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SalesOrderReservedStock_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);




GO




CREATE TRIGGER [dbo].[Trg_SalesOrderReservedStockAudit]

   ON  [dbo].[SalesOrderReservedStock]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SalesOrderReservedStockAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END