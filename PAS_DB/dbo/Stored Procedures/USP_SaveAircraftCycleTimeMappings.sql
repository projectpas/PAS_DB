/*************************************************************     
** Author:  <Amit Ghediya>    
** Create date: <14/04/2026>    
** Description: <This Proc Is used to Same Turn In Aircraft CycleTime>    
    
Exec [USP_SaveAircraftCycleTimeMappings]   
**************************************************************   
** Change History   
**************************************************************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
   1    14/04/2026  Amit Ghediya		Created  
   2	15/04/2026  Amit Ghediya		Added into AircraftMaintenanceProgram table (PN-16015)
   3	21/04/2026  Amit Ghediya		Stop insert into AircraftMaintenanceProgram table update logic to save data.
   4	22/04/2026  Amit Ghediya		Add DateInstalled Last Flown Date (PN-16156).
   5    28/04/2026  Amit Ghediya		Get Minutes related data (PN-16151)
   6	04/05/2026  Amit Ghediya		revert insert into AircraftMaintenanceProgram table update logic to save data.
   7    07/05/2026	Priyansh Patel		Fixed the Remaining time calculation [PN-16306]
   8    07/05/2026  Abhishek Jirawla	Edit Last flown date only when add cycle time is done.
   9    14/05/2026  Amit Ghediya		Update logic for AircraftMaintenanceProgram & LastFlownDate [PN-16428].
   10   27/05/2026  Priyansh Patel		Update logic for Remaining Cycles [PN-16587].
     
**************************************************************/   
create PROCEDURE [dbo].[USP_SaveAircraftCycleTimeMappings]  
	 @CycleData NVARCHAR(MAX),
     @EngineData NVARCHAR(MAX)
