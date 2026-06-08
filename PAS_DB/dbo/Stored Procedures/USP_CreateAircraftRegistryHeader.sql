/*************************************************************             
 ** File:   [USP_CreateAircraftRegistryHeader]          
 ** Author:   Bhargav Saliya 
 ** Description: This stored procedure is used to add a record in [AircraftRegistryHeader].
 ** Jira Id: PN-15843
 ** Purpose:           
 ** Date:  [26-Mar-2026] 
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------     
    1    26/03/2026   Bhargav Saliya       PN-15456: Created
    2    31/03/2026   Bhargav Saliya       Modified - Added CodePrefix
    3    05/06/2026   Abhishek Jirawla     Adding Data Validation & Restrictions [PN-16292] 
	4    22/06/2026   Amit Ghediya		   Adding TTSN H/M & TCSN H/M [PN-16533]
	5    02/06/2026   Abhishek Jirawla	   Adding CustomerId and CustomerName [PN-16679]
	6    04/06/2026   Amit Ghediya		   Adding Header data in History module [PN-16581]
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_CreateAircraftRegistryHeader]
    @tbl_AircraftRegistryHeaderType dbo.AircraftRegistryTableType READONLY
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  

	DECLARE @AircraftRegistryId BIGINT = (SELECT AircraftRegistryId FROM @tbl_AircraftRegistryHeaderType);
	DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50),@AircraftRegistryNum VARCHAR(30) = NULL;
	DECLARE @CurrentNo INT = 0, @IsUpdate INT = 0;
	DECLARE @AircraftRegistryCodePrefix INT = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='AircraftRegistryNumber');
	DECLARE @MasterCompanyId INT = (SELECT [MasterCompanyId] FROM @tbl_AircraftRegistryHeaderType);
	SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @AircraftRegistryCodePrefix AND [MasterCompanyId] = @MasterCompanyId;

    IF EXISTS ( SELECT 1 FROM dbo.AircraftRegistryHeader AR WITH (NOLOCK) INNER JOIN @tbl_AircraftRegistryHeaderType T ON AR.TailNum = T.TailNum
                    AND AR.MasterCompanyId = T.MasterCompanyId
                    AND AR.IsDeleted = 0
                    AND AR.AircraftRegistryId <> ISNULL(T.AircraftRegistryId,0)
        )
        BEGIN
			IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SELECT 0 AS Status, 'AC Tail Num for this AC type already exist' AS Message;
            RETURN;
        END
	ELSE IF EXISTS ( SELECT 1 FROM dbo.AircraftRegistryHeader AR WITH (NOLOCK) INNER JOIN @tbl_AircraftRegistryHeaderType T ON AR.SerialNum = T.SerialNum
                    AND AR.MasterCompanyId = T.MasterCompanyId
                    AND AR.IsDeleted = 0
                    AND AR.AircraftRegistryId <> ISNULL(T.AircraftRegistryId,0)
        )
        BEGIN
			IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SELECT 0 AS Status, 'AC Serial Num for this AC type already exist' AS Message;
            RETURN;
        END
	ELSE
	BEGIN
	    IF(@AircraftRegistryId > 0)
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
					@Old_AircraftModel      = AR.AircraftModel,
					@Old_AircraftSubModel   = ISNULL(AR.AircraftSubModel, ''),
					@Old_NumOfEngines       = CAST(ISNULL(AR.NumOfEngines, 0) AS VARCHAR),
					@Old_TailNum            = AR.TailNum,
					@Old_SerialNum          = AR.SerialNum,
					@Old_ManufacturedDate   = ISNULL(CONVERT(VARCHAR(30), AR.ManufacturedDate,   103), ''),
					@Old_PlaceInServiceDate = ISNULL(CONVERT(VARCHAR(30), AR.PlaceInServiceDate, 103), ''),
					@Old_TotalTSN           = CAST(CAST(ISNULL(AR.TotalTSN,   0) AS INT) AS VARCHAR) + ' : ' + RIGHT('00' + CAST(CAST(ISNULL(AR.TotalTSNMM, 0) AS INT) AS VARCHAR), 2),
					@Old_TotalCSN           = CAST(ISNULL(AR.TotalCSN, 0) AS VARCHAR),
					@Old_Hobbs              = CAST(ISNULL(AR.Hobbs, 0) AS VARCHAR),
					@Old_AircraftLocation   = ISNULL(AR.AircraftLocation, ''),
					@Old_NextScheduled      = ISNULL(CONVERT(VARCHAR(30), AR.NextScheduled, 103), ''),
					@Old_AircraftStatus     = ISNULL(AR.AircraftStatus, ''),
					@Old_MaintenanceStatus  = ISNULL(AR.MaintenanceStatus, ''),
					@Old_Memo               = ISNULL(AR.Memo, ''),
					@Old_IsActive           = CASE WHEN AR.IsActive = 1 THEN 'Active' ELSE 'Inactive' END
			FROM dbo.[AircraftRegistryHeader] AR WITH (NOLOCK)
			WHERE AR.AircraftRegistryId = @AircraftRegistryId
			AND AR.MasterCompanyId    = @MasterCompanyId;

		    UPDATE AR
            SET
                AR.MakeTypeId = T.MakeTypeId,
                AR.MakeType = T.MakeType,
                AR.AircraftModelId = T.AircraftModelId,
                AR.AircraftModel = T.AircraftModel,
                AR.AircraftSubModel = T.AircraftSubModel,
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
                AR.AircraftLocation = T.AircraftLocation,
                AR.NextScheduled = T.NextScheduled,
                AR.MEL = T.MEL,
                AR.AircraftStatusId = T.AircraftStatusId,
                AR.AircraftStatus = T.AircraftStatus,
                AR.MaintenanceStatusId = T.MaintenanceStatusId,
                AR.MaintenanceStatus = T.MaintenanceStatus,
                AR.Memo = T.Memo,
                AR.IsActive = ISNULL(T.IsActive, AR.IsActive),
                AR.IsDeleted = ISNULL(T.IsDeleted, AR.IsDeleted),
                AR.MasterCompanyId = T.MasterCompanyId,
                AR.UpdatedBy = T.UpdatedBy,
                AR.UpdatedDate = GETUTCDATE()
            FROM dbo.[AircraftRegistryHeader] AR
            INNER JOIN @tbl_AircraftRegistryHeaderType T ON AR.AircraftRegistryId = T.AircraftRegistryId
            WHERE T.AircraftRegistryId IS NOT NULL;

			-- Read new values from updated
			SELECT
					@New_MakeType           = ISNULL(T.MakeType, ''),
					@New_AircraftModel      = ISNULL(T.AircraftModel, ''),
					@New_AircraftSubModel   = ISNULL(T.AircraftSubModel, ''),
					@New_NumOfEngines       = CAST(ISNULL(T.NumOfEngines, 0) AS VARCHAR),
					@New_TailNum            = ISNULL(T.TailNum, ''),
					@New_SerialNum          = ISNULL(T.SerialNum, ''),
					@New_ManufacturedDate   = ISNULL(CONVERT(VARCHAR(30), T.ManufacturedDate,   103), ''),
					@New_PlaceInServiceDate = ISNULL(CONVERT(VARCHAR(30), T.PlaceInServiceDate, 103), ''),
					@New_TotalTSN           = CAST(CAST(ISNULL(T.TotalTSN,   0) AS INT) AS VARCHAR) + ' : ' + RIGHT('00' + CAST(CAST(ISNULL(T.TotalTSNMM, 0) AS INT) AS VARCHAR), 2),
					@New_TotalCSN           = CAST(ISNULL(T.TotalCSN, 0) AS VARCHAR(20)),
					@New_Hobbs              = CAST(ISNULL(T.Hobbs, 0) AS VARCHAR),
					@New_AircraftLocation   = ISNULL(T.AircraftLocation, ''),
					@New_NextScheduled      = ISNULL(CONVERT(VARCHAR(30), T.NextScheduled, 103), ''),
					@New_AircraftStatus     = ISNULL(T.AircraftStatus, ''),
					@New_MaintenanceStatus  = ISNULL(T.MaintenanceStatus, ''),
					@New_Memo               = ISNULL(T.Memo, ''),
					@New_IsActive           = CASE WHEN ISNULL(T.IsActive, 1) = 1 THEN 'Active' ELSE 'Inactive' END,
					@Hist_UpdatedBy         = T.UpdatedBy,
					@Hist_TailNum           = T.TailNum,
					@Hist_Make              = T.MakeType,
					@Hist_Model             = T.AircraftModel,
					@Hist_SerialNum         = T.SerialNum
				FROM @tbl_AircraftRegistryHeaderType T;

			SET @IsUpdate = 1;
            SELECT 1 AS Status, 'Saved successfully' AS Message, * FROM dbo.[AircraftRegistryHeader] WITH(NOLOCK) WHERE AircraftRegistryId = @AircraftRegistryId
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
			    SET @AircraftRegistryNum = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
		    END
		    ELSE
		    BEGIN
			    -- Generate Aircraft Registry Number
			    SET @AircraftRegistryNum = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
		    END
            INSERT INTO [AircraftRegistryHeader]
            (
                MakeTypeId,
                MakeType,
                AircraftModelId,
                AircraftModel,
                AircraftSubModel,
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
                AircraftLocation,
                NextScheduled,
                MEL,
                AircraftStatusId,
                AircraftStatus,
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
			    AircraftRegistryNumber
            )
            SELECT
                T.MakeTypeId,
                T.MakeType,
                T.AircraftModelId,
                T.AircraftModel,
                T.AircraftSubModel,
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
                T.AircraftLocation,
                T.NextScheduled,
                T.MEL,
                T.AircraftStatusId,
                T.AircraftStatus,
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
			    @AircraftRegistryNum
            FROM @tbl_AircraftRegistryHeaderType T

			SET @AircraftRegistryId = SCOPE_IDENTITY();
			SELECT 1 AS Status, 'Saved successfully' AS Message, * FROM dbo.[AircraftRegistryHeader] WITH(NOLOCK) WHERE AircraftRegistryId = @AircraftRegistryId
	    END   

		-- =====================================================
        -- HISTORY BLOCK 
        -- =====================================================
		DECLARE @TemplateCode VARCHAR(50)='',@TemplateBody VARCHAR(MAX)='',
				@CreatedBy VARCHAR(100) = NULL,@AcTailNum VARCHAR(50) = NULL,@AcMake VARCHAR(100) = NULL,
				@AcModel   VARCHAR(100) = NULL,@SerialNum VARCHAR(100) = NULL,@Activity VARCHAR(100) = NULL;

		SELECT @AcTailNum = T.TailNum,@AcMake = T.MakeType,@AcModel = T.AircraftModel,@SerialNum = T.SerialNum, @CreatedBy = T.CreatedBy,@MasterCompanyId = T.MasterCompanyId FROM @tbl_AircraftRegistryHeaderType T;

		IF(@IsUpdate = 1)
		BEGIN
			 SET @TemplateCode = 'UpdateAircraftRegistry';
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

			IF ISNULL(@Old_Memo,'')               <> @New_Memo
				SET @TemplateBody += 'Memo: '               + ISNULL(@Old_Memo,'')               + ' to ' + @New_Memo               + ' | ';

			IF ISNULL(@Old_IsActive,'')           <> @New_IsActive
				SET @TemplateBody += 'Status: '             + ISNULL(@Old_IsActive,'')           + ' to ' + @New_IsActive           + ' | ';
			 
			 -- Remove trailing ' | '
			 IF LEN(@TemplateBody) > 3
			 	SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 3);
		END
		ELSE
		BEGIN
		     SET @TemplateCode = 'AddAircraftRegistry';
			 SET @Activity = 'New Added';

			 SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[AircraftHistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @TemplateCode;

			 SET @TemplateBody = REPLACE(@TemplateBody, '##AcTailNum##', @AcTailNum)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##AcMake##', @AcMake)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##AcModel##', @AcModel)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##SerialNum##', @SerialNum)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##CreatedBy##', @CreatedBy)
			 SET @TemplateBody = REPLACE(@TemplateBody, '##CreatedDate##', GETUTCDATE())
		END

        -- ── Call usp_SaveAircraftHistory only if rows exist ───
        IF ISNULL(LTRIM(RTRIM(@TemplateBody)), '') <> ''
		BEGIN
			EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 1,@ModuleName = 'Aircraft Registry',@RefferenceId = @AircraftRegistryId,@FieldsName = NULL,
												 @OldValue = NULL,@NewValue = @AircraftRegistryNum,@HistoryText = @TemplateBody,@Activity = @Activity,@MasterCompanyId = @MasterCompanyId,
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