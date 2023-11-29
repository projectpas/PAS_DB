CREATE TABLE [dbo].[GLAccountAudit] (
    [GLAccountAuditId]            BIGINT          IDENTITY (1, 1) NOT NULL,
    [GLAccountId]                 BIGINT          NOT NULL,
    [OldAccountCode]              VARCHAR (30)    NULL,
    [AccountCode]                 VARCHAR (30)    NULL,
    [AccountName]                 VARCHAR (100)   NULL,
    [AccountDescription]          VARCHAR (500)   NULL,
    [AllowManualJE]               BIT             NULL,
    [GLAccountTypeId]             BIGINT          NULL,
    [GLClassFlowClassificationId] BIGINT          NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NULL,
    [UpdatedBy]                   VARCHAR (256)   NULL,
    [CreatedDate]                 DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   NOT NULL,
    [IsActive]                    BIT             NULL,
    [isDeleted]                   BIT             NULL,
    [POROCategoryId]              BIGINT          NULL,
    [GLAccountNodeId]             BIGINT          NULL,
    [LedgerId]                    BIGINT          NULL,
    [LedgerName]                  VARCHAR (30)    NULL,
    [InterCompany]                BIT             NULL,
    [Category1099Id]              BIGINT          NULL,
    [Threshold]                   DECIMAL (18, 2) NULL,
    [IsManualJEReference]         BIT             NULL,
    [ReferenceTypeId]             INT             NULL
);