AS  
BEGIN  
   
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
   BEGIN TRY 
   BEGIN TRANSACTION  
    BEGIN 

		DECLARE @CycleId BIGINT;
		DECLARE @AircraftEngineStartsMappingsId BIGINT,
				@AircraftCycleTimeMappingsId BIGINT,
				@EngineName VARCHAR(50),
				@Hours DECIMAL(18,6),
				@Minutes DECIMAL(18,6),
				@CurruntHours DECIMAL(18,6),
				@CurruntMinutes DECIMAL(18,6),
				@CumulativeHours DECIMAL(18,6),
				@CumulativeMinutes DECIMAL(18,6),
				@Starts INT,
				@CurruntStarts INT,
				@CumulativeStarts INT,
				@Memo NVARCHAR(MAX),
				@MasterCompanyId INT,
				@CreatedBy VARCHAR(256),
				@UpdatedBy VARCHAR(256),
				@ProgramId BIGINT = 0;

        -------------------------------------------------------
        -- READ JSON INTO TEMP TABLE
        -------------------------------------------------------
        DECLARE @CycleTable TABLE
        (
            AircraftCycleTimeMappingsId BIGINT,
            ModuleId BIGINT,
            RefrenceId BIGINT,
            CycleDate DATETIME2,
            [Hours] DECIMAL(18,6),
			[Minutes] DECIMAL(18,6),
            CurruntHours DECIMAL(18,6),
			CurruntMinutes DECIMAL(18,6),
            CumulativeHours DECIMAL(18,6),
			CumulativeMinutes DECIMAL(18,6),
            Cycles DECIMAL(18,6),
			CyclesMinutes DECIMAL(18,6),
            CurruntCycles DECIMAL(18,6),
			CurruntCyclesMinutes DECIMAL(18,6),
            CumulativeCycles DECIMAL(18,6),
			CumulativeCyclesMinutes DECIMAL(18,6),
			AddUpdated BIT,
            Memo NVARCHAR(MAX),
            MasterCompanyId INT,
            CreatedBy VARCHAR(256),
            UpdatedBy VARCHAR(256)
        );

        INSERT INTO @CycleTable
        SELECT *
        FROM OPENJSON(@CycleData)
        WITH
        (
            AircraftCycleTimeMappingsId BIGINT,
            ModuleId BIGINT,
            RefrenceId BIGINT,
            CycleDate DATETIME2,
            [Hours] DECIMAL(18,6),
			[Minutes] DECIMAL(18,6),
            CurruntHours DECIMAL(18,6),
			CurruntMinutes DECIMAL(18,6),
            CumulativeHours DECIMAL(18,6),
			CumulativeMinutes DECIMAL(18,6),
            Cycles DECIMAL(18,6),
			CyclesMinutes DECIMAL(18,6),
            CurruntCycles DECIMAL(18,6),
			CurruntCyclesMinutes DECIMAL(18,6),
            CumulativeCycles DECIMAL(18,6),
			CumulativeCyclesMinutes DECIMAL(18,6),
			AddUpdated BIT,
            Memo NVARCHAR(MAX),
            MasterCompanyId INT,
            CreatedBy VARCHAR(256),
            UpdatedBy VARCHAR(256)
        );

        -------------------------------------------------------
        -- CHECK INSERT OR UPDATE
        -------------------------------------------------------
        IF EXISTS (SELECT 1 FROM @CycleTable WHERE ISNULL(AircraftCycleTimeMappingsId,0) > 0)
        BEGIN
            ---------------------------------------------------
            -- UPDATE
            ---------------------------------------------------
            UPDATE A
            SET
                A.ModuleId = C.ModuleId,
                A.RefrenceId = C.RefrenceId,
                A.CycleDate = C.CycleDate,
                A.Hours = C.Hours,
				A.Minutes = C.Minutes,
                A.CurruntHours = C.CurruntHours,
				A.CurruntMinutes = C.CurruntMinutes,
                A.CumulativeHours = C.CumulativeHours,
				A.CumulativeMinutes = C.CumulativeMinutes,
                A.Cycles = C.Cycles,
				A.CyclesMinutes = C.CyclesMinutes,				
                A.CurruntCycles = C.CurruntCycles,
				A.CurruntCyclesMinutes = C.CurruntCyclesMinutes,
                A.CumulativeCycles = C.CumulativeCycles,
				A.CumulativeCyclesMinutes = C.CumulativeCyclesMinutes,
                A.Memo = C.Memo,
                A.MasterCompanyId = C.MasterCompanyId,
                A.UpdatedBy = C.UpdatedBy,
                A.UpdatedDate = GETUTCDATE()
            FROM dbo.AircraftCycleTimeMappings A
            INNER JOIN @CycleTable C
                ON A.AircraftCycleTimeMappingsId = C.AircraftCycleTimeMappingsId;

            SELECT @CycleId = AircraftCycleTimeMappingsId FROM @CycleTable;
        END
        ELSE
        BEGIN
            ---------------------------------------------------
            -- INSERT
            ---------------------------------------------------
            INSERT INTO dbo.AircraftCycleTimeMappings
            (
                ModuleId,
                RefrenceId,
                CycleDate,
                [Hours],
				[Minutes],
                CurruntHours,
				CurruntMinutes,
                CumulativeHours,
				CumulativeMinutes,
                Cycles,
				CyclesMinutes,
                CurruntCycles,
				CurruntCyclesMinutes,
                CumulativeCycles,
				CumulativeCyclesMinutes,
                Memo,
                MasterCompanyId,
                CreatedBy,
                UpdatedBy,
                CreatedDate,
                UpdatedDate,
                IsActive,
                IsDeleted
            )
            SELECT
                ModuleId,
                RefrenceId,
                GETUTCDATE(),
                [Hours],
				[Minutes],
                CurruntHours,
				CurruntMinutes,
                CumulativeHours,
				CumulativeMinutes,
                Cycles,
				CyclesMinutes,
                CurruntCycles,
				CurruntCyclesMinutes,
                CumulativeCycles,
				CumulativeCyclesMinutes,
                Memo,
                MasterCompanyId,
                CreatedBy,
                UpdatedBy,
                GETUTCDATE(),
                GETUTCDATE(),
                1,
                0
            FROM @CycleTable;

            SET @CycleId = SCOPE_IDENTITY();
        END

		---------------------------------------------------
		-- UPDATE AircraftInstalledPartDetails (ADD values)
		---------------------------------------------------
		UPDATE AIPD
		SET 
			AIPD.FlightHours = ISNULL(AIPD.FlightHours, 0) + ISNULL(C.[Hours], 0),
			AIPD.FlightMinutes = ISNULL(AIPD.FlightMinutes, 0) + ISNULL(C.[Minutes], 0),
			AIPD.Cycles = ISNULL(AIPD.Cycles, 0) + ISNULL(C.[Cycles], 0),
			AIPD.UpdatedBy = C.UpdatedBy,
			AIPD.UpdatedDate = GETUTCDATE(),
			AIPD.LastFlownDate = CASE 
									WHEN ISNULL(C.AddUpdated, 0) = 1 
									THEN CAST(GETUTCDATE() AS DATE)
									ELSE AIPD.LastFlownDate
								 END
		FROM dbo.AircraftInstalledPartDetails AIPD WITH(NOLOCK)
		INNER JOIN @CycleTable C ON AIPD.AircraftRegistryId = C.RefrenceId;

		---------------------------------------------------
		-- INSERT INTO AircraftMaintenanceProgram
		---------------------------------------------------
		IF EXISTS (SELECT 1 FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK) INNER JOIN @CycleTable C ON AMP.AircraftRegistryId = C.RefrenceId)
		BEGIN
			--UPDATE AMP
			--	SET
			--		AMP.FlightHoursRecordedHours = FLOOR(ISNULL(C.CumulativeHours, 0)),
			--		AMP.FlightHoursRecordedMinutes = FLOOR(ISNULL(C.CumulativeMinutes, 0)),
			--		AMP.CyclesRecorded = ISNULL(C.CumulativeCycles, 0),
			--		AMP.FlightHoursRemainingHours = FLOOR(ISNULL(AMP.FlightHoursLimitHours, 0)) - FLOOR(ISNULL(C.CumulativeHours, 0)),
			--		AMP.FlightHoursRemainingMinutes = FLOOR(ISNULL(AMP.FlightHoursLimitMinutes, 0)) - FLOOR(ISNULL(C.CumulativeMinutes, 0)),
			--		AMP.CyclesRemaining = FLOOR(ISNULL(AMP.CyclesLimit, 0)) - ISNULL(C.CumulativeCycles, 0),
			--		AMP.[TimeRemaining] = FLOOR(ISNULL(AMP.TimeLimit, 0)) - 0,
			--		AMP.[LandingsRemaining] = FLOOR(ISNULL(AMP.LandingsLimit, 0)) - 0,
			--		AMP.[EngineStartsRemaining] = FLOOR(ISNULL(AMP.EngineStartsLimit, 0)) - 0,
			--		AMP.UpdatedBy = C.UpdatedBy,
			--		AMP.UpdatedDate = GETUTCDATE()
			--	FROM dbo.AircraftMaintenanceProgram AMP WITH(NOLOCK)
			--	INNER JOIN @CycleTable C ON AMP.AircraftRegistryId = C.RefrenceId;

			SET @ProgramId = (SELECT TOP 1 [ProgramId] FROM [dbo].[AircraftMaintenanceProgram] AMP WITH(NOLOCK)
							INNER JOIN @CycleTable C ON AMP.AircraftRegistryId = C.RefrenceId
							WHERE 
								[IsDeleted] = 0
								AND [IsActive] = 1
								AND [NextScheduledMaintenance] IS NOT NULL
								AND [NextScheduledMaintenance] >= CAST(GETDATE() AS DATE)
								AND [AircraftRegistryId] = AMP.AircraftRegistryId
							ORDER BY NextScheduledMaintenance ASC);


			-- Compute remaining minutes before UPDATE
			DECLARE @TotalRemainingMinutes INT = NULL;
			DECLARE @TotalRemainingCycles BIGINT = NULL;


			--SELECT @TotalRemainingMinutes =
			--	(ISNULL(AMP.FlightHoursLimitHours, 0) * 60 + ISNULL(AMP.FlightHoursLimitMinutes, 0))
			--	- (FLOOR(ISNULL(C.CumulativeHours, 0)) * 60 + FLOOR(ISNULL(C.CumulativeMinutes, 0)))
			--FROM dbo.AircraftMaintenanceProgram AMP
			--INNER JOIN @CycleTable C ON AMP.AircraftRegistryId = C.RefrenceId AND AMP.ProgramId = @ProgramId;
			SELECT @TotalRemainingMinutes =
				(ISNULL(AMP.FlightHoursLimitHours, 0) * 60 + ISNULL(AMP.FlightHoursLimitMinutes, 0))
				- (FLOOR(ISNULL(C.[Hours], 0)) * 60 + FLOOR(ISNULL(C.[Minutes], 0))),
				 @TotalRemainingCycles =  ISNULL(AMP.CyclesLimit, 0) - ISNULL(C.Cycles, 0)
			FROM dbo.AircraftMaintenanceProgram AMP
			INNER JOIN @CycleTable C ON AMP.AircraftRegistryId = C.RefrenceId AND AMP.ProgramId = @ProgramId;

			SET @TotalRemainingMinutes = CASE WHEN @TotalRemainingMinutes < 0 THEN 0 ELSE @TotalRemainingMinutes END;


			UPDATE AMP
			SET
				-- Recorded (safe)
				--AMP.FlightHoursRecordedHours = FLOOR(ISNULL(C.CumulativeHours, 0)),
				--AMP.FlightHoursRecordedMinutes = 
				--CASE 
				--	WHEN FLOOR(ISNULL(C.CumulativeMinutes, 0)) > 59 THEN 59
				--	WHEN FLOOR(ISNULL(C.CumulativeMinutes, 0)) < 0 THEN 0
				--	ELSE FLOOR(ISNULL(C.CumulativeMinutes, 0))
				--END,
				--AMP.CyclesRecorded = ISNULL(C.CumulativeCycles, 0),
				AMP.FlightHoursRecordedHours = FLOOR(ISNULL(AMP.FlightHoursRecordedHours, 0)) + FLOOR(ISNULL(C.[Hours], 0)),
				AMP.FlightHoursRecordedMinutes = FLOOR(ISNULL(AMP.FlightHoursRecordedMinutes, 0)) +
				CASE 
					WHEN FLOOR(ISNULL(C.[Minutes], 0)) > 59 THEN 59
					WHEN FLOOR(ISNULL(C.[Minutes], 0)) < 0 THEN 0
					ELSE FLOOR(ISNULL(C.[Minutes], 0))
				END,
				AMP.CyclesRecorded = ISNULL(AMP.CyclesRecorded, 0) + ISNULL(C.Cycles, 0),

				AMP.FlightHoursRemainingHours   = CASE WHEN @TotalRemainingMinutes IS NULL THEN NULL ELSE @TotalRemainingMinutes / 60 END,
				AMP.FlightHoursRemainingMinutes = CASE WHEN @TotalRemainingMinutes IS NULL THEN NULL ELSE @TotalRemainingMinutes % 60 END,
				AMP.CyclesRemaining = CASE WHEN @TotalRemainingCycles IS NULL THEN NULL  WHEN @TotalRemainingCycles < 0 THEN 0
				ELSE @TotalRemainingCycles END,

				--AMP.CyclesRemaining = CASE WHEN ISNULL(AMP.CyclesLimit, 0) - ISNULL(C.CumulativeCycles, 0) < 0 THEN 0 ELSE 
				--	ISNULL(AMP.CyclesLimit, 0) - ISNULL(C.CumulativeCycles, 0) END,

				AMP.TimeRemaining = ISNULL(AMP.TimeLimit, 0),
				AMP.LandingsRemaining = ISNULL(AMP.LandingsLimit, 0),
				AMP.EngineStartsRemaining = ISNULL(AMP.EngineStartsLimit, 0),

				AMP.UpdatedBy = C.UpdatedBy,
				AMP.UpdatedDate = GETUTCDATE()

			FROM dbo.AircraftMaintenanceProgram AMP
			INNER JOIN @CycleTable C ON AMP.AircraftRegistryId = C.RefrenceId
			AND AMP.ProgramId = @ProgramId;
		END
		ELSE
		BEGIN
			INSERT INTO dbo.AircraftMaintenanceProgram
			(
				TailNumber,
				AircraftMake,
				AircraftModel,
				SerialNumber,
				MaintenanceType,
				TemplateId,
				FlightHoursRecordedHours,
				FlightHoursRecordedMinutes,
				FlightHoursRemainingHours,
				FlightHoursRemainingMinutes,
				CyclesRemaining,
				CyclesRecorded,
				MasterCompanyId,
				CreatedBy,
				UpdatedBy,
				CreatedDate,
				UpdatedDate,
				IsActive,
				IsDeleted,
				AircraftRegistryId
			)
			SELECT
				'',
				'',
				'',
				'',
				'',
				1,
				FLOOR(ISNULL(C.CumulativeHours, 0)),
				FLOOR(ISNULL(C.CumulativeMinutes, 0)),
				FLOOR(ISNULL(C.CumulativeHours, 0)),
				FLOOR(ISNULL(C.CumulativeMinutes, 0)),
				ISNULL(C.CumulativeCycles, 0),
				ISNULL(C.CumulativeCycles, 0),
				C.MasterCompanyId,
				C.CreatedBy,
				C.UpdatedBy,
				GETUTCDATE(),
				GETUTCDATE(),
				1,
				0,
				C.RefrenceId
			FROM @CycleTable C;
		END

        -------------------------------------------------------
        -- INSERT ENGINE DATA
        -------------------------------------------------------
		DECLARE @EngineTable TABLE
		(
			AircraftEngineStartsMappingsId BIGINT,
			AircraftCycleTimeMappingsId BIGINT,
			EngineName VARCHAR(50),
			[Hours] DECIMAL(18,6),
			[Minutes] DECIMAL(18,6),
			CurruntHours DECIMAL(18,6),
			CurruntMinutes DECIMAL(18,6),
			CumulativeHours DECIMAL(18,6),
			CumulativeMinutes DECIMAL(18,6),
			Starts INT,
			CurruntStarts INT,
			CumulativeStarts INT,
			Memo NVARCHAR(MAX),
			MasterCompanyId INT,
			CreatedBy VARCHAR(256),
			UpdatedBy VARCHAR(256)
		);

		INSERT INTO @EngineTable
		SELECT
			AircraftEngineStartsMappingsId,
			AircraftCycleTimeMappingsId,
			EngineName,
			[Hours],
			[Minutes],
			CurruntHours,
			CurruntMinutes,
			CumulativeHours,
			CumulativeMinutes,
			Starts,
			CurruntStarts,
			CumulativeStarts,
			Memo,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy
		FROM OPENJSON(@EngineData)
		WITH
		(
			AircraftEngineStartsMappingsId BIGINT,
			AircraftCycleTimeMappingsId BIGINT,
			EngineName VARCHAR(50),
			[Hours] DECIMAL(18,6),
			[Minutes] DECIMAL(18,6),
			CurruntHours DECIMAL(18,6),
			CurruntMinutes DECIMAL(18,6),
			CumulativeHours DECIMAL(18,6),
			CumulativeMinutes DECIMAL(18,6),
			Starts INT,
			CurruntStarts INT,
			CumulativeStarts INT,
			Memo NVARCHAR(MAX),
			MasterCompanyId INT,
			CreatedBy VARCHAR(256),
			UpdatedBy VARCHAR(256)
		);

		DECLARE EngineCursor CURSOR FOR
		SELECT 
			AircraftEngineStartsMappingsId,
			AircraftCycleTimeMappingsId,
			EngineName,
			[Hours],
			[Minutes],
			CurruntHours,
			CurruntMinutes,
			CumulativeHours,
			CumulativeMinutes,
			Starts,
			CurruntStarts,
			CumulativeStarts,
			Memo,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy
		FROM @EngineTable;

		OPEN EngineCursor;

		FETCH NEXT FROM EngineCursor INTO @AircraftEngineStartsMappingsId,@AircraftCycleTimeMappingsId,
			@EngineName, @Hours, @Minutes, @CurruntHours, @CurruntMinutes, @CumulativeHours, @CumulativeMinutes,
			@Starts, @CurruntStarts, @CumulativeStarts,
			@Memo, @MasterCompanyId, @CreatedBy, @UpdatedBy;

		WHILE @@FETCH_STATUS = 0
		BEGIN

			IF EXISTS (
				SELECT 1 
				FROM dbo.AircraftEngineStartsMappings
				WHERE AircraftEngineStartsMappingsId = @AircraftEngineStartsMappingsId
				  AND EngineName = @EngineName
			)
			BEGIN
				---------------------------------------------------
				-- UPDATE
				---------------------------------------------------
				UPDATE dbo.AircraftEngineStartsMappings
				SET
					[Hours] = @Hours,
					[Minutes] = @Minutes,
					CurruntHours = @CurruntHours,
					CurruntMinutes = @CurruntMinutes,
					CumulativeHours = @CumulativeHours,
					CumulativeMinutes = @CumulativeMinutes,
					Starts = @Starts,
					CurruntStarts = @CurruntStarts,
					CumulativeStarts = @CumulativeStarts,
					Memo = @Memo,
					MasterCompanyId = @MasterCompanyId,
					UpdatedBy = @UpdatedBy,
					UpdatedDate = GETUTCDATE()
				WHERE AircraftEngineStartsMappingsId = @AircraftEngineStartsMappingsId
				  AND EngineName = @EngineName;
			END
			ELSE
			BEGIN
				---------------------------------------------------
				-- INSERT
				---------------------------------------------------
				INSERT INTO dbo.AircraftEngineStartsMappings
				(
					AircraftCycleTimeMappingsId,
					EngineName,
					[Hours],
					[Minutes],
					CurruntHours,
					CurruntMinutes,
					CumulativeHours,
					CumulativeMinutes,
					Starts,
					CurruntStarts,
					CumulativeStarts,
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
					@CycleId,
					@EngineName,
					@Hours,
					@Minutes,
					@CurruntHours,
					@CurruntMinutes,
					@CumulativeHours,
					@CumulativeMinutes,
					@Starts,
					@CurruntStarts,
					@CumulativeStarts,
					@Memo,
					@MasterCompanyId,
					@CreatedBy,
					@UpdatedBy,
					GETUTCDATE(),
					GETUTCDATE(),
					1,
					0
				);
			END

			FETCH NEXT FROM EngineCursor INTO @AircraftEngineStartsMappingsId,@AircraftCycleTimeMappingsId,
				@EngineName, @Hours, @Minutes, @CurruntHours, @CurruntMinutes, @CumulativeHours, @CumulativeMinutes,
				@Starts, @CurruntStarts, @CumulativeStarts,
				@Memo, @MasterCompanyId, @CreatedBy, @UpdatedBy;

		END

		CLOSE EngineCursor;
		DEALLOCATE EngineCursor;

        -------------------------------------------------------
        -- RETURN
        -------------------------------------------------------
        SELECT @CycleId AS AircraftCycleTimeMappingsId;

    END  
   COMMIT  TRANSACTION 
    END TRY        
 BEGIN CATCH
  IF @@trancount > 0    
   PRINT 'ROLLBACK'  
    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_SaveAircraftCycleTimeMappings'     
			, @ProcedureParameters VARCHAR(3000) = '@CycleData = ''' + CAST(ISNULL(@CycleData, '') AS VARCHAR(100))  
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);    
 END CATCH    
END