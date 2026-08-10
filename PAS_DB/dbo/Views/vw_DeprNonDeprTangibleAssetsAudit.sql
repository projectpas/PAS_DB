



CREATE VIEW [dbo].[vw_DeprNonDeprTangibleAssetsAudit]
AS
SELECT
	AAT.[AuditDeprNonDeprTangibleAssetsId] AS PkID
	,AAT.[DeprNonDeprTangibleAssetsId] AS ID
	,AAT.[DeprNonDeprTangibleClassTypeId]
      ,ATC.[TangibleClassName] 'TangibleClassName'
	  ,AT2.[DeprNonDeprTangibleClassTypeName]
	  ,AAT.[Description] AS [Description]
	  ,ADM.[AssetDepreciationMethodName] 'DepreciationMethodName'

	  ,AAT.[ResidualPercentage]
	  ,PER.[PercentValue] 'ResidualPercentageValue'
	  ,AAT.[AssetLife]
	  ,FI.[Name] 'DepreciationFrequencyName'

	  ,CGL.[AccountCode] +'-'+ CGL.[AccountName] 'CalibratedGLAccountName'
	  ,ADGL.[AccountCode] +'-'+ ADGL.[AccountName] 'AccumDeprGLAccountName'
	  
	  ,AGL.[AccountCode] +'-'+ AGL.[AccountName] 'AcquiredGLAccountName'
	  ,DGL.[AccountCode] +'-'+ DGL.[AccountName] 'DeprExpenseGLAccountName'
	  ,ASG.[AccountCode] +'-'+ ASG.[AccountName] 'AssetSaleGLAccountName'
	  ,AWG.[AccountCode] +'-'+ AWG.[AccountName] 'AssetWriteOffGLAccountName'
	  ,ARG.[AccountCode] +'-'+ ARG.[AccountName] 'AssetWriteDownGLAccountName'
      ,AAT.[CreatedBy]
      ,AAT.[CreatedDate]
      ,AAT.[UpdatedBy]
      ,AAT.[UpdatedDate]
      ,AAT.[IsActive]
      ,AAT.[IsDeleted]
FROM dbo.DeprNonDeprTangibleAssetsAudit AAT WITH(NOLOCK)
	LEFT JOIN [dbo].[DeprNonDeprTangibleClassTypes] AT2 WITH (NOLOCK) ON AAT.DeprNonDeprTangibleClassTypeId = AT2.DeprNonDeprTangibleClassTypeId
  LEFT JOIN [dbo].[TangibleClass] ATC WITH (NOLOCK) ON AAT.TangibleClassId = ATC.TangibleClassId
  LEFT JOIN [dbo].[AssetDepreciationMethod] ADM WITH (NOLOCK) ON AAT.AssetDeprMethodId = ADM.AssetDepreciationMethodId
  LEFT JOIN [dbo].[Percent] PER WITH (NOLOCK) ON AAT.ResidualPercentage = PER.PercentId
  LEFT JOIN [dbo].[AssetDepreciationFrequency] FI WITH (NOLOCK) ON AAT.DepreciationFrequencyId = FI.AssetDepreciationFrequencyId
  LEFT JOIN [dbo].[GLAccount] AGL WITH (NOLOCK) ON AAT.AcquiredGLAccountId = AGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] DGL WITH (NOLOCK) ON AAT.DeprExpenseGLAccountId = DGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ASG WITH (NOLOCK) ON AAT.AssetSaleGLAccountId = ASG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] AWG WITH (NOLOCK) ON AAT.AssetWriteOffGLAccountId = AWG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ARG WITH (NOLOCK) ON AAT.AssetWriteDownGLAccountId = ARG.GLAccountId
  LEFT JOIN [dbo].[GLAccount] CGL WITH (NOLOCK) ON AAT.CalibratedGLAccountId = CGL.GLAccountId
  LEFT JOIN [dbo].[GLAccount] ADGL WITH (NOLOCK) ON AAT.AccumDeprGLAccountId = ADGL.GLAccountId