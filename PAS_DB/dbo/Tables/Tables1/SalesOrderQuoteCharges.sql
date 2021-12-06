CREATE TABLE [dbo].[SalesOrderQuoteCharges] (
    [SalesOrderQuoteChargesId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]        BIGINT          NOT NULL,
    [SalesOrderQuotePartId]    BIGINT          NULL,
    [ChargesTypeId]            BIGINT          NOT NULL,
    [VendorId]                 BIGINT          NULL,
    [Quantity]                 INT             NOT NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [Description]              VARCHAR (256)   NULL,
    [UnitCost]                 DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]             DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [MarkupFixedPrice]         DECIMAL (20, 2) NULL,
    [BillingMethodId]          INT             NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [RefNum]                   VARCHAR (20)    NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuoteCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_SalesOrderQuoteCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_SalesOrderQuoteCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [VendorName]               NVARCHAR (100)  NULL,
    [ChargeName]               NVARCHAR (100)  NULL,
    [MarkupName]               NVARCHAR (100)  NULL,
    [ItemMasterId]             BIGINT          NULL,
    [ConditionId]              BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderQuoteCharges] PRIMARY KEY CLUSTERED ([SalesOrderQuoteChargesId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_SalesOrderQuoteCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuoteCharges_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderQuoteCharges_SalesOrderQuoteId] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId])
);


GO


CREATE TRIGGER [dbo].[Trg_SalesOrderQuoteChargesAudit]

   ON  [dbo].[SalesOrderQuoteCharges]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderQuoteChargesAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END