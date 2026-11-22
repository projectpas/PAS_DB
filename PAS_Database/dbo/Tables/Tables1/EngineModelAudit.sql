CREATE TABLE [dbo].[EngineModelAudit] (
	[EngineModelAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
	[EngineModelId]      BIGINT         NOT NULL,
	[EngineTypeId]       BIGINT         NOT NULL,
	[ModelName]          VARCHAR (50)   NOT NULL,
	[Memo]               NVARCHAR (MAX) NULL,
	[MasterCompanyId]    INT            NOT NULL,
	[CreatedBy]          VARCHAR (256)  NOT NULL,
	[UpdatedBy]          VARCHAR (256)  NOT NULL,
	[CreatedDate]        DATETIME2 (7)  NOT NULL,
	[UpdatedDate]        DATETIME2 (7)  NOT NULL,
	[IsActive]           BIT            NOT NULL,
	[IsDeleted]          BIT            NOT NULL,
	[EngineType]         VARCHAR (256)  NULL,
	CONSTRAINT [PK_EngineModelAudit] PRIMARY KEY CLUSTERED ([EngineModelAuditId] ASC)
);
