CREATE   VIEW [dbo].[vw_MasterDiscountTypeAudit]
AS
SELECT DA.[MasterDiscountTypeAuditId]  AS PkID
      ,DA.[Id] AS ID
      ,DA.[Name]	  
      ,DA.[Description]
	  ,GL.[AccountName] AS 'GL Account'
      ,DA.[CreatedBy] AS [Created By]
      ,DA.[CreatedDate] AS [Created Date]
      ,DA.[UpdatedBy] AS [Updated By]
      ,DA.[UpdatedDate]  AS [Updated Date]
      ,DA.[IsActive] 'Active ?'
      ,DA.[IsDeleted] 'Deleted ?'	  
  FROM [dbo].[MasterDiscountTypeAudit] DA WITH(NOLOCK)
  JOIN [dbo].[GLAccount] GL ON  DA.GLAccountId = GL.GLAccountId