/**************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   	Date         Author				Change Description            
 ** --   	--------     -------			--------------------------------     
	1    26/07/2023   Ayesha Sultana		condition overriding bug fix in billing/invoicing
	2    31/08/2023   Devendra Shekh		old version billing partnumber issue resolved
	3    01/01/2024   Devendra Shekh		updated for serialnumber
	4    01/02/2024   Devendra Shekh		updated for serialnumber
	5    22-01-2024   Shrey Chandegara		updated for Notes
	6    24-01-2024   Shrey Chandegara      remove condition from WorkOrderBillingInvoicing for QtyBilled
	7    30/01/2024   Devendra Shekh		updated for performInvoice
	8    01/02/2024   Devendra Shekh		updated for performInvoice
	9    06/02/2024   Shrey Chandegara      add conditionId for multiple billing invoicing issue.
	10   06/02/2024   Devendra Shekh		updated for performInvoice
	11   08/02/2024   Devendra Shekh		added new param @IncludeProformaInvoice
	12   12/02/2024   Devendra Shekh		duplicate data for proforma Issue resolved
	13   14/02/2024   Devendra Shekh	    added depositamt field for select
	14   20/02/2024   Devendra Shekh	    added [IsAllowIncreaseVersionForBillItem] field for select
	14   26/02/2024   Devendra Shekh	    added default invoice name for STANDARD

	EXEC [sp_GetWorkOrderBillingInvoiceChildList] 4176,3668

**************************************************************/ 

