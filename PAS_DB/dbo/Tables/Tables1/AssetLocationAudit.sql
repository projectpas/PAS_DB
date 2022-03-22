CREATE TABLE [dbo].[AssetLocationAudit] (
    [AssetLocationAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetLocationId]      BIGINT         NOT NULL,
    [Code]                 VARCHAR (100)  NOT NULL,
    [Name]                 VARCHAR (100)  NOT NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([AssetLocationAuditId] ASC),
    CONSTRAINT [FK_AssetLocationAudit_AssetLocation] FOREIGN KEY ([AssetLocationId]) REFERENCES [dbo].[AssetLocation] ([AssetLocationId])
);

