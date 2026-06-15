CREATE TABLE [dbo].[SalesOrderStocklineV1] (
    [SalesOrderStocklineId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderPartId]      BIGINT          NOT NULL,
    [StockLineId]           BIGINT          NOT NULL,
    [ConditionId]           BIGINT          NOT NULL,
    [QtyOrder]              DECIMAL (18, 6) NULL,
    [QtyReserved]           DECIMAL (18, 6) NULL,
    [QtyAvailable]          DECIMAL (18, 6) NULL,
    [QtyOH]                 DECIMAL (18, 6) NULL,
    [CustomerRequestDate]   DATETIME2 (7)   NULL,
    [PromisedDate]          DATETIME2 (7)   NULL,
    [EstimatedShipDate]     DATETIME2 (7)   NULL,
    [StatusId]              INT             NOT NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SalesOrderStocklineV1_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SalesOrderStocklineV1_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_SalesOrderStocklineV1_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_SalesOrderStocklineV1_IsDeleted] DEFAULT ((0)) NOT NULL,
    [StocklineNumber]       VARCHAR (100)   NULL,
    [ConditionName]         VARCHAR (100)   NULL,
    [StatusName]            VARCHAR (100)   NULL,
    [Notes]                 NVARCHAR (MAX)  NULL,
    [ECCN]                  VARCHAR (200)   NULL,
    [HSCODE]                VARCHAR (200)   NULL,
    [Weight]                DECIMAL (18, 6) NULL,
    [SizeLength]            DECIMAL (18, 6) NULL,
    [SizeWidth]             DECIMAL (18, 6) NULL,
    [SizeHeight]            DECIMAL (18, 6) NULL,
    [ReferenceNumber]       VARCHAR (100)   NULL,
    [PriorityId]            BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderStocklineV1] PRIMARY KEY CLUSTERED ([SalesOrderStocklineId] ASC),
    CONSTRAINT [FK_SalesOrderStocklineV1_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SalesOrderStocklineV1_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderStocklineV1_SalesOrderPartV1] FOREIGN KEY ([SalesOrderPartId]) REFERENCES [dbo].[SalesOrderPartV1] ([SalesOrderPartId]),
    CONSTRAINT [FK_SalesOrderStocklineV1_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);
















GO
CREATE TRIGGER [dbo].[Trg_SalesOrderStocklineV1Audit]
   ON  [dbo].[SalesOrderStocklineV1]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO SalesOrderStocklineV1Audit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END