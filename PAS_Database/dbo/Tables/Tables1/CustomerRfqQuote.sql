CREATE TABLE [dbo].[CustomerRfqQuote] (
    [CustomerRfqQuoteId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerRfqId]         BIGINT        NULL,
    [RfqId]                 BIGINT        NULL,
    [AddComment]            VARCHAR (250) NULL,
    [IsAddCommentQuote]     BIT           NULL,
    [FaaEasaRelease]        VARCHAR (250) NULL,
    [IsFaaEasaReleaseQuote] BIT           NULL,
    [RpOh]                  VARCHAR (250) NULL,
    [IsRpOhQuote]           BIT           NULL,
    [LegalEntityId]         BIGINT        NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (50)  NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_CustomerRfqQuote_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (50)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_CustomerRfqQuote_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_CustomerRfqQuoteIsActi_59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_CustomerRfqQuoteIsDele_5AEE82B9] DEFAULT ((0)) NOT NULL,
    [Note]                  VARCHAR (300) NULL,
    CONSTRAINT [PK_CustomerRfqQuote] PRIMARY KEY CLUSTERED ([CustomerRfqQuoteId] ASC),
    CONSTRAINT [FK_CustomerRfqQuote_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);