CREATE   Procedure [dbo].[sp_GetWorkOrderBillingInvoiceChildList]
	@WorkOrderId  BIGINT,
	@WorkOrderPartId BIGINT,
	@IncludeProformaInvoice BIT
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

				IF OBJECT_ID('tempdb.dbo.#InvoiceMainDetails', 'U') IS NOT NULL
					DROP TABLE #InvoiceMainDetails; 

				CREATE TABLE #InvoiceMainDetails (
					[Id] [BIGINT] IDENTITY NOT NULL,
					[WOBillingInvoicingId] [BIGINT] NULL,
					[WorkOrderShippingId] [BIGINT] NULL,
					[InvoiceDate] [DATETIME2] NULL,
					[InvoiceNo] [VARCHAR](256) NULL,
					[WOShippingNum] [VARCHAR](50) NULL,
					[QtyToBill] [INT] NULL,
					[WorkOrderNumber] [VARCHAR](30) NULL,
					[PartNumber] [VARCHAR](50) NULL,
					[PartDescription] [NVARCHAR](MAX) NULL,
					[StockLineNumber] [VARCHAR](50) NULL,
					[SerialNumber] [VARCHAR](30) NULL,
					[QtyBilled] [INT] NULL,
					[ItemNo] [INT] NULL,
					[WorkOrderId] [BIGINT] NULL,
					[WorkOrderPartId] [BIGINT] NULL,
					[Condition] [NVARCHAR](MAX) NULL,
					[CurrencyCode] [VARCHAR](10) NULL,
					[TotalSales] [DECIMAL](18,2) NULL,
					[InvoiceStatus] [VARCHAR](10) NULL,
					[VersionNo] [VARCHAR](10) NULL,
					[ItemMasterId] [BIGINT] NULL,
					[IsAllowIncreaseVersion] [BIT] NULL,
					[WorkFlowWorkOrderId] [BIGINT] NULL,
					[AWB] [VARCHAR](50) NULL,
					[IsFinishGood] [BIT] NULL,
					[Notes] [NVARCHAR](MAX) NULL,
					[InvoiceTypeName] [VARCHAR](50) NULL,
					[IsProformaInvoice] [bit] NULL,
					[ConditionId] [BIGINT] NULL,
					[IsInvoicePosted] [bit] NULL,
					[DepositAmount] [DECIMAL](18,2) NULL,
					[UsedDeposit] [DECIMAL](18,2) NULL,
					[IsAllowIncreaseVersionForBillItem] [BIT] NULL,
				)


				IF EXISTS (SELECT TOP 1 * FROM DBO.WorkOrderShipping WOS WITH(NOLOCK) WHERE WOS.WorkOrderId = @WorkOrderId AND WorkOrderPartNoId = @WorkOrderPartId)
				BEGIN
					SELECT * INTO #MyTempTable from 
					(SELECT DISTINCT 
						wosi.WorkOrderShippingId, 
						CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
						CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
						CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
						wos.WOShippingNum, 
						wos.AirwayBill As 'AWB',
						(SUM(wosi.QtyShipped)- (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0)) as QtyToBill, 
						wo.WorkOrderNum as WorkOrderNumber, 
						--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
						--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imt.PartNumber ELSE 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartNumber ELSE imt.PartNumber END END as 'PartNumber',
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imt.PartDescription ELSE 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartDescription ELSE imt.PartDescription END END as 'PartDescription',
						sl.StockLineNumber,
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND ISNULL(wobi.RevisedSerialNumber, '') != '' THEN wobi.RevisedSerialNumber 
						ELSE CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END END AS 'SerialNumber', 
						cr.[Name] as CustomerName, 
						(SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) AS QtyBilled,
						'1' as ItemNo,
						wop.WorkOrderId, 
						wop.Id as WorkOrderPartId, 
						-- CASE WHEN  ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END as 'Condition',
						cond.Memo as 'Condition',
						cond.ConditionId,
						curr.Code as 'CurrencyCode',
						--wocd.TotalCost as TotalSales,
						(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobi.SubTotal end) as TotalSales,
						wobi.InvoiceStatus ,
						(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
						(CASE WHEN wobi.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersion
						,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
						,ISNULL(wop.IsFinishGood,0)IsFinishGood
						,wobi.Notes
						,ISNULL(INV.[Description],'STANDARD') AS [InvoiceTypeName]
						,ISNULL(wobi.[IsInvoicePosted], 0) AS [IsInvoicePosted]
						,ISNULL(wobi.[DepositAmount], 0) AS [DepositAmount]
						,ISNULL(wobi.[UsedDeposit], 0) AS [UsedDeposit]
						,(CASE WHEN wobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem
						--,(CASE WHEN ISNULL((SELECT TOP 1 ISNULL(stkh.ActionId,0) FROM DBO.Stkline_History stkh WITH(NOLOCK) WHERE stkh.StocklineId = sl.StockLineId),0) = @ActionId THEN 1 else 0 END) IsReOpen
					FROM DBO.WorkOrderShippingItem wosi WITH(NOLOCK)
						INNER JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wosi.WorkOrderShippingId = wos.WorkOrderShippingId
						LEFT JOIN dbo.WorkOrderWorkFlow wof WITH(NOLOCK) on wos.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @WorkOrderPartId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
						LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobi.WorkOrderId = wof.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 0 --AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
						INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
						LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
						INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
						LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) on imv.ItemMasterId = wobi.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN DBO.WorkOrderCustomsInfo woc WITH(NOLOCK) on woc.WorkOrderShippingId = wos.WorkOrderShippingId
						LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
						LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wosc.ConditionId
						LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
						LEFT JOIN DBO.InvoiceType INV WITH(NOLOCK) on INV.InvoiceTypeId = wobi.InvoiceTypeId
					WHERE wos.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 

					GROUP BY wosi.WorkOrderShippingId, wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
						wos.WOShippingNum, wos.AirwayBill, wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
						sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
						-- CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END,
						cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobi.SubTotal 
						, wobii.WOBillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription,wop.IsFinishGood
						,wobi.ItemMasterId,wop.RevisedSerialNumber,wobi.RevisedSerialNumber,wobi.Notes,cond.ConditionId,INV.[Description],wobi.[IsInvoicePosted]
						,wobi.[DepositAmount],wobi.[UsedDeposit],wobii.IsVersionIncrease
					) a

					;WITH CTE_Temp AS
					(
						SELECT *,
						--(CASE WHEN ISNULL((SELECT TOP 1 ISNULL(stkh.ActionId,0) FROM DBO.Stkline_History stkh WITH(NOLOCK) WHERE stkh.StocklineId = StockLineId ORDER BY StklineHistoryId DESC),0) = @ActionId THEN 1 else 0 END) AS IsReOpen,
							ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
						FROM #MyTempTable
					)
	
					INSERT INTO #InvoiceMainDetails([WOBillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [WorkOrderNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], [IsProformaInvoice], [ConditionId]
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem])
					select [WOBillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [WorkOrderNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], 0, ConditionId
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem] from CTE_Temp t1
					where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
							or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
							or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
							or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
							AND
							((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
					ORDER BY WOBillingInvoicingId desc	
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
								CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
								CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
								CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
								wos.WOShippingNum, 
								wos.AirwayBill As 'AWB',
								(SUM(wosi.QtyShipped)- (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0)) as QtyToBill, 
								wo.WorkOrderNum as WorkOrderNumber, 
								--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
								--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
								CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imt.PartNumber ELSE 
								CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartNumber ELSE imt.PartNumber END END as 'PartNumber',
								CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imt.PartDescription ELSE 
								CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartDescription ELSE imt.PartDescription END END as 'PartDescription',
								sl.StockLineNumber,
								CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND ISNULL(wobi.RevisedSerialNumber, '') != '' THEN wobi.RevisedSerialNumber 
								ELSE CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END END AS 'SerialNumber',
								cr.[Name] as CustomerName, 
								(SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) AS QtyBilled,
								'1' as ItemNo,
								wop.WorkOrderId, 
								wop.Id as WorkOrderPartId, 
								-- CASE WHEN  ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END as 'Condition',
								cond.Memo as 'Condition',
								cond.ConditionId,
								curr.Code as 'CurrencyCode',
								--wocd.TotalCost as TotalSales,
								(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobi.SubTotal end) as TotalSales,
								wobi.InvoiceStatus ,
								(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
								CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
								(CASE WHEN wobi.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersion
								,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
								,ISNULL(wop.IsFinishGood,0)IsFinishGood
								,wobi.Notes
								,ISNULL(INV.[Description],'STANDARD') AS [InvoiceTypeName]
								,ISNULL(wobi.[IsInvoicePosted], 0) AS [IsInvoicePosted]
								,ISNULL(wobi.[DepositAmount], 0) AS [DepositAmount]
								,ISNULL(wobi.[UsedDeposit], 0) AS [UsedDeposit]
								,(CASE WHEN wobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem
								--,S.ConditionId AS 'ConditionId'
							FROM DBO.WorkOrderShippingItem wosi WITH(NOLOCK)
								INNER JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wosi.WorkOrderShippingId = wos.WorkOrderShippingId								
								LEFT JOIN dbo.WorkOrderWorkFlow wof WITH(NOLOCK) on wos.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @WorkOrderPartId
								LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
								LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobi.WorkOrderId = wof.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 0 --AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
								INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
								LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
								INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
								INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
								LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
								LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
								LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) on imv.ItemMasterId = wobi.ItemMasterId
								LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
								LEFT JOIN DBO.WorkOrderCustomsInfo woc WITH(NOLOCK) on woc.WorkOrderShippingId = wos.WorkOrderShippingId
								LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
								LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wosc.ConditionId
								LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
								LEFT JOIN DBO.InvoiceType INV WITH(NOLOCK) on INV.InvoiceTypeId = wobi.InvoiceTypeId
							WHERE wos.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 
							GROUP BY wosi.WorkOrderShippingId, wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
								wos.WOShippingNum, wos.AirwayBill, wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
								sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
								-- CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END,
								cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobi.SubTotal 
								, wobii.WOBillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription,wop.IsFinishGood
								,wobi.ItemMasterId,wop.RevisedSerialNumber,wobi.RevisedSerialNumber,wobi.Notes,cond.ConditionId,INV.[Description],wobi.[IsInvoicePosted]
								,wobi.[DepositAmount],wobi.[UsedDeposit],wobii.IsVersionIncrease
							) a

							;WITH CTE_Temp AS
							(
								SELECT *,
								--(CASE WHEN ISNULL((SELECT TOP 1 ISNULL(stkh.ActionId,0) FROM DBO.Stkline_History stkh WITH(NOLOCK) WHERE stkh.StocklineId = StockLineId ORDER BY StklineHistoryId DESC),0) = @ActionId THEN 1 else 0 END) AS IsReOpen,
									ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
								FROM #MyTempTable1
							)
	
							INSERT INTO #InvoiceMainDetails([WOBillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [WorkOrderNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], [IsProformaInvoice], [ConditionId]
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem])
							select [WOBillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [WorkOrderNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], 0, ConditionId
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem] from CTE_Temp t1
							where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
									or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
									or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
									or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
									AND
									((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
							ORDER BY WOBillingInvoicingId desc	
							drop table  #MyTempTable1 
					END
					ELSE
					BEGIN
						PRINT 'ELSE'
						SELECT * INTO #MyTempTable2 from 
						(SELECT DISTINCT 
							--wop.ID AS WorkOrderShippingId, 
							CASE WHEN wosi.WorkOrderShippingId IS NOT NULL THEN wosi.WorkOrderShippingId ELSE wop.ID END AS WorkOrderShippingId, 
							CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
							CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
							CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
							'' AS WOShippingNum, 
							'' As 'AWB',
							--(SUM(wopick.QtyToShip)- (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId)) as QtyToBill, 
							(SUM(wop.Quantity)- (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0)) as QtyToBill, 
							wo.WorkOrderNum as WorkOrderNumber, 
							--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
							--CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'PartDescription', 
							CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imt.PartNumber ELSE 
							CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartNumber ELSE imt.PartNumber END END as 'PartNumber',
							CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imt.PartDescription ELSE 
							CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartDescription ELSE imt.PartDescription END END as 'PartDescription',
							sl.StockLineNumber,
							CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND ISNULL(wobi.RevisedSerialNumber, '') != '' THEN wobi.RevisedSerialNumber 
							ELSE CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END END AS 'SerialNumber', 
							cr.[Name] as CustomerName, 
							(SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) AS QtyBilled,
							'1' as ItemNo,
							wop.WorkOrderId, 
							wop.Id as WorkOrderPartId, 
							-- CASE WHEN  ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END as 'Condition',
							cond.Memo as 'Condition',
							cond.ConditionId ,
							curr.Code as 'CurrencyCode',
							(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobi.SubTotal end) as TotalSales,
							wobi.InvoiceStatus ,
							(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
							CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
							(CASE WHEN wobi.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersion
							,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
							,ISNULL(wop.IsFinishGood,0)IsFinishGood
							,wobi.Notes
							,ISNULL(INV.[Description],'STANDARD') AS [InvoiceTypeName]
							,ISNULL(wobi.[IsInvoicePosted], 0) AS [IsInvoicePosted]
							,ISNULL(wobi.[DepositAmount], 0) AS [DepositAmount]
							,ISNULL(wobi.[UsedDeposit], 0) AS [UsedDeposit]
							,(CASE WHEN wobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem
						FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)							
							LEFT JOIN dbo.WorkOrderWorkFlow wof WITH(NOLOCK) on wop.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @WorkOrderPartId
							LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
							LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobi.WorkOrderId = wof.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 0 --AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
							LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
							INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
							INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
							LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
							LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
							LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) on imv.ItemMasterId = wobi.ItemMasterId
							LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
							LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
							LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wosc.ConditionId
							LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
							--INNER JOIN DBO.WOPickTicket wopick WITH(NOLOCK) on wopick.WorkOrderId = wop.WorkOrderId AND wop.ID = wopick.OrderPartId
							LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId
							LEFT JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
							LEFT JOIN DBO.InvoiceType INV WITH(NOLOCK) on INV.InvoiceTypeId = wobi.InvoiceTypeId
						WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 
						AND (ISNULL(wop.IsFinishGood, 0) = 1)
						GROUP BY wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
							wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
							sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
							-- CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END,
							cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobi.SubTotal 
							, wobii.WOBillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription, wosi.WorkOrderShippingId,wop.IsFinishGood
							,wobi.ItemMasterId,wop.RevisedSerialNumber,wobi.RevisedSerialNumber,wobi.Notes,cond.ConditionId,INV.[Description],wobi.[IsInvoicePosted]
							,wobi.[DepositAmount],wobi.[UsedDeposit],wobii.IsVersionIncrease
						) a

						;WITH CTE_Temp AS
						(
							SELECT *,
							--(CASE WHEN ISNULL((SELECT TOP 1 ISNULL(stkh.ActionId,0) FROM DBO.Stkline_History stkh WITH(NOLOCK) WHERE stkh.StocklineId = StockLineId ORDER BY StklineHistoryId DESC),0) = @ActionId  THEN 1 else 0 END) AS IsReOpen,
								ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
							FROM #MyTempTable2
						)
	
						INSERT INTO #InvoiceMainDetails([WOBillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [WorkOrderNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], [IsProformaInvoice], [ConditionId]
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem])
						select [WOBillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [WorkOrderNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], 0, ConditionId
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem] from CTE_Temp t1
						where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
								or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
								or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
								or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
								AND
								((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
						ORDER BY WOBillingInvoicingId desc	
						drop table  #MyTempTable2 
					END
				END

				IF(@IncludeProformaInvoice = 1)
				BEGIN
					--INSERTING BillingInvoicing Details For ProformaInvoice ::-START
					SELECT * INTO #MyTempTable3 FROM 
					(SELECT DISTINCT 
						CASE WHEN wos.WorkOrderShippingId IS NOT NULL THEN wos.WorkOrderShippingId 
							 ELSE CASE WHEN ISNULL(woProfomaBillData.WorkOrderShippingId, 0) > 0 THEN woProfomaBillData.WorkOrderShippingId
							 --ELSE CASE WHEN wosisn.WorkOrderShippingId IS NOT NULL THEN wosisn.WorkOrderShippingId
							 ELSE 0  END END AS WorkOrderShippingId, 
						CASE WHEN wop.ID IS NOT NULL AND  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK)  WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
						CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
						CASE WHEN wop.ID IS NOT NULL AND  (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
						CASE WHEN ISNULL(wos.WOShippingNum, '') = ''  THEN '' ELSE wos.WOShippingNum END AS WOShippingNum, 
						CASE WHEN ISNULL(wos.AirwayBill, '') = '' THEN '' ELSE wos.AirwayBill END As 'AWB',
						CASE WHEN ISNULL(wos.WorkOrderShippingId, 0) != 0 
							 THEN (SUM(wosi.QtyShipped)- (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1))
							 ELSE (SUM(wop.Quantity)- (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1)) END AS QtyToBill, 
						wo.WorkOrderNum AS WorkOrderNumber, 
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imt.PartNumber ELSE 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartNumber ELSE imt.PartNumber END END AS 'PartNumber',
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imt.PartDescription ELSE 
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartDescription ELSE imt.PartDescription END END AS 'PartDescription',
						sl.StockLineNumber,
						CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND ISNULL(wobi.RevisedSerialNumber, '') != '' THEN wobi.RevisedSerialNumber 
						ELSE CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END END AS 'SerialNumber', 
						cr.[Name] AS CustomerName, 
						(SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) AS QtyBilled,
						'1' AS ItemNo,
						wop.WorkOrderId, 
						wop.Id AS WorkOrderPartId, 
						CASE WHEN ISNULL(billcond.Memo, '') != '' THEN billcond.Memo 
							 WHEN ISNULL(billcond.Code, '') != '' THEN billcond.Code ELSE cond.Memo END AS 'Condition',
						CASE WHEN ISNULL(billcond.ConditionId, 0) = 0 THEN cond.ConditionId ELSE billcond.ConditionId END AS 'ConditionId',
						curr.Code AS 'CurrencyCode',
						(CASE WHEN (CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) IS NULL THEN 0 ELSE wobi.SubTotal END) AS TotalSales,
						wobi.InvoiceStatus ,
						(CASE WHEN (CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(1) FROM DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) IS NULL THEN NULL ELSE wobi.VersionNo END) AS VersionNo ,
						CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
						(CASE WHEN wobi.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsAllowIncreaseVersion
						,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
						,ISNULL(wop.IsFinishGood,0)IsFinishGood
						,wobi.Notes
						,ISNULL(INV.[Description], 'PROFORMA') AS [InvoiceTypeName]
						,CASE WHEN UPPER(ISNULL(woBillData.InvoiceStatus, '')) = 'INVOICED' THEN 1 ELSE ISNULL(wobi.[IsInvoicePosted], 0) END AS [IsInvoicePosted]
						,ISNULL(wobi.[DepositAmount], 0) AS [DepositAmount]
						,ISNULL(wobi.[UsedDeposit], 0) AS [UsedDeposit]
						,(CASE WHEN wobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem
					FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)							
						LEFT JOIN dbo.WorkOrderWorkFlow wof WITH(NOLOCK) on wop.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @WorkOrderPartId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1
						LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobi.WorkOrderId = wof.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 1 
						--LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
						INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) on imv.ItemMasterId = wobi.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
						LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wobi.ConditionId
						LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
						LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderId = wop.WorkOrderId AND wobi.WorkOrderShippingId = wos.WorkOrderShippingId
						LEFT JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
						--LEFT JOIN DBO.WorkOrderShipping wossn WITH(NOLOCK) on wop.WorkOrderId = wossn.WorkOrderId
						--LEFT JOIN DBO.WorkOrderShippingItem wosisn WITH(NOLOCK) on wossn.WorkOrderShippingId = wosisn.WorkOrderShippingId AND wosisn.WorkOrderPartNumId = wop.ID
						LEFT JOIN DBO.InvoiceType INV WITH(NOLOCK) on INV.InvoiceTypeId = wobi.InvoiceTypeId
						LEFT JOIN DBO.Condition billcond  WITH(NOLOCK) on billcond.ConditionId = wobi.ConditionId
						OUTER APPLY
							(SELECT NWOP.WorkOrderId, NWOP.Id,NWOBI.InvoiceStatus FROM DBO.WorkOrderPartNumber NWOP WITH(NOLOCK)							
							LEFT JOIN dbo.WorkOrderWorkFlow NWOF WITH(NOLOCK) on NWOP.WorkOrderId = NWOF.WorkOrderId AND NWOF.WorkOrderPartNoId = @WorkOrderPartId
							LEFT JOIN DBO.WorkOrderBillingInvoicingItem NWOBII WITH(NOLOCK) on NWOBII.WorkOrderPartId = @WorkOrderPartId AND ISNULL(NWOBII.IsPerformaInvoice, 0) = 0
							LEFT JOIN DBO.WorkOrderBillingInvoicing NWOBI WITH(NOLOCK) on NWOBI.BillingInvoicingId = NWOBII.BillingInvoicingId AND NWOBI.WorkOrderId = NWOF.WorkOrderId AND ISNULL(NWOBI.IsPerformaInvoice, 0) = 0
							WHERE NWOP.WorkOrderId = @WorkOrderId AND NWOP.ID = @WorkOrderPartId AND (ISNULL(NWOP.IsFinishGood, 0) = 1) AND ISNULL(NWOBII.IsVersionIncrease, 0) = 0 GROUP BY NWOP.WorkOrderId, NWOP.Id,NWOBI.InvoiceStatus) woBillData
						OUTER APPLY
							(SELECT PWOP.WorkOrderId, PWOP.Id,PWOSSN.WorkOrderShippingId  FROM DBO.WorkOrderPartNumber PWOP WITH(NOLOCK)							
							LEFT JOIN dbo.WorkOrderWorkFlow PWOF WITH(NOLOCK) on PWOP.WorkOrderId = PWOF.WorkOrderId AND PWOF.WorkOrderPartNoId = @WorkOrderPartId
							LEFT JOIN DBO.WorkOrderBillingInvoicingItem PWOBII WITH(NOLOCK) on PWOBII.WorkOrderPartId = @WorkOrderPartId AND ISNULL(PWOBII.IsPerformaInvoice, 0) = 1
							LEFT JOIN DBO.WorkOrderBillingInvoicing PWOBI WITH(NOLOCK) on PWOBI.BillingInvoicingId = PWOBII.BillingInvoicingId AND PWOBI.WorkOrderId = PWOF.WorkOrderId AND ISNULL(PWOBI.IsPerformaInvoice, 0) = 1
						    LEFT JOIN DBO.WorkOrderShippingItem PWOSISN WITH(NOLOCK) on PWOSISN.WorkOrderPartNumId = PWOP.ID AND PWOSISN.WorkOrderPartNumId = @WorkOrderPartId
							LEFT JOIN DBO.WorkOrderShipping PWOSSN WITH(NOLOCK) on PWOSISN.WorkOrderShippingId = PWOSSN.WorkOrderShippingId
							WHERE PWOP.WorkOrderId = @WorkOrderId AND PWOP.ID = @WorkOrderPartId AND (ISNULL(PWOP.IsFinishGood, 0) = 1) AND ISNULL(PWOBII.IsVersionIncrease, 0) = 0 GROUP BY PWOP.WorkOrderId, PWOP.Id,PWOSSN.WorkOrderShippingId) woProfomaBillData
					WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 
					--AND ((SELECT CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END) NOT IN (SELECT TMP.ItemMasterId FROM #InvoiceMainDetails TMP WHERE ISNULL(TMP.[IsProformaInvoice], 0) = 1))
					GROUP BY wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
						wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
						sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
						--,wocd.TotalCost
						cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wobi.SubTotal 
						, wobii.WOBillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription, wos.WorkOrderShippingId,wop.IsFinishGood
						,wobi.ItemMasterId,wop.RevisedSerialNumber,wobi.RevisedSerialNumber,wobi.Notes,wos.WOShippingNum,wos.AirwayBill,wos.WorkOrderShippingId
						--,wosisn.WorkOrderShippingId
						,INV.[Description],cond.ConditionId,wobi.[IsInvoicePosted],billcond.Memo,billcond.Code,billcond.ConditionId,woBillData.InvoiceStatus
						,woProfomaBillData.WorkOrderShippingId,wobi.[DepositAmount],wobi.[UsedDeposit],wobii.IsVersionIncrease
					) a

					;WITH CTE_Temp AS
					(
						SELECT *,
							ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
						FROM #MyTempTable3
					)
					INSERT INTO #InvoiceMainDetails([WOBillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [WorkOrderNumber], [PartNumber], [PartDescription],
														[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
														[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], [IsProformaInvoice], [ConditionId]
														,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem])
					SELECT [WOBillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [WorkOrderNumber], [PartNumber], [PartDescription],
														[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
														[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], 1, ConditionId
														,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem] from CTE_Temp t1
					WHERE (((VersionNo IS NULL AND IsAllowIncreaseVersion =1) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable3 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0) AND RowNumber =1)
							OR ((VersionNo IS NOT NULL AND IsAllowIncreaseVersion =1) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable3 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
							OR((VersionNo IS NULL AND IsAllowIncreaseVersion =0) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable3 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0) AND RowNumber =1)
							OR ((VersionNo IS NOT NULL AND IsAllowIncreaseVersion =0) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable3 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
							AND
							((VersionNo IS NULL AND InvoiceStatus IS NULL) OR  (VersionNo IS NOT NULL AND InvoiceStatus IS NOT NULL) OR (InvoiceStatus IS NOT NULL AND IsAllowIncreaseVersion = 1))
					ORDER BY WOBillingInvoicingId desc	
					drop table  #MyTempTable3 
					--INSERTING BillingInvoicing Details For ProformaInvoice ::-END
				END

				SELECT * FROM #InvoiceMainDetails;
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@WorkOrderId AS VARCHAR), '') + '''
													   @Parameter2 = ' + ISNULL(CAST(@WorkOrderPartId AS VARCHAR) ,'') +''
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