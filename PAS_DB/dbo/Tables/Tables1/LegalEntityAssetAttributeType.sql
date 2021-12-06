CREATE TABLE [dbo].[LegalEntityAssetAttributeType] (
    [LegalEntityAssetAttributeTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [AssetAttributeTypeId]            BIGINT        NOT NULL,
    [LegalEntityId]                   BIGINT        NOT NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) CONSTRAINT [LegalEntityAssetAttributeType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) CONSTRAINT [LegalEntityAssetAttributeType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                        BIT           CONSTRAINT [DF_LegalEntityAssetAttributeType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT           CONSTRAINT [DF_LegalEntityAssetAttributeType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LegalEntityAssetAttributeTypeId] PRIMARY KEY CLUSTERED ([LegalEntityAssetAttributeTypeId] ASC),
    CONSTRAINT [FK_LegalEntityAssetAttributeType_AssetAttributeType] FOREIGN KEY ([AssetAttributeTypeId]) REFERENCES [dbo].[AssetAttributeType] ([AssetAttributeTypeId]),
    CONSTRAINT [FK_LegalEntityAssetAttributeType_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId])
);


GO




CREATE TRIGGER [dbo].[Trg_LegalEntityAssetAttributeTypeAudit]

   ON  [dbo].[LegalEntityAssetAttributeType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO LegalEntityAssetAttributeTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END