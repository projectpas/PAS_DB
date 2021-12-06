CREATE TABLE [dbo].[AssetStatusAudit] (
    [AssetStatusAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetStatusId]      BIGINT         NOT NULL,
    [Code]               VARCHAR (100)  NULL,
    [Name]               VARCHAR (100)  NOT NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  NOT NULL,
    [IsActive]           BIT            NOT NULL,
    [IsDeleted]          BIT            NOT NULL,
    CONSTRAINT [PK_AssetStatusAudit] PRIMARY KEY CLUSTERED ([AssetStatusAuditId] ASC),
    CONSTRAINT [FK_AssetStatusAudit_AssetStatus] FOREIGN KEY ([AssetStatusId]) REFERENCES [dbo].[AssetStatus] ([AssetStatusId])
);

