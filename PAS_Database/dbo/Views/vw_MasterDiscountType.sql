CREATE   VIEW [dbo].[vw_MasterDiscountType]
AS
SELECT MD.[Id]
      ,MD.[Name]
      ,MD.[Description]
      ,MD.[GLAccountId]
	  ,(GL.[AccountCode] + '-' + GL.[AccountName]) AS GLAccountName
      ,MD.[MasterCompanyId]
      ,MD.[CreatedBy]
      ,MD.[CreatedDate]
      ,MD.[UpdatedBy]
      ,MD.[UpdatedDate]
      ,MD.[IsActive]
      ,MD.[IsDeleted]
  FROM [dbo].[MasterDiscountType] MD WITH(NOLOCK)
  LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON MD.GLAccountId=GL.GLAccountId