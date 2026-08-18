/*************************************************************             
 ** File:   [USP_CreateEngineRegistryHeader]          
 ** Author:   Amit Ghediya 
 ** Description: This stored procedure is used to add a record in [EngineRegistryHeader].
 ** Jira Id: PN-17037
 ** Purpose:           
 ** Date:  29/06/2026
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------     
 ** 1    29/06/2026   Amit Ghediya		Created [PN-17037]


**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateEngineRegistryHeader]
    @tbl_EngineRegistryHeaderType dbo.EngineRegistryTableType READONLY
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  

	DECLARE @EngineRegistryId BIGINT = (SELECT EngineRegistryId FROM @tbl_EngineRegistryHeaderType);
	DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50),@EngineRegistryNum VARCHAR(30) = NULL;
	DECLARE @CurrentNo INT = 0, @IsUpdate INT = 0;
	DECLARE @EngineRegistryCodePrefix INT = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='EngineRegistryNumber');
	DECLARE @MasterCompanyId INT = (SELECT [MasterCompanyId] FROM @tbl_EngineRegistryHeaderType);
	SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @EngineRegistryCodePrefix AND [MasterCompanyId] = @MasterCompanyId;

		--IF EXISTS ( SELECT 1 FROM dbo.EngineRegistryHeader AR WITH (NOLOCK) INNER JOIN @tbl_EngineRegistryHeaderType T ON AR.TailNum = T.TailNum
  --                  AND AR.MasterCompanyId = T.MasterCompanyId
  --                  AND AR.IsDeleted = 0
  --                  AND AR.EngineRegistryId <> ISNULL(T.EngineRegistryId,0)
  --      )
  --      BEGIN
		--	IF @@TRANCOUNT > 0
  --              ROLLBACK TRANSACTION;

  --          SELECT 0 AS Status, 'Engine Tail Num for this AC type already exist' AS Message;
  --          RETURN;
  --      END
		--ELSE 
		IF EXISTS ( SELECT 1 FROM dbo.EngineRegistryHeader AR WITH (NOLOCK) INNER JOIN @tbl_EngineRegistryHeaderType T ON AR.SerialNum = T.SerialNum
                    AND AR.MasterCompanyId = T.MasterCompanyId
                    AND AR.IsDeleted = 0
                    AND AR.EngineRegistryId <> ISNULL(T.EngineRegistryId,0)
        )
        BEGIN
			IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SELECT 0 AS Status, 'Engine Serial Num for this AC type already exist' AS Message;
            RETURN;
        END
	ELSE
	BEGIN
	    IF(@EngineRegistryId > 0)
	    BEGIN
			-- Declare OLD value holders
			DECLARE @Old_MakeType           VARCHAR(200),
					@Old_AircraftModel      VARCHAR(200),
					@Old_AircraftSubModel   VARCHAR(200),
					@Old_NumOfEngines       VARCHAR(50),
					@Old_TailNum            VARCHAR(50),
					@Old_SerialNum          VARCHAR(100),
					@Old_ManufacturedDate   VARCHAR(30),
					@Old_PlaceInServiceDate VARCHAR(30),
					@Old_TotalTSN           VARCHAR(50),
					@Old_TotalCSN           VARCHAR(maX),
					@Old_Hobbs              VARCHAR(50),
					@Old_AircraftLocation   VARCHAR(200),
					@Old_NextScheduled      VARCHAR(30),
					@Old_AircraftStatus     VARCHAR(100),
					@Old_MaintenanceStatus  VARCHAR(100),
					@Old_Memo               NVARCHAR(MAX),
					@Old_IsActive           VARCHAR(10),
					@New_MakeType           VARCHAR(200),
					@New_AircraftModel      VARCHAR(200),
					@New_AircraftSubModel   VARCHAR(200),
					@New_NumOfEngines       VARCHAR(50),
					@New_TailNum            VARCHAR(50),
					@New_SerialNum          VARCHAR(100),
					@New_ManufacturedDate   VARCHAR(30),
					@New_PlaceInServiceDate VARCHAR(30),
					@New_TotalTSN           VARCHAR(50),
					@New_TotalCSN           VARCHAR(max),
					@New_Hobbs              VARCHAR(50),
					@New_AircraftLocation   VARCHAR(200),
					@New_NextScheduled      VARCHAR(30),
					@New_AircraftStatus     VARCHAR(100),
					@New_MaintenanceStatus  VARCHAR(100),
					@New_Memo               NVARCHAR(MAX),
					@New_IsActive           VARCHAR(10),
					@Hist_UpdatedBy         VARCHAR(256),
					@Hist_TailNum           VARCHAR(50),
					@Hist_Make              VARCHAR(100),
					@Hist_Model             VARCHAR(100),
					@Hist_SerialNum         VARCHAR(100);

			-- Read current DB values BEFORE updated
			SELECT
					@Old_MakeType           = AR.MakeType,
					@Old_AircraftModel      = AR.EngineModel,
					@Old_AircraftSubModel   = ISNULL(AR.EngineSubModel, ''),
					@Old_NumOfEngines       = CAST(ISNULL(AR.NumOfEngines, 0) AS VARCHAR),
					@Old_TailNum            = AR.TailNum,
					@Old_SerialNum          = AR.SerialNum,
					@Old_ManufacturedDate   = ISNULL(CONVERT(VARCHAR(30), AR.ManufacturedDate,   103), ''),
					@Old_PlaceInServiceDate = ISNULL(CONVERT(VARCHAR(30), AR.PlaceInServiceDate, 103), ''),
					@Old_TotalTSN           = CAST(CAST(ISNULL(AR.TotalTSN,   0) AS INT) AS VARCHAR) + ' : ' + RIGHT('00' + CAST(CAST(ISNULL(AR.TotalTSNMM, 0) AS INT) AS VARCHAR), 2),
					@Old_TotalCSN           = CAST(ISNULL(AR.TotalCSN, 0) AS VARCHAR),
					@Old_Hobbs              = CAST(ISNULL(AR.Hobbs, 0) AS VARCHAR),
					@Old_AircraftLocation   = ISNULL(AR.EngineLocation, ''),
					@Old_NextScheduled      = ISNULL(CONVERT(VARCHAR(30), AR.NextScheduled, 103), ''),
					@Old_AircraftStatus     = ISNULL(AR.EngineStatus, ''),
					@Old_MaintenanceStatus  = ISNULL(AR.MaintenanceStatus, ''),
					@Old_Memo               = ISNULL(AR.Memo, ''),
					@Old_IsActive           = CASE WHEN AR.IsActive = 1 THEN 'Active' ELSE 'Inactive' END
			FROM dbo.[EngineRegistryHeader] AR WITH (NOLOCK)
			WHERE AR.EngineRegistryId = @EngineRegistryId
			AND AR.MasterCompanyId    = @MasterCompanyId;

		    UPDATE AR
            SET
                AR.MakeTypeId = T.MakeTypeId,
                AR.MakeType = T.MakeType,
                AR.EngineModelId = T.EngineModelId,
                AR.EngineModel = T.EngineModel,
                AR.EngineSubModel = T.EngineSubModel,
                AR.NumOfEngines = T.NumOfEngines,
                AR.TailNum = T.TailNum,
                AR.SerialNum = T.SerialNum,
                AR.ManufacturedDate = T.ManufacturedDate,
                AR.PlaceInServiceDate = T.PlaceInServiceDate,
                AR.TotalTSN = T.TotalTSN,
				AR.TotalTSNMM = T.TotalTSNMM,
                AR.TotalCSN = T.TotalCSN,
				AR.TotalCSNMM = T.TotalCSNMM,
                AR.Hobbs = T.Hobbs,
                AR.EngineLocation = T.EngineLocation,
                AR.NextScheduled = T.NextScheduled,
                AR.MEL = T.MEL,
                AR.EngineStatusId = T.EngineStatusId,
                AR.EngineStatus = T.EngineStatus,
                AR.MaintenanceStatusId = T.MaintenanceStatusId,
                AR.MaintenanceStatus = T.MaintenanceStatus,
                AR.Memo = T.Memo,
                AR.IsActive = ISNULL(T.IsActive, AR.IsActive),
                AR.IsDeleted = ISNULL(T.IsDeleted, AR.IsDeleted),
                AR.MasterCompanyId = T.MasterCompanyId,
                AR.UpdatedBy = T.UpdatedBy,
                AR.UpdatedDate = GETUTCDATE(),
				AR.[Description] = T.[Description]
            FROM dbo.[EngineRegistryHeader] AR
            INNER JOIN @tbl_EngineRegistryHeaderType T ON AR.EngineRegistryId = T.EngineRegistryId
            WHERE T.EngineRegistryId IS NOT NULL;

			-- Read new values from updated
			SELECT
					@New_MakeType           = ISNULL(T.MakeType, ''),
					@New_AircraftModel      = ISNULL(T.EngineModel, ''),
					@New_AircraftSubModel   = ISNULL(T.EngineSubModel, ''),
					@New_NumOfEngines       = CAST(ISNULL(T.NumOfEngines, 0) AS VARCHAR),
					@New_TailNum            = ISNULL(T.TailNum, ''),
					@New_SerialNum          = ISNULL(T.SerialNum, ''),
					@New_ManufacturedDate   = ISNULL(CONVERT(VARCHAR(30), T.ManufacturedDate,   103), ''),
					@New_PlaceInServiceDate = ISNULL(CONVERT(VARCHAR(30), T.PlaceInServiceDate, 103), ''),
					@New_TotalTSN           = CAST(CAST(ISNULL(T.TotalTSN,   0) AS INT) AS VARCHAR) + ' : ' + RIGHT('00' + CAST(CAST(ISNULL(T.TotalTSNMM, 0) AS INT) AS VARCHAR), 2),
					@New_TotalCSN           = CAST(ISNULL(T.TotalCSN, 0) AS VARCHAR(20)),
					@New_Hobbs              = CAST(ISNULL(T.Hobbs, 0) AS VARCHAR),
					@New_AircraftLocation   = ISNULL(T.EngineLocation, ''),
					@New_NextScheduled      = ISNULL(CONVERT(VARCHAR(30), T.NextScheduled, 103), ''),
					@New_AircraftStatus     = ISNULL(T.EngineStatus, ''),
					@New_MaintenanceStatus  = ISNULL(T.MaintenanceStatus, ''),
					@New_Memo               = ISNULL(T.Memo, ''),
					@New_IsActive           = CASE WHEN ISNULL(T.IsActive, 1) = 1 THEN 'Active' ELSE 'Inactive' END,
					@Hist_UpdatedBy         = T.UpdatedBy,
					@Hist_TailNum           = T.TailNum,
					@Hist_Make              = T.MakeType,
					@Hist_Model             = T.EngineModel,
					@Hist_SerialNum         = T.SerialNum
				FROM @tbl_EngineRegistryHeaderType T;

			SET @IsUpdate = 1;
            SELECT 1 AS Status, 'Saved successfully' AS Message, * FROM dbo.[EngineRegistryHeader] WITH(NOLOCK) WHERE EngineRegistryId = @EngineRegistryId
	    END
	    ELSE
	    BEGIN
		    IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
		    BEGIN
			    SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
			    IF @CurrentNo > 0
			    BEGIN
				    SET @CurrentNo = @CurrentNo + 1;
				    UPDATE [dbo].[CodePrefixes] 
				    SET [CurrentNummber] = @CurrentNo
				    WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
			    END
			    ELSE
			    BEGIN
				    SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
				    UPDATE [dbo].[CodePrefixes]
				    SET [CurrentNummber] = @CurrentNo 
				    WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
			    END
			    -- Generate Aircraft Registry Number
			    SET @EngineRegistryNum = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
		    END
		    ELSE
		    BEGIN
			    -- Generate Aircraft Registry Number
			    SET @EngineRegistryNum = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
		    END
            INSERT INTO [EngineRegistryHeader]
            (
                MakeTypeId,
                MakeType,
                EngineModelId,
                EngineModel,
                EngineSubModel,
                NumOfEngines,
                TailNum,
                SerialNum,
                ManufacturedDate,
                PlaceInServiceDate,
                TotalTSN,
				TotalTSNMM,
                TotalCSN,
				TotalCSNMM,
                Hobbs,
                EngineLocation,
                NextScheduled,
                MEL,
                EngineStatusId,
                EngineStatus,
                MaintenanceStatusId,
                MaintenanceStatus,
                CustomerId,
                CustomerName,
			    Memo,
                IsActive,
                IsDeleted,
                MasterCompanyId,
                CreatedBy,
                UpdatedBy,
                CreatedDate,
                UpdatedDate,
			    EngineRegistryNumber,
				[Description]
            )
            SELECT
                T.MakeTypeId,
                T.MakeType,
                T.EngineModelId,
                T.EngineModel,
                T.EngineSubModel,
                T.NumOfEngines,
                T.TailNum,
                T.SerialNum,
                T.ManufacturedDate,
                T.PlaceInServiceDate,
                T.TotalTSN,
				T.TotalTSNMM,
                T.TotalCSN,
				T.TotalCSNMM,
                T.Hobbs,
                T.EngineLocation,
                T.NextScheduled,
                T.MEL,
                T.EngineStatusId,
                T.EngineStatus,
                T.MaintenanceStatusId,
                T.MaintenanceStatus,
                T.CustomerId,
                T.CustomerName,
			    T.Memo,
                ISNULL(T.IsActive, 1),
                ISNULL(T.IsDeleted, 0),
                T.MasterCompanyId,
                T.CreatedBy,
                T.UpdatedBy,
                GETUTCDATE(),
                GETUTCDATE(),
			    @EngineRegistryNum,
				T.[Description]
            FROM @tbl_EngineRegistryHeaderType T

			SET @EngineRegistryId = SCOPE_IDENTITY();
			SELECT 1 AS Status, 'Saved successfully' AS Message, * FROM dbo.[EngineRegistryHeader] WITH(NOLOCK) WHERE EngineRegistryId = @EngineRegistryId
	    END   

		-- =====================================================
        -- HISTORY BLOCK 
        -- =====================================================
		DECLARE @TemplateCode VARCHAR(50)='',@TemplateBody VARCHAR(MAX)='',
				@CreatedBy VARCHAR(100) = NULL,@AcTailNum VARCHAR(50) = NULL,@AcMake VARCHAR(100) = NULL,
				@AcModel   VARCHAR(100) = NULL,@SerialNum VARCHAR(100) = NULL,@Activity VARCHAR(100) = NULL;

		SELECT @AcTailNum = T.TailNum,@AcMake = T.MakeType,@AcModel = T.EngineModel,@SerialNum = T.SerialNum, @CreatedBy = T.CreatedBy,@MasterCompanyId = T.MasterCompanyId FROM @tbl_EngineRegistryHeaderType T;

		IF(@IsUpdate = 1)
		BEGIN
			 SET @TemplateCode = 'UpdateEngineRegistry';
			 SET @Activity = 'Updated';

			 -- Build ONE combined HistoryText — appends only changed fields
			-- DECLARE @HistoryText NVARCHAR(MAX) = '';
			 
			IF ISNULL(@Old_MakeType,'')           <> @New_MakeType
				SET @TemplateBody += 'Make/Type: '          + ISNULL(@Old_MakeType,'')           + ' to ' + @New_MakeType           + ' | ';

			IF ISNULL(@Old_AircraftModel,'')      <> @New_AircraftModel
				SET @TemplateBody += 'Model: '              + ISNULL(@Old_AircraftModel,'')      + ' to ' + @New_AircraftModel      + ' | ';

			IF ISNULL(@Old_AircraftSubModel,'')   <> @New_AircraftSubModel
				SET @TemplateBody += 'Sub Model: '          + ISNULL(@Old_AircraftSubModel,'')   + ' to ' + @New_AircraftSubModel   + ' | ';

			IF ISNULL(@Old_NumOfEngines,'')       <> ISNULL(@New_NumOfEngines,'')
				SET @TemplateBody += 'Num Of Engines: '     + ISNULL(@Old_NumOfEngines,'')       + ' to ' + @New_NumOfEngines + ' | ';

			IF ISNULL(@Old_TailNum,'')            <> @New_TailNum
				SET @TemplateBody += 'Tail No.: '           + ISNULL(@Old_TailNum,'')            + ' to ' + @New_TailNum            + ' | ';

			IF ISNULL(@Old_SerialNum,'')          <> @New_SerialNum
				SET @TemplateBody += 'Serial No.: '         + ISNULL(@Old_SerialNum,'')          + ' to ' + @New_SerialNum          + ' | ';

			IF ISNULL(@Old_ManufacturedDate,'')   <> @New_ManufacturedDate
				SET @TemplateBody += 'Manufactured Date: '  + ISNULL(@Old_ManufacturedDate,'')   + ' to ' + @New_ManufacturedDate   + ' | ';

			IF ISNULL(@Old_PlaceInServiceDate,'') <> @New_PlaceInServiceDate
				SET @TemplateBody += 'Place In Service: '   + ISNULL(@Old_PlaceInServiceDate,'') + ' to ' + @New_PlaceInServiceDate + ' | ';

			IF ISNULL(@Old_TotalTSN,'')           <> @New_TotalTSN
				SET @TemplateBody += 'TTSN (HH:MM): '       + ISNULL(@Old_TotalTSN,'')           + ' to ' + @New_TotalTSN           + ' | ';

			IF ISNULL(@Old_TotalCSN,'')           <> @New_TotalCSN
				SET @TemplateBody += 'TCSN: '               + ISNULL(@Old_TotalCSN,'')           + ' to ' + @New_TotalCSN           + ' | ';

			IF ISNULL(@Old_Hobbs,'')              <> @New_Hobbs
				SET @TemplateBody += 'Hobbs: '              + ISNULL(@Old_Hobbs,'')              + ' to ' + @New_Hobbs              + ' | ';

			IF ISNULL(@Old_AircraftLocation,'')   <> @New_AircraftLocation
				SET @TemplateBody += 'Location: '           + ISNULL(@Old_AircraftLocation,'')   + ' to ' + @New_AircraftLocation   + ' | ';

			IF ISNULL(@Old_NextScheduled,'')      <> @New_NextScheduled
				SET @TemplateBody += 'Next Scheduled: '     + ISNULL(@Old_NextScheduled,'')      + ' to ' + @New_NextScheduled      + ' | ';

			IF ISNULL(@Old_AircraftStatus,'')     <> @New_AircraftStatus
				SET @TemplateBody += 'Aircraft Status: '    + ISNULL(@Old_AircraftStatus,'')     + ' to ' + @New_AircraftStatus     + ' | ';

			IF ISNULL(@Old_MaintenanceStatus,'')  <> @New_MaintenanceStatus
				SET @TemplateBody += 'Maintenance Status: ' + ISNULL(@Old_MaintenanceStatus,'')  + ' to ' + @New_MaintenanceStatus  + ' | ';

			IF ISNULL(@Old_Memo,'') <> @New_Memo
			BEGIN
				DECLARE @CleanOld NVARCHAR(MAX) = ISNULL(@Old_Memo,'');
				DECLARE @CleanNew NVARCHAR(MAX) = ISNULL(@New_Memo,'');

				-- Strip HTML tags from OLD
				WHILE CHARINDEX('<', @CleanOld) > 0
				BEGIN
					DECLARE @S INT = CHARINDEX('<', @CleanOld);
					DECLARE @E INT = CHARINDEX('>', @CleanOld, @S);
					IF @E > 0
						SET @CleanOld = STUFF(@CleanOld, @S, @E - @S + 1, '');
					ELSE
						BREAK;
				END

				-- Strip HTML tags from NEW
				WHILE CHARINDEX('<', @CleanNew) > 0
				BEGIN
					DECLARE @S2 INT = CHARINDEX('<', @CleanNew);
					DECLARE @E2 INT = CHARINDEX('>', @CleanNew, @S2);
					IF @E2 > 0
						SET @CleanNew = STUFF(@CleanNew, @S2, @E2 - @S2 + 1, '');
					ELSE
						BREAK;
				END

				-- Clean up extra spaces and line breaks
				SET @CleanOld = LTRIM(RTRIM(REPLACE(REPLACE(@CleanOld, CHAR(13), ''), CHAR(10), ' ')));
				SET @CleanNew = LTRIM(RTRIM(REPLACE(REPLACE(@CleanNew, CHAR(13), ''), CHAR(10), ' ')));

				IF @CleanOld <> @CleanNew AND @CleanNew <> ''
					SET @TemplateBody += 'Memo: ' + @CleanOld + ' to ' + @CleanNew + ' | ';
			END

			IF ISNULL(@Old_IsActive,'')           <> @New_IsActive
				SET @TemplateBody += 'Status: '             + ISNULL(@Old_IsActive,'')           + ' to ' + @New_IsActive           + ' | ';
			 
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
		     SET @TemplateCode = 'AddEngineRegistry';
			 SET @Activity = 'New Engine Registry Added';

			 SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[AircraftHistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @TemplateCode;

			 SET @TemplateBody = REPLACE(@TemplateBody, '##AcTailNum##', @AcTailNum)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##AcMake##', @AcMake)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##AcModel##', @AcModel)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##SerialNum##', @SerialNum)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##CreatedBy##', @CreatedBy)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##CreatedDate##', ISNULL(CONVERT(VARCHAR(30), GETUTCDATE(),   103), ''))
		END

        -- ── Call usp_SaveAircraftHistory only if rows exist ───
        IF ISNULL(LTRIM(RTRIM(@TemplateBody)), '') <> ''
		BEGIN
			EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 1,@ModuleName = 'Aircraft Registry',@RefferenceId = @EngineRegistryId,@FieldsName = NULL,
												 @OldValue = NULL,@NewValue = @EngineRegistryNum,@HistoryText = @TemplateBody,@Activity = @Activity,@MasterCompanyId = @MasterCompanyId,
												 @CreatedBy = @CreatedBy;
		END

        -- ── END HISTORY BLOCK ─────────────────────────────────
		
    END

    END TRY      
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateAircraftRegistryHeader'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END