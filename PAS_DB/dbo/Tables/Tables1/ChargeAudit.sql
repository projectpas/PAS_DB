﻿CREATE TABLE [dbo].[ChargeAudit] (
    [ChargeId]        BIGINT          NOT NULL,
    [Description]     VARCHAR (200)   NOT NULL,
    [GLAccountId]     BIGINT          NULL,
    [MasterCompanyId] INT             NOT NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   NOT NULL,
    [IsActive]        BIT             NOT NULL,
    [IsDeleted]       BIT             NOT NULL,
    [ChargeType]      VARCHAR (256)   NOT NULL,
    [ChargeAuditId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [Cost]            DECIMAL (10, 2) NULL,
    [Price]           DECIMAL (10, 2) NULL,
    [SequenceNo]      INT             NULL,
    [CurrencyId]      INT             NULL,
    [UnitOfMeasureId] BIGINT          NULL,
    [AccountName]     VARCHAR (256)   NULL,
    [Code]            VARCHAR (100)   NULL,
    [ShortName]       VARCHAR (100)   NULL,
    CONSTRAINT [PK__ChargeAu__183FCF72C725DC30] PRIMARY KEY CLUSTERED ([ChargeAuditId] ASC)
);



