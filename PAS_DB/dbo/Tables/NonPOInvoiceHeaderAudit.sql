﻿CREATE TABLE [dbo].[NonPOInvoiceHeaderAudit] (
    [NonPOInvoiceHeaderAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [NonPOInvoiceId]            BIGINT        NOT NULL,
    [VendorId]                  BIGINT        NOT NULL,
    [VendorName]                VARCHAR (256) NOT NULL,
    [VendorCode]                VARCHAR (256) NOT NULL,
    [PaymentTermsId]            BIGINT        NOT NULL,
    [StatusId]                  INT           NOT NULL,
    [ManagementStructureId]     INT           NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (50)  NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_NonPOInvoiceHeaderAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_NonPOInvoiceHeaderAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [DF__NonPOInvoiceHeaderAudit__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [DF__NonPOInvoiceHeaderAudit__IsDeleted] DEFAULT ((0)) NOT NULL,
    [PaymentMethodId]           BIGINT        NULL,
    [EmployeeId]                BIGINT        NULL,
    [IsEnforceNonPoApproval]    BIT           NULL,
    [ApproverId]                BIGINT        NULL,
    [ApprovedBy]                VARCHAR (100) NULL,
    [DateApproved]              DATETIME2 (7) NULL,
    [NPONumber]                 VARCHAR (150) NULL,
    [EntryDate]                 DATETIME2 (7) NULL,
    [InvoiceNumber]             VARCHAR (150) NULL,
    [InvoiceDate]               DATETIME2 (7) NULL,
    [PONumber]                  VARCHAR (150) NULL,
    [AccountingCalendarId]      BIGINT        NULL,
    [CurrencyId]                BIGINT        NULL,
    [PostedDate]                DATETIME2 (7) NULL,
    [IsUsedInVendorPayment]     BIT           NULL,
    CONSTRAINT [PK_NonPOInvoiceHeaderAudit] PRIMARY KEY CLUSTERED ([NonPOInvoiceHeaderAuditId] ASC)
);



