CREATE TABLE [dbo].[ExchangeSalesOrderShippingCustomsInfo] (
    [ExchangeSalesOrderCustomsInfoId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderShippingId]    BIGINT          NOT NULL,
    [EntryType]                       VARCHAR (100)   NULL,
    [EPU]                             VARCHAR (100)   NULL,
    [CustomsValue]                    DECIMAL (20, 2) NULL,
    [NetMass]                         DECIMAL (20, 2) NULL,
    [EntryStatus]                     VARCHAR (100)   NULL,
    [EntryNumber]                     VARCHAR (100)   NULL,
    [VATValue]                        DECIMAL (20, 2) NULL,
    [UCR]                             VARCHAR (100)   NULL,
    [MasterUCR]                       VARCHAR (100)   NULL,
    [MovementRefNo]                   VARCHAR (100)   NULL,
    [CommodityCode]                   VARCHAR (100)   NULL,
    [MasterCompanyId]                 INT             NOT NULL,
    [CreatedBy]                       VARCHAR (256)   NOT NULL,
    [UpdatedBy]                       VARCHAR (256)   NOT NULL,
    [CreatedDate]                     DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderShippingCustomsInfo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderShippingCustomsInfo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                        BIT             CONSTRAINT [DF_ExchangeSalesOrderShippingCustomsInfo_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT             CONSTRAINT [DF_ExchangeSalesOrderShippingCustomsInfo_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CustomCurrencyId]                INT             NULL,
    CONSTRAINT [PK_ExchangeSalesOrderShippingCustomsInfo] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderCustomsInfoId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderShippingCustomsInfo_ExchangeSalesOrderShipping] FOREIGN KEY ([ExchangeSalesOrderShippingId]) REFERENCES [dbo].[ExchangeSalesOrderShipping] ([ExchangeSalesOrderShippingId]),
    CONSTRAINT [FK_ExchangeSalesOrderShippingCustomsInfo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderShippingCustomsInfoAudit]

   ON  [dbo].[ExchangeSalesOrderShippingCustomsInfo]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderShippingCustomsInfoAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END