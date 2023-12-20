﻿CREATE TABLE [dbo].[ExchangeStatusAudit] (
    [ExchangeStatusAuditId] INT          IDENTITY (1, 1) NOT NULL,
    [ExchangeStatusId]      INT          NOT NULL,
    [Name]                  VARCHAR (50) NOT NULL,
    [MasterCompanyId]       INT          NOT NULL,
    [CreatedBy]             VARCHAR (50) NOT NULL,
    [CreatedOn]             DATETIME     NOT NULL,
    [UpdatedBy]             VARCHAR (50) NULL,
    [UpdatedOn]             DATETIME     NULL,
    [IsActive]              BIT          NOT NULL,
    [IsDeleted]             BIT          NOT NULL,
    CONSTRAINT [PK_ExchangeStatusAudit] PRIMARY KEY CLUSTERED ([ExchangeStatusAuditId] ASC)
);

