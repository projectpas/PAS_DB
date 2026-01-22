CREATE TABLE [dbo].[DepreciationConventionAudit] (
    [AuditDepreciationConventionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [DepreciationConventionId]      BIGINT         NOT NULL,
    [ConventionCode]                VARCHAR (30)   NOT NULL,
    [Description]                   VARCHAR (256)  NOT NULL,
    [Memo]                          NVARCHAR (MAX) NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  NOT NULL,
    [IsActive]                      BIT            NOT NULL,
    [IsDeleted]                     BIT            NOT NULL,
    CONSTRAINT [PK_DepreciationConventionAudit] PRIMARY KEY CLUSTERED ([AuditDepreciationConventionId] ASC)
);

