﻿CREATE TABLE [dbo].[CustomerCreditPaymentDetail] (
    [CustomerCreditPaymentDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceiptId]                     BIGINT          NOT NULL,
    [CustomerId]                    BIGINT          NOT NULL,
    [CustomerName]                  VARCHAR (100)   NULL,
    [CustomerCode]                  VARCHAR (100)   NULL,
    [StatusId]                      INT             NULL,
    [PaymentId]                     BIGINT          NULL,
    [ReceiveDate]                   DATETIME2 (7)   NULL,
    [ReferenceNumber]               VARCHAR (100)   NULL,
    [TotalAmount]                   DECIMAL (18, 2) NULL,
    [PaidAmount]                    DECIMAL (18, 2) NULL,
    [RemainingAmount]               DECIMAL (18, 2) NULL,
    [RefundAmount]                  DECIMAL (18, 2) NULL,
    [CheckNumber]                   VARCHAR (50)    NULL,
    [CheckDate]                     DATETIME2 (7)   NULL,
    [IsCheckPayment]                BIT             NULL,
    [IsWireTransfer]                BIT             NULL,
    [IsCCDCPayment]                 BIT             NULL,
    [IsProcessed]                   BIT             NULL,
    [Memo]                          VARCHAR (500)   NULL,
    [VendorId]                      BIGINT          NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (50)    NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_CustomerCreditPaymentDetail_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                     VARCHAR (50)    NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_CustomerCreditPaymentDetail_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [DF__CustomerCreditPaymentDetail__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF__CustomerCreditPaymentDetail__IsDeleted] DEFAULT ((0)) NOT NULL,
    [SuspenseUnappliedNumber]       VARCHAR (30)    NULL,
    [IsMiscellaneous]               BIT             NULL,
    [CreditMemoHeaderId]            BIGINT          NULL,
    [ProcessedDate]                 DATETIME2 (7)   NULL,
    [ManagementStructureId]         BIGINT          NULL,
    [MappingCustomerId]             BIGINT          NULL,
    CONSTRAINT [PK_CustomerCreditPaymentDetail] PRIMARY KEY CLUSTERED ([CustomerCreditPaymentDetailId] ASC)
);













