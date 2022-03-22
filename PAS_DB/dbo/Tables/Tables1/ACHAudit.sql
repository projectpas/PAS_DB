CREATE TABLE [dbo].[ACHAudit] (
    [ACHAuditId]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [ACHId]                BIGINT        NOT NULL,
    [ABA]                  VARCHAR (50)  NULL,
    [AccountNumber]        VARCHAR (50)  NULL,
    [BankName]             VARCHAR (100) NULL,
    [BeneficiaryBankName]  VARCHAR (100) NULL,
    [IntermediateBankName] VARCHAR (100) NULL,
    [SwiftCode]            VARCHAR (100) NULL,
    [BankAddressId]        BIGINT        NULL,
    [LegalENtityId]        BIGINT        NULL,
    [MasterCompanyId]      INT           NULL,
    [CreatedBy]            VARCHAR (256) NULL,
    [UpdatedBy]            VARCHAR (256) NULL,
    [CreatedDate]          DATETIME2 (7) NULL,
    [UpdatedDate]          DATETIME2 (7) NULL,
    [IsActive]             BIT           NULL,
    [IsDeleted]            BIT           NULL,
    [GLAccountId]          BIGINT        NULL,
    CONSTRAINT [PK__ACHAudit__854679C8D5100FF3] PRIMARY KEY CLUSTERED ([ACHAuditId] ASC),
    CONSTRAINT [FK_ACHAudit_ACH] FOREIGN KEY ([ACHId]) REFERENCES [dbo].[ACH] ([ACHId])
);

