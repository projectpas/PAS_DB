
CREATE VIEW [dbo].[vw_AssetAttributeTypeAudit]
AS
SELECT
	[AAT].[AssetAttributeTypeId] AS PkID,
	[AAT].[AssetAttributeTypeId] AS ID,
	LegalEntity = STUFF((SELECT ', ' + [Name] FROM dbo.LegalEntity LE WITH(NOLOCK) WHERE LE.LegalEntityId IN (SELECT Item FROM DBO.SPLITSTRING(AAT.SelectedCompanyIds,',')) FOR XML PATH('')), 1, 2, ''),
	[ATY].[TangibleClassName] AS [Tangible Class],
	[AAT].[AssetAttributeTypeName] AS [Name],
	[AAT].[Description] AS [Description],	
	[ADC].[AssetDepConventionName] AS [Convention Type],
	[DM].[AssetDepreciationMethodName] AS [Depreciation Method],
	[PER].[PercentValue] AS [Residual Percentage],
	[AAT].[AssetLife] AS [Asset Life],
	[FI].[Name] AS [Depreciation Frequency],
	[AQGL].[AccountName] AS [Acquired GL Account],
	[DPGL].[AccountName] AS [Depr Expense GL Account],
	[ADGL].[AccountName] AS [Accum Depr GL Account],
	[ASGL].[AccountName] AS [Asset Sale GL Account],
	[WOGL].[AccountName] AS [Asset Write Off GL Account],
	[WDGL].[AccountName] AS [Asset Write Down GL Account],
	[AAT].[UpdatedBy] AS [Updated By],
	[AAT].[UpdatedDate]	AS [Updated Date],
	[AAT].[IsActive] AS [Active],
	[AAT].[IsDeleted] AS [Deleted]
FROM dbo.AssetAttributeTypeAudit AAT WITH(NOLOCK)
	JOIN dbo.TangibleClass ATY WITH(NOLOCK) ON AAT.TangibleClassId=ATY.TangibleClassId	
	JOIN dbo.AssetDepConvention ADC WITH(NOLOCK) ON AAT.ConventionType = ADC.AssetDepConventionId	
	JOIN dbo.AssetDepreciationMethod DM WITH(NOLOCK) ON  AAT.DepreciationMethod=DM.AssetDepreciationMethodId
	JOIN dbo.AssetDepreciationFrequency FI WITH(NOLOCK) ON AAT.DepreciationFrequencyId=FI.AssetDepreciationFrequencyId
	JOIN dbo.GLAccount AQGL WITH(NOLOCK) ON  AAT.AcquiredGLAccountId=AQGL.GLAccountId
	JOIN dbo.GLAccount DPGL WITH(NOLOCK) ON  AAT.DeprExpenseGLAccountId=DPGL.GLAccountId
	JOIN dbo.GLAccount ADGL WITH(NOLOCK) ON  AAT.AdDepsGLAccountId=ADGL.GLAccountId
	JOIN dbo.GLAccount ASGL WITH(NOLOCK) ON  AAT.AssetSale=ASGL.GLAccountId
	JOIN dbo.GLAccount WOGL WITH(NOLOCK) ON  AAT.AssetWriteOff=WOGL.GLAccountId
	JOIN dbo.GLAccount WDGL WITH(NOLOCK) ON  AAT.AssetWriteDown=WDGL.GLAccountId
	LEFT JOIN dbo.[Percent] PER WITH(NOLOCK) ON AAT.ResidualPercentage=PER.PercentId