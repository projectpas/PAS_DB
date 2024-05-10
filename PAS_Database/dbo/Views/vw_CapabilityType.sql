
CREATE   VIEW [dbo].[vw_CapabilityType]
AS
SELECT ct.[CapabilityTypeId] AS PkID
	  ,ct.[CapabilityTypeId] AS ID
      ,ct.[Description]
      ,ct.[CreatedBy]
      ,ct.[UpdatedBy]
      ,ct.[CreatedDate]
      ,ct.[UpdatedDate]
	   ,ct.[IsActive]
      ,ct.[IsDeleted]
  FROM [dbo].[CapabilityType] ct