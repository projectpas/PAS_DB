

CREATE VIEW [dbo].[vw_MasterDiscountType]
AS
SELECT MD.[Id]
      ,MD.[Name]
      ,MD.[Description]
      ,MD.[GLAccountId]
	  ,GL.[AccountName] AS GLAccountName
      ,MD.[MasterCompanyId]
      ,MD.[CreatedBy]
      ,MD.[CreatedDate]
      ,MD.[UpdatedBy]
      ,MD.[UpdatedDate]
      ,MD.[IsActive]
      ,MD.[IsDeleted]
  FROM [dbo].[MasterDiscountType] MD LEFT JOIN [dbo].[GLAccount] GL ON MD.GLAccountId=GL.GLAccountId