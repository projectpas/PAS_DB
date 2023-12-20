

CREATE VIEW [dbo].[vw_AssetIntangibleAttributeType]
AS
SELECT IAT.*,
IT.AssetIntangibleName AS AssetIntangibleType,
ADM.AssetDepreciationMethodName AS AssetDepreciationMethod,
DF.Name AS AssetAmortizationInterval,
IGL.AccountName AS IntangibleGLAccount,
AEGL.AccountName AS AmortExpenseGLAccount,
AACGL.AccountName AS AccAmortDeprGLAccount,
WDGL.AccountName AS IntangibleWriteDownGLAccount,
WOGL.AccountName AS IntangibleWriteOffGLAccount,
--LegalEntity = STUFF((SELECT ', ' + Name
--           FROM LegalEntityAssetIntangibleAttributeType	 LEA 
--		   JOIN LegalEntity LE ON LEA.LegalEntityId=LE.LegalEntityId
--           WHERE LEA.AssetIntangibleAttributeTypeId = IAT.AssetIntangibleAttributeTypeId 
--          FOR XML PATH('')), 1, 2, '')
LegalEntity = STUFF((SELECT ', ' + Name
           FROM LegalEntity LE 
		   --WHERE LE.LegalEntityId = AAT.SelectedCompanyIds
		   WHERE LE.LegalEntityId IN (SELECT Item FROM DBO.SPLITSTRING(IAT.SelectedCompanyIds,','))
          FOR XML PATH('')), 1, 2, '')
FROM AssetIntangibleAttributeType IAT
JOIN AssetIntangibleType IT ON IAT.AssetIntangibleTypeId=IT.AssetIntangibleTypeId
JOIN AssetDepreciationMethod ADM ON IAT.AssetDepreciationMethodId=ADM.AssetDepreciationMethodId
JOIN AssetDepreciationFrequency DF ON IAT.AssetAmortizationIntervalId=DF.AssetDepreciationFrequencyId
JOIN GLAccount IGL ON IAT.IntangibleGLAccountId=IGL.GLAccountId
JOIN GLAccount AEGL ON IAT.AmortExpenseGLAccountId=AEGL.GLAccountId
JOIN GLAccount AACGL ON IAT.AccAmortDeprGLAccountId=AACGL.GLAccountId
JOIN GLAccount WDGL ON IAT.IntangibleWriteDownGLAccountId=WDGL.GLAccountId
JOIN GLAccount WOGL ON IAT.IntangibleWriteOffGLAccountId=WOGL.GLAccountId