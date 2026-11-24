CREATE TABLE [dbo].[EngineModel] (
	[EngineModelId]   BIGINT         IDENTITY (1, 1) NOT NULL,
	[EngineTypeId]    BIGINT         NOT NULL,              -- Engine Type = Manufacturer
	[ModelName]       VARCHAR (50)   NOT NULL,
	[Memo]            NVARCHAR (MAX) NULL,
	[MasterCompanyId] INT            NOT NULL,
	[CreatedBy]       VARCHAR (256)  NOT NULL,
	[UpdatedBy]       VARCHAR (256)  NOT NULL,
	[CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_EngineModel_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
	[UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_EngineModel_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
	[IsActive]        BIT            CONSTRAINT [DF_EngineModel_IsActive] DEFAULT ((1)) NOT NULL,
	[IsDeleted]       BIT            CONSTRAINT [DF_EngineModel_IsDeleted] DEFAULT ((0)) NOT NULL,
	CONSTRAINT [PK_EngineModel] PRIMARY KEY CLUSTERED ([EngineModelId] ASC),
	CONSTRAINT [FK_EngineModel_Manufacturer] FOREIGN KEY ([EngineTypeId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
	CONSTRAINT [FK_EngineModel_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
	CONSTRAINT [Unique_EngineTypeModel] UNIQUE NONCLUSTERED ([EngineTypeId] ASC, [ModelName] ASC, [MasterCompanyId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_EngineModelAudit]
   ON [dbo].[EngineModel]
   AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO [dbo].[EngineModelAudit]
		([EngineModelId], [EngineTypeId], [ModelName], [Memo], [MasterCompanyId], [CreatedBy], [UpdatedBy],
		 [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [EngineType])
	SELECT I.[EngineModelId], I.[EngineTypeId], I.[ModelName], I.[Memo], I.[MasterCompanyId], I.[CreatedBy], I.[UpdatedBy],
		   I.[CreatedDate], I.[UpdatedDate], I.[IsActive], I.[IsDeleted], M.[Name]
	FROM INSERTED I
		LEFT JOIN [dbo].[Manufacturer] M WITH (NOLOCK) ON M.[ManufacturerId] = I.[EngineTypeId];
END
