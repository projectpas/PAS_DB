/*************************************************************           
 ** File:   [RPT_GetTSLWorkOrderInvoiceItems]           
 ** Author: RAJESH GAMI
 ** Description: Work Order Invoice line items for the Turbine Standard Ltd (TSL) invoice format.
 **              Lines per billed MPN: life limited parts, other parts, labor, charges, freight, taxes.
 **              Each billed bucket on BillingInvoicingItems (MaterialCostPlus, LaborCostPlus, MiscChargesCostPlus,
 **              FreightCostPlus) is spread over its detail lines by cost weight, the rounding difference is added
 **              to the largest line, so the lines always add up to what was billed on the invoice.
 ** Date:   09-Nov-2026
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author          Change Description            
 ** --   --------      -------         --------------------------------          
    1    09-Nov-2026   RAJESH GAMI     [PN-18514] Created

--   EXEC [dbo].[RPT_GetTSLWorkOrderInvoiceItems] 9696,15
**************************************************************/
CREATE PROCEDURE [dbo].[RPT_GetTSLWorkOrderInvoiceItems]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @WOModuleId INT, @GridTermsText VARCHAR(1000) = 'This invoice is expressly subject to all standard Terms and Conditions of Sale and Service of Turbine Standard Ltd. The current version of these terms, which include the warranty policy and limits of liability, are found on our website. By requesting goods or services from Turbine Standard Ltd, you agree to these terms.';

		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

		IF (ISNULL(@ModuleId, 0) <> ISNULL(@WOModuleId, -1))
		BEGIN
			RETURN;
		END

		IF OBJECT_ID(N'tempdb..#Mpn') IS NOT NULL DROP TABLE #Mpn;
		IF OBJECT_ID(N'tempdb..#Lines') IS NOT NULL DROP TABLE #Lines;

		-- One row per billed MPN, ItemNo is the same ROW_NUMBER used by RPT_GetTSLWorkOrderInvoiceHeader
		SELECT BII.[BillingInvoicingItemId],
		       BII.[ReferenceId] AS [WorkOrderId],
		       COALESCE(NULLIF(BII.[WorkFlowWorkOrderId], 0),
		                (SELECT TOP 1 WOF.[WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WOF WITH(NOLOCK)
		                  WHERE WOF.[WorkOrderPartNoId] = WOP.[ID] ORDER BY WOF.[WorkFlowWorkOrderId] DESC)) AS [WorkFlowWorkOrderId],
		       ROW_NUMBER() OVER (ORDER BY WOP.[ID]) AS [ItemNo],
		       ISNULL(BII.[MaterialCostPlus], 0)    AS [MatAmt],
		       ISNULL(BII.[LaborCostPlus], 0)       AS [LabAmt],
		       ISNULL(BII.[MiscChargesCostPlus], 0) AS [ChgAmt],
		       ISNULL(BII.[FreightCostPlus], 0)     AS [FrtAmt]
		  INTO #Mpn
		  FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
		       INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON BII.[SubReferenceId] = WOP.[ID]
		 WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND BII.[ModuleId] = @WOModuleId;

		CREATE TABLE #Lines
		(
			[LineId]                 INT IDENTITY(1,1) NOT NULL,
			[BillingInvoicingItemId] BIGINT NOT NULL,
			[SectionOrder]           INT NOT NULL,
			[SectionName]            VARCHAR(100) NOT NULL,
			[Bucket]                 CHAR(3) NOT NULL,   -- MAT / LAB / CHG / FRT / TAX / TRM
			[Qty]                    DECIMAL(18, 2) NULL,
			[PartNumber]             VARCHAR(100) NULL,
			[SerialNumber]           VARCHAR(100) NULL,
			[Description]            VARCHAR(1000) NULL,
			[Condition]              VARCHAR(100) NULL,
			[Weight]                 DECIMAL(28, 6) NOT NULL DEFAULT 0,
			[Amount]                 DECIMAL(18, 2) NULL
		);

		/* ---- PARTS (issued stock materials). Life limited parts (ItemMaster.isTimeLife) get their own heading ---- */
		INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [Qty], [PartNumber], [SerialNumber], [Description], [Condition], [Weight])
		SELECT M.[BillingInvoicingItemId],
		       CASE WHEN ISNULL(IM.[isTimeLife], 0) = 1 THEN 1 ELSE 2 END,
		       CASE WHEN ISNULL(IM.[isTimeLife], 0) = 1 THEN '*LIFE LIMITED COMPONENTS*' ELSE '*PARTS REQUIRED*' END,
		       'MAT', WOMS.[QtyIssued], IM.[partnumber], SL.[SerialNumber], IM.[PartDescription],
		       CASE WHEN ISNULL(C.[Memo], '') <> '' THEN C.[Memo] ELSE C.[Code] END,
		       ISNULL(WOMS.[UnitCost], 0) * ISNULL(WOMS.[QtyIssued], 0)
		  FROM #Mpn M
		       INNER JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.[WorkFlowWorkOrderId] = M.[WorkFlowWorkOrderId] AND WOM.[IsDeleted] = 0
		       INNER JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK) ON WOMS.[WorkOrderMaterialsId] = WOM.[WorkOrderMaterialsId]
		       INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = WOMS.[ItemMasterId]
		        LEFT JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.[StockLineId] = WOMS.[StockLineId]
		        LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.[ConditionId] = WOMS.[ConditionId]
		 WHERE ISNULL(WOMS.[QtyIssued], 0) > 0
		 ORDER BY M.[ItemNo], WOM.[WorkOrderMaterialsId], WOMS.[WOMStockLineId];

		/* ---- PARTS (kit materials) ---- */
		INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [Qty], [PartNumber], [SerialNumber], [Description], [Condition], [Weight])
		SELECT M.[BillingInvoicingItemId],
		       CASE WHEN ISNULL(IM.[isTimeLife], 0) = 1 THEN 1 ELSE 2 END,
		       CASE WHEN ISNULL(IM.[isTimeLife], 0) = 1 THEN '*LIFE LIMITED COMPONENTS*' ELSE '*PARTS REQUIRED*' END,
		       'MAT', WOMSK.[QtyIssued], IM.[partnumber], SL.[SerialNumber], IM.[PartDescription],
		       CASE WHEN ISNULL(C.[Memo], '') <> '' THEN C.[Memo] ELSE C.[Code] END,
		       ISNULL(WOMSK.[UnitCost], 0) * ISNULL(WOMSK.[QtyIssued], 0)
		  FROM #Mpn M
		       INNER JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.[WorkFlowWorkOrderId] = M.[WorkFlowWorkOrderId] AND WOMK.[IsDeleted] = 0
		       INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMSK WITH(NOLOCK) ON WOMSK.[WorkOrderMaterialsKitId] = WOMK.[WorkOrderMaterialsKitId]
		       INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = WOMSK.[ItemMasterId]
		        LEFT JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.[StockLineId] = WOMSK.[StockLineId]
		        LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.[ConditionId] = WOMSK.[ConditionId]
		 WHERE ISNULL(WOMSK.[QtyIssued], 0) > 0
		 ORDER BY M.[ItemNo], WOMK.[WorkOrderMaterialsKitId], WOMSK.[WorkOrderMaterialStockLineKitId];

		/* ---- LABOR (billable labor tasks) ---- */
		INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [PartNumber], [Description], [Weight])
		SELECT X.[BillingInvoicingItemId], 3, '', 'LAB', 'LABOR', ISNULL(NULLIF(X.[TaskName], ''), 'Maintenance Labor'), X.[Cost]
		  FROM (SELECT M.[BillingInvoicingItemId], M.[ItemNo],
		               CASE WHEN ISNULL(WO.[WorkOrderFormTypeId], 0) = 1 THEN ISNULL(WOT.[TaskName], '') ELSE ISNULL(TS.[Description], '') END AS [TaskName],
		               SUM(ISNULL(L.[TotalCost], 0)) AS [Cost]
		          FROM #Mpn M
		               INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.[WorkOrderId] = M.[WorkOrderId]
		               INNER JOIN [dbo].[WorkOrderLaborHeader] LH WITH(NOLOCK) ON LH.[WorkFlowWorkOrderId] = M.[WorkFlowWorkOrderId]
		               INNER JOIN [dbo].[WorkOrderLabor] L WITH(NOLOCK) ON L.[WorkOrderLaborHeaderId] = LH.[WorkOrderLaborHeaderId]
		                      AND L.[BillableId] = 1 AND L.[IsActive] = 1 AND L.[IsDeleted] = 0
		                LEFT JOIN [dbo].[Task] TS WITH(NOLOCK) ON TS.[TaskId] = L.[TaskId]
		                LEFT JOIN [dbo].[WorkOrderTask] WOT WITH(NOLOCK) ON WOT.[WorkOrderTaskId] = L.[TaskId]
		         GROUP BY M.[BillingInvoicingItemId], M.[ItemNo],
		               CASE WHEN ISNULL(WO.[WorkOrderFormTypeId], 0) = 1 THEN ISNULL(WOT.[TaskName], '') ELSE ISNULL(TS.[Description], '') END) X
		 ORDER BY X.[ItemNo], X.[TaskName];

		/* ---- CHARGES ---- */
		INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [PartNumber], [Description], [Weight])
		SELECT M.[BillingInvoicingItemId], 3, '', 'CHG', CT.[ChargeType], ISNULL(NULLIF(WOC.[Description], ''), CT.[ChargeType]), ISNULL(WOC.[ExtendedCost], 0)
		  FROM #Mpn M
		       INNER JOIN [dbo].[WorkOrderCharges] WOC WITH(NOLOCK) ON WOC.[WorkFlowWorkOrderId] = M.[WorkFlowWorkOrderId] AND WOC.[IsDeleted] = 0
		       INNER JOIN [dbo].[Charge] CT WITH(NOLOCK) ON CT.[ChargeId] = WOC.[ChargesTypeId]
		 ORDER BY M.[ItemNo], WOC.[WorkOrderChargesId];

		/* ---- FREIGHT ---- */
		INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [PartNumber], [Description], [Weight])
		SELECT M.[BillingInvoicingItemId], 3, '', 'FRT', 'FREIGHT', 'Freight' + ISNULL(' - ' + SV.[Name], ''), ISNULL(WF.[Amount], 0)
		  FROM #Mpn M
		       INNER JOIN [dbo].[WorkOrderFreight] WF WITH(NOLOCK) ON WF.[WorkFlowWorkOrderId] = M.[WorkFlowWorkOrderId] AND WF.[IsDeleted] = 0
		        LEFT JOIN [dbo].[ShippingVia] SV WITH(NOLOCK) ON SV.[ShippingViaId] = WF.[ShipViaId]
		 ORDER BY M.[ItemNo], WF.[WorkOrderFreightId];

		/* ---- A billed bucket without any detail line is printed as one summary line ---- */
		INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [PartNumber], [Description], [Weight])
		SELECT M.[BillingInvoicingItemId], X.[SecOrder], X.[SecName], X.[Bucket], X.[PN], X.[Descr], 1
		  FROM #Mpn M
		       CROSS APPLY (VALUES ('MAT', 2, '*PARTS REQUIRED*', 'PARTS', 'Parts', M.[MatAmt]),
		                           ('LAB', 3, '', 'LABOR', 'Maintenance Labor', M.[LabAmt]),
		                           ('CHG', 3, '', 'CHARGES', 'Miscellaneous Charges', M.[ChgAmt]),
		                           ('FRT', 3, '', 'FREIGHT', 'Freight', M.[FrtAmt])) X([Bucket], [SecOrder], [SecName], [PN], [Descr], [Amt])
		 WHERE X.[Amt] <> 0
		   AND NOT EXISTS (SELECT 1 FROM #Lines L WHERE L.[BillingInvoicingItemId] = M.[BillingInvoicingItemId] AND L.[Bucket] = X.[Bucket]);

		/* ---- An MPN without any line at all still prints its header (one blank line) ---- */
		INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [Description])
		SELECT M.[BillingInvoicingItemId], 3, '', 'EMP', ''
		  FROM #Mpn M
		 WHERE NOT EXISTS (SELECT 1 FROM #Lines L WHERE L.[BillingInvoicingItemId] = M.[BillingInvoicingItemId]);

		/* ---- Spread each billed bucket over its lines (by cost weight, equal split when all weights are 0) ---- */
		;WITH T AS
		(
			SELECT L.[LineId], L.[Weight],
			       CASE L.[Bucket] WHEN 'MAT' THEN M.[MatAmt] WHEN 'LAB' THEN M.[LabAmt] WHEN 'CHG' THEN M.[ChgAmt] WHEN 'FRT' THEN M.[FrtAmt] END AS [BucketAmt],
			       SUM(L.[Weight]) OVER (PARTITION BY L.[BillingInvoicingItemId], L.[Bucket]) AS [SumW],
			       COUNT(1) OVER (PARTITION BY L.[BillingInvoicingItemId], L.[Bucket]) AS [Cnt]
			  FROM #Lines L INNER JOIN #Mpn M ON M.[BillingInvoicingItemId] = L.[BillingInvoicingItemId]
			 WHERE L.[Bucket] IN ('MAT', 'LAB', 'CHG', 'FRT')
		)
		UPDATE L SET [Amount] = ROUND(T.[BucketAmt] * CASE WHEN T.[SumW] > 0 THEN L.[Weight] / T.[SumW] ELSE 1.0 / T.[Cnt] END, 2)
		  FROM #Lines L INNER JOIN T ON T.[LineId] = L.[LineId];

		-- rounding difference goes to the largest line of the bucket
		;WITH R AS
		(
			SELECT L.[LineId],
			       CASE L.[Bucket] WHEN 'MAT' THEN M.[MatAmt] WHEN 'LAB' THEN M.[LabAmt] WHEN 'CHG' THEN M.[ChgAmt] WHEN 'FRT' THEN M.[FrtAmt] END AS [BucketAmt],
			       SUM(L.[Amount]) OVER (PARTITION BY L.[BillingInvoicingItemId], L.[Bucket]) AS [SumAmt],
			       ROW_NUMBER() OVER (PARTITION BY L.[BillingInvoicingItemId], L.[Bucket] ORDER BY L.[Amount] DESC, L.[LineId] DESC) AS [RN]
			  FROM #Lines L INNER JOIN #Mpn M ON M.[BillingInvoicingItemId] = L.[BillingInvoicingItemId]
			 WHERE L.[Bucket] IN ('MAT', 'LAB', 'CHG', 'FRT')
		)
		UPDATE L SET [Amount] = L.[Amount] + (R.[BucketAmt] - R.[SumAmt])
		  FROM #Lines L INNER JOIN R ON R.[LineId] = L.[LineId]
		 WHERE R.[RN] = 1;

		/* ---- Taxes and the terms line are printed on the last MPN of the invoice ---- */
		DECLARE @LastMpnItemId BIGINT;
		SELECT TOP 1 @LastMpnItemId = [BillingInvoicingItemId] FROM #Mpn ORDER BY [ItemNo] DESC;

		INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [PartNumber], [Description], [Amount])
		SELECT @LastMpnItemId, 4, '', 'TAX', 'TAX', 'Sales Tax', BI.[SalesTax]
		  FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK) WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BI.[SalesTax], 0) <> 0 AND @LastMpnItemId IS NOT NULL
		UNION ALL
		SELECT @LastMpnItemId, 4, '', 'TAX', 'TAX', 'Other Tax', BI.[OtherTax]
		  FROM [dbo].[BillingInvoicing] BI WITH(NOLOCK) WHERE BI.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BI.[OtherTax], 0) <> 0 AND @LastMpnItemId IS NOT NULL;

		IF (ISNULL(@GridTermsText, '') <> '' AND @LastMpnItemId IS NOT NULL)
		BEGIN
			INSERT INTO #Lines ([BillingInvoicingItemId], [SectionOrder], [SectionName], [Bucket], [PartNumber], [Description])
			VALUES (@LastMpnItemId, 5, '', 'TRM', 'Terms & Conditions', @GridTermsText);
		END

		-- zero amounts print blank on the invoice
		UPDATE #Lines SET [Amount] = NULL WHERE [Amount] = 0;

		SELECT L.[BillingInvoicingItemId],
		       M.[ItemNo],
		       L.[SectionOrder],
		       L.[SectionName],
		       L.[LineId] AS [LineOrder],
		       L.[Qty],
		       L.[PartNumber],
		       L.[SerialNumber],
		       L.[Description],
		       L.[Condition],
		       L.[Amount]
		  FROM #Lines L
		       INNER JOIN #Mpn M ON M.[BillingInvoicingItemId] = L.[BillingInvoicingItemId]
		 ORDER BY M.[ItemNo], L.[SectionOrder], L.[LineId];

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'RPT_GetTSLWorkOrderInvoiceItems'
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))
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
