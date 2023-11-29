CREATE TABLE [dbo].[LegalEntityBankingLockBox] (
    [LegalEntityBankingLockBoxId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]               BIGINT        NOT NULL,
    [AddressId]                   BIGINT        NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_LegalEntityBankingLockBox_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [LegalEntityBankingLockBox_DC_Delete] DEFAULT ((0)) NOT NULL,
    [PayeeName]                   VARCHAR (100) NULL,
    [GLAccountId]                 BIGINT        NULL,
    [BankName]                    VARCHAR (100) NULL,
    [BankAccountNumber]           VARCHAR (50)  NULL,
    [IsPrimay]                    BIT           NULL,
    [AccountTypeId]               INT           NULL,
    [AttachmentId]                BIGINT        NULL,
    CONSTRAINT [PK_LegalEntityBankingLockBox] PRIMARY KEY CLUSTERED ([LegalEntityBankingLockBoxId] ASC),
    CONSTRAINT [FK_LegalEntityBankingLockBox_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_LegalEntityBankingLockBox_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityBankingLockBox_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO








CREATE TRIGGER [dbo].[Trg_LegalEntityBankingLockBoxAudit] ON [dbo].[LegalEntityBankingLockBox]

		AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN    

		INSERT INTO [dbo].[LegalEntityBankingLockBoxAudit]  

		SELECT * FROM INSERTED

		SET NOCOUNT ON;    

END