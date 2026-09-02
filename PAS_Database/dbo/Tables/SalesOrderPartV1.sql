CREATE TABLE [dbo].[SalesOrderPartV1] (
    [SalesOrderPartId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]          BIGINT          NOT NULL,
    [ItemMasterId]          BIGINT          NOT NULL,
    [ConditionId]           BIGINT          NOT NULL,
    [QtyRequested]          DECIMAL (18, 6) NULL,
    [QtyOrder]              DECIMAL (18, 6) NULL,
    [QtyReserved]           DECIMAL (18, 6) NULL,
    [CurrencyId]            INT             NULL,
    [PriorityId]            BIGINT          NOT NULL,
    [StatusId]              INT             NOT NULL,
    [FxRate]                DECIMAL (18, 6) NULL,
    [CustomerRequestDate]   DATETIME2 (7)   NULL,
    [PromisedDate]          DATETIME2 (7)   NULL,
    [EstimatedShipDate]     DATETIME2 (7)   NULL,
    [POId]                  BIGINT          NULL,
    [PONumber]              VARCHAR (256)   NULL,
    [PONextDlvrDate]        DATETIME2 (7)   NULL,
    [Notes]                 NVARCHAR (MAX)  NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SalesOrderPartV1_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SalesOrderPartV1_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_SalesOrderPartV1_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_SalesOrderPartV1_IsDeleted] DEFAULT ((0)) NOT NULL,
    [OldSalesOrderPartId]   BIGINT          NULL,
    [PartNumber]            VARCHAR (200)   NULL,
    [PartDescription]       VARCHAR (MAX)   NULL,
    [ConditionName]         VARCHAR (100)   NULL,
    [CurrencyName]          VARCHAR (100)   NULL,
    [PriorityName]          VARCHAR (100)   NULL,
    [StatusName]            VARCHAR (100)   NULL,
    [SalesOrderQuotePartId] BIGINT          NULL,
    [LotId]                 BIGINT          NULL,
    [IsLotAssigned]         BIT             NULL,
    [ECCN]                  VARCHAR (200)   NULL,
    [HSCODE]                VARCHAR (200)   NULL,
    [Weight]                DECIMAL (18, 6) NULL,
    [SizeLength]            DECIMAL (18, 6) NULL,
    [SizeWidth]             DECIMAL (18, 6) NULL,
    [SizeHeight]            DECIMAL (18, 6) NULL,
    [AltOrEqType]           VARCHAR (50)    NULL,
    [UnitSalesPrice]        DECIMAL (18, 6) NULL,
    [SequenceNumber]        BIGINT          NULL,
    [ToTalReservedQty]      DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_SalesOrderPartV1] PRIMARY KEY CLUSTERED ([SalesOrderPartId] ASC),
    CONSTRAINT [FK_SalesOrderPartV1_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SalesOrderPartV1_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_SalesOrderPartV1_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SalesOrderPartV1_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderPartV1_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_SalesOrderPartV1_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId])
);






















GO
CREATE TRIGGER [dbo].[Trg_SalesOrderPartV1Audit]
   ON  [dbo].[SalesOrderPartV1]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO SalesOrderPartV1Audit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END