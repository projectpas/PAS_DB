CREATE TABLE [dbo].[LegalEntityBankingCheque] (
    [LegalEntityBankingChequeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]              BIGINT        NOT NULL,
    [PayeeName]                  VARCHAR (150) NULL,
    [BankName]                   VARCHAR (150) NULL,
    [LockboxNumber]              VARCHAR (80)  NULL,
    [AddressId]                  BIGINT        NOT NULL,
    [GLAccountId]                BIGINT        NULL,
    [IsPrimary]                  BIT           NULL,
    [AccountTypeId]              INT           NULL,
    [AccountType]                VARCHAR (50)  NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [DF_LegalEntityBankingCheque_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [DF_LegalEntityBankingCheque_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LegalEntityBankingCheque] PRIMARY KEY CLUSTERED ([LegalEntityBankingChequeId] ASC),
    CONSTRAINT [FK_LegalEntityBankingCheque_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_LegalEntityBankingCheque_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityBankingCheque_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE   TRIGGER [dbo].[Trg_LegalEntityBankingChequeAudit] ON [dbo].[LegalEntityBankingCheque]

		AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN    

		INSERT INTO [dbo].[LegalEntityBankingChequeAudit]  

		SELECT * FROM INSERTED

		SET NOCOUNT ON;    

END