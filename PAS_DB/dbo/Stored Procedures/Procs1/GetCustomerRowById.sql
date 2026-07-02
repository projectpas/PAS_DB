/*************************************************************             
 ** File:   [GetCustomerRowById]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetCustomerRowById
 ** Purpose:           
 ** Date:  10/12/2024        
            
 ** PARAMETERS: @customerId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    10/12/2024		EKTA CHANDEGRA	 Created 
	2    02/07/2026     Sahdev Saliya    Added Physical Resale [PN-17018]

 EXEC GetCustomerRowById 3409
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetCustomerRowById]
 @customerId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		SELECT 
			t.CustomerId,
			t.AddressId,
			t.IsAddressForBilling,
			t.IsAddressForShipping,
			vt.CustomerAffiliationId,
			type.CustomerTypeName AS Type,
			t.CustomerTypeId,
			t.Name,
			t.CustomerPhone,
			t.Email,
			ad.Line1 AS Address1,
			ad.Line2 AS Address2,
			ad.Line3 AS Address3,
			ad.City,
			ad.StateOrProvince,
			ad.PostalCode,
			ad.CountryId,
			cont.countries_name AS CountryName,
			t.CustomerCode,
			t.DoingBuinessAsName,
			t.ParentId,
			t.IsParent,
			cust.Name AS CustomerParentName,
			t.CustomerURL,
			t.ContractReference,
			t.IsPBHCustomer,
			t.PBHCustomerMemo,
			t.RestrictPMA,
			t.RestrictDER,
			t.IsCustomerAlsoVendor,
			t.CreatedBy,
			t.UpdatedBy,
			t.UpdatedDate,
			t.CreatedDate,
			t.MasterCompanyId,
			t.IsActive,
			t.CustomerPhoneExt,
			v.Description AS AccountType,
			t.IsTradeRestricted,
			t.TradeRestrictedMemo,
			t.IsTrackScoreCard,
			t.CommunicationPreference,
			CASE 
				WHEN t.CommunicationPreference = 1 THEN 'Email'
				WHEN t.CommunicationPreference = 2 THEN 'Phone'
				ELSE 'Text Message'
			END AS CommunicationPreferenceText,
			t.Ismiscellaneous,
			t.IsStageChange,
			t.IsCommunicationPreference,
			t.IsCustomerShipping,
			t.Memo,
			t.PhysicalResale
		FROM 
			[dbo].[Customer] t WITH(NOLOCK)
		LEFT JOIN [dbo].[Address] ad WITH(NOLOCK) ON t.AddressId = ad.AddressId
		LEFT JOIN [dbo].[CustomerType] type WITH(NOLOCK) ON t.CustomerTypeId = type.CustomerTypeId
		LEFT JOIN [dbo].[Countries] cont WITH(NOLOCK) ON ad.CountryId = cont.countries_id
		LEFT JOIN [dbo].[CustomerAffiliation] vt WITH(NOLOCK) ON t.CustomerAffiliationId = vt.CustomerAffiliationId
		LEFT JOIN [dbo].[Customer] cust WITH(NOLOCK) ON t.ParentId = cust.CustomerId
		LEFT JOIN [dbo].[CustomerAffiliation] v WITH(NOLOCK) ON t.CustomerAffiliationId = v.CustomerAffiliationId
		WHERE 
			t.CustomerId = @customerId
		ORDER BY 
			t.UpdatedDate DESC;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetCustomerRowById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@customerId, '') 
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1); 
	END CATCH
END