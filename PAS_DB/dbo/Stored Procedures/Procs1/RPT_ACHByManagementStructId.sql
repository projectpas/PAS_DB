/*************************************************************           
 ** File:   [RPT_ACHByManagementStructId]          
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get ACH Details.
 ** Purpose:         
 ** Date:   02/06/2025    
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author          Change Description            
 ** --   --------     -------		  --------------------------------          
    1    02/06/2025   Moin Bloch    Created
	2    16/Jul/2025  Moin Bloch	Added UPPERCASE
	3    10/Sep/2025	RAJESH GAMI		 Rename the #value as mentioned in the PBI (PN-14096)
	4    10/Oct/2025	RAJESH GAMI		 Added code for NEO (PN-14371)
	5    29/Oct/2025	RAJESH GAMI		 Added Swift Code
	6    30/Oct/2025	RAJESH GAMI		 Check the condition with MasterCompanyCode instead of MasterCompanyId
EXEC [dbo].[RPT_ACHByManagementStructId]  38
**************************************************************/
CREATE  PROCEDURE [dbo].[RPT_ACHByManagementStructId] 
@ManagementStructId BIGINT = NULL
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
    BEGIN TRY
      BEGIN
			DECLARE @LegalEntityId BIGINT, @ownerAddress VARCHAR(MAX);
			DECLARE @MasterCompanyId INT,@NEO_MasterComapnyId BIGINT = 20,@NEO_MasterCompanyIdCode  VARCHAR(100)='NEO' , @CompanyCode VARCHAR(100)='';
				SET @MasterCompanyId = (SELECT TOP 1 MasterCompanyId
								FROM [dbo].[EntityStructureSetup] WITH(NOLOCK)
								WHERE EntityStructureId = @ManagementStructId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1 );
			SET @CompanyCode = (SELECT TOP 1 MasterCompanyCode FROM dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1 )
			
			SELECT TOP 1 @LegalENtityId = LE.LegalEntityId, @ownerAddress = 

				CASE WHEN ad.Line1 IS NOT NULL THEN 
					'<label style="text-transform: uppercase;">' + UPPER(ad.Line1) + '</label><br />' 
				ELSE '' END +
				CASE WHEN ad.City IS NOT NULL THEN 
					'<label style="text-transform: uppercase;">' + UPPER(ad.City) +  ', '+	CASE WHEN ad.StateOrProvince IS NOT NULL THEN 
					 + UPPER(ad.StateOrProvince) 
				ELSE '' END + ', ' +CASE WHEN ad.PostalCode IS NOT NULL THEN UPPER(ad.PostalCode) ELSE '' END + '</label>' 
				ELSE '' END +
				'<br />' 

								  FROM  [dbo].[EntityStructureSetup] ES WITH (NOLOCK)
								  JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
								  JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
								  	INNER JOIN [dbo].[Address] ad WITH(NOLOCK) ON le.AddressId = ad.AddressId
								  WHERE ES.EntityStructureId = @ManagementStructId;
								  PRINT  @ownerAddress

			IF @CompanyCode = @NEO_MasterCompanyIdCode
			BEGIN
						SELECT  
						
						'<label style="text-transform:uppercase;"> ' + UPPER(ISNULL(ach.BankName, '')) + ' </label><br/>' +
						@ownerAddress +
						'<label style="text-transform:uppercase;"> ' + UPPER(ISNULL(ach.BeneficiaryBankName, '')) + ' </label><br/>' +
						'ACCT# <label style="text-transform:uppercase;">' + UPPER(ISNULL(ach.AccountNumber, '')) + '</label><br/>' +
						'ABA# <label style="text-transform:uppercase;">' + UPPER(ISNULL(ach.ABA, '')) + '</label><br/>'
						+'SWIFT CODE : <label style="text-transform:uppercase;">' + UPPER(ISNULL(SwiftCode, '')) + '</label><br/>' 
						AS ACHDetail
					FROM [dbo].[ACH] ach WITH (NOLOCK)
					WHERE LegalEntityId = @LegalEntityId 
					  AND IsPrimay = 1;
			END
			ELSE
			BEGIN
					SELECT  '<label style="text-transform:uppercase;"> ' + UPPER(ISNULL(BankName, '')) + ' </label><br/>' +
					'<label style="text-transform:uppercase;"> ' + UPPER(ISNULL(IntermediateBankName, '')) + ' </label><br/>' +
					'ACCT# <label style="text-transform:uppercase;">' + UPPER(ISNULL(AccountNumber, '')) + '</label><br/>' +
					'ROUTING# <label style="text-transform:uppercase;">' + UPPER(ISNULL(ABA, '')) + '</label><br/>'
					+'SWIFT CODE : <label style="text-transform:uppercase;">' + UPPER(ISNULL(SwiftCode, '')) + '</label><br/>' 
					AS ACHDetail
				FROM [dbo].[ACH] WITH (NOLOCK)
				WHERE LegalEntityId = @LegalEntityId 
				  AND IsPrimay = 1;
			END

	  END
	END TRY
    BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_ACHByManagementStructId'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@ManagementStructId, '') + ''
		,@ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END