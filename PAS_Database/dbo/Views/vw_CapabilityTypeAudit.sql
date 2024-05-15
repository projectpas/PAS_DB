CREATE    VIEW [dbo].[vw_CapabilityTypeAudit]
AS
SELECT ct.[CapabilityTypeId] AS PkID
	  ,ct.[CapabilityTypeId] AS ID
	  ,ct.CapabilityTypeDesc AS [Work Scope/Cap Type]
	  ,ct.SequenceNo AS [Sequence Num]
      ,ct.[Description]
      ,ct.[IsActive]
      ,ct.[IsDeleted]
      ,ct.[CreatedBy]
      ,ct.[UpdatedBy]
      ,ct.[CreatedDate]
      ,ct.[UpdatedDate]
  FROM [dbo].[CapabilityTypeAudit] ct WITH(NOLOCK) LEFT JOIN dbo.Condition c ON ct.ConditionId = c.ConditionId