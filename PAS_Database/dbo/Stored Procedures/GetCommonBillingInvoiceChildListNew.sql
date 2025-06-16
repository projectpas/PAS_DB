
/*************************************************************           
 ** File:  [GetCommonBillingInvoiceListNew]           
 ** Author:	  Moin Bloch
 ** Description: This SP is Used to get list of Invoices for Part    
 ** Purpose:         
 ** Date:   27/05/2025        
 ** PARAMETERS: 
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------     
	1    27/05/2025   Moin Bloch		Created
	2    02/06/2025   Rajesh Gami		Implemented SO & Use IsInvoicePosted instead of IsBilling in SO
	3    16/06/2025   Rajesh Gami		Resolved issue regarding get the billing invoice
**************************************************************/ 
--   EXEC [dbo].[GetCommonBillingInvoiceChildListNew] 8810,8582,1,15

CREATE     PROCEDURE [dbo].[GetCommonBillingInvoiceChildListNew]
@ReferenceId BIGINT = NULL,
@SubReferenceId BIGINT = NULL, 
@IncludeProformaInvoice BIT = NULL,
@ModuleId INT = NULL,
@EmployeeId BIGINT = NULL,
@ConditionId bigint =NULL,
@ItemMasterId bigint =NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
			DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
			DECLARE @AllowBillingBeforeShipping BIT;
			DECLARE @FlateBilingMethodId INT = (SELECT BillingMethodId FROM dbo.BillingMethod WITH(NOLOCK) WHERE Description ='Flate Rate');

			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
			SELECT
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM
					dbo.Employee E WITH (NOLOCK)
				LEFT JOIN
					dbo.TimeZone ETZ WITH (NOLOCK)
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN
					dbo.LegalEntity LE WITH (NOLOCK)
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN
					dbo.TimeZone LTZ WITH (NOLOCK)
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE
					E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

			SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
			SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
			SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';	
			
			IF OBJECT_ID('tempdb.dbo.#InvoiceMainDetails', 'U') IS NOT NULL
					DROP TABLE #InvoiceMainDetails; 

			CREATE TABLE #InvoiceMainDetails (
				[Id] [BIGINT] IDENTITY NOT NULL,
				[BillingInvoicingId] [BIGINT] NULL,
				[WorkOrderShippingId] [BIGINT] NULL,
				[InvoiceDate] [DATETIME2] NULL,
				[InvoiceNo] [VARCHAR](256) NULL,
				[WOShippingNum] [VARCHAR](50) NULL,
				[QtyToBill] [INT] NULL,
				[ReferenceNumber] [VARCHAR](30) NULL,
				[PartNumber] [VARCHAR](50) NULL,
				[PartDescription] [NVARCHAR](MAX) NULL,
				[StockLineNumber] [VARCHAR](50) NULL,
				[SerialNumber] [VARCHAR](30) NULL,
				[QtyBilled] [INT] NULL,
				[ItemNo] [INT] NULL,
				[ReferenceId] [BIGINT] NULL,
				[SubReferenceId] [BIGINT] NULL,
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
				[IsQuickBookGeneratedInvoice] [BIT] NULL,

				[IndexColumn] BIGINT NULL,
				[SalesOrderShippingId] BIGINT NULL,
				[SalesOrderShippingItemId] BIGINT NULL,
				[BillingInvoicingItemId] BIGINT NULL,
				[InvoiceTypeId] BIGINT NULL,
				[SOShippingNum] VARCHAR(250) NULL,
				[SalesOrderNumber] VARCHAR(250) NULL,
				[CustomerName] VARCHAR(250) NULL,
				[StockLineId] BIGINT NULL,
				[SalesOrderId] BIGINT NULL,
				[SalesOrderPartId] BIGINT NULL,
				[SalesOrderStocklineId] BIGINT NULL,
				[TotalUnitCost] DECIMAL(18,2) NULL,
				[TotalFreight] DECIMAL(18,2) NULL,
				[TotalFlatFreight] DECIMAL(18,2) NULL,
				[TotalCharges] DECIMAL(18,2) NULL,
				[TotalFlatCharges] DECIMAL(18,2) NULL,
				[SmentNo] VARCHAR(250) NULL,
				[IsVersionIncrease] INT NULL,
				[IsNewInvoice] INT NULL,
				[IsBilling] BIT NULL,
				[ECCN] VARCHAR(200) NULL,
				[HSCODE] VARCHAR(200) NULL,
				[Weight] DECIMAL(18,2) NULL,
				[SizeLength] DECIMAL(18,2) NULL,
				[SizeWidth] DECIMAL(18,2) NULL,
				[SizeHeight] DECIMAL(18,2) NULL,
				IsLastInserted BIT DEFAULT 0
			)
		
			IF(@ModuleId = @WOModuleId) /*********START: WORK ORDER ********/
			BEGIN
	
				DECLARE @IsInvoiceBeforeShippingAllowed BIT;
				DECLARE @ActionId INT;
				SET @ActionId = 10; -- Re-OpenFinishedGood
				SELECT @IsInvoiceBeforeShippingAllowed = ISNULL(WOPN.[AllowInvoiceBeforeShipping], 0) FROM [dbo].[WorkOrderPartNumber] WOPN WITH(NOLOCK) WHERE WOPN.ID = @SubReferenceId;
				
				IF EXISTS (SELECT TOP 1 [WorkOrderShippingId] FROM [dbo].[WorkOrderShipping] WOS WITH(NOLOCK) WHERE WOS.WorkOrderId = @ReferenceId AND WorkOrderPartNoId = @SubReferenceId)
				BEGIN
					SELECT * INTO #MyTempTable FROM 
					(SELECT DISTINCT 
						wosi.WorkOrderShippingId, 
						CASE WHEN wop.ID IS NOT NULL AND  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS BillingInvoicingId, 
						CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
						CASE WHEN wop.ID IS NOT NULL AND  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
						wos.WOShippingNum, 
						wos.AirwayBill As 'AWB',
						(SUM(wosi.QtyShipped)- (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0)) as QtyToBill, 
						wo.WorkOrderNum as ReferenceNumber, 
						wop.RevisedPartNumber as 'PartNumber',
						wop.RevisedPartDescription as 'PartDescription',
						sl.StockLineNumber,
						wop.RevisedSerialNumber AS 'SerialNumber', 
						cr.[Name] as CustomerName, 
						(SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) JOIN DBO.BillingInvoicing wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) AS QtyBilled,
						'1' as ItemNo,
						wop.WorkOrderId, 
						wop.Id as WorkOrderPartId, 
						cond.Memo as 'Condition',
						cond.ConditionId,
						curr.Code as 'CurrencyCode',
						(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobii.GrandTotal end) as TotalSales,
						wobi.InvoiceStatus ,
						(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
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
						,ISNULL(wobi.[IsQuickBookGeneratedInvoice], 0) AS [IsQuickBookGeneratedInvoice]
					FROM [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderShipping] wos WITH(NOLOCK) ON wosi.WorkOrderShippingId = wos.WorkOrderShippingId
					 LEFT JOIN [dbo].[WorkOrderWorkFlow] wof WITH(NOLOCK) ON wos.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @SubReferenceId
					 LEFT JOIN [dbo].[BillingInvoicingItems] wobii WITH(NOLOCK) ON wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
					 LEFT JOIN [dbo].[BillingInvoicing] wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobi.ReferenceId = wof.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 0 --AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
					 LEFT JOIN [dbo].[WorkOrderMPNCostDetails] wocd WITH(NOLOCK) ON wop.ID = wocd.WOPartNoId
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
					 LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
					 LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = wop.ItemMasterId
					 --LEFT JOIN [dbo].[ItemMaster] imv WITH(NOLOCK) ON imv.ItemMasterId = wobi.ItemMasterId
					 LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId
					 LEFT JOIN [dbo].[WorkOrderCustomsInfo] woc WITH(NOLOCK) ON woc.WorkOrderShippingId = wos.WorkOrderShippingId
					 LEFT JOIN [dbo].[Customer] cr WITH(NOLOCK) ON cr.CustomerId = wo.CustomerId
					 LEFT JOIN [dbo].[Condition] cond  WITH(NOLOCK) ON cond.ConditionId = wosc.ConditionId
					 LEFT JOIN [dbo].[Currency] curr WITH(NOLOCK) ON curr.CurrencyId = wobi.CurrencyId
					 LEFT JOIN [dbo].[InvoiceType] INV WITH(NOLOCK) ON INV.InvoiceTypeId = wobi.InvoiceTypeId
					WHERE wos.WorkOrderId = @ReferenceId AND wop.ID = @SubReferenceId 

					GROUP BY wosi.WorkOrderShippingId, wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
						wos.WOShippingNum, wos.AirwayBill, wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
						sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
						cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobii.GrandTotal 
						,wobii.BillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription,wop.IsFinishGood
						,wop.RevisedSerialNumber,wobi.Notes,cond.ConditionId,INV.[Description],wobi.[IsInvoicePosted]
						,wobi.[DepositAmount],wobi.[UsedDeposit],wobii.IsVersionIncrease,wobi.[IsQuickBookGeneratedInvoice]
					) a

					;WITH CTE_Temp AS
					(
						SELECT *,
							ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY BillingInvoicingId desc) AS RowNumber
						FROM #MyTempTable
					)
	
					INSERT INTO #InvoiceMainDetails([BillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [ReferenceNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [ReferenceId], [SubReferenceId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], [IsProformaInvoice], [ConditionId]
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem], [IsQuickBookGeneratedInvoice])
					SELECT [BillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [ReferenceNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], 0, ConditionId
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem], [IsQuickBookGeneratedInvoice] from CTE_Temp t1
					where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
							or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
							or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
							or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
							AND
							((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
					ORDER BY BillingInvoicingId desc	
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
								CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS BillingInvoicingId, 
								CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
								CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
								wos.WOShippingNum, 
								wos.AirwayBill As 'AWB',
								(SUM(wosi.QtyShipped)- (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0)) as QtyToBill, 
								wo.WorkOrderNum as ReferenceNumber, 
							    wop.RevisedPartNumber as 'PartNumber',
								wop.RevisedPartDescription as 'PartDescription',
								sl.StockLineNumber,
								wop.RevisedSerialNumber AS 'SerialNumber',
								cr.[Name] as CustomerName, 
								(SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) JOIN DBO.BillingInvoicing wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) AS QtyBilled,
								'1' as ItemNo,
								wop.WorkOrderId, 
								wop.Id as WorkOrderPartId, 
								cond.Memo as 'Condition',
								cond.ConditionId,
								curr.Code as 'CurrencyCode',
								(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobii.GrandTotal end) as TotalSales,
								wobi.InvoiceStatus ,
								(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
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
								,ISNULL(wobi.[IsQuickBookGeneratedInvoice], 0) AS [IsQuickBookGeneratedInvoice]
							FROM [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK)
							INNER JOIN [dbo].[WorkOrderShipping] wos WITH(NOLOCK) ON wosi.WorkOrderShippingId = wos.WorkOrderShippingId								
							 LEFT JOIN [dbo].[WorkOrderWorkFlow] wof WITH(NOLOCK) ON wos.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @SubReferenceId
							 LEFT JOIN [dbo].[BillingInvoicingItems] wobii WITH(NOLOCK) ON wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
							 LEFT JOIN [dbo].[BillingInvoicing] wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobi.ReferenceId = wof.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 0 --AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
							INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
							 LEFT JOIN [dbo].[WorkOrderMPNCostDetails] wocd WITH(NOLOCK) ON wop.ID = wocd.WOPartNoId
							INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
							INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
							 LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
							 LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = wop.ItemMasterId
							--LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) ON imv.ItemMasterId = wobi.ItemMasterId
							 LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId
							 LEFT JOIN [dbo].[WorkOrderCustomsInfo] woc WITH(NOLOCK) ON woc.WorkOrderShippingId = wos.WorkOrderShippingId
							 LEFT JOIN [dbo].[Customer] cr WITH(NOLOCK) ON cr.CustomerId = wo.CustomerId
							 LEFT JOIN [dbo].[Condition] cond  WITH(NOLOCK) ON cond.ConditionId = wosc.ConditionId
							 LEFT JOIN [dbo].[Currency] curr WITH(NOLOCK) ON curr.CurrencyId = wobi.CurrencyId
							 LEFT JOIN [dbo].[InvoiceType] INV WITH(NOLOCK) ON INV.InvoiceTypeId = wobi.InvoiceTypeId
							WHERE wos.WorkOrderId = @ReferenceId AND wop.ID = @SubReferenceId 
							GROUP BY wosi.WorkOrderShippingId, wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
								wos.WOShippingNum, wos.AirwayBill, wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
								sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
								cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobii.GrandTotal 
								,wobii.BillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription,wop.IsFinishGood
								,wop.RevisedSerialNumber,wobi.Notes,cond.ConditionId,INV.[Description],wobi.[IsInvoicePosted]
								,wobi.[DepositAmount],wobi.[UsedDeposit],wobii.IsVersionIncrease,wobi.[IsQuickBookGeneratedInvoice]
							) a

							;WITH CTE_Temp AS
							(
								SELECT *,
									ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY BillingInvoicingId DESC) AS RowNumber
								FROM #MyTempTable1
							)
	
							INSERT INTO #InvoiceMainDetails([BillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [ReferenceNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [ReferenceId], [SubReferenceId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], [IsProformaInvoice], [ConditionId]
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem], [IsQuickBookGeneratedInvoice])
							SELECT [BillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [ReferenceNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], 0, ConditionId
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem], [IsQuickBookGeneratedInvoice] from CTE_Temp t1
							WHERE (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
									or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
									or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
									or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable1 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
									AND
									((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
							ORDER BY BillingInvoicingId DESC	
							DROP TABLE  #MyTempTable1 
					END
					ELSE
					BEGIN
						PRINT 'ELSE'
						SELECT * INTO #MyTempTable2 from 
						(SELECT DISTINCT 							
							CASE WHEN wosi.WorkOrderShippingId IS NOT NULL THEN wosi.WorkOrderShippingId ELSE wop.ID END AS WorkOrderShippingId, 
							CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS BillingInvoicingId, 
							CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
							CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
							wos.WOShippingNum, 
						    wos.AirwayBill As 'AWB',	
							(SUM(wop.Quantity)- (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0)) as QtyToBill, 
							wo.WorkOrderNum as ReferenceNumber, 
							wop.RevisedPartNumber as 'PartNumber',
							wop.RevisedPartDescription as 'PartDescription',
							sl.StockLineNumber,
							wop.RevisedSerialNumber AS 'SerialNumber', 
							cr.[Name] as CustomerName, 
							(SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) JOIN DBO.BillingInvoicing wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) AS QtyBilled,
							'1' as ItemNo,
							wop.WorkOrderId, 
							wop.Id as WorkOrderPartId, 
							cond.Memo as 'Condition',
							cond.ConditionId ,
							curr.Code as 'CurrencyCode',
							(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then wocd.TotalCost else wobii.GrandTotal end) as TotalSales,
							wobi.InvoiceStatus ,
							(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
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
							,ISNULL(wobi.[IsQuickBookGeneratedInvoice], 0) AS [IsQuickBookGeneratedInvoice]
						FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)							
						 LEFT JOIN [dbo].[WorkOrderWorkFlow] wof WITH(NOLOCK) ON wop.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @SubReferenceId
						 LEFT JOIN [dbo].[BillingInvoicingItems] wobii WITH(NOLOCK) ON wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 0
						 LEFT JOIN [dbo].[BillingInvoicing] wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobi.ReferenceId = wof.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 0 --AND wof.WorkFlowWorkOrderId = wobi.WorkFlowWorkOrderId
						 LEFT JOIN [dbo].[WorkOrderMPNCostDetails] wocd WITH(NOLOCK) ON wop.ID = wocd.WOPartNoId
						INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
						 LEFT JOIN [dbo].[WorkOrderSettlementDetails] wosc WITH(NOLOCK) ON wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
						 LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = wop.ItemMasterId
						--LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) ON imv.ItemMasterId = wobi.ItemMasterId
						 LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId
						 LEFT JOIN [dbo].[Customer] cr WITH(NOLOCK) ON cr.CustomerId = wo.CustomerId
						 LEFT JOIN [dbo].[Condition] cond  WITH(NOLOCK) ON cond.ConditionId = wosc.ConditionId
						 LEFT JOIN [dbo].[Currency] curr WITH(NOLOCK) ON curr.CurrencyId = wobi.CurrencyId
						 LEFT JOIN [dbo].[WorkOrderShipping] wos WITH(NOLOCK) ON wop.WorkOrderId = wos.WorkOrderId
						 LEFT JOIN [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK) ON wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
						 LEFT JOIN [dbo].[InvoiceType] INV WITH(NOLOCK) ON INV.InvoiceTypeId = wobi.InvoiceTypeId
						WHERE wop.WorkOrderId = @ReferenceId AND wop.ID = @SubReferenceId 						
						  AND (ISNULL(wop.IsFinishGood, 0) = 1 OR wobi.BillingInvoicingId IS NOT NULL)
						GROUP BY wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo,  wos.WOShippingNum, wos.AirwayBill,
							wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
							sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
							cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost,wobii.GrandTotal 
							, wobii.BillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription, wosi.WorkOrderShippingId,wop.IsFinishGood
							,wop.RevisedSerialNumber,wobi.Notes,cond.ConditionId,INV.[Description],wobi.[IsInvoicePosted]
							,wobi.[DepositAmount],wobi.[UsedDeposit],wobii.IsVersionIncrease,wobi.[IsQuickBookGeneratedInvoice]
						) a

						;WITH CTE_Temp AS
						(
							SELECT *,
								ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY BillingInvoicingId DESC) AS RowNumber
							FROM #MyTempTable2
						)
	
						INSERT INTO #InvoiceMainDetails([BillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [ReferenceNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [ReferenceId], [SubReferenceId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], [IsProformaInvoice], [ConditionId]
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem], [IsQuickBookGeneratedInvoice])
						select [BillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [ReferenceNumber], [PartNumber], [PartDescription],
													[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
													[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], 0, ConditionId
													,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem], [IsQuickBookGeneratedInvoice] from CTE_Temp t1
						where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
								or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
								or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
								or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable2 t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
								AND
								((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
						ORDER BY BillingInvoicingId desc	
						drop table  #MyTempTable2 
					END
				END
				
				IF(@IncludeProformaInvoice = 1)
				BEGIN
					SELECT * INTO #MyTempTable3 FROM 
					(SELECT DISTINCT 
						CASE WHEN wos.WorkOrderShippingId IS NOT NULL THEN wos.WorkOrderShippingId 
							 ELSE CASE WHEN ISNULL(woProfomaBillData.WorkOrderShippingId, 0) > 0 THEN woProfomaBillData.WorkOrderShippingId
							 ELSE 0  END END AS WorkOrderShippingId, 
						CASE WHEN wop.ID IS NOT NULL AND  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK)  WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS BillingInvoicingId, 
						CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
						CASE WHEN wop.ID IS NOT NULL AND  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
						CASE WHEN ISNULL(wos.WOShippingNum, '') = ''  THEN '' ELSE wos.WOShippingNum END AS WOShippingNum, 
						CASE WHEN ISNULL(wos.AirwayBill, '') = '' THEN '' ELSE wos.AirwayBill END As 'AWB',
						CASE WHEN ISNULL(wos.WorkOrderShippingId, 0) != 0 
							 THEN (SUM(wosi.QtyShipped)- (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1))
							 ELSE (SUM(wop.Quantity)- (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1)) END AS QtyToBill, 
						wo.WorkOrderNum AS ReferenceNumber, 
						wop.RevisedPartNumber AS 'PartNumber',
						wop.RevisedPartDescription AS 'PartDescription',
						sl.StockLineNumber,
						wop.RevisedSerialNumber AS 'SerialNumber', 
						cr.[Name] AS CustomerName, 
						(SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) AS QtyBilled,
						'1' AS ItemNo,
						wop.WorkOrderId, 
						wop.Id AS WorkOrderPartId, 
						CASE WHEN ISNULL(billcond.Memo, '') != '' THEN billcond.Memo 
							 WHEN ISNULL(billcond.Code, '') != '' THEN billcond.Code ELSE cond.Memo END AS 'Condition',
						CASE WHEN ISNULL(billcond.ConditionId, 0) = 0 THEN cond.ConditionId ELSE billcond.ConditionId END AS 'ConditionId',
						curr.Code AS 'CurrencyCode',
						(CASE WHEN (CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) IS NULL THEN 0 ELSE wobii.SubTotal END) AS TotalSales,
						wobi.InvoiceStatus ,
						(CASE WHEN (CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(1) FROM DBO.BillingInvoicingItems wobii WITH(NOLOCK) WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) IS NULL THEN NULL ELSE wobi.VersionNo END) AS VersionNo ,
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
						,ISNULL(wobi.[IsQuickBookGeneratedInvoice], 0) AS [IsQuickBookGeneratedInvoice]
					FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)							
					 LEFT JOIN [dbo].[WorkOrderWorkFlow] wof WITH(NOLOCK) ON wop.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @SubReferenceId
					 LEFT JOIN [dbo].[BillingInvoicingItems] wobii WITH(NOLOCK) ON wobii.SubReferenceId = @SubReferenceId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1
					 LEFT JOIN [dbo].[BillingInvoicing] wobi WITH(NOLOCK) ON wobi.BillingInvoicingId = wobii.BillingInvoicingId AND wobi.ReferenceId = wof.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 1 
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
					 LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = wop.ItemMasterId
					--LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) ON imv.ItemMasterId = wobi.ItemMasterId
					 LEFT JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.StockLineId = wop.StockLineId
					 LEFT JOIN [dbo].[Customer] cr WITH(NOLOCK) ON cr.CustomerId = wo.CustomerId
					 LEFT JOIN [dbo].[Condition] cond  WITH(NOLOCK) ON cond.ConditionId = wobii.ConditionId
					 LEFT JOIN [dbo].[Currency] curr WITH(NOLOCK) ON curr.CurrencyId = wobi.CurrencyId
					 LEFT JOIN [dbo].[WorkOrderShipping] wos WITH(NOLOCK) ON wos.WorkOrderId = wop.WorkOrderId AND wobi.WorkOrderShippingId = wos.WorkOrderShippingId
					 LEFT JOIN [dbo].[WorkOrderShippingItem] wosi WITH(NOLOCK) ON wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
					 LEFT JOIN [dbo].[InvoiceType] INV WITH(NOLOCK) ON INV.InvoiceTypeId = wobi.InvoiceTypeId
					 LEFT JOIN [dbo].[Condition] billcond  WITH(NOLOCK) ON billcond.ConditionId = wobii.ConditionId
						OUTER APPLY
							(SELECT NWOP.WorkOrderId, NWOP.Id,NWOBI.InvoiceStatus FROM DBO.WorkOrderPartNumber NWOP WITH(NOLOCK)							
							LEFT JOIN dbo.WorkOrderWorkFlow NWOF WITH(NOLOCK) ON NWOP.WorkOrderId = NWOF.WorkOrderId AND NWOF.WorkOrderPartNoId = @SubReferenceId
							LEFT JOIN DBO.BillingInvoicingItems NWOBII WITH(NOLOCK) ON Nwobii.SubReferenceId = @SubReferenceId AND ISNULL(NWOBII.IsPerformaInvoice, 0) = 0
							LEFT JOIN DBO.BillingInvoicing NWOBI WITH(NOLOCK) ON NWOBI.BillingInvoicingId = NWOBII.BillingInvoicingId AND NWOBI.ReferenceId = NWOF.WorkOrderId AND ISNULL(NWOBI.IsPerformaInvoice, 0) = 0
							WHERE NWOP.WorkOrderId = @ReferenceId AND NWOP.ID = @SubReferenceId AND (ISNULL(NWOP.IsFinishGood, 0) = 1) AND ISNULL(NWOBII.IsVersionIncrease, 0) = 0 GROUP BY NWOP.WorkOrderId, NWOP.Id,NWOBI.InvoiceStatus) woBillData
						OUTER APPLY
							(SELECT PWOP.WorkOrderId, PWOP.Id,PWOSSN.WorkOrderShippingId  FROM DBO.WorkOrderPartNumber PWOP WITH(NOLOCK)							
							LEFT JOIN dbo.WorkOrderWorkFlow PWOF WITH(NOLOCK) ON PWOP.WorkOrderId = PWOF.WorkOrderId AND PWOF.WorkOrderPartNoId = @SubReferenceId
							LEFT JOIN DBO.BillingInvoicingItems PWOBII WITH(NOLOCK) ON Pwobii.SubReferenceId = @SubReferenceId AND ISNULL(PWOBII.IsPerformaInvoice, 0) = 1
							LEFT JOIN DBO.BillingInvoicing PWOBI WITH(NOLOCK) ON PWOBI.BillingInvoicingId = PWOBII.BillingInvoicingId AND PWOBI.ReferenceId = PWOF.WorkOrderId AND ISNULL(PWOBI.IsPerformaInvoice, 0) = 1
						    LEFT JOIN DBO.WorkOrderShippingItem PWOSISN WITH(NOLOCK) ON PWOSISN.WorkOrderPartNumId = PWOP.ID AND PWOSISN.WorkOrderPartNumId = @SubReferenceId
							LEFT JOIN DBO.WorkOrderShipping PWOSSN WITH(NOLOCK) ON PWOSISN.WorkOrderShippingId = PWOSSN.WorkOrderShippingId
							WHERE PWOP.WorkOrderId = @ReferenceId AND PWOP.ID = @SubReferenceId AND (ISNULL(PWOP.IsFinishGood, 0) = 1) AND ISNULL(PWOBII.IsVersionIncrease, 0) = 0 GROUP BY PWOP.WorkOrderId, PWOP.Id,PWOSSN.WorkOrderShippingId) woProfomaBillData
					WHERE wop.WorkOrderId = @ReferenceId AND wop.ID = @SubReferenceId 
					GROUP BY wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
						wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
						sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
						cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wobii.SubTotal 
						,wobii.BillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription, wos.WorkOrderShippingId,wop.IsFinishGood
						,wop.RevisedSerialNumber,wobi.Notes,wos.WOShippingNum,wos.AirwayBill,wos.WorkOrderShippingId
						,INV.[Description],cond.ConditionId,wobi.[IsInvoicePosted],billcond.Memo,billcond.Code,billcond.ConditionId,woBillData.InvoiceStatus
						,woProfomaBillData.WorkOrderShippingId,wobi.[DepositAmount],wobi.[UsedDeposit],wobii.IsVersionIncrease,wobi.[IsQuickBookGeneratedInvoice]
					) a

					;WITH CTE_Temp AS
					(
						SELECT *,
							ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY BillingInvoicingId DESC) AS RowNumber
						FROM #MyTempTable3
					)
					INSERT INTO #InvoiceMainDetails([BillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [ReferenceNumber], [PartNumber], [PartDescription],
														[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [ReferenceId], [SubReferenceId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
														[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], [IsProformaInvoice], [ConditionId]
														,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem], [IsQuickBookGeneratedInvoice])
					SELECT [BillingInvoicingId], [WorkOrderShippingId], [InvoiceDate], [InvoiceNo], [WOShippingNum], [QtyToBill], [ReferenceNumber], [PartNumber], [PartDescription],
														[StockLineNumber], [SerialNumber], [QtyBilled], [ItemNo], [WorkOrderId], [WorkOrderPartId], [Condition], [CurrencyCode], [TotalSales], [InvoiceStatus],
														[VersionNo], [ItemMasterId], [IsAllowIncreaseVersion], [WorkFlowWorkOrderId], [AWB], [IsFinishGood], [Notes], [InvoiceTypeName], 1, ConditionId
														,[IsInvoicePosted], [DepositAmount], [UsedDeposit], [IsAllowIncreaseVersionForBillItem], [IsQuickBookGeneratedInvoice] from CTE_Temp t1
					WHERE (((VersionNo IS NULL AND IsAllowIncreaseVersion =1) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable3 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0) AND RowNumber =1)
							OR ((VersionNo IS NOT NULL AND IsAllowIncreaseVersion =1) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable3 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
							OR((VersionNo IS NULL AND IsAllowIncreaseVersion =0) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable3 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0) AND RowNumber =1)
							OR ((VersionNo IS NOT NULL AND IsAllowIncreaseVersion =0) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable3 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
							AND
							((VersionNo IS NULL AND InvoiceStatus IS NULL) OR  (VersionNo IS NOT NULL AND InvoiceStatus IS NOT NULL) OR (InvoiceStatus IS NOT NULL AND IsAllowIncreaseVersion = 1))
					ORDER BY BillingInvoicingId DESC	
					drop table  #MyTempTable3 
				END										
			END
			ELSE IF(@ModuleId = @SOModuleId) /*********START: SALES ORDER ********/
			BEGIN
			    SELECT @AllowBillingBeforeShipping = AllowInvoiceBeforeShipping FROM DBO.SalesOrder SO (NOLOCK) WHERE SO.SalesOrderId = @ReferenceId;
				IF (ISNULL(@AllowBillingBeforeShipping, 0) = 0)
				BEGIN 
				;WITH CTE (IndexColumn,
				SalesOrderShippingId,SalesOrderShippingItemId,BillingInvoicingId ,InvoiceDate , InvoiceNo , InvoiceTypeId ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId,PartDescription ,
				StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
				TotalSales , TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProformaInvoice,DepositAmount,IsAllowIncreaseVersionForBillItem,IsBilling,
				ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight) AS
				(
				SELECT DISTINCT 
				0 AS IndexColumn,
				sosi.SalesOrderShippingId,   
				sosi.SalesOrderShippingItemId,   
				CASE WHEN sop.SalesOrderPartId IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems sobii_1 WITH(NOLOCK) 
				WHERE sobii_1.BillingInvoicingId = sobi.BillingInvoicingId and sobii_1.ItemMasterId = sop.ItemMasterId
				AND ISNULL(sobii_1.IsPerformaInvoice, 0) = 0) > 0 THEN sobii.BillingInvoicingId  
				ELSE NULL END AS BillingInvoicingId,

				(SELECT TOP 1 case when CAST(a.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(a.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end FROM dbo.BillingInvoicing a WITH (NOLOCK)
					INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
					Where a.ReferenceId = @ReferenceId AND b.ItemMasterId = sop.ItemMasterId 
					AND stk.StockLineId = b.StockLineId AND ShippingId = sosi.SalesOrderShippingId
					AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0) AS InvoiceDate,
				CASE WHEN sop.SalesOrderPartId IS NOT NULL and  (SELECT COUNT(1) FROM DBO.BillingInvoicingItems sobii_1 WITH(NOLOCK) 
				WHERE sobii_1.BillingInvoicingId = sobi.BillingInvoicingId and sobii_1.ItemMasterId = sop.ItemMasterId 
				AND ISNULL(sobii_1.IsPerformaInvoice, 0) = 0) >0  THEN sobi.InvoiceNo ELSE NULL END AS InvoiceNo,
				sobi.InvoiceTypeId,
				sos.SOShippingNum, 
				sosi.QtyShipped as QtyToBill,   
				so.SalesOrderNumber, 
				imt.partnumber, 
				imt.ItemMasterId,
				sop.ConditionId,
				imt.PartDescription, 
				sl.StockLineNumber,  
				sl.SerialNumber, 
				cr.[Name] as CustomerName,   
				stk.StockLineId,  
				(SELECT TOP 1 b.QtyBilled FROM dbo.BillingInvoicing a WITH (NOLOCK) 
					INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
					WHERE a.ReferenceId = @ReferenceId AND b.ItemMasterId = sop.ItemMasterId 
					AND stk.StockLineId = b.StockLineId AND b.ShippingId = sosi.SalesOrderShippingId
					AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0) AS QtyBilled,  
				--sobii.QtyBilled,
				0 AS ItemNo,  
				sop.SalesOrderId, 
				sop.SalesOrderPartId, 
				stk.SalesOrderStocklineId,
				cond.Description as 'Condition',   
				CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
				CASE WHEN ISNULL(sobii.BillingInvoicingId, 0) > 0 THEN ISNULL(sobi.GrandTotal, 0) ELSE 
				((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 1)) * sosi.QtyShipped)
				END 
				as 'TotalSales',  
			
				((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 1)) * ISNULL(sosi.QtyShipped, 0)) AS TotalUnitCost,
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) 
				 WHERE sof.SalesOrderId = @ReferenceId 			  
					AND sof.ItemMasterId = sop.ItemMasterId 
					AND sof.ConditionId = @ConditionId 
					AND sof.IsActive = 1 
					AND sof.IsDeleted = 0)  AS TotalFreight,

				(SELECT MAX(ISNULL(SO.TotalFreight,0)) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
					WHERE [SO].[SalesOrderId] = @ReferenceId AND so.FreightBilingMethodId = @FlateBilingMethodId)
				 AS  TotalFlatFreight,
				(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) 
				WHERE socg.SalesOrderId = @ReferenceId 				
					AND socg.ItemMasterId = sop.ItemMasterId 
					AND socg.ConditionId = @ConditionId 
					AND socg.IsActive = 1 
					AND socg.IsDeleted = 0) 
				AS TotalCharges,
				(SELECT TOP 1 ISNULL(SO.TotalCharges,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
				WHERE [SO].[SalesOrderId] = @ReferenceId AND so.ChargesBilingMethodId = @FlateBilingMethodId)
				AS TotalFlatCharges,
				(SELECT TOP 1 a.InvoiceStatus FROM dbo.BillingInvoicing a WITH (NOLOCK) 
					INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
					Where a.ReferenceId = @ReferenceId AND sobii.BillingInvoicingId = a.BillingInvoicingId AND b.ItemMasterId = sop.ItemMasterId 
					AND stk.StockLineId = b.StockLineId AND ShippingId = sosi.SalesOrderShippingId
					AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0 ORDER BY a.InvoiceDate DESC) AS InvoiceStatus,
				--sobi.InvoiceStatus,
				sos.SmentNum AS 'SmentNo',
				sobii.VersionNo,
				(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
				CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
				0 AS IsProformaInvoice,
				0 AS DepositAmount,
				(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
				ISNULL(sobi.[IsInvoicePosted], 0) as [IsBilling],

				sop.ECCN AS ECCN,
				sop.HSCODE AS HSCODE,
				sop.[Weight] AS [Weight], 
				sop.SizeLength AS BillSizeLength,
				sop.SizeWidth AS BillSizeWidth,
				sop.SizeHeight AS BillSizeHeight

				FROM DBO.SalesOrderShipping sos WITH (NOLOCK)
				INNER JOIN DBO.SalesOrderPartV1 sop WITH (NOLOCK) on sop.SalesOrderId = sos.SalesOrderId --AND sop.SalesOrderPartId = sosi.SalesOrderPartId  
				INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) on SOPC.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.SalesOrderStocklineCost sosc WITH (NOLOCK) ON sosc.SalesOrderStocklineId = stk.SalesOrderStocklineId
				INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) on SOPT.SalesOrderId = sos.SalesOrderId AND SOPT.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
				INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) on sosi.SalesOrderShippingId = sos.SalesOrderShippingId  AND sosi.SOPickTicketId = SOPT.SOPickTicketId
				LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.ItemMasterId = sop.ItemMasterId AND ISNULL(sobii.IsPerformaInvoice,0) = 0
				LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice,0) = 0
				INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
				LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
				LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId  
				LEFT JOIN DBO.SalesOrderCustomsInfo soc WITH (NOLOCK) on soc.SalesOrderShippingId = sos.SalesOrderShippingId  
				LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
				LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.FunctionalCurrencyId 
				LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
				WHERE sos.SalesOrderId = @ReferenceId AND sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = @ConditionId  
				GROUP BY sosi.SalesOrderShippingId, sosi.SalesOrderShippingItemId, sos.SOShippingNum, so.SalesOrderNumber, imt.ItemMasterId, imt.partnumber,imt.ItemMasterId,sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
				sl.SerialNumber, cr.[Name], sop.SalesOrderId, sop.SalesOrderPartId, stk.SalesOrderStocklineId, cond.Description, curr.Code, currb.Code, stk.StockLineId,  
				sobi.InvoiceStatus, sosi.QtyShipped, sop.ItemMasterId, sobi.InvoiceStatus,SOSC.NetSaleAmount, sobi.InvoiceNo, sobi.InvoiceTypeId,
				SOPC.TaxAmount, SOPC.TaxPercentage, sos.SmentNum, sobii.VersionNo,sobi.IsVersionIncrease,sobii.IsVersionIncrease, sobi.BillingInvoicingId, sobii.BillingInvoicingId,sobi.GrandTotal,sobi.[IsInvoicePosted],
				sop.ECCN ,sop.HSCODE ,sop.[Weight] ,sop.SizeLength ,sop.SizeWidth ,sop.SizeHeight, stk.QtyOrder)

				INSERT INTO #InvoiceMainDetails (IndexColumn,
				SalesOrderShippingId,SalesOrderShippingItemId,BillingInvoicingId ,InvoiceDate , InvoiceNo , InvoiceTypeId ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId,PartDescription ,
				StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
				TotalSales , TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProformaInvoice,DepositAmount,IsAllowIncreaseVersionForBillItem,IsBilling,
				ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
				SELECT IndexColumn,
				SalesOrderShippingId,SalesOrderShippingItemId,BillingInvoicingId ,InvoiceDate , InvoiceNo , InvoiceTypeId ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId,PartDescription ,
				StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
				TotalSales , TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProformaInvoice,DepositAmount,IsAllowIncreaseVersionForBillItem,IsBilling,
				ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight FROM CTE;
			END
			ELSE
			BEGIN
				IF EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
					INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) on SOP.SalesOrderId = SOS.SalesOrderId AND SOP.SalesOrderPartId = SOSI.SalesOrderPartId
					WHERE SOS.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId)
				BEGIN  
					IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.BillingInvoicing SOBI WITH (NOLOCK) INNER JOIN DBO.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId
					INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) on SOP.SalesOrderId = SOBI.ReferenceId AND SOP.SalesOrderPartId = SOBII.SubReferenceId
					WHERE SOBI.ReferenceId = @ReferenceId AND ISNULL(SOBI.IsPerformaInvoice, 0) = 0 AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId)
					BEGIN
						INSERT INTO #InvoiceMainDetails(IndexColumn,
						SalesOrderShippingId,SalesOrderShippingItemId,BillingInvoicingId ,InvoiceDate , InvoiceNo ,InvoiceTypeId,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber ,ItemMasterId,ConditionId ,PartDescription ,
						StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
						TotalSales, TotalUnitCost, TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges, InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProformaInvoice, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
						ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
						(
						SELECT DISTINCT 
						--ROW_NUMBER() OVER (ORDER BY sop.SalesOrderPartId, sobi.BillingInvoicingId DESC) AS IndexColumn,
						0 AS IndexColumn,
						(CASE WHEN sobii.IsVersionIncrease = 1 then sobii.ShippingId 
						else (SELECT TOP 1 SOS.SalesOrderShippingId FROM DBO.SalesOrderShipping SOS 
						WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
						INNER JOIN DBO.SOPickTicket SO_PICK WITH (NOLOCK) on SO_PICK.SOPickTicketId = SOSI.SOPickTicketId
						WHERE SOS.SalesOrderId = @ReferenceId AND SO_PICK.SOPickTicketId = SOPPick.SOPickTicketId) end) AS SalesOrderShippingId,  
						SOSI.SalesOrderShippingItemId,
						sobi.BillingInvoicingId,
						case when CAST(sobi.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end InvoiceDate,
						sobi.InvoiceNo AS InvoiceNo,
						sobi.InvoiceTypeId,
						(CASE WHEN sobii.IsVersionIncrease = 1 then 
							(SELECT TOP 1 SOS.SOShippingNum FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) WHERE SOS.SalesOrderShippingId = sobii.ShippingId) 
						else 
							(SELECT top 1 SOS.SOShippingNum 
							FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
							INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
							INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) on SOPICK.SOPickTicketId = SOSI.SOPickTicketId
							INNER JOIN DBO.SalesOrderStocklineV1 SOSB WITH (NOLOCK) on SOSB.SalesOrderStocklineId = SOPICK.SalesOrderPartStocklineId
							WHERE SOS.SalesOrderId = @ReferenceId AND SOSB.SalesOrderStocklineId = STK.SalesOrderStocklineId
							AND SOSI.SOPickTicketId = SOPPick.SOPickTicketId) end)
						AS SOShippingNum, 
				
						CASE WHEN sobii.IsVersionIncrease = 1 THEN 0 ELSE (SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
						FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
						INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
						INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) ON SOPT.SOPickTicketId = SOSI.SOPickTicketId
						INNER JOIN DBO.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderStocklineId = SOPT.SalesOrderPartStocklineId
						WHERE SOS.SalesOrderId = @ReferenceId AND stk.SalesOrderStocklineId = SOPS.SalesOrderStocklineId
						AND SOSI.SOPickTicketId = SOPPick.SOPickTicketId) end  as QtyToBill,
				
						so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
						sl.SerialNumber, cr.[Name] as CustomerName,   
						stk.StockLineId,  
						ISNULL((SELECT ISNULL(b.QtyBilled, 0) FROM dbo.BillingInvoicing a WITH (NOLOCK) 
							INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
							WHERE b.BillingInvoicingItemId = SOBII.BillingInvoicingItemId AND b.StockLineId = SOBII.StockLineId
							AND a.ReferenceId = @ReferenceId
							AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0), 0) AS QtyBilled,
						0 AS ItemNo, 
						sop.SalesOrderId, sop.SalesOrderPartId, stk.SalesOrderStocklineId, cond.Description as 'Condition',   
						CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
						CASE WHEN ISNULL(sobi.BillingInvoicingId, 0) = 0 THEN ((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 0)) * ((SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
						FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
						INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
						INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) ON SOPT.SOPickTicketId = SOSI.SOPickTicketId
						INNER JOIN DBO.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderStocklineId = SOPT.SalesOrderPartStocklineId
						WHERE SOS.SalesOrderId = @ReferenceId AND stk.SalesOrderStocklineId = SOPS.SalesOrderStocklineId
						AND SOSI.SOPickTicketId = SOPPick.SOPickTicketId)))
						ELSE sobii.GrandTotal END as 'TotalSales',  

						((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 0)) * 
						(ISNULL((SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
						FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
						INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
						INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) ON SOPT.SOPickTicketId = SOSI.SOPickTicketId
						INNER JOIN DBO.SalesOrderPartV1 SOPI WITH (NOLOCK) on SOPI.SalesOrderId = SOS.SalesOrderId AND SOPI.SalesOrderPartId = SOSI.SalesOrderPartId
						WHERE SOS.SalesOrderId = @ReferenceId AND SOPT.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
						), 0) 
						)) AS TotalUnitCost,
			
						(SELECT TOP 1 ISNULL((BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) 
						 WHERE sof.SalesOrderId = @ReferenceId 					
							AND sof.ItemMasterId = sop.ItemMasterId 
							AND sof.ConditionId = @ConditionId 
							AND sof.IsActive = 1 
							AND sof.IsDeleted = 0)  AS TotalFreight,

						(SELECT TOP 1 ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
							WHERE [SO].[SalesOrderId] = @ReferenceId AND so.FreightBilingMethodId = @FlateBilingMethodId)
						 AS  TotalFlatFreight,

						(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) 
						WHERE socg.SalesOrderId = @ReferenceId 					
							AND socg.ItemMasterId = sop.ItemMasterId 
							AND socg.ConditionId = @ConditionId 
							AND socg.IsActive = 1 
							AND socg.IsDeleted = 0) 
						AS TotalCharges,
			
						(SELECT ISNULL(SO.TotalCharges,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
						WHERE [SO].[SalesOrderId] = @ReferenceId AND so.ChargesBilingMethodId = @FlateBilingMethodId)
						AS TotalFlatCharges,

						(SELECT a.InvoiceStatus FROM dbo.BillingInvoicing a WITH (NOLOCK) 
							INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
							Where a.ReferenceId = @ReferenceId AND b.BillingInvoicingItemId = sobii.BillingInvoicingItemId
							AND ISNULL(a.IsPerformaInvoice,0) = 0 AND ISNULL(b.IsPerformaInvoice,0) = 0) AS InvoiceStatus,
						(CASE WHEN sobii.IsVersionIncrease = 1 then (CASE WHEN SOBII.ShippingId > 0 THEN 1 ELSE 0 END) else 1 end) AS 'SmentNo',
						sobii.VersionNo, 
						(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
						CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
						0 AS IsProformaInvoice,
						0 AS DepositAmount,
						(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
						ISNULL(sobi.[IsInvoicePosted], 0) as [IsBilling],

						stk.ECCN AS ECCN,
						stk.HSCODE AS HSCODE,
						stk.[Weight] AS [Weight], 
						stk.SizeLength AS BillSizeLength,
						stk.SizeWidth AS BillSizeWidth,
						stk.SizeHeight AS BillSizeHeight

						FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId AND sop.SalesOrderId = @ReferenceId
						LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
						LEFT JOIN DBO.SOPickTicket SOPPick WITH (NOLOCK) on SOPPick.SalesOrderId = sop.SalesOrderId AND SOPPick.SalesOrderPartId = sop.SalesOrderPartId AND SOPPick.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
						LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) on SOSI.SOPickTicketId = SOPPick.SOPickTicketId
						LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.ShippingId = SOSI.SalesOrderShippingId AND sobii.StockLineId = stk.StockLineId AND ISNULL(sobii.IsPerformaInvoice,0) = 0 
						LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.BillingInvoicingId = sobii.BillingInvoicingId  AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ReferenceId = @ReferenceId
						INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId  
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
						LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId  
						LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
						LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
						LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = imt.PurchaseCurrencyId  
						LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
						LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId AND SOR.StockLineId = Stk.StockLineId AND SOR.SalesOrderId = @ReferenceId
						WHERE sop.SalesOrderId = @ReferenceId AND sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = @ConditionId
						AND (SOSI.SalesOrderShippingItemId IS NOT NULL))

						UNION ALL

						SELECT DISTINCT 
							0 AS IndexColumn,
							0 AS SalesOrderShippingId,   
							0 AS SalesOrderShippingItemId,   
							sobi.BillingInvoicingId,
							case when CAST(sobi.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end InvoiceDate,
							sobi.InvoiceNo AS InvoiceNo,
							sobi.InvoiceTypeId,
							'' AS SOShippingNum,
							ISNULL(SOR.QtyToReserve, 0) AS QtyToBill,
							so.SalesOrderNumber,
							imt.partnumber, 
							imt.ItemMasterId,
							sop.ConditionId, 
							imt.PartDescription, 
							sl.StockLineNumber,  
							sl.SerialNumber, 
							cr.[Name] as CustomerName,   
							stk.StockLineId,
							ISNULL(sobii.QtyBilled, 0) AS QtyBilled,
							0 AS ItemNo,  
							sop.SalesOrderId, 
							sop.SalesOrderPartId, 
							stk.SalesOrderStocklineId,
							cond.Description as 'Condition',   
							CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
							((ISNULL(SOSC.NetSaleAmount, 0) / STK.QtyOrder) * SOR.QtyToReserve) AS 'TotalSales',
							((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 0)) * (ISNULL((SELECT SUM(ISNULL(SOSI.QtyShipped, 0)) 
							FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
							INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
							INNER JOIN DBO.SOPickTicket SOPT WITH (NOLOCK) ON SOPT.SOPickTicketId = SOSI.SOPickTicketId
							INNER JOIN DBO.SalesOrderPartV1 SOPI WITH (NOLOCK) on SOPI.SalesOrderId = SOS.SalesOrderId AND SOPI.SalesOrderPartId = SOSI.SalesOrderPartId
							WHERE SOS.SalesOrderId = @ReferenceId AND SOPT.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
							), 0) + ISNULL(SOR.QtyToReserve, 0))) AS TotalUnitCost,
							0 AS TotalFreight,
							0 AS TotalFlatFreight,
							0 AS TotalCharges,
							0 AS TotalFlatCharges,
							'' AS InvoiceStatus,
							0 AS 'SmentNo',
							sobii.VersionNo,
							(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
							CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
							0 AS IsProformaInvoice,
							0 AS DepositAmount,
							(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
							ISNULL(sobi.IsInvoicePosted, 0) as [IsBilling],
							stk.ECCN AS ECCN,
							stk.HSCODE AS HSCODE,
							stk.[Weight] AS [Weight], 
							stk.SizeLength AS BillSizeLength,
							stk.SizeWidth AS BillSizeWidth,
							stk.SizeHeight AS BillSizeHeight

						FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
							LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
							INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId 
							LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId AND SOR.StockLineId = Stk.StockLineId AND SOR.SalesOrderId = @ReferenceId
							LEFT JOIN DBO.SOPickTicket SOPPick WITH (NOLOCK) on SOPPick.SalesOrderId = sop.SalesOrderId AND SOPPick.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
							LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) on SOSI.SOPickTicketId = SOPPick.SOPickTicketId
							LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.StockLineId = stk.StockLineId AND ISNULL(sobii.IsPerformaInvoice,0) = 0
							LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ReferenceId = @ReferenceId
							LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
							LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId  
							LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
							LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
							LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.FunctionalCurrencyId  
							LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
							LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = @ReferenceId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
							INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = sop.SalesOrderPartId
							LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
						WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId and SOP.ConditionId = @ConditionId
						AND (SOSI.SalesOrderShippingItemId IS NULL AND ISNULL(SOR.QtyToReserve, 0) > 0)
					END
					ELSE
					BEGIN
						;WITH CTE AS (
							SELECT DISTINCT 
								0 AS IndexColumn,
								ISNULL(
									CASE 
										WHEN sobii.IsVersionIncrease = 1 THEN 
											(SELECT TOP 1 SOS.SalesOrderShippingId 
											 FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
											 INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
											 INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) ON SOPICK.SOPickTicketId = SOSI.SOPickTicketId
											 WHERE SOPICK.SOPickTicketId = SOPPick.SOPickTicketId)
										ELSE 
											(SELECT TOP 1 SOS.SalesOrderShippingId 
											 FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
											 INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
											 INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) ON SOPICK.SOPickTicketId = SOSI.SOPickTicketId
											 INNER JOIN DBO.SalesOrderStocklineV1 SOSB WITH (NOLOCK) ON SOSB.SalesOrderStocklineId = SOPICK.SalesOrderPartStocklineId
											 WHERE SOS.SalesOrderId = @ReferenceId 
											 AND SOPICK.SOPickTicketId = SOPPick.SOPickTicketId)
									END, 0) AS SalesOrderShippingId,
								0 AS SalesOrderShippingItemId,
								sobi.BillingInvoicingId,
								sobii.BillingInvoicingItemId,
								CASE 
									WHEN CAST(sobi.InvoiceDate AS DATE) = '0001-01-01 00:00:00' THEN NULL 
									ELSE CAST(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)
								END AS InvoiceDate,
								sobi.InvoiceNo,
								sobi.InvoiceTypeId,
								CASE WHEN sobii.IsVersionIncrease = 1 THEN 
									(SELECT TOP 1 SOS.SOShippingNum 
										FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
										INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
										INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) ON SOPICK.SOPickTicketId = SOSI.SOPickTicketId
										WHERE SOPICK.SOPickTicketId = SOPPick.SOPickTicketId)
									ELSE 
									(SELECT TOP 1 SOS.SOShippingNum 
										FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
										INNER JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
										INNER JOIN DBO.SOPickTicket SOPICK WITH (NOLOCK) ON SOPICK.SOPickTicketId = SOSI.SOPickTicketId
										INNER JOIN DBO.SalesOrderStocklineV1 SOSB WITH (NOLOCK) ON SOSB.SalesOrderStocklineId = SOPICK.SalesOrderPartStocklineId
										WHERE SOS.SalesOrderId = @ReferenceId 
										AND SOPICK.SOPickTicketId = SOPPick.SOPickTicketId)
									END
								AS SOShippingNum,
								so.SalesOrderNumber, 
								imt.partnumber, 
								imt.ItemMasterId,
								sop.ConditionId, 
								imt.PartDescription, 
								sl.StockLineNumber,  
								sl.SerialNumber, 
								cr.[Name] AS CustomerName,   
								ISNULL(stk.StockLineId, 0) AS StockLineId,
								0 AS ItemNo,  
								sop.SalesOrderId, 
								sop.SalesOrderPartId, 
								stk.SalesOrderStocklineId,
								cond.Description AS 'Condition',   
								ISNULL(currb.Code, curr.Code) AS 'CurrencyCode',
								(CASE WHEN SOBII.ShippingId > 0 THEN 1 ELSE 0 END) AS 'SmentNo',
								ISNULL(SOSC.NetSaleAmount, 0) AS TotalUnitCost,
								sobii.VersionNo,
								CASE WHEN ISNULL(sobi.IsVersionIncrease, 0) = 1 then 0 else 1 end AS IsVersionIncrease,
								CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
								0 AS IsProformaInvoice,
								0 AS DepositAmount,
								(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
								ISNULL(sobi.[IsInvoicePosted], 0) AS [IsBilling],
								stk.ECCN, 
								stk.HSCODE, 
								stk.[Weight], 
								stk.SizeLength,
								stk.SizeWidth,
								stk.SizeHeight
							FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
							LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
							LEFT JOIN DBO.SOPickTicket SOPPick WITH (NOLOCK) ON SOPPick.SalesOrderId = sop.SalesOrderId AND SOPPick.SalesOrderPartId = sop.SalesOrderPartId AND SOPPick.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
							INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId 
							LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) ON sobii.SubReferenceId = sop.SalesOrderPartId AND (sobii.StockLineId = stk.StockLineId OR sobii.StockLineId IS NULL)
							LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) ON sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice, 0) = 0 AND sobi.ReferenceId = @ReferenceId
							LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
							LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId  
							LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
							LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
							LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.FunctionalCurrencyId  
							LEFT JOIN DBO.Currency currb WITH (NOLOCK) ON currb.CurrencyId = sobi.CurrencyId
							INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = sop.SalesOrderPartId
							LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
							WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId
							AND (sobi.BillingInvoicingId IS NOT NULL OR ISNULL(stk.QtyReserved, 0) > 0)
						)

						INSERT INTO #InvoiceMainDetails (IndexColumn,
						SalesOrderShippingId,SalesOrderShippingItemId,BillingInvoicingId , BillingInvoicingItemId, InvoiceDate , InvoiceNo, InvoiceTypeId ,SOShippingNum ,	SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
						StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId , ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
						SmentNo, TotalUnitCost, VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProformaInvoice, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
						ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
						SELECT DISTINCT
						0 AS IndexColumn,
						SalesOrderShippingId,SalesOrderShippingItemId,BillingInvoicingId , BillingInvoicingItemId, InvoiceDate , InvoiceNo, InvoiceTypeId ,SOShippingNum ,	SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
						StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId , ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
						SmentNo, TotalUnitCost, VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProformaInvoice, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
						ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight FROM CTE;

						UPDATE  #InvoiceMainDetails SET QtyToBill = tmpcash.QtyToBill
							FROM (SELECT CASE WHEN SOSI.SalesOrderShippingId IS NOT NULL THEN ISNULL(SOSI.QtyShipped, 0) ELSE ISNULL(SOP.QtyReserved, 0) END  QtyToBill, b.BillingInvoicingItemId, b.StockLineId
								FROM dbo.BillingInvoicingItems b WITH (NOLOCK) 
										JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingId = b.BillingInvoicingId
										AND tmpSOBI.BillingInvoicingItemId = b.BillingInvoicingItemId
										LEFT JOIN DBO.SOPickTicket SOPick WITH (NOLOCK) ON SOPick.SalesOrderId = @ReferenceId AND tmpSOBI.SalesOrderStocklineId = SOPick.SalesOrderPartStocklineId
										LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOPick.SOPickTicketId = SOSI.SOPickTicketId AND b.ShippingId = SOSI.SalesOrderShippingId
										LEFT JOIN DBO.SalesOrderStocklineV1 SOP WITH (NOLOCK) ON b.StockLineId = SOP.StockLineId
							) tmpcash WHERE tmpcash.BillingInvoicingItemId = #InvoiceMainDetails.BillingInvoicingItemId
							AND tmpcash.StockLineId = #InvoiceMainDetails.StockLineId

						UPDATE  #InvoiceMainDetails SET QtyToBill = tmpcash.QtyToBill
							FROM (SELECT CASE WHEN SOSI.SalesOrderShippingId IS NOT NULL THEN ISNULL(SOSI.QtyShipped, 0) ELSE ISNULL(SOP.QtyReserved, 0) END QtyToBill, tmpSOBI.SalesOrderShippingId, tmpSOBI.StockLineId
								FROM #InvoiceMainDetails tmpSOBI 
										LEFT JOIN DBO.SOPickTicket SOPick WITH (NOLOCK) ON SOPick.SalesOrderId = @ReferenceId AND tmpSOBI.SalesOrderStocklineId = SOPick.SalesOrderPartStocklineId
										LEFT JOIN DBO.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOPick.SOPickTicketId = SOSI.SOPickTicketId AND tmpSOBI.SalesOrderShippingId = SOSI.SalesOrderShippingId
										LEFT JOIN DBO.SalesOrderStocklineV1 SOP WITH (NOLOCK) ON SOP.StockLineId = tmpSOBI.StockLineId
							) tmpcash WHERE tmpcash.SalesOrderShippingId = #InvoiceMainDetails.SalesOrderShippingId
							AND tmpcash.StockLineId = #InvoiceMainDetails.StockLineId
					  
						UPDATE  #InvoiceMainDetails SET QtyBilled = tmpcash.QtyBilled
							FROM( SELECT b.QtyBilled, b.BillingInvoicingItemId, b.StockLineId
								FROM dbo.BillingInvoicingItems b WITH (NOLOCK) 
										JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingId = b.BillingInvoicingId
										AND tmpSOBI.BillingInvoicingItemId = b.BillingInvoicingItemId
							) tmpcash WHERE tmpcash.BillingInvoicingItemId = #InvoiceMainDetails.BillingInvoicingItemId
							AND tmpcash.StockLineId = #InvoiceMainDetails.StockLineId

						UPDATE  #InvoiceMainDetails SET TotalSales = ISNULL(tmpcash.TotalSales, 0)
						FROM( SELECT 
								CASE WHEN ISNULL(tmpSOBI.BillingInvoicingId, 0) = 0 THEN 
								((ISNULL(SOSC.NetSaleAmount, 0)))
								ELSE ISNULL(SOBII.GrandTotal, 0) END as 'TotalSales',
								tmpSOBI.BillingInvoicingItemId,
								STK.SalesOrderStocklineId,
								SOBII.StockLineId
							FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK) 
								INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
								LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
								LEFT JOIN dbo.SalesOrderStocklineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
								LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBII.StockLineId = STK.StockLineId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
								LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId =  SOBII.BillingInvoicingId AND SOBI.ReferenceId = @ReferenceId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0
								LEFT JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingId = SOBI.BillingInvoicingId AND tmpSOBI.BillingInvoicingItemId = SOBII.BillingInvoicingItemId
						) tmpcash WHERE 
						tmpcash.StockLineId = #InvoiceMainDetails.StockLineId

						UPDATE  #InvoiceMainDetails SET TotalSales = ISNULL(tmpcash.TotalSales, 0)
						FROM( SELECT 
								CASE WHEN ISNULL(tmpSOBI.BillingInvoicingId, 0) = 0 THEN 
								((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 1)) * ISNULL(STK.QtyReserved, 1))
								ELSE ISNULL(SOBII.GrandTotal, 0) END as 'TotalSales',
								STK.SalesOrderStocklineId,
								tmpSOBI.BillingInvoicingId
							FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK) 
								INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
								INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = SOP.SalesOrderPartId AND SOR.SalesOrderId = @ReferenceId
								LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
								LEFT JOIN dbo.SalesOrderStocklineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
								LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBII.StockLineId = STK.StockLineId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
								LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId =  SOBII.BillingInvoicingId AND SOBI.ReferenceId = @ReferenceId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0
								LEFT JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingItemId = SOBII.BillingInvoicingItemId
						) tmpcash WHERE 
						tmpcash.SalesOrderStocklineId = #InvoiceMainDetails.SalesOrderStocklineId
						AND tmpcash.BillingInvoicingId IS NULL
						AND #InvoiceMainDetails.SalesOrderShippingId IS NULL
					
						UPDATE #InvoiceMainDetails
						SET TotalFreight = tmp.TotalFreight
						FROM (SELECT SalesOrderPartId, SUM(ISNULL(BillingAmount, 0)) AS TotalFreight
							FROM dbo.SalesOrderFreight WITH (NOLOCK)
							WHERE IsActive = 1 AND IsDeleted = 0
							GROUP BY SalesOrderPartId
						) tmp JOIN #InvoiceMainDetails sobi ON sobi.SalesOrderPartId = tmp.SalesOrderPartId
						WHERE ISNULL(sobi.IsVersionIncrease, 0) = 1;

						UPDATE  #InvoiceMainDetails SET TotalFlatFreight = tmpcash.TotalFreight
						FROM( SELECT ISNULL(SO.TotalFreight,0) As TotalFreight, SO.SalesOrderId
								FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
								JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
								WHERE so.FreightBilingMethodId = @FlateBilingMethodId
						) tmpcash WHERE tmpcash.SalesOrderId = #InvoiceMainDetails.SalesOrderId

						UPDATE  #InvoiceMainDetails SET TotalCharges = tmpcash.TotalCharges
						FROM( SELECT SUM(ISNULL((BillingAmount), 0)) AS TotalCharges , tmpSOBI.SalesOrderPartId, ISNULL(tmpSOBI.StockLineId, 0) StockLineId
								FROM dbo.SalesOrderCharges SOC WITH (NOLOCK) 
								LEFT JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.SalesOrderPartId = SOC.SalesOrderPartId
								WHERE SOC.SalesOrderId = @ReferenceId 						
									AND SOC.ItemMasterId = tmpSOBI.ItemMasterId 
									AND SOC.ConditionId = tmpSOBI.ConditionId 
									AND SOC.IsActive = 1 
									AND SOC.IsDeleted = 0  AND ISNULL(tmpSOBI.IsVersionIncrease,0) = 1
								GROUP BY tmpSOBI.SalesOrderPartId, tmpSOBI.StockLineId
						) tmpcash WHERE tmpcash.SalesOrderPartId = #InvoiceMainDetails.SalesOrderPartId --AND tmpcash.StockLineId = #InvoiceMainDetails.StockLineId

						UPDATE  #InvoiceMainDetails SET TotalFlatCharges = tmpcash.TotalFlatCharges
						FROM( SELECT ISNULL(SO.TotalCharges,0) As TotalFlatCharges, SO.SalesOrderId
								FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
								JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
								WHERE so.ChargesBilingMethodId = @FlateBilingMethodId
						) tmpcash WHERE tmpcash.SalesOrderId = #InvoiceMainDetails.SalesOrderId

						UPDATE  #InvoiceMainDetails SET InvoiceStatus = tmpcash.InvoiceStatus
						FROM( SELECT SOBI.InvoiceStatus, tmpSOBI.BillingInvoicingId 
								FROM dbo.BillingInvoicing SOBI WITH (NOLOCK) 
								INNER JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId 
								JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingItemId = SOBII.BillingInvoicingItemId
								Where SOBI.ReferenceId = @ReferenceId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
					
						) tmpcash WHERE tmpcash.BillingInvoicingId = #InvoiceMainDetails.BillingInvoicingId

						UPDATE  #InvoiceMainDetails SET TotalFreight = 0
						WHERE IndexColumn > 1

						UPDATE  #InvoiceMainDetails SET TotalCharges = 0
						WHERE IndexColumn > 1
					END				
				END
				ELSE
				BEGIN 
					PRINT '2.2'
					INSERT INTO #InvoiceMainDetails(IndexColumn,
					SalesOrderShippingId,SalesOrderShippingItemId,BillingInvoicingId , BillingInvoicingItemId, InvoiceDate , InvoiceNo, InvoiceTypeId ,SOShippingNum ,	SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
					StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId , ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
					SmentNo, TotalUnitCost, VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProformaInvoice, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
					ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
					SELECT DISTINCT 
						0 AS IndexColumn,
						0 AS SalesOrderShippingId,   
						0 AS SalesOrderShippingItemId,   
						sobi.BillingInvoicingId,
						sobii.BillingInvoicingItemId,
						case when CAST(sobi.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end InvoiceDate,
						sobi.InvoiceNo AS InvoiceNo,
						sobi.InvoiceTypeId,
						'' AS SOShippingNum,
						so.SalesOrderNumber, 
						imt.partnumber, 
						imt.ItemMasterId,
						sop.ConditionId, 
						imt.PartDescription, 
						sl.StockLineNumber,  
						sl.SerialNumber, 
						cr.[Name] as CustomerName,   
						ISNULL(stk.StockLineId, 0) StockLineId,
						0 AS ItemNo,  
						sop.SalesOrderId, 
						sop.SalesOrderPartId, 
						stk.SalesOrderStocklineId,
						cond.Description as 'Condition',   
						CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
						0 AS 'SmentNo',
						(ISNULL(SOSC.NetSaleAmount, 0)) AS TotalUnitCost,
						sobii.VersionNo,
						(CASE WHEN sobi.IsVersionIncrease = 1 then 0 else 1 end) IsVersionIncrease,
						CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
						0 AS IsProformaInvoice,
						0 AS DepositAmount,
						(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
						ISNULL(sobi.[IsInvoicePosted], 0) as [IsBilling],

						stk.ECCN AS ECCN,
						stk.HSCODE AS HSCODE,
						stk.[Weight] AS [Weight], 
						stk.SizeLength AS BillSizeLength,
						stk.SizeWidth AS BillSizeWidth,
						stk.SizeHeight AS BillSizeHeight

					FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
						INNER JOIN DBO.SalesOrder so WITH (NOLOCK) on so.SalesOrderId = sop.SalesOrderId 
						INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = sop.SalesOrderPartId AND SOR.StockLineId = Stk.StockLineId AND SOR.SalesOrderId = @ReferenceId
						LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) on sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.StockLineId = stk.StockLineId AND ISNULL(sobii.IsPerformaInvoice,0) = 0
						LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) on sobi.BillingInvoicingId = sobii.BillingInvoicingId AND ISNULL(sobi.IsPerformaInvoice,0) = 0 AND sobi.ReferenceId = @ReferenceId
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) on imt.ItemMasterId = sop.ItemMasterId  
						LEFT JOIN DBO.Stockline sl WITH (NOLOCK) on sl.StockLineId = stk.StockLineId  
						LEFT JOIN DBO.Customer cr WITH (NOLOCK) on cr.CustomerId = so.CustomerId  
						LEFT JOIN DBO.Condition cond WITH (NOLOCK) on cond.ConditionId = sop.ConditionId  
						LEFT JOIN DBO.Currency curr WITH (NOLOCK) on curr.CurrencyId = so.FunctionalCurrencyId  
						LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
						LEFT JOIN SalesOrderApproval soapr WITH(NOLOCK) on soapr.SalesOrderId = @ReferenceId and soapr.SalesOrderPartId = sop.SalesOrderPartId AND soapr.CustomerStatusId = 2
						INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
					WHERE SOP.SalesOrderId = @ReferenceId AND SOP.ItemMasterId = @ItemMasterId and SOP.ConditionId = @ConditionId
					AND SOR.QtyToReserve > 0

					UPDATE  #InvoiceMainDetails SET QtyToBill = tmpcash.QtyToBill
								FROM( SELECT ISNULL(SORR.QtyToReserve, 0)  QtyToBill, tmpSOBI.StockLineId
										FROM DBO.SalesOrderReserveParts SORR WITH (NOLOCK)
										JOIN #InvoiceMainDetails tmpSOBI ON SORR.SalesOrderPartId = tmpSOBI.SalesOrderPartId 
										AND SORR.StockLineId = tmpSOBI.StockLineId
										AND SORR.SalesOrderId = @ReferenceId
								) tmpcash WHERE tmpcash.StockLineId = #InvoiceMainDetails.StockLineId

					UPDATE  #InvoiceMainDetails SET QtyBilled = tmpcash.QtyBilled
								FROM( SELECT b.QtyBilled, b.SubReferenceId, b.StockLineId
									FROM dbo.BillingInvoicingItems b WITH (NOLOCK) 
											JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingItemId = b.BillingInvoicingItemId
											WHERE b.BillingInvoicingItemId = tmpSOBI.BillingInvoicingItemId
											AND ISNULL(b.IsPerformaInvoice,0) = 0 
								) tmpcash WHERE tmpcash.StockLineId = #InvoiceMainDetails.StockLineId

					UPDATE  #InvoiceMainDetails SET TotalSales = ISNULL(tmpcash.TotalSales, 0)
					FROM( SELECT 
							CASE WHEN ISNULL(tmpSOBI.BillingInvoicingId, 0) = 0 THEN 
							((ISNULL(SOSC.NetSaleAmount, 0)))
							ELSE ISNULL(SOBII.GrandTotal, 0) END as 'TotalSales',
							tmpSOBI.BillingInvoicingItemId
						FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK) 
							INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
							LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
							LEFT JOIN dbo.SalesOrderStocklineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
							LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBII.StockLineId = STK.StockLineId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
							LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId =  SOBII.BillingInvoicingId AND SOBI.ReferenceId = @ReferenceId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0
							LEFT JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingId = SOBI.BillingInvoicingId AND tmpSOBI.BillingInvoicingItemId = SOBII.BillingInvoicingItemId
					) tmpcash WHERE 
					tmpcash.BillingInvoicingItemId = #InvoiceMainDetails.BillingInvoicingItemId

					UPDATE  #InvoiceMainDetails SET TotalSales = ISNULL(tmpcash.TotalSales, 0)
					FROM( SELECT 
							CASE WHEN ISNULL(tmpSOBI.BillingInvoicingId, 0) = 0 THEN 
							((ISNULL(SOSC.NetSaleAmount, 0) / ISNULL(STK.QtyOrder, 1)) * ISNULL(STK.QtyReserved, 1))
							ELSE ISNULL(SOBII.GrandTotal, 0) END as 'TotalSales',
							STK.SalesOrderStocklineId,
							tmpSOBI.BillingInvoicingId
						FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK) 
							INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
							INNER JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) on SOR.SalesOrderPartId = SOP.SalesOrderPartId AND SOR.SalesOrderId = @ReferenceId
							LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH (NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
							LEFT JOIN dbo.SalesOrderStocklineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = STK.SalesOrderStocklineId
							LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND SOBII.StockLineId = STK.StockLineId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
							LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBI.BillingInvoicingId =  SOBII.BillingInvoicingId AND SOBI.ReferenceId = @ReferenceId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0
							LEFT JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingItemId = SOBII.BillingInvoicingItemId
					) tmpcash WHERE 
					tmpcash.SalesOrderStocklineId = #InvoiceMainDetails.SalesOrderStocklineId
					AND tmpcash.BillingInvoicingId IS NULL

					UPDATE  #InvoiceMainDetails SET TotalFreight = tmpcash.TotalFreight
					FROM( SELECT SUM(ISNULL((BillingAmount), 0)) AS TotalFreight , tmpSOBI.SalesOrderPartId, ISNULL(tmpSOBI.StockLineId, 0) StockLineId
						FROM dbo.SalesOrderFreight SOF WITH (NOLOCK) 
						JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.SalesOrderPartId = SOF.SalesOrderPartId
						WHERE sof.SalesOrderId = tmpSOBI.SalesOrderId 						
							AND sof.ItemMasterId = tmpSOBI.ItemMasterId 
							AND sof.ConditionId = tmpSOBI.ConditionId 
							AND sof.IsActive = 1 
							AND sof.IsDeleted = 0 AND ISNULL(tmpSOBI.IsVersionIncrease,0) = 1
						GROUP BY tmpSOBI.SalesOrderPartId, tmpSOBI.StockLineId
					) tmpcash WHERE tmpcash.SalesOrderPartId = #InvoiceMainDetails.SalesOrderPartId --AND tmpcash.StockLineId = #InvoiceMainDetails.StockLineId

					UPDATE  #InvoiceMainDetails SET TotalFlatFreight = tmpcash.TotalFreight
					FROM( SELECT ISNULL(SO.TotalFreight,0) As TotalFreight, SO.SalesOrderId
							FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
							JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
							WHERE so.FreightBilingMethodId = @FlateBilingMethodId
					) tmpcash WHERE tmpcash.SalesOrderId = #InvoiceMainDetails.SalesOrderId

					UPDATE  #InvoiceMainDetails SET TotalCharges = tmpcash.TotalCharges
					FROM( SELECT SUM(ISNULL((BillingAmount), 0)) AS TotalCharges , tmpSOBI.SalesOrderPartId, ISNULL(tmpSOBI.StockLineId, 0) StockLineId
							FROM dbo.SalesOrderCharges SOC WITH (NOLOCK) 
							LEFT JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.SalesOrderPartId = SOC.SalesOrderPartId
							WHERE SOC.SalesOrderId = @ReferenceId 						
								AND SOC.ItemMasterId = tmpSOBI.ItemMasterId 
								AND SOC.ConditionId = tmpSOBI.ConditionId 
								AND SOC.IsActive = 1 
								AND SOC.IsDeleted = 0  AND ISNULL(tmpSOBI.IsVersionIncrease,0) = 1
							GROUP BY tmpSOBI.SalesOrderPartId, tmpSOBI.StockLineId
					) tmpcash WHERE tmpcash.SalesOrderPartId = #InvoiceMainDetails.SalesOrderPartId --AND tmpcash.StockLineId = #InvoiceMainDetails.StockLineId

					UPDATE  #InvoiceMainDetails SET TotalFlatCharges = tmpcash.TotalFlatCharges
					FROM( SELECT ISNULL(SO.TotalCharges,0) As TotalFlatCharges, SO.SalesOrderId
							FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
							JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.SalesOrderId = SO.SalesOrderId
							WHERE so.ChargesBilingMethodId = @FlateBilingMethodId
					) tmpcash WHERE tmpcash.SalesOrderId = #InvoiceMainDetails.SalesOrderId

					UPDATE  #InvoiceMainDetails SET InvoiceStatus = tmpcash.InvoiceStatus
					FROM( SELECT SOBI.InvoiceStatus, tmpSOBI.BillingInvoicingId 
							FROM dbo.BillingInvoicing SOBI WITH (NOLOCK) 
							INNER JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId 
							JOIN #InvoiceMainDetails tmpSOBI ON tmpSOBI.BillingInvoicingItemId = SOBII.BillingInvoicingItemId
							Where SOBI.ReferenceId = @ReferenceId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
					
					) tmpcash WHERE tmpcash.BillingInvoicingId = #InvoiceMainDetails.BillingInvoicingId
				
					UPDATE  #InvoiceMainDetails SET TotalFreight = 0
					WHERE IndexColumn > 1

					UPDATE  #InvoiceMainDetails SET TotalCharges = 0
					WHERE IndexColumn > 1
				END
			END
				PRINT '3.0'
				INSERT INTO #InvoiceMainDetails (IndexColumn,
					SalesOrderShippingId,SalesOrderShippingItemId,BillingInvoicingId ,InvoiceDate , InvoiceNo , InvoiceTypeId ,SOShippingNum ,	QtyToBill ,SalesOrderNumber ,partnumber,ItemMasterId ,ConditionId,PartDescription ,
					StockLineNumber,SerialNumber ,	CustomerName ,	StockLineId ,QtyBilled ,ItemNo,	SalesOrderId ,SalesOrderPartId, SalesOrderStocklineId ,Condition ,	CurrencyCode ,
					TotalSales ,InvoiceStatus ,	SmentNo ,VersionNo ,IsVersionIncrease ,	IsNewInvoice,IsProformaInvoice, DepositAmount, IsAllowIncreaseVersionForBillItem,[IsBilling],
					ECCN ,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight,TotalUnitCost,TotalFreight,TotalFlatFreight,TotalCharges,TotalFlatCharges)
				(
					
						SELECT DISTINCT 
						0 AS IndexColumn,
						0 AS SalesOrderShippingId,   
						0 AS SalesOrderShippingItemId,   
						sobi.BillingInvoicingId,
						case when CAST(sobi.InvoiceDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(sobi.InvoiceDate, @CurrntEmpTimeZoneDesc) as Date))end InvoiceDate,
						sobi.InvoiceNo AS InvoiceNo,
						sobi.InvoiceTypeId,
						'' AS SOShippingNum, 
						ISNULL(stk.QtyOrder, 0) AS QtyToBill, 
						so.SalesOrderNumber, imt.partnumber, imt.ItemMasterId, sop.ConditionId, imt.PartDescription, sl.StockLineNumber,  
						sl.SerialNumber, cr.[Name] AS CustomerName,   
						stk.StockLineId,  
						ISNULL((SELECT ISNULL(b.QtyBilled, 0)
							FROM dbo.BillingInvoicing a WITH (NOLOCK) 
							INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
							WHERE b.BillingInvoicingItemId = SOBII.BillingInvoicingItemId AND ISNULL(b.IsPerformaInvoice,0) = 1 AND ISNULL(a.IsPerformaInvoice,0) = 1), 0) AS QtyBilled,  
						0 AS ItemNo,  
						sop.SalesOrderId, sop.SalesOrderPartId, stk.SalesOrderStocklineId, cond.Description AS 'Condition',   
						CASE WHEN currb.Code IS NOT NULL THEN currb.Code ELSE curr.Code END AS 'CurrencyCode',
						ISNULL(sobi.GrandTotal, 0) as 'TotalSales',  
						(SELECT a.InvoiceStatus FROM DBO.BillingInvoicing a WITH (NOLOCK) 
							INNER JOIN dbo.BillingInvoicingItems b WITH (NOLOCK) ON a.BillingInvoicingId = b.BillingInvoicingId 
							Where a.ReferenceId = @ReferenceId 
							AND b.BillingInvoicingItemId = sobii.BillingInvoicingItemId
							AND ISNULL(b.IsPerformaInvoice,0) = 1 AND ISNULL(a.IsPerformaInvoice,0) = 1) AS InvoiceStatus,
						0 AS 'SmentNo',
						sobii.VersionNo, 
						(CASE WHEN sobi.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsVersionIncrease,
						CASE WHEN sobi.BillingInvoicingId IS NULL THEN 1 ELSE 0 END AS IsNewInvoice,
						1 AS IsProformaInvoice,
						ISNULL(sobi.DepositAmount,0) AS DepositAmount,
						(CASE WHEN sobii.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersionForBillItem,
						ISNULL(sobi.[IsInvoicePosted], 0) as [IsBilling],
						'' AS ECCN,
						'' AS HSCODE,
						0 AS [Weight], 
						0 AS BillSizeLength,
						0 AS BillSizeWidth,
						0 AS BillSizeHeight,
						CASE WHEN SOSC.[SalesOrderStocklineId] > 0 THEN ISNULL(SOSC.NetSaleAmount,0) ELSE ISNULL(spc.NetSaleAmount,0) END AS TotalUnitCost,
						(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderFreight sof WITH (NOLOCK) 
							WHERE sof.SalesOrderId = @ReferenceId 			  
							AND sof.ItemMasterId = sop.ItemMasterId 
							AND sof.ConditionId = @ConditionId 
							AND sof.IsActive = 1 
							AND sof.IsDeleted = 0)  AS TotalFreight,
						(SELECT ISNULL(SO.TotalFreight,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
							WHERE [SO].[SalesOrderId] = @ReferenceId AND so.FreightBilingMethodId = @FlateBilingMethodId)
						 AS  TotalFlatFreight,
						(SELECT ISNULL(SUM(BillingAmount), 0) FROM dbo.SalesOrderCharges socg WITH (NOLOCK) 
						WHERE socg.SalesOrderId = @ReferenceId 				
							AND socg.ItemMasterId = sop.ItemMasterId 
							AND socg.ConditionId = @ConditionId 
							AND socg.IsActive = 1 
							AND socg.IsDeleted = 0) 
						AS TotalCharges,
						(SELECT ISNULL(SO.TotalCharges,0) FROM [dbo].[SalesOrder] SO WITH(NOLOCK) 
						WHERE [SO].[SalesOrderId] = @ReferenceId AND so.ChargesBilingMethodId = @FlateBilingMethodId)
						AS TotalFlatCharges
						FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
						LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderPartCost spc WITH (NOLOCK) ON spc.SalesOrderPartId = sop.SalesOrderPartId
						LEFT JOIN DBO.SalesOrderStockLineCost SOSC WITH (NOLOCK) ON SOSC.SalesOrderStocklineId = stk.SalesOrderStocklineId
						LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) ON sobii.SubReferenceId = sop.SalesOrderPartId AND (sobii.StockLineId = stk.StockLineId OR ISNULL(sobii.StockLineId, 0) = 0) AND ISNULL(sobii.IsPerformaInvoice,0) = 1
						LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) ON sobi.BillingInvoicingId = sobii.BillingInvoicingId  AND ISNULL(sobi.IsPerformaInvoice,0) = 1 AND sobi.ReferenceId = @ReferenceId
						INNER JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId  
						LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId  
						LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId  
						LEFT JOIN DBO.Customer cr WITH (NOLOCK) ON cr.CustomerId = so.CustomerId  
						LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON cond.ConditionId = sop.ConditionId  
						LEFT JOIN DBO.Currency curr WITH (NOLOCK) ON curr.CurrencyId = so.FunctionalCurrencyId 
						LEFT JOIN DBO.Currency currb WITH (NOLOCK) on currb.CurrencyId = sobi.CurrencyId
						WHERE sop.SalesOrderId = @ReferenceId AND sop.ItemMasterId = @ItemMasterId AND sop.ConditionId = @ConditionId
						)

				;WITH FinalCTE AS(
					SELECT DISTINCT
						   ROW_NUMBER() OVER (PARTITION BY SalesOrderPartId, IsProformaInvoice ORDER BY SalesOrderPartId, IsVersionIncrease DESC) AS IndexColumn,
						   SalesOrderShippingId,
						   SalesOrderShippingItemId,
						   BillingInvoicingId,
						   BillingInvoicingItemId,
						   InvoiceDate,
						   InvoiceNo,
						   InvoiceTypeId,
						   SOShippingNum,
						   QtyToBill,
						   SalesOrderNumber,
						   partnumber,
						   PartDescription,
						   StockLineNumber,
						   SerialNumber,	
						   CustomerName,
						   StockLineId,
						   QtyBilled,
						   ItemNo,
						   SalesOrderId,
						   SalesOrderPartId,
						   SalesOrderStocklineId,
						   Condition,
						   CurrencyCode,
						   TotalSales,
						   ISNULL(TotalUnitCost,0) TotalUnitCost,
						   ISNULL(TotalFreight,0) TotalFreight,
						   ISNULL(TotalFlatFreight,0) TotalFlatFreight,
						   ISNULL(TotalCharges,0) TotalCharges,
						   ISNULL(TotalFlatCharges,0) TotalFlatCharges,
						   InvoiceStatus ,	
						   SmentNo ,
						   VersionNo ,
						   IsVersionIncrease ,	
						   IsNewInvoice,
						   IsProformaInvoice,
						   DepositAmount,
						   IsAllowIncreaseVersionForBillItem,
						   [IsBilling],
						   ECCN,
						   HSCODE,
						   [Weight],
						   SizeLength,
						   SizeWidth,
						   SizeHeight
					FROM #InvoiceMainDetails )

					INSERT INTO #InvoiceMainDetails (
							IndexColumn,
							SalesOrderShippingId,
							SalesOrderShippingItemId,
							BillingInvoicingId,
							BillingInvoicingItemId,
							InvoiceDate, 
							InvoiceNo,
							InvoiceTypeId,
							SOShippingNum,	
							QtyToBill,
							SalesOrderNumber,
							partnumber,
							PartDescription,
							StockLineNumber,
							SerialNumber,	
							CustomerName,	
							StockLineId,
							QtyBilled,
							ItemNo,	
							SalesOrderId,
							SalesOrderPartId,
							SalesOrderStocklineId,
							Condition,	
							CurrencyCode,
							TotalSales,
							TotalUnitCost,
							TotalFreight,
							TotalFlatFreight,
							TotalCharges,
							TotalFlatCharges,
							InvoiceStatus,	
							SmentNo,
							VersionNo,
							IsVersionIncrease,	
							IsNewInvoice,
							IsProformaInvoice,
							DepositAmount,
							IsAllowIncreaseVersionForBillItem,
							IsBilling,
							ECCN,
							HSCODE,
							Weight,
							SizeLength,
							SizeWidth,
							SizeHeight,
							IsAllowIncreaseVersion,
							IsLastInserted
						)
						SELECT 
							IndexColumn,
							SalesOrderShippingId,
							SalesOrderShippingItemId,
							BillingInvoicingId,
							BillingInvoicingItemId,
							InvoiceDate, 
							InvoiceNo,
							InvoiceTypeId,
							SOShippingNum,	
							QtyToBill,
							SalesOrderNumber,
							partnumber,
							PartDescription,
							StockLineNumber,
							SerialNumber,	
							CustomerName,	
							StockLineId,
							QtyBilled,
							ItemNo,	
							SalesOrderId,
							SalesOrderPartId,
							SalesOrderStocklineId,
							Condition,	
							CurrencyCode,
							TotalSales,
							TotalUnitCost,
							ISNULL(CASE WHEN IndexColumn = 1 THEN TotalFreight ELSE 0 END, 0),
							TotalFlatFreight,
							ISNULL(CASE WHEN IndexColumn = 1 THEN TotalCharges ELSE 0 END, 0),
							TotalFlatCharges,
							InvoiceStatus,	
							SmentNo,
							VersionNo,
							IsVersionIncrease,	
							IsNewInvoice,
							IsProformaInvoice,
							DepositAmount,
							IsAllowIncreaseVersionForBillItem,
							IsBilling,
							ECCN,
							HSCODE,
							Weight,
							SizeLength,
							SizeWidth,
							SizeHeight,
							IsVersionIncrease,
							1
						FROM FinalCTE
						ORDER BY partnumber, IsProformaInvoice DESC, InvoiceNo DESC, VersionNo DESC;

						DELETE FROM #InvoiceMainDetails WHERE ISNULL(IsLastInserted,0) = 0
					
			END /*********END: SALES ORDER ********/
			SELECT * FROM #InvoiceMainDetails;	
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'	
				SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetCommonBillingInvoiceChildListNew' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@ReferenceId AS VARCHAR), '') + '''
													   @Parameter2 = ' + ISNULL(CAST(@SubReferenceId AS VARCHAR) ,'') +''
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