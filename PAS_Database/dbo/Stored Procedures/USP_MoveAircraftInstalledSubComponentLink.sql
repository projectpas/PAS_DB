
/*************************************************************
 ** File:   [USP_MoveAircraftInstalledSubComponentLink]
 ** Description: The stockline of an installed component (AircraftInstalledPartDetails.StockLineId) was replaced outside the Installed Components
                 screen, e.g. the part came back from Repair Order receiving as a new stockline. The Sub Component link moves from the old
                 stockline to the new one (USP_SetAircraftSubComponentLink, whole stockline).
                 It never fails the caller : an error is logged (spLogException) and the receiving / save goes on.
 ** Date:   10/23/2026
 ** Author:  Kishor Makwana
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    23/OCT/2026  Kishor Makwana   [PN-18118] Created
-- EXEC [dbo].[USP_MoveAircraftInstalledSubComponentLink] @AircraftInstalledPartDetailsId = 1, @OldStockLineId = 10, @NewStockLineId = 11, @MasterCompanyId = 1, @UpdatedBy = 'admin'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_MoveAircraftInstalledSubComponentLink]
	@AircraftInstalledPartDetailsId BIGINT,
	@OldStockLineId BIGINT = NULL,
	@NewStockLineId BIGINT,
	@MasterCompanyId INT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @IsFromAircraft BIT = 1, @RegistryId BIGINT = NULL;

		SELECT @IsFromAircraft = ISNULL([IsFromAircraft], 0),
			   @RegistryId = CASE WHEN ISNULL([IsFromAircraft], 0) = 1 THEN [AircraftRegistryId] ELSE [EngineRegistryId] END
		FROM [dbo].[AircraftInstalledPartDetails] WITH (NOLOCK)
		WHERE [AircraftInstalledPartDetailsId] = @AircraftInstalledPartDetailsId;

		IF (ISNULL(@RegistryId, 0) = 0 OR ISNULL(@OldStockLineId, 0) = ISNULL(@NewStockLineId, 0))
			RETURN;

		EXEC [dbo].[USP_SetAircraftSubComponentLink] @StockLineId = @NewStockLineId OUTPUT, @OldStockLineId = @OldStockLineId, @RegistryId = @RegistryId,
			 @IsFromAircraft = @IsFromAircraft, @Quantity = NULL, @MasterCompanyId = @MasterCompanyId, @UpdatedBy = @UpdatedBy;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_MoveAircraftInstalledSubComponentLink'
			, @ProcedureParameters VARCHAR(3000) = '@AircraftInstalledPartDetailsId = ''' + CONVERT(VARCHAR(20), ISNULL(@AircraftInstalledPartDetailsId, 0)) + ''', @OldStockLineId = ''' + CONVERT(VARCHAR(20), ISNULL(@OldStockLineId, 0)) + ''', @NewStockLineId = ''' + CONVERT(VARCHAR(20), ISNULL(@NewStockLineId, 0)) + ''', @MasterCompanyId = ''' + CONVERT(VARCHAR(20), ISNULL(@MasterCompanyId, 0)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		-- not re-raised on purpose : the link must never block receiving
	END CATCH
END