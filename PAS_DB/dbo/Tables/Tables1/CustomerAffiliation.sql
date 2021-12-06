CREATE TABLE [dbo].[CustomerAffiliation] (
    [CustomerAffiliationId] INT            IDENTITY (1, 1) NOT NULL,
    [Description]           NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [D_CA_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [D_CA_UD] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [IsActive]              BIT            CONSTRAINT [D_CA_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [D_CA_Delete] DEFAULT ((0)) NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [AccountType]           VARCHAR (256)  NOT NULL,
    CONSTRAINT [PK_CustomerAffiliation] PRIMARY KEY CLUSTERED ([CustomerAffiliationId] ASC),
    CONSTRAINT [Unique_CustomerAffiliation] UNIQUE NONCLUSTERED ([AccountType] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_CustomerAffiliationAudit]

   ON  [dbo].[CustomerAffiliation]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO CustomerAffiliationAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END