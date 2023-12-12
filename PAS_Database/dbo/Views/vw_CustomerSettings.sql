CREATE   VIEW [dbo].[vw_CustomerSettings]
AS
SELECT [Id]
      ,CS.[LegalEntityId]
	  ,LE.Name as LegalEntityName
      ,CS.[CreditTermsId]
	  ,CT.Name as CreditTerms
      ,CS.[CreditLimit]
      ,CS.[CurrencyId]
	  ,CC.Code as Currency
      ,CS.[MasterCompanyId]
      ,CS.[CreatedBy]
      ,CS.[UpdatedBy]
      ,CS.[CreatedDate]
      ,CS.[UpdatedDate]
      ,CS.[IsActive]
      ,CS.[IsDeleted]
  FROM [dbo].[CustomerSettings] CS
  LEFT JOIN [dbo].LegalEntity LE ON LE.LegalEntityId=CS.LegalEntityId
  LEFT JOIN [dbo].Currency CC ON CC.CurrencyId=CS.CurrencyId
  LEFT JOIN [dbo].CreditTerms CT ON CT.CreditTermsId=CS.CreditTermsId