﻿CREATE TABLE [dbo].[PrintCheckSetupAudit] (
    [AuditPrintingId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [PrintingId]            BIGINT        NOT NULL,
    [StartNum]              INT           NULL,
    [ConfirmStartNum]       BIT           NULL,
    [BankId]                BIGINT        NULL,
    [BankName]              VARCHAR (100) NULL,
    [BankAccountId]         BIGINT        NULL,
    [BankAccountNumber]     VARCHAR (100) NULL,
    [GLAccountId]           BIGINT        NULL,
    [GlAccount]             VARCHAR (100) NULL,
    [ConfirmBankAccInfo]    BIT           NULL,
    [BankRef]               VARCHAR (100) NULL,
    [CcardPaymentRef]       VARCHAR (100) NULL,
    [Type]                  INT           NULL,
    [MasterCompanyId]       INT           NULL,
    [CreatedBy]             VARCHAR (100) NULL,
    [CreatedDate]           DATETIME      NULL,
    [UpdatedBy]             VARCHAR (100) NULL,
    [UpdatedDate]           DATETIME      NULL,
    [IsActive]              BIT           CONSTRAINT [DF_PrintCheckSetupAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_PrintCheckSetupAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId] BIGINT        NULL,
    [LegalEntityId]         BIGINT        NULL,
    CONSTRAINT [PK_PrintCheckSetupAudit] PRIMARY KEY CLUSTERED ([AuditPrintingId] ASC)
);





