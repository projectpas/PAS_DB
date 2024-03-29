﻿CREATE TABLE [dbo].[AssetIntangibleAttributeTypeAudit] (
    [AssetIntangibleAttributeTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetIntangibleAttributeTypeId]      BIGINT         NOT NULL,
    [AssetIntangibleTypeId]               BIGINT         NOT NULL,
    [AssetDepreciationMethodId]           BIGINT         NOT NULL,
    [IntangibleLifeYears]                 INT            NOT NULL,
    [AssetAmortizationIntervalId]         BIGINT         NOT NULL,
    [IntangibleGLAccountId]               BIGINT         NOT NULL,
    [AmortExpenseGLAccountId]             BIGINT         NOT NULL,
    [AccAmortDeprGLAccountId]             BIGINT         NOT NULL,
    [IntangibleWriteDownGLAccountId]      BIGINT         NOT NULL,
    [IntangibleWriteOffGLAccountId]       BIGINT         NOT NULL,
    [MasterCompanyId]                     INT            NOT NULL,
    [CreatedBy]                           VARCHAR (256)  NOT NULL,
    [UpdatedBy]                           VARCHAR (256)  NOT NULL,
    [CreatedDate]                         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)  NOT NULL,
    [IsActive]                            BIT            NOT NULL,
    [IsDeleted]                           BIT            NOT NULL,
    [SelectedCompanyIds]                  VARCHAR (1000) NOT NULL,
    [AssetIntangibleType]                 VARCHAR (100)  NULL,
    [AssetDepreciationMethod]             VARCHAR (100)  NULL,
    [AssetAmortizationInterval]           VARCHAR (100)  NULL,
    [IntangibleGLAccount]                 VARCHAR (100)  NULL,
    [AmortExpenseGLAccount]               VARCHAR (100)  NULL,
    [AccAmortDeprGLAccount]               VARCHAR (100)  NULL,
    [IntangibleWriteDownGLAccount]        VARCHAR (100)  NULL,
    [IntangibleWriteOffGLAccount]         VARCHAR (100)  NULL,
    [LegalEntity]                         VARCHAR (MAX)  NULL
);

