/***************************************************************  
 ** File:   [USP_CreateUpdateAircraftMaintenanceProgram]
 ** Author:   Priyansh Patel
 ** Description: This stored procedure is used add Aircraft Maintenance Program
 ** Date:   21/04/2026

 ** Change History
 **************************************************************
 ** PR   Date			Author  				Change Description
 ** --   --------		-------					--------------------------------
    1    21/04/2026	    Priyansh Patel			Created  PN-16016
	2    05/05/2026	    Amit Ghediya			update chnge for program
    3    07/05/2026	    Priyansh Patel			Fixed the Remaining time calculation [PN-16306]
	4    14/05/2026	    Amit Ghediya			Added TailNumber [PN-16378]
	5    18/05/2026	    Bhargav Saliya			Added @IsScheduledMaintenance [PN-16475]
	6    19/05/2026	    Bhargav Saliya			Replace @IsScheduledMaintenance to @MtcCategoryId
	7    20/05/2026	    Moin Bloch			    Added @IsMtceRecordUpdated [PN-16449]
    8    22/05/2026     Ayushi Patel            [PN-16553] Save MaintenanceType from WorkScope table
**************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateUpdateAircraftMaintenanceProgram]
    @ProgramId                  BIGINT,
    @AircraftRegistryId         BIGINT,
    @MaintenanceTypeId          BIGINT          = NULL,
    @NextScheduledMaintenance   DATETIME2(7)    = NULL,
    @TemplateId                 BIGINT          = NULL,
    @TemplateVersionNumber      VARCHAR(50)     = NULL,
    @FlightHoursLimitHours      INT             = NULL,
    @FlightHoursLimitMinutes    INT             = NULL,
    @CyclesLimit                BIGINT          = NULL,
    @TimeLimit                  BIGINT          = NULL,
    @LandingsLimit              BIGINT          = NULL,
    @EngineStartsLimit          BIGINT          = NULL,
    @IsActive                   BIT             = 1,
    @IsDeleted                  BIT             = 0,
    @MasterCompanyId            INT,
    @CreatedBy                  VARCHAR(256),
    @UpdatedBy                  VARCHAR(256)    = NULL,
    @IsVersionIncrease          BIT             = 0,
	@TailNumber      VARCHAR(50)     = NULL,
    @MtcCategoryId          BIGINT,
	@IsMtceRecordUpdated    BIT          = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
    BEGIN TRANSACTION

        -- Fetch Aircraft details from AircraftRegistryHeader
        --DECLARE @TailNumber      VARCHAR(50)     = NULL;
        DECLARE @AircraftMake    VARCHAR(100)    = NULL;
        DECLARE @AircraftModel   VARCHAR(100)    = NULL;
        DECLARE @SerialNumber    VARCHAR(100)    = NULL;
        DECLARE @MaintenanceType VARCHAR(200)    = NULL;


        IF @FlightHoursLimitHours IS NOT NULL OR @FlightHoursLimitMinutes IS NOT NULL
        BEGIN
            SET @FlightHoursLimitHours    = ISNULL(@FlightHoursLimitHours, 0);
            SET @FlightHoursLimitMinutes  = ISNULL(@FlightHoursLimitMinutes, 0);
        END

		--GET AC Details
		IF(ISNULL(@TailNumber,'') != '')
		BEGIN
			 SELECT @AircraftRegistryId = AircraftRegistryId
			 FROM dbo.AircraftRegistryHeader WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(TailNum))) = UPPER(LTRIM(RTRIM(@TailNumber)))
		END

        SELECT @TailNumber     = TailNum, @AircraftMake   = MakeType, @AircraftModel  = AircraftModel, @SerialNumber   = SerialNum
        FROM dbo.AircraftRegistryHeader WITH(NOLOCK) WHERE AircraftRegistryId = @AircraftRegistryId AND [IsActive]= 1 AND [IsDeleted] = 0;

        SELECT @MaintenanceType = WorkScopeCode FROM dbo.WorkScope WITH(NOLOCK) WHERE WorkScopeId = @MaintenanceTypeId AND [IsActive]= 1 AND [IsDeleted] = 0;

        -- Version Control
        DECLARE @VersionNum         VARCHAR(50)     = NULL;
        DECLARE @NewVersionNum      VARCHAR(50)     = '';
        DECLARE @versionNo          INT             = 0;
        DECLARE @splitPos           INT             = 0;
        DECLARE @VersionCodePrefix  NVARCHAR(50);
        DECLARE @VersionCodeSuffix  NVARCHAR(50);
        DECLARE @WorkFlowVersion    INT;

        SELECT @WorkFlowVersion = [CodeTypeId]
        FROM [dbo].[CodeTypes] WITH(NOLOCK)
        WHERE [CodeType] = 'Version';

        SELECT TOP 1
            @VersionCodePrefix = [CodePrefix],
            @VersionCodeSuffix = [CodeSufix]
        FROM [dbo].[CodePrefixes] WITH(NOLOCK)
        WHERE [IsActive]        = 1
          AND [IsDeleted]       = 0
          AND [CodeTypeId]      = @WorkFlowVersion
          AND [MasterCompanyId] = @MasterCompanyId;

        -- ===================== UPDATE =====================
        IF (@ProgramId > 0)
        BEGIN
            IF (@IsVersionIncrease = 1)
            BEGIN
                SELECT @VersionNum = VersionNumber
                FROM dbo.AircraftMaintenanceProgram WITH(NOLOCK)
                WHERE ProgramId = @ProgramId AND [MasterCompanyId] = @MasterCompanyId;

                IF (@VersionNum IS NOT NULL AND @VersionNum <> '')
                BEGIN
                    IF LEN(@VersionNum) > 5
                    BEGIN
                        SET @splitPos = CHARINDEX('-', @VersionNum);
                        IF @splitPos > 0
                            SET @versionNo = CAST(SUBSTRING(@VersionNum, @splitPos + 1, LEN(@VersionNum)) AS INT) + 1;
                    END
                    ELSE
                        SET @versionNo = CAST(SUBSTRING(@VersionNum, 3, LEN(@VersionNum)) AS INT) + 1;

                    SET @NewVersionNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@versionNo, ISNULL(@VersionCodePrefix,''), ISNULL(@VersionCodeSuffix,'')))
                END
                ELSE
                    SET @NewVersionNum = (SELECT * FROM dbo.udfGenerateCodeNumber(1, ISNULL(@VersionCodePrefix,''), ISNULL(@VersionCodeSuffix,'')))

                SET @NewVersionNum = CASE WHEN @NewVersionNum <> '' THEN @NewVersionNum ELSE ISNULL(@VersionNum, '') END;
            END
            ELSE
            BEGIN
                SELECT @NewVersionNum = VersionNumber
                FROM dbo.AircraftMaintenanceProgram WITH(NOLOCK)
                WHERE ProgramId = @ProgramId AND [MasterCompanyId] = @MasterCompanyId;
            END
            
			UPDATE dbo.AircraftMaintenanceProgram
			SET
				AircraftRegistryId          = @AircraftRegistryId,
				TailNumber                  = @TailNumber,
				AircraftMake                = @AircraftMake,
				AircraftModel               = @AircraftModel,
				SerialNumber                = @SerialNumber,
				MaintenanceType             = @MaintenanceType,
				MaintenanceTypeId           = @MaintenanceTypeId,
				NextScheduledMaintenance    = @NextScheduledMaintenance,
				TemplateId                  = @TemplateId,
				TemplateVersionNumber       = @TemplateVersionNumber,
				VersionNumber               = @NewVersionNum,
				FlightHoursLimitHours       = @FlightHoursLimitHours,
				FlightHoursLimitMinutes     = @FlightHoursLimitMinutes,
				CyclesLimit                 = @CyclesLimit,
				TimeLimit                   = @TimeLimit,
				LandingsLimit               = @LandingsLimit,
				EngineStartsLimit           = @EngineStartsLimit,
                FlightHoursRemainingHours =
                CASE 
                    WHEN @FlightHoursLimitHours IS NULL AND @FlightHoursLimitMinutes IS NULL THEN NULL
                    ELSE
                        CASE
                            WHEN (
                                (@FlightHoursLimitHours * 60 + @FlightHoursLimitMinutes)
                                - (ISNULL(FlightHoursRecordedHours,0) * 60 + ISNULL(FlightHoursRecordedMinutes,0))
                            ) < 0 THEN 0
                            ELSE (
                                (@FlightHoursLimitHours * 60 + @FlightHoursLimitMinutes)
                                - (ISNULL(FlightHoursRecordedHours,0) * 60 + ISNULL(FlightHoursRecordedMinutes,0))
                            ) / 60
                        END
                END,

                FlightHoursRemainingMinutes =
                    CASE 
                        WHEN @FlightHoursLimitHours IS NULL AND @FlightHoursLimitMinutes IS NULL THEN NULL
                        ELSE
                            CASE
                                WHEN (
                                    (@FlightHoursLimitHours * 60 + @FlightHoursLimitMinutes)
                                    - (ISNULL(FlightHoursRecordedHours,0) * 60 + ISNULL(FlightHoursRecordedMinutes,0))
                                ) < 0 THEN 0
                                ELSE (
                                    (@FlightHoursLimitHours * 60 + @FlightHoursLimitMinutes)
                                    - (ISNULL(FlightHoursRecordedHours,0) * 60 + ISNULL(FlightHoursRecordedMinutes,0))
                                ) % 60
                            END
                    END,
                    CyclesRemaining =
	                    CASE 
		                    WHEN CyclesRecorded IS NULL THEN @CyclesLimit
		                    ELSE 
                                CASE
                                    WHEN  @CyclesLimit - CyclesRecorded < 0 THEN 0
                                    ELSE  @CyclesLimit - CyclesRecorded
                                END
                            
	                    END,
				TimeRemaining =
					CASE 
						WHEN TimeRecorded IS NULL THEN @TimeLimit
						ELSE @TimeLimit - TimeRecorded
					END,
				LandingsRemaining =
					CASE 
						WHEN LandingsRecorded IS NULL THEN @LandingsLimit
						ELSE @LandingsLimit - LandingsRecorded
					END,
				EngineStartsRemaining =
					CASE 
						WHEN EngineStartsRecorded IS NULL THEN @EngineStartsLimit
						ELSE @EngineStartsLimit - EngineStartsRecorded
					END,
				IsActive        = @IsActive,
				IsDeleted       = @IsDeleted,
				UpdatedBy       = @UpdatedBy,
				UpdatedDate     = GETUTCDATE(),
                MtcCategoryId = @MtcCategoryId
			WHERE ProgramId = @ProgramId 
			AND MasterCompanyId = @MasterCompanyId;
        END

        -- ===================== INSERT =====================
        ELSE
        BEGIN
            SET @NewVersionNum = (SELECT * FROM dbo.udfGenerateCodeNumber(1, ISNULL(@VersionCodePrefix,''), ISNULL(@VersionCodeSuffix,'')))

            INSERT INTO dbo.AircraftMaintenanceProgram
            (
                AircraftRegistryId, VersionNumber, TailNumber,
                AircraftMake, AircraftModel, SerialNumber,
                MaintenanceType, MaintenanceTypeId, NextScheduledMaintenance,
                TemplateId, TemplateVersionNumber,
                FlightHoursLimitHours, FlightHoursLimitMinutes,
                CyclesLimit, TimeLimit, LandingsLimit, EngineStartsLimit,
                FlightHoursRemainingHours,FlightHoursRemainingMinutes,CyclesRemaining,
                IsActive, IsDeleted, MasterCompanyId,
                CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,MtcCategoryId,IsMtceRecordUpdated
            )
            VALUES
            (
                @AircraftRegistryId, @NewVersionNum, @TailNumber,
                @AircraftMake, @AircraftModel, @SerialNumber,@MaintenanceType,
                @MaintenanceTypeId, @NextScheduledMaintenance,
                @TemplateId, @TemplateVersionNumber,
                @FlightHoursLimitHours, @FlightHoursLimitMinutes,
                @CyclesLimit, @TimeLimit, @LandingsLimit, @EngineStartsLimit,
                @FlightHoursLimitHours, @FlightHoursLimitMinutes, @CyclesLimit,
                ISNULL(@IsActive, 1), ISNULL(@IsDeleted, 0), @MasterCompanyId,
                @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),@MtcCategoryId, @IsMtceRecordUpdated
            );

            SET @ProgramId = SCOPE_IDENTITY();
        END

        SELECT * FROM dbo.AircraftMaintenanceProgram WITH(NOLOCK)
        WHERE ProgramId = @ProgramId AND [MasterCompanyId] = @MasterCompanyId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
                , @AdhocComments        VARCHAR(150)    = 'USP_CreateUpdateAircraftMaintenanceProgram'
                , @ProcedureParameters  VARCHAR(3000)   =
                    '@Parameter1 = '''  + ISNULL(CAST(@ProgramId            AS VARCHAR), '') + ''',
                     @Parameter2 = '''  + ISNULL(CAST(@AircraftRegistryId   AS VARCHAR), '') + ''',
                     @Parameter3 = '''  + ISNULL(@MaintenanceTypeId,          '')               + ''',
                     @Parameter4 = '''  + ISNULL(CAST(@TemplateId           AS VARCHAR), '') + ''',
                     @Parameter5 = '''  + ISNULL(CAST(@MasterCompanyId      AS VARCHAR), '') + ''',
                     @Parameter6 = ''' + ISNULL(CAST(@IsVersionIncrease     AS VARCHAR), '') + ''''
                , @ApplicationName VARCHAR(100) = 'PAS'

            EXEC spLogException
                  @DatabaseName         = @DatabaseName
                , @AdhocComments        = @AdhocComments
                , @ProcedureParameters  = @ProcedureParameters
                , @ApplicationName      = @ApplicationName
                , @ErrorLogID           = @ErrorLogID OUTPUT;

            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
    END CATCH
END