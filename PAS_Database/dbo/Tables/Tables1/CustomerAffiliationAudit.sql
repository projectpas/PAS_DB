CREATE TABLE [dbo].[CustomerAffiliationAudit] (
    [AuditCustomerAffiliationId] INT            IDENTITY (1, 1) NOT NULL,
    [CustomerAffiliationId]      INT            NOT NULL,
    [Description]                NVARCHAR (500) NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedDate]                DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [IsActive]                   BIT            NOT NULL,
    [IsDeleted]                  BIT            NOT NULL,
    [Memo]                       NVARCHAR (MAX) NULL,
    [AccountType]                VARCHAR (256)  NOT NULL,
    CONSTRAINT [PK_CustomerAffiliationAudit] PRIMARY KEY CLUSTERED ([AuditCustomerAffiliationId] ASC),
    CONSTRAINT [FK_CustomerAffiliationAudit_CustomerAffiliation] FOREIGN KEY ([CustomerAffiliationId]) REFERENCES [dbo].[CustomerAffiliation] ([CustomerAffiliationId])
);

