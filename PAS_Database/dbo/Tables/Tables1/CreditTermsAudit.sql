﻿CREATE TABLE [dbo].[CreditTermsAudit] (
    [CreditTermsAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CreditTermsId]      INT             NOT NULL,
    [Name]               VARCHAR (30)    NOT NULL,
    [PercentId]          DECIMAL (18, 2) NOT NULL,
    [Days]               TINYINT         NOT NULL,
    [NetDays]            TINYINT         NOT NULL,
    [Memo]               NVARCHAR (MAX)  NULL,
    [MasterCompanyId]    INT             NOT NULL,
    [CreatedBy]          VARCHAR (256)   NOT NULL,
    [UpdatedBy]          VARCHAR (256)   NOT NULL,
    [CreatedDate]        DATETIME2 (7)   NOT NULL,
    [UpdatedDate]        DATETIME2 (7)   NOT NULL,
    [IsActive]           BIT             NOT NULL,
    [IsDeleted]          BIT             NOT NULL,
    [Code]               VARCHAR (50)    NULL,
    CONSTRAINT [PK_CreditTermsAudit] PRIMARY KEY CLUSTERED ([CreditTermsAuditId] ASC)
);



