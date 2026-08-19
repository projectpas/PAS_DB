/*************************************************************
 ** File:   [USP_CreateUpdateLeasePart]
 ** Description: This stored procedure is used to Create/Update a record in [LeasePart].
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    07/08/2026     Amit Ghediya            Created
    2    18/08/2026     Amit Ghediya            Added Notes

exec USP_CreateUpdateLeasePart
@LeasePartId=0,@LeaseHeaderId=1,@ItemMasterId=1,@ConditionId=1,@QtyRequested=1,@QtyOrder=1,@AircraftSectionId=NULL,
@StartDate=NULL,@EndDate=NULL,@POId=NULL,@PONumber=NULL,@StatusId=1,
@MasterCompanyId=1,@CreatedBy='',@UpdatedBy='',@Notes=NULL
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateUpdateLeasePart]
	@LeasePartId BIGINT = 0,
	@LeaseHeaderId BIGINT,
	@ItemMasterId BIGINT,
	@ConditionId BIGINT,
	@QtyOrder INT,
	@AircraftSectionId BIGINT = NULL,
	@StartDate DATE = NULL,
	@EndDate DATE = NULL,
	@POId BIGINT = NULL,
	@PONumber VARCHAR(256) = NULL,
	@StatusId INT = 1,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256),
	@UpdatedBy VARCHAR(256),
	@Notes NVARCHAR(MAX) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @PN NVARCHAR(100), @PNDescription NVARCHAR(500), @UOM NVARCHAR(50), @OEMPMA NVARCHAR(100);

		SELECT
			@PN = IM.partnumber,
			@PNDescription = IM.PartDescription,
			@UOM = IM.StockUnitOfMeasure,
			@OEMPMA = CASE WHEN IM.IsPma = 1 THEN 'PMA' WHEN IM.IsOEM = 1 THEN 'OEM' ELSE '' END
		FROM [dbo].[ItemMaster] IM WITH (NOLOCK)
		WHERE IM.ItemMasterId = @ItemMasterId;

		IF (ISNULL(@LeasePartId, 0) > 0)
		BEGIN
			UPDATE [dbo].[LeasePart]
			SET
				ItemMasterId      = @ItemMasterId,
				PN                = @PN,
				PNDescription     = @PNDescription,
				UOM               = @UOM,
				QtyOrder          = @QtyOrder,
				ConditionId       = @ConditionId,
				AircraftSectionId = @AircraftSectionId,
				StartDate         = @StartDate,
				EndDate           = @EndDate,
				POId              = @POId,
				PONumber          = @PONumber,
				StatusId          = @StatusId,
				Notes             = @Notes,
				UpdatedBy         = @UpdatedBy,
				UpdatedDate       = GETUTCDATE()
			WHERE LeasePartId = @LeasePartId;
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[LeasePart]
			(
				LeaseHeaderId, ItemMasterId, PN, PNDescription, UOM, QtyOrder, QtyReserved,
				ConditionId, AircraftSectionId, StartDate, EndDate, POId, PONumber, StatusId, Notes,
				MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
			)
			VALUES
			(
				@LeaseHeaderId, @ItemMasterId, @PN, @PNDescription, @UOM, @QtyOrder, 0,
				@ConditionId, @AircraftSectionId, @StartDate, @EndDate, @POId, @PONumber, @StatusId, @Notes,
				@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0
			);

			SET @LeasePartId = SCOPE_IDENTITY();
		END

		SELECT
			LP.LeasePartId,
			LP.LeaseHeaderId,
			LP.ItemMasterId,
			LP.PN,
			LP.PNDescription,
			LP.UOM,
			LP.QtyOrder,
			LP.QtyReserved,
			LP.ConditionId,
			C.Description AS ConditionDescription,
			LP.AircraftSectionId,
			ACS.Section AS AcSection,
			LP.StartDate,
			LP.EndDate,
			LP.POId,
			LP.PONumber,
			LP.StatusId,
			LP.Notes,
			LP.MasterCompanyId,
			LP.CreatedBy,
			LP.UpdatedBy,
			LP.CreatedDate,
			LP.UpdatedDate,
			LP.IsActive,
			LP.IsDeleted
		FROM [dbo].[LeasePart] LP WITH (NOLOCK)
		LEFT JOIN [dbo].[Condition] C WITH (NOLOCK) ON C.ConditionId = LP.ConditionId
		LEFT JOIN [dbo].[AircraftSection] ACS WITH (NOLOCK) ON ACS.AircraftSectionId = LP.AircraftSectionId
		WHERE LP.LeasePartId = @LeasePartId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_CreateUpdateLeasePart]',
            @ProcedureParameters varchar(3000) = '@LeasePartId = ''' + CAST(ISNULL(@LeasePartId, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END