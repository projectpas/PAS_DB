CREATE   VIEW [dbo].[vw_CapabilityTypes]
AS
SELECT ct.[CapabilityTypeId] AS PkID
	  ,ct.[CapabilityTypeId] AS ID
      ,ct.[Description]
      ,ct.[IsActive]
      ,ct.[IsDeleted]
      ,ct.[CreatedBy]
      ,ct.[UpdatedBy]
      ,ct.[CreatedDate]
      ,ct.[UpdatedDate]
      ,ct.[MasterCompanyId]
      ,ct.[SequenceNo]
      ,ct.[CapabilityTypeDesc]
      ,ct.[SequenceMemo]
  FROM [dbo].[CapabilityType] ct WITH(NOLOCK) LEFT JOIN dbo.Condition c ON ct.ConditionId = c.ConditionId