/*************************************************************
** Author:  Amit Ghediya
** Create date: 07/10/2026
** Change date: 07/13/2026 - Consolidated ComponentSerial + Exclusion tables
**              into a single AircraftEffectivitySerialDetail table (IsAffect flag).
** Description: Upsert save for a single Aircraft Effectivity rule's
**              "affects" (Individual/Range) and "except" (exclusion) serial
**              entries, for both Aircraft and Component. The caller always
**              submits the complete current state, each row optionally carrying its own
**              AircraftEffectivitySerialDetailId.

** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    14/07/2026  Amit Ghediya      Created
** 2    14/07/2026  Amit Ghediya      Update for AC/Com Serial num when any update
** 3    16/07/2026  Amit Ghediya      update sernum if only added one ser number in affect
************************************************************/
Create   PROCEDURE [dbo].[USP_SaveAircraftEffectivitySerialDetails]
    @AircraftEffectivityId  BIGINT,
    @AircraftPublicationId  BIGINT,
    @ACPSectionId           BIGINT NULL,
    @MakeTypeId             BIGINT,
    @AircraftModelId        BIGINT NULL,
    @AircraftSubModel       VARCHAR(100) = NULL,
    @ItemMasterId           BIGINT,
    @MasterCompanyId        INT,
    @CreatedBy              VARCHAR(256),
    @UpdatedBy              VARCHAR(256),
    @tbl_SerialDetail       dbo.AircraftEffectivitySerialDetailTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- =========================================================
        -- VALIDATION (runs first, no mutation yet)
        -- =========================================================
        -- Aircraft: match key is ONLY (AircraftPublicationId, MakeTypeId, AircraftModelId, Serial)
        -- -- AircraftSubModel/ItemMasterId/Notes are irrelevant to the match. Any existing active
        -- row with the same serial value belonging to a DIFFERENT rule (AircraftEffectivityId) is
        -- a conflict, regardless of whether either side is Affect or Except. This rule's own
        -- existing rows (same AircraftEffectivityId) are excluded so re-saving/editing it doesn't
        -- conflict with itself.
        -- Component: same idea, keyed by (AircraftPublicationId, MakeTypeId, AircraftModelId,
        -- ComponentSerial).

        DECLARE @ConflictSerial VARCHAR(100);

        SELECT TOP 1 @ConflictSerial = T.FromSerial
        FROM @tbl_SerialDetail T
        WHERE T.IsAircraftSerialNum = 1
          AND ISNULL(T.FromSerial, '') <> ''
          AND (
                EXISTS (
                    SELECT 1 FROM dbo.AircraftEffectivitySerialDetail AESD WITH (NOLOCK)
                    WHERE AESD.AircraftPublicationId = @AircraftPublicationId
                      AND AESD.MakeTypeId            = @MakeTypeId
                      AND AESD.AircraftModelId       = @AircraftModelId
                      AND AESD.IsAircraftSerialNum   = 1
                      AND AESD.FromSerial            = T.FromSerial
                      AND AESD.IsDeleted             = 0
                      AND AESD.AircraftEffectivityId <> ISNULL(@AircraftEffectivityId, 0)
                )
                OR EXISTS (
                    SELECT 1 FROM @tbl_SerialDetail T2
                    WHERE T2.IsAircraftSerialNum = 1
                      AND T2.IsAffect           <> T.IsAffect
                      AND T2.FromSerial          = T.FromSerial
                )
              );

        IF @ConflictSerial IS NOT NULL
        BEGIN
            SELECT 0 AS Status,
                   'Aircraft Serial Number "' + @ConflictSerial + '" is already used for this AC Type/Model. Please update the existing entry instead.' AS Message;
            RETURN;
        END

        SELECT TOP 1 @ConflictSerial = T.FromSerial
        FROM @tbl_SerialDetail T
        WHERE T.IsAircraftSerialNum = 0
          AND ISNULL(T.FromSerial, '') <> ''
          AND (
                EXISTS (
                    SELECT 1 FROM dbo.AircraftEffectivitySerialDetail AESD WITH (NOLOCK)
                    WHERE AESD.AircraftPublicationId = @AircraftPublicationId
                      AND AESD.MakeTypeId            = @MakeTypeId
                      AND AESD.AircraftModelId       = @AircraftModelId
                      AND AESD.IsAircraftSerialNum   = 0
                      AND AESD.FromSerial            = T.FromSerial
                      AND AESD.IsDeleted             = 0
                      AND AESD.AircraftEffectivityId <> ISNULL(@AircraftEffectivityId, 0)
                )
                OR EXISTS (
                    SELECT 1 FROM @tbl_SerialDetail T2
                    WHERE T2.IsAircraftSerialNum = 0
                      AND T2.IsAffect           <> T.IsAffect
                      AND T2.FromSerial          = T.FromSerial
                )
              );

        IF @ConflictSerial IS NOT NULL
        BEGIN
            SELECT 0 AS Status,
                   'Component Serial Number "' + @ConflictSerial + '" is already used for this AC Type/Model. Please update the existing entry instead.' AS Message;
            RETURN;
        END

        -- =========================================================
        -- VALIDATION PASSED -- now safe to mutate
        -- =========================================================

        BEGIN TRANSACTION;

        -- SOFT-DELETE ROWS FOR THIS RULE THAT ARE NO LONGER IN THE SUBMITTED SET
        -- (only rows the caller knows about via an id can be "kept"; a row with no matching
        -- submitted id was removed by the user in the picker)

        UPDATE AESD
        SET IsDeleted = 1, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE()
        FROM dbo.AircraftEffectivitySerialDetail AESD
        WHERE AESD.AircraftEffectivityId = @AircraftEffectivityId
          AND AESD.IsDeleted             = 0
          AND NOT EXISTS (
              SELECT 1 FROM @tbl_SerialDetail T
              WHERE T.AircraftEffectivitySerialDetailId = AESD.AircraftEffectivitySerialDetailId
          );

		----Update legacy single-serial reference fields: exactly one AFFECT entry -> that value,
		----zero or 2+ AFFECT entries -> blank (frontend then displays "All"). Only AFFECT rows
		----count -- Except (exclusion) entries must never leak into these legacy fields.
		DECLARE @AcAffectCount INT, @AcSingleSerial VARCHAR(100);
		DECLARE @ComAffectCount INT, @ComSingleSerial VARCHAR(100);

		SELECT @AcAffectCount = COUNT(T.AircraftEffectivitySerialDetailId), @AcSingleSerial = MIN(T.FromSerial)
		FROM @tbl_SerialDetail T
		WHERE T.IsAircraftSerialNum = 1
		  AND T.IsAffect            = 1
		  AND ISNULL(T.FromSerial, '') <> '';

		SELECT @ComAffectCount = COUNT(T.AircraftEffectivitySerialDetailId), @ComSingleSerial = MIN(T.FromSerial)
		FROM @tbl_SerialDetail T
		WHERE T.IsAircraftSerialNum = 0
		  AND T.IsAffect            = 1
		  AND ISNULL(T.FromSerial, '') <> '';

		UPDATE DBO.AircraftEffectivity
		SET SerialNum          = CASE WHEN ISNULL(@AcAffectCount, 0)  = 1 THEN @AcSingleSerial  ELSE NULL END,
		    ComponentSerialNum = CASE WHEN ISNULL(@ComAffectCount, 0) = 1 THEN @ComSingleSerial ELSE NULL END
		WHERE AircraftEffectivityId = @AircraftEffectivityId;

        -- UPDATE ROWS THE CALLER SUBMITTED WITH A REAL (EXISTING) ID

        UPDATE AESD
        SET
            IsAircraftSerialNum = T.IsAircraftSerialNum,
            IsAffect            = T.IsAffect,
            SerialType          = T.SerialType,
            FromSerial          = T.FromSerial,
            ToSerial            = T.ToSerial,
            UpdatedBy           = @UpdatedBy,
            UpdatedDate         = GETUTCDATE()
        FROM dbo.AircraftEffectivitySerialDetail AESD
        INNER JOIN @tbl_SerialDetail T
            ON AESD.AircraftEffectivitySerialDetailId = T.AircraftEffectivitySerialDetailId
        WHERE AESD.AircraftEffectivityId       = @AircraftEffectivityId
          AND ISNULL(T.AircraftEffectivitySerialDetailId, 0) > 0
          AND ISNULL(T.FromSerial, '') <> '';

        -- INSERT ROWS THE CALLER SUBMITTED WITH NO ID (NEW ENTRIES)

        INSERT INTO dbo.AircraftEffectivitySerialDetail
        (
            AircraftEffectivityId, AircraftPublicationId, ACPSectionId, MakeTypeId, AircraftModelId, AircraftSubModel,
            ItemMasterId, IsAircraftSerialNum, IsAffect, SerialType, FromSerial, ToSerial,
            MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsDeleted
        )
        SELECT
            @AircraftEffectivityId, @AircraftPublicationId, @ACPSectionId, @MakeTypeId, @AircraftModelId, @AircraftSubModel,
            CASE WHEN T.IsAircraftSerialNum = 0 THEN @ItemMasterId ELSE NULL END,
            T.IsAircraftSerialNum, T.IsAffect, T.SerialType, T.FromSerial, T.ToSerial,
            @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 0
        FROM @tbl_SerialDetail T
        WHERE ISNULL(T.AircraftEffectivitySerialDetailId, 0) = 0
          AND ISNULL(T.FromSerial, '') <> '';

        COMMIT TRANSACTION;

        SELECT 1 AS Status, 'Saved successfully' AS Message;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE
            @ErrorLogID      INT,
            @DatabaseName    VARCHAR(100) = DB_NAME(),
            @AdhocComments   VARCHAR(150) = 'USP_SaveAircraftEffectivitySerialDetails',
            @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName    = @DatabaseName,
            @AdhocComments   = @AdhocComments,
            @ApplicationName = @ApplicationName,
            @ErrorLogID      = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );

        RETURN(1);

    END CATCH

END