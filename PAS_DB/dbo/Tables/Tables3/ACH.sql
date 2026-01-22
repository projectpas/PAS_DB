CREATE TABLE [dbo].[ACH] (
    [ACHId]                BIGINT        IDENTITY (1, 1) NOT NULL,
    [ABA]                  VARCHAR (50)  NOT NULL,
    [AccountNumber]        VARCHAR (50)  NOT NULL,
    [BankName]             VARCHAR (100) NOT NULL,
    [BeneficiaryBankName]  VARCHAR (100) NULL,
    [IntermediateBankName] VARCHAR (100) NULL,
    [SwiftCode]            VARCHAR (100) NULL,
    [BankAddressId]        BIGINT        NULL,
    [LegalENtityId]        BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_ACH_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_ACH_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_ACH_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_ACH_IdDeleted] DEFAULT ((0)) NOT NULL,
    [GLAccountId]          BIGINT        NULL,
    [IsPrimay]             BIT           NULL,
    CONSTRAINT [PK_ACHId] PRIMARY KEY CLUSTERED ([ACHId] ASC),
    CONSTRAINT [FK_ACH_LegalEntity] FOREIGN KEY ([LegalENtityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_ACHId_Address] FOREIGN KEY ([BankAddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_ACHId_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO








CREATE TRIGGER [dbo].[Trg_ACHAudit] ON [dbo].[ACH]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[ACHAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END