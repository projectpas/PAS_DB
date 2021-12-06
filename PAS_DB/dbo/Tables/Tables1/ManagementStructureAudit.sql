CREATE TABLE [dbo].[ManagementStructureAudit] (
    [ManagementStructureAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId]      BIGINT         NOT NULL,
    [Code]                       VARCHAR (30)   NULL,
    [Name]                       VARCHAR (256)  NULL,
    [Description]                VARCHAR (200)  NULL,
    [ParentId]                   BIGINT         NULL,
    [IsLastChild]                BIT            NULL,
    [TagName]                    VARCHAR (100)  NULL,
    [LegalEntityId]              BIGINT         NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  NOT NULL,
    [IsActive]                   BIT            NOT NULL,
    [IsDeleted]                  BIT            NOT NULL,
    [Ids]                        VARCHAR (2000) NULL,
    [Names]                      VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_ManagementStructureAudit] PRIMARY KEY CLUSTERED ([ManagementStructureAuditId] ASC)
);

