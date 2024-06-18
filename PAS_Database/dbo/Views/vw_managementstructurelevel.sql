CREATE   VIEW [dbo].[vw_managementstructurelevel]
AS

SELECT ML.[ID]
      ,MT.[Description] AS TypeName
      ,ML.[Code]
	  ,ML.LegalEntityId
      ,ML.[Description]
      ,ML.[TypeID]     
      ,ML.[IsActive]
      ,ML.[IsDeleted]
      ,ML.[CreatedBy]
      ,ML.[UpdatedBy]
      ,ML.[CreatedDate]
      ,ML.[UpdatedDate]
	  ,ML.[MasterCompanyId]	  
FROM dbo.[ManagementStructureLevel] ML  WITH(NOLOCK) INNER JOIN ManagementStructureType MT ON ML.TypeID = MT.TypeID WHERE ML.LegalEntityId IS NULL