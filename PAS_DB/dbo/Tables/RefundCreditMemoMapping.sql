CREATE TABLE [dbo].[RefundCreditMemoMapping] (
    [RefundCreditMemoMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerRefundId]          BIGINT        NOT NULL,
    [CreditMemoHeaderId]        BIGINT        NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (50)  NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_RefundCreditMemoMapping_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_RefundCreditMemoMapping_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [DF__RefundCreditMemoMapping__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [DF__RefundCreditMemoMapping__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RefundCreditMemoMapping] PRIMARY KEY CLUSTERED ([RefundCreditMemoMappingId] ASC),
    CONSTRAINT [FK_RefundCreditMemoMapping_CreditMemoHeaderId] FOREIGN KEY ([CreditMemoHeaderId]) REFERENCES [dbo].[CreditMemo] ([CreditMemoHeaderId]),
    CONSTRAINT [FK_RefundCreditMemoMapping_CustomerRefundId] FOREIGN KEY ([CustomerRefundId]) REFERENCES [dbo].[CustomerRefund] ([CustomerRefundId])
);

