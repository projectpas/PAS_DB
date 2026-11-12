/*************************************************************
 ** File:   [USP_SavePreliminaryInspectionReport]
 ** Author: RAJESH GAMI
 ** Description: Creates / updates the Preliminary Inspection Report of a work order (one report per work order).
 **              A section that is signed off is read-only: its values are not changed. A Completed report cannot be saved
 **              (reopen a section first). Items come as JSON: [{itemMasterId, answer, remarks, partNumber, serialNumber, seriesNumber, selectedOption}].
 **              Returns one row: PreliminaryInspectionReportId, Success, Message.
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_SavePreliminaryInspectionReport] @WorkOrderId = 10783, @MasterCompanyId = 30, @UserName = 'ADMIN User', @WorkScope = 'LTD RPR', @ItemsJson = '[{"itemMasterId":1,"answer":"No","remarks":"ok"}]'
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SavePreliminaryInspectionReport]
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT = NULL,
@MasterCompanyId INT,
@UserName VARCHAR(256),
@WorkScope VARCHAR(200) = NULL,
@ContainerIdAttached BIT = NULL,
@ContainerCondition VARCHAR(500) = NULL,
@ReplacementRequired BIT = NULL,
@ShippingDamageAcknowledged BIT = NULL,
@LogbookQuantity INT = NULL,
@PicturesSavedInEngineFolder BIT = NULL,
@EngineState VARCHAR(20) = NULL,
@RotatingCondition VARCHAR(20) = NULL,
@LinesCapped BIT = NULL,
@InletDamage VARCHAR(1000) = NULL,
@TurbineDamage VARCHAR(1000) = NULL,
@OtherDamage VARCHAR(1000) = NULL,
@ExternalDamage VARCHAR(1000) = NULL,
@QecOther VARCHAR(500) = NULL,
@RemoveBoxCustomerHardware BIT = NULL,
@OtherPartsOther VARCHAR(500) = NULL,
@Notes NVARCHAR(MAX) = NULL,
@ItemsJson NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @ReportId BIGINT = NULL, @Status VARCHAR(20) = NULL, @Now DATETIME2(7) = GETUTCDATE(), @WopId BIGINT = @WorkOrderPartNumberId;
		DECLARE @ShipSigned BIT = 0, @EngSigned BIT = 0, @PartsSigned BIT = 0;

		IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [MasterCompanyId] = @MasterCompanyId)
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionReportId], CAST(0 AS BIT) AS [Success], 'Work Order was not found.' AS [Message];
			RETURN;
		END

		SET @EngineState = NULLIF(LTRIM(RTRIM(ISNULL(@EngineState, ''))), '');
		SET @RotatingCondition = NULLIF(LTRIM(RTRIM(ISNULL(@RotatingCondition, ''))), '');
		IF (@EngineState IS NOT NULL AND @EngineState NOT IN ('Assembled', 'Disassembled'))
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionReportId], CAST(0 AS BIT) AS [Success], 'State of engine received must be Assembled or Disassembled.' AS [Message];
			RETURN;
		END
		IF (@RotatingCondition IS NOT NULL AND @RotatingCondition NOT IN ('Free', 'SlightDrag', 'Seized'))
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionReportId], CAST(0 AS BIT) AS [Success], 'Rotating condition must be Free, Slight Drag or Seized.' AS [Message];
			RETURN;
		END

		IF (@WopId IS NULL OR NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WopId AND [WorkOrderId] = @WorkOrderId))
		BEGIN
			SELECT TOP 1 @WopId = [ID] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK)
			 WHERE [WorkOrderId] = @WorkOrderId AND ISNULL([IsDeleted], 0) = 0 ORDER BY [ID];
		END

		SELECT TOP 1 @ReportId = [PreliminaryInspectionReportId], @Status = [ReportStatus]
		  FROM [dbo].[PreliminaryInspectionReport] WITH(NOLOCK)
		 WHERE [WorkOrderId] = @WorkOrderId AND [IsDeleted] = 0
		 ORDER BY [PreliminaryInspectionReportId];

		IF (@ReportId IS NOT NULL AND @Status = 'Completed')
		BEGIN
			SELECT @ReportId AS [PreliminaryInspectionReportId], CAST(0 AS BIT) AS [Success], 'The report is Completed. Reopen a section to edit it.' AS [Message];
			RETURN;
		END

		BEGIN TRANSACTION;

		IF (@ReportId IS NULL)
		BEGIN
			INSERT INTO [dbo].[PreliminaryInspectionReport]
			       ([WorkOrderId], [WorkOrderPartNumberId], [MasterCompanyId], [WorkScope], [ReportStatus],
			        [ContainerIdAttached], [ContainerCondition], [ReplacementRequired], [ShippingDamageAcknowledged], [LogbookQuantity],
			        [PicturesSavedInEngineFolder], [EngineState], [RotatingCondition], [LinesCapped], [InletDamage], [TurbineDamage], [ExternalDamage], [OtherDamage],
			        [QecOther], [RemoveBoxCustomerHardware], [OtherPartsOther], [Notes],
			        [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES (@WorkOrderId, @WopId, @MasterCompanyId, @WorkScope, 'Draft',
			        @ContainerIdAttached, @ContainerCondition, @ReplacementRequired, @ShippingDamageAcknowledged, @LogbookQuantity,
			        @PicturesSavedInEngineFolder, @EngineState, @RotatingCondition, @LinesCapped, @InletDamage, @TurbineDamage, @ExternalDamage, @OtherDamage,
			        @QecOther, @RemoveBoxCustomerHardware, @OtherPartsOther, @Notes,
			        @UserName, @UserName, @Now, @Now, 1, 0);

			SET @ReportId = SCOPE_IDENTITY();

			INSERT INTO [dbo].[PreliminaryInspectionReportSignOff] ([PreliminaryInspectionReportId], [MasterCompanyId], [SectionCode], [IsSigned], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT @ReportId, @MasterCompanyId, S.[SectionCode], 0, @UserName, @UserName, @Now, @Now, 1, 0
			  FROM (VALUES ('SHIPPING'), ('ENGINE'), ('PARTS'), ('REVIEW')) S([SectionCode]);
		END
		ELSE
		BEGIN
			SELECT @ShipSigned = MAX(CASE WHEN [SectionCode] = 'SHIPPING' THEN CAST([IsSigned] AS INT) ELSE 0 END),
			       @EngSigned  = MAX(CASE WHEN [SectionCode] = 'ENGINE' THEN CAST([IsSigned] AS INT) ELSE 0 END),
			       @PartsSigned = MAX(CASE WHEN [SectionCode] = 'PARTS' THEN CAST([IsSigned] AS INT) ELSE 0 END)
			  FROM [dbo].[PreliminaryInspectionReportSignOff] WITH(NOLOCK)
			 WHERE [PreliminaryInspectionReportId] = @ReportId;

			UPDATE R SET
			       R.[WorkScope] = @WorkScope,
			       R.[ContainerIdAttached]          = CASE WHEN @ShipSigned = 1 THEN R.[ContainerIdAttached] ELSE @ContainerIdAttached END,
			       R.[ContainerCondition]           = CASE WHEN @ShipSigned = 1 THEN R.[ContainerCondition] ELSE @ContainerCondition END,
			       R.[ReplacementRequired]          = CASE WHEN @ShipSigned = 1 THEN R.[ReplacementRequired] ELSE @ReplacementRequired END,
			       R.[ShippingDamageAcknowledged]   = CASE WHEN @ShipSigned = 1 THEN R.[ShippingDamageAcknowledged] ELSE @ShippingDamageAcknowledged END,
			       R.[LogbookQuantity]              = CASE WHEN @ShipSigned = 1 THEN R.[LogbookQuantity] ELSE @LogbookQuantity END,
			       R.[PicturesSavedInEngineFolder]  = CASE WHEN @EngSigned = 1 THEN R.[PicturesSavedInEngineFolder] ELSE @PicturesSavedInEngineFolder END,
			       R.[EngineState]                  = CASE WHEN @EngSigned = 1 THEN R.[EngineState] ELSE @EngineState END,
			       R.[RotatingCondition]            = CASE WHEN @EngSigned = 1 THEN R.[RotatingCondition] ELSE @RotatingCondition END,
			       R.[LinesCapped]                  = CASE WHEN @EngSigned = 1 THEN R.[LinesCapped] ELSE @LinesCapped END,
			       R.[InletDamage]                  = CASE WHEN @EngSigned = 1 THEN R.[InletDamage] ELSE @InletDamage END,
			       R.[TurbineDamage]                = CASE WHEN @EngSigned = 1 THEN R.[TurbineDamage] ELSE @TurbineDamage END,
			       R.[OtherDamage]                  = CASE WHEN @EngSigned = 1 THEN R.[OtherDamage] ELSE @OtherDamage END,
			       R.[ExternalDamage]               = CASE WHEN @EngSigned = 1 THEN R.[ExternalDamage] ELSE @ExternalDamage END,
			       R.[QecOther]                     = CASE WHEN @PartsSigned = 1 THEN R.[QecOther] ELSE @QecOther END,
			       R.[RemoveBoxCustomerHardware]    = CASE WHEN @PartsSigned = 1 THEN R.[RemoveBoxCustomerHardware] ELSE @RemoveBoxCustomerHardware END,
			       R.[OtherPartsOther]              = CASE WHEN @PartsSigned = 1 THEN R.[OtherPartsOther] ELSE @OtherPartsOther END,
			       R.[Notes]                        = CASE WHEN @PartsSigned = 1 THEN R.[Notes] ELSE @Notes END,
			       R.[UpdatedBy] = @UserName,
			       R.[UpdatedDate] = @Now
			  FROM [dbo].[PreliminaryInspectionReport] R
			 WHERE R.[PreliminaryInspectionReportId] = @ReportId;
		END

		/* checklist items (QEC / Other Parts / Components); items of a signed section are not changed */
		IF (@ItemsJson IS NOT NULL AND LEN(@ItemsJson) > 2)
		BEGIN
			IF OBJECT_ID(N'tempdb..#Items') IS NOT NULL DROP TABLE #Items;

			SELECT J.[itemMasterId] AS [PreliminaryInspectionItemMasterId],
			       CASE WHEN J.[answer] IN ('Yes', 'No') THEN J.[answer] ELSE NULL END AS [Answer],
			       NULLIF(LTRIM(RTRIM(ISNULL(J.[remarks], ''))), '') AS [Remarks],
			       NULLIF(LTRIM(RTRIM(ISNULL(J.[partNumber], ''))), '') AS [PartNumber],
			       NULLIF(LTRIM(RTRIM(ISNULL(J.[serialNumber], ''))), '') AS [SerialNumber],
			       NULLIF(LTRIM(RTRIM(ISNULL(J.[seriesNumber], ''))), '') AS [SeriesNumber],
			       CASE WHEN J.[selectedOption] IN (1, 2) THEN CAST(J.[selectedOption] AS TINYINT) ELSE NULL END AS [SelectedOption],
			       M.[SectionCode], M.[ItemName], M.[SortOrder]
			  INTO #Items
			  FROM OPENJSON(@ItemsJson) WITH (
			           [itemMasterId]   BIGINT        '$.itemMasterId',
			           [answer]         VARCHAR(3)    '$.answer',
			           [remarks]        VARCHAR(500)  '$.remarks',
			           [partNumber]     VARCHAR(100)  '$.partNumber',
			           [serialNumber]   VARCHAR(100)  '$.serialNumber',
			           [seriesNumber]   VARCHAR(100)  '$.seriesNumber',
			           [selectedOption] INT           '$.selectedOption') J
			       INNER JOIN [dbo].[PreliminaryInspectionItemMaster] M WITH(NOLOCK)
			               ON M.[PreliminaryInspectionItemMasterId] = J.[itemMasterId] AND M.[MasterCompanyId] = @MasterCompanyId
			 WHERE @PartsSigned = 0;

			UPDATE I SET
			       I.[Answer] = T.[Answer], I.[Remarks] = T.[Remarks], I.[PartNumber] = T.[PartNumber],
			       I.[SerialNumber] = T.[SerialNumber], I.[SeriesNumber] = T.[SeriesNumber], I.[SelectedOption] = T.[SelectedOption],
			       I.[ItemName] = T.[ItemName], I.[SortOrder] = T.[SortOrder],
			       I.[UpdatedBy] = @UserName, I.[UpdatedDate] = @Now, I.[IsDeleted] = 0
			  FROM [dbo].[PreliminaryInspectionReportItem] I
			       INNER JOIN #Items T ON T.[PreliminaryInspectionItemMasterId] = I.[PreliminaryInspectionItemMasterId]
			 WHERE I.[PreliminaryInspectionReportId] = @ReportId
			   AND (ISNULL(I.[Answer], '') <> ISNULL(T.[Answer], '') OR ISNULL(I.[Remarks], '') <> ISNULL(T.[Remarks], '')
			        OR ISNULL(I.[PartNumber], '') <> ISNULL(T.[PartNumber], '') OR ISNULL(I.[SerialNumber], '') <> ISNULL(T.[SerialNumber], '')
			        OR ISNULL(I.[SeriesNumber], '') <> ISNULL(T.[SeriesNumber], '') OR ISNULL(I.[SelectedOption], 0) <> ISNULL(T.[SelectedOption], 0)
			        OR I.[IsDeleted] = 1);

			INSERT INTO [dbo].[PreliminaryInspectionReportItem]
			       ([PreliminaryInspectionReportId], [PreliminaryInspectionItemMasterId], [MasterCompanyId], [SectionCode], [ItemName], [SortOrder],
			        [Answer], [Remarks], [PartNumber], [SerialNumber], [SeriesNumber], [SelectedOption],
			        [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			SELECT @ReportId, T.[PreliminaryInspectionItemMasterId], @MasterCompanyId, T.[SectionCode], T.[ItemName], T.[SortOrder],
			       T.[Answer], T.[Remarks], T.[PartNumber], T.[SerialNumber], T.[SeriesNumber], T.[SelectedOption],
			       @UserName, @UserName, @Now, @Now, 1, 0
			  FROM #Items T
			 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[PreliminaryInspectionReportItem] I
			                    WHERE I.[PreliminaryInspectionReportId] = @ReportId
			                      AND I.[PreliminaryInspectionItemMasterId] = T.[PreliminaryInspectionItemMasterId]);
		END

		COMMIT TRANSACTION;

		SELECT @ReportId AS [PreliminaryInspectionReportId], CAST(1 AS BIT) AS [Success], 'Preliminary Inspection Report saved successfully.' AS [Message];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SavePreliminaryInspectionReport'
			, @ProcedureParameters VARCHAR(3000) = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			EXEC spLogException
				@DatabaseName = @DatabaseName
				, @AdhocComments = @AdhocComments
				, @ProcedureParameters = @ProcedureParameters
				, @ApplicationName = @ApplicationName
				, @ErrorLogID = @ErrorLogID OUTPUT;
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
			RETURN(1);
	END CATCH
END
