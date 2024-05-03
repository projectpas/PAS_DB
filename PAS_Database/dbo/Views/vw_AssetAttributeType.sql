

CREATE VIEW [dbo].[vw_AssetAttributeType]
AS
SELECT AAT.[AssetAttributeTypeId]
      ,AAT.[TangibleClassId]
	  ,ATC.[TangibleClassName] 'TangibleClass'
      ,AAT.[AssetAttributeTypeName]
      ,AAT.[Description]
      ,AAT.[ConventionType]
	  ,ADC.[AssetDepConventionName] 'ConventionTypeName'
      ,AAT.[DepreciationMethod]
	  ,ADM.[AssetDepreciationMethodName] 'DepreciationMethodName'
      ,AAT.[ResidualPercentage]
	  ,ATP.[PercentValue] 'ResidualPercentageName'
      ,AAT.[AssetLife]
      ,AAT.[DepreciationFrequencyId]
	  ,ATF.[Name]'DepreciationFrequencyName'
      ,AAT.[AcquiredGLAccountId]
	  ,AGL.[AccountCode] +'-'+ AGL.[AccountName] 'AcquiredGLAccountName'
      ,AAT.[DeprExpenseGLAccountId]
	  ,DGL.[AccountCode] +'-'+ DGL.[AccountName] 'DeprExpenseGLAccountName'
      ,AAT.[AdDepsGLAccountId]
	  ,ADG.[AccountCode] +'-'+ ADG.[AccountName] 'AccumDeprGLAccountName'
      ,AAT.[AssetSale]
	  ,ASG.[AccountCode] +'-'+ ASG.[AccountName] 'AssetSaleGLAccountName'
      ,AAT.[AssetWriteOff]
	  ,AWG.[AccountCode] +'-'+ AWG.[AccountName] 'AssetWriteOffGLAccountName'
      ,AAT.[AssetWriteDown]
	  ,ARG.[AccountCode] +'-'+ ARG.[AccountName] 'AssetWriteDownGLAccountName'
      ,AAT.[MasterCompanyId]
      ,AAT.[CreatedBy]
      ,AAT.[CreatedDate]
      ,AAT.[UpdatedBy]
      ,AAT.[UpdatedDate]
      ,AAT.[IsActive]
      ,AAT.[IsDeleted]	  	  
	  ,STUFF((SELECT ',' + I.Name FROM DBO.SPLITSTRING((SELECT SelectedCompanyIds FROM [dbo].[AssetAttributeType] AMM WHERE AMM.AssetAttributeTypeId = AAT.AssetAttributeTypeId),',') AS ss
				LEFT JOIN [DBO].[LegalEntity] I ON ss.Item = I.LegalEntityId
		FOR XML PATH('')), 1, 1, '') 'LegalEntity'
	  ,AAT.SelectedCompanyIds
  FROM [dbo].[AssetAttributeType] AAT WITH (NOLOCK)
  LEFT JOIN [dbo].[TangibleClass] ATC WITH (NOLOCK) ON AAT.TangibleClassId = ATC.TangibleClassId
  LEFT JOIN [dbo].[AssetDepConvention] ADC WITH (NOLOCK) ON AAT.ConventionType = ADC.AssetDepConventionId
  LEFT JOIN [dbo].[AssetDepreciationMethod] ADM WITH (NOLOCK) ON AAT.DepreciationMethod = ADM.AssetDepreciationMethodId
  LEFT JOIN [dbo].[Percent] ATP WITH (NOLOCK) ON AAT.ResidualPercentage = ATP.PercentId
  LEFT JOIN [dbo].[AssetDepreciationFrequency] ATF WITH (NOLOCK) ON AAT.DepreciationFrequencyId = ATF.AssetDepreciationFrequencyId
  LEFT JOIN [dbo].[GLAccount] AGL WITH (NOLOCK) ON AAT.AcquiredGLAccountId = AGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] DGL WITH (NOLOCK) ON AAT.DeprExpenseGLAccountId = DGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ADG WITH (NOLOCK) ON AAT.AdDepsGLAccountId = ADG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ASG WITH (NOLOCK) ON AAT.AssetSale = ASG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] AWG WITH (NOLOCK) ON AAT.AssetWriteOff = AWG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ARG WITH (NOLOCK) ON AAT.AssetWriteDown = ARG.GLAccountId