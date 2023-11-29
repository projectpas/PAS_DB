﻿CREATE TABLE [dbo].[ExchangeSalesOrderShippingCustomsInfoAudit] (
    [AuditExchangeSalesOrderCustomsInfoId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderCustomsInfoId]      BIGINT          NOT NULL,
    [ExchangeSalesOrderShippingId]         BIGINT          NOT NULL,
    [EntryType]                            VARCHAR (100)   NULL,
    [EPU]                                  VARCHAR (100)   NULL,
    [CustomsValue]                         DECIMAL (20, 2) NULL,
    [NetMass]                              DECIMAL (20, 2) NULL,
    [EntryStatus]                          VARCHAR (100)   NULL,
    [EntryNumber]                          VARCHAR (100)   NULL,
    [VATValue]                             DECIMAL (20, 2) NULL,
    [UCR]                                  VARCHAR (100)   NULL,
    [MasterUCR]                            VARCHAR (100)   NULL,
    [MovementRefNo]                        VARCHAR (100)   NULL,
    [CommodityCode]                        VARCHAR (100)   NULL,
    [MasterCompanyId]                      INT             NOT NULL,
    [CreatedBy]                            VARCHAR (256)   NOT NULL,
    [UpdatedBy]                            VARCHAR (256)   NOT NULL,
    [CreatedDate]                          DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                          DATETIME2 (7)   NOT NULL,
    [IsActive]                             BIT             NOT NULL,
    [IsDeleted]                            BIT             NOT NULL,
    [CustomCurrencyId]                     INT             NULL,
    CONSTRAINT [PK_ExchangeSalesOrderShippingCustomsInfoAudit] PRIMARY KEY CLUSTERED ([AuditExchangeSalesOrderCustomsInfoId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderShippingCustomsInfoAudit_ExchangeSalesOrderShippingCustomsInfo] FOREIGN KEY ([ExchangeSalesOrderCustomsInfoId]) REFERENCES [dbo].[ExchangeSalesOrderShippingCustomsInfo] ([ExchangeSalesOrderCustomsInfoId])
);



