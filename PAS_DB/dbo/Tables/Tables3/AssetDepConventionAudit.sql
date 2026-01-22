CREATE TABLE [dbo].[AssetDepConventionAudit] (
    [AssetDepConventionAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDepConventionId]      BIGINT         NOT NULL,
    [AssetDepConventionCode]    VARCHAR (30)   NOT NULL,
    [AssetDepConventionName]    VARCHAR (50)   NOT NULL,
    [AssetDepConventionMemo]    NVARCHAR (MAX) NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  NOT NULL,
    [IsActive]                  BIT            NOT NULL,
    [IsDeleted]                 BIT            NOT NULL,
    CONSTRAINT [PK_AssetDepConventionAudit] PRIMARY KEY CLUSTERED ([AssetDepConventionAuditId] ASC),
    CONSTRAINT [FK_AssetDepConventionAudit_AssetDepConvention] FOREIGN KEY ([AssetDepConventionId]) REFERENCES [dbo].[AssetDepConvention] ([AssetDepConventionId])
);

