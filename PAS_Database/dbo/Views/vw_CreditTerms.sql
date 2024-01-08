

CREATE VIEW [dbo].[vw_CreditTerms]
AS
SELECT ct.[CreditTermsId]
      ,ct.[Name]
      ,ct.[PercentId] AS [Percentage]
	  ,p.[PercentValue] AS [Percent]
      ,ct.[Days]
      ,ct.[NetDays]
      ,ct.[Memo]
      ,ct.[MasterCompanyId]
      ,ct.[CreatedBy]
      ,ct.[UpdatedBy]
      ,ct.[CreatedDate]
      ,ct.[UpdatedDate]
      ,ct.[IsActive]
      ,ct.[IsDeleted]
  FROM [dbo].[CreditTerms] ct left JOIN dbo.[Percent] p  ON CAST(CT.PercentId AS INT) = p.PercentId 
  --ct.[Percentage]=p.PercentId