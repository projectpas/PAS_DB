CREATE TABLE [dbo].[ConventionTypeAudit] (
    [ConventionTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]                  NVARCHAR (50)  NOT NULL,
    [Description]           NVARCHAR (100) NOT NULL,
    [Memo]                  NVARCHAR (50)  NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [ConventionTypeId]      BIGINT         NOT NULL,
    CONSTRAINT [PK_ConventionTypeAudit] PRIMARY KEY CLUSTERED ([ConventionTypeAuditId] ASC)
);

