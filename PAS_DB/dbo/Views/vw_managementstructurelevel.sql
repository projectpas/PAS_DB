

CREATE VIEW [dbo].[vw_managementstructurelevel]
AS
SELECT dbo.ManagementStructureLevel.[ID]
      ,dbo.ManagementStructureLevel.[Code]
      ,dbo.ManagementStructureLevel.[Description]
      ,dbo.ManagementStructureLevel.[TypeID]
      ,dbo.ManagementStructureLevel.[MasterCompanyId]
      ,dbo.ManagementStructureLevel.[CreatedBy]
      ,dbo.ManagementStructureLevel.[UpdatedBy]
      ,dbo.ManagementStructureLevel.[CreatedDate]
      ,dbo.ManagementStructureLevel.[UpdatedDate]
      ,dbo.ManagementStructureLevel.[IsActive]
      ,dbo.ManagementStructureLevel.[IsDeleted]
	  ,dbo.ManagementStructureType.[Description] as TypeName
	  ,dbo.ManagementStructureType.[SequenceNo] as SequenceNo
  FROM [dbo].ManagementStructureLevel   WITH(NOLOCK)
  INNER JOIN ManagementStructureType  on ManagementStructureLevel.TypeID =ManagementStructureType.TypeID