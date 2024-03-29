﻿CREATE TABLE [dbo].[VendorPaymentDetailsAudit] (
    [AuditVendorPaymentId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorPaymentId]               BIGINT          NOT NULL,
    [ReadyToPayId]                  BIGINT          NULL,
    [DueDate]                       DATETIME        NULL,
    [VendorId]                      BIGINT          NULL,
    [VendorName]                    VARCHAR (100)   NULL,
    [PaymentMethodId]               INT             NULL,
    [PaymentMethodName]             VARCHAR (50)    NULL,
    [ReceivingReconciliationId]     BIGINT          NULL,
    [InvoiceNum]                    VARCHAR (100)   NULL,
    [CurrencyId]                    INT             NULL,
    [CurrencyName]                  VARCHAR (50)    NULL,
    [FXRate]                        NUMERIC (9, 4)  NULL,
    [OriginalAmount]                DECIMAL (18, 2) NULL,
    [PaymentMade]                   DECIMAL (18, 2) NULL,
    [AmountDue]                     DECIMAL (18, 2) NULL,
    [DaysPastDue]                   INT             NULL,
    [DiscountDate]                  DATETIME        NULL,
    [DiscountAvailable]             INT             NULL,
    [DiscountToken]                 DECIMAL (18, 2) NULL,
    [RRTotal]                       DECIMAL (18, 2) NULL,
    [InvoiceTotal]                  DECIMAL (18, 2) NULL,
    [DIfferenceAmount]              DECIMAL (18, 2) NULL,
    [TotalAdjustAmount]             DECIMAL (18, 2) NULL,
    [MasterCompanyId]               INT             NULL,
    [StatusId]                      INT             NULL,
    [Status]                        VARCHAR (50)    NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_VendorPaymentDetailsAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_VendorPaymentDetailsAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [DF_VendorPaymentDetailsAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF_VendorPaymentDetailsAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [NonPOInvoiceId]                BIGINT          NULL,
    [CustomerCreditPaymentDetailId] BIGINT          NULL,
    [CreditMemoHeaderId]            BIGINT          NULL,
    CONSTRAINT [PK_VendorPaymentDetailsAudit] PRIMARY KEY CLUSTERED ([AuditVendorPaymentId] ASC)
);





