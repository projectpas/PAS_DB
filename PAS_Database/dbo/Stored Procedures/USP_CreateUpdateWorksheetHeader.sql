/*************************************************************             
 ** File:   [USP_CreateUpdateWorksheetHeader]          
 ** Author:   
 ** Description: This stored procedure is used to Create/Update a record in [WorksheetHeader].
 ** Purpose:           
 ** Date:  [14-May-2026] 
            
 ** PARAMETERS:             
 @tbl_WorksheetHeaderType WorksheetHeaderTableType     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date           Author                  Change Description              
 ** --   --------       -------                 --------------------------------     
    1    14/05/2026     Priyansh Patel          Created [PN-16408]
    2    19/05/2026     Priyansh Patel          Added Duplicate inspection fields [PN-16408]
    3    8/06/2026      Divyesh Kathiriya       Update WorksheetNumber on AircraftMaintenanceProgram Table [PN-16704]
    4    8/06/2026      Amit Ghediya            Adding Header data in History module [PN-16581]
    5    10/06/2026     Divyesh Kathiriya       Update WorksheetNumber on AircraftInstalledPartDetails Table [PN-16780]
	6    15/06/2026     Amit Ghediya			Added MtcCategoryId in WorksheetHeader Table [PN-16839]
    7    30/06/2026     Divyesh Kathiriya       Added WorkSheetStatusId fields [PN-16897]
	8    27/07/2026     Amit Ghediya			Added for mapping table WorksheetMapping for multiple ws. [PN-17396]

**************************************************************/

