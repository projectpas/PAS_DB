﻿CREATE TABLE [dbo].[CustomerPaymentsAudit] (
    [ReceiptAuditId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceiptId]             BIGINT          NOT NULL,
    [ReceiptNo]             VARCHAR (100)   NOT NULL,
    [BankName]              INT             NULL,
    [BankAcctNum]           INT             NULL,
    [DepositDate]           DATETIME        NULL,
    [AcctingPeriod]         BIGINT          NULL,
    [Amount]                DECIMAL (20, 2) NOT NULL,
    [AmtApplied]            DECIMAL (20, 2) NULL,
    [AmtRemaining]          DECIMAL (20, 2) NULL,
    [Reference]             VARCHAR (100)   NULL,
    [CntrlNum]              VARCHAR (100)   NULL,
    [ManagementStructureId] BIGINT          NULL,
    [OpenDate]              DATETIME        NULL,
    [StatusId]              INT             NOT NULL,
    [PostedDate]            DATETIME        NULL,
    [EmployeeId]            BIGINT          NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   NOT NULL,
    [IsActive]              BIT             NOT NULL,
    [IsDeleted]             BIT             NOT NULL,
    [LEVEL1]                VARCHAR (256)   NULL,
    [LEVEL2]                VARCHAR (256)   NULL,
    [LEVEL3]                VARCHAR (256)   NULL,
    [LEVEL4]                VARCHAR (256)   NULL,
    [GLAccountId]           BIGINT          NULL,
    [LegalEntityId]         BIGINT          NULL,
    [BankType]              VARCHAR (50)    NULL,
    [CurrencyId]            INT             NULL,
    CONSTRAINT [PK_CustomerPaymentsAudit] PRIMARY KEY CLUSTERED ([ReceiptAuditId] ASC)
);





