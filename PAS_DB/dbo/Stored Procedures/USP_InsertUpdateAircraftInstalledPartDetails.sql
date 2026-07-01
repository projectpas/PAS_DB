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
 **  3   04-15-2026   Amit Ghediya      Added for AircraftTailNumber in stockline selected.
 **  4   04-21-2026   Amit Ghediya      Added for SequenceNum. (PN-16146)
 **  5   04-23-2026   Amit Ghediya      Added item cycle data with PartFlightMinutes. (PN-16162)
 **  5   05-12-2026   Amit Ghediya      Added item InstallFlightHours,InstalledTime,InstalledCycles,. (PN-16382)
 **  6   05-15-2026   Abhishek Jirawla  Added Tail Number in Params. (PN-16384)
 **  7   09/06/2026   Amit Ghediya		Adding Header data in History module [PN-16581]
 **  8   30/06/2026	  Amit Ghediya	    Update for Engine data [PN-17075]
 ************************************************************************/
CREATE    PROCEDURE [dbo].[USP_InsertUpdateAircraftInstalledPartDetails]
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
	@Quantity DECIMAL(18,6) = NULL,
	@SequenceNum BIGINT,
	@PartFlightHours DECIMAL(18,6) = NULL,
	@PartFlightMinutes DECIMAL(18,6) = NULL,
	@PartCycles DECIMAL(18,6) = NULL,
	@PartLandings DECIMAL(18,6) = NULL,
	@PartEngineStarts DECIMAL(18,6) = NULL,
	@TailNumber VARCHAR(30) = NULL,
	@InstallFlightHours DECIMAL(18,6) = NULL,
	@InstallFlightTime DECIMAL(18,6) = NULL,
	@InstallCycles DECIMAL(18,6) = NULL,
	@IsFromAircraft BIT = NULL
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION;

		DECLARE @AircraftPartDetailsId BIGINT = 0,
				@ConditionId BIGINT = 0,
				@OldStockLineId BIGINT = 0,
				@IsUpdate       INT    = 0;

		-- ── OLD value holders ─────────────────────────────────
        DECLARE @Old_ATAChapterId       VARCHAR(256),
                @Old_SequenceNum        VARCHAR(256),
                @Old_PartNumber         VARCHAR(256),
                @Old_PartDescription    NVARCHAR(MAX),
                @Old_IsLLP              VARCHAR(5),
                @Old_IsSerialized       VARCHAR(5),
                @Old_SerialNumber       VARCHAR(256),
                @Old_DateInstalled      VARCHAR(256),
                @Old_PositionCode       VARCHAR(256),
                @Old_Quantity           VARCHAR(256),
                @Old_StockLine          VARCHAR(256),
                @Old_EngineStarts       VARCHAR(256),
                @Old_Memo               NVARCHAR(MAX),
                @Old_PartFlightHours    VARCHAR(256),
                @Old_PartFlightMinutes  VARCHAR(256),
                @Old_PartCycles         VARCHAR(256),
                @Old_PartLandings       VARCHAR(256),
                @Old_PartEngineStarts   VARCHAR(256),
                @Old_InstallFlightHours VARCHAR(256),
                @Old_InstallFlightTime  VARCHAR(256),
                @Old_InstallCycles      VARCHAR(256),
				@Old_StockLineId_Hist BIGINT = 0;

        -- ── NEW value holders ─────────────────────────────────
        DECLARE @New_ATAChapterId       VARCHAR(256),
                @New_SequenceNum        VARCHAR(256),
                @New_PartNumber         VARCHAR(256),
                @New_PartDescription    NVARCHAR(MAX),
                @New_IsLLP              VARCHAR(5),
                @New_IsSerialized       VARCHAR(5),
                @New_SerialNumber       VARCHAR(256),
                @New_DateInstalled      VARCHAR(256),
                @New_PositionCode       VARCHAR(256),
                @New_Quantity           VARCHAR(256),
                @New_StockLine          VARCHAR(256),
                @New_EngineStarts       VARCHAR(256),
                @New_Memo               NVARCHAR(MAX),
                @New_PartFlightHours    VARCHAR(256),
                @New_PartFlightMinutes  VARCHAR(256),
                @New_PartCycles         VARCHAR(256),
                @New_PartLandings       VARCHAR(256),
                @New_PartEngineStarts   VARCHAR(256),
                @New_InstallFlightHours VARCHAR(256),
                @New_InstallFlightTime  VARCHAR(256),
                @New_InstallCycles      VARCHAR(256);

		--GET AC Details
		IF(ISNULL(@IsFromAircraft,0) = 1)
		BEGIN
			IF(ISNULL(@TailNumber,'') != '')
			BEGIN
				 SELECT @AircraftRegistryId = AircraftRegistryId
				 FROM dbo.AircraftRegistryHeader WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(TailNum))) = UPPER(LTRIM(RTRIM(@TailNumber)))
			END

			-- Get TailNum
			SELECT @TailNumber = [TailNum] FROM DBO.AircraftRegistryHeader WITH(NOLOCK) WHERE [AircraftRegistryId] = @AircraftRegistryId;
		END
		ELSE
		BEGIN
			IF(ISNULL(@TailNumber,'') != '')
			BEGIN
				 SELECT @AircraftRegistryId = EngineRegistryId
				 FROM dbo.EngineRegistryHeader WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(TailNum))) = UPPER(LTRIM(RTRIM(@TailNumber)))
			END

			-- Get TailNum
			SELECT @TailNumber = [TailNum] FROM DBO.EngineRegistryHeader WITH(NOLOCK) WHERE [EngineRegistryId] = @AircraftRegistryId;
		END

		

		-- CHECK IF RECORD EXISTS
		IF EXISTS (
			SELECT 1 
			FROM DBO.AircraftInstalledPartDetails WITH(NOLOCK)
			WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId
		)
		BEGIN
			-- STEP 1: Read OLD values BEFORE update
            SELECT
                @Old_ATAChapterId       = CAST(ISNULL( CONCAT_WS(' - ',
										   NULLIF(IMAM.Level1, ''),
										   NULLIF(IMAM.Level2, ''),
										   NULLIF(IMAM.Level3, '')
									   ), 0)               AS VARCHAR),
                @Old_SequenceNum        = CAST(ISNULL(AIP.SequenceNum, 0)                AS VARCHAR),
                @Old_PartNumber         = ISNULL(AIP.PartNumber, ''),
                @Old_PartDescription    = ISNULL(AIP.PartDescription, ''),
                @Old_IsLLP              = CASE WHEN AIP.IsLLP = 1 THEN 'Yes' ELSE 'No' END,
                @Old_IsSerialized       = CASE WHEN AIP.IsSerialized = 1 THEN 'Yes' ELSE 'No' END,
                @Old_SerialNumber       = ISNULL(AIP.SerialNumber, ''),
                @Old_DateInstalled      = ISNULL(CONVERT(VARCHAR(10), CAST(AIP.DateInstalled AS DATE), 103), ''),
                @Old_PositionCode       = ISNULL(AIP.PositionCode, ''),
                @Old_Quantity           = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIP.Quantity,0))),--CAST(ISNULL(Quantity, 0)                   AS VARCHAR),
			    @Old_StockLineId_Hist	= AIP.StockLineId,
                @Old_EngineStarts       = CAST(ISNULL(AIP.EngineStarts, 0)              AS VARCHAR),
                @Old_Memo               = ISNULL(AIP.Memo, ''),
				@Old_PartFlightHours    = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(PartFlightHours,   0)))
											+ ' : '
											+ RIGHT('00' + CONVERT(VARCHAR(2), CONVERT(BIGINT, ISNULL(AIP.PartFlightMinutes,  0))), 2),
				@Old_PartFlightMinutes  = NULL,
				@Old_PartCycles         = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIP.PartCycles,         0))),
				@Old_PartLandings       = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIP.PartLandings,       0))),
				@Old_PartEngineStarts   = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIP.PartEngineStarts,   0))),
				@Old_InstallFlightHours = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIP.InstallFlightHours, 0)))
										+ ' : '
										+ RIGHT('00' + CONVERT(VARCHAR(2), CONVERT(BIGINT, ISNULL(AIP.InstallFlightTime,   0))), 2),
				@Old_InstallFlightTime  = NULL, 
				@Old_InstallCycles      = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(AIP.InstallCycles,      0)))
            FROM DBO.AircraftInstalledPartDetails AIP WITH(NOLOCK)
			LEFT JOIN dbo.ItemMasterAircraftMapping IMAM WITH(NOLOCK) ON IMAM.ItemMasterAircraftMappingId = AIP.ATAChapterId
            WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId;

			SELECT @Old_StockLine = ISNULL(StockLineNumber, '')  FROM dbo.StockLine WITH(NOLOCK)
			WHERE StockLineId = @Old_StockLineId_Hist;	

			-- Remove from stockline table
			IF(ISNULL(@StockLineId,0) = 0)
			BEGIN
				 SELECT @OldStockLineId = [StockLineId] FROM DBO.AircraftInstalledPartDetails WITH(NOLOCK) WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId;

				 UPDATE [dbo].[Stockline] SET [AircraftInstalledPartDetailsId] = 0, [AircraftTailNumber] = NULL WHERE [StockLineId] = @OldStockLineId;
			END

			-- UPDATE
			UPDATE DBO.AircraftInstalledPartDetails
			SET
				ATAChapterId = @ATAChapterId,
				SequenceNum = @SequenceNum,
				PartNumber = @PartNumber,
				PartDescription = @PartDescription,
				IsLLP = @IsLLP,
				IsSerialized = @IsSerialized,
				DateInstalled = @DateInstalled,
				PositionCodeId = @PositionCodeId,
				PositionCode = @PositionCode,
				Quantity = @Quantity,
				[StockLineId] = @StockLineId,
				EngineStarts = @EngineStarts,
				Memo = @Memo,
				MasterCompanyId = @MasterCompanyId,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE(),
				PartFlightHours = @PartFlightHours,
				PartFlightMinutes = @PartFlightMinutes,
				PartCycles = @PartCycles,
				PartLandings = @PartLandings,
				PartEngineStarts = @PartEngineStarts,
				InstallFlightHours = @InstallFlightHours,
				InstallFlightTime = @InstallFlightTime,
				InstallCycles = @InstallCycles
			WHERE AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId;
			
			--Update stockline for part
			IF(ISNULL(@StockLineId,0) > 0)
			BEGIN
				 UPDATE [dbo].[Stockline] SET [AircraftInstalledPartDetailsId] = @AircraftInstalledPartDetailsId, [AircraftTailNumber] = @TailNumber WHERE [StockLineId] = @StockLineId;

				 SELECT @ConditionId = [ConditionId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

				 UPDATE [dbo].[AircraftInstalledPartDetails] SET [StockLineId] = @StockLineId,[ConditionId] = @ConditionId WHERE [AircraftInstalledPartDetailsId] = @AircraftInstalledPartDetailsId;
			END

			SET  @IsUpdate = 1;
		END
		ELSE
		BEGIN
			-- INSERT
			INSERT INTO AircraftInstalledPartDetails
			(
				AircraftRegistryId,
				EngineRegistryId,
				IsFromAircraft,
				ATAChapterId,
				SequenceNum,
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
				IsDeleted,
				PartFlightHours,
				PartFlightMinutes,
				PartCycles,
				PartLandings,
				PartEngineStarts,
				InstallFlightHours,
				InstallFlightTime,
				InstallCycles
			)
			VALUES
			(
				@AircraftRegistryId,
				CASE WHEN ISNULL(@IsFromAircraft,0) = 1 THEN NULL ELSE  @AircraftRegistryId END,
				CASE WHEN ISNULL(@IsFromAircraft,0) = 1 THEN 1 ELSE  0 END,
				@ATAChapterId,
				@SequenceNum,
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
				0,
				@PartFlightHours,
				@PartFlightMinutes,
				@PartCycles,
				@PartLandings,
				@PartEngineStarts,
				@InstallFlightHours,
				@InstallFlightTime,
				@InstallCycles
			);

			SELECT @AircraftPartDetailsId = SCOPE_IDENTITY() 

			--Add stockline for part
			IF(ISNULL(@StockLineId,0) > 0)
			BEGIN
				 UPDATE [dbo].[Stockline] SET [AircraftInstalledPartDetailsId] = @AircraftPartDetailsId, [AircraftTailNumber] = @TailNumber WHERE [StockLineId] = @StockLineId;

				 SELECT @ConditionId = [ConditionId] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

				 UPDATE [dbo].[AircraftInstalledPartDetails] SET [StockLineId] = @StockLineId,[ConditionId] = @ConditionId WHERE [AircraftInstalledPartDetailsId] = @AircraftPartDetailsId;
			END
		END
		COMMIT TRANSACTION;

		-- ══════════════════════════════════════════════════════
        -- HISTORY BLOCK
        -- ══════════════════════════════════════════════════════
        DECLARE @TemplateBody   VARCHAR(MAX) = '',
                @Activity       VARCHAR(100) = NULL,
                @PartIdStr      VARCHAR(50)  = NULL,
				@ATAChapter     VARCHAR(100) = NULL;

		SELECT @New_StockLine = ISNULL(StockLineNumber, '')  FROM dbo.StockLine WITH(NOLOCK) WHERE StockLineId = ISNULL(@StockLineId, 0);

		SELECT @ATAChapter = CONCAT_WS(' - ',
				   NULLIF(IMAM.Level1, ''),
				   NULLIF(IMAM.Level2, ''),
				   NULLIF(IMAM.Level3, '')
			   )  FROM dbo.ItemMasterAircraftMapping IMAM WITH(NOLOCK) WHERE ItemMasterAircraftMappingId = ISNULL(@ATAChapterId, 0);

        -- Build NEW value strings from params
        SET @New_ATAChapterId       = CAST(ISNULL(@ATAChapter, 0)                                             AS VARCHAR);
        SET @New_SequenceNum        = CAST(ISNULL(@SequenceNum, 0)                                              AS VARCHAR);
        SET @New_PartNumber         = ISNULL(@PartNumber, '');
        SET @New_PartDescription    = ISNULL(@PartDescription, '');
        SET @New_IsLLP              = CASE WHEN @IsLLP = 1 THEN 'Yes' ELSE 'No' END;
        SET @New_IsSerialized       = CASE WHEN @IsSerialized = 1 THEN 'Yes' ELSE 'No' END;
        SET @New_SerialNumber       = ISNULL(@SerialNumber, '');
        SET @New_DateInstalled      = ISNULL(CONVERT(VARCHAR(10), CAST(@DateInstalled AS DATE), 103), '');
        SET @New_PositionCode       = ISNULL(@PositionCode, '');
        SET @New_Quantity           = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(@Quantity, 0)));--CAST(ISNULL(@Quantity, 0)                                                 AS VARCHAR);
        SET @New_EngineStarts       = CAST(ISNULL(@EngineStarts, 0)                                            AS VARCHAR);
        SET @New_Memo               = ISNULL(@Memo, '');
		SET @New_PartFlightHours    = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(@PartFlightHours,   0)))
										+ ' : '
										+ RIGHT('00' + CONVERT(VARCHAR(2), CONVERT(BIGINT, ISNULL(@PartFlightMinutes,  0))), 2);
		SET @New_PartFlightMinutes  = NULL;
		SET @New_PartCycles         = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(@PartCycles,         0)));
		SET @New_PartLandings       = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(@PartLandings,       0)));
		SET @New_PartEngineStarts   = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(@PartEngineStarts,   0)));
		SET @New_InstallFlightHours = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(@InstallFlightHours, 0)))
										+ ' : '
										+ RIGHT('00' + CONVERT(VARCHAR(2), CONVERT(BIGINT, ISNULL(@InstallFlightTime,   0))), 2);
		SET @New_InstallFlightTime  = NULL;
		SET @New_InstallCycles      = CONVERT(VARCHAR(20), CONVERT(BIGINT, ISNULL(@InstallCycles,      0)));

        -- ── UPDATE: only changed fields ───────────────────────
        IF @IsUpdate = 1
        BEGIN
            SET @Activity = 'Installed Component Updated';

            IF ISNULL(@Old_ATAChapterId,'0')      <> @New_ATAChapterId      AND @New_ATAChapterId      <> '0'
                SET @TemplateBody += 'ATA Chapter: '          + @Old_ATAChapterId      + ' to ' + @New_ATAChapterId      + ' | ';

            IF ISNULL(@Old_SequenceNum,'0')        <> @New_SequenceNum        AND @New_SequenceNum        <> '0'
                SET @TemplateBody += 'Sequence Num.: '        + @Old_SequenceNum        + ' to ' + @New_SequenceNum        + ' | ';

            IF ISNULL(@Old_PartNumber,'')          <> @New_PartNumber          AND @New_PartNumber          <> ''
                SET @TemplateBody += 'Part Number: '          + @Old_PartNumber          + ' to ' + @New_PartNumber          + ' | ';

            IF ISNULL(@Old_PartDescription,'')     <> @New_PartDescription     AND @New_PartDescription     <> ''
                SET @TemplateBody += 'Part Description: '     + @Old_PartDescription     + ' to ' + @New_PartDescription     + ' | ';

            IF ISNULL(@Old_IsLLP,'')               <> @New_IsLLP
                SET @TemplateBody += 'LLP: '                  + @Old_IsLLP               + ' to ' + @New_IsLLP               + ' | ';

            IF ISNULL(@Old_IsSerialized,'')        <> @New_IsSerialized
                SET @TemplateBody += 'Serialized: '           + @Old_IsSerialized        + ' to ' + @New_IsSerialized        + ' | ';

            IF ISNULL(@Old_SerialNumber,'')        <> @New_SerialNumber        AND @New_SerialNumber        <> ''
                SET @TemplateBody += 'Serial Number: '        + @Old_SerialNumber        + ' to ' + @New_SerialNumber        + ' | ';

            IF ISNULL(@Old_DateInstalled,'')       <> @New_DateInstalled       AND @New_DateInstalled       <> ''
                SET @TemplateBody += 'Date Installed: '       + @Old_DateInstalled       + ' to ' + @New_DateInstalled       + ' | ';

            IF ISNULL(@Old_PositionCode,'')        <> @New_PositionCode        AND @New_PositionCode        <> ''
                SET @TemplateBody += 'Position Code: '        + @Old_PositionCode        + ' to ' + @New_PositionCode        + ' | ';

            IF ISNULL(@Old_Quantity,'0')           <> @New_Quantity            AND @New_Quantity            <> '0'
                SET @TemplateBody += 'Quantity: '             + @Old_Quantity            + ' to ' + @New_Quantity            + ' | ';

			IF ISNULL(@Old_StockLine,'') <> ISNULL(@New_StockLine,'') AND ISNULL(@New_StockLine,'') <> ''
                SET @TemplateBody += 'Stock Line: '           + @Old_StockLine         + ' to ' + @New_StockLine         + ' | ';

            IF ISNULL(@Old_EngineStarts,'0')       <> @New_EngineStarts        AND @New_EngineStarts        <> '0'
                SET @TemplateBody += 'Engine Starts: '        + @Old_EngineStarts        + ' to ' + @New_EngineStarts        + ' | ';

            IF ISNULL(@Old_Memo,'')                <> @New_Memo                AND @New_Memo                <> ''
                SET @TemplateBody += 'Memo: '                 + @Old_Memo                + ' to ' + @New_Memo                + ' | ';

			IF ISNULL(@Old_PartFlightHours,'0 : 00')  <> @New_PartFlightHours  AND @New_PartFlightHours  <> '0 : 00'
				SET @TemplateBody += 'Part Flight Hours (HH:MM): '    + @Old_PartFlightHours  + ' to ' + @New_PartFlightHours  + ' | ';			

            IF ISNULL(@Old_PartCycles,'0')         <> @New_PartCycles          AND @New_PartCycles          <> '0'
                SET @TemplateBody += 'Part Cycles: '          + @Old_PartCycles          + ' to ' + @New_PartCycles          + ' | ';

            IF ISNULL(@Old_PartLandings,'0')       <> @New_PartLandings        AND @New_PartLandings        <> '0'
                SET @TemplateBody += 'Part Landings: '        + @Old_PartLandings        + ' to ' + @New_PartLandings        + ' | ';

            IF ISNULL(@Old_PartEngineStarts,'0')   <> @New_PartEngineStarts    AND @New_PartEngineStarts    <> '0'
                SET @TemplateBody += 'Part Engine Starts: '   + @Old_PartEngineStarts    + ' to ' + @New_PartEngineStarts    + ' | ';

			IF ISNULL(@Old_InstallFlightHours,'0 : 00') <> @New_InstallFlightHours AND @New_InstallFlightHours <> '0 : 00'
				SET @TemplateBody += 'Install Flight Hours (HH:MM): ' + @Old_InstallFlightHours + ' to ' + @New_InstallFlightHours + ' | ';

            IF ISNULL(@Old_InstallCycles,'0')      <> @New_InstallCycles       AND @New_InstallCycles       <> '0'
                SET @TemplateBody += 'Install Cycles: '       + @Old_InstallCycles       + ' to ' + @New_InstallCycles       + ' | ';

            -- Remove trailing ' | ' safely without touching the value
			SET @TemplateBody = RTRIM(@TemplateBody);

			IF RIGHT(@TemplateBody, 3) = ' | '
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 3);
			ELSE IF RIGHT(@TemplateBody, 2) = ' |'
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 2);
			ELSE IF RIGHT(@TemplateBody, 1) = '|'
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 1);
        END

        -- ── CREATE: all non-empty values ──────────────────────
        ELSE
        BEGIN
            SET @Activity = 'Installed Component Added';

			SET @PartIdStr = 'Installed Component Part: ' + CAST(ISNULL(@PartNumber, 0) AS VARCHAR(20));

            IF @New_ATAChapterId      <> '0' SET @TemplateBody += 'ATA Chapter: '          + @New_ATAChapterId      + ' | ';
            IF @New_SequenceNum       <> '0' SET @TemplateBody += 'Sequence Num.: '        + @New_SequenceNum       + ' | ';
            IF @New_PartNumber        <> ''  SET @TemplateBody += 'Part Number: '          + @New_PartNumber        + ' | ';
            IF @New_PartDescription   <> ''  SET @TemplateBody += 'Part Description: '     + @New_PartDescription   + ' | ';
                                             SET @TemplateBody += 'LLP: '                  + @New_IsLLP             + ' | ';
                                             SET @TemplateBody += 'Serialized: '           + @New_IsSerialized      + ' | ';
            IF @New_SerialNumber      <> ''  SET @TemplateBody += 'Serial Number: '        + @New_SerialNumber      + ' | ';
            IF @New_DateInstalled     <> ''  SET @TemplateBody += 'Date Installed: '       + @New_DateInstalled     + ' | ';
            IF @New_PositionCode      <> ''  SET @TemplateBody += 'Position Code: '        + @New_PositionCode      + ' | ';
            IF @New_Quantity          <> '0' SET @TemplateBody += 'Quantity: '             + @New_Quantity          + ' | ';
            IF @New_StockLine         <> '0' SET @TemplateBody += 'Stock Line: '           + @New_StockLine       + ' | ';
            IF @New_EngineStarts      <> '0' SET @TemplateBody += 'Engine Starts: '        + @New_EngineStarts      + ' | ';
            IF @New_PartFlightHours   <> '0' SET @TemplateBody += 'Part Flight Hours (HH:MM): '    + @New_PartFlightHours   + ' | ';
            IF @New_PartCycles        <> '0' SET @TemplateBody += 'Part Cycles: '          + @New_PartCycles        + ' | ';
            IF @New_PartLandings      <> '0' SET @TemplateBody += 'Part Landings: '        + @New_PartLandings      + ' | ';
            IF @New_PartEngineStarts  <> '0' SET @TemplateBody += 'Part Engine Starts: '   + @New_PartEngineStarts  + ' | ';
            IF @New_InstallFlightHours <> '0' SET @TemplateBody += 'Install Flight Hours (HH:MM): '+ @New_InstallFlightHours + ' | ';
            IF @New_InstallCycles      <> '0' SET @TemplateBody += 'Install Cycles: '      + @New_InstallCycles      + ' | ';
            IF @New_Memo               <> ''  SET @TemplateBody += 'Memo: '                + @New_Memo               + ' | ';

            SET @TemplateBody += 'Created By: '  + ISNULL(@UpdatedBy, '')    + ' | ';
            SET @TemplateBody += 'Created Date: '+ CONVERT(VARCHAR(10), CAST(GETUTCDATE() AS DATE), 103);
        END

        -- Call usp_SaveAircraftHistory once
        IF ISNULL(LTRIM(RTRIM(@TemplateBody)), '') <> ''
        BEGIN
			EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 3,@ModuleName = 'Installed Components',@RefferenceId = @AircraftRegistryId,@FieldsName = NULL,
												 @OldValue = NULL,@NewValue = @PartIdStr,@HistoryText = @TemplateBody,@Activity = @Activity,@MasterCompanyId = @MasterCompanyId,
												 @CreatedBy = @UpdatedBy;
        END
        -- ── END HISTORY BLOCK ─────────────────────────────────

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