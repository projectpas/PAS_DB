/**************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   	Date         Author				Change Description            
 ** --   	--------     -------			--------------------------------     
	1    26/07/2023   Ayesha Sultana		condition overriding bug fix in billing/invoicing
	2    31/08/2023   Devendra Shekh		old version billing partnumber issue resolved
	3    01/01/2024   Devendra Shekh		updated for serialnumber
	4    01/02/2024   Devendra Shekh		updated for serialnumber
	4    22-01-2024   Shrey Chandegara		updated for Notes

	EXEC [sp_GetWorkOrderBillingInvoiceChildList] 3543,3013

**************************************************************/ 

CREATE     Procedure [dbo].[sp_GetWorkOrderBillingInvoiceChildList]
	@WorkOrderId  bigint,
	@WorkOrderPartId bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN		
				DECLARE @IsInvoiceBeforeShippingAllowed BIT;
				DECLARE @ActionId INT;
				SET @ActionId = 10; -- Re-OpenFinishedGood
				SELECT @IsInvoiceBeforeShippingAllowed = ISNULL(WOPN.AllowInvoiceBeforeShipping, 0) FROM DBO.WorkOrderPartNumber WOPN WITH(NOLOCK) WHERE WOPN.ID = @WorkOrderPartId;

				IF EXISTS (SELECT TOP 1 * FROM DBO.WorkOrderShipping WOS WITH(NOLOCK) WHERE WOS.WorkOrderId = @WorkOrderId AND WorkOrderPartNoId = @WorkOrderPartId)
				BEGIN
					SELECT * INTO #MyTempTable from 
					(SELECT DISTINCT 
						wosi.WorkOrderShippingId, 
						CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
						CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
						CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
						wos.WOShippingNum, 
						wos.AirwayBill As 'AWB',
						(SUM(wosi.QtyShipped)- (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId)) as QtyToBill, 
						wo.WorkOrderNum as WorkOrderNumber, 
						--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
						--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imv.PartNumber ELSE 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartNumber ELSE imt.PartNumber END END as 'PartNumber',
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imv.PartDescription ELSE 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartDescription ELSE imt.PartDescription END END as 'PartDescription',
						sl.StockLineNumber,
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND ISNULL(wobi.RevisedSerialNumber, '') != '' THEN wobi.RevisedSerialNumber 
						ELSE CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END END AS 'SerialNumber', 
						cr.[Name] as CustomerName, 
						(SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) AS QtyBilled,
						'1' as ItemNo,
						wop.WorkOrderId, 
						wop.Id as WorkOrderPartId, 
						-- CASE WHEN  ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END as 'Condition',
						cond.Memo as 'Condition',
						curr.Code as 'CurrencyCode',
						--wocd.TotalCost as TotalSales,
						(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobi.SubTotal end) as TotalSales,
						wobi.InvoiceStatus ,
						(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
						(CASE WHEN wobi.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersion
						,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
						,ISNULL(wop.IsFinishGood,0)IsFinishGood
						,wobi.Notes
						--,(CASE WHEN ISNULL((SELECT TOP 1 ISNULL(stkh.ActionId,0) FROM DBO.Stkline_History stkh WITH(NOLOCK) WHERE stkh.StocklineId = sl.StockLineId),0) = @ActionId THEN 1 else 0 END) IsReOpen
					FROM DBO.WorkOrderShippingItem wosi WITH(NOLOCK)
						INNER JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wosi.WorkOrderShippingId = wos.WorkOrderShippingId
						LEFT JOIN dbo.WorkOrderWorkFlow wof WITH(NOLOCK) on wos.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @WorkOrderPartId
						LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.WorkOrderId = wos.WorkOrderId AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId
						INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
						LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
						INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						-- LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
						LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) on imv.ItemMasterId = wobi.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN DBO.WorkOrderCustomsInfo woc WITH(NOLOCK) on woc.WorkOrderShippingId = wos.WorkOrderShippingId
						LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
						LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wobi.ConditionId
						LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
					WHERE wos.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 

					GROUP BY wosi.WorkOrderShippingId, wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
						wos.WOShippingNum, wos.AirwayBill, wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
						sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
						-- CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END,
						cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobi.SubTotal 
						, wobii.WOBillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription,wop.IsFinishGood
						,wobi.ItemMasterId,imv.PartNumber,imv.PartDescription,wop.RevisedSerialNumber,wobi.RevisedSerialNumber,wobi.Notes
					) a

					;WITH CTE_Temp AS
					(
						SELECT *,
						--(CASE WHEN ISNULL((SELECT TOP 1 ISNULL(stkh.ActionId,0) FROM DBO.Stkline_History stkh WITH(NOLOCK) WHERE stkh.StocklineId = StockLineId ORDER BY StklineHistoryId DESC),0) = @ActionId THEN 1 else 0 END) AS IsReOpen,
							ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
						FROM #MyTempTable
					)
	
					select * from CTE_Temp t1
					where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
							or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
							or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
							or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
							AND
							((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
					order by WOBillingInvoicingId desc	
					drop table  #MyTempTable 
				END
				ELSE
				BEGIN
					IF (@IsInvoiceBeforeShippingAllowed = 0)
					BEGIN
						PRINT 'IF'
						SELECT * INTO #MyTempTable1 from 
							(SELECT DISTINCT 
								wosi.WorkOrderShippingId, 
								CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
								CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
								CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
								wos.WOShippingNum, 
								wos.AirwayBill As 'AWB',
								(SUM(wosi.QtyShipped)- (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId)) as QtyToBill, 
								wo.WorkOrderNum as WorkOrderNumber, 
								--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
								--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
								CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imv.PartNumber ELSE 
								CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartNumber ELSE imt.PartNumber END END as 'PartNumber',
								CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imv.PartDescription ELSE 
								CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartDescription ELSE imt.PartDescription END END as 'PartDescription',
								sl.StockLineNumber,
								CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND ISNULL(wobi.RevisedSerialNumber, '') != '' THEN wobi.RevisedSerialNumber 
								ELSE CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END END AS 'SerialNumber',
								cr.[Name] as CustomerName, 
								(SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) AS QtyBilled,
								'1' as ItemNo,
								wop.WorkOrderId, 
								wop.Id as WorkOrderPartId, 
								-- CASE WHEN  ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END as 'Condition',
								cond.Memo as 'Condition',
								curr.Code as 'CurrencyCode',
								--wocd.TotalCost as TotalSales,
								(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobi.SubTotal end) as TotalSales,
								wobi.InvoiceStatus ,
								(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
								CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
								(CASE WHEN wobi.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersion
								,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
								,ISNULL(wop.IsFinishGood,0)IsFinishGood
								,wobi.Notes
							FROM DBO.WorkOrderShippingItem wosi WITH(NOLOCK)
								INNER JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wosi.WorkOrderShippingId = wos.WorkOrderShippingId								
								LEFT JOIN dbo.WorkOrderWorkFlow wof WITH(NOLOCK) on wos.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @WorkOrderPartId
								LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.WorkOrderId = wos.WorkOrderId AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
								LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId
								INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
								LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
								INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
								INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
								-- LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
								LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
								LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) on imv.ItemMasterId = wobi.ItemMasterId
								LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
								LEFT JOIN DBO.WorkOrderCustomsInfo woc WITH(NOLOCK) on woc.WorkOrderShippingId = wos.WorkOrderShippingId
								LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
								LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wobi.ConditionId
								LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
							WHERE wos.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 

							GROUP BY wosi.WorkOrderShippingId, wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
								wos.WOShippingNum, wos.AirwayBill, wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
								sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
								-- CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END,
								cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobi.SubTotal 
								, wobii.WOBillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription,wop.IsFinishGood
								,wobi.ItemMasterId,imv.PartNumber,imv.PartDescription,wop.RevisedSerialNumber,wobi.RevisedSerialNumber,wobi.Notes
							) a

							;WITH CTE_Temp AS
							(
								SELECT *,
								--(CASE WHEN ISNULL((SELECT TOP 1 ISNULL(stkh.ActionId,0) FROM DBO.Stkline_History stkh WITH(NOLOCK) WHERE stkh.StocklineId = StockLineId ORDER BY StklineHistoryId DESC),0) = @ActionId THEN 1 else 0 END) AS IsReOpen,
									ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
								FROM #MyTempTable1
							)
	
							select * from CTE_Temp t1
							where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
									or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
									or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
									or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
									AND
									((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
							order by WOBillingInvoicingId desc	
							drop table  #MyTempTable1 
					END
					ELSE
					BEGIN
						PRINT 'ELSE'
						SELECT * INTO #MyTempTable2 from 
						(SELECT DISTINCT 
							--wop.ID AS WorkOrderShippingId, 
							CASE WHEN wosi.WorkOrderShippingId IS NOT NULL THEN wosi.WorkOrderShippingId ELSE wop.ID END AS WorkOrderShippingId, 
							CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
							CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
							CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
							'' AS WOShippingNum, 
							'' As 'AWB',
							--(SUM(wopick.QtyToShip)- (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId)) as QtyToBill, 
							(SUM(wop.Quantity)- (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId)) as QtyToBill, 
							wo.WorkOrderNum as WorkOrderNumber, 
							--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
							--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
							CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imv.PartNumber ELSE 
							CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartNumber ELSE imt.PartNumber END END as 'PartNumber',
							CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imv.PartDescription ELSE 
							CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartDescription ELSE imt.PartDescription END END as 'PartDescription',
							sl.StockLineNumber,
							CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND ISNULL(wobi.RevisedSerialNumber, '') != '' THEN wobi.RevisedSerialNumber 
							ELSE CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END END AS 'SerialNumber', 
							cr.[Name] as CustomerName, 
							(SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) AS QtyBilled,
							'1' as ItemNo,
							wop.WorkOrderId, 
							wop.Id as WorkOrderPartId, 
							-- CASE WHEN  ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END as 'Condition',
							cond.Memo as 'Condition',
							curr.Code as 'CurrencyCode',
							(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobi.SubTotal end) as TotalSales,
							wobi.InvoiceStatus ,
							(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
							CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
							(CASE WHEN wobi.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersion
							,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
							,ISNULL(wop.IsFinishGood,0)IsFinishGood
							,wobi.Notes
						FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)							
							LEFT JOIN dbo.WorkOrderWorkFlow wof WITH(NOLOCK) on wop.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @WorkOrderPartId
							LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.WorkOrderId = wop.WorkOrderId AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
							LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId
							LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
							INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
							INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
							-- LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
							LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
							LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) on imv.ItemMasterId = wobi.ItemMasterId
							LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
							LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
							LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wobi.ConditionId
							LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
							--INNER JOIN DBO.WOPickTicket wopick WITH(NOLOCK) on wopick.WorkOrderId = wop.WorkOrderId AND wop.ID = wopick.OrderPartId
							LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId
							LEFT JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
						WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 

						GROUP BY wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
							wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
							sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
							-- CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END,
							cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobi.SubTotal 
							, wobii.WOBillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription, wosi.WorkOrderShippingId,wop.IsFinishGood
							,wobi.ItemMasterId,imv.PartNumber,imv.PartDescription,wop.RevisedSerialNumber,wobi.RevisedSerialNumber,wobi.Notes
						) a

						;WITH CTE_Temp AS
						(
							SELECT *,
							--(CASE WHEN ISNULL((SELECT TOP 1 ISNULL(stkh.ActionId,0) FROM DBO.Stkline_History stkh WITH(NOLOCK) WHERE stkh.StocklineId = StockLineId ORDER BY StklineHistoryId DESC),0) = @ActionId  THEN 1 else 0 END) AS IsReOpen,
								ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
							FROM #MyTempTable2
						)
	
						select * from CTE_Temp t1
						where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
								or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
								or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
								or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
								AND
								((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
						order by WOBillingInvoicingId desc	
						drop table  #MyTempTable2 
					END
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
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWorkOrderBillingInvoiceChildList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter2 = ' + ISNULL(@WorkOrderPartId ,'') +''
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