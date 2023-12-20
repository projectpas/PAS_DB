



CREATE VIEW [dbo].[vw_AssetAttributeType]
AS
SELECT AAT.* ,
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
--LegalEntity = STUFF((SELECT ', ' + Name
--           FROM LegalEntityAssetAttributeType LEA 
--		   JOIN LegalEntity LE ON LEA.LegalEntityId=LE.LegalEntityId
--           WHERE LEA.AssetAttributeTypeId = AAT.AssetAttributeTypeId 
--          FOR XML PATH('')), 1, 2, '')
LegalEntity = STUFF((SELECT ', ' + Name
           FROM LegalEntity LE 
		   --WHERE LE.LegalEntityId = AAT.SelectedCompanyIds
		   WHERE LE.LegalEntityId IN (SELECT Item FROM DBO.SPLITSTRING(AAT.SelectedCompanyIds,','))
          FOR XML PATH('')), 1, 2, '')
FROM AssetAttributeType AAT
JOIN TangibleClass ATY ON AAT.TangibleClassId=ATY.TangibleClassId
JOIN ConventionType CT ON AAT.ConventionType=CT.ConventionTypeId
JOIN AssetDepreciationMethod DM ON AAT.DepreciationMethod=DM.AssetDepreciationMethodId
--JOIN AssetDepreciationInterval DI ON AAT.DepreciationFrequencyId=DI.AssetDepreciationIntervalId
JOIN AssetDepreciationFrequency FI ON AAT.DepreciationFrequencyId=FI.AssetDepreciationFrequencyId
LEFT JOIN [Percent] PER ON AAT.ResidualPercentage=PER.PercentId
JOIN GLAccount AQGL ON  AAT.AcquiredGLAccountId=AQGL.GLAccountId
JOIN GLAccount DPGL ON  AAT.DeprExpenseGLAccountId=DPGL.GLAccountId
JOIN GLAccount ADGL ON  AAT.AdDepsGLAccountId=ADGL.GLAccountId
JOIN GLAccount ASGL ON  AAT.AssetSale=ASGL.GLAccountId
JOIN GLAccount WOGL ON  AAT.AssetWriteOff=WOGL.GLAccountId
JOIN GLAccount WDGL ON  AAT.AssetWriteDown=WDGL.GLAccountId