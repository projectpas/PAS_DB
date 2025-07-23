
/*************************************************************           
 ** File:  [GetCommonBillingInvoiceListNew]           
 ** Author:	  Moin Bloch
 ** Description: This SP is Used to get list of Invoices for Part    
 ** Purpose:         
 ** Date:   05/24/2023          
 ** PARAMETERS: 
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------     
	1    12/05/2025   Moin Bloch		Created
	2    02/06/2025   Rajesh Gami		Implemented SO
	3    07-07-2025   Moin Bloch        Changed Old To New Billing Table
	4    21-07-2025   Moin Bloch        Added BillingAmount
**************************************************************/ 
--   EXEC [dbo].[GetCommonBillingInvoiceListNew] 8810, 8582,15
CREATE     PROCEDURE [dbo].[GetCommonBillingInvoiceListNew]
@ReferenceId BIGINT = NULL,
@SubReferenceId BIGINT = NULL, 
@ModuleId INT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY

		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
		DECLARE @AllowBillingBeforeShipping BIT,@SalesOrderShippingId BIGINT;;
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';	
		
		IF OBJECT_ID('tempdb.dbo.#InvoiceMainDetails', 'U') IS NOT NULL
			DROP TABLE #InvoiceMainDetails; 

		CREATE TABLE #InvoiceMainDetails (
			[Id] [BIGINT] IDENTITY NOT NULL,
			[ReferenceNumber] [VARCHAR](30) NULL,
			[IsProformaInvoice] [bit] NULL,
			[PartNumber] [VARCHAR](50) NULL,
			[PartDescription] [NVARCHAR](MAX) NULL,
			[QtyToBill] [INT] NULL,
			[QtyBilled] [INT] NULL,
			[ReferenceId] [BIGINT] NULL,
			[ItemMasterId] [BIGINT] NULL,
			[SubReferenceId] [BIGINT] NULL,
			[QtyRemaining] [INT] NULL,
			[Status] [VARCHAR](50) NULL,
			[NewStatus] [VARCHAR](50) NULL,
			[ItemNo] [INT] NULL,
			[ConditionId] [BIGINT]  NULL,
			[Condition] [VARCHAR](250)  NULL,
			[CustomerId] [BIGINT] NULL,
			[BillingAmount] [decimal](18,2) NULL,
			[PerformaBillingAmount] [decimal](18,2) NULL,
		)
		
		IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
		BEGIN
			DECLARE @IsInvoiceBeforeShippingAllowed BIT;

			SELECT @IsInvoiceBeforeShippingAllowed = ISNULL(WOPN.[AllowInvoiceBeforeShipping], 0) FROM [dbo].[WorkOrderPartNumber] WOPN WITH(NOLOCK) WHERE WOPN.WorkOrderId = @ReferenceId;
								
			IF (@IsInvoiceBeforeShippingAllowed = 0)
			BEGIN

					INSERT INTO #InvoiceMainDetails([ReferenceNumber], [PartNumber], [PartDescription], [QtyToBill], [QtyBilled], [ReferenceId], [ItemMasterId], [SubReferenceId], [QtyRemaining], [Status], 
													[NewStatus], [ItemNo], [IsProformaInvoice],[BillingAmount],[PerformaBillingAmount])
					SELECT 
						wo.WorkOrderNum as WorkOrderNumber, 
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedPartNumber] ELSE imt.[PartNumber] END as 'PartNumber',
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedPartDescription] ELSE imt.[PartDescription] END as 'PartDescription',

						CASE WHEN (SELECT SUM(ISNULL(WSI.[QtyShipped], 0)) FROM [dbo].[WorkOrderShippingItem]  WSI  WITH(NOLOCK) 
															  INNER JOIN [dbo].[WorkOrderPartNumber]  WP WITH(NOLOCK) ON WP.ID = WSI.[WorkOrderPartNumId] WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID]) < 0 THEN 0 ELSE 
								  (SELECT SUM(ISNULL(WSI.[QtyShipped], 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) 
															  INNER JOIN [dbo].[WorkOrderPartNumber]  WP WITH(NOLOCK) ON WP.ID = WSI.[WorkOrderPartNumId] WHERE WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID]) END AS QtyToBill,
						
						CASE WHEN ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0),0) < 0 THEN 0 ELSE
								  ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0),0) END AS QtyBilled,

						wop.[WorkOrderId], 
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedItemmasterid] ELSE imt.[ItemMasterId] END AS [ItemMasterId],						
						wop.ID as [WorkOrderPartId],
						CASE WHEN ((SELECT SUM(ISNULL(WSI.[QtyShipped], 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) 
															  INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WP.[ID] = WSI.[WorkOrderPartNumId] WHERE WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID])) - ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN  [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.BillingInvoicingId = WOBI.BillingInvoicingId WHERE ISNULL(WOB.IsVersionIncrease,0) = 0 AND WOB.ReferenceId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) < 0 THEN 0 ELSE
								((SELECT SUM(ISNULL(WSI.[QtyShipped], 0)) FROM [dbo].[WorkOrderShippingItem]  WSI WITH(NOLOCK) 
															  INNER JOIN [dbo].[WorkOrderPartNumber]  WP WITH(NOLOCK) ON WP.[ID] = WSI.WorkOrderPartNumId WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID])) - ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN  [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.BillingInvoicingId = WOBI.BillingInvoicingId WHERE ISNULL(WOB.IsVersionIncrease,0) = 0 AND WOB.ReferenceId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) END AS QtyRemaining,
															  															   						
						CASE WHEN 
						(SELECT SUM(ISNULL(WSI.[QtyShipped], 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) 
															  INNER JOIN [dbo].[WorkOrderPartNumber] WP  WITH(NOLOCK) ON WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)
							= ISNULL((Select  SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB  WITH(NOLOCK)  
						 INNER JOIN  [dbo].[BillingInvoicingItems] WOBI  WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 and WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) THEN 'Fullfilled'
						ELSE 'Fullfilling' END AS [Status], 

						CASE WHEN SUM(ISNULL(wosi.[QtyShipped], 0)) = (SELECT SUM(ISNULL([QtyBilled], 0)) FROM BillingInvoicingItems wobII WITH(NOLOCK) WHERE wobII.ItemMasterId = imt.ItemMasterId AND ISNULL(wobII.IsPerformaInvoice, 0) = 0) THEN 'Fullfilled'
						END as [NewStatus],

						0 AS ItemNo
					   ,0 AS [IsProformaInvoice]
					   ,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @WOModuleId
								   AND WOB.[ReferenceId] = wo.[WorkOrderId] 
								   AND WOBI.[SubReferenceId] = wop.[ID] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0)
					   ,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @WOModuleId
								   AND WOB.[ReferenceId] = wo.[WorkOrderId] 
								   AND WOBI.[SubReferenceId] = wop.[ID] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1)
					FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
					 LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.[WorkOrderId] = wop.[WorkOrderId]
					INNER JOIN [dbo].[WorkOrderShipping] wos WITH(NOLOCK) ON wos.[WorkOrderId] = wop.[WorkOrderId]
					INNER JOIN [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK) ON wos.[WorkOrderShippingId] = wosi.[WorkOrderShippingId] AND wosi.[WorkOrderPartNumId] = wop.[ID]
					 LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.[ItemMasterId] = wop.[ItemMasterId]
					 LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.[StockLineId] = wop.[StockLineId]
					 LEFT JOIN [dbo].[BillingInvoicingItems] wobii WITH(NOLOCK) ON wop.[ID] = wobii.[SubReferenceId] AND ISNULL(wobii.[IsPerformaInvoice], 0) = 0
					 LEFT JOIN [dbo].[BillingInvoicing] wobi WITH(NOLOCK) ON wobii.[BillingInvoicingId] = wobi.[BillingInvoicingId] AND ISNULL(wobi.[IsVersionIncrease],0) = 0 AND wobii.[SubReferenceId] = wop.ID AND wobii.[QtyBilled] = wosi.[QtyShipped]
					WHERE wop.[WorkOrderId] = @ReferenceId
					GROUP BY wo.[WorkOrderNum],wop.[ID], imt.[partnumber],imt.[PartDescription],wo.[WorkOrderId],wop.[WorkOrderId], 
					imt.[ItemMasterId],wop.[RevisedItemmasterid],wop.[RevisedPartNumber],wop.[RevisedPartDescription]
				END
			ELSE
			BEGIN
					INSERT INTO #InvoiceMainDetails([ReferenceNumber], [PartNumber], [PartDescription], [QtyToBill], [QtyBilled], [ReferenceId], [ItemMasterId], [SubReferenceId], [QtyRemaining], [Status],
													[NewStatus], [ItemNo], [IsProformaInvoice],[BillingAmount],[PerformaBillingAmount])
					SELECT 
						wo.[WorkOrderNum] AS [WorkOrderNumber], 
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedPartNumber] ELSE imt.[PartNumber] END AS 'PartNumber',
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedPartDescription] ELSE imt.[PartDescription] END AS 'PartDescription',
						(SELECT SUM(ISNULL(WP.[Quantity], 0)) FROM [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) WHERE WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID]) AS QtyToBill,
						ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0),0) AS [QtyBilled],
						wop.[WorkOrderId], 
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedItemmasterid] ELSE imt.[ItemMasterId] END AS [ItemMasterId],
						wop.ID AS [WorkOrderPartId],
						CASE WHEN ((SELECT SUM(ISNULL(WP.[Quantity], 0)) FROM [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) WHERE WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID])) - ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0),0) < 0 THEN 0 ELSE ((SELECT SUM(ISNULL(WP.Quantity, 0)) FROM [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID])) - ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) on WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0),0) END AS [QtyRemaining],
						CASE WHEN (SELECT SUM(ISNULL(WSI.QtyToShip, 0)) FROM [dbo].[WOPickTicket]  WSI  WITH(NOLOCK) 
															  INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WP.ID = WSI.[OrderPartId] WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID])
						= ISNULL((SELECT  SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 and WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0),0) THEN 'Fullfilled'
						ELSE 'Fullfilling' END AS [Status],
						CASE WHEN SUM(ISNULL(wop.[Quantity], 0)) = (SELECT SUM(ISNULL([QtyBilled], 0)) FROM [dbo].[BillingInvoicingItems] wobII WITH(NOLOCK) WHERE wobII.[ItemMasterId] = imt.[ItemMasterId] AND ISNULL(wobII.[IsPerformaInvoice], 0) = 0) THEN 'Fullfilled'
						END as [NewStatus],
						0 AS ItemNo, 
						0 AS [IsProformaInvoice]
					   ,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @WOModuleId
								   AND WOB.[ReferenceId] = wo.[WorkOrderId] 
								   AND WOBI.[SubReferenceId] = wop.[ID] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0)
					   ,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @WOModuleId
								   AND WOB.[ReferenceId] = wo.[WorkOrderId] 
								   AND WOBI.[SubReferenceId] = wop.[ID] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1)
					FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
					LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.[WorkOrderId] = wop.[WorkOrderId]
					LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.[ItemMasterId] = wop.[ItemMasterId]
					LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.[StockLineId] = wop.[StockLineId]
					LEFT JOIN [dbo].[BillingInvoicingItems] wobii WITH(NOLOCK) ON wop.[ID] = wobii.[SubReferenceId] AND ISNULL(wobii.[IsPerformaInvoice], 0) = 0
					LEFT JOIN [dbo].[BillingInvoicing] wobi WITH(NOLOCK) ON wobii.[BillingInvoicingId] = wobi.[BillingInvoicingId] AND ISNULL(wobi.[IsVersionIncrease],0) = 0
					AND wobii.[SubReferenceId] = wop.[ID] AND wobii.[QtyBilled] = wop.[Quantity] --wopick.QtyToShip
					WHERE wop.[WorkOrderId] = @ReferenceId
					AND (ISNULL(wop.[IsFinishGood], 0) = 1 OR wobi.[BillingInvoicingId] IS NOT NULL)
					GROUP BY wo.[WorkOrderNum],wop.[ID],imt.[partnumber],imt.[PartDescription],wo.[WorkOrderId],wop.[WorkOrderId],
					        imt.[ItemMasterId],wop.[RevisedItemmasterid],wop.[RevisedPartNumber],wop.[RevisedPartDescription]
				END
										
			INSERT INTO #InvoiceMainDetails([ReferenceNumber], [PartNumber], [PartDescription], [QtyToBill], [QtyBilled], [ReferenceId], [ItemMasterId], [SubReferenceId], [QtyRemaining], [Status],
													[NewStatus], [ItemNo], [IsProformaInvoice],[BillingAmount],[PerformaBillingAmount])
				SELECT 
						wo.[WorkOrderNum] 'WorkOrderNumber', 
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedPartNumber] ELSE imt.[PartNumber] END 'PartNumber',
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedPartDescription] ELSE imt.[PartDescription] END 'PartDescription',
						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) 
						          INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WP.[ID] = WSI.[WorkOrderPartNumId] WHERE WP.[WorkOrderId] = @ReferenceId AND WP.[ID] = @SubReferenceId) > 0 
							 THEN CASE WHEN (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM [dbo].[WorkOrderShippingItem]  WSI  WITH(NOLOCK) 
							      INNER JOIN [dbo].[WorkOrderPartNumber]  WP WITH(NOLOCK) ON WP.[ID] = WSI.[WorkOrderPartNumId] WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID]) < 0 
							 THEN 0 ELSE (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM [dbo].[WorkOrderShippingItem]  WSI  WITH(NOLOCK) 
							 INNER JOIN [dbo].[WorkOrderPartNumber]  WP WITH(NOLOCK) ON WP.ID = WSI.WorkOrderPartNumId WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.ID = wop.ID) END
							 ELSE (SELECT SUM(ISNULL(WP.Quantity, 0)) FROM [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK)  WHERE  WP.[WorkOrderId] = wo.[WorkOrderId]  AND WP.ID = wop.ID) END AS [QtyToBill],

						CASE WHEN ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB 
						     INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
							 WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1),0) < 0
							 THEN 0 
							 ELSE ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1),0) END AS [QtyBilled],
						wop.[WorkOrderId], 
						CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedItemmasterid] ELSE imt.[ItemMasterId] END AS [ItemMasterId],
						wop.ID AS [WorkOrderPartId],

						CASE WHEN (SELECT COUNT(ISNULL([WorkOrderShippingItemId], 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) 
											INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @ReferenceId AND WP.ID = @SubReferenceId) > 0 THEN
								CASE WHEN ((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) 
															  INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WP.[ID] = WSI.[WorkOrderPartNumId] WHERE WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID])) - ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.BillingInvoicingId = WOBI.BillingInvoicingId WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1),0) < 0 THEN 0 
								ELSE ((SELECT SUM(ISNULL(WSI.[QtyShipped], 0)) FROM [dbo].[WorkOrderShippingItem]  WSI  WITH(NOLOCK) 
															  INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WP.ID = WSI.[WorkOrderPartNumId] WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.ID = wop.ID)) - ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN  [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1),0) END
							ELSE CASE WHEN ((SELECT SUM(ISNULL(WP.[Quantity], 0)) FROM [dbo].[WorkOrderPartNumber]  WP WITH(NOLOCK) WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID])) - ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN  [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.ID AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1),0) < 0 THEN 0 
							ELSE ((SELECT SUM(ISNULL(WP.[Quantity], 0)) FROM [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) WHERE WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID])) - ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN  [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.IsVersionIncrease,0) = 0 AND WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.ID AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1),0) END END AS [QtyRemaining],

						CASE WHEN (SELECT COUNT(ISNULL([WorkOrderShippingItemId], 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WP.ID = WSI.[WorkOrderPartNumId] WHERE WP.[WorkOrderId] = @ReferenceId AND WP.[ID] = @SubReferenceId) > 0
							 THEN CASE WHEN (SELECT SUM(ISNULL(WSI.[QtyShipped], 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderPartNumber]  WP WITH(NOLOCK) ON WP.ID = WSI.[WorkOrderPartNumId] WHERE WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.[ID] = wop.[ID]) = ISNULL((SELECT SUM(ISNULL(WOBI.[QtyBilled],0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN  [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 and WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.[ID] AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1),0) 
									  THEN 'Fullfilled' ELSE 'Fullfilling' END
							 ELSE CASE WHEN (SELECT SUM(ISNULL(WSI.[QtyToShip], 0)) FROM [dbo].[WOPickTicket] WSI WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WP.ID = WSI.OrderPartId WHERE  WP.[WorkOrderId] = wo.[WorkOrderId] AND WP.ID = wop.ID) = ISNULL((SELECT SUM(ISNULL(WOBI.QtyBilled,0)) FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.[IsVersionIncrease],0) = 0 and WOB.[ReferenceId] = wo.[WorkOrderId] AND WOBI.[SubReferenceId] = wop.ID AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1),0) 
								  THEN 'Fullfilled' ELSE 'Fullfilling' END END AS [Status], 

						CASE WHEN (SELECT COUNT(ISNULL([WorkOrderShippingItemId], 0)) FROM [dbo].[WorkOrderShippingItem] WSI WITH(NOLOCK) INNER JOIN [dbo].[WorkOrderPartNumber]  WP ON WP.[ID] = WSI.[WorkOrderPartNumId] WHERE WP.[WorkOrderId] = @ReferenceId AND WP.[ID] = @SubReferenceId) > 0 
							 THEN CASE WHEN SUM(ISNULL(wosi.[QtyShipped], 0)) = (SELECT SUM(ISNULL(QtyBilled, 0)) FROM [dbo].[BillingInvoicingItems] wobII WITH(NOLOCK) WHERE wobII.[ItemMasterId] = imt.[ItemMasterId] AND ISNULL(wobII.[IsPerformaInvoice], 0) = 1) 
								  THEN 'Fullfilled' END 
							ELSE CASE WHEN SUM(ISNULL(wop.[Quantity], 0)) = (SELECT SUM(ISNULL([QtyBilled], 0)) FROM [dbo].[BillingInvoicingItems] wobII WITH(NOLOCK) WHERE wobII.[ItemMasterId] = imt.[ItemMasterId] AND ISNULL(wobII.[IsPerformaInvoice], 0) = 1) THEN 'Fullfilled'
								 END END AS [NewStatus],
						0 AS ItemNo
						,1 AS [IsProformaInvoice]
						,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @WOModuleId
								   AND WOB.[ReferenceId] = wo.[WorkOrderId] 
								   AND WOBI.[SubReferenceId] = wop.[ID] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0)
					    ,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @WOModuleId
								   AND WOB.[ReferenceId] = wo.[WorkOrderId] 
								   AND WOBI.[SubReferenceId] = wop.[ID] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1)
					FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
					LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.[WorkOrderId] = wop.[WorkOrderId]
					LEFT JOIN [dbo].[WorkOrderShipping] wos WITH(NOLOCK) ON wos.[WorkOrderId] = wop.[WorkOrderId]
					LEFT JOIN [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK) ON wos.[WorkOrderShippingId] = wosi.[WorkOrderShippingId] AND wosi.[WorkOrderPartNumId] = wop.[ID]
					LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.[ItemMasterId] = wop.[ItemMasterId]
					LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.[StockLineId] = wop.[StockLineId]
					LEFT JOIN [dbo].[BillingInvoicingItems] wobii WITH(NOLOCK) ON wop.[ID] = wobii.[SubReferenceId] AND ISNULL(wobii.[IsPerformaInvoice], 0) = 1
					LEFT JOIN [dbo].[BillingInvoicing] wobi WITH(NOLOCK) ON wobii.[BillingInvoicingId] = wobi.[BillingInvoicingId] AND ISNULL(wobi.[IsVersionIncrease],0) = 0 AND wobii.[SubReferenceId] = wop.[ID] AND wobii.[QtyBilled] = wop.[Quantity]
					WHERE wop.[WorkOrderId] = @ReferenceId AND ((SELECT CASE WHEN ISNULL(wop.[RevisedItemmasterid], 0) > 0 THEN wop.[RevisedItemmasterid] ELSE imt.[ItemMasterId] END) NOT IN (SELECT [ItemMasterId] FROM #InvoiceMainDetails))					
					GROUP BY wo.[WorkOrderNum],wop.[ID],imt.[partnumber],imt.[PartDescription],wo.[WorkOrderId],wop.[WorkOrderId],
					imt.[ItemMasterId],wop.[RevisedItemmasterid],wop.[RevisedPartNumber],wop.[RevisedPartDescription]								
		END /*********END: WORK ORDER ********/
		ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
		BEGIN
		PRINT 'SALES ORDER'
			SELECT @AllowBillingBeforeShipping = AllowInvoiceBeforeShipping FROM DBO.SalesOrder SO (NOLOCK) WHERE SO.SalesOrderId = @ReferenceId;
			SELECT @SalesOrderShippingId = ISNULL(SalesOrderShippingId,0) FROM DBO.SalesOrderShipping SO (NOLOCK) WHERE SO.SalesOrderId = @ReferenceId;
						
				IF (ISNULL(@AllowBillingBeforeShipping, 0) = 0)
				BEGIN 
					INSERT INTO #InvoiceMainDetails(ReferenceNumber,partnumber,ItemMasterId,PartDescription,ConditionId,Condition,ReferenceId,SubReferenceId,Status,ItemNo,CustomerId,[BillingAmount],[PerformaBillingAmount])
					(
					SELECT DISTINCT so.SalesOrderNumber, imt.partnumber,imt.ItemMasterId, imt.PartDescription, sop.ConditionId, cond.Description as 'Condition', sop.SalesOrderId,sop.SalesOrderPartId, '' as [Status],	0 AS ItemNo,so.CustomerId
					,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @SOModuleId
								   AND WOB.[ReferenceId] = sop.[SalesOrderId] 
								   AND WOBI.[SubReferenceId] = sop.[SalesOrderPartId] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0)
					,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @SOModuleId
								   AND WOB.[ReferenceId] = sop.[SalesOrderId] 
								   AND WOBI.[SubReferenceId] = sop.[SalesOrderPartId] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1)					
					FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
					INNER JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sos.SalesOrderId = sop.SalesOrderId
					INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
					LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId
					LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.ReferenceId = sos.SalesOrderId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId
					LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.BillingInvoicingId = sobi.BillingInvoicingId
								AND sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.QtyBilled = sosi.QtyShipped
								AND ISNULL(sobii.IsVersionIncrease,0) = 0 AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.[ModuleId] = @SOModuleId
					LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId 
					WHERE sop.SalesOrderId = @ReferenceId AND ISNULL(stk.StockLineId, 0) > 0
					GROUP BY so.SalesOrderNumber, imt.partnumber,imt.ItemMasterId, imt.PartDescription,
					sop.SalesOrderId, imt.ItemMasterId, sop.ConditionId,cond.Description, sop.SalesOrderPartId,so.CustomerId)
				END
				ELSE
				BEGIN
					IF (@SalesOrderShippingId > 0)
					BEGIN 
						INSERT INTO #InvoiceMainDetails(ReferenceNumber,partnumber,ItemMasterId,PartDescription,ConditionId,Condition,ReferenceId,SubReferenceId,Status,ItemNo,CustomerId,[BillingAmount],[PerformaBillingAmount])
						(SELECT DISTINCT so.SalesOrderNumber, imt.partnumber,imt.ItemMasterId, imt.PartDescription, sop.ConditionId, cond.Description as 'Condition',				
						sop.SalesOrderId, sop.SalesOrderPartId AS SubReferenceId,	'' as [Status], 0 AS ItemNo,so.CustomerId
						,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @SOModuleId
								   AND WOB.[ReferenceId] = sop.[SalesOrderId] 
								   AND WOBI.[SubReferenceId] = sop.[SalesOrderPartId] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0)
					    ,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @SOModuleId
								   AND WOB.[ReferenceId] = sop.[SalesOrderId] 
								   AND WOBI.[SubReferenceId] = sop.[SalesOrderPartId] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1)
						FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId
						LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.ReferenceId = sop.SalesOrderId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId--AND sobi.IsVersionIncrease = 0
						LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.BillingInvoicingId = sobi.BillingInvoicingId
									AND sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.QtyBilled = sop.QtyOrder
									AND sobii.IsVersionIncrease = 0 AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.[ModuleId] = @SOModuleId
						LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sos.SalesOrderId = sop.SalesOrderId
						LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = sop.SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
						LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId
						WHERE sop.SalesOrderId = @ReferenceId AND ISNULL(stk.StockLineId, 0) > 0
						AND (ISNULL(soapr.SalesOrderApprovalId, 0) > 0 OR ISNULL(sosi.QtyShipped, 0) > 0) 
						GROUP BY so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, imt.PartDescription,
						sop.SalesOrderId, imt.ItemMasterId, sop.SalesOrderPartId, sop.ConditionId,cond.Description,so.CustomerId)
					END
					ELSE 
					BEGIN
						INSERT INTO #InvoiceMainDetails(ReferenceNumber,partnumber,ItemMasterId,PartDescription,ConditionId,Condition,ReferenceId,SubReferenceId,Status,ItemNo,CustomerId,[BillingAmount],[PerformaBillingAmount])
						(SELECT DISTINCT so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, imt.PartDescription, sop.ConditionId, cond.Description as 'Condition',				
						sop.SalesOrderId,sop.SalesOrderPartId AS SubReferenceId,'' as [Status],0 AS ItemNo,so.CustomerId
						,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @SOModuleId
								   AND WOB.[ReferenceId] = sop.[SalesOrderId] 
								   AND WOBI.[SubReferenceId] = sop.[SalesOrderPartId] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0)
					    ,(SELECT SUM(ISNULL(WOBI.[GrandTotal],0)) 
						        FROM [dbo].[BillingInvoicing] WOB WITH(NOLOCK) 
								INNER JOIN [dbo].[BillingInvoicingItems] WOBI WITH(NOLOCK) ON WOB.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
								WHERE ISNULL(WOB.[IsVersionIncrease],0) = 0 
								   AND WOB.[ModuleId] = @SOModuleId
								   AND WOB.[ReferenceId] = sop.[SalesOrderId] 
								   AND WOBI.[SubReferenceId] = sop.[SalesOrderPartId] 
								   AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 1)
						FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId
						LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.ReferenceId = sop.SalesOrderId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.[ModuleId] = @SOModuleId --AND sobi.IsVersionIncrease = 0
						LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.BillingInvoicingId = sobi.BillingInvoicingId
									AND sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.QtyBilled = sop.QtyOrder
									AND ISNULL(sobii.IsVersionIncrease,0) = 0 AND ISNULL(sobii.IsPerformaInvoice,0) = 0 AND sobii.[ModuleId] = @SOModuleId
						LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sos.SalesOrderId = sop.SalesOrderId
						LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = sop.SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
						LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId
						WHERE sop.SalesOrderId = @ReferenceId AND ISNULL(stk.StockLineId, 0) > 0
						AND ((ISNULL(soapr.SalesOrderApprovalId, 0) > 0   
						AND (ISNULL(SOR.SalesOrderReservePartId, 0) > 0) AND (ISNULL(SOR.TotalReserved, 0) > 0)) OR ISNULL(sosi.QtyShipped, 0) > 0)
						GROUP BY so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, imt.PartDescription,
						sop.SalesOrderId, imt.ItemMasterId, sop.ConditionId,cond.Description, sop.SalesOrderPartId,so.CustomerId)
					END
				END

				IF OBJECT_ID(N'tempdb..#tmpSalesOrderPart') IS NOT NULL
				BEGIN
					DROP TABLE #tmpSalesOrderPart
				END
	 
				CREATE TABLE #tmpSalesOrderPart (
					ID BIGINT NOT NULL IDENTITY (1, 1),
					SalesOrderId BIGINT NULL,
					SalesOrderPartId BIGINT NULL,
					ItemMasterId  BIGINT NULL,
					ConditionId BIGINT NULL
				 )

				DECLARE @ItemMasterId AS BIGINT = 0;
				DECLARE @ConditionId AS BIGINT = 0;
				DECLARE @SalesOrderPartId AS BIGINT = 0;
				DECLARE @COUNT AS INT = 0;

				INSERT INTO #tmpSalesOrderPart(SalesOrderId, SalesOrderPartId, ConditionId, ItemMasterId)
				SELECT SalesOrderId, SalesOrderPartId, ConditionId, ItemMasterId FROM DBO.SalesOrderPartV1 WITH (NOLOCK) WHERE SalesOrderId = @ReferenceId
				
				SELECT @COUNT = MAX(ID) FROM #tmpSalesOrderPart 

				WHILE(@COUNT > 0)
				BEGIN
					SELECT @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @SalesOrderPartId = SalesOrderPartId FROM #tmpSalesOrderPart WITH(NOLOCK) WHERE ID = @COUNT

					IF((SELECT COUNT(1) FROM #InvoiceMainDetails WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId AND ReferenceId = @ReferenceId AND SubReferenceId = @SalesOrderPartId) <= 0)
					BEGIN
					
						INSERT INTO #InvoiceMainDetails(ReferenceNumber,partnumber,ItemMasterId,PartDescription,ConditionId,Condition,ReferenceId,SubReferenceId,Status,ItemNo,CustomerId,[BillingAmount],[PerformaBillingAmount])
						(SELECT DISTINCT so.SalesOrderNumber, 
										imt.partnumber, 
										imt.ItemMasterId,
										imt.PartDescription, 
										sop.ConditionId, 	
										cond.Description as 'Condition',
										sop.SalesOrderId, 
										sop.SalesOrderPartId As SubReferenceId,
										'' AS [Status],
										0 AS ItemNo,
										so.CustomerId,
										0 AS [BillingAmount],
										0 AS [PerformaBillingAmount]
								FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
									INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
									INNER JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
									LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId
								
								WHERE sop.SalesOrderId = @ReferenceId AND sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = @ConditionId AND  sop.SalesOrderPartId = @SalesOrderPartId
								GROUP BY so.SalesOrderNumber, imt.partnumber,imt.ItemMasterId, imt.PartDescription,sop.SalesOrderId,  imt.ItemMasterId, sop.SalesOrderPartId, sop.ConditionId,cond.Description,so.CustomerId)
					END
					
					SET @COUNT = @COUNT - 1
				END

		END /*********END: WORK ORDER ********/

		SELECT * FROM #InvoiceMainDetails
		
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetBillingInvoiceListNew' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReferenceId, '') + '''
													   @Parameter2 = ' + ISNULL(@SubReferenceId ,'') +'
													   @Parameter3 = ' + ISNULL(@ModuleId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH



END