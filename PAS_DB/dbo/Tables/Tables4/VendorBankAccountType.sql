CREATE TABLE [dbo].[VendorBankAccountType] (
    [VendorBankAccountTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [VendorBankAccountType]   VARCHAR (50)  NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_VendorBankAccountType_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_VendorBankAccountType_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_VendorBankAccountType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_VendorBankAccountType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorBankAccountType] PRIMARY KEY CLUSTERED ([VendorBankAccountTypeId] ASC)
);

