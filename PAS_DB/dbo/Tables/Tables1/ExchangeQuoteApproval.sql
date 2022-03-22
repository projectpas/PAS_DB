﻿CREATE TABLE [dbo].[ExchangeQuoteApproval] (
    [ExchangeQuoteApprovalId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteId]         BIGINT         NOT NULL,
    [ExchangeQuotePartId]     BIGINT         NOT NULL,
    [CustomerId]              BIGINT         NOT NULL,
    [InternalMemo]            NVARCHAR (MAX) NULL,
    [InternalSentDate]        DATETIME2 (7)  NULL,
    [InternalApprovedDate]    DATETIME2 (7)  NULL,
    [InternalApprovedById]    BIGINT         NULL,
    [CustomerSentDate]        DATETIME2 (7)  NULL,
    [CustomerApprovedDate]    DATETIME2 (7)  NULL,
    [CustomerApprovedById]    BIGINT         NULL,
    [ApprovalActionId]        INT            NULL,
    [CustomerStatusId]        INT            NULL,
    [InternalStatusId]        INT            NULL,
    [CustomerMemo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_ExchangeQuoteApproval_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_ExchangeQuoteApproval_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_ExchangeQuoteApproval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF_ExchangeQuoteApproval_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CustomerName]            VARCHAR (100)  NULL,
    [InternalApprovedBy]      VARCHAR (100)  NULL,
    [CustomerApprovedBy]      VARCHAR (100)  NULL,
    [ApprovalAction]          VARCHAR (100)  NULL,
    [CustomerStatus]          VARCHAR (50)   NULL,
    [InternalStatus]          VARCHAR (50)   NULL,
    [RejectedById]            BIGINT         NULL,
    [RejectedByName]          VARCHAR (100)  NULL,
    [RejectedDate]            DATETIME2 (7)  NULL,
    CONSTRAINT [PK_ExchangeQuoteApproval] PRIMARY KEY CLUSTERED ([ExchangeQuoteApprovalId] ASC),
    CONSTRAINT [FK_ExchangeQuote_ExchangeQuoteApproval] FOREIGN KEY ([ExchangeQuoteId]) REFERENCES [dbo].[ExchangeQuote] ([ExchangeQuoteId])
);

