CREATE   VIEW [dbo].[vw_DeprNonDeprTangibleAssets]
AS
SELECT AAT.[DeprNonDeprTangibleAssetsId]
      ,AAT.[TangibleClassId]
	  ,ATC.[TangibleClassName] 'TangibleClassName'
	  ,AAT.[AssetAttributeTypeName]
	  ,AAT.[Description] AS [Description]
      ,AAT.[AssetDeprMethodId]
	  ,ADM.[AssetDepreciationMethodName] 'DepreciationMethodName'
      
	  ,AAT.[CalibratedGLAccountId]
	  ,CGL.[AccountCode] +'-'+ CGL.[AccountName] 'CalibratedGLAccountName'

	  ,AAT.[AccumDeprGLAccountId]
	  ,ADGL.[AccountCode] +'-'+ ADGL.[AccountName] 'AccumDeprGLAccountName'
	  
	  ,AAT.[AcquiredGLAccountId]
	  ,AGL.[AccountCode] +'-'+ AGL.[AccountName] 'AcquiredGLAccountName'
      ,AAT.[DeprExpenseGLAccountId]
	  ,DGL.[AccountCode] +'-'+ DGL.[AccountName] 'DeprExpenseGLAccountName'
      ,AAT.[AssetSaleGLAccountId]
	  ,ASG.[AccountCode] +'-'+ ASG.[AccountName] 'AssetSaleGLAccountName'
      ,AAT.[AssetWriteOffGLAccountId]
	  ,AWG.[AccountCode] +'-'+ AWG.[AccountName] 'AssetWriteOffGLAccountName'
      ,AAT.[AssetWriteDownGLAccountId]
	  ,ARG.[AccountCode] +'-'+ ARG.[AccountName] 'AssetWriteDownGLAccountName'
      ,AAT.[MasterCompanyId]
      ,AAT.[CreatedBy]
      ,AAT.[CreatedDate]
      ,AAT.[UpdatedBy]
      ,AAT.[UpdatedDate]
      ,AAT.[IsActive]
      ,AAT.[IsDeleted]	  	  
	  ,STUFF((SELECT ',' + I.Name FROM DBO.SPLITSTRING((SELECT SelectedCompanyIds FROM [dbo].[AssetAttributeType] AMM WHERE AMM.AssetAttributeTypeId = AAT.DeprNonDeprTangibleAssetsId),',') AS ss
				LEFT JOIN [DBO].[LegalEntity] I ON ss.Item = I.LegalEntityId
		FOR XML PATH('')), 1, 1, '') 'LegalEntity'
	  ,AAT.SelectedCompanyIds
  FROM [dbo].[DeprNonDeprTangibleAssets] AAT WITH (NOLOCK)
  LEFT JOIN [dbo].[TangibleClass] ATC WITH (NOLOCK) ON AAT.TangibleClassId = ATC.TangibleClassId
  LEFT JOIN [dbo].[AssetDepreciationMethod] ADM WITH (NOLOCK) ON AAT.AssetDeprMethodId = ADM.AssetDepreciationMethodId
  LEFT JOIN [dbo].[GLAccount] AGL WITH (NOLOCK) ON AAT.AcquiredGLAccountId = AGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] DGL WITH (NOLOCK) ON AAT.DeprExpenseGLAccountId = DGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ASG WITH (NOLOCK) ON AAT.AssetSaleGLAccountId = ASG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] AWG WITH (NOLOCK) ON AAT.AssetWriteOffGLAccountId = AWG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ARG WITH (NOLOCK) ON AAT.AssetWriteDownGLAccountId = ARG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] CGL WITH (NOLOCK) ON AAT.CalibratedGLAccountId = CGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ADGL WITH (NOLOCK) ON AAT.AccumDeprGLAccountId = ADGL.GLAccountId