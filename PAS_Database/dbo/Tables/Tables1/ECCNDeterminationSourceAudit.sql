﻿CREATE TABLE [dbo].[ECCNDeterminationSourceAudit] (
    [EccnDeterminationSourceAuditID] INT           IDENTITY (1, 1) NOT NULL,
    [EccnDeterminationSourceID]      INT           NOT NULL,
    [Name]                           VARCHAR (100) NULL,
    [Description]                    VARCHAR (100) NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (50)  NOT NULL,
    [CreatedDate]                    DATETIME      NOT NULL,
    [UpdatedBy]                      VARCHAR (50)  NOT NULL,
    [UpdatedDate]                    DATETIME      NOT NULL,
    [IsActive]                       BIT           NOT NULL,
    [IsDeleted]                      BIT           NOT NULL,
    CONSTRAINT [PK_ECCNDeterminationSourceAudit] PRIMARY KEY CLUSTERED ([EccnDeterminationSourceAuditID] ASC)
);

