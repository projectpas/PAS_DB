CREATE TABLE [dbo].[AssetDepreciationIntervalAudit] (
    [AssetDepreciationIntervalAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDepreciationIntervalId]      BIGINT         NOT NULL,
    [AssetDepreciationIntervalCode]    VARCHAR (30)   NOT NULL,
    [AssetDepreciationIntervalName]    VARCHAR (50)   NOT NULL,
    [AssetDepreciationIntervalMemo]    NVARCHAR (MAX) NULL,
    [MasterCompanyId]                  INT            NOT NULL,
    [CreatedBy]                        VARCHAR (256)  NOT NULL,
    [UpdatedBy]                        VARCHAR (256)  NOT NULL,
    [CreatedDate]                      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                      DATETIME2 (7)  NOT NULL,
    [IsActive]                         BIT            NOT NULL,
    [IsDeleted]                        BIT            NOT NULL,
    CONSTRAINT [PK_AssetDepreciationIntervalAudit] PRIMARY KEY CLUSTERED ([AssetDepreciationIntervalAuditId] ASC),
    CONSTRAINT [FK_AssetDepreciationIntervalAudit_AssetDepreciationInterval] FOREIGN KEY ([AssetDepreciationIntervalId]) REFERENCES [dbo].[AssetDepreciationInterval] ([AssetDepreciationIntervalId])
);

