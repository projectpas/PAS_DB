/************************************************************
** File:        [USP_LinkPartToExistingWorksheet]
** Description: "Add to Existing Worksheet" action from the "Create Worksheet"
**              confirmation popup -- links the given maintenance-program or
**              installed-part-details row to an ALREADY-EXISTING WorksheetHeader
**              by stamping its WorksheetNumber onto the row, without creating a
**              new WorksheetHeader. Mirrors the exact back-link UPDATE statements
**              already used by USP_CreateUpdateWorksheetHeader (lines ~334-352)
**              when a brand-new worksheet is created.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    24/07/2026  Amit Ghediya      Created
************************************************************/
CREATE   PROCEDURE [dbo].[USP_LinkPartToExistingWorksheet]
    @WorksheetHeaderId              BIGINT,
    @ProgramId                      BIGINT       = NULL,
    @AircraftInstalledPartDetailsId BIGINT       = NULL,
    @IsFromAircraft                 BIT          = 1,
    @MasterCompanyId                INT,
    @UpdatedBy                      VARCHAR(256)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @WorksheetNum VARCHAR(50);
		DECLARE @AircraftRegistryId BIGINT,@EngineRegistryId BIGINT;

		IF(ISNULL(@ProgramId,0) > 0)
		BEGIN
			 SELECT @IsFromAircraft = [IsFromAircraft], @AircraftRegistryId = [AircraftRegistryId] , @EngineRegistryId = [EngineRegistryId] 
			 FROM dbo.AircraftMaintenanceProgram WITH(NOLOCK) WHERE [ProgramId] = @ProgramId AND [MasterCompanyId] = @MasterCompanyId;
		END
		
		IF(ISNULL(@AircraftInstalledPartDetailsId,0) > 0)
		BEGIN
			 SELECT @IsFromAircraft = [IsFromAircraft], @AircraftRegistryId = [AircraftRegistryId] , @EngineRegistryId = [EngineRegistryId] 
			 FROM dbo.AircraftInstalledPartDetails WITH(NOLOCK) WHERE [AircraftInstalledPartDetailsId] = @AircraftInstalledPartDetailsId AND [MasterCompanyId] = @MasterCompanyId;
		END

        SELECT @WorksheetNum = WorksheetNumber
        FROM [dbo].[WorksheetHeader] WITH (NOLOCK)
        WHERE WorksheetHeaderId = @WorksheetHeaderId
          AND MasterCompanyId = @MasterCompanyId
          AND IsDeleted = 0;

        IF @WorksheetNum IS NULL
        BEGIN
            SELECT 0 AS Status, 'Worksheet not found.' AS Message;
            RETURN;
        END

        UPDATE AMP
        SET
            AMP.WorksheetNumber = @WorksheetNum,
            AMP.UpdatedBy       = @UpdatedBy,
            AMP.UpdatedDate     = GETUTCDATE()
        FROM [dbo].[AircraftMaintenanceProgram] AMP
        WHERE AMP.ProgramId = @ProgramId
          AND AMP.MasterCompanyId = @MasterCompanyId
          AND ISNULL(@ProgramId, 0) > 0;

        UPDATE AIPD
        SET
            AIPD.WorksheetNumber = @WorksheetNum,
            AIPD.UpdatedBy       = @UpdatedBy,
            AIPD.UpdatedDate     = GETUTCDATE()
        FROM [dbo].[AircraftInstalledPartDetails] AIPD
        WHERE AIPD.AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId
          AND AIPD.MasterCompanyId = @MasterCompanyId
          AND ISNULL(@AircraftInstalledPartDetailsId, 0) > 0;

		UPDATE WorksheetHeader
		SET ProgramId = NULLIF(@ProgramId, 0),
		AircraftInstalledPartDetailsId = NULLIF(@AircraftInstalledPartDetailsId, 0),
		IsFromAircraft = @IsFromAircraft,
		AircraftRegistryId = CASE WHEN ISNULL(@AircraftRegistryId,0) > 0 THEN @AircraftRegistryId ELSE @EngineRegistryId END
		WHERE WorksheetHeaderId = @WorksheetHeaderId;

        -- Track which maintenance program / installed part got linked to this worksheet.
        INSERT INTO [dbo].[WorksheetMapping]
            (WorksheetHeaderId, IsFromAircraft,RegistryId, ProgramId, AircraftInstalledPartDetailsId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate)
        SELECT
            @WorksheetHeaderId,
            ISNULL(@IsFromAircraft, 1),
			CASE WHEN ISNULL(@AircraftRegistryId,0) > 0 THEN @AircraftRegistryId ELSE @EngineRegistryId END,
            NULLIF(@ProgramId, 0),
            NULLIF(@AircraftInstalledPartDetailsId, 0),
            @MasterCompanyId,
            @UpdatedBy,
            @UpdatedBy,
            GETUTCDATE(),
            GETUTCDATE()
        WHERE ISNULL(@ProgramId, 0) > 0 OR ISNULL(@AircraftInstalledPartDetailsId, 0) > 0;

        SELECT 1 AS Status, 'Linked successfully' AS Message, @WorksheetNum AS WorksheetNumber;

    END TRY
    BEGIN CATCH

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'USP_LinkPartToExistingWorksheet',
            @ProcedureParameters VARCHAR(3000) =
                '@WorksheetHeaderId = ' + ISNULL(CAST(@WorksheetHeaderId AS VARCHAR(20)), 'NULL')
                + ', @MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), 'NULL'),
            @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected error in the database. Please provide error number %d to the support team.',
            16, 1, @ErrorLogID
        );

        RETURN 1;

    END CATCH;
END;