CREATE     PROCEDURE [dbo].[USP_CreateUpdateWorksheetHeader]
    @tbl_WorksheetHeaderType dbo.WorksheetHeaderTableType READONLY
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
    BEGIN TRY

		DECLARE @WorksheetHeaderId              BIGINT,
				@MasterCompanyId                INT,
				@AircraftRegistryId              BIGINT,
				@ProgramId                       BIGINT,
				@AircraftInstalledPartDetailsId  BIGINT,
				@IsFromAircraft                  BIT,
				@UpdatedBy                       VARCHAR(256);

		SELECT 
			@WorksheetHeaderId             = WorksheetHeaderId,
			@MasterCompanyId                = MasterCompanyId,
			@AircraftRegistryId             = AircraftRegistryId,
			@ProgramId                      = ProgramId,
			@AircraftInstalledPartDetailsId = AircraftInstalledPartDetailsId,
			@UpdatedBy						= UpdatedBy
		FROM @tbl_WorksheetHeaderType;

        DECLARE @CodePrefix         NVARCHAR(50);
        DECLARE @CodeSuffix         NVARCHAR(50);
        DECLARE @WorksheetNum       VARCHAR(50)  = NULL;
        DECLARE @CurrentNo          INT          = 0;

        DECLARE @TailNum            VARCHAR(50)  = NULL;
        DECLARE @SerialNum          VARCHAR(50)  = NULL;
        DECLARE @AircraftModelId    BIGINT  = NULL;
        DECLARE @MakeTypeId         BIGINT  = NULL;
        DECLARE @WorkSheetStatusId  INT     = 1;       

        DECLARE @WorksheetCodePrefix INT = (
            SELECT [CodeTypeId]
            FROM   [dbo].[CodeTypes] WITH (NOLOCK)
            WHERE  [CodeType] = 'WorksheetNumber'
        );

		-- ── NEW value holders ─────────────────────────────────
        DECLARE @New_MakeType                   VARCHAR(200),
                @New_AircraftModel              VARCHAR(200),
                @New_WorksheetType              VARCHAR(100),
				@New_TailNum                    VARCHAR(50),
				@New_SerialNum                  VARCHAR(100),
                @New_IsActive                   VARCHAR(10);

        SELECT TOP 1
            @CodePrefix = [CodePrefix],
            @CodeSuffix = [CodeSufix]
        FROM [dbo].[CodePrefixes] WITH (NOLOCK)
        WHERE  [IsActive]        = 1
          AND  [IsDeleted]       = 0
          AND  [CodeTypeId]      = @WorksheetCodePrefix
          AND  [MasterCompanyId] = @MasterCompanyId;

        -- -------------------------------------------------------
        -- VALIDATION: Duplicate TailNum / AircraftReg check
        -- -------------------------------------------------------
        IF EXISTS (
            SELECT 1
            FROM   dbo.WorksheetHeader WH WITH (NOLOCK)
            INNER JOIN @tbl_WorksheetHeaderType T
                ON  WH.AircraftReg       = T.AircraftReg
                AND WH.MasterCompanyId   = T.MasterCompanyId
                AND WH.IsDeleted         = 0
                AND WH.WorksheetHeaderId <> ISNULL(T.WorksheetHeaderId, 0)
        )
        BEGIN
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SELECT 0 AS Status, 'Aircraft Registration already exists for this company.' AS Message;
            RETURN;
        END
        ELSE
        BEGIN

            -- -------------------------------------------------------
            -- UPDATE existing record
            -- -------------------------------------------------------
            IF (ISNULL(@WorksheetHeaderId, 0) > 0)
            BEGIN
                UPDATE WH
                SET
                    WH.MakeTypeId                    = T.MakeTypeId,
                    WH.MakeType                      = T.MakeType,
                    WH.AircraftModelId               = T.AircraftModelId,
                    WH.AircraftModel                 = T.AircraftModel,
                    WH.WorksheetType                 = T.WorksheetType,
                    WH.WorksheetTypeId               = T.WorksheetTypeId,
                    WH.MtcCategoryId				 = T.MtcCategoryId,
                    WH.TailNum                      = T.TailNum,
                    WH.SerialNum                    = T.SerialNum,
                    WH.WorkOrderNo                   = T.WorkOrderNo,                    
                    WH.AFHours                       = T.AFHours,
                    WH.InspectionType                = T.InspectionType,
					WH.InspectionTypeId              = T.InspectionTypeId,
                    WH.InspectionDate                = T.InspectionDate,
                    WH.QualitySafetyDeptSignOutBy    = T.QualitySafetyDeptSignOutBy,
                    WH.QualitySafetyDeptSignOutDate  = T.QualitySafetyDeptSignOutDate,
                    WH.QualitySafetyDeptSignInBy     = T.QualitySafetyDeptSignInBy,
                    WH.QualitySafetyDeptSignInDate   = T.QualitySafetyDeptSignInDate,
                    WH.ReleaseToServiceBy            = T.ReleaseToServiceBy,
                    WH.ReleaseDate                   = T.ReleaseDate,
                    WH.ReleaseLicenseNumber          = T.ReleaseLicenseNumber,
                    WH.AMONumber                     = T.AMONumber,
                    WH.AircraftReg                   = T.AircraftReg,
                    WH.TechnicalRecordsWO            = T.TechnicalRecordsWO,
                    WH.CalmSysWO                     = T.CalmSysWO,
                    WH.CertificationStatement        = T.CertificationStatement,
                    WH.DupInspSysDescription        = T.DupInspSysDescription,
                    WH.DupInspDefectWorkNo          = T.DupInspDefectWorkNo,
                    WH.DupInspDate                  = T.DupInspDate,
                    WH.DupInspStation               = T.DupInspStation,
                    WH.DupInspSignatory1By          = T.DupInspSignatory1By,
                    WH.DupInspSignatory1LicAppNo    = T.DupInspSignatory1LicAppNo,
                    WH.DupInspSignatory1Time        = T.DupInspSignatory1Time,
                    WH.DupInspSignatory2By          = T.DupInspSignatory2By,
                    WH.DupInspSignatory2LicAppNo    = T.DupInspSignatory2LicAppNo,
                    WH.DupInspSignatory2Time        = T.DupInspSignatory2Time,
                    WH.AircraftInstalledPartDetailsId = T.AircraftInstalledPartDetailsId,
                    WH.ProgramId                    = T.ProgramId,
					WH.IsFromAircraft				= T.IsFromAircraft,
                    WH.AircraftRegistryId           = T.AircraftRegistryId,
					WH.EngineRegistryId				= T.EngineRegistryId,
                    WH.IsActive                      = ISNULL(T.IsActive,  WH.IsActive),
                    WH.IsDeleted                     = ISNULL(T.IsDeleted, WH.IsDeleted),
                    WH.UpdatedBy                     = T.UpdatedBy,
                    WH.UpdatedDate                   = GETUTCDATE(),
					WH.IsScheduled                   = T.IsScheduled
                FROM dbo.[WorksheetHeader] WH
                INNER JOIN @tbl_WorksheetHeaderType T
                    ON WH.WorksheetHeaderId = T.WorksheetHeaderId
                WHERE T.WorksheetHeaderId IS NOT NULL;

                SELECT 1 AS Status, 'Updated successfully' AS Message,
                       *
                FROM   dbo.[WorksheetHeader] WITH (NOLOCK)
                WHERE  WorksheetHeaderId = @WorksheetHeaderId;
            END

            -- -------------------------------------------------------
            -- INSERT new record
            -- -------------------------------------------------------
            ELSE
            BEGIN
                -- Generate Worksheet Number
                IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
                BEGIN
                    SELECT @CurrentNo = ISNULL([CurrentNummber], 0)
                    FROM   [dbo].[CodePrefixes] WITH (NOLOCK)
                    WHERE  [CodePrefix]      = @CodePrefix
                      AND  [MasterCompanyId] = @MasterCompanyId;

                    IF @CurrentNo > 0
                    BEGIN
                        SET @CurrentNo = @CurrentNo + 1;
                        UPDATE [dbo].[CodePrefixes]
                        SET    [CurrentNummber] = @CurrentNo
                        WHERE  [CodePrefix]      = @CodePrefix
                          AND  [MasterCompanyId] = @MasterCompanyId;
                    END
                    ELSE
                    BEGIN
                        SET @CurrentNo = (
                            SELECT ISNULL([StartsFrom], 0)
                            FROM   [dbo].[CodePrefixes]
                            WHERE  [CodePrefix]      = @CodePrefix
                              AND  [MasterCompanyId] = @MasterCompanyId
                        ) + 1;

                        UPDATE [dbo].[CodePrefixes]
                        SET    [CurrentNummber] = @CurrentNo
                        WHERE  [CodePrefix]      = @CodePrefix
                          AND  [MasterCompanyId] = @MasterCompanyId;
                    END

                    SET @WorksheetNum = (
                        SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(
                            @CurrentNo,
                            ISNULL(@CodePrefix, ''),
                            ISNULL(@CodeSuffix,  '')
                        )
                    );
                END
                ELSE
                BEGIN
                    SET @WorksheetNum = (
                        SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '', '')
                    );
                END


                IF ISNULL(@AircraftRegistryId, 0) > 0
                BEGIN
                    SELECT
                        @MakeTypeId = MakeTypeId,
                        @AircraftModelId = AircraftModelId,
                        @SerialNum = SerialNum,
                        @TailNum = TailNum
                    FROM dbo.AircraftRegistryHeader WITH (NOLOCK)
                    WHERE AircraftRegistryId = @AircraftRegistryId;
                END


                INSERT INTO [dbo].[WorksheetHeader]
                (
                    WorksheetNumber,
                    MakeTypeId,
                    MakeType,
                    AircraftModelId,
                    AircraftModel,
                    WorksheetType,
                    WorksheetTypeId,
					MtcCategoryId,
                    WorkOrderNo,
                    WorkSheetStatusId,                    
                    TailNum,
					SerialNum,
                    AFHours,
                    InspectionType,
					InspectionTypeId,
                    InspectionDate,
                    QualitySafetyDeptSignOutBy,
                    QualitySafetyDeptSignOutDate,
                    QualitySafetyDeptSignInBy,
                    QualitySafetyDeptSignInDate,
                    ReleaseToServiceBy,
                    ReleaseDate,
                    ReleaseLicenseNumber,
                    AMONumber,
                    AircraftReg,
                    TechnicalRecordsWO,
                    CalmSysWO,
                    CertificationStatement,
                    DupInspSysDescription,
                    DupInspDefectWorkNo,
                    DupInspDate,
                    DupInspStation,
                    DupInspSignatory1By,
                    DupInspSignatory1LicAppNo,
                    DupInspSignatory1Time,
                    DupInspSignatory2By,
                    DupInspSignatory2LicAppNo,
                    DupInspSignatory2Time,
                    AircraftInstalledPartDetailsId ,
                    ProgramId,
					IsFromAircraft,
					AircraftRegistryId,
					EngineRegistryId,
                    IsActive,
                    IsDeleted,
                    MasterCompanyId,
                    CreatedBy,
                    UpdatedBy,
                    CreatedDate,
                    UpdatedDate,
					IsScheduled
                )
                SELECT
                    @WorksheetNum,
                    ISNULL(@MakeTypeId, T.MakeTypeId),
                    T.MakeType,
                    ISNULL(@AircraftModelId, T.AircraftModelId),
                    T.AircraftModel,
                    T.WorksheetType,
                    T.WorksheetTypeId,
					T.MtcCategoryId,
                    T.WorkOrderNo,
                    @WorkSheetStatusId,
                    ISNULL(@TailNum, T.TailNum),
                    ISNULL(@SerialNum, T.SerialNum),
                    T.AFHours,
                    T.InspectionType,
					T.InspectionTypeId,
                    T.InspectionDate,
                    T.QualitySafetyDeptSignOutBy,
                    T.QualitySafetyDeptSignOutDate,
                    T.QualitySafetyDeptSignInBy,
                    T.QualitySafetyDeptSignInDate,
                    T.ReleaseToServiceBy,
                    T.ReleaseDate,
                    T.ReleaseLicenseNumber,
                    T.AMONumber,
                    T.AircraftReg,
                    T.TechnicalRecordsWO,
                    T.CalmSysWO,
                    T.CertificationStatement,
                    T.DupInspSysDescription,
                    T.DupInspDefectWorkNo,
                    T.DupInspDate,
                    T.DupInspStation,
                    T.DupInspSignatory1By,
                    T.DupInspSignatory1LicAppNo,
                    T.DupInspSignatory1Time,
                    T.DupInspSignatory2By,
                    T.DupInspSignatory2LicAppNo,
                    T.DupInspSignatory2Time,
                    T.AircraftInstalledPartDetailsId,
                    T.ProgramId,
					T.IsFromAircraft,
					T.AircraftRegistryId,
					T.EngineRegistryId,
                    ISNULL(T.IsActive,  1),
                    ISNULL(T.IsDeleted, 0),
                    T.MasterCompanyId,
                    T.CreatedBy,
                    T.UpdatedBy,
                    GETUTCDATE(),
                    GETUTCDATE(),
					T.IsScheduled
                FROM @tbl_WorksheetHeaderType T;

                SET @WorksheetHeaderId = SCOPE_IDENTITY();

                UPDATE AMP
                SET
                    AMP.WorksheetNumber = @WorksheetNum,
                    AMP.UpdatedBy       = T.UpdatedBy,
                    AMP.UpdatedDate     = GETUTCDATE()
                FROM [dbo].[AircraftMaintenanceProgram] AMP
                INNER JOIN @tbl_WorksheetHeaderType T ON AMP.ProgramId = T.ProgramId AND AMP.MasterCompanyId = T.MasterCompanyId
                WHERE ISNULL(T.ProgramId, 0) > 0
                  AND ISNULL(AMP.WorksheetNumber, '') <> ISNULL(@WorksheetNum, '');

                UPDATE AIPD
                SET
                    AIPD.WorksheetNumber = @WorksheetNum,
                    AIPD.UpdatedBy       = T.UpdatedBy,
                    AIPD.UpdatedDate     = GETUTCDATE()
                FROM [dbo].[AircraftInstalledPartDetails] AIPD
                INNER JOIN @tbl_WorksheetHeaderType T ON AIPD.AircraftInstalledPartDetailsId = T.AircraftInstalledPartDetailsId AND AIPD.MasterCompanyId = T.MasterCompanyId
                WHERE ISNULL(T.AircraftInstalledPartDetailsId, 0) > 0
                  AND ISNULL(AIPD.WorksheetNumber, '') <> ISNULL(@WorksheetNum, '');

                SELECT 1 AS Status, 'Saved successfully' AS Message,
                       *
                FROM   dbo.[WorksheetHeader] WITH (NOLOCK)
                WHERE  WorksheetHeaderId = @WorksheetHeaderId;

				-- ══════════════════════════════════════════════════
				-- HISTORY BLOCK
				-- Same pattern as USP_CreateAircraftRegistryHeader
				-- ══════════════════════════════════════════════════
				DECLARE @TemplateBody   VARCHAR(MAX)    = '',
						@Activity       VARCHAR(MAX)    = NULL,
						@HistCreatedBy  VARCHAR(256)    = NULL,
						@WorksheetStr   VARCHAR(50)     = NULL;

			    SET @WorksheetStr = 'Worksheet Num.: ' + @WorksheetNum;

				-- Read NEW values from TVP
				SELECT
					@New_MakeType                  = ISNULL(T.MakeType, ''),
					@New_AircraftModel             = ISNULL(T.AircraftModel, ''),
					@New_WorksheetType             = ISNULL(T.WorksheetType, ''),
					@New_TailNum                   = ISNULL(T.TailNum,   ISNULL(@TailNum,  '')),
					@New_SerialNum                 = ISNULL(T.SerialNum, ISNULL(@SerialNum, '')),
					@New_IsActive                  = CASE WHEN ISNULL(T.IsActive, 1) = 1 THEN 'Active' ELSE 'Inactive' END,
					@HistCreatedBy                 = ISNULL(T.UpdatedBy, T.CreatedBy)
				FROM @tbl_WorksheetHeaderType T;

				SET @Activity = 'New Worksheet Added';

                IF @New_MakeType                 <> '' SET @TemplateBody += 'Make/Type: '                 + @New_MakeType                 + ' | ';
                IF @New_AircraftModel            <> '' SET @TemplateBody += 'Aircraft Model: '            + @New_AircraftModel            + ' | ';
                IF @New_WorksheetType            <> '' SET @TemplateBody += 'Worksheet Type: '            + @New_WorksheetType            + ' | ';
                IF @New_TailNum                  <> '' SET @TemplateBody += 'Tail No.: '                  + @New_TailNum                  + ' | ';
                IF @New_SerialNum                <> '' SET @TemplateBody += 'Serial No.: '                + @New_SerialNum                + ' | ';
                SET @TemplateBody += 'Created By: ' + ISNULL(@HistCreatedBy,'') + ' | ';
                SET @TemplateBody += 'Created Date: '+ CONVERT(VARCHAR(30), GETUTCDATE(), 103);

				-- Call usp_SaveAircraftHistory once
				IF ISNULL(LTRIM(RTRIM(@TemplateBody)), '') <> ''
				BEGIN

					EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 2,@ModuleName = 'Aircraft Worksheet',@RefferenceId = @AircraftRegistryId,@FieldsName = NULL,
												 @OldValue = NULL,@NewValue = @WorksheetStr,@HistoryText = @TemplateBody,@Activity = @Activity,@MasterCompanyId = @MasterCompanyId,
												 @CreatedBy = @HistCreatedBy;
				END
				-- ── END HISTORY BLOCK ─────────────────────────────
            END
        END

		--Add into Mapping WorksheetMapping table
		EXEC USP_LinkPartToExistingWorksheet @WorksheetHeaderId,@ProgramId,@AircraftInstalledPartDetailsId,@IsFromAircraft,@MasterCompanyId,@UpdatedBy

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID            INT,
                @DatabaseName          VARCHAR(100)  = DB_NAME(),
                @AdhocComments         VARCHAR(150)  = 'USP_CreateUpdateWorksheetHeader',
                @ProcedureParameters   VARCHAR(3000) = '@Parameter1 = ''' + '',
                @ApplicationName       VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName         = @DatabaseName,
            @AdhocComments        = @AdhocComments,
            @ProcedureParameters  = @ProcedureParameters,
            @ApplicationName      = @ApplicationName,
            @ErrorLogID           = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );
        RETURN(1);
    END CATCH
END