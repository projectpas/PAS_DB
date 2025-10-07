
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
    2    12/12/2024		EKTA CHANDEGRA	 Check IsNUll And Add Inline Html  
    3    25/12/2024		EKTA CHANDEGRA	 Check IsPrimary 
    4    09/Jul/2025	RAJESH GAMI		 Manage address space
	5    16/Jul/2025	Moin Bloch		 Added UPPERCASE
	6    10/Sep/2025	RAJESH GAMI		 Rename the #value as mentioned in the PBI (PN-14096), Remove line break comma
 EXEC GetWireTransferBankingInfo 1 
************************************************************************/  
CREATE     PROCEDURE [dbo].[GetWireTransferBankingInfo]
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
			(
				 CASE WHEN inter.BankName IS NOT NULL THEN 
                '<label style="text-transform: uppercase;">' + UPPER(inter.BankName) + '</label><br />' 
				ELSE '' END +
				CASE WHEN inter.BeneficiaryBank IS NOT NULL THEN 
					'<label style="text-transform: uppercase;">' + UPPER(inter.BeneficiaryBank) + '</label><br />' 
				ELSE '' END +
				CASE WHEN inter.BeneficiaryBankAccount IS NOT NULL THEN 
					'ACCOUNT #: <label style="text-transform: uppercase;">' + UPPER(inter.BeneficiaryBankAccount) + '</label>' 
				ELSE '' END +
				CASE WHEN inter.BeneficiaryBankAccount IS NOT NULL AND LTRIM(RTRIM(inter.BeneficiaryBankAccount)) != '' THEN '' ELSE '' END + 
				'<br />' +
				CASE WHEN inter.ABA IS NOT NULL THEN 
					'ROUTING #: <label style="text-transform: uppercase;">' + UPPER(inter.ABA) + '</label><br />' 
				ELSE '' END +
				CASE WHEN inter.SwiftCode IS NOT NULL THEN 
					'SWIFT CODE: <label style="text-transform: uppercase;">' + UPPER(inter.SwiftCode) + '</label>' 
				ELSE '' END
			) AS chequeTo
			FROM 
				[dbo].[EntityStructureSetup] ess WITH(NOLOCK)
				INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ess.Level1Id = msl.ID
				INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				LEFT JOIN [dbo].[LegalEntityInternationalWireBanking] lockbox WITH(NOLOCK) ON le.LegalEntityId = lockbox.LegalEntityId AND lockbox.IsPrimay = 1
				LEFT JOIN [dbo].[InternationalWirePayment] inter WITH(NOLOCK) ON lockbox.InternationalWirePaymentId = inter.InternationalWirePaymentId
				LEFT JOIN [dbo].[ACH] ach WITH(NOLOCK) ON le.LegalEntityId = ach.LegalEntityId AND ach.IsPrimay = 1
				INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
				INNER JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
			WHERE 
				ISNULL(ess.IsActive,0) = 1
				AND ISNULL(ess.IsDeleted,0) = 0
				AND ess.EntityStructureId = @ManagementStructId;
		END
    ELSE
		BEGIN
			-- Query for other companies
			SELECT TOP 1
			(
				 CASE WHEN inter.BankName IS NOT NULL THEN 
                '<label style="text-transform: uppercase;">' + UPPER(inter.BankName) + '</label><br />' 
				ELSE '' END +
				CASE WHEN ad.Line1 IS NOT NULL THEN 
					'<label style="text-transform: uppercase;">' + UPPER(ad.Line1) + '</label><br />' 
				ELSE '' END +
				CASE WHEN ad.City IS NOT NULL THEN 
					'<label style="text-transform: uppercase;">' + UPPER(ad.City) +  ', '+	CASE WHEN ad.StateOrProvince IS NOT NULL THEN 
					 + UPPER(ad.StateOrProvince) 
				ELSE '' END + ', ' +CASE WHEN ad.PostalCode IS NOT NULL THEN UPPER(ad.PostalCode) ELSE '' END + '</label>' 
				ELSE '' END +
				'<br />' + 
				--CASE WHEN ad.StateOrProvince IS NOT NULL THEN 
				--	'<label style="text-transform: uppercase;">' + ad.StateOrProvince + '</label>' 
				--ELSE '' END +
				--',' +
				--CASE WHEN ad.PostalCode IS NOT NULL THEN ad.PostalCode ELSE '' END + 
				--'<br />' +
				CASE WHEN co.countries_name IS NOT NULL THEN 
					'<label style="text-transform: uppercase;">' + UPPER(co.countries_name) + '</label><br />' 
				ELSE '' END +
				CASE WHEN inter.BeneficiaryBank IS NOT NULL THEN 
					'<label style="text-transform: uppercase;">' + UPPER(inter.BeneficiaryBank) + '</label><br />' 
				ELSE '' END +
				CASE WHEN inter.BeneficiaryBankAccount IS NOT NULL THEN 
					'ACCT# <label style="text-transform: uppercase;">' + UPPER(inter.BeneficiaryBankAccount) + '</label>' 
				ELSE '' END +
				CASE WHEN inter.BeneficiaryBankAccount IS NOT NULL AND LTRIM(RTRIM(inter.BeneficiaryBankAccount)) != '' THEN '' ELSE '' END + 
				'<br />' +
				CASE WHEN inter.ABA IS NOT NULL THEN 
					'ABA# <label style="text-transform: uppercase;">' + UPPER(inter.ABA) + '</label><br />' 
				ELSE '' END +
				CASE WHEN inter.SwiftCode IS NOT NULL THEN 
					'SWIFT/IBAN CODE: <label style="text-transform: uppercase;">' + UPPER(inter.SwiftCode) + '</label>' 
				ELSE '' END
			) AS chequeTo
			FROM 
				[dbo].[EntityStructureSetup] ess WITH(NOLOCK)
				INNER JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON ess.Level1Id = msl.ID
				INNER JOIN [dbo].[LegalEntity] le WITH(NOLOCK) ON  msl.LegalEntityId = le.LegalEntityId
				LEFT JOIN [dbo].[LegalEntityInternationalWireBanking] lockbox WITH(NOLOCK) ON le.LegalEntityId = lockbox.LegalEntityId AND lockbox.IsPrimay = 1
				LEFT JOIN [dbo].[InternationalWirePayment] inter WITH(NOLOCK) ON lockbox.InternationalWirePaymentId = inter.InternationalWirePaymentId
				INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
				INNER JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
			WHERE 
				ISNULL(ess.IsActive,0) = 1
				AND ISNULL(ess.IsDeleted,0) = 0
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