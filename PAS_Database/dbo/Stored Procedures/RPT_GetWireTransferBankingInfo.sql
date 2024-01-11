/*************************************************************           
 ** File:  [RPT_GetWireTransferBankingInfo]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get Print GetWireTransferBankingInfo Data By ManagementStructId
 ** Purpose:         
 ** Date:   01/10/2024      
          
 ** PARAMETERS: @ManagementStructId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/10/2024  Amit Ghediya    Created
     
-- EXEC RPT_GetWireTransferBankingInfo 1
************************************************************************/
CREATE       PROCEDURE [dbo].[RPT_GetWireTransferBankingInfo] 
	@ManagementStructId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	 SELECT TOP 1
		 UPPER(inter.BankName) AS 'BankName',
		 UPPER(ad.Line1) AS 'Line1',
		 UPPER(ad.City) AS 'City',
		 UPPER(ad.StateOrProvince) + ',' + UPPER(ad.PostalCode) AS 'StateOrProvince',
		 UPPER(ad.PostalCode) AS 'PostalCode',
		 UPPER(co.countries_name) AS 'countries',
		 UPPER(inter.BeneficiaryBank) AS 'AccountName',
		 UPPER(inter.BeneficiaryBankAccount) AS 'Acct',
		 UPPER(inter.ABA) AS 'ABA',
		 UPPER(inter.SwiftCode) AS 'SwiftCode'
		 FROM 
				dbo.EntityStructureSetup ess WITH(NOLOCK)
				JOIN dbo.ManagementStructureLevel msl WITH(NOLOCK) ON ess.Level1Id = msl.ID
				JOIN dbo.LegalEntity le WITH(NOLOCK) ON msl.LegalEntityId = le.LegalEntityId
				LEFT JOIN dbo.LegalEntityInternationalWireBanking lb WITH(NOLOCK) ON le.LegalEntityId = lb.LegalEntityId
				LEFT JOIN dbo.InternationalWirePayment inter WITH(NOLOCK) ON lb.InternationalWirePaymentId = inter.InternationalWirePaymentId
				LEFT JOIN dbo.Address ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
				LEFT JOIN dbo.Countries co WITH(NOLOCK) ON ad.CountryId = co.countries_id
			WHERE 
				ess.IsActive = 1 
				AND ess.IsDeleted = 0 
				AND ess.EntityStructureId = @ManagementStructId

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'RPT_GetWireTransferBankingInfo' 
        ,@ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@ManagementStructId, '') AS varchar(100))			   
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