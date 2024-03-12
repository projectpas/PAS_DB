CREATE TYPE [dbo].[CustomerRfqType] AS TABLE (
    [RfqId]               BIGINT        NULL,
    [RfqCreatedDate]      DATETIME2 (7) NULL,
    [IntegrationPortalId] INT           NULL,
    [Type]                VARCHAR (50)  NULL,
    [Notes]               VARCHAR (100) NULL,
    [BuyerName]           VARCHAR (250) NULL,
    [BuyerCompanyName]    VARCHAR (250) NULL,
    [BuyerAddress]        VARCHAR (250) NULL,
    [BuyerCity]           VARCHAR (50)  NULL,
    [BuyerCountry]        VARCHAR (50)  NULL,
    [BuyerState]          VARCHAR (50)  NULL,
    [BuyerZip]            VARCHAR (50)  NULL,
    [LinePartNumber]      VARCHAR (250) NULL,
    [LineDescription]     VARCHAR (250) NULL,
    [AltPartNumber]       VARCHAR (250) NULL,
    [Quantity]            INT           NULL,
    [Condition]           VARCHAR (50)  NULL);





