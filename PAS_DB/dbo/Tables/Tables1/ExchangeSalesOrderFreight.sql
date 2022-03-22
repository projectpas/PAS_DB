CREATE TABLE [dbo].[ExchangeSalesOrderFreight] (
    [ExchangeSalesOrderFreightId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]        BIGINT          NOT NULL,
    [ExchangeSalesOrderPartId]    BIGINT          NULL,
    [ShipViaId]                   BIGINT          NOT NULL,
    [Weight]                      VARCHAR (50)    NULL,
    [Memo]                        NVARCHAR (MAX)  NULL,
    [Amount]                      DECIMAL (20, 3) NULL,
    [MarkupPercentageId]          BIGINT          NULL,
    [MarkupFixedPrice]            DECIMAL (20, 2) NULL,
    [HeaderMarkupId]              BIGINT          NULL,
    [BillingMethodId]             INT             NULL,
    [BillingRate]                 DECIMAL (20, 2) NULL,
    [BillingAmount]               DECIMAL (20, 2) NULL,
    [Length]                      DECIMAL (10, 2) NULL,
    [Width]                       DECIMAL (10, 2) NULL,
    [Height]                      DECIMAL (10, 2) NULL,
    [UOMId]                       BIGINT          NULL,
    [DimensionUOMId]              BIGINT          NULL,
    [CurrencyId]                  INT             NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT             CONSTRAINT [DF_ExchangeSalesOrderFreight_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT             CONSTRAINT [DF_ExchangeSalesOrderFreight_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId]    BIGINT          NULL,
    [ShipViaName]                 NVARCHAR (100)  NULL,
    [UOMName]                     NVARCHAR (100)  NULL,
    [DimensionUOMName]            NVARCHAR (100)  NULL,
    [CurrencyName]                NVARCHAR (100)  NULL,
    [IsInsert]                    BIT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeSalesOrderFreight] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderFreightId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderFreight_ExchangeSalesOrder] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId]),
    CONSTRAINT [FK_ExchangeSalesOrderFreight_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeSalesOrderFreight_ShippingVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId])
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderFreightAudit]

   ON  [dbo].[ExchangeSalesOrderFreight]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderFreightAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END