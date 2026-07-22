/*************************************************************           
 ** File:   [GetWorkOrderSettlementDetailsForStageChangeNew]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used Work order Settlement Details for Stage Change
 ** Purpose:         
 ** Date:   10/07/2026
 ** PARAMETERS:                   
 ** RETURN VALUE:         
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    10/07/2026   Moin Bloch 	    Created
	2    21/07/2026   Moin Bloch 	    added ControlNumber to display Confirm Outgoing MPN and Final Disposition Popup List

  EXEC [GetWorkOrderSettlementDetailsForStageChangeNew] 4345,2
  EXEC [GetWorkOrderSettlementDetailsForStageChangeNew] 14353,2
  EXEC [GetWorkOrderSettlementDetailsForStageChangeNew] 4291,2
**************************************************************/
CREATE   PROCEDURE [dbo].[GetWorkOrderSettlementDetailsForStageChangeNew]
@WorkorderId BIGINT,
@EmployeeId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM [dbo].[Employee] E WITH (NOLOCK) 
			LEFT JOIN [dbo].[TimeZone] ETZ WITH (NOLOCK) ON E.[TimeZoneId] = ETZ.[TimeZoneId]
			LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON E.[LegalEntityId] = LE.[LegalEntityId]
			LEFT JOIN [dbo].[TimeZone] LTZ WITH (NOLOCK) ON LE.[TimeZoneId] = LTZ.[TimeZoneId]
		WHERE E.[EmployeeId] = @EmployeeId; 

		DECLARE @WOModuleId INT

		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

	BEGIN TRY
	BEGIN TRANSACTION
  
				DECLARE @TaskStatusID INT;
				DECLARE @MasterCompanyID INT;
				DECLARE @AvailableStatusID INT;
				DECLARE @ProvisionId INT;
				DECLARE @RepairProvisionId INT;
				DECLARE @MaterialSettlement INT,@LaborSettlement INT,@AllToolsSettlement INT

				SELECT @ProvisionId = [ProvisionId] FROM [DBO].[Provision] WITH (NOLOCK) WHERE [StatusCode] = 'REPLACE';
				SELECT @RepairProvisionId = [ProvisionId] FROM [DBO].[Provision] WITH (NOLOCK) WHERE [StatusCode] = 'REPAIR';
		
				SELECT @MaterialSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'Material Required is Issued';
				SELECT @LaborSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'Labor Entries Confirmed';
				SELECT @AllToolsSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'All Tools Checked Out of Work Order';

				SELECT @MasterCompanyID = [MasterCompanyId] FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkorderId

				SELECT @TaskStatusID = [TaskStatusId] FROM [dbo].[TaskStatus] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyID AND UPPER([StatusCode]) = 'COMPLETED'

				SELECT @AvailableStatusID = [AssetAvailableStatusId] FROM [dbo].[AssetAvailableStatus] WITH (NOLOCK) WHERE UPPER([Status]) = 'AVAILABLE'

				;WITH WFList AS (
					-- Every distinct WorkFlowWorkOrderId / workOrderPartNoId pair that belongs to this WorkOrderId.
					-- All the per-row aggregates below are scoped to this set instead of a single passed-in pair.
					SELECT DISTINCT [WorkFlowWorkOrderId], [workOrderPartNoId]
					FROM [dbo].[WorkOrderSettlementDetails] WITH(NOLOCK)
					WHERE [WorkOrderId] = @WorkorderId
				),
				MatAgg AS (
					SELECT WOM.[WorkFlowWorkOrderId],
						SUM(ISNULL(WOM.[Quantity],0)) AS qtyreq
					FROM WFList wf
						JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
					WHERE ISNULL(WOM.[IsDeleted],0) = 0
					GROUP BY WOM.[WorkFlowWorkOrderId]
				),
				OtherMatProvAgg AS (
					SELECT WOM.[WorkFlowWorkOrderId],
						SUM(ISNULL(WOM.[Quantity],0)) AS OtherMaterialsProvisionQty
					FROM WFList wf
						JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.[WorkOrderMaterialsId] = WOMS.[WorkOrderMaterialsId]
					WHERE WOM.[ProvisionId] != @ProvisionId
						AND ISNULL(WOMS.[IsDeleted],0) = 0
						AND WOMS.[WOMStockLineId] IS NULL
					GROUP BY WOM.[WorkFlowWorkOrderId]
				),
				QtyIssueAgg AS (
					SELECT WOM.[WorkFlowWorkOrderId],
						SUM(ISNULL(WOMS.[QtyIssued],0)) AS qtyissue
					FROM WFList wf
						JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.[WorkOrderMaterialsId] = WOMS.[WorkOrderMaterialsId]
					WHERE ISNULL(WOM.[IsDeleted],0) = 0
						AND WOMS.[ProvisionId] IN (@ProvisionId, @RepairProvisionId)
					GROUP BY WOM.[WorkFlowWorkOrderId]
				),
				OtherProvAgg AS (
					SELECT WOM.[WorkFlowWorkOrderId],
						SUM(ISNULL(WOMS.[Quantity],0)) AS OtherProvisionQty
					FROM WFList wf
						JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.[WorkOrderMaterialsId] = WOMS.[WorkOrderMaterialsId]
					WHERE ISNULL(WOM.[IsDeleted],0) = 0
						AND WOMS.[ProvisionId] NOT IN (@ProvisionId, @RepairProvisionId)
					GROUP BY WOM.[WorkFlowWorkOrderId]
				),
				KitAgg AS (
					SELECT WOMK.[WorkFlowWorkOrderId],
						SUM(ISNULL(WOMK.[Quantity],0)) AS kitqtyreq
					FROM WFList wf
						JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
					GROUP BY WOMK.[WorkFlowWorkOrderId]
				),
				OtherMatProvKitAgg AS (
					SELECT WOMK.[WorkFlowWorkOrderId],
						SUM(ISNULL(WOMK.[Quantity],0)) AS OtherMaterialsProvisionKitQty
					FROM WFList wf
						JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMSK WITH(NOLOCK) ON WOMK.[WorkOrderMaterialsKitId] = WOMSK.[WorkOrderMaterialsKitId]
					WHERE WOMK.[ProvisionId] != @ProvisionId
						AND WOMSK.[WorkOrderMaterialStockLineKitId] IS NULL
					GROUP BY WOMK.[WorkFlowWorkOrderId]
				),
				KitIssueAgg AS (
					SELECT WOMK.[WorkFlowWorkOrderId],
						SUM(ISNULL(WOMSK.[QtyIssued],0)) AS kitqtyissue
					FROM WFList wf
						JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMSK WITH(NOLOCK) ON WOMK.[WorkOrderMaterialsKitId] = WOMSK.[WorkOrderMaterialsKitId]
					WHERE WOMSK.[ProvisionId] IN (@ProvisionId, @RepairProvisionId)
					GROUP BY WOMK.[WorkFlowWorkOrderId]
				),
				OtherProvKitAgg AS (
					SELECT WOMK.[WorkFlowWorkOrderId],
						SUM(ISNULL(WOMSK.[Quantity],0)) AS OtherProvisionKitQty
					FROM WFList wf
						JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMSK WITH(NOLOCK) ON WOMK.[WorkOrderMaterialsKitId] = WOMSK.[WorkOrderMaterialsKitId]
					WHERE WOMSK.[ProvisionId] NOT IN (@ProvisionId, @RepairProvisionId)
					GROUP BY WOMK.[WorkFlowWorkOrderId]
				),
				LaborFlagAgg AS (
					-- Mirrors the source: only reads from active (IsDeleted = 0) headers
					SELECT WLH.[WorkFlowWorkOrderId],
						MAX(CAST(ISNULL(WLH.[IsLaborTrackingTurnedOff],0) AS INT)) AS IsLaborTrackingTurnedOff
					FROM WFList wf
						JOIN [dbo].[WorkOrderLaborHeader] WLH WITH(NOLOCK) ON WLH.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
					WHERE WLH.[WorkOrderId] = @WorkorderId AND ISNULL(WLH.[IsDeleted], 0) = 0
					GROUP BY WLH.[WorkFlowWorkOrderId]
				),
				LaborCountAgg AS (
					-- Mirrors the source exactly: the outer gate checks WLH.IsDeleted, but the count
					-- itself only filters on WL.IsDeleted (not WLH.IsDeleted) - a deliberate asymmetry
					-- in this proc that differs from the sibling procs, preserved as-is.
					SELECT WLH.[WorkFlowWorkOrderId],
						COUNT(WL.[WorkOrderLaborId]) AS IsLaborCompleled
					FROM WFList wf
						JOIN [dbo].[WorkOrderLaborHeader] WLH WITH(NOLOCK) ON WLH.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						JOIN [dbo].[WorkOrderLabor] WL WITH(NOLOCK) ON WL.[WorkOrderLaborHeaderId] = WLH.[WorkOrderLaborHeaderId]
					WHERE WLH.[WorkOrderId] = @WorkorderId
						AND WL.[IsDeleted] = 0
						AND ISNULL(WL.[TaskStatusId], 0) <> @TaskStatusID
						AND EXISTS (
							SELECT 1 FROM [dbo].[WorkOrderLaborHeader] WLH2 WITH(NOLOCK)
							WHERE WLH2.[WorkFlowWorkOrderId] = WLH.[WorkFlowWorkOrderId] AND WLH2.[IsDeleted] = 0
						)
					GROUP BY WLH.[WorkFlowWorkOrderId]
				),
				ToolsAgg AS (
					SELECT COCI.[workOrderPartNoId],
						COUNT(COCI.[CheckInCheckOutWorkOrderAssetId]) AS AllToolsAreCheckOut
					FROM WFList wf
						JOIN [dbo].[CheckInCheckOutWorkOrderAsset] COCI WITH(NOLOCK) ON COCI.[workOrderPartNoId] = wf.[workOrderPartNoId]
					WHERE COCI.[WorkOrderId] = @WorkorderId AND COCI.[IsDeleted] = 0 AND ISNULL(COCI.[InventoryStatusId], 0) <> @AvailableStatusID
					GROUP BY COCI.[workOrderPartNoId]
				),
				ShippingAgg AS (
					SELECT WOSI.[WorkOrderPartNumId] AS workOrderPartNoId,
						COUNT(WOSI.[WorkOrderShippingId]) AS IsShippingCompleled
					FROM WFList wf
						JOIN [dbo].[WorkOrderShippingItem] WOSI WITH(NOLOCK) ON WOSI.[WorkOrderPartNumId] = wf.[workOrderPartNoId]
					GROUP BY WOSI.[WorkOrderPartNumId]
				),
				BillingAgg AS (
					SELECT wop.[ID] AS workOrderPartNoId,
						COUNT(wobi.[BillingInvoicingId]) AS IsBillingCompleled
					FROM [DBO].[BillingInvoicing] wobi WITH(NOLOCK)  
						INNER JOIN [DBO].[BillingInvoicingItems] wobii WITH(NOLOCK) ON wobi.[BillingInvoicingId] = wobii.[BillingInvoicingId] AND wobii.[ModuleId] = @WOModuleId
						INNER JOIN [DBO].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wop.[WorkOrderId] = wobi.[ReferenceId] AND wop.[ID] = wobii.[SubReferenceId] AND wobi.[ModuleId] = @WOModuleId
						INNER JOIN [DBO].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.[ID] = wowf.[WorkOrderPartNoId]
					WHERE wop.[WorkOrderId] = @WorkorderId AND ISNULL(wobi.[IsVersionIncrease],0) = 0 AND wobi.[InvoiceStatus] = 'Invoiced' AND ISNULL(wobii.[IsPerformaInvoice], 0) = 0
					GROUP BY wop.[ID]
				),
				PaymentAgg AS (
					SELECT WOBII.[SubReferenceId] AS workOrderPartNoId,
						CASE WHEN (ISNULL(SUM(WOBI.[RemainingAmount]),0) - ISNULL(SUM(WOBI.[GrandTotal]), 0)) = 0 THEN 0 ELSE 1 END AS IsPaymentReceived
					FROM WFList wf
						JOIN [dbo].[BillingInvoicing] WOBI WITH(NOLOCK) ON WOBI.[ReferenceId] = @WorkorderId AND WOBI.[ModuleId] = @WOModuleId
						JOIN [dbo].[BillingInvoicingItems] WOBII WITH(NOLOCK) ON WOBII.[BillingInvoicingId] = WOBI.[BillingInvoicingId] AND WOBII.[SubReferenceId] = wf.[workOrderPartNoId]
					WHERE ISNULL(WOBI.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBI.[IsVersionIncrease], 0) = 0 AND WOBI.[IsDeleted] = 0
						AND ISNULL(WOBII.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBII.[IsVersionIncrease], 0) = 0 AND WOBII.[IsDeleted] = 0
					GROUP BY WOBII.[SubReferenceId]
				),
				Combined AS (
					SELECT wf.[WorkFlowWorkOrderId],
						wf.[workOrderPartNoId],
						ISNULL(ma.[qtyreq],0) + ISNULL(ka.[kitqtyreq],0) - ISNULL(omp.[OtherMaterialsProvisionQty],0) - ISNULL(ompk.[OtherMaterialsProvisionKitQty],0) AS qtyrequested,
						ISNULL(qi.[qtyissue],0) + ISNULL(ki.[kitqtyissue],0) + ISNULL(op.[OtherProvisionQty],0) + ISNULL(opk.[OtherProvisionKitQty],0) AS qtyissued,
						ISNULL(lc.[IsLaborCompleled], 0) AS IsLaborCompleled,
						ISNULL(lf.[IsLaborTrackingTurnedOff], 0) AS IsLaborTrackingTurnedOff,
						ISNULL(ta.[AllToolsAreCheckOut], 0) AS AllToolsAreCheckOut,
						ISNULL(sa.[IsShippingCompleled], 0) AS IsShippingCompleled,
						ISNULL(ba.[IsBillingCompleled], 0) AS IsBillingCompleled,
						CASE WHEN ISNULL(pa.[IsPaymentReceived], 0) = 1 THEN 0 ELSE 1 END AS IsAllowReopenWO
					FROM WFList wf
						LEFT JOIN MatAgg ma ON ma.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN OtherMatProvAgg omp ON omp.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN QtyIssueAgg qi ON qi.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN OtherProvAgg op ON op.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN KitAgg ka ON ka.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN OtherMatProvKitAgg ompk ON ompk.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN KitIssueAgg ki ON ki.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN OtherProvKitAgg opk ON opk.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN LaborFlagAgg lf ON lf.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN LaborCountAgg lc ON lc.[WorkFlowWorkOrderId] = wf.[WorkFlowWorkOrderId]
						LEFT JOIN ToolsAgg ta ON ta.[workOrderPartNoId] = wf.[workOrderPartNoId]
						LEFT JOIN ShippingAgg sa ON sa.[workOrderPartNoId] = wf.[workOrderPartNoId]
						LEFT JOIN BillingAgg ba ON ba.[workOrderPartNoId] = wf.[workOrderPartNoId]
						LEFT JOIN PaymentAgg pa ON pa.[workOrderPartNoId] = wf.[workOrderPartNoId]
				)
				SELECT  wosd.[WorkOrderId], 
						wos.[WorkOrderSettlementName], 
						wos.[WorkOrderSettlementId], 
						ISNULL(wosd.[WorkFlowWorkOrderId],0) as WorkFlowWorkOrderId,
						ISNULL(wosd.[workOrderPartNoId],0) as workOrderPartNoId,
						ISNULL(wosd.[WorkOrderSettlementDetailId],0) as WorkOrderSettlementDetailId,
						CASE WHEN wos.[WorkOrderSettlementId] = @MaterialSettlement THEN CASE WHEN ISNULL(c.[qtyrequested], 0) = ISNULL(c.[qtyissued], 0) THEN 1 ELSE 0 END 
							 WHEN wos.[WorkOrderSettlementId] = @LaborSettlement THEN CASE WHEN ISNULL(c.[IsLaborTrackingTurnedOff], 0) = 1 THEN 1 WHEN ISNULL(c.[IsLaborCompleled],0) <= 0 THEN 1 ELSE 0 END 
							 WHEN wos.[WorkOrderSettlementId] = @AllToolsSettlement THEN CASE WHEN ISNULL(c.[AllToolsAreCheckOut],0) <= 0 THEN 1 ELSE 0 END 
						ELSE wosd.[IsMastervalue] END
						AS IsMastervalue,
						wosd.[Isvalue_NA],
						wosd.[Memo],
						ISNULL(wosd.[ConditionId],0) as ConditionId,
						ISNULL(wosd.[UserId],0) as UserId,
						wosd.[conditionName],
						wosd.[UserName],
						CASE WHEN CAST(wosd.[sattlement_DateTime] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (Cast([DBO].[ConvertUTCtoLocal](wosd.[sattlement_DateTime], @CurrntEmpTimeZoneDesc) AS DATETIME)) END AS sattlement_DateTime,
						wosd.[MasterCompanyId],
						wosd.[CreatedBy],
						wosd.[UpdatedBy],
						wosd.[CreatedDate],
						wosd.[UpdatedDate],
						wosd.[IsActive],
						wosd.[IsDeleted],
						wosd.[RevisedPartId],
						IM.[partnumber] as RevisedPartNumber,
						WOP.[ItemMasterId],
						CASE WHEN WOP.[RevisedPartNumber] IS NOT NULL AND WOP.[RevisedPartNumber] <> '' THEN WOP.[RevisedPartNumber] ELSE WOP.[PartNumber] END AS PartNumber,
						CASE WHEN WOP.[RevisedSerialNumber] IS NOT NULL AND WOP.[RevisedSerialNumber] <> '' THEN WOP.[RevisedSerialNumber] ELSE WOP.[CurrentSerialNumber] END AS SerialNumber,
						WOP.[RevisedSerialNumber],
						CASE WHEN WOP.[RevisedConditionId] > 0 THEN WOP.[RevisedConditionId] ELSE WOP.[ConditionId] END [FinalConditionId],
						CASE WHEN WOP.[RevisedConditionId] > 0 THEN WORC.[Code] ELSE WOC.[Code] END [FinalConditionName],
						CASE WHEN ISNULL(c.[IsShippingCompleled],0) > 0 THEN 1 ELSE 0 END [IsShippingCompleled],
						CASE WHEN ISNULL(c.[IsBillingCompleled],0) > 0 THEN 1 ELSE 0 END [IsBillingCompleled],
						ISNULL(c.[IsAllowReopenWO], 1) AS IsAllowReopenWO,
						ISNULL(WOP.[IsFinishGood],0) AS IsFinishGood,
						ISNULL(WOP.[IsClosed],0) AS IsWOClose,
						ISNULL(SL.[ControlNumber],'') [ControlNumber]
				INTO #SettlementRows
				FROM [DBO].[WorkOrderSettlement] wos  WITH(NOLOCK)
					LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosd WITH(NOLOCK) ON wosd.[WorkOrderSettlementId] = wos.[WorkOrderSettlementId]
					LEFT JOIN Combined c ON c.[WorkFlowWorkOrderId] = wosd.[WorkFlowWorkOrderId] AND c.[workOrderPartNoId] = wosd.[workOrderPartNoId]
					LEFT JOIN [dbo].[ItemMaster] IM ON IM.[ItemMasterId] = wosd.[RevisedPartId] AND ISNULL(IM.IsNonStock,0) = 0
					LEFT JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.[ID] = wosd.[workOrderPartNoId]
					LEFT JOIN [dbo].[StockLine] SL WITH(NOLOCK) ON WOP.[StockLineId] = SL.[StockLineId] AND ISNULL(SL.IsNonStock,0) = 0
					LEFT JOIN [dbo].[Condition] WOC WITH(NOLOCK) ON WOC.[ConditionId] = WOP.[ConditionId]
					LEFT JOIN [dbo].[Condition] WORC WITH(NOLOCK) ON WORC.[ConditionId] = WOP.[RevisedConditionId]	
				WHERE wosd.[WorkOrderId] = @WorkorderId

				-- ============================================================
				-- Pivot: one row per WorkOrderId/WorkFlowWorkOrderId/workOrderPartNoId,
				-- with each WorkOrderSettlementName's WorkOrderSettlementId/
				-- WorkOrderSettlementDetailId/IsMastervalue/Isvalue_NA pivoted into
				-- its own prefixed set of columns - same field set as
				-- GetWorkOrderSettlementDetailsNew's pivot. Memo/ConditionId/UserId/
				-- conditionName/UserName/sattlement_DateTime/MasterCompanyId/CreatedBy/
				-- UpdatedBy/CreatedDate/UpdatedDate/IsActive/IsDeleted stay in
				-- #SettlementRows (available if needed) but aren't pivoted or
				-- surfaced in the final result, since they vary per settlement row
				-- and don't collapse meaningfully into a single per-part value.
				-- ============================================================
				DECLARE @cols NVARCHAR(MAX) = N'';
				DECLARE @sql NVARCHAR(MAX);

				SELECT @cols = @cols +
					N',MAX(CASE WHEN [WorkOrderSettlementId] = ' + CAST([WorkOrderSettlementId] AS VARCHAR(10)) + N' THEN CAST([WorkOrderSettlementId] AS INT) END) AS [' + [CleanName] + N'_WorkOrderSettlementId]' +
					N',MAX(CASE WHEN [WorkOrderSettlementId] = ' + CAST([WorkOrderSettlementId] AS VARCHAR(10)) + N' THEN CAST([WorkOrderSettlementDetailId] AS BIGINT) END) AS [' + [CleanName] + N'_WorkOrderSettlementDetailId]' +
					N',MAX(CASE WHEN [WorkOrderSettlementId] = ' + CAST([WorkOrderSettlementId] AS VARCHAR(10)) + N' THEN CAST([IsMastervalue] AS INT) END) AS [' + [CleanName] + N'_IsMastervalue]' +
					N',MAX(CASE WHEN [WorkOrderSettlementId] = ' + CAST([WorkOrderSettlementId] AS VARCHAR(10)) + N' THEN CAST([Isvalue_NA] AS INT) END) AS [' + [CleanName] + N'_Isvalue_NA]'
				FROM (
					SELECT DISTINCT [WorkOrderSettlementId], [WorkOrderSettlementName],
						REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([WorkOrderSettlementName], ',', ''), '(', ''), ')', ''), '/', ''), ' ', '_') AS [CleanName]
					FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK)
				) x
				ORDER BY [WorkOrderSettlementId];

				SET @sql = N'
				SELECT
					[WorkOrderId],
					[WorkFlowWorkOrderId],
					[workOrderPartNoId],
					MAX([RevisedPartId]) AS [RevisedPartId],
					MAX([RevisedPartNumber]) AS [RevisedPartNumber],
					MAX([ItemMasterId]) AS [ItemMasterId],
					MAX([PartNumber]) AS [PartNumber],
					MAX([SerialNumber]) AS [SerialNumber],
					MAX([FinalConditionId]) AS [FinalConditionId],
					MAX([FinalConditionName]) AS [FinalConditionName],
					MAX([RevisedSerialNumber]) AS [RevisedSerialNumber],
					MAX(CAST([IsShippingCompleled] AS INT)) AS [IsShippingCompleled],
					MAX(CAST([IsBillingCompleled] AS INT)) AS [IsBillingCompleled],
					MAX(CAST([IsAllowReopenWO] AS INT)) AS [IsAllowReopenWO],
					MAX(CAST([IsFinishGood] AS INT)) AS [IsFinishGood],
					MAX(CAST([IsWOClose] AS INT)) AS [IsWOClose],
					MAX([ControlNumber]) AS [ControlNumber]'
					+ @cols + N'
				FROM #SettlementRows
				GROUP BY [WorkOrderId], [WorkFlowWorkOrderId], [workOrderPartNoId]';

				EXEC sp_executesql @sql;

				DROP TABLE #SettlementRows;
			
	COMMIT TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderSettlementDetailsForStageChangeNew' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, 0) AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END