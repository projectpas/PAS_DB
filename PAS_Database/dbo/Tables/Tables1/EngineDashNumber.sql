CREATE TABLE [dbo].[EngineDashNumber] (
	[EngineDashNumberId] BIGINT         IDENTITY (1, 1) NOT NULL,
	[EngineTypeId]       BIGINT         NOT NULL,           -- Engine Type = Manufacturer
	[EngineModelId]      BIGINT         NOT NULL,
	[DashNumber]         VARCHAR (250)  NOT NULL,
	[Memo]               NVARCHAR (MAX) NULL,
	[MasterCompanyId]    INT            NOT NULL,
	[CreatedBy]          VARCHAR (256)  NOT NULL,
	[UpdatedBy]          VARCHAR (256)  NOT NULL,
	[CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_EngineDashNumber_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
	[UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_EngineDashNumber_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
	[IsActive]           BIT            CONSTRAINT [DF_EngineDashNumber_IsActive] DEFAULT ((1)) NOT NULL,
	[IsDeleted]          BIT            CONSTRAINT [DF_EngineDashNumber_IsDeleted] DEFAULT ((0)) NOT NULL,
	CONSTRAINT [PK_EngineDashNumber] PRIMARY KEY CLUSTERED ([EngineDashNumberId] ASC),
	CONSTRAINT [FK_EngineDashNumber_Manufacturer] FOREIGN KEY ([EngineTypeId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
	CONSTRAINT [FK_EngineDashNumber_EngineModel] FOREIGN KEY ([EngineModelId]) REFERENCES [dbo].[EngineModel] ([EngineModelId]),
	CONSTRAINT [FK_EngineDashNumber_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
	CONSTRAINT [Unique_EngineDashNumber] UNIQUE NONCLUSTERED ([EngineTypeId] ASC, [EngineModelId] ASC, [DashNumber] ASC, [MasterCompanyId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_EngineDashNumberAudit]
   ON [dbo].[EngineDashNumber]
   AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [dbo].[EngineDashNumberAudit]
		([EngineDashNumberId], [EngineTypeId], [EngineModelId], [DashNumber], [Memo], [MasterCompanyId], [CreatedBy], [UpdatedBy],
		 [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [EngineType], [EngineModel])
	SELECT I.[EngineDashNumberId], I.[EngineTypeId], I.[EngineModelId], I.[DashNumber], I.[Memo], I.[MasterCompanyId], I.[CreatedBy], I.[UpdatedBy],
		   I.[CreatedDate], I.[UpdatedDate], I.[IsActive], I.[IsDeleted], M.[Name], EM.[ModelName]
	FROM INSERTED I
		LEFT JOIN [dbo].[Manufacturer] M  WITH (NOLOCK) ON M.[ManufacturerId] = I.[EngineTypeId]
		LEFT JOIN [dbo].[EngineModel]  EM WITH (NOLOCK) ON EM.[EngineModelId] = I.[EngineModelId];
END
