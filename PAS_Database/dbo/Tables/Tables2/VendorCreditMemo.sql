CREATE TABLE [dbo].[VendorCreditMemo] (
    [VendorCreditMemoId]            BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorCreditMemoNumber]        VARCHAR (100)   NOT NULL,
    [VendorRMAId]                   BIGINT          NULL,
    [RMANum]                        VARCHAR (100)   NULL,
    [VendorCreditMemoStatusId]      INT             NOT NULL,
    [CurrencyId]                    INT             NULL,
    [OriginalAmt]                   DECIMAL (18, 2) NULL,
    [ApplierdAmt]                   DECIMAL (18, 2) NULL,
    [RefundAmt]                     DECIMAL (18, 2) NULL,
    [RefundDate]                    DATETIME2 (7)   NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_VendorCreditMemo_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_VendorCreditMemo_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [DF_VendorCreditMemo_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF_VendorCreditMemo_IsDeleted] DEFAULT ((0)) NOT NULL,
    [VendorId]                      BIGINT          NULL,
    [IsVendorPayment]               BIT             NULL,
    [VendorPaymentDetailsId]        BIGINT          NULL,
    [OpenDate]                      DATETIME2 (7)   NULL,
    [RequestedBy]                   BIGINT          NULL,
    [Notes]                         VARCHAR (MAX)   NULL,
    [VendorCreditMemoTypeId]        INT             NULL,
    [CustomerCreditPaymentDetailId] BIGINT          NULL,
    CONSTRAINT [PK_VendorCreditMemo] PRIMARY KEY CLUSTERED ([VendorCreditMemoId] ASC),
    CONSTRAINT [FK_VendorCreditMemo_VendorRMA] FOREIGN KEY ([VendorRMAId]) REFERENCES [dbo].[VendorRMA] ([VendorRMAId])
);



