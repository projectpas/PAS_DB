CREATE TABLE [dbo].[VendorCreditMemoMapping] (
    [VendorCreditMemoMappingId] INT             IDENTITY (1, 1) NOT NULL,
    [VendorCreditMemoId]        BIGINT          NULL,
    [VendorPaymentDetailsId]    BIGINT          NULL,
    [VendorId]                  BIGINT          NULL,
    [Amount]                    DECIMAL (18, 2) NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (50)    NOT NULL,
    [CreatedDate]               DATETIME        CONSTRAINT [DF_VendorCreditMemoMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)    NULL,
    [UpdatedDate]               DATETIME        CONSTRAINT [DF_VendorCreditMemoMapping_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_VendorCreditMemoMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_VendorCreditMemoMapping_IsDeleted] DEFAULT ((0)) NOT NULL,
    [InvoiceType]               INT             NULL,
    [IsPosted]                  BIT             NULL,
    CONSTRAINT [PK_VendorCreditMemoMapping] PRIMARY KEY CLUSTERED ([VendorCreditMemoMappingId] ASC)
);



