CREATE TABLE [dbo].[VendorCreditMemoDetail] (
    [VendorCreditMemoDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorCreditMemoId]       BIGINT          NOT NULL,
    [VendorRMADetailId]        BIGINT          NULL,
    [VendorRMAId]              BIGINT          NULL,
    [Qty]                      BIGINT          NULL,
    [Notes]                    VARCHAR (MAX)   NULL,
    [OriginalAmt]              DECIMAL (18, 2) NULL,
    [ApplierdAmt]              DECIMAL (18, 2) NULL,
    [RefundAmt]                DECIMAL (18, 2) NULL,
    [RefundDate]               DATETIME2 (7)   NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_VendorCreditMemoDetail_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_VendorCreditMemoDetail_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_VendorCreditMemoDetail_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_VendorCreditMemoDetail_IsDeleted] DEFAULT ((0)) NOT NULL,
    [UnitCost]                 DECIMAL (18, 2) NULL,
    [StockLineId]              BIGINT          NULL,
    CONSTRAINT [PK_VendorCreditMemoDetail] PRIMARY KEY CLUSTERED ([VendorCreditMemoDetailId] ASC)
);



