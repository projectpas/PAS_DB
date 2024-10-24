﻿CREATE TABLE [dbo].[ExchangeSalesOrderAudit] (
    [AuditExchangeSalesOrderId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]      BIGINT          NOT NULL,
    [Version]                   INT             CONSTRAINT [DF_ExchangeSalesOrderAudit_Version] DEFAULT ((1)) NOT NULL,
    [TypeId]                    INT             NOT NULL,
    [OpenDate]                  DATETIME2 (7)   NOT NULL,
    [ShippedDate]               DATETIME2 (7)   NULL,
    [NumberOfItems]             INT             CONSTRAINT [DF_ExchangeSalesOrderAudit_NumberOfItems] DEFAULT ((0)) NOT NULL,
    [AccountTypeId]             INT             NULL,
    [CustomerId]                BIGINT          NOT NULL,
    [CustomerContactId]         BIGINT          NOT NULL,
    [CustomerReference]         VARCHAR (100)   NULL,
    [CurrencyId]                INT             NULL,
    [TotalSalesAmount]          NUMERIC (9, 2)  CONSTRAINT [DF_ExchangeSalesOrderAudit_TotalSalesAmount] DEFAULT ((0)) NOT NULL,
    [CustomerHold]              NUMERIC (9, 2)  CONSTRAINT [DF_ExchangeSalesOrderAudit_CustomerHold] DEFAULT ((0)) NOT NULL,
    [DepositAmount]             NUMERIC (9, 2)  CONSTRAINT [DF_ExchangeSalesOrderAudit_DepositAmount] DEFAULT ((0)) NOT NULL,
    [BalanceDue]                DECIMAL (18, 2) NULL,
    [SalesPersonId]             BIGINT          NULL,
    [AgentId]                   BIGINT          NULL,
    [CustomerSeviceRepId]       BIGINT          NULL,
    [EmployeeId]                BIGINT          NOT NULL,
    [ApprovedById]              BIGINT          NULL,
    [ApprovedDate]              DATETIME2 (7)   NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [StatusId]                  INT             CONSTRAINT [DF_ExchangeSalesOrderAudit_StatusId] DEFAULT ((1)) NOT NULL,
    [StatusChangeDate]          DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderAudit_StatusChangeDate] DEFAULT (getdate()) NOT NULL,
    [Notes]                     NVARCHAR (MAX)  NULL,
    [RestrictPMA]               BIT             CONSTRAINT [DF_ExchangeSalesOrderAudit_RestrictPMA] DEFAULT ((0)) NOT NULL,
    [RestrictDER]               BIT             CONSTRAINT [DF_ExchangeSalesOrderAudit_RestrictDER] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]     BIGINT          NOT NULL,
    [CustomerWarningId]         BIGINT          NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_ExchangeSalesOrderAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ExchangeQuoteId]           BIGINT          NULL,
    [QtyRequested]              INT             CONSTRAINT [DF_ExchangeSalesOrderAudit_QtyRequested] DEFAULT ((0)) NULL,
    [QtyToBeQuoted]             INT             CONSTRAINT [DF_ExchangeSalesOrderAudit_QtyToBeQuoted] DEFAULT ((0)) NULL,
    [ExchangeSalesOrderNumber]  VARCHAR (50)    NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_ExchangeSalesOrderAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [ContractReference]         VARCHAR (100)   NULL,
    [TypeName]                  VARCHAR (50)    NULL,
    [AccountTypeName]           VARCHAR (256)   NULL,
    [CustomerName]              VARCHAR (100)   NULL,
    [CustomerCode]              VARCHAR (100)   NULL,
    [SalesPersonName]           VARCHAR (80)    NULL,
    [CustomerServiceRepName]    VARCHAR (80)    NULL,
    [EmployeeName]              VARCHAR (80)    NULL,
    [CurrencyName]              VARCHAR (50)    NULL,
    [CustomerWarningName]       VARCHAR (300)   NULL,
    [ManagementStructureName]   VARCHAR (286)   NULL,
    [CreditLimit]               DECIMAL (18, 2) NULL,
    [CreditTermId]              INT             NULL,
    [CreditLimitName]           VARCHAR (50)    NULL,
    [CreditTermName]            VARCHAR (50)    NULL,
    [VersionNumber]             VARCHAR (50)    NULL,
    [ExchangeQuoteNumber]       VARCHAR (50)    NULL,
    [IsApproved]                BIT             NULL,
    [CoreAccepted]              BIT             DEFAULT ((0)) NOT NULL,
    [IsVendor]                  BIT             NULL,
    [IsFreightFlatRate]         BIT             NULL,
    [FreightFlatRate]           DECIMAL (18, 2) NULL,
    [IsChargeFlatRate]          BIT             NULL,
    [ChargeFlatRate]            DECIMAL (18, 2) NULL,
    [IsFreightFlatRateInsert]   BIT             NULL,
    [IsChargeFlatRateInsert]    BIT             NULL,
    [PercentId]                 BIGINT          NULL,
    [Days]                      INT             NULL,
    [NetDays]                   INT             NULL,
    [FunctionalCurrencyId]      INT             NULL,
    [ReportCurrencyId]          INT             NULL,
    [ForeignExchangeRate]       DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_ExchangeSalesOrderAudit_1] PRIMARY KEY CLUSTERED ([AuditExchangeSalesOrderId] ASC)
);















