CREATE TABLE [dbo].[AssetIntangibleTypeAudit] (
    [AssetIntangibleTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetIntangibleTypeId]      BIGINT         NOT NULL,
    [AssetIntangibleName]        VARCHAR (30)   NOT NULL,
    [AssetIntangibleMemo]        NVARCHAR (MAX) NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  NOT NULL,
    [IsActive]                   BIT            NOT NULL,
    [IsDeleted]                  BIT            NOT NULL,
    [AssetIntangibleCode]        VARCHAR (50)   NOT NULL,
    [Description]                VARCHAR (MAX)  NULL,
    CONSTRAINT [FK_AssetIntangibleTypeAudit_AssetIntangibleType] FOREIGN KEY ([AssetIntangibleTypeId]) REFERENCES [dbo].[AssetIntangibleType] ([AssetIntangibleTypeId])
);

