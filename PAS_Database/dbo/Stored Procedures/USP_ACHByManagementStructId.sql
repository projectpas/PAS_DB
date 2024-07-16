/*************************************************************           
 ** File:   [USP_ACHByManagementStructId]          
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to get ACH Details.
 ** Purpose:         
 ** Date:   16/07/2024    
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author          Change Description            
 ** --   --------     -------		  --------------------------------          
    1    16/07/2024   Amit Ghediya    Created

EXEC [dbo].[USP_ACHByManagementStructId]  10
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ACHByManagementStructId] 
(
	@ManagementStructId BIGINT = NULL
)
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
				UPPER(BankName) AS 'BankName',
				UPPER(IntermediateBankName) AS 'IntermediateBankName',
				UPPER(AccountNumber) AS 'AccountNumber',
				UPPER(ABA) AS 'ABA',
				UPPER(SwiftCode) AS 'SwiftCode'
			FROM [dbo].[ACH] WITH (NOLOCK)
			WHERE LegalENtityId = @LegalENtityId 
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