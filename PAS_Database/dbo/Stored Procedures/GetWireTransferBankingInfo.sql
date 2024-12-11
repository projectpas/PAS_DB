/*************************************************************             
 ** File:   [GetWireTransferBankingInfo]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetWireTransferBankingInfo
 ** Purpose:           
 ** Date:  10/12/2024        
            
 ** PARAMETERS: @ManagementStructId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    10/12/2024		EKTA CHANDEGRA	 Created  

 EXEC GetWireTransferBankingInfo 1 
************************************************************************/  
CREATE   PROCEDURE [dbo].[GetWireTransferBankingInfo]
    @ManagementStructId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		-- Declare variable to store MasterCompanyId
		DECLARE @MasterCompanyId INT;
		DECLARE @MTI_MasterComapnyId BIGINT = 12;

		-- Retrieve MasterCompanyId from EntityStructureSetup table
		SET @MasterCompanyId = (SELECT MasterCompanyId
								FROM [dbo].[EntityStructureSetup] WITH(NOLOCK)
								WHERE EntityStructureId = @ManagementStructId);

		-- Check if MasterCompanyId is equal to the value for @MTI_MasterComapnyId
		IF @MasterCompanyId = CAST(@MTI_MasterComapnyId AS INT)
		BEGIN
			-- Query for @MTI_MasterComapnyId
			SELECT TOP 1
				 ISNULL(inter.BankName,'') AS BankName,
				 ISNULL(inter.BeneficiaryBank,'') AS BeneficiaryBank,
				 ISNULL(inter.BeneficiaryBankAccount,'') AS BeneficiaryBankAccount,
				 ISNULL(inter.ABA,'') AS ABA,
				 ISNULL(inter.SwiftCode,'') AS SwiftCode
			FROM 
				[dbo].[EntityStructureSetup] ess WITH(NOLOCK)
				INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ess.Level1Id = msl.ID
				INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				LEFT JOIN [dbo].[LegalEntityInternationalWireBanking] lockbox WITH(NOLOCK) ON le.LegalEntityId = lockbox.LegalEntityId
				LEFT JOIN [dbo].[InternationalWirePayment] inter WITH(NOLOCK) ON lockbox.InternationalWirePaymentId = inter.InternationalWirePaymentId
				LEFT JOIN [dbo].[ACH] ach WITH(NOLOCK) ON le.LegalEntityId = ach.LegalEntityId AND ach.IsPrimay = 1
				INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
				INNER JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
			WHERE 
				ess.IsActive = 1 
				AND ess.IsDeleted = 0 
				AND ess.EntityStructureId = @ManagementStructId;
		END
    ELSE
		BEGIN
			-- Query for other companies
			SELECT TOP 1
				ISNULL(inter.BankName,'') AS BankName,
				ad.Line1,
				ad.City,
				ad.StateOrProvince,
				ad.PostalCode,
				co.countries_name,
				ISNULL(inter.BeneficiaryBank,'') AS BeneficiaryBank,
				ISNULL(inter.BeneficiaryBankAccount,'') AS BeneficiaryBankAccount,
				ISNULL(inter.ABA,'') AS ABA,
				ISNULL(inter.SwiftCode,'') AS SwiftCode
			FROM 
				[dbo].[EntityStructureSetup] ess WITH(NOLOCK)
				INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ess.Level1Id = msl.ID
				INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON  msl.LegalEntityId = le.LegalEntityId
				LEFT JOIN [dbo].[LegalEntityInternationalWireBanking] lockbox WITH(NOLOCK) ON le.LegalEntityId = lockbox.LegalEntityId
				LEFT JOIN [dbo].[InternationalWirePayment] inter WITH(NOLOCK) ON lockbox.InternationalWirePaymentId = inter.InternationalWirePaymentId
				INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
				INNER JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
			WHERE 
				ess.IsActive = 1 
				AND ess.IsDeleted = 0 
				AND ess.EntityStructureId = @ManagementStructId;
		END
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetWireTransferBankingInfo'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManagementStructId, '') 
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
END;