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

EXEC [dbo].[RPT_ACHByManagementStructId]  1
**************************************************************/
CREATE      PROCEDURE [dbo].[RPT_ACHByManagementStructId] 
@ManagementStructId BIGINT = NULL
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
    BEGIN TRY
      BEGIN
			DECLARE @LegalEntityId BIGINT;

			SET @LegalENtityId = (SELECT LE.LegalEntityId
								  FROM  [dbo].[EntityStructureSetup] ES WITH (NOLOCK)
								  JOIN [dbo].[ManagementStructureLevel] MSL ON ES.Level1Id = MSL.ID
								  JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId  
								  WHERE ES.EntityStructureId = @ManagementStructId);
			SELECT 
			'<label style="text-transform:uppercase;"> ' + UPPER(ISNULL(BankName, '')) + ' </label><br/>' +
			'<label style="text-transform:uppercase;"> ' + UPPER(ISNULL(IntermediateBankName, '')) + ' </label><br/>' +
			'ACCOUNT NUMBER: <label style="text-transform:uppercase;">' + UPPER(ISNULL(AccountNumber, '')) + '</label><br/>' +
			'ROUTING NUMBER: <label style="text-transform:uppercase;">' + UPPER(ISNULL(ABA, '')) + '</label><br/>' +
			'SWIFT CODE : <label style="text-transform:uppercase;">' + UPPER(ISNULL(SwiftCode, '')) + '</label><br/>' 
			AS ACHDetail
		FROM [dbo].[ACH] WITH (NOLOCK)
		WHERE LegalEntityId = @LegalEntityId 
		  AND IsPrimay = 1;

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