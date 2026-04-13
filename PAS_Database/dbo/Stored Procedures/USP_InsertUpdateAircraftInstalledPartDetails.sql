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
 **  2   04-13-2026   Amit Ghediya      Added for Quantity (PN-16028)
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
	@PositionCodeId BIGINT,
    @PositionCode VARCHAR(256) = NULL,
    @Hours DECIMAL(18,2) = NULL,
    @Minutes DECIMAL(18,2) = NULL,
    @FlightHours DECIMAL(18,2) = NULL,
    @Cycles DECIMAL(18,2) = NULL,
    @Landings BIGINT = NULL,
    @EngineStarts BIGINT = NULL,
    @Memo NVARCHAR(MAX) = NULL,
    @MasterCompanyId INT,
	@UpdatedBy VARCHAR(50) = NULL,
	@StockLineId BIGINT = NULL,
	@Quantity DECIMAL(18,6) = NULL
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION;

		DECLARE @AircraftPartDetailsId BIGINT = 0,
				@ConditionId BIGINT = 0,
				@OldStockLineId BIGINT = 0;

		-- CHECK IF RECORD EXISTS
		IF EXISTS (
			SELECT 1 
			FROM DBO.AircraftInstalledPartDetails WITH(NOLOCK)
			WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId
		)
		BEGIN
			-- Remove from stockline table
			IF(ISNULL(@StockLineId,0) = 0)
			BEGIN
				 SELECT @OldStockLineId = [StockLineId] FROM DBO.AircraftInstalledPartDetails WITH(NOLOCK) WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId;

				 UPDATE [dbo].[Stockline] SET [AircraftInstalledPartDetailsId] = 0 WHERE [StockLineId] = @OldStockLineId;
			END

			-- UPDATE
			UPDATE DBO.AircraftInstalledPartDetails
			SET
				ATAChapterId = @ATAChapterId,
				PartNumber = @PartNumber,
				PartDescription = @PartDescription,
				--CASE WHEN ISNULL(@StockLineId,0) > 0 THEN IsLLP = @IsLLP ELSE 0 END,
				IsLLP = CASE WHEN ISNULL(@StockLineId,0) > 0 THEN @IsLLP ELSE 0 END,
				IsSerialized = CASE WHEN ISNULL(@StockLineId,0) > 0 THEN @IsSerialized ELSE 0 END,
				--IsSerialized = @IsSerialized,
				DateInstalled = @DateInstalled,
				PositionCodeId = @PositionCodeId,
				PositionCode = @PositionCode,
				Quantity = @Quantity,
				[StockLineId] = @StockLineId,
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
			
			--Update stockline for part
			IF(ISNULL(@StockLineId,0) > 0)
			BEGIN
				 UPDATE [dbo].[Stockline] SET [AircraftInstalledPartDetailsId] = @AircraftInstalledPartDetailsId WHERE [StockLineId] = @StockLineId;

				 SELECT @ConditionId = [ConditionId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

				 UPDATE [dbo].[AircraftInstalledPartDetails] SET [StockLineId] = @StockLineId,[ConditionId] = @ConditionId WHERE [AircraftInstalledPartDetailsId] = @AircraftInstalledPartDetailsId;
			END
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
				PositionCodeId,
				PositionCode,
				Quantity,
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
				@PositionCodeId,
				@PositionCode,
				@Quantity,
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

			SELECT @AircraftPartDetailsId = SCOPE_IDENTITY() 

			--Add stockline for part
			IF(ISNULL(@StockLineId,0) > 0)
			BEGIN
				 UPDATE [dbo].[Stockline] SET [AircraftInstalledPartDetailsId] = @AircraftPartDetailsId WHERE [StockLineId] = @StockLineId;

				 SELECT @ConditionId = [ConditionId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

				 UPDATE [dbo].[AircraftInstalledPartDetails] SET [StockLineId] = @StockLineId,[ConditionId] = @ConditionId WHERE [AircraftInstalledPartDetailsId] = @AircraftPartDetailsId;
			END
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