CREATE TABLE [dbo].[SalesOrderStocklineV1] (
    [SalesOrderStocklineId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderPartId]      BIGINT        NOT NULL,
    [StockLineId]           BIGINT        NOT NULL,
    [ConditionId]           BIGINT        NOT NULL,
    [QtyOrder]              INT           NOT NULL,
    [QtyReserved]           INT           NOT NULL,
    [QtyAvailable]          INT           NOT NULL,
    [QtyOH]                 INT           NOT NULL,
    [CustomerRequestDate]   DATETIME2 (7) NULL,
    [PromisedDate]          DATETIME2 (7) NULL,
    [EstimatedShipDate]     DATETIME2 (7) NULL,
    [StatusId]              INT           NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_SalesOrderStocklineV1_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_SalesOrderStocklineV1_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_SalesOrderStocklineV1_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_SalesOrderStocklineV1_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderStocklineV1] PRIMARY KEY CLUSTERED ([SalesOrderStocklineId] ASC),
    CONSTRAINT [FK_SalesOrderStocklineV1_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

