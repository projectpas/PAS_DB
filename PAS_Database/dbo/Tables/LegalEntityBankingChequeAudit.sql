CREATE TABLE [dbo].[LegalEntityBankingChequeAudit] (
    [LegalEntityBankingChequeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityBankingChequeId]      BIGINT        NULL,
    [LegalEntityId]                   BIGINT        NOT NULL,
    [PayeeName]                       VARCHAR (150) NULL,
    [BankName]                        VARCHAR (150) NULL,
    [LockboxNumber]                   VARCHAR (80)  NULL,
    [AddressId]                       BIGINT        NOT NULL,
    [GLAccountId]                     BIGINT        NULL,
    [IsPrimary]                       BIT           NULL,
    [AccountTypeId]                   INT           NULL,
    [AccountType]                     VARCHAR (50)  NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) NOT NULL,
    [IsActive]                        BIT           NOT NULL,
    [IsDeleted]                       BIT           NOT NULL,
    CONSTRAINT [PK_LegalEntityBankingChequeAudit] PRIMARY KEY CLUSTERED ([LegalEntityBankingChequeAuditId] ASC)
);

