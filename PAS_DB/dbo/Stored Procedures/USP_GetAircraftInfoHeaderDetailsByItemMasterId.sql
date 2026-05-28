/*************************************************************           
 ** File:   [USP_GetAircraftInfoHeaderDetailsByItemMasterId]           
 ** Author: Abhishek Jirawla
 ** Description: This stored procedure is used to Get Aircraft Info by ItemMasterId
 ** Purpose:         
 ** jira id :  PN-16523       
 ** Date:   05/21/2026
 ***************************************************************/     
CREATE PROCEDURE [dbo].[USP_GetAircraftInfoHeaderDetailsByItemMasterId]
(
	@ItemMasterId BIGINT,
	@MasterCompanyId BIGINT
)
AS
BEGIN 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION;

		SELECT
			AI.AircraftInfoId,
			AI.ACMakeTypeId,
			AI.ACMakeTypeName,
			AI.ACModelId,
			AI.ACModelName,
			AI.ACSubModel,
			AI.ItemMasterId
		FROM dbo.[AircraftInfo] AI WITH(NOLOCK) 
		WHERE AI.ItemMasterId = @ItemMasterId 
			AND AI.MasterCompanyId = @MasterCompanyId;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorLogID INT,
				@DatabaseName VARCHAR(100) = DB_NAME(),
				@AdhocComments VARCHAR(150) = 'USP_GetAircraftInfoHeaderDetailsByItemMasterId',
				@ProcedureParameters VARCHAR(3000),
				@ApplicationName VARCHAR(100) = 'PAS';

		SET @ProcedureParameters =
			'@ItemMasterId = ' + CAST(ISNULL(@ItemMasterId,0) AS VARCHAR(20))
			+ ', @MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId,0) AS VARCHAR(20));

		EXEC spLogException 
			 @DatabaseName = @DatabaseName,
			 @AdhocComments = @AdhocComments,
			 @ProcedureParameters = @ProcedureParameters,
			 @ApplicationName = @ApplicationName,
			 @ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
			'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
			16,
			1,
			@ErrorLogID
		);

		RETURN(1);
	END CATCH
END