CREATE TABLE [dbo].[AssetDepreciationFrequencyAudit] (
    [AssetDepreciationFrequencyAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDepreciationFrequencyId]      BIGINT         NOT NULL,
    [Name]                              VARCHAR (50)   NOT NULL,
    [Description]                       VARCHAR (50)   NOT NULL,
    [Memo]                              NVARCHAR (MAX) NULL,
    [MasterCompanyId]                   INT            NOT NULL,
    [CreatedBy]                         VARCHAR (256)  NOT NULL,
    [UpdatedBy]                         VARCHAR (256)  NOT NULL,
    [CreatedDate]                       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)  NOT NULL,
    [IsActive]                          BIT            NOT NULL,
    [IsDeleted]                         BIT            NOT NULL,
    CONSTRAINT [PK_AssetDepreciationFrequencyAudit] PRIMARY KEY CLUSTERED ([AssetDepreciationFrequencyAuditId] ASC),
    CONSTRAINT [FK_AssetDepreciationFrequencyAudit_AssetDepreciationFrequency] FOREIGN KEY ([AssetDepreciationFrequencyId]) REFERENCES [dbo].[AssetDepreciationFrequency] ([AssetDepreciationFrequencyId])
);

