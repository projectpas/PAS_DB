
CREATE   VIEW [dbo].[vw_CapabilityTypes]
AS
SELECT ct.[CapabilityTypeId] AS PkID
	  ,ct.[CapabilityTypeId] AS ID
      ,ct.[Description]
      ,ct.[IsActive]
      ,ct.[IsDeleted]
      ,ct.[SequenceMemo]
      ,ct.[MasterCompanyId]
      ,ct.[CreatedBy]
      ,ct.[UpdatedBy]
      ,ct.[CreatedDate]
      ,ct.[UpdatedDate]
      ,ct.[SequenceNo]
      ,ct.[CapabilityTypeDesc]
      ,ct.[WorkScopeId]
      ,ct.[ConditionId]
	  ,c.[Description] AS Condition
  FROM [dbo].[CapabilityType] ct LEFT JOIN dbo.Condition c ON ct.ConditionId = c.ConditionId