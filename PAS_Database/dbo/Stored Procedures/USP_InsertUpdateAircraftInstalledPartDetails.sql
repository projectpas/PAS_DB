/*************************************************************           
 ** File:        [USP_InsertUpdateAircraftInstalledPartDetails]           
 ** Author:      Amit Ghediya
 ** Description: This stored procedure is used to Add and Update AircraftInstalledPartDetails
 ** Date:        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author             Change Description            
 ** --   ----------  -----------------  -----------------------------         
 **  1   03-27-2026   Amit Ghediya      Created
 ************************************************************************/
CREATE   PROCEDURE [dbo].[USP_InsertUpdateAircraftInstalledPartDetails]
(
	@AircraftInstalledPartDetailsId BIGINT,
    @AircraftRegistryId BIGINT,
    @ATAChapterId BIGINT,
    @ItemMasterId BIGINT,
    @PartNumber VARCHAR(50) = NULL,
    @PartDescription NVARCHAR(MAX) = NULL,
    @IsLLP BIT,
	@IsSerialized BIT,
    @SerialNumber VARCHAR(100) = NULL,
    @DateInstalled DATETIME2(7) = NULL,
    @PositionCode VARCHAR(256) = NULL,
    @Hours DECIMAL(18,2) = NULL,
    @Minutes DECIMAL(18,2) = NULL,
    @FlightHours DECIMAL(18,2) = NULL,
    @Cycles DECIMAL(18,2) = NULL,
    @Landings BIGINT = NULL,
    @EngineStarts BIGINT = NULL,
    @Memo NVARCHAR(MAX) = NULL,
    @MasterCompanyId INT,
	@UpdatedBy VARCHAR(50) = NULL
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION;

		-- CHECK IF RECORD EXISTS
		IF EXISTS (
			SELECT 1 
			FROM AircraftInstalledPartDetails WITH(NOLOCK)
			WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId
		)
		BEGIN
			-- UPDATE
			UPDATE AircraftInstalledPartDetails
			SET
				ATAChapterId = @ATAChapterId,
				PartNumber = @PartNumber,
				PartDescription = @PartDescription,
				IsLLP = @IsLLP,
				DateInstalled = @DateInstalled,
				PositionCode = @PositionCode,
				[Hours] = @Hours,
				[Minutes] = @Minutes,
				FlightHours = @FlightHours,
				Cycles = @Cycles,
				Landings = @Landings,
				EngineStarts = @EngineStarts,
				Memo = @Memo,
				MasterCompanyId = @MasterCompanyId,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
			WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId;
		END
		ELSE
		BEGIN
			-- INSERT
			INSERT INTO AircraftInstalledPartDetails
			(
				AircraftRegistryId,
				ATAChapterId,
				ItemMasterId,
				PartNumber,
				PartDescription,
				IsLLP,
				IsSerialized,
				SerialNumber,
				DateInstalled,
				PositionCode,
				[Hours],
				[Minutes],
				FlightHours,
				Cycles,
				Landings,
				EngineStarts,
				Memo,
				MasterCompanyId,
				CreatedBy,
				UpdatedBy,
				CreatedDate,
				UpdatedDate,
				IsActive,
				IsDeleted
			)
			VALUES
			(
				@AircraftRegistryId,
				@ATAChapterId,
				@ItemMasterId,
				@PartNumber,
				@PartDescription,
				@IsLLP,
				@IsSerialized,
				@SerialNumber,
				@DateInstalled,
				@PositionCode,
				@Hours,
				@Minutes,
				@FlightHours,
				@Cycles,
				@Landings,
				@EngineStarts,
				@Memo,
				@MasterCompanyId,
				@UpdatedBy,
				@UpdatedBy,
				GETUTCDATE(),
				GETUTCDATE(),
				1,
				0
			);
		END
		COMMIT TRANSACTION;

		SELECT AircraftInstalledPartDetailsId AS Result FROM DBO.AircraftInstalledPartDetails WITH(NOLOCK)
	END TRY
BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				, @AdhocComments     VARCHAR(150)    = '[dbo].[USP_InsertUpdateAircraftInstalledPartDetails] ' 
				, @ProcedureParameters VARCHAR(3000)  = ''
				, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
					exec spLogException 
							  @DatabaseName         = @DatabaseName
							, @AdhocComments        = @AdhocComments
							, @ProcedureParameters  = @ProcedureParameters
							, @ApplicationName      =  @ApplicationName
							, @ErrorLogID           = @ErrorLogID OUTPUT ;
					RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				RETURN(1);
END CATCH
END