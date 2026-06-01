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
** 2    15/05/2026 Amit Ghediya    Added ToSerialNumber/FromSerialNumber
** 3    20/05/2026 Amit Ghediya    Removed Part Validation
** 4    29/05/2026 Amit Ghediya    Fixed Serial Range Insert
**************************************************************/

CREATE PROCEDURE [dbo].[USP_SaveAircraftEffectivity]
    @tbl_AircraftEffectivityType dbo.AircraftEffectivityTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE @Id BIGINT;

        -- =========================================================
        -- DUPLICATE VALIDATION
        -- =========================================================

        IF EXISTS
        (
            SELECT 1
            FROM dbo.AircraftEffectivity AE WITH(NOLOCK)
            INNER JOIN @tbl_AircraftEffectivityType T
                ON AE.MakeTypeId = T.MakeTypeId
                AND AE.SerialNum = T.FromSerialNumber
                AND AE.MasterCompanyId = T.MasterCompanyId
                AND AE.IsDeleted = 0
                AND AE.AircraftEffectivityId <> ISNULL(T.AircraftEffectivityId,0)
        )
        BEGIN

            ROLLBACK TRANSACTION;

            SELECT 0 AS Status,
                   'Duplicate Serial Number for same Aircraft Type' AS Message;

            RETURN;
        END

        -- =========================================================
        -- UPDATE
        -- =========================================================

        UPDATE AE
        SET
            AE.AircraftPublicationId = T.AircraftPublicationsId,
            AE.MakeTypeId = T.MakeTypeId,
            AE.AircraftModelId = T.AircraftModelId,
            AE.AircraftSubModel = T.AircraftSubModel,
            AE.SerialNum = T.FromSerialNumber,
            AE.ItemMasterId = T.ItemMasterId,
            AE.PartNumber = T.PartNumber,
            AE.PartDescription = T.PartDescription,
            AE.Notes = T.Notes,
            AE.UpdatedBy = T.UpdatedBy,
            AE.UpdatedDate = GETUTCDATE()
        FROM dbo.AircraftEffectivity AE
        INNER JOIN @tbl_AircraftEffectivityType T
            ON AE.AircraftEffectivityId = T.AircraftEffectivityId
        WHERE T.AircraftEffectivityId > 0;

        -- =========================================================
        -- INSERT VARIABLES
        -- =========================================================

        DECLARE
            @FromSerial VARCHAR(100),
            @ToSerial VARCHAR(100),
            @Prefix VARCHAR(100),
            @FromPrefix VARCHAR(100),
            @ToPrefix VARCHAR(100),
            @FromNo INT,
            @ToNo INT,
            @CurrentNo INT,
            @PaddingLength INT;

        SELECT TOP 1
            @FromSerial = T.FromSerialNumber,
            @ToSerial = T.ToSerialNumber
        FROM @tbl_AircraftEffectivityType T;

        -- =========================================================
        -- SINGLE INSERT
        -- =========================================================

        IF ISNULL(@ToSerial, '') = ''
        BEGIN

            INSERT INTO dbo.AircraftEffectivity
            (
                AircraftPublicationId,
                MakeTypeId,
                AircraftModelId,
                AircraftSubModel,
                SerialNum,
                ItemMasterId,
                PartNumber,
                PartDescription,
                Notes,
                MasterCompanyId,
                CreatedBy,
                UpdatedBy,
                CreatedDate,
                UpdatedDate,
                IsActive,
                IsDeleted
            )
            SELECT
                T.AircraftPublicationsId,
                T.MakeTypeId,
                T.AircraftModelId,
                T.AircraftSubModel,
                @FromSerial,
                T.ItemMasterId,
                T.PartNumber,
                T.PartDescription,
                T.Notes,
                T.MasterCompanyId,
                T.CreatedBy,
                T.UpdatedBy,
                GETUTCDATE(),
                GETUTCDATE(),
                1,
                0
            FROM @tbl_AircraftEffectivityType T
            WHERE ISNULL(T.AircraftEffectivityId,0) = 0;

            SET @Id = SCOPE_IDENTITY();

        END
        ELSE
        BEGIN

            -- =====================================================
            -- MULTIPLE SERIAL INSERT
            -- =====================================================

            IF CHARINDEX('-', @FromSerial) > 0
               AND CHARINDEX('-', @ToSerial) > 0
            BEGIN

                -- PREFIX
                SET @FromPrefix =
                    LEFT(
                        @FromSerial,
                        LEN(@FromSerial) - CHARINDEX('-', REVERSE(@FromSerial))
                    );

                SET @ToPrefix =
                    LEFT(
                        @ToSerial,
                        LEN(@ToSerial) - CHARINDEX('-', REVERSE(@ToSerial))
                    );

                -- VALIDATE PREFIX
                IF @FromPrefix <> @ToPrefix
                BEGIN

                    ROLLBACK TRANSACTION;

                    SELECT 0 AS Status,
                           'Serial prefix must be same' AS Message;

                    RETURN;
                END

                SET @Prefix = @FromPrefix + '-';

                -- NUMBER PART
                SET @FromNo =
                    CAST(
                        RIGHT(
                            @FromSerial,
                            CHARINDEX('-', REVERSE(@FromSerial)) - 1
                        ) AS INT
                    );

                SET @ToNo =
                    CAST(
                        RIGHT(
                            @ToSerial,
                            CHARINDEX('-', REVERSE(@ToSerial)) - 1
                        ) AS INT
                    );

                SET @PaddingLength =
                    LEN(
                        RIGHT(
                            @FromSerial,
                            CHARINDEX('-', REVERSE(@FromSerial)) - 1
                        )
                    );

            END
            ELSE
            BEGIN

                -- PURE NUMERIC SERIAL
                SET @Prefix = '';

                SET @FromNo = CAST(@FromSerial AS INT);

                SET @ToNo = CAST(@ToSerial AS INT);

                SET @PaddingLength = LEN(@FromSerial);

            END

            -- VALIDATE RANGE
            IF @FromNo > @ToNo
            BEGIN

                ROLLBACK TRANSACTION;

                SELECT 0 AS Status,
                       'From Serial cannot be greater than To Serial' AS Message;

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
                    AircraftPublicationId,
                    MakeTypeId,
                    AircraftModelId,
                    AircraftSubModel,
                    SerialNum,
                    ItemMasterId,
                    PartNumber,
                    PartDescription,
                    Notes,
                    MasterCompanyId,
                    CreatedBy,
                    UpdatedBy,
                    CreatedDate,
                    UpdatedDate,
                    IsActive,
                    IsDeleted
                )
                SELECT
                    T.AircraftPublicationsId,
                    T.MakeTypeId,
                    T.AircraftModelId,
                    T.AircraftSubModel,

                    CASE
                        WHEN LEN(CAST(@CurrentNo AS VARCHAR)) >= @PaddingLength
                        THEN @Prefix + CAST(@CurrentNo AS VARCHAR)

                        ELSE @Prefix +
                             RIGHT(
                                 REPLICATE('0', @PaddingLength)
                                 + CAST(@CurrentNo AS VARCHAR),
                                 @PaddingLength
                             )
                    END,

                    T.ItemMasterId,
                    T.PartNumber,
                    T.PartDescription,
                    T.Notes,
                    T.MasterCompanyId,
                    T.CreatedBy,
                    T.UpdatedBy,
                    GETUTCDATE(),
                    GETUTCDATE(),
                    1,
                    0
                FROM @tbl_AircraftEffectivityType T
                WHERE ISNULL(T.AircraftEffectivityId,0) = 0;

                SET @Id = SCOPE_IDENTITY();

                SET @CurrentNo = @CurrentNo + 1;

            END

        END

        COMMIT TRANSACTION;

        SELECT 1 AS Status,
               'Saved successfully' AS Message,
               @Id AS Id;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = 'USP_SaveAircraftEffectivity',
            @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR
        (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16,
            1,
            @ErrorLogID
        );

        RETURN(1);

    END CATCH

END