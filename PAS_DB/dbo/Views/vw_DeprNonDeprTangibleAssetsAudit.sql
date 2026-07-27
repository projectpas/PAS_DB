
CREATE VIEW [dbo].[vw_DeprNonDeprTangibleAssetsAudit]
AS
SELECT
	[DAT].[AuditDeprNonDeprTangibleAssetsId] AS PkID,
	[DAT].[DeprNonDeprTangibleAssetsId] AS ID,
	LegalEntity = STUFF((SELECT ', ' + [Name] FROM dbo.LegalEntity LE WITH(NOLOCK) WHERE LE.LegalEntityId IN (SELECT Item FROM DBO.SPLITSTRING(DAT.SelectedCompanyIds,',')) FOR XML PATH('')), 1, 2, ''),
	[ATY].[TangibleClassName] AS [Tangible Class],
	[DAT].[AssetAttributeTypeName] AS [Name],
	[DAT].[Description] AS [Description],
	[DM].[AssetDepreciationMethodName] AS [Depreciation Method],
	[PER].[PercentValue] AS [Residual Percentage],
	[DAT].[AssetLife] AS [Asset Life],
	[FI].[Name] AS [Depreciation Frequency],
	[CLGL].[AccountName] AS [Calibrated GL Account],
	[AQGL].[AccountName] AS [Acquired GL Account],
	[DPGL].[AccountName] AS [Depr Expense GL Account],
	[ADGL].[AccountName] AS [Accum Depr GL Account],
	[ASGL].[AccountName] AS [Asset Sale GL Account],
	[WOGL].[AccountName] AS [Asset Write Off GL Account],
	[WDGL].[AccountName] AS [Asset Write Down GL Account],
	[DAT].[UpdatedBy] AS [Updated By],
	[DAT].[UpdatedDate] AS [Updated Date],
	[DAT].[IsActive] AS [Active],
	[DAT].[IsDeleted] AS [Deleted]
FROM dbo.DeprNonDeprTangibleAssetsAudit DAT WITH(NOLOCK)
	LEFT JOIN dbo.TangibleClass ATY WITH(NOLOCK) ON DAT.TangibleClassId=ATY.TangibleClassId
	LEFT JOIN dbo.AssetDepreciationMethod DM WITH(NOLOCK) ON DAT.AssetDeprMethodId=DM.AssetDepreciationMethodId
	LEFT JOIN dbo.AssetDepreciationFrequency FI WITH(NOLOCK) ON DAT.DepreciationFrequencyId=FI.AssetDepreciationFrequencyId
	LEFT JOIN dbo.GLAccount CLGL WITH(NOLOCK) ON DAT.CalibratedGLAccountId=CLGL.GLAccountId
	LEFT JOIN dbo.GLAccount AQGL WITH(NOLOCK) ON DAT.AcquiredGLAccountId=AQGL.GLAccountId
	LEFT JOIN dbo.GLAccount DPGL WITH(NOLOCK) ON DAT.DeprExpenseGLAccountId=DPGL.GLAccountId
	LEFT JOIN dbo.GLAccount ADGL WITH(NOLOCK) ON DAT.AccumDeprGLAccountId=ADGL.GLAccountId
	LEFT JOIN dbo.GLAccount ASGL WITH(NOLOCK) ON DAT.AssetSaleGLAccountId=ASGL.GLAccountId
	LEFT JOIN dbo.GLAccount WOGL WITH(NOLOCK) ON DAT.AssetWriteOffGLAccountId=WOGL.GLAccountId
	LEFT JOIN dbo.GLAccount WDGL WITH(NOLOCK) ON DAT.AssetWriteDownGLAccountId=WDGL.GLAccountId
	LEFT JOIN dbo.[Percent] PER WITH(NOLOCK) ON DAT.ResidualPercentage=PER.PercentId