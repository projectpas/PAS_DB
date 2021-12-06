CREATE TABLE [dbo].[SpeedQuotePart] (
    [SpeedQuotePartId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [SpeedQuoteId]             BIGINT          NULL,
    [ItemMasterId]             BIGINT          NULL,
    [QuantityRequested]        INT             NULL,
    [ConditionId]              BIGINT          CONSTRAINT [DF_SpeedQuotePart_ConditionId] DEFAULT ((0)) NOT NULL,
    [UnitSalePrice]            NUMERIC (18, 2) NULL,
    [UnitCost]                 NUMERIC (18, 2) CONSTRAINT [DF_SpeedQuotePart_UnitCost] DEFAULT ((0)) NULL,
    [MarginAmount]             NUMERIC (18, 2) CONSTRAINT [DF_SpeedQuotePart_MarginAmount] DEFAULT ((0)) NULL,
    [MarginPercentage]         NUMERIC (18, 2) NULL,
    [SalesPriceExtended]       NUMERIC (18, 2) CONSTRAINT [DF_SpeedQuotePart_SalesPriceExtended] DEFAULT ((0)) NULL,
    [UnitCostExtended]         NUMERIC (18, 2) CONSTRAINT [DF_SpeedQuotePart_UnitCostExtended] DEFAULT ((0)) NULL,
    [MarginAmountExtended]     NUMERIC (18, 2) CONSTRAINT [DF_SpeedQuotePart_MarginAmountExtended] DEFAULT ((0)) NULL,
    [MarginPercentageExtended] NUMERIC (18, 2) CONSTRAINT [DF_Table_1_MarginAmountExtended1] DEFAULT ((0)) NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SpeedQuotePart_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SpeedQuotePart_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_SpeedQuotePart_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_SpeedQuotePart_IsActive] DEFAULT ((1)) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [Notes]                    NVARCHAR (MAX)  NULL,
    [CurrencyId]               INT             NULL,
    [PartNumber]               NVARCHAR (100)  NULL,
    [PartDescription]          NVARCHAR (MAX)  NULL,
    [ConditionName]            NVARCHAR (100)  NULL,
    [CurrencyName]             NVARCHAR (100)  NULL,
    [ManufacturerId]           BIGINT          NULL,
    [Manufacturer]             VARCHAR (50)    NULL,
    [Type]                     VARCHAR (50)    NULL,
    [TAT]                      INT             CONSTRAINT [DF_SpeedQuotePart_TAT] DEFAULT ((0)) NULL,
    [StatusId]                 INT             NULL,
    [StatusName]               NVARCHAR (100)  NULL,
    [ItemNo]                   INT             DEFAULT ((0)) NOT NULL,
    [Code]                     VARCHAR (100)   NULL,
    CONSTRAINT [PK_SpeedQuotePart] PRIMARY KEY CLUSTERED ([SpeedQuotePartId] ASC),
    CONSTRAINT [FK_SpeedQuote_SpeedQuotePart] FOREIGN KEY ([SpeedQuoteId]) REFERENCES [dbo].[SpeedQuote] ([SpeedQuoteId])
);


GO


CREATE TRIGGER [dbo].[Trg_SpeedQuotePartAudit]

   ON  [dbo].[SpeedQuotePart]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SpeedQuotePartAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END