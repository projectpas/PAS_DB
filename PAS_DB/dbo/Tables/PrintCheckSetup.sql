CREATE TABLE [dbo].[PrintCheckSetup] (
    [PrintingId]            BIGINT        IDENTITY (1, 1) NOT NULL,
    [StartNum]              INT           NULL,
    [ConfirmStartNum]       BIT           NULL,
    [BankId]                BIGINT        NULL,
    [BankName]              VARCHAR (100) NULL,
    [BankAccountId]         BIGINT        NULL,
    [BankAccountNumber]     VARCHAR (100) NULL,
    [GLAccountId]           BIGINT        NULL,
    [GlAccount]             VARCHAR (100) NULL,
    [ConfirmBankAccInfo]    BIT           NULL,
    [BankRef]               VARCHAR (100) NULL,
    [CcardPaymentRef]       VARCHAR (100) NULL,
    [Type]                  INT           NULL,
    [MasterCompanyId]       INT           NULL,
    [CreatedBy]             VARCHAR (100) NULL,
    [CreatedDate]           DATETIME      NULL,
    [UpdatedBy]             VARCHAR (100) NULL,
    [UpdatedDate]           DATETIME      NULL,
    [IsActive]              BIT           CONSTRAINT [DF_PrintCheckSetup_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_PrintCheckSetup_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId] BIGINT        NULL,
    CONSTRAINT [PK_PrintCheckSetup] PRIMARY KEY CLUSTERED ([PrintingId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_PrintCheckSetupAudit]
   ON  [dbo].[PrintCheckSetup]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
INSERT INTO PrintCheckSetupAudit
SELECT * FROM INSERTED
SET NOCOUNT ON;
END