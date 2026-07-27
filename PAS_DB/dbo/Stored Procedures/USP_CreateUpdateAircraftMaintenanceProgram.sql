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
    9    01/06/2026     Ayushi Patel            [PN-16657] Save MaintenanceType from VW_WorkScopeType table
   10    02/06/2026     Abhishek Jirawla        Added IsScheduled [PN-16679]
   11	 08/06/2026		Amit Ghediya		    Adding Header data in History module [PN-16581]
   12    16/06/2026	    Amit Ghediya			Added @AircraftPublicationId [PN-16797]
   13    25/06/2026	    Amit Ghediya			Added @LastInspectedDate,@Description,@LastinspectedById [PN-17000]
   14    29/06/2026	    Moin Bloch			    Removed MaintenanceTypeId PN-17043
   15    30/06/2026	    Amit Ghediya	        Update for Engine data [PN-17075]
   16    01/07/2026	    Amit Ghediya	        Add auto SequenceNo when insert data remove update
   16    01/07/2026	    Amit Ghediya	        Remove update time ac & engine id not required
**************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateUpdateAircraftMaintenanceProgram]
    @ProgramId                  BIGINT,
    @AircraftRegistryId         BIGINT,
	@MaintenanceType            VARCHAR(MAX)     = NULL,
    @MaintenanceTypeId          BIGINT          = NULL,
    @NextScheduledMaintenance   DATETIME2(7)    = NULL,
    @TemplateId                 BIGINT          = NULL,
    @TemplateVersionNumber      VARCHAR(50)     = NULL,
    @FlightHoursLimitHours      INT             = NULL,
    @FlightHoursLimitMinutes    INT             = NULL,
	@FlightHoursLimitMonthsOrDays INT             = NULL,   -- ← NEW
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
    @TailNumber                 VARCHAR(50)     = NULL,
    @MtcCategoryId              BIGINT,
    @IsMtceRecordUpdated        BIT             = NULL,
	@AircraftPublicationId		BIGINT          = NULL,
    @IsScheduled                BIT             = NULL,
	@LastInspectedDate			DATETIME2(7)    = NULL,
	@Description				VARCHAR(256)    = NULL,
	@LastinspectedById			BIGINT			= NULL,
	@IsFromAircraft				BIT             = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
    BEGIN TRANSACTION

        -- ── Aircraft details ──────────────────────────────────
        DECLARE @AircraftMake    VARCHAR(100)    = NULL;
        DECLARE @AircraftModel   VARCHAR(100)    = NULL;
        DECLARE @SerialNumber    VARCHAR(100)    = NULL;

        -- ── OLD value holders (capture BEFORE update) ─────────
        DECLARE @Old_MaintenanceType            VARCHAR(200),
                @Old_NextScheduledMaintenance   VARCHAR(250),
                @Old_FlightHours                VARCHAR(250),    -- stored as "HH : MM"
                @Old_CyclesLimit                VARCHAR(250),
                @Old_TimeLimit                  VARCHAR(250),
                @Old_LandingsLimit              VARCHAR(250),
                @Old_EngineStartsLimit          VARCHAR(250),
                @Old_IsActive                   VARCHAR(10);

        -- ── NEW value holders (populated from params) ─────────
        DECLARE @New_MaintenanceType            VARCHAR(200),
                @New_NextScheduledMaintenance   VARCHAR(300),
                @New_FlightHours                VARCHAR(250),
                @New_CyclesLimit                VARCHAR(250),
                @New_TimeLimit                  VARCHAR(250),
                @New_LandingsLimit              VARCHAR(250),
                @New_EngineStartsLimit          VARCHAR(250),
                @New_IsActive                   VARCHAR(10);

        DECLARE @IsUpdate INT = 0;

        IF @FlightHoursLimitHours IS NOT NULL OR @FlightHoursLimitMinutes IS NOT NULL
        BEGIN
            SET @FlightHoursLimitHours   = ISNULL(@FlightHoursLimitHours, 0);
            SET @FlightHoursLimitMinutes = ISNULL(@FlightHoursLimitMinutes, 0);
        END

		-- ← NEW: normalize Days the same way
        IF @FlightHoursLimitMonthsOrDays IS NOT NULL
            SET @FlightHoursLimitMonthsOrDays = ISNULL(@FlightHoursLimitMonthsOrDays, 0);

        -- GET AC Details
		IF(ISNULL(@IsFromAircraft,0) = 1)
		BEGIN
			 IF (ISNULL(@TailNumber,'') != '')
			 BEGIN
				 SELECT @AircraftRegistryId = AircraftRegistryId
				 FROM dbo.AircraftRegistryHeader WITH(NOLOCK)
				 WHERE UPPER(LTRIM(RTRIM(TailNum))) = UPPER(LTRIM(RTRIM(@TailNumber)));
			END
		END
		ELSE
		BEGIN
			 IF (ISNULL(@TailNumber,'') != '')
			 BEGIN
				 SELECT @AircraftRegistryId = EngineRegistryId
				 FROM dbo.EngineRegistryHeader WITH(NOLOCK)
				 WHERE UPPER(LTRIM(RTRIM(TailNum))) = UPPER(LTRIM(RTRIM(@TailNumber)));
			END
		END
        

		IF(ISNULL(@IsFromAircraft,0) = 1)
		BEGIN
			 SELECT
				@TailNumber    = TailNum,
				@AircraftMake  = MakeType,
				@AircraftModel = AircraftModel,
				@SerialNumber  = SerialNum
			FROM dbo.AircraftRegistryHeader WITH(NOLOCK)
			WHERE AircraftRegistryId = @AircraftRegistryId
			  AND [IsActive]  = 1
			  AND [IsDeleted] = 0;
		END
		ELSE
		BEGIN
			SELECT
				@TailNumber    = TailNum,
				@AircraftMake  = MakeType,
				@AircraftModel = EngineModel,
				@SerialNumber  = SerialNum
			FROM dbo.EngineRegistryHeader WITH(NOLOCK)
			WHERE EngineRegistryId = @AircraftRegistryId
			  AND [IsActive]  = 1
			  AND [IsDeleted] = 0;
		END
        

        SELECT @MaintenanceType = WorkScopeCode
        FROM dbo.VW_WorkScopeType WITH(NOLOCK)
        WHERE WorkScopeId = @MaintenanceTypeId
          AND [IsActive]  = 1
          AND [IsDeleted] = 0;

        -- Version Control
        DECLARE @VersionNum         VARCHAR(50) = NULL;
        DECLARE @NewVersionNum      VARCHAR(50) = '';
        DECLARE @versionNo          INT         = 0;
        DECLARE @splitPos           INT         = 0;
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

        -- =====================================================
        -- UPDATE
        -- =====================================================
        IF (@ProgramId > 0)
        BEGIN
            -- ── STEP 1: Read OLD values BEFORE update ─────────
            SELECT
                @Old_MaintenanceType          = AMP.MaintenanceType,
                @Old_NextScheduledMaintenance = ISNULL(CONVERT(VARCHAR(30), CAST(AMP.NextScheduledMaintenance AS DATE), 103), ''),
                @Old_FlightHours              = CAST(ISNULL(AMP.FlightHoursLimitHours, 0) AS VARCHAR)
                                              + ' : '
                                              + RIGHT('00' + CAST(ISNULL(AMP.FlightHoursLimitMinutes, 0) AS VARCHAR), 2),
                @Old_CyclesLimit              = CAST(ISNULL(AMP.CyclesLimit, 0) AS VARCHAR),
                @Old_TimeLimit                = CAST(ISNULL(AMP.TimeLimit,   0) AS VARCHAR),
                @Old_LandingsLimit            = CAST(ISNULL(AMP.LandingsLimit, 0) AS VARCHAR),
                @Old_EngineStartsLimit        = CAST(ISNULL(AMP.EngineStartsLimit, 0) AS VARCHAR),
                @Old_IsActive                 = CASE WHEN AMP.IsActive = 1 THEN 'Active' ELSE 'Inactive' END
            FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
            WHERE AMP.ProgramId       = @ProgramId
              AND AMP.MasterCompanyId = @MasterCompanyId;

            -- ── Version handling ──────────────────────────────
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

                    SET @NewVersionNum = (SELECT * FROM dbo.udfGenerateCodeNumber(@versionNo, ISNULL(@VersionCodePrefix,''), ISNULL(@VersionCodeSuffix,'')));
                END
                ELSE
                    SET @NewVersionNum = (SELECT * FROM dbo.udfGenerateCodeNumber(1, ISNULL(@VersionCodePrefix,''), ISNULL(@VersionCodeSuffix,'')));

                SET @NewVersionNum = CASE WHEN @NewVersionNum <> '' THEN @NewVersionNum ELSE ISNULL(@VersionNum, '') END;
            END
            ELSE
            BEGIN
                SELECT @NewVersionNum = VersionNumber
                FROM dbo.AircraftMaintenanceProgram WITH(NOLOCK)
                WHERE ProgramId = @ProgramId AND [MasterCompanyId] = @MasterCompanyId;
            END

			--Update engine maintance records
			IF(ISNULL(@TailNumber,'') = '' AND ISNULL(@IsFromAircraft,0) = 0)
			BEGIN
				 SELECT @TailNumber = [TailNum] FROM dbo.EngineRegistryHeader WHERE [EngineRegistryId] = @AircraftRegistryId;
			END

            -- ── Main UPDATE ───────────────────────────────────
            UPDATE dbo.AircraftMaintenanceProgram
            SET
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
				FlightHoursLimitMonthsOrDays = @FlightHoursLimitMonthsOrDays,    -- ← NEW
                CyclesLimit                 = @CyclesLimit,
                TimeLimit                   = @TimeLimit,
                LandingsLimit               = @LandingsLimit,
                EngineStartsLimit           = @EngineStartsLimit,
                FlightHoursRemainingHours =
                    CASE
                        WHEN @FlightHoursLimitHours IS NULL AND @FlightHoursLimitMinutes IS NULL THEN NULL
                        ELSE CASE
                                WHEN ((@FlightHoursLimitHours * 60 + @FlightHoursLimitMinutes)
                                    - (ISNULL(FlightHoursRecordedHours,0) * 60 + ISNULL(FlightHoursRecordedMinutes,0))) < 0 THEN 0
                                ELSE ((@FlightHoursLimitHours * 60 + @FlightHoursLimitMinutes)
                                    - (ISNULL(FlightHoursRecordedHours,0) * 60 + ISNULL(FlightHoursRecordedMinutes,0))) / 60
                             END
                    END,
                FlightHoursRemainingMinutes =
                    CASE
                        WHEN @FlightHoursLimitHours IS NULL AND @FlightHoursLimitMinutes IS NULL THEN NULL
                        ELSE CASE
                                WHEN ((@FlightHoursLimitHours * 60 + @FlightHoursLimitMinutes)
                                    - (ISNULL(FlightHoursRecordedHours,0) * 60 + ISNULL(FlightHoursRecordedMinutes,0))) < 0 THEN 0
                                ELSE ((@FlightHoursLimitHours * 60 + @FlightHoursLimitMinutes)
                                    - (ISNULL(FlightHoursRecordedHours,0) * 60 + ISNULL(FlightHoursRecordedMinutes,0))) % 60
                             END
                    END,
                CyclesRemaining =
                    CASE
                        WHEN CyclesRecorded IS NULL THEN @CyclesLimit
                        ELSE CASE WHEN @CyclesLimit - CyclesRecorded < 0 THEN 0 ELSE @CyclesLimit - CyclesRecorded END
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
                MtcCategoryId   = @MtcCategoryId,
                IsScheduled     = @IsScheduled,

				LastInspectedDate     = @LastInspectedDate,
				[Description]     = @Description,
				LastinspectedById     = @LastinspectedById
            WHERE ProgramId       = @ProgramId
              AND MasterCompanyId = @MasterCompanyId;

            SET @IsUpdate = 1;
        END

        -- =====================================================
        -- INSERT
        -- =====================================================
        ELSE
        BEGIN
            SET @NewVersionNum = (SELECT * FROM dbo.udfGenerateCodeNumber(1, ISNULL(@VersionCodePrefix,''), ISNULL(@VersionCodeSuffix,'')));

			DECLARE @OldNum INT = ISNULL((SELECT MAX(SequenceNo) FROM dbo.AircraftMaintenanceProgram), 0);

            INSERT INTO dbo.AircraftMaintenanceProgram
            (
                AircraftRegistryId, EngineRegistryId, IsFromAircraft,VersionNumber, TailNumber,
                AircraftMake, AircraftModel, SerialNumber,
                MaintenanceType, MaintenanceTypeId, NextScheduledMaintenance,
                TemplateId, TemplateVersionNumber,
                FlightHoursLimitHours, FlightHoursLimitMinutes,
                CyclesLimit, TimeLimit, LandingsLimit, EngineStartsLimit,
                FlightHoursRemainingHours, FlightHoursRemainingMinutes, CyclesRemaining,
                IsActive, IsDeleted, MasterCompanyId,
                CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
                MtcCategoryId, IsMtceRecordUpdated, AircraftPublicationId, IsScheduled,
				LastInspectedDate , [Description], LastinspectedById,FlightHoursLimitMonthsOrDays,SequenceNo
            )
            VALUES
            (
                @AircraftRegistryId,CASE WHEN ISNULL(@IsFromAircraft,0) = 1 THEN NULL ELSE  @AircraftRegistryId END,CASE WHEN ISNULL(@IsFromAircraft,0) = 1 THEN 1 ELSE  0 END, @NewVersionNum, @TailNumber,
                @AircraftMake, @AircraftModel, @SerialNumber,
                @MaintenanceType, @MaintenanceTypeId, @NextScheduledMaintenance,
                @TemplateId, @TemplateVersionNumber,
                @FlightHoursLimitHours, @FlightHoursLimitMinutes,
                @CyclesLimit, @TimeLimit, @LandingsLimit, @EngineStartsLimit,
                @FlightHoursLimitHours, @FlightHoursLimitMinutes, @CyclesLimit,
                ISNULL(@IsActive, 1), ISNULL(@IsDeleted, 0), @MasterCompanyId,
                @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
                @MtcCategoryId, @IsMtceRecordUpdated, @AircraftPublicationId, @IsScheduled,
				@LastInspectedDate, @Description, @LastinspectedById,@FlightHoursLimitMonthsOrDays,@OldNum + 1
            );

            SET @ProgramId = SCOPE_IDENTITY();
        END

        SELECT * FROM dbo.AircraftMaintenanceProgram WITH(NOLOCK)
        WHERE ProgramId = @ProgramId AND [MasterCompanyId] = @MasterCompanyId;

        -- =====================================================
        -- HISTORY BLOCK
        -- Same pattern as USP_CreateAircraftRegistryHeader
        -- =====================================================
        DECLARE @TemplateCode   VARCHAR(50)     = '',
                @TemplateBody   VARCHAR(MAX)    = '',
                @HistCreatedBy  VARCHAR(100)    = ISNULL(@UpdatedBy, @CreatedBy),
                @Activity       VARCHAR(100)    = NULL,
				@ProgramIdStr VARCHAR(50);

        -- Build NEW value strings from params
        SET @New_MaintenanceType          = ISNULL(@MaintenanceType, '');
		SET @New_NextScheduledMaintenance = ISNULL(CONVERT(VARCHAR(250), CAST(@NextScheduledMaintenance AS DATE), 103), '');
        SET @New_FlightHours              = CAST(ISNULL(@FlightHoursLimitHours,   0) AS VARCHAR)
                                          + ' : '
                                          + RIGHT('00' + CAST(ISNULL(@FlightHoursLimitMinutes, 0) AS VARCHAR), 2);
        SET @New_CyclesLimit              = CAST(ISNULL(@CyclesLimit,       0) AS VARCHAR);
        SET @New_TimeLimit                = CAST(ISNULL(@TimeLimit,         0) AS VARCHAR);
        SET @New_LandingsLimit            = CAST(ISNULL(@LandingsLimit,     0) AS VARCHAR);
        SET @New_EngineStartsLimit        = CAST(ISNULL(@EngineStartsLimit, 0) AS VARCHAR);
        SET @New_IsActive                 = CASE WHEN ISNULL(@IsActive, 1) = 1 THEN 'Active' ELSE 'Inactive' END;

        IF (@IsUpdate = 1)
        BEGIN
            SET @TemplateCode = 'UpdateAircraftMaintenance';
            SET @Activity     = 'Maintenance Updated';

            -- Build ONE combined TemplateBody — only changed fields
            IF ISNULL(@Old_MaintenanceType,'')          <> @New_MaintenanceType          AND ISNULL(@New_MaintenanceType,'')          <> ''
                SET @TemplateBody += 'Maintenance Type: '        + ISNULL(@Old_MaintenanceType,'')          + ' to ' + @New_MaintenanceType          + ' | ';

            IF ISNULL(@Old_NextScheduledMaintenance,'') <> @New_NextScheduledMaintenance AND ISNULL(@New_NextScheduledMaintenance,'') <> ''
                SET @TemplateBody += 'Next Scheduled: '          + ISNULL(@Old_NextScheduledMaintenance,'') + ' to ' + @New_NextScheduledMaintenance + ' | ';

            IF ISNULL(@Old_FlightHours,'')              <> @New_FlightHours              AND ISNULL(@New_FlightHours,'')              <> ''
                SET @TemplateBody += 'Flight Hours (HH:MM): '    + ISNULL(@Old_FlightHours,'')              + ' to ' + @New_FlightHours              + ' | ';

            IF CAST(ISNULL(@Old_CyclesLimit,'0') AS BIGINT)       <> CAST(ISNULL(@New_CyclesLimit,'0') AS BIGINT)       AND ISNULL(@New_CyclesLimit,'')       <> ''
                SET @TemplateBody += 'Cycles Limit: '            + ISNULL(@Old_CyclesLimit,'')              + ' to ' + @New_CyclesLimit              + ' | ';

            IF CAST(ISNULL(@Old_TimeLimit,'0') AS BIGINT)         <> CAST(ISNULL(@New_TimeLimit,'0') AS BIGINT)         AND ISNULL(@New_TimeLimit,'')         <> ''
                SET @TemplateBody += 'Time Limit: '              + ISNULL(@Old_TimeLimit,'')                + ' to ' + @New_TimeLimit                + ' | ';

            IF CAST(ISNULL(@Old_LandingsLimit,'0') AS BIGINT)     <> CAST(ISNULL(@New_LandingsLimit,'0') AS BIGINT)     AND ISNULL(@New_LandingsLimit,'')     <> ''
                SET @TemplateBody += 'Landings Limit: '          + ISNULL(@Old_LandingsLimit,'')            + ' to ' + @New_LandingsLimit            + ' | ';

            IF CAST(ISNULL(@Old_EngineStartsLimit,'0') AS BIGINT) <> CAST(ISNULL(@New_EngineStartsLimit,'0') AS BIGINT) AND ISNULL(@New_EngineStartsLimit,'') <> ''
                SET @TemplateBody += 'Engine Starts Limit: '     + ISNULL(@Old_EngineStartsLimit,'')        + ' to ' + @New_EngineStartsLimit        + ' | ';

            IF ISNULL(@Old_IsActive,'')                 <> @New_IsActive                 AND ISNULL(@New_IsActive,'')                 <> ''
                SET @TemplateBody += 'Status: '                  + ISNULL(@Old_IsActive,'')                 + ' to ' + @New_IsActive                 + ' | ';

            -- Remove trailing ' | ' safely without touching the value
			SET @TemplateBody = RTRIM(@TemplateBody);

			IF RIGHT(@TemplateBody, 3) = ' | '
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 3);
			ELSE IF RIGHT(@TemplateBody, 2) = ' |'
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 2);
			ELSE IF RIGHT(@TemplateBody, 1) = '|'
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 1);
        END
        ELSE
        BEGIN
            SET @TemplateCode = 'AddAircraftMaintenance';
			SET @Activity     = 'New Maintenance Added';

			SET @ProgramIdStr = 'Program ID: ' + CAST(ISNULL(@ProgramId, 0) AS VARCHAR(20));

			-- Build body directly from all non-empty CREATE values
			SET @TemplateBody = '';

			IF ISNULL(@New_MaintenanceType,'')          <> ''
				SET @TemplateBody += 'Maintenance Type: '     + @New_MaintenanceType          + ' | ';

			IF ISNULL(@New_NextScheduledMaintenance,'') <> ''
				SET @TemplateBody += 'Next Scheduled: '       + @New_NextScheduledMaintenance + ' | ';

			IF @New_FlightHours <> '0 : 00'
				SET @TemplateBody += 'Flight Hours (HH:MM): ' + @New_FlightHours              + ' | ';

			IF CAST(ISNULL(@New_CyclesLimit,'0') AS BIGINT) > 0
				SET @TemplateBody += 'Cycles Limit: '         + @New_CyclesLimit              + ' | ';

			IF CAST(ISNULL(@New_TimeLimit,'0') AS BIGINT) > 0
				SET @TemplateBody += 'Time Limit: '           + @New_TimeLimit                + ' | ';

			IF CAST(ISNULL(@New_LandingsLimit,'0') AS BIGINT) > 0
				SET @TemplateBody += 'Landings Limit: '       + @New_LandingsLimit            + ' | ';

			IF CAST(ISNULL(@New_EngineStartsLimit,'0') AS BIGINT) > 0
				SET @TemplateBody += 'Engine Starts Limit: '  + @New_EngineStartsLimit        + ' | ';

			-- Remove trailing ' | ' safely without touching the value
			SET @TemplateBody = RTRIM(@TemplateBody);

			IF RIGHT(@TemplateBody, 3) = ' | '
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 3);
			ELSE IF RIGHT(@TemplateBody, 2) = ' |'
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 2);
			ELSE IF RIGHT(@TemplateBody, 1) = '|'
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 1);
        END

        -- Call usp_SaveAircraftHistory once
        IF ISNULL(LTRIM(RTRIM(@TemplateBody)), '') <> ''
        BEGIN
			
			EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 2,@ModuleName = 'Aircraft Maintenance',@RefferenceId = @AircraftRegistryId,@FieldsName = NULL,
												 @OldValue = NULL,@NewValue = @ProgramIdStr,@HistoryText = @TemplateBody,@Activity = @Activity,@MasterCompanyId = @MasterCompanyId,
												 @CreatedBy = @CreatedBy;
        END
        -- ── END HISTORY BLOCK ─────────────────────────────────

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'ROLLBACK';
            ROLLBACK TRAN;
        END

        DECLARE @ErrorLogID             INT,
                @DatabaseName           VARCHAR(100) = DB_NAME(),
                @AdhocComments          VARCHAR(150) = 'USP_CreateUpdateAircraftMaintenanceProgram',
                @ProcedureParameters    VARCHAR(3000) =
                    '@Parameter1 = ''' + ISNULL(CAST(@ProgramId           AS VARCHAR), '') + ''',' +
                    '@Parameter2 = ''' + ISNULL(CAST(@AircraftRegistryId  AS VARCHAR), '') + ''',' +
                    '@Parameter3 = ''' + ISNULL(CAST(@MaintenanceTypeId   AS VARCHAR), '') + ''',' +
                    '@Parameter4 = ''' + ISNULL(CAST(@TemplateId          AS VARCHAR), '') + ''',' +
                    '@Parameter5 = ''' + ISNULL(CAST(@MasterCompanyId     AS VARCHAR), '') + ''',' +
                    '@Parameter6 = ''' + ISNULL(CAST(@IsVersionIncrease   AS VARCHAR), '') + '''',
                @ApplicationName        VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END