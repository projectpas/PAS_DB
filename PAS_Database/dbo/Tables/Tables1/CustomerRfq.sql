CREATE TABLE [dbo].[CustomerRfq] (
    [CustomerRfqId]       BIGINT        IDENTITY (1, 1) NOT NULL,
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
    [Condition]           VARCHAR (50)  NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (50)  NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_CustomerRfq_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]           VARCHAR (50)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_CustomerRfq_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_CustomerRfqIsActi_59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_CustomerRfqIsDele_5AEE82B9] DEFAULT ((0)) NOT NULL,
    [IsQuote]             INT           NULL,
    CONSTRAINT [PK_CustomerRfq] PRIMARY KEY CLUSTERED ([CustomerRfqId] ASC),
    CONSTRAINT [FK_CustomerRfq_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);





