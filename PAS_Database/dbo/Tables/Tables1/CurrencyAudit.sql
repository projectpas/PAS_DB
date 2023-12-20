CREATE TABLE [dbo].[CurrencyAudit] (
    [CurrencyAuditId] INT            IDENTITY (1, 1) NOT NULL,
    [CurrencyId]      INT            NOT NULL,
    [Code]            VARCHAR (10)   NOT NULL,
    [Symbol]          VARCHAR (10)   NOT NULL,
    [DisplayName]     VARCHAR (20)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [CountryId]       SMALLINT       NOT NULL,
    [Country]         VARCHAR (100)  NULL,
    CONSTRAINT [PK_CurrencyAudit] PRIMARY KEY CLUSTERED ([CurrencyAuditId] ASC)
);

