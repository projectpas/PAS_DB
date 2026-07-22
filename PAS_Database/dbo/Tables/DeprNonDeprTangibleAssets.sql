CREATE TABLE [dbo].[DeprNonDeprTangibleAssets] (
    [DeprNonDeprTangibleAssetsId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TangibleClassId]             BIGINT         NOT NULL,
    [AssetAttributeTypeName]      VARCHAR (30)   NOT NULL,
    [Description]                 VARCHAR (500)  NOT NULL,
    [AssetDeprMethodId]           BIGINT         NOT NULL,
    [CalibratedGLAccountId]       BIGINT         NULL,
    [AcquiredGLAccountId]         BIGINT         NULL,
    [DeprExpenseGLAccountId]      BIGINT         NULL,
    [AccumDeprGLAccountId]        BIGINT         NULL,
    [AssetSaleGLAccountId]        BIGINT         NULL,
    [AssetWriteOffGLAccountId]    BIGINT         NULL,
    [AssetWriteDownGLAccountId]   BIGINT         NULL,
    [ManagementStructureId]       BIGINT         NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_DeprNonDeprTangibleAssets_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_DeprNonDeprTangibleAssets_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [DF_DeprNonDeprTangibleAssets_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [DF_DeprNonDeprTangibleAssets_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SelectedCompanyIds]          VARCHAR (1000) NOT NULL,
    [ResidualPercentage]          BIGINT         NULL,
    [AssetLife]                   INT            NULL,
    [DepreciationFrequencyId]     BIGINT         NULL,
    CONSTRAINT [PK_DeprNonDeprTangibleAssets] PRIMARY KEY CLUSTERED ([DeprNonDeprTangibleAssetsId] ASC),
    CONSTRAINT [FK_DeprNonDeprTangibleAssets_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_DeprNonDeprTangibleAssets_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_DeprNonDeprTangibleAssets_TangibleClass] FOREIGN KEY ([TangibleClassId]) REFERENCES [dbo].[TangibleClass] ([TangibleClassId]),
    CONSTRAINT [FK_DeprNonDeprTangibleAssetsDeps_AssetDepreciationMethod] FOREIGN KEY ([AssetDeprMethodId]) REFERENCES [dbo].[AssetDepreciationMethod] ([AssetDepreciationMethodId]),
    CONSTRAINT [Unique_DeprNonDeprTangibleAssets] UNIQUE NONCLUSTERED ([AssetAttributeTypeName] ASC, [MasterCompanyId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_DeprNonDeprTangibleAssetsAudit] ON [dbo].[DeprNonDeprTangibleAssets]
   AFTER INSERT,UPDATE,DELETE
AS
BEGIN
DECLARE @TangibleClass VARCHAR(100),@AssetDepreciationMethodName VARCHAR(100),
	@AssetDepreciationIntervalName VARCHAR(100),@PercentValue VARCHAR(100),@CalibratedGLAccount VARCHAR(100),
	@AcquiredGLAccount VARCHAR(100),@DeprExpenseGLAccount VARCHAR(100),
	@AccumDeprGLAccount VARCHAR(100),@AssetSaleGLAccount VARCHAR(100),@AssetWriteOffGLAccount VARCHAR(100),@AssetWriteDownGLAccount VARCHAR(100),
	@LegalEntity VARCHAR(MAX)
DECLARE @TangibleClassId BIGINT,@AssetDeprMethodId BIGINT,
	@DepreciationFrequencyId BIGINT,@ResidualPercentage BIGINT,@CalibratedGLAccountId BIGINT,@AcquiredGLAccountId BIGINT,@DeprExpenseGLAccountId BIGINT,
	@AccumDeprGLAccountId BIGINT,@AssetSaleGLAccountId BIGINT,@AssetWriteOffGLAccountId BIGINT,@AssetWriteDownGLAccountId BIGINT,
	@LegalEntityIds VARCHAR(1000),@DeprNonDeprTangibleAssetsId BIGINT
	SELECT @TangibleClassId=TangibleClassId,@AssetDeprMethodId=AssetDeprMethodId,
	@DepreciationFrequencyId=DepreciationFrequencyId,@ResidualPercentage=ResidualPercentage,@CalibratedGLAccountId=CalibratedGLAccountId,
	@AcquiredGLAccountId=AcquiredGLAccountId,@DeprExpenseGLAccountId=DeprExpenseGLAccountId,@AccumDeprGLAccountId=AccumDeprGLAccountId,
	@AssetSaleGLAccountId=AssetSaleGLAccountId,@AssetWriteOffGLAccountId=AssetWriteOffGLAccountId,@AssetWriteDownGLAccountId=AssetWriteDownGLAccountId,
	@LegalEntityIds=SelectedCompanyIds,@DeprNonDeprTangibleAssetsId=DeprNonDeprTangibleAssetsId FROM INSERTED
	SELECT @TangibleClass=TangibleClassName FROM TangibleClass WHERE TangibleClassId=@TangibleClassId
	SELECT @AssetDepreciationMethodName=AssetDepreciationMethodName FROM AssetDepreciationMethod WHERE AssetDepreciationMethodId=@AssetDeprMethodId
	SELECT @AssetDepreciationIntervalName=AssetDepreciationIntervalName FROM AssetDepreciationInterval WHERE AssetDepreciationIntervalId=@DepreciationFrequencyId
	SELECT @PercentValue=PercentValue FROM [Percent] WHERE PercentId=@ResidualPercentage
	SELECT @CalibratedGLAccount=AccountName FROM GLAccount WHERE GLAccountId=@CalibratedGLAccountId
	SELECT @AcquiredGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AcquiredGLAccountId
	SELECT @DeprExpenseGLAccount=AccountName FROM GLAccount WHERE GLAccountId=@DeprExpenseGLAccountId
	SELECT @AccumDeprGLAccount=AccountName FROM GLAccount WHERE GLAccountId=@AccumDeprGLAccountId
	SELECT @AssetSaleGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AssetSaleGLAccountId
	SELECT @AssetWriteOffGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AssetWriteOffGLAccountId
	SELECT @AssetWriteDownGLAccount= AccountName FROM GLAccount WHERE GLAccountId=@AssetWriteDownGLAccountId
	SELECT @DeprNonDeprTangibleAssetsId=DeprNonDeprTangibleAssetsId, @LegalEntity = 
		   STUFF((SELECT ', ' + Name
           FROM LegalEntityAssetAttributeType LEA 
		   JOIN LegalEntity LE ON LEA.LegalEntityId=LE.LegalEntityId
           WHERE LEA.AssetAttributeTypeId = DAT.DeprNonDeprTangibleAssetsId 
           FOR XML PATH('')), 1, 2, '')
	FROM DeprNonDeprTangibleAssets DAT
	WHERE DAT.DeprNonDeprTangibleAssetsId=@DeprNonDeprTangibleAssetsId
	GROUP BY DeprNonDeprTangibleAssetsId
 INSERT INTO [dbo].[DeprNonDeprTangibleAssetsAudit]  
 SELECT *,@TangibleClass,@AssetDepreciationMethodName,@AssetDepreciationIntervalName,@PercentValue,@CalibratedGLAccount,
 @AcquiredGLAccount,@DeprExpenseGLAccount,@AccumDeprGLAccount,@AssetSaleGLAccount,@AssetWriteOffGLAccount,@AssetWriteDownGLAccount,
 @LegalEntity
 FROM INSERTED  
 SET NOCOUNT ON;
END