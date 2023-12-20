CREATE TABLE [dbo].[AssetDepreciationMethodAudit] (
    [AssetDepreciationMethodAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDepreciationMethodId]      BIGINT         NOT NULL,
    [AssetDepreciationMethodCode]    VARCHAR (30)   NOT NULL,
    [AssetDepreciationMethodName]    VARCHAR (30)   NOT NULL,
    [AssetDepreciationMethodBasis]   VARCHAR (20)   NOT NULL,
    [AssetDepreciationMethodMemo]    NVARCHAR (MAX) NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  NOT NULL,
    [IsActive]                       BIT            NOT NULL,
    [IsDeleted]                      BIT            NOT NULL,
    [SequenceNo]                     INT            NOT NULL,
    CONSTRAINT [PK__AssetDep__A7A30B2107A197AA] PRIMARY KEY CLUSTERED ([AssetDepreciationMethodAuditId] ASC),
    CONSTRAINT [FK_AssetDepreciationMethodAudit_AssetDepreciationMethod] FOREIGN KEY ([AssetDepreciationMethodId]) REFERENCES [dbo].[AssetDepreciationMethod] ([AssetDepreciationMethodId])
);

