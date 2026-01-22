CREATE TABLE [dbo].[CustomerCreditPaymentDetailChild] (
    [CustomerCreditPaymentDetailChildId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerCreditPaymentDetailId]      BIGINT          NOT NULL,
    [PaymentId]                          BIGINT          NOT NULL,
    [Amount]                             DECIMAL (18, 2) NULL,
    [PaidAmount]                         DECIMAL (18, 2) NULL,
    [RemainingAmount]                    DECIMAL (18, 2) NULL,
    [RefundAmount]                       DECIMAL (18, 2) NULL,
    [CheckNumber]                        VARCHAR (50)    NULL,
    [CheckDate]                          DATETIME2 (7)   NULL,
    [IsCheckPayment]                     BIT             NULL,
    [IsWireTransfer]                     BIT             NULL,
    [IsCCDCPayment]                      BIT             NULL,
    [MasterCompanyId]                    INT             NOT NULL,
    [CreatedBy]                          VARCHAR (50)    NOT NULL,
    [CreatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_CustomerCreditPaymentDetailChild_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                          VARCHAR (50)    NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_CustomerCreditPaymentDetailChild_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                           BIT             CONSTRAINT [DF__CustomerCreditPaymentDetailChild__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT             CONSTRAINT [DF__CustomerCreditPaymentDetailChild__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerCreditPaymentDetailChild] PRIMARY KEY CLUSTERED ([CustomerCreditPaymentDetailChildId] ASC)
);

