/*************************************************************           
 ** File:   [GetSubWorkOrderSettlementDetailsNew]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used Work order Settlement Details  
 ** Purpose:         
 ** Date:   16/07/2026                  
 ** PARAMETERS:                     
 ** RETURN VALUE:         
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/07/2026   Moin Bloch     Created

	EXEC [dbo].[GetSubWorkOrderSettlementDetailsNew] 4352,261
**************************************************************/
CREATE   PROCEDURE [dbo].[GetSubWorkOrderSettlementDetailsNew]
@WorkorderId BIGINT,
@SubWorkOrderId BIGINT,
@EmployeeId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @TaskStatusID INT;
				DECLARE @MasterCompanyID INT;
				DECLARE @AvailableStatusID INT;
				DECLARE @ProvisionId INT; -- FOR REPLACE
				 SELECT @ProvisionId = [ProvisionId] FROM [dbo].[Provision] WITH (NOLOCK) WHERE [StatusCode] = 'REPLACE'
				DECLARE @MaterialSettlement INT,@LaborSettlement INT,@AllToolsSettlement INT

				SELECT @MasterCompanyID = [MasterCompanyId] FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkorderId

				SELECT @TaskStatusID = [TaskStatusId] FROM [dbo].[TaskStatus] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyID AND UPPER([StatusCode]) = 'COMPLETED'

				SELECT @AvailableStatusID = [AssetAvailableStatusID] FROM [dbo].[AssetAvailableStatus] WITH (NOLOCK) WHERE UPPER([Status]) = 'AVAILABLE'

				SELECT @MaterialSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'Material Required is Issued'
				SELECT @LaborSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'Labor Entries Confirmed'
				SELECT @AllToolsSettlement = [WorkOrderSettlementId] FROM [dbo].[WorkOrderSettlement] WITH (NOLOCK) WHERE [WorkOrderSettlementName] = 'All Tools Checked Out of Work Order'
				
				;WITH SWFList AS (					
					SELECT DISTINCT [SubWOPartNoId]
					FROM [dbo].[SubWorkOrderSettlementDetails] WITH(NOLOCK)
					WHERE [WorkOrderId] = @WorkorderId AND [SubWorkOrderId] = @SubWorkOrderId
				),
				MatAgg AS (
					SELECT WOM.[SubWOPartNoId], SUM(ISNULL(WOM.[Quantity],0)) AS qtyreq
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[SubWOPartNoId] = swf.[SubWOPartNoId]
					WHERE WOM.[WorkOrderId] = @WorkorderId AND WOM.[SubWorkOrderId] = @SubWorkOrderId
					GROUP BY WOM.[SubWOPartNoId]
				),
				QtyIssueAgg AS (
					SELECT WOM.[SubWOPartNoId], SUM(ISNULL(WOMS.[QtyIssued],0)) AS qtyissue
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[SubWOPartNoId] = swf.[SubWOPartNoId]
						JOIN [dbo].[SubWorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.[SubWorkOrderMaterialsId] = WOMS.[SubWorkOrderMaterialsId]
					WHERE WOM.[WorkOrderId] = @WorkorderId AND WOM.[SubWorkOrderId] = @SubWorkOrderId AND WOMS.[ProvisionId] = @ProvisionId -- REPLACE
					GROUP BY WOM.[SubWOPartNoId]
				),
				KitAgg AS (
					SELECT WOMK.[SubWOPartNoId],
						SUM(ISNULL(WOMK.[Quantity],0)) AS kitqtyreq
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.[SubWOPartNoId] = swf.[SubWOPartNoId]
					WHERE WOMK.[WorkOrderId] = @WorkorderId AND WOMK.[SubWorkOrderId] = @SubWorkOrderId
					GROUP BY WOMK.[SubWOPartNoId]
				),
				KitIssueAgg AS (
					SELECT WOM.[SubWOPartNoId], SUM(ISNULL(WOMS.[QtyIssued],0)) AS kitqtyissue
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) ON WOM.[SubWOPartNoId] = swf.[SubWOPartNoId]
						JOIN [dbo].[SubWorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOM.[SubWorkOrderMaterialsKitId] = WOMS.[SubWorkOrderMaterialsKitId]
					WHERE WOM.[WorkOrderId] = @WorkorderId AND WOM.[SubWorkOrderId] = @SubWorkOrderId AND WOMS.[ProvisionId] = @ProvisionId -- REPLACE
					GROUP BY WOM.[SubWOPartNoId]
				),
				OtherProvAgg AS (
					SELECT WOM.[SubWOPartNoId], SUM(ISNULL(WOMS.[Quantity],0)) AS OtherProvisionQty
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[SubWOPartNoId] = swf.[SubWOPartNoId]
						JOIN [dbo].[SubWorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.[SubWorkOrderMaterialsId] = WOMS.[SubWorkOrderMaterialsId]
					WHERE WOM.[WorkOrderId] = @WorkorderId AND WOM.[SubWorkOrderId] = @SubWorkOrderId AND WOMS.[ProvisionId] != @ProvisionId -- REPLACE
					GROUP BY WOM.[SubWOPartNoId]
				),
				OtherMatProvAgg AS (
					SELECT WOM.[SubWOPartNoId], SUM(ISNULL(WOM.[Quantity],0)) AS OtherMaterialsProvisionQty
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN [dbo].[SubWorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOM.[SubWorkOrderMaterialsId] = WOMS.[SubWorkOrderMaterialsId]
					WHERE WOM.[WorkOrderId] = @WorkorderId AND WOM.[SubWorkOrderId] = @SubWorkOrderId
						AND WOM.[ProvisionId] != @ProvisionId
						AND WOMS.[SWOMStockLineId] IS NULL
					GROUP BY WOM.[SubWOPartNoId]
				),
				OtherProvKitAgg AS (
					SELECT WOM.[SubWOPartNoId], SUM(ISNULL(WOMS.[Quantity],0)) AS OtherProvisionKitQty
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) ON WOM.[SubWOPartNoId] = swf.[SubWOPartNoId]
						JOIN [dbo].[SubWorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOM.[SubWorkOrderMaterialsKitId] = WOMS.[SubWorkOrderMaterialsKitId]
					WHERE WOM.[WorkOrderId] = @WorkorderId AND WOM.[SubWorkOrderId] = @SubWorkOrderId AND WOMS.[ProvisionId] != @ProvisionId -- REPLACE
					GROUP BY WOM.[SubWOPartNoId]
				),
				OtherMatProvKitAgg AS (
					SELECT WOM.[SubWOPartNoId], SUM(ISNULL(WOM.[Quantity],0)) AS OtherMaterialsProvisionKitQty
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) ON WOM.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN [dbo].[SubWorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK) ON WOM.[SubWorkOrderMaterialsKitId] = WOMS.[SubWorkOrderMaterialsKitId]
					WHERE WOM.[WorkOrderId] = @WorkorderId AND WOM.[SubWorkOrderId] = @SubWorkOrderId
						AND WOM.[ProvisionId] != @ProvisionId
						AND WOMS.[SWOMStockLineKitId] IS NULL
					GROUP BY WOM.[SubWOPartNoId]
				),
				LaborFlagAgg AS (					
					SELECT WLH.[SubWOPartNoId],
						MAX(CAST(ISNULL(WLH.[IsLaborTrackingTurnedOff],0) AS INT)) AS IsLaborTrackingTurnedOff
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderLaborHeader] WLH WITH(NOLOCK) ON WLH.[SubWOPartNoId] = swf.[SubWOPartNoId]
					WHERE WLH.[SubWorkOrderId] = @SubWorkOrderId AND WLH.[WorkOrderId] = @WorkorderId AND ISNULL(WLH.[IsDeleted],0) = 0
					GROUP BY WLH.[SubWOPartNoId]
				),
				LaborCountAgg AS (
					SELECT WLH.[SubWOPartNoId], COUNT(WL.[SubWorkOrderLaborId]) AS IsLaborCompleled
					FROM SWFList swf
						JOIN [dbo].[SubWorkOrderLaborHeader] WLH WITH(NOLOCK) ON WLH.[SubWOPartNoId] = swf.[SubWOPartNoId]
						JOIN [dbo].[SubWorkOrderLabor] WL WITH(NOLOCK) ON WL.[SubWorkOrderLaborHeaderId] = WLH.[SubWorkOrderLaborHeaderId]
					WHERE WLH.[SubWorkOrderId] = @SubWorkOrderId AND WLH.[WorkOrderId] = @WorkorderId
						AND WL.[IsDeleted] = 0 AND ISNULL(WL.[TaskStatusId], 0) <> @TaskStatusID
						AND EXISTS (
							SELECT 1 FROM [dbo].[SubWorkOrderLaborHeader] WLH2 WITH(NOLOCK)
							WHERE WLH2.[SubWOPartNoId] = WLH.[SubWOPartNoId]
								AND WLH2.[SubWorkOrderId] = WLH.[SubWorkOrderId]
								AND WLH2.[WorkOrderId] = WLH.[WorkOrderId]
								AND ISNULL(WLH2.[IsDeleted],0) = 0
						)
					GROUP BY WLH.[SubWOPartNoId]
				),
				ToolsAgg AS (
					SELECT COCI.[SubWOPartNoId], COUNT(COCI.[SubWOCheckInCheckOutWorkOrderAssetId]) AS AllToolsAreCheckOut
					FROM SWFList swf
						JOIN [dbo].[SubWOCheckInCheckOutWorkOrderAsset] COCI WITH(NOLOCK) ON COCI.[SubWOPartNoId] = swf.[SubWOPartNoId]
					WHERE COCI.[SubWorkOrderId] = @SubWorkOrderId AND COCI.[WorkOrderId] = @WorkorderId
						AND COCI.[IsDeleted] = 0 AND ISNULL(COCI.[InventoryStatusId], 0) <> @AvailableStatusID
					GROUP BY COCI.[SubWOPartNoId]
				),
				Combined AS (
					SELECT swf.[SubWOPartNoId],
						ISNULL(ma.[qtyreq],0) + ISNULL(ka.[kitqtyreq],0) - ISNULL(omp.[OtherMaterialsProvisionQty],0) - ISNULL(ompk.[OtherMaterialsProvisionKitQty],0) AS qtyrequested,
						ISNULL(qi.[qtyissue],0) + ISNULL(ki.[kitqtyissue],0) + ISNULL(op.[OtherProvisionQty],0) + ISNULL(opk.[OtherProvisionKitQty],0) AS qtyissued,
						ISNULL(lc.[IsLaborCompleled], 0) AS IsLaborCompleled,
						ISNULL(lf.[IsLaborTrackingTurnedOff], 0) AS IsLaborTrackingTurnedOff,
						ISNULL(ta.[AllToolsAreCheckOut], 0) AS AllToolsAreCheckOut
					FROM SWFList swf
						LEFT JOIN MatAgg ma ON ma.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN KitAgg ka ON ka.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN OtherMatProvAgg omp ON omp.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN OtherMatProvKitAgg ompk ON ompk.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN QtyIssueAgg qi ON qi.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN KitIssueAgg ki ON ki.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN OtherProvAgg op ON op.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN OtherProvKitAgg opk ON opk.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN LaborFlagAgg lf ON lf.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN LaborCountAgg lc ON lc.[SubWOPartNoId] = swf.[SubWOPartNoId]
						LEFT JOIN ToolsAgg ta ON ta.[SubWOPartNoId] = swf.[SubWOPartNoId]
				)
				SELECT  wosd.[WorkOrderId], 
						wos.[WorkOrderSettlementName], 
						wos.[WorkOrderSettlementId], 
						ISNULL(wosd.[SubWorkOrderId],0) AS SubWorkOrderId,
						ISNULL(wosd.[SubWOPartNoId],0) AS SubWOPartNoId,
						ISNULL(wosd.[SubWorkOrderSettlementDetailId],0) AS SubWorkOrderSettlementDetailId,
						CASE WHEN wos.[WorkOrderSettlementId] = @MaterialSettlement THEN CASE WHEN ISNULL(c.[qtyrequested], 0) = ISNULL(c.[qtyissued], 0) THEN 1 ELSE 0 END 
							 WHEN wos.[WorkOrderSettlementId] = @LaborSettlement THEN CASE WHEN ISNULL(c.[IsLaborTrackingTurnedOff], 0) = 1 THEN 1 WHEN ISNULL(c.[IsLaborCompleled],0) <= 0 THEN 1 ELSE 0 END 
							 WHEN wos.[WorkOrderSettlementId] = @AllToolsSettlement THEN CASE WHEN ISNULL(c.[AllToolsAreCheckOut],0) <= 0 THEN 1 ELSE 0 END 
						ELSE wosd.[IsMastervalue] END AS IsMastervalue,
						wosd.[Isvalue_NA],
						Im.[partnumber],
						wosd.[RevisedItemmasterid] AS RevisedPartId,
						IMR.[partnumber] AS RevisedPartNumber,						
						sop.[RevisedSerialNumber],		
						ISNULL(sop.[IsTransferredToParentWO],0) AS [IsTransferredToParentWO],
						ISNULL(sop.[IsFinishGood],0) AS [IsFinishGood],
						ISNULL(sop.[IsClosed],0) AS [IsWOClose]
				INTO #SubSettlementRows
				FROM [DBO].[WorkOrderSettlement] wos  WITH(NOLOCK)
					LEFT JOIN [dbo].[SubWorkOrderSettlementDetails] wosd WITH(NOLOCK) ON wosd.[WorkOrderSettlementId] = wos.[WorkOrderSettlementId]
					LEFT JOIN Combined c ON c.[SubWOPartNoId] = wosd.[SubWOPartNoId]
					LEFT JOIN [dbo].[SubWorkOrderPartNumber] sop WITH(NOLOCK) ON sop.[SubWOPartNoId] = wosd.[SubWOPartNoId]
					LEFT JOIN [dbo].[ItemMaster] Im WITH(NOLOCK) ON sop.[ItemMasterId] = Im.[ItemMasterId] AND ISNULL(Im.IsNonStock,0) = 0
					LEFT JOIN [dbo].[ItemMaster] IMR WITH(NOLOCK) ON IMR.[ItemMasterId] = wosd.[RevisedItemmasterid] AND ISNULL(IMR.IsNonStock,0) = 0
				WHERE wosd.[WorkOrderId] = @WorkorderId and wosd.[SubWorkOrderId] = @SubWorkOrderId

				DECLARE @cols NVARCHAR(MAX) = N'';
				DECLARE @sql NVARCHAR(MAX);

				SELECT @cols = @cols +
					N',MAX(CASE WHEN [WorkOrderSettlementId] = ' + CAST([WorkOrderSettlementId] AS VARCHAR(10)) + N' THEN CAST([WorkOrderSettlementId] AS INT) END) AS [' + [CleanName] + N'_WorkOrderSettlementId]' +
					N',MAX(CASE WHEN [WorkOrderSettlementId] = ' + CAST([WorkOrderSettlementId] AS VARCHAR(10)) + N' THEN CAST([SubWorkOrderSettlementDetailId] AS BIGINT) END) AS [' + [CleanName] + N'_SubWorkOrderSettlementDetailId]' +
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
					[SubWorkOrderId],
					[SubWOPartNoId],
					MAX([partnumber]) AS [partnumber],
					MAX([RevisedPartId]) AS [RevisedPartId],
					MAX([RevisedPartNumber]) AS [RevisedPartNumber],
					MAX([RevisedSerialNumber]) AS [RevisedSerialNumber],
					MAX(CAST([IsTransferredToParentWO] AS INT)) AS [IsTransferredToParentWO],
					MAX(CAST([IsFinishGood] AS INT)) AS [IsFinishGood],
					MAX(CAST([IsWOClose] AS INT)) AS [IsWOClose]'
					+ @cols + N'
				FROM #SubSettlementRows
				GROUP BY [WorkOrderId], [SubWorkOrderId], [SubWOPartNoId]';

				EXEC sp_executesql @sql;

				DROP TABLE #SubSettlementRows;
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderSettlementDetailsNew' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CONVERT(VARCHAR(50), @WorkOrderId), '') + '''
													   @Parameter3 = '''+ ISNULL(CONVERT(VARCHAR(50), @SubWorkOrderId), '') + ''													   
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