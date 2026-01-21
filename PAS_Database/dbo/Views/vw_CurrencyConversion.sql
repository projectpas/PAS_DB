CREATE VIEW [dbo].[vw_CurrencyConversion]  
AS  
 SELECT  CurrencyConversionId,   
   CS.CurrencyTypeId,
   CT.[Name] CurrencyType,   
   CS.FromCurrencyId,  
   FC.Code AS FromCurrency,
   CS.ToCurrencyId,  
   TC.Code AS ToCurrency,
   ISNULL(CS.ConversionRate,0) ConversionRate,
   CS.MasterCompanyId,  
   CS.CreatedBy,  
   CS.UpdatedBy,  
   CS.CreatedDate,  
   CS.UpdatedDate,  
   CS.IsActive,  
   CS.IsDeleted
 FROM [DBO].[CurrencyConversion] CS WITH (NOLOCK)  
 LEFT JOIN [DBO].[CurrencyType] CT WITH (NOLOCK) ON CS.CurrencyTypeId = CT.CurrencyTypeId  
 LEFT JOIN [DBO].[Currency] FC WITH (NOLOCK) ON CS.FromCurrencyId = FC.CurrencyId
 LEFT JOIN [DBO].[Currency] TC WITH (NOLOCK) ON CS.ToCurrencyId = TC.CurrencyId