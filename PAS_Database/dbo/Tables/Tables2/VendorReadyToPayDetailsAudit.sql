﻿CREATE TABLE [dbo].[VendorReadyToPayDetailsAudit] (
    [ReadyToPayDetailsAuditId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReadyToPayDetailsId]           BIGINT          NOT NULL,
    [ReadyToPayId]                  BIGINT          NULL,
    [DueDate]                       DATETIME2 (7)   NULL,
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
    [DiscountAvailable]             DECIMAL (18, 2) NULL,
    [DiscountToken]                 DECIMAL (18, 2) NULL,
    [MasterCompanyId]               INT             NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             NOT NULL,
    [IsDeleted]                     BIT             NOT NULL,
    [VendorPaymentDetailsId]        BIGINT          NULL,
    [PdfPath]                       NVARCHAR (MAX)  NULL,
    [CheckNumber]                   NVARCHAR (MAX)  NULL,
    [CheckDate]                     DATETIME        NULL,
    [IsVoidedCheck]                 BIT             NULL,
    [IsCreditMemo]                  BIT             NULL,
    [CreditMemoAmount]              DECIMAL (18, 2) NULL,
    [CreditMemoHeaderId]            BIGINT          NULL,
    [IsCheckPrinted]                BIT             NULL,
    [VendorReadyToPayDetailsTypeId] INT             NULL,
    [NonPOInvoiceId]                BIGINT          NULL,
    [IsGenerated]                   BIT             NULL,
    [CustomerCreditPaymentDetailId] BIGINT          NULL,
    [ControlNumber]                 VARCHAR (250)   NULL,
    CONSTRAINT [PK_VendorReadyToPayDetailsAudit] PRIMARY KEY CLUSTERED ([ReadyToPayDetailsAuditId] ASC)
);









