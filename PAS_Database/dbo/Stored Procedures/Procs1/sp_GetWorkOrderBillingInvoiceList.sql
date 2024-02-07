/*************************************************************           
 ** File:     [sp_GetWorkOrderBillingInvoiceList]           
 ** Author:	  Vishal Suthar
 ** Description: This SP is Used to get list of Invoices for WO Part    
 ** Purpose:         
 ** Date:   05/24/2023
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------     
	1    05/24/2023   Vishal Suthar		Modified SP to show Old Invoice after re-opening the finished good
	2    01/30/2024   Devendra Shekh	modified sp for performaInvoice
	3    02/06/2024   Devendra Shekh	modified sp for performaInvoice

**************************************************************/ 
-- EXEC [dbo].[sp_GetWorkOrderBillingInvoiceList] 4268, 3771
CREATE   Procedure [dbo].[sp_GetWorkOrderBillingInvoiceList]
	@WorkOrderId  bigint,
	@workOrderPartNumberId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		 BEGIN TRANSACTION
			BEGIN
				DECLARE @IsInvoiceBeforeShippingAllowed BIT;

				SELECT @IsInvoiceBeforeShippingAllowed = ISNULL(WOPN.AllowInvoiceBeforeShipping, 0) FROM DBO.WorkOrderPartNumber WOPN WITH(NOLOCK) WHERE WOPN.WorkOrderId = @WorkOrderId;

				IF OBJECT_ID('tempdb.dbo.#InvoiceMainDetails', 'U') IS NOT NULL
					DROP TABLE #InvoiceMainDetails; 

				CREATE TABLE #InvoiceMainDetails (
					[Id] [BIGINT] IDENTITY NOT NULL,
					[WorkOrderNumber] [VARCHAR](30) NULL,
					[IsProformaInvoice] [bit] NULL,
					[PartNumber] [VARCHAR](50) NULL,
					[PartDescription] [NVARCHAR](MAX) NULL,
					[QtyToBill] [INT] NULL,
					[QtyBilled] [INT] NULL,
					[WorkOrderId] [BIGINT] NULL,
					[ItemMasterId] [BIGINT] NULL,
					[WorkOrderPartId] [BIGINT] NULL,
					[QtyRemaining] [INT] NULL,
					[Status] [VARCHAR](50) NULL,
					[NewStatus] [VARCHAR](50) NULL,
					[ItemNo] [INT] NULL,
				)

				IF (@IsInvoiceBeforeShippingAllowed = 0)
				BEGIN

					INSERT INTO #InvoiceMainDetails([WorkOrderNumber], [PartNumber], [PartDescription], [QtyToBill], [QtyBilled], [WorkOrderId], [ItemMasterId], [WorkOrderPartId], [QtyRemaining], [Status], 
													[NewStatus], [ItemNo], [IsProformaInvoice])
					SELECT 
						wo.WorkOrderNum as WorkOrderNumber, 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription',

						CASE WHEN (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) <0 THEN 0 ELSE 
								  (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) END AS QtyToBill,
						
						CASE WHEN ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) <0 THEN 0 ELSE
										ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) END AS QtyBilled,

						wop.WorkOrderId, 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
						wop.ID as WorkOrderPartId ,

						CASE WHEN ((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) <0 THEN 0 ELSE
								((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) END AS QtyRemaining,
															  															   						
						CASE WHEN 
						(SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)
						= ISNULL((Select  SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) THEN 'Fullfilled'
						ELSE 'Fullfilling' END as [Status], 

						CASE WHEN SUM(ISNULL(wosi.QtyShipped, 0)) = (SELECT SUM(ISNULL(NoofPieces, 0)) FROM WorkOrderBillingInvoicingItem wobII Where wobII.ItemMasterId = imt.ItemMasterId AND ISNULL(wobII.IsPerformaInvoice, 0) = 0) THEN 'Fullfilled'
						END as [NewStatus],

						0 AS ItemNo
						,0 AS [IsProformaInvoice]
					FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
						LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						INNER JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderId = wop.WorkOrderId
						INNER JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
						LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
						LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0
						AND wobii.WorkOrderPartId = wop.ID AND wobii.NoofPieces = wosi.QtyShipped
					WHERE wop.WorkOrderId = @WorkOrderId
					GROUP BY wo.WorkOrderNum,wop.ID, imt.partnumber, imt.PartDescription,wo.WorkOrderId,
						wop.WorkOrderId, imt.ItemMasterId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription
				END
				ELSE
				BEGIN
					INSERT INTO #InvoiceMainDetails([WorkOrderNumber], [PartNumber], [PartDescription], [QtyToBill], [QtyBilled], [WorkOrderId], [ItemMasterId], [WorkOrderPartId], [QtyRemaining], [Status],
													[NewStatus], [ItemNo], [IsProformaInvoice])
					SELECT 
						wo.WorkOrderNum as WorkOrderNumber, 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription',
						(SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId  AND WP.ID = wop.ID)	 AS QtyToBill,
						ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) as QtyBilled,
						wop.WorkOrderId, 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
						wop.ID as WorkOrderPartId ,
						CASE WHEN ((SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) < 0 THEN 0 ELSE ((SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0),0) END as QtyRemaining,
						CASE WHEN 
						(SELECT SUM(ISNULL(WSI.QtyToShip, 0)) FROM WOPickTicket  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.OrderPartId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)
						= ISNULL((Select  SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0)  = 0),0) THEN 'Fullfilled'
						ELSE 'Fullfilling' END as [Status], 

						--CASE WHEN SUM(ISNULL(wopick.QtyToShip, 0)) = (SELECT SUM(ISNULL(NoofPieces, 0)) FROM WorkOrderBillingInvoicingItem wobII Where wobII.ItemMasterId = imt.ItemMasterId) THEN 'Fullfilled'
						--END as [Status],
						CASE WHEN SUM(ISNULL(wop.Quantity, 0)) = (SELECT SUM(ISNULL(NoofPieces, 0)) FROM WorkOrderBillingInvoicingItem wobII Where wobII.ItemMasterId = imt.ItemMasterId AND ISNULL(wobII.IsPerformaInvoice, 0) = 0) THEN 'Fullfilled'
						END as [NewStatus],

						0 AS ItemNo  
						,0 AS [IsProformaInvoice]
					FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
						LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
						--INNER JOIN DBO.WOPickTicket wopick WITH(NOLOCK) on wopick.WorkOrderId = wop.WorkOrderId AND wop.ID = wopick.OrderPartId AND wopick.IsConfirmed = 1
						LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0
						AND wobii.WorkOrderPartId = wop.ID AND wobii.NoofPieces = wop.Quantity --wopick.QtyToShip
					WHERE wop.WorkOrderId = @WorkOrderId
					AND (ISNULL(wop.IsFinishGood, 0) = 1 OR wobi.BillingInvoicingId IS NOT NULL)
					GROUP BY wo.WorkOrderNum,wop.ID, imt.partnumber, imt.PartDescription,wo.WorkOrderId,
					wop.WorkOrderId, imt.ItemMasterId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription
				END

				---IF(SELECT * FROM #InvoiceMainDetails WHERE ItemMasterId 


				--INSERTING BillingInvoicing Details For ProformaInvoice ::-START
				INSERT INTO #InvoiceMainDetails([WorkOrderNumber], [PartNumber], [PartDescription], [QtyToBill], [QtyBilled], [WorkOrderId], [ItemMasterId], [WorkOrderPartId], [QtyRemaining], [Status],
													[NewStatus], [ItemNo], [IsProformaInvoice])
				SELECT 
						wo.WorkOrderNum as WorkOrderNumber, 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription',

						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @WorkOrderId AND WP.ID = @WorkOrderPartNumberId) > 0 
							 THEN CASE WHEN (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) < 0 
									   THEN 0 ELSE (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) END
							 ELSE (SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId  AND WP.ID = wop.ID) END AS QtyToBill,

						CASE WHEN ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) < 0 THEN 0 
							 ELSE ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) END AS QtyBilled,

						wop.WorkOrderId, 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
						wop.ID as WorkOrderPartId ,

						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
											INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @WorkOrderId AND WP.ID = @WorkOrderPartNumberId) > 0 THEN
								CASE WHEN ((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) < 0 THEN 0 
								ELSE ((SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) 
															  INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) END
							ELSE CASE WHEN ((SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) < 0 THEN 0 
							ELSE ((SELECT SUM(ISNULL(WP.Quantity, 0)) FROM dbo.WorkOrderPartNumber  WP WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID)) - ISNULL((Select SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) END END as QtyRemaining,

						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @WorkOrderId AND WP.ID = @WorkOrderPartNumberId) > 0
							 THEN CASE WHEN (SELECT SUM(ISNULL(WSI.QtyShipped, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) = ISNULL((Select  SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) 
									  THEN 'Fullfilled' ELSE 'Fullfilling' END
							 ELSE CASE WHEN (SELECT SUM(ISNULL(WSI.QtyToShip, 0)) FROM WOPickTicket  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.OrderPartId WHERE  WP.WorkOrderId = wo.WorkOrderId AND WP.ID = wop.ID) = ISNULL((Select  SUM(ISNULL(WOBI.NoofPieces,0)) FROM WorkOrderBillingInvoicing WOB inner join  WorkOrderBillingInvoicingItem WOBI on WOB.BillingInvoicingId = WOBI.BillingInvoicingId where ISNULL(WOB.IsVersionIncrease,0) = 0 and WOB.WorkOrderId = wo.WorkOrderId AND WOBI.WorkOrderPartId = wop.ID AND ISNULL(WOBI.IsPerformaInvoice, 0) = 1),0) 
								  THEN 'Fullfilled' ELSE 'Fullfilling' END END as [Status], 

						CASE WHEN (SELECT COUNT(ISNULL(WorkOrderShippingItemId, 0)) FROM WorkOrderShippingItem  WSI  WITH(NOLOCK) INNER JOIN dbo.WorkOrderPartNumber  WP on WP.ID = WSI.WorkOrderPartNumId WHERE WP.WorkOrderId = @WorkOrderId AND WP.ID = @WorkOrderPartNumberId) > 0 
							 THEN CASE WHEN SUM(ISNULL(wosi.QtyShipped, 0)) = (SELECT SUM(ISNULL(NoofPieces, 0)) FROM WorkOrderBillingInvoicingItem wobII Where wobII.ItemMasterId = imt.ItemMasterId AND ISNULL(wobII.IsPerformaInvoice, 0) = 1) 
								  THEN 'Fullfilled' END 
							ELSE CASE WHEN SUM(ISNULL(wop.Quantity, 0)) = (SELECT SUM(ISNULL(NoofPieces, 0)) FROM WorkOrderBillingInvoicingItem wobII Where wobII.ItemMasterId = imt.ItemMasterId AND ISNULL(wobII.IsPerformaInvoice, 0) = 1) THEN 'Fullfilled'
								 END END as [NewStatus],
						0 AS ItemNo
						,1 AS [IsProformaInvoice]
					FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)
						LEFT JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
						LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wop.ID = wobii.WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1
						LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobii.BillingInvoicingId = wobi.BillingInvoicingId and wobi.IsVersionIncrease=0
						AND wobii.WorkOrderPartId = wop.ID AND wobii.NoofPieces = wop.Quantity
					WHERE wop.WorkOrderId = @WorkOrderId AND ((SELECT CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END) NOT IN (SELECT ItemMasterId FROM #InvoiceMainDetails))
					--wop.ItemMasterId NOT IN (SELECT ItemMasterId FROM #InvoiceMainDetails)
					GROUP BY wo.WorkOrderNum,wop.ID, imt.partnumber, imt.PartDescription,wo.WorkOrderId,
					wop.WorkOrderId, imt.ItemMasterId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription
					--INSERTING BillingInvoicing Details For ProformaInvoice ::-END

				SELECT * FROM #InvoiceMainDetails
			END
		 COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWorkOrderBillingInvoiceList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter4 = ' + ISNULL(@workOrderPartNumberId ,'') +''
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