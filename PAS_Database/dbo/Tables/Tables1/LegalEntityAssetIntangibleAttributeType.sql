CREATE TABLE [dbo].[LegalEntityAssetIntangibleAttributeType] (
    [LegalEntityAssetIntangibleAttributeTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [AssetIntangibleAttributeTypeId]            BIGINT        NOT NULL,
    [LegalEntityId]                             BIGINT        NOT NULL,
    [MasterCompanyId]                           INT           NOT NULL,
    [CreatedBy]                                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                                 VARCHAR (256) NOT NULL,
    [CreatedDate]                               DATETIME2 (7) CONSTRAINT [LegalEntityAssetIntangibleAttributeType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                               DATETIME2 (7) CONSTRAINT [LegalEntityAssetIntangibleAttributeType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                                  BIT           CONSTRAINT [DF_LegalEntityAssetIntangibleAttributeType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                                 BIT           CONSTRAINT [DF_LegalEntityAssetIntangibleAttributeType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LegalEntityAssetIntangibleAttributeTypeId] PRIMARY KEY CLUSTERED ([LegalEntityAssetIntangibleAttributeTypeId] ASC),
    CONSTRAINT [FK_LegalEntityAssetIntangibleAttributeType_AssetIntangibleAttributeType] FOREIGN KEY ([AssetIntangibleAttributeTypeId]) REFERENCES [dbo].[AssetIntangibleAttributeType] ([AssetIntangibleAttributeTypeId]),
    CONSTRAINT [FK_LegalEntityAssetIntangibleAttributeType_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId])
);


GO




CREATE TRIGGER [dbo].[Trg_LegalEntityAssetIntangibleAttributeTypeAudit]

   ON  [dbo].[LegalEntityAssetIntangibleAttributeType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO LegalEntityAssetIntangibleAttributeTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END