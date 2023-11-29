﻿CREATE TABLE [dbo].[SalesOrderAudit] (
    [AuditSalesOrderId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]               BIGINT          NOT NULL,
    [Version]                    INT             NOT NULL,
    [TypeId]                     INT             NOT NULL,
    [OpenDate]                   DATETIME2 (7)   NOT NULL,
    [ShippedDate]                DATETIME2 (7)   NULL,
    [NumberOfItems]              INT             NOT NULL,
    [AccountTypeId]              INT             NOT NULL,
    [CustomerId]                 BIGINT          NOT NULL,
    [CustomerContactId]          BIGINT          NOT NULL,
    [CustomerReference]          VARCHAR (100)   NOT NULL,
    [CurrencyId]                 INT             NULL,
    [TotalSalesAmount]           NUMERIC (9, 2)  NOT NULL,
    [CustomerHold]               NUMERIC (9, 2)  NOT NULL,
    [DepositAmount]              NUMERIC (9, 2)  NOT NULL,
    [BalanceDue]                 DECIMAL (18, 2) NULL,
    [SalesPersonId]              BIGINT          NULL,
    [AgentId]                    BIGINT          NULL,
    [CustomerSeviceRepId]        BIGINT          NULL,
    [EmployeeId]                 BIGINT          NOT NULL,
    [ApprovedById]               BIGINT          NULL,
    [ApprovedDate]               DATETIME2 (7)   NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [StatusId]                   INT             NOT NULL,
    [StatusChangeDate]           DATETIME2 (7)   NOT NULL,
    [Notes]                      NVARCHAR (MAX)  NULL,
    [RestrictPMA]                BIT             NOT NULL,
    [RestrictDER]                BIT             NOT NULL,
    [ManagementStructureId]      BIGINT          NOT NULL,
    [CustomerWarningId]          BIGINT          NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   NOT NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [IsDeleted]                  BIT             NOT NULL,
    [SalesOrderQuoteId]          BIGINT          NULL,
    [QtyRequested]               INT             NULL,
    [QtyToBeQuoted]              INT             NULL,
    [SalesOrderNumber]           VARCHAR (50)    NOT NULL,
    [IsActive]                   BIT             NOT NULL,
    [ContractReference]          VARCHAR (100)   NULL,
    [TypeName]                   VARCHAR (50)    NULL,
    [AccountTypeName]            VARCHAR (256)   NULL,
    [CustomerName]               VARCHAR (100)   NULL,
    [SalesPersonName]            VARCHAR (80)    NULL,
    [CustomerServiceRepName]     VARCHAR (80)    NULL,
    [EmployeeName]               VARCHAR (80)    NULL,
    [CurrencyName]               VARCHAR (50)    NULL,
    [CustomerWarningName]        VARCHAR (300)   NULL,
    [ManagementStructureName]    VARCHAR (286)   NULL,
    [CreditLimit]                DECIMAL (18, 2) NULL,
    [CreditTermId]               INT             NULL,
    [CreditLimitName]            VARCHAR (50)    NULL,
    [CreditTermName]             VARCHAR (50)    NULL,
    [VersionNumber]              VARCHAR (50)    NULL,
    [TotalFreight]               DECIMAL (20, 2) NULL,
    [TotalCharges]               DECIMAL (20, 2) NULL,
    [FreightBilingMethodId]      INT             NULL,
    [ChargesBilingMethodId]      INT             NULL,
    [EnforceEffectiveDate]       DATETIME2 (7)   NULL,
    [IsEnforceApproval]          BIT             NULL,
    [Level1]                     VARCHAR (200)   NULL,
    [Level2]                     VARCHAR (200)   NULL,
    [Level3]                     VARCHAR (200)   NULL,
    [Level4]                     VARCHAR (200)   NULL,
    [ATAPDFPath]                 VARCHAR (MAX)   NULL,
    [LotId]                      BIGINT          NULL,
    [IsLotAssigned]              BIT             NULL,
    [AllowInvoiceBeforeShipping] BIT             NULL,
    CONSTRAINT [PK_SalesOrderAudit] PRIMARY KEY CLUSTERED ([AuditSalesOrderId] ASC),
    CONSTRAINT [FK_SalesOrderAudit_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId])
);



