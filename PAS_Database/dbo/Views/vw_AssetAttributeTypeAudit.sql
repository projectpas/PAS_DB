


CREATE VIEW [dbo].[vw_AssetAttributeTypeAudit]
AS
SELECT --AAT.* , 
	AAT.AssetAttributeTypeId AS PkID,
	AAT.AssetAttributeTypeId AS ID,
	ATY.TangibleClassName ,
	CT.Name AS ConventionTypeName,
	DM.AssetDepreciationMethodName,
	FI.Name AS AssetDepreciationFrequencyName,
	PER.PercentValue,
	AQGL.AccountName AS AcquiredGLAccount,
	DPGL.AccountName AS DeprExpenseGLAccount,
	ADGL.AccountName AS AdDepsGLAccount,
	ASGL.AccountName AS AssetSaleGLAccount,
	WOGL.AccountName AS AssetWriteOffGLAccount,
	WDGL.AccountName AS AssetWriteDownLAccount,
	LegalEntity = STUFF((SELECT ', ' + Name
			   FROM dbo.LegalEntity LE 
			   WHERE LE.LegalEntityId IN (SELECT Item FROM DBO.SPLITSTRING(AAT.SelectedCompanyIds,','))
			  FOR XML PATH('')), 1, 2, '')
FROM dbo.AssetAttributeType AAT WITH(NOLOCK)
	JOIN dbo.TangibleClass ATY WITH(NOLOCK) ON AAT.TangibleClassId=ATY.TangibleClassId
	JOIN dbo.ConventionType CT WITH(NOLOCK) ON AAT.ConventionType=CT.ConventionTypeId
	JOIN dbo.AssetDepreciationMethod DM WITH(NOLOCK) ON  AAT.DepreciationMethod=DM.AssetDepreciationMethodId
	JOIN dbo.AssetDepreciationFrequency FI WITH(NOLOCK) ON AAT.DepreciationFrequencyId=FI.AssetDepreciationFrequencyId
	JOIN dbo.GLAccount AQGL WITH(NOLOCK) ON  AAT.AcquiredGLAccountId=AQGL.GLAccountId
	JOIN dbo.GLAccount DPGL WITH(NOLOCK) ON  AAT.DeprExpenseGLAccountId=DPGL.GLAccountId
	JOIN dbo.GLAccount ADGL WITH(NOLOCK) ON  AAT.AdDepsGLAccountId=ADGL.GLAccountId
	JOIN dbo.GLAccount ASGL WITH(NOLOCK) ON  AAT.AssetSale=ASGL.GLAccountId
	JOIN dbo.GLAccount WOGL WITH(NOLOCK) ON  AAT.AssetWriteOff=WOGL.GLAccountId
	JOIN dbo.GLAccount WDGL WITH(NOLOCK) ON  AAT.AssetWriteDown=WDGL.GLAccountId
	LEFT JOIN dbo.[Percent] PER WITH(NOLOCK) ON AAT.ResidualPercentage=PER.PercentId