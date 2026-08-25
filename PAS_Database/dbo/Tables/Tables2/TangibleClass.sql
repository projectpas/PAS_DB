CREATE TABLE [dbo].[TangibleClass] (
    [TangibleClassId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [TangibleClassName] VARCHAR (50)   NULL,
    [TangibleClassMemo] VARCHAR (1000) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [TangibleClass_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [TangibleClass_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [TangibleClass_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [TangibleClass_DC_Delete] DEFAULT ((0)) NOT NULL,
    [StatusCode]        VARCHAR (25)   NULL,
    CONSTRAINT [PK_TangibleClass] PRIMARY KEY CLUSTERED ([TangibleClassId] ASC),
    CONSTRAINT [FK_TangibleClass_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_TangibleClass] UNIQUE NONCLUSTERED ([TangibleClassName] ASC, [MasterCompanyId] ASC)
);






GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_TangibleClassAudit]

   ON  [dbo].[TangibleClass]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO TangibleClassAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_TangibleClass_AssetAttributeTypeSync] ON [dbo].[TangibleClass] FOR INSERT, UPDATE, DELETE
AS
SET NOCOUNT ON;

-- INSERT: create a matching AssetAttributeType row for every newly added TangibleClass row.
-- Attribute-specific columns (ConventionType, DepreciationMethod, GL accounts, etc.) are left NULL.
INSERT INTO dbo.AssetAttributeType
(
    TangibleClassId,
    AssetAttributeTypeName,
    Description,
    ConventionType,
    DepreciationMethod,
    ResidualPercentage,
    AssetLife,
    DepreciationFrequencyId,
    AcquiredGLAccountId,
    DeprExpenseGLAccountId,
    AdDepsGLAccountId,
    AssetSale,
    AssetWriteOff,
    AssetWriteDown,
    ManagementStructureId,
    MasterCompanyId,
    CreatedBy,
    UpdatedBy,
    CreatedDate,
    UpdatedDate,
    IsActive,
    IsDeleted,
    SelectedCompanyIds
)
SELECT
    I.[TangibleClassId],
    I.[TangibleClassName],
    I.[TangibleClassName],
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    I.[MasterCompanyId],
    I.[CreatedBy],
    I.[UpdatedBy],
    I.[CreatedDate],
    I.[UpdatedDate],
    I.[IsActive],
    I.[IsDeleted],
    NULL
FROM Inserted I
WHERE I.[TangibleClassName] IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM Deleted D WHERE D.[TangibleClassId] = I.[TangibleClassId])
  AND NOT EXISTS (SELECT 1 FROM dbo.AssetAttributeType aat WHERE aat.[TangibleClassId] = I.[TangibleClassId])
  AND NOT EXISTS (
    SELECT 1 FROM dbo.AssetAttributeType existing
    WHERE existing.[AssetAttributeTypeName] = I.[TangibleClassName] AND existing.[MasterCompanyId] = I.[MasterCompanyId]
  );

-- UPDATE: keep the linked AssetAttributeType row's name/description/status columns
-- in sync with the TangibleClass row they belong to. Skipped if that name is already
-- used by a different AssetAttributeType row in the same company.
UPDATE aat
SET
    aat.[AssetAttributeTypeName] = I.[TangibleClassName],
    aat.[Description] = I.[TangibleClassName],
    aat.[MasterCompanyId] = I.[MasterCompanyId],
    aat.[IsActive] = I.[IsActive],
    aat.[IsDeleted] = I.[IsDeleted],
    aat.[UpdatedBy] = I.[UpdatedBy],
    aat.[UpdatedDate] = I.[UpdatedDate]
FROM dbo.AssetAttributeType aat
INNER JOIN Inserted I ON I.[TangibleClassId] = aat.[TangibleClassId]
INNER JOIN Deleted D ON D.[TangibleClassId] = I.[TangibleClassId]
WHERE I.[TangibleClassName] IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM dbo.AssetAttributeType other
    WHERE other.[AssetAttributeTypeName] = I.[TangibleClassName]
      AND other.[MasterCompanyId] = I.[MasterCompanyId]
      AND other.[AssetAttributeTypeId] <> aat.[AssetAttributeTypeId]
  );

-- DELETE: soft-delete the linked AssetAttributeType row(s) for every removed TangibleClass row
-- (a hard delete on AssetAttributeType is avoided since Asset/LegalEntityAssetAttributeType reference it).
UPDATE aat
SET
    aat.[IsDeleted] = 1,
    aat.[IsActive] = 0,
    aat.[UpdatedBy] = D.[UpdatedBy],
    aat.[UpdatedDate] = GETUTCDATE()
FROM dbo.AssetAttributeType aat
INNER JOIN Deleted D ON D.[TangibleClassId] = aat.[TangibleClassId]
WHERE NOT EXISTS (SELECT 1 FROM Inserted I WHERE I.[TangibleClassId] = D.[TangibleClassId]);