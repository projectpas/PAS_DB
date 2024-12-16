CREATE TABLE [dbo].[AssetAvailableStatusAudit] (
    [AssetAvailableStatusAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetAvailableStatusId]      BIGINT         NOT NULL,
    [Status]                      VARCHAR (256)  NOT NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [MasterCompanyId]             INT            CONSTRAINT [DF_AssetAvailableStatusAudit_MasterCompanyId] DEFAULT ((0)) NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_AssetAvailableStatusAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_AssetAvailableStatusAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [DF_AssetAvailableStatusAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [DF_AssetAvailableStatusAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetAvailableStatusAudit] PRIMARY KEY CLUSTERED ([AssetAvailableStatusAuditId] ASC)
);

