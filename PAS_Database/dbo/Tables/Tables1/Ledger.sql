CREATE TABLE [dbo].[Ledger] (
    [LedgerId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [LedgerName]      VARCHAR (50)   NOT NULL,
    [LegalEntityId]   BIGINT         NULL,
    [Description]     VARCHAR (250)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Ledger_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Ledger_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_Ledger_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_Ledger_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Ledger] PRIMARY KEY CLUSTERED ([LedgerId] ASC),
    CONSTRAINT [FK_Ledger_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LedgerId_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Ledger] UNIQUE NONCLUSTERED ([LedgerName] ASC, [LegalEntityId] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_LedgerAudit] 

ON [dbo].[Ledger]

AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  



DECLARE @LegalEntityId BIGINT,@LegalEntity VARCHAR(256)



--SELECT @LegalEntityId=LegalEntityId FROM INSERTED



--SELECT @LegalEntity=Name FROM LegalEntity WHERE LegalEntityId=@LegalEntityId



 INSERT INTO [dbo].[LedgerAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END