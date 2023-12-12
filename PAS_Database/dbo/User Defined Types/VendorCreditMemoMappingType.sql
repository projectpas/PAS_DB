CREATE TYPE [dbo].[VendorCreditMemoMappingType] AS TABLE (
    [VendorCreditMemoId]     BIGINT          NULL,
    [VendorPaymentDetailsId] BIGINT          NULL,
    [VendorId]               BIGINT          NULL,
    [Amount]                 DECIMAL (18, 2) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (50)    NOT NULL,
    [CreatedDate]            DATETIME        NOT NULL,
    [UpdatedBy]              VARCHAR (50)    NULL,
    [UpdatedDate]            DATETIME        NULL,
    [IsActive]               BIT             NOT NULL,
    [IsDeleted]              BIT             NOT NULL,
    [InvoiceType]            INT             NULL);

