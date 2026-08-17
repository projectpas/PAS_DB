

CREATE   VIEW [dbo].[vw_LegalEntityWithCode]
AS
SELECT [LegalEntityId]
	  ,[CompanyCode] +'-'+ [Name] AS [Name]
	  ,[MasterCompanyId]
	  ,[IsActive]
	  ,[IsDeleted]
  FROM [dbo].[LegalEntity]