CREATE TABLE [dbo].[taxrateAudit] (
    [TaxRateAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [TaxRateId]       BIGINT          NOT NULL,
    [TaxRate]         NUMERIC (18, 2) NOT NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   NOT NULL,
    [IsActive]        BIT             NOT NULL,
    [IsDeleted]       BIT             NOT NULL
);

