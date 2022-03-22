CREATE TABLE [dbo].[ChargesCurrenciesAudit] (
    [ChargesCurrenciesAuditId] INT          IDENTITY (1, 1) NOT NULL,
    [Id]                       INT          NOT NULL,
    [CreatedBy]                VARCHAR (50) NULL,
    [CreatedDate]              DATETIME     NOT NULL,
    [UpdatedBy]                VARCHAR (50) NULL,
    [UpdatedDate]              DATETIME     NOT NULL,
    [IsDeleted]                BIT          NOT NULL,
    [Name]                     VARCHAR (50) NULL,
    [Symbol]                   VARCHAR (10) NULL,
    CONSTRAINT [PK_ChargesCurrenciesAudit] PRIMARY KEY CLUSTERED ([ChargesCurrenciesAuditId] ASC)
);

