/*************************************************************           
 ** File:   [dbo].[GetBillingInvoiceByShipping]          
 ** Author:   Deep Patel
 ** Description: Get Billing Data based on Shipping id.
 ** Date:   01-March-2021   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    06/12/2023   Vishal Suthar			Updated the SP to handle invoice before shipping and versioning
    2    06/22/2023   Vishal Suthar			Updated the SP to show billing data only after part approval OR if the shipping is generated
    3    07/25/2023   Devendra Shekh		added new 'and condtion for SalesOrderReservePartId' for else result
    4    07/25/2023   Devendra Shekh		added new if-else , to resolve issue regarding billing data after shipment
	5    01/30/2024   AMIT GHEDIYA		    Updated the SP to show billing data only when is Billing Invoiced
	6    02/05/2024   AMIT GHEDIYA			Updated the SP to show Performa invoice Data.

--   EXEC sp_GetSalesOrderBillingInvoiceList 887
**************************************************************/ 
CREATE   PROCEDURE [dbo].[sp_GetSalesOrderBillingInvoiceList]
	@SalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @AllowBillingBeforeShipping BIT;
				SELECT @AllowBillingBeforeShipping = AllowInvoiceBeforeShipping FROM DBO.SalesOrder SO (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId;

				DECLARE @SalesOrderShippingId BIGINT;
				SELECT @SalesOrderShippingId = ISNULL(SalesOrderShippingId,0) FROM DBO.SalesOrderShipping SO (NOLOCK) WHERE SO.SalesOrderId = @SalesOrderId;

				--Create Temp Table 
				IF OBJECT_ID(N'tempdb..#SalesOrderBillingInvoiceList') IS NOT NULL
				BEGIN
					DROP TABLE #SalesOrderBillingInvoiceList
				END

				CREATE TABLE #SalesOrderBillingInvoiceList(
					SalesOrderNumber [VARCHAR](MAX)  NULL,
					partnumber [VARCHAR](MAX) NOT NULL,
					ItemMasterId [BIGINT]  NULL,
					PartDescription [VARCHAR](MAX) NULL,
					ConditionId [BIGINT]  NULL,
					SalesOrderId [BIGINT]  NULL,
					SalesOrderPartId [BIGINT]  NULL,
					SOPartId [BIGINT]  NULL,
					Status  [VARCHAR](150)  NULL,
					ItemNo  [INT]  NULL
				);


				IF (ISNULL(@AllowBillingBeforeShipping, 0) = 0)
				BEGIN
					INSERT INTO #SalesOrderBillingInvoiceList(SalesOrderNumber,partnumber,ItemMasterId,PartDescription,ConditionId,SalesOrderId,SalesOrderPartId, SOPartId,Status,ItemNo)
					(
					SELECT DISTINCT so.SalesOrderNumber, imt.partnumber,imt.ItemMasterId, imt.PartDescription, sop.ConditionId, sop.SalesOrderId, imt.ItemMasterId As SalesOrderPartId, sop.SalesOrderPartId, '' as [Status],	0 AS ItemNo
					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId
					INNER JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sos.SalesOrderId = sop.SalesOrderId
					INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
					LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
					LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SalesOrderId = sos.SalesOrderId AND sobi.IsProforma = 0
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId
								AND sobii.SalesOrderPartId = sop.SalesOrderPartId AND sobii.NoofPieces = sosi.QtyShipped
								AND ISNULL(sobii.IsVersionIncrease,0) = 0 AND ISNULL(sobii.IsProforma,0) = 0
					WHERE sop.SalesOrderId = @SalesOrderId AND ISNULL(sop.StockLineId,0) >0
					GROUP BY so.SalesOrderNumber, imt.partnumber,imt.ItemMasterId, imt.PartDescription,
					sop.SalesOrderId, imt.ItemMasterId, sop.ConditionId, sop.SalesOrderPartId)
				END
				ELSE
				BEGIN

				IF (@SalesOrderShippingId > 0)
				BEGIN
					INSERT INTO #SalesOrderBillingInvoiceList(SalesOrderNumber,partnumber,ItemMasterId,PartDescription,ConditionId,SalesOrderId,SalesOrderPartId,SOPartId,Status,ItemNo)
					(SELECT DISTINCT so.SalesOrderNumber, imt.partnumber,imt.ItemMasterId, imt.PartDescription, sop.ConditionId, 				
					sop.SalesOrderId, imt.ItemMasterId AS SalesOrderPartId, sop.SalesOrderPartId AS SOPartId,	'' as [Status], 0 AS ItemNo
					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
					LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
					LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SalesOrderId = sop.SalesOrderId AND ISNULL(sobi.IsProforma,0) = 0--AND sobi.IsVersionIncrease = 0
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId
								AND sobii.SalesOrderPartId = sop.SalesOrderPartId AND sobii.NoofPieces = sop.Qty
								AND sobii.IsVersionIncrease = 0 AND ISNULL(sobii.IsProforma,0) = 0
					LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sos.SalesOrderId = sop.SalesOrderId
					LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = sop.SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
					WHERE sop.SalesOrderId = @SalesOrderId AND ISNULL(sop.StockLineId,0) >0
					AND (ISNULL(soapr.SalesOrderApprovalId, 0) > 0 OR ISNULL(sosi.QtyShipped, 0) > 0) 
					GROUP BY so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, imt.PartDescription,
					sop.SalesOrderId, imt.ItemMasterId, sop.SalesOrderPartId, sop.ConditionId)
				END
				ELSE 
				BEGIN 
					INSERT INTO #SalesOrderBillingInvoiceList(SalesOrderNumber,partnumber,ItemMasterId,PartDescription,ConditionId,SalesOrderId,SalesOrderPartId,SOPartId,Status,ItemNo)
					(SELECT DISTINCT so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, imt.PartDescription, sop.ConditionId, 				
					sop.SalesOrderId, imt.ItemMasterId AS SalesOrderPartId,	sop.SalesOrderPartId AS SOPartId,'' as [Status],0 AS ItemNo
					FROM DBO.SalesOrderPart sop WITH (NOLOCK)
					LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId
					LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
					LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = sop.StockLineId
					LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) on sobi.SalesOrderId = sop.SalesOrderId AND ISNULL(sobi.IsProforma,0) = 0--AND sobi.IsVersionIncrease = 0
					LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) on sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId
								AND sobii.SalesOrderPartId = sop.SalesOrderPartId AND sobii.NoofPieces = sop.Qty
								AND sobii.IsVersionIncrease = 0 AND ISNULL(sobii.IsProforma,0) = 0
					LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) on sos.SalesOrderId = sop.SalesOrderId
					LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
					LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = sop.SalesOrderId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
					WHERE sop.SalesOrderId = @SalesOrderId AND ISNULL(sop.StockLineId,0) >0
					AND ((ISNULL(soapr.SalesOrderApprovalId, 0) > 0   
					AND (ISNULL(SOR.SalesOrderReservePartId, 0) > 0) AND (ISNULL(SOR.TotalReserved, 0) > 0)) OR ISNULL(sosi.QtyShipped, 0) > 0)
					GROUP BY so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, imt.PartDescription,
					sop.SalesOrderId, imt.ItemMasterId, sop.ConditionId, sop.SalesOrderPartId)
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

				--SELECT * FROM #tmpSalesOrderPart

				INSERT INTO #tmpSalesOrderPart(SalesOrderId, SalesOrderPartId, ConditionId, ItemMasterId)
				SELECT SalesOrderId, SalesOrderPartId, ConditionId, ItemMasterId FROM DBO.SalesOrderPart WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId
				
				SELECT @COUNT = MAX(ID) FROM #tmpSalesOrderPart 

				WHILE(@COUNT > 0)
				BEGIN
					SELECT @ItemMasterId = ItemMasterId, @ConditionId = ConditionId, @SalesOrderPartId = SalesOrderPartId FROM #tmpSalesOrderPart WITH(NOLOCK) WHERE ID = @COUNT

					--SELECT @ItemMasterId AS 'ItemMasterId', @ConditionId AS 'ConditionId' , @SalesOrderPartId AS 'SalesOrderPartId', @SalesOrderId
					--SELECT * FROM #SalesOrderBillingInvoiceList

					IF((SELECT COUNT(1) FROM #SalesOrderBillingInvoiceList WHERE ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId AND SalesOrderId = @SalesOrderId AND SOPartId = @SalesOrderPartId) <= 0)
					BEGIN
					
					--SELECT * FROM #SalesOrderBillingInvoiceList
						INSERT INTO #SalesOrderBillingInvoiceList(SalesOrderNumber,partnumber,ItemMasterId,PartDescription,ConditionId,SalesOrderId,SalesOrderPartId,SOPartId,Status,ItemNo)
						(SELECT DISTINCT so.SalesOrderNumber, 
										imt.partnumber, 
										imt.ItemMasterId,
										imt.PartDescription, 
										sop.ConditionId, 				
										sop.SalesOrderId, 
										imt.ItemMasterId AS SalesOrderPartId,	
										sop.SalesOrderPartId As SOPartId,
										'' AS [Status],
										0 AS ItemNo
								FROM DBO.SalesOrderPart sop WITH (NOLOCK)
									INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
									INNER JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
									--LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId
									--LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SalesOrderId = sop.SalesOrderId AND ISNULL(sobi.IsProforma,0) = 1
									--LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId AND ISNULL(sobii.IsProforma,0) = 1
									--			AND sobii.SalesOrderPartId = sop.SalesOrderPartId AND sobii.NoofPieces = sop.Qty
									--			AND sobii.IsVersionIncrease = 0
								WHERE sop.SalesOrderId = @SalesOrderId AND sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = @ConditionId AND  sop.SalesOrderPartId = @SalesOrderPartId
								GROUP BY so.SalesOrderNumber, imt.partnumber,imt.ItemMasterId, imt.PartDescription,sop.SalesOrderId,  imt.ItemMasterId, sop.SalesOrderPartId, sop.ConditionId)
					END
					
					SET @COUNT = @COUNT - 1
				END

				SELECT DISTINCT SalesOrderNumber,
					   partnumber,
					   ItemMasterId,
					   PartDescription,
					   ConditionId,
					   SalesOrderId,
					   SalesOrderPartId,
					   Status,
					   ItemNo 
			  FROM #SalesOrderBillingInvoiceList;
					
				END
			END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetSalesOrderBillingInvoiceList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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