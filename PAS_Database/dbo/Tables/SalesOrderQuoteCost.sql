CREATE TABLE [dbo].[SalesOrderQuoteCost] (
    [SalesOrderQuoteCostId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]     BIGINT          NOT NULL,
    [SubTotal]              DECIMAL (18, 4) NULL,
    [SalesTax]              DECIMAL (18, 4) NULL,
    [OtherTax]              DECIMAL (18, 4) NULL,
    [MiscCharges]           DECIMAL (18, 4) NULL,
    [Freight]               DECIMAL (18, 4) NULL,
    [NetTotal]              DECIMAL (18, 4) NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteCost_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteCost_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_SalesOrderQuoteCost_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_SalesOrderQuoteCost_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderQuoteCost] PRIMARY KEY CLUSTERED ([SalesOrderQuoteCostId] ASC)
);

