/*************************************************************             
 ** File:   [GetInternationalWireTransferBankingInfoV2]            
 ** Author:  RAJESH GAMI
 ** Description: This stored procedure is used Get Internationa lWireTransfer Banking Info V2
 ** Purpose:           
 ** Date:  08/Oct/2025       
            
 ** PARAMETERS: @ManagementStructId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
	1    08/Oct/2025	RAJESH GAMI		 CREATED
 EXEC GetInternationalWireTransferBankingInfoV2 38 
************************************************************************/  
CREATE       PROCEDURE [dbo].[GetInternationalWireTransferBankingInfoV2]
    @ManagementStructId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		DECLARE @MasterCompanyId INT;
		DECLARE @MTI_MasterComapnyId BIGINT = 12,@NEO_MasterComapnyId BIGINT = 20;

		SET @MasterCompanyId = (SELECT MasterCompanyId
								FROM [dbo].[EntityStructureSetup] WITH(NOLOCK)
								WHERE EntityStructureId = @ManagementStructId);

		IF @MasterCompanyId = CAST(@MTI_MasterComapnyId AS INT)
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
				LEFT JOIN [dbo].[LegalEntityInternationalWireBankingV2] lockbox WITH(NOLOCK) ON le.LegalEntityId = lockbox.LegalEntityId AND lockbox.IsPrimay = 1
				LEFT JOIN [dbo].[InternationalWirePaymentV2] inter WITH(NOLOCK) ON lockbox.InternationalWirePaymentId = inter.InternationalWirePaymentId
				LEFT JOIN [dbo].[ACH] ach WITH(NOLOCK) ON le.LegalEntityId = ach.LegalEntityId AND ach.IsPrimay = 1
				INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
				INNER JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
			WHERE 
				ISNULL(ess.IsActive,0) = 1
				AND ISNULL(ess.IsDeleted,0) = 0
				AND ess.EntityStructureId = @ManagementStructId;
		END
		ELSE IF @MasterCompanyId = CAST(@NEO_MasterComapnyId AS INT)
		BEGIN
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
				CASE WHEN co.countries_name IS NOT NULL THEN 
					'<label style="text-transform: uppercase;">' + UPPER(co.countries_name)+'Rajesh' + '</label><br />' 
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
				LEFT JOIN [dbo].[LegalEntityInternationalWireBankingV2] lockbox WITH(NOLOCK) ON le.LegalEntityId = lockbox.LegalEntityId AND lockbox.IsPrimay = 1
				LEFT JOIN [dbo].[InternationalWirePaymentV2] inter WITH(NOLOCK) ON lockbox.InternationalWirePaymentId = inter.InternationalWirePaymentId
				INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
				INNER JOIN [dbo].[Countries] co WITH(NOLOCK) ON ad.CountryId = co.countries_id
			WHERE 
				ISNULL(ess.IsActive,0) = 1
				AND ISNULL(ess.IsDeleted,0) = 0
				AND ess.EntityStructureId = @ManagementStructId;
		END
		ELSE
		BEGIN
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
				LEFT JOIN [dbo].[LegalEntityInternationalWireBankingV2] lockbox WITH(NOLOCK) ON le.LegalEntityId = lockbox.LegalEntityId AND lockbox.IsPrimay = 1
				LEFT JOIN [dbo].[InternationalWirePaymentV2] inter WITH(NOLOCK) ON lockbox.InternationalWirePaymentId = inter.InternationalWirePaymentId
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
            , @AdhocComments     VARCHAR(150)    = 'GetInternationalWireTransferBankingInfoV2'     
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