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
	7    08/Oct/2025	RAJESH GAMI		 Added logic for NEO(PN-14371)
	8    30/Oct/2025	RAJESH GAMI		 Check the condition with MasterCompanyCode instead of MasterCompanyId
	9    20/Apr/2026	AYUSHI PATEL	 return the BankName based on MasterCompanyCode (lower case for a2z)
 EXEC GetWireTransferBankingInfo 38 
************************************************************************/  
CREATE     PROCEDURE [dbo].[GetWireTransferBankingInfo]
    @ManagementStructId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		DECLARE @MasterCompanyId INT , @CompanyCode VARCHAR(100)='';
		--DECLARE @MTI_MasterComapnyId BIGINT = 12,@NEO_MasterComapnyId BIGINT = 20;
		DECLARE @MTI_MasterCompanyCode  VARCHAR(100) ='MTI',@NEO_MasterCompanyIdCode  VARCHAR(100)='NEO' ,@a2z_MasterCompanyIdCode  VARCHAR(100)='a2z';
		SET @MasterCompanyId = (SELECT MasterCompanyId	FROM [dbo].[EntityStructureSetup] WITH(NOLOCK)	WHERE EntityStructureId = @ManagementStructId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1 );
		SET @CompanyCode = (SELECT TOP 1 MasterCompanyCode FROM dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1 )

		IF @CompanyCode = @MTI_MasterCompanyCode
		BEGIN
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
		ELSE IF @CompanyCode = @NEO_MasterCompanyIdCode
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
				CASE 
					WHEN ISNULL(TRIM(inter.BankLocation1), '') <> '' AND ISNULL(TRIM(inter.BankLocation2), '') <> '' THEN
					'<label style="text-transform: uppercase;">' 
					+ UPPER(inter.BankLocation1) + ', ' + UPPER(inter.BankLocation2) 
						+ '</label><br />'
        
					WHEN ISNULL(TRIM(inter.BankLocation1), '') <> '' THEN
						'<label style="text-transform: uppercase;">' 
						+ UPPER(inter.BankLocation1) 
						+ '</label><br />'

					WHEN ISNULL(TRIM(inter.BankLocation2), '') <> '' THEN
						'<label style="text-transform: uppercase;">' 
						+ UPPER(inter.BankLocation2) 
						+ '</label><br />'
					ELSE ''
				END +
				CASE WHEN inter.BeneficiaryBankAccount IS NOT NULL THEN 
					'ACCT# <label style="text-transform: uppercase;">' + UPPER(inter.BeneficiaryBankAccount) + '</label>' 
				ELSE '' END +
				CASE WHEN inter.BeneficiaryBankAccount IS NOT NULL AND LTRIM(RTRIM(inter.BeneficiaryBankAccount)) != '' THEN '' ELSE '' END + 
				'<br />' +
				CASE WHEN inter.ABA IS NOT NULL THEN 
					'ABA# <label style="text-transform: uppercase;">' + UPPER(inter.ABA) + '</label><br />' 
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
		ELSE
		BEGIN
			-- Query for other companies
			SELECT TOP 1
			(
				CASE WHEN inter.BankName IS NOT NULL THEN 
					'<label style="text-transform:' + 
					CASE 
						WHEN @CompanyCode = @a2z_MasterCompanyIdCode THEN 'lowercase'
						ELSE 'uppercase'
					END +
					';">' + 
					CASE 
						WHEN @CompanyCode = @a2z_MasterCompanyIdCode THEN LOWER(inter.BankName)
						ELSE UPPER(inter.BankName)
					END 
					+ '</label><br />' 
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
					'SWIFT CODE: <label style="text-transform: uppercase;">' + UPPER(inter.SwiftCode) + '</label>' 
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