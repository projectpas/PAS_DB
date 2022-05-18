﻿CREATE TABLE [dbo].[ExchangeQuoteApprovalAudit] (
    [AuditExchangeQuoteApprovalId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeQuoteApprovalId]      BIGINT         NOT NULL,
    [ExchangeQuoteId]              BIGINT         NOT NULL,
    [ExchangeQuotePartId]          BIGINT         NOT NULL,
    [CustomerId]                   BIGINT         NOT NULL,
    [InternalMemo]                 NVARCHAR (MAX) NULL,
    [InternalSentDate]             DATETIME2 (7)  NULL,
    [InternalApprovedDate]         DATETIME2 (7)  NULL,
    [InternalApprovedById]         BIGINT         NULL,
    [CustomerSentDate]             DATETIME2 (7)  NULL,
    [CustomerApprovedDate]         DATETIME2 (7)  NULL,
    [CustomerApprovedById]         BIGINT         NULL,
    [ApprovalActionId]             INT            NULL,
    [CustomerStatusId]             INT            NULL,
    [InternalStatusId]             INT            NULL,
    [CustomerMemo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NOT NULL,
    [UpdatedBy]                    VARCHAR (256)  NOT NULL,
    [CreatedDate]                  DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  NOT NULL,
    [IsActive]                     BIT            NOT NULL,
    [IsDeleted]                    BIT            NOT NULL,
    [CustomerName]                 VARCHAR (100)  NULL,
    [InternalApprovedBy]           VARCHAR (100)  NULL,
    [CustomerApprovedBy]           VARCHAR (100)  NULL,
    [ApprovalAction]               VARCHAR (100)  NULL,
    [CustomerStatus]               VARCHAR (50)   NULL,
    [InternalStatus]               VARCHAR (50)   NULL,
    [RejectedById]                 BIGINT         NULL,
    [RejectedByName]               VARCHAR (100)  NULL,
    [RejectedDate]                 DATETIME2 (7)  NULL,
    [InternalSentToId]             BIGINT         NULL,
    [InternalSentToName]           VARCHAR (100)  NULL,
    [InternalSentById]             BIGINT         NULL,
    [InternalRejectedById]         BIGINT         NULL,
    [InternalRejectedBy]           VARCHAR (100)  NULL,
    [InternalRejectedDate]         DATETIME2 (7)  NULL,
    CONSTRAINT [PK_ExchangeQuoteApprovalAudit] PRIMARY KEY CLUSTERED ([AuditExchangeQuoteApprovalId] ASC)
);





