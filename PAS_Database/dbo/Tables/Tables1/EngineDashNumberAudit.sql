CREATE TABLE [dbo].[EngineDashNumberAudit] (
	[EngineDashNumberAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
	[EngineDashNumberId]      BIGINT         NOT NULL,
	[EngineTypeId]            BIGINT         NOT NULL,
	[EngineModelId]           BIGINT         NOT NULL,
	[DashNumber]              VARCHAR (250)  NOT NULL,
	[Memo]                    NVARCHAR (MAX) NULL,
	[MasterCompanyId]         INT            NOT NULL,
	[CreatedBy]               VARCHAR (256)  NOT NULL,
	[UpdatedBy]               VARCHAR (256)  NOT NULL,
	[CreatedDate]             DATETIME2 (7)  NOT NULL,
	[UpdatedDate]             DATETIME2 (7)  NOT NULL,
	[IsActive]                BIT            NOT NULL,
	[IsDeleted]               BIT            NOT NULL,
	[EngineType]              VARCHAR (256)  NULL,
	[EngineModel]             VARCHAR (256)  NULL,
	CONSTRAINT [PK_EngineDashNumberAudit] PRIMARY KEY CLUSTERED ([EngineDashNumberAuditId] ASC)
);
