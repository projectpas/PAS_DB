﻿CREATE TYPE [dbo].[SpeedQuoteType] AS TABLE (
    [SpeedQuoteId]           BIGINT          NULL,
    [SpeedQuoteTypeId]       INT             NULL,
    [SpeedQuoteNumber]       VARCHAR (256)   NULL,
    [Version]                INT             NULL,
    [VersionNumber]          VARCHAR (256)   NULL,
    [OpenDate]               DATETIME2 (7)   NULL,
    [ValidForDays]           INT             NULL,
    [QuoteExpireDate]        DATETIME2 (7)   NULL,
    [AccountTypeId]          INT             NULL,
    [CustomerId]             BIGINT          NULL,
    [CustomerContactId]      BIGINT          NULL,
    [CustomerReference]      VARCHAR (256)   NULL,
    [ContractReference]      VARCHAR (256)   NULL,
    [SalesPersonId]          BIGINT          NULL,
    [AgentName]              VARCHAR (256)   NULL,
    [CustomerSeviceRepId]    BIGINT          NULL,
    [ProbabilityId]          BIGINT          NULL,
    [LeadSourceId]           INT             NULL,
    [LeadSourceReference]    VARCHAR (256)   NULL,
    [CreditLimit]            DECIMAL (20, 2) NULL,
    [CreditTermId]           INT             NULL,
    [EmployeeId]             BIGINT          NULL,
    [RestrictPMA]            BIT             NULL,
    [RestrictDER]            BIT             NULL,
    [ApprovedDate]           DATETIME2 (7)   NULL,
    [CurrencyId]             INT             NULL,
    [CustomerWarningId]      BIGINT          NULL,
    [Memo]                   VARCHAR (256)   NULL,
    [Notes]                  VARCHAR (256)   NULL,
    [StatusId]               INT             NULL,
    [StatusName]             VARCHAR (256)   NULL,
    [StatusChangeDate]       DATETIME2 (7)   NULL,
    [ManagementStructureId]  BIGINT          NULL,
    [AgentId]                BIGINT          NULL,
    [QtyRequested]           INT             NULL,
    [QtyToBeQuoted]          INT             NULL,
    [QuoteSentDate]          DATETIME2 (7)   NULL,
    [IsNewVersionCreated]    BIT             NULL,
    [QuoteParentId]          BIGINT          NULL,
    [QuoteTypeName]          VARCHAR (256)   NULL,
    [AccountTypeName]        VARCHAR (256)   NULL,
    [CustomerContactName]    VARCHAR (256)   NULL,
    [CustomerContactEmail]   VARCHAR (256)   NULL,
    [CustomerCode]           VARCHAR (256)   NULL,
    [CustomerName]           VARCHAR (256)   NULL,
    [SalesPersonName]        VARCHAR (256)   NULL,
    [CustomerServiceRepName] VARCHAR (256)   NULL,
    [ProbabilityName]        VARCHAR (256)   NULL,
    [LeadSourceName]         VARCHAR (256)   NULL,
    [CreditTermName]         VARCHAR (256)   NULL,
    [CreditLimitName]        VARCHAR (256)   NULL,
    [EmployeeName]           VARCHAR (256)   NULL,
    [CustomerWarningName]    VARCHAR (256)   NULL,
    [CurrencyName]           VARCHAR (256)   NULL,
    [Level1]                 VARCHAR (256)   NULL,
    [Level2]                 VARCHAR (256)   NULL,
    [Level3]                 VARCHAR (256)   NULL,
    [Level4]                 VARCHAR (256)   NULL,
    [EntityStructureId]      BIGINT          NULL,
    [MSDetailsId]            BIGINT          NULL,
    [LastMSLevel]            VARCHAR (256)   NULL,
    [AllMSlevels]            VARCHAR (256)   NULL);

