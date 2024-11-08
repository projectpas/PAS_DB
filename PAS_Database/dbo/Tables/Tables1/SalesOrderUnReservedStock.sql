CREATE TABLE [dbo].[SalesOrderUnReservedStock] (
    [SOUnReservedStockId] BIGINT        IDENTITY (1, 1) NOT NULL,
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
    [UnReservedById]      BIGINT        NOT NULL,
    [UnReservedDate]      DATETIME2 (7) NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_SalesOrderUnReservedStock_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_SalesOrderUnReservedStock_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_SalesOrderUnReservedStock_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_SalesOrderUnReservedStock_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderUnReservedStock] PRIMARY KEY CLUSTERED ([SOUnReservedStockId] ASC),
    CONSTRAINT [FK_SalesOrderUnReservedStock_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SalesOrderUnReservedStock_Employee] FOREIGN KEY ([UnReservedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderUnReservedStock_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SalesOrderUnReservedStock_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderUnReservedStock_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SalesOrderUnReservedStock_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);




GO




CREATE TRIGGER [dbo].[Trg_SalesOrderUnReservedStockAudit]

   ON  [dbo].[SalesOrderUnReservedStock]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SalesOrderUnReservedStockAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END