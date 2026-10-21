CREATE TABLE [dbo].[VendorACHPayment] (
    [VendorACHPaymentId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]                BIGINT        NOT NULL,
    [PayeeName]               VARCHAR (100) NOT NULL,
    [IntermediateBankName]    VARCHAR (100) NULL,
    [BeneficiaryBankName]     VARCHAR (100) NULL,
    [AccountNumber]           VARCHAR (50)  NOT NULL,
    [ABA]                     VARCHAR (50)  NOT NULL,
    [SwiftCode]               VARCHAR (50)  NULL,
    [GLAccountId]             BIGINT        NULL,
    [VendorBankAccountTypeId] INT           NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_VendorACHPayment_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_VendorACHPayment_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_VendorACHPayment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_VendorACHPayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorACHPayment] PRIMARY KEY CLUSTERED ([VendorACHPaymentId] ASC),
    CONSTRAINT [FK_VendorACHPayment_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_VendorACHPayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO

CREATE TRIGGER [dbo].[Trg_VendorACHPaymentAudit]
   ON  [dbo].[VendorACHPayment]
   AFTER INSERT,UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO [dbo].[VendorACHPaymentAudit] (
		[VendorACHPaymentId], [VendorId], [PayeeName], [IntermediateBankName], [BeneficiaryBankName],
		[AccountNumber], [ABA], [SwiftCode], [GLAccountId], [VendorBankAccountTypeId], [MasterCompanyId],
		[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
	)
	SELECT
		[VendorACHPaymentId], [VendorId], [PayeeName], [IntermediateBankName], [BeneficiaryBankName],
		[AccountNumber], [ABA], [SwiftCode], [GLAccountId], [VendorBankAccountTypeId], [MasterCompanyId],
		[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
	FROM INSERTED;
END
