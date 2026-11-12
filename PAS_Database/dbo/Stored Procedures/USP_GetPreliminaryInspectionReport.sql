/*************************************************************
 ** File:   [USP_GetPreliminaryInspectionReport]
 ** Author: RAJESH GAMI
 ** Description: Preliminary Inspection Report of a work order for the screen / PDF. Returns 4 result sets:
 **              1) header (work order values + saved report values, one row, also when the report is not created yet)
 **              2) checklist items (master data of the company + saved answers)
 **              3) sign-off of the 4 sections
 **              4) photos
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_GetPreliminaryInspectionReport] @WorkOrderId = 10783, @WorkOrderPartNumberId = NULL, @MasterCompanyId = 30
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetPreliminaryInspectionReport]
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT = NULL,
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @ReportId BIGINT = NULL, @WopId BIGINT = @WorkOrderPartNumberId;

		IF (@WopId IS NULL OR NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WopId AND [WorkOrderId] = @WorkOrderId))
		BEGIN
			SELECT TOP 1 @WopId = [ID] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK)
			 WHERE [WorkOrderId] = @WorkOrderId AND ISNULL([IsDeleted], 0) = 0 ORDER BY [ID];
		END

		SELECT TOP 1 @ReportId = R.[PreliminaryInspectionReportId]
		  FROM [dbo].[PreliminaryInspectionReport] R WITH(NOLOCK)
		 WHERE R.[WorkOrderId] = @WorkOrderId AND R.[IsDeleted] = 0
		 ORDER BY R.[PreliminaryInspectionReportId];

		/* 1) header */
		SELECT R.[PreliminaryInspectionReportId],
		       WO.[WorkOrderId],
		       WOP.[ID] AS [WorkOrderPartNumberId],
		       WO.[MasterCompanyId],
		       WO.[WorkOrderNum],
		       ISNULL(NULLIF(CUST.[CustomerCode], ''), ISNULL(WO.[CustomerName], '')) AS [CustomerName],
		       ISNULL(WOP.[RevisedPartNumber], '') AS [EngineModel],
		       ISNULL(IM.[partnumber], ISNULL(WOP.[PartNumber], '')) AS [EnginePartNumber],
		       ISNULL(NULLIF(WOP.[CurrentSerialNumber], ''), ISNULL(WOP.[RevisedSerialNumber], '')) AS [EngineSerialNumber],
		       ISNULL(WS.[WorkScopeCode], '') AS [DefaultWorkScope],
		       ISNULL(R.[WorkScope], ISNULL(NULLIF(WOP.[WorkScope], ''), ISNULL(WS.[WorkScopeCode], ''))) AS [WorkScope],
		       ISNULL(R.[ReportStatus], 'Draft') AS [ReportStatus],
		       CAST(CASE WHEN R.[PreliminaryInspectionReportId] IS NULL THEN 0 ELSE 1 END AS BIT) AS [IsCreated],
		       R.[CompletedBy], R.[CompletedDate],
		       R.[ContainerIdAttached], R.[ContainerCondition], R.[ReplacementRequired], R.[ShippingDamageAcknowledged], R.[LogbookQuantity],
		       R.[PicturesSavedInEngineFolder], R.[EngineState], R.[RotatingCondition], R.[LinesCapped],
		       R.[InletDamage], R.[TurbineDamage], R.[ExternalDamage], R.[OtherDamage],
		       R.[QecOther], R.[RemoveBoxCustomerHardware], R.[OtherPartsOther], R.[Notes],
		       R.[CreatedBy], R.[CreatedDate], R.[UpdatedBy], R.[UpdatedDate]
		  FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
		       LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.[ID] = @WopId
		       LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WOP.[ItemMasterId] = IM.[ItemMasterId]
		       LEFT JOIN [dbo].[WorkScope] WS WITH(NOLOCK) ON WOP.[WorkOrderScopeId] = WS.[WorkScopeId]
		       LEFT JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON WO.[CustomerId] = CUST.[CustomerId]
		       LEFT JOIN [dbo].[PreliminaryInspectionReport] R WITH(NOLOCK) ON R.[PreliminaryInspectionReportId] = @ReportId
		 WHERE WO.[WorkOrderId] = @WorkOrderId AND WO.[MasterCompanyId] = @MasterCompanyId;

		/* 2) checklist items: master data of the company + saved answers (a retired item stays visible when it was answered) */
		SELECT M.[PreliminaryInspectionItemMasterId],
		       M.[SectionCode],
		       M.[ItemName],
		       M.[SortOrder],
		       M.[OptionLabel1],
		       M.[OptionLabel2],
		       I.[Answer],
		       I.[Remarks],
		       I.[PartNumber],
		       I.[SerialNumber],
		       I.[SeriesNumber],
		       I.[SelectedOption]
		  FROM [dbo].[PreliminaryInspectionItemMaster] M WITH(NOLOCK)
		       LEFT JOIN [dbo].[PreliminaryInspectionReportItem] I WITH(NOLOCK)
		              ON I.[PreliminaryInspectionItemMasterId] = M.[PreliminaryInspectionItemMasterId]
		             AND I.[PreliminaryInspectionReportId] = @ReportId AND I.[IsDeleted] = 0
		 WHERE M.[MasterCompanyId] = @MasterCompanyId
		   AND ((M.[IsDeleted] = 0 AND M.[IsActive] = 1) OR I.[PreliminaryInspectionReportItemId] IS NOT NULL)
		 ORDER BY CASE M.[SectionCode] WHEN 'QEC' THEN 1 WHEN 'OTHERPARTS' THEN 2 ELSE 3 END, M.[SortOrder], M.[PreliminaryInspectionItemMasterId];

		/* 3) sign-off of the 4 sections */
		SELECT S.[SectionCode],
		       CAST(ISNULL(SO.[IsSigned], 0) AS BIT) AS [IsSigned],
		       SO.[SignedBy], SO.[SignedInitials], SO.[SignedDate], SO.[ReopenedBy], SO.[ReopenedDate]
		  FROM (VALUES ('SHIPPING', 1), ('ENGINE', 2), ('PARTS', 3), ('REVIEW', 4)) S([SectionCode], [SortNo])
		       LEFT JOIN [dbo].[PreliminaryInspectionReportSignOff] SO WITH(NOLOCK)
		              ON SO.[SectionCode] = S.[SectionCode] AND SO.[PreliminaryInspectionReportId] = @ReportId
		 ORDER BY S.[SortNo];

		/* 4) photos */
		SELECT P.[PreliminaryInspectionReportPhotoId], P.[SectionCode], P.[FileName], P.[FilePath], P.[FileType], P.[FileSize],
		       P.[CreatedBy], P.[CreatedDate]
		  FROM [dbo].[PreliminaryInspectionReportPhoto] P WITH(NOLOCK)
		 WHERE P.[PreliminaryInspectionReportId] = @ReportId AND P.[IsDeleted] = 0
		 ORDER BY P.[PreliminaryInspectionReportPhotoId];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetPreliminaryInspectionReport'
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
