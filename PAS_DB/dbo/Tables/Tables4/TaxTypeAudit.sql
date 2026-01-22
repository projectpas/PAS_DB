CREATE TABLE [dbo].[TaxTypeAudit] (
    [TaxTypeAuditId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [TaxTypeId]       INT            NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [Code]            VARCHAR (100)  NULL,
    PRIMARY KEY CLUSTERED ([TaxTypeAuditId] ASC)
);

