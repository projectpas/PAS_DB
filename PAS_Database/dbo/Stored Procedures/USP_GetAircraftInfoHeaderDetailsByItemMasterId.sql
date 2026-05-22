/*************************************************************           
 ** File:   [USP_GetAircraftInfoHeaderDetailsByItemMasterId]           
 ** Author: Abhishek Jirawla
 ** Description: This stored procedure is used to Get Aircraft Info by ItemMasterId
 ** Purpose:         
 ** jira id :  PN-16523       
 ** Date:   05/21/2026

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    05/21/2026  Abhishek Jirawla	CREATED	
 
EXEC [dbo].[USP_GetAircraftInfoHeaderDetailsByItemMasterId] 5 ,1  
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetAircraftInfoHeaderDetailsByItemMasterId]
(
	@ItemMasterId BIGINT,
	@MasterCompanyId BIGINT
)
AS
BEGIN 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			SELECT
				AI.AircraftInfoId,
				AI.ACMakeTypeId,
				AI.ACMakeTypeName,
				AI.ACModelId,
				AI.ACModelName,
				AI.ACSubModel,
				AI.ItemMasterId
			FROM dbo.[AircraftInfo] AI WITH(NOLOCK) 
			WHERE AI.ItemMasterId = @ItemMasterId AND AI.MasterCompanyId = @MasterCompanyId 
		END
	COMMIT  TRANSACTION
	END TRY
	BEGIN CATCH
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAircraftInfoHeaderDetailsByItemMasterId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''', @Parameter2 = ' + ISNULL(@MasterCompanyId,'') + ''
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