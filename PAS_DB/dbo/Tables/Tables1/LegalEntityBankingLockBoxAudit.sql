CREATE TABLE [dbo].[LegalEntityBankingLockBoxAudit] (
    [LegalEntityBankingLockBoxAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityBankingLockBoxId]      BIGINT        NOT NULL,
    [LegalEntityId]                    BIGINT        NOT NULL,
    [AddressId]                        BIGINT        NOT NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NULL,
    [UpdatedBy]                        VARCHAR (256) NULL,
    [CreatedDate]                      DATETIME2 (7) CONSTRAINT [DF_LegalEntityBankingLockBoxAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) CONSTRAINT [DF_LegalEntityBankingLockBoxAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                         BIT           CONSTRAINT [DF_LegalEntityBankingLockBoxAudit_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]                        BIT           CONSTRAINT [DF_LegalEntityBankingLockBoxAudit_IsDeleted] DEFAULT ((0)) NULL,
    [PayeeName]                        VARCHAR (100) NULL,
    [GLAccountId]                      BIGINT        NULL,
    [BankName]                         VARCHAR (100) NULL,
    [BankAccountNumber]                VARCHAR (50)  NULL,
    [IsPrimay]                         BIT           NULL,
    [AccountTypeId]                    INT           NULL,
    [AttachmentId]                     BIGINT        NULL,
    CONSTRAINT [PK_LegalEntityBankingLockBoxAudit] PRIMARY KEY CLUSTERED ([LegalEntityBankingLockBoxAuditId] ASC)
);





