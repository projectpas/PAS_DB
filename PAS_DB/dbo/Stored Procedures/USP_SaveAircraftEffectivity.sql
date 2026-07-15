/*************************************************************
** Author:  Amit Ghediya
** Create date: 05/04/2026
** Description: Save Aircraft Effectivity
**************************************************************
** Change History
**************************************************************
** PR   Date        Author          Change Description
** --   --------    -------         --------------------------------
** 1    05/05/2026  Amit Ghediya    Created
** 2    15/05/2026  Amit Ghediya    Added ToSerialNumber/FromSerialNumber
** 3    20/05/2026  Amit Ghediya    Removed Part Validation
** 4    29/05/2026  Amit Ghediya    Fixed Serial Range Insert
** 5    02/06/2026  Amit Ghediya    Fixed alphanumeric serial (no dash) range insert e.g. AC454245 -> AC454247 with allow duplicate for other pub.
** 6    06/07/2026  Amit Ghediya    Added AcSection,ComponentSerialNum,ComponentToSerialNum [PN-17117]
** 7    13/07/2026  Amit Ghediya    Check for duplication Ser Num [PN-17223]
**************************************************************/

CREATE      PROCEDURE [dbo].[USP_SaveAircraftEffectivity]
    @tbl_AircraftEffectivityType dbo.AircraftEffectivityTableType READONLY,
    @tbl_SerialDetail            dbo.AircraftEffectivitySerialDetailTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        DECLARE @Id BIGINT;

        DECLARE
            @AircraftPublicationId BIGINT,
            @MakeTypeId            BIGINT,
            @AircraftModelId       BIGINT,
            @ThisAircraftEffectivityId BIGINT,
            @ConflictSerial        VARCHAR(100);

        SELECT TOP 1
            @AircraftPublicationId     = T.AircraftPublicationsId,
            @MakeTypeId                = T.MakeTypeId,
            @AircraftModelId           = T.AircraftModelId,
            @ThisAircraftEffectivityId = ISNULL(T.AircraftEffectivityId, 0)
        FROM @tbl_AircraftEffectivityType T;

        -- =========================================================
        -- SERIAL NUMBER VALIDATION (runs first, no mutation yet)
        -- =========================================================
        -- Same match rule as USP_SaveAircraftEffectivitySerialDetails: a serial is a conflict
        -- purely on (AircraftPublicationId, MakeTypeId, AircraftModelId, Serial) for Aircraft /
        -- (..., ComponentSerial) for Component, regardless of Affect/Except combination.

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
                      AND AESD.AircraftEffectivityId <> @ThisAircraftEffectivityId
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
                      AND AESD.AircraftEffectivityId <> @ThisAircraftEffectivityId
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

        -- =========================================================
        -- UPDATE
        -- =========================================================

        UPDATE AE
        SET
            AE.AircraftPublicationId = T.AircraftPublicationsId,
			AE.ACPSectionId          = T.ACPSectionId,
            AE.MakeTypeId            = T.MakeTypeId,
            AE.AircraftModelId       = T.AircraftModelId,
            AE.AircraftSubModel      = T.AircraftSubModel,
            AE.SerialNum             = T.FromSerialNumber,
            AE.ItemMasterId          = T.ItemMasterId,
            AE.PartNumber            = T.PartNumber,
            AE.PartDescription       = T.PartDescription,
			AE.ComponentSerialNum    = T.ComponentSerialNum,
			AE.ComponentToSerialNum  = T.ComponentToSerialNum,
            AE.Notes                 = T.Notes,
            AE.UpdatedBy             = T.UpdatedBy,
            AE.UpdatedDate           = GETUTCDATE()
        FROM dbo.AircraftEffectivity AE
        INNER JOIN @tbl_AircraftEffectivityType T
            ON AE.AircraftEffectivityId = T.AircraftEffectivityId
        WHERE T.AircraftEffectivityId > 0;

        -- =========================================================
        -- INSERT VARIABLES
        -- =========================================================

        DECLARE
            @FromSerial    VARCHAR(100),
            @ToSerial      VARCHAR(100),
            @Prefix        VARCHAR(100),
            @FromPrefix    VARCHAR(100),
            @ToPrefix      VARCHAR(100),
            @FromNo        INT,
            @ToNo          INT,
            @CurrentNo     INT,
            @PaddingLength INT,
            @NumericStart  INT;   -- position where numeric suffix starts

        SELECT TOP 1
            @FromSerial = T.FromSerialNumber,
            @ToSerial   = T.ToSerialNumber
        FROM @tbl_AircraftEffectivityType T;

        -- =========================================================
        -- SINGLE INSERT  (no ToSerial provided)
        -- =========================================================

        IF ISNULL(@ToSerial, '') = ''
        BEGIN

            INSERT INTO dbo.AircraftEffectivity
            (
                AircraftPublicationId, ACPSectionId, MakeTypeId, AircraftModelId, AircraftSubModel,
                SerialNum, ItemMasterId, PartNumber, PartDescription, ComponentSerialNum, ComponentToSerialNum, Notes,
                MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
                IsActive, IsDeleted
            )
            SELECT
                T.AircraftPublicationsId, T.ACPSectionId, T.MakeTypeId, T.AircraftModelId, T.AircraftSubModel,
                @FromSerial, T.ItemMasterId, T.PartNumber, T.PartDescription, ComponentSerialNum, ComponentToSerialNum, T.Notes,
                T.MasterCompanyId, T.CreatedBy, T.UpdatedBy,
                GETUTCDATE(), GETUTCDATE(), 1, 0
            FROM @tbl_AircraftEffectivityType T
            WHERE ISNULL(T.AircraftEffectivityId, 0) = 0;

            SET @Id = SCOPE_IDENTITY();

        END
        ELSE
        BEGIN

            -- =====================================================
            -- RANGE INSERT — determine serial format
            -- Three supported formats:
            --   A) Dash-separated  : AB-001  -> AB-003
            --   B) Alphanumeric    : AC454245 -> AC454247
            --   C) Pure numeric    : 10001    -> 10003
            -- =====================================================

            -- ── FORMAT A: dash-separated (original logic) ────────
            IF CHARINDEX('-', @FromSerial) > 0
               AND CHARINDEX('-', @ToSerial) > 0
            BEGIN

                SET @FromPrefix = LEFT(@FromSerial, LEN(@FromSerial) - CHARINDEX('-', REVERSE(@FromSerial)));
                SET @ToPrefix   = LEFT(@ToSerial,   LEN(@ToSerial)   - CHARINDEX('-', REVERSE(@ToSerial)));

                IF @FromPrefix <> @ToPrefix
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS Status, 'Serial prefix must be same' AS Message;
                    RETURN;
                END

                SET @Prefix = @FromPrefix + '-';

                SET @FromNo = CAST(RIGHT(@FromSerial, CHARINDEX('-', REVERSE(@FromSerial)) - 1) AS INT);
                SET @ToNo   = CAST(RIGHT(@ToSerial,   CHARINDEX('-', REVERSE(@ToSerial))   - 1) AS INT);

                SET @PaddingLength = LEN(RIGHT(@FromSerial, CHARINDEX('-', REVERSE(@FromSerial)) - 1));

            END

            -- ── FORMAT B: alphanumeric without dash e.g. AC454245 ─
            -- PATINDEX finds the position of the first digit in the string.
            -- Everything before it is the prefix; everything from it is the number.
            ELSE IF PATINDEX('%[0-9]%', @FromSerial) > 1
                 AND PATINDEX('%[0-9]%', @ToSerial)  > 1
            BEGIN

                -- Find where digits start in FromSerial
                SET @NumericStart = PATINDEX('%[0-9]%', @FromSerial);

                SET @FromPrefix = LEFT(@FromSerial, @NumericStart - 1);
                SET @ToPrefix   = LEFT(@ToSerial,   @NumericStart - 1);

                -- Prefixes must match
                IF @FromPrefix <> @ToPrefix
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS Status,
                           'Serial prefix must be same (e.g. both must start with ''' + @FromPrefix + ''')' AS Message;
                    RETURN;
                END

                -- Validate that the suffix is purely numeric
                IF PATINDEX('%[^0-9]%', RIGHT(@FromSerial, LEN(@FromSerial) - @NumericStart + 1)) > 0
                   OR PATINDEX('%[^0-9]%', RIGHT(@ToSerial, LEN(@ToSerial) - @NumericStart + 1)) > 0
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS Status,
                           'Serial number suffix must be numeric for range insert' AS Message;
                    RETURN;
                END

                SET @Prefix        = @FromPrefix;
                SET @FromNo        = CAST(RIGHT(@FromSerial, LEN(@FromSerial) - @NumericStart + 1) AS INT);
                SET @ToNo          = CAST(RIGHT(@ToSerial,   LEN(@ToSerial)   - @NumericStart + 1) AS INT);
                SET @PaddingLength = LEN(RIGHT(@FromSerial,  LEN(@FromSerial) - @NumericStart + 1));

            END

            -- ── FORMAT C: pure numeric e.g. 10001 ─────────────────
            ELSE IF ISNUMERIC(@FromSerial) = 1 AND ISNUMERIC(@ToSerial) = 1
            BEGIN

                SET @Prefix        = '';
                SET @FromNo        = CAST(@FromSerial AS INT);
                SET @ToNo          = CAST(@ToSerial   AS INT);
                SET @PaddingLength = LEN(@FromSerial);

            END
            ELSE
            BEGIN

                -- Unrecognised format
                ROLLBACK TRANSACTION;
                SELECT 0 AS Status,
                       'Unsupported serial number format for range insert. '
                       + 'Supported formats: dash-separated (AB-001), alphanumeric (AC454245), or numeric (10001)' AS Message;
                RETURN;

            END

            -- ── Validate range direction ─────────────────────────
            IF @FromNo > @ToNo
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS Status,
                       'From Serial cannot be greater than To Serial' AS Message;
                RETURN;
            END

            -- ── Warn if range is unexpectedly large (> 10 000) ───
            IF (@ToNo - @FromNo + 1) > 10000
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS Status,
                       'Serial range exceeds 10,000 records. Please reduce the range.' AS Message;
                RETURN;
            END

            -- =====================================================
            -- LOOP INSERT
            -- =====================================================

            SET @CurrentNo = @FromNo;

            WHILE @CurrentNo <= @ToNo
            BEGIN

                INSERT INTO dbo.AircraftEffectivity
                (
                    AircraftPublicationId, ACPSectionId, MakeTypeId, AircraftModelId, AircraftSubModel,
                    SerialNum, ItemMasterId, PartNumber, PartDescription, ComponentSerialNum, ComponentToSerialNum, Notes,
                    MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
                    IsActive, IsDeleted
                )
                SELECT
                    T.AircraftPublicationsId,
					T.ACPSectionId,
                    T.MakeTypeId,
                    T.AircraftModelId,
                    T.AircraftSubModel,

                    -- Build the serial: prefix + zero-padded number
                    CASE
                        WHEN LEN(CAST(@CurrentNo AS VARCHAR)) >= @PaddingLength
                        THEN @Prefix + CAST(@CurrentNo AS VARCHAR)
                        ELSE @Prefix + RIGHT(
                                           REPLICATE('0', @PaddingLength) + CAST(@CurrentNo AS VARCHAR),
                                           @PaddingLength
                                       )
                    END,

                    T.ItemMasterId,
                    T.PartNumber,
                    T.PartDescription,
					T.ComponentSerialNum,
					T.ComponentToSerialNum,
                    T.Notes,
                    T.MasterCompanyId,
                    T.CreatedBy,
                    T.UpdatedBy,
                    GETUTCDATE(),
                    GETUTCDATE(),
                    1,
                    0
                FROM @tbl_AircraftEffectivityType T
                WHERE ISNULL(T.AircraftEffectivityId, 0) = 0;

                SET @Id = SCOPE_IDENTITY();
                SET @CurrentNo = @CurrentNo + 1;

            END

        END

        COMMIT TRANSACTION;

        SELECT 1 AS Status, 'Saved successfully' AS Message, @Id AS Id;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE
            @ErrorLogID      INT,
            @DatabaseName    VARCHAR(100) = DB_NAME(),
            @AdhocComments   VARCHAR(150) = 'USP_SaveAircraftEffectivity',
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