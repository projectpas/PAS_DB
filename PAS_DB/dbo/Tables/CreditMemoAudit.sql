﻿CREATE TABLE [dbo].[CreditMemoAudit] (
    [CreditMemoHeaderAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CreditMemoHeaderId]      BIGINT          NOT NULL,
    [CreditMemoNumber]        VARCHAR (50)    NOT NULL,
    [RMAHeaderId]             BIGINT          NULL,
    [RMANumber]               VARCHAR (50)    NULL,
    [InvoiceId]               BIGINT          NULL,
    [InvoiceNumber]           VARCHAR (50)    NULL,
    [InvoiceDate]             DATETIME2 (7)   NULL,
    [StatusId]                INT             NOT NULL,
    [Status]                  VARCHAR (50)    NULL,
    [CustomerId]              BIGINT          NOT NULL,
    [CustomerName]            VARCHAR (100)   NULL,
    [CustomerCode]            VARCHAR (50)    NULL,
    [CustomerContactId]       BIGINT          NULL,
    [CustomerContact]         VARCHAR (100)   NULL,
    [CustomerContactPhone]    VARCHAR (20)    NULL,
    [IsWarranty]              BIT             NULL,
    [IsAccepted]              BIT             NULL,
    [ReasonId]                BIGINT          NULL,
    [Reason]                  VARCHAR (50)    NULL,
    [DeniedMemo]              NVARCHAR (MAX)  NULL,
    [RequestedById]           BIGINT          NOT NULL,
    [RequestedBy]             VARCHAR (100)   NULL,
    [ApproverId]              BIGINT          NULL,
    [ApprovedBy]              VARCHAR (100)   NULL,
    [WONum]                   VARCHAR (50)    NULL,
    [WorkOrderId]             BIGINT          NULL,
    [Originalwosonum]         VARCHAR (50)    NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [Notes]                   NVARCHAR (MAX)  NULL,
    [ManagementStructureId]   BIGINT          NOT NULL,
    [IsEnforce]               BIT             NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_CreditMemoAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_CreditMemoAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsWorkOrder]             BIT             NULL,
    [DateApproved]            DATETIME2 (7)   NULL,
    [ReferenceId]             BIGINT          NULL,
    [ReturnDate]              DATETIME2 (7)   NULL,
    [PDFPath]                 NVARCHAR (100)  NULL,
    [FreightBilingMethodId]   INT             NULL,
    [TotalFreight]            DECIMAL (20, 2) NULL,
    [ChargesBilingMethodId]   INT             NULL,
    [TotalCharges]            DECIMAL (18, 2) NULL,
    [Amount]                  DECIMAL (18, 2) NULL,
    [AcctingPeriodId]         BIGINT          NULL,
    [IsStandAloneCM]          BIT             NULL,
    [IsClosed]                BIT             NULL,
    CONSTRAINT [PK_CreditMemoAudit] PRIMARY KEY CLUSTERED ([CreditMemoHeaderAuditId] ASC)
);









