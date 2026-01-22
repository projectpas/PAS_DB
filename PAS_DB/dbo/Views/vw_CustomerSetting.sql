
create   VIEW [dbo].[vw_CustomerSetting]  
AS  
 SELECT  Id,  
   CS.LegalEntityId,  
   LE.[Name] AS LegalEntityName,
   CS.CreditTermsId,  
   CT.Name AS CreditTerms,
   CS.CreditLimit,  
   CS.CurrencyId,  
   C.Code AS Currency,
   CS.MasterCompanyId,  
   CS.CreatedBy,  
   CS.UpdatedBy,  
   CS.CreatedDate,  
   CS.UpdatedDate,  
   CS.IsActive,  
   CS.IsDeleted
 FROM [DBO].[CustomerSettings] CS WITH (NOLOCK)  
 LEFT JOIN [DBO].[LegalEntity] LE WITH (NOLOCK) ON CS.LegalEntityId = LE.LegalEntityId  
 LEFT JOIN [DBO].[CreditTerms] CT WITH (NOLOCK) ON CS.CreditTermsId = CT.CreditTermsId  
 LEFT JOIN [DBO].[Currency] C WITH (NOLOCK) ON CS.CurrencyId = C.CurrencyId