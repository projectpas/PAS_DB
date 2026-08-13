/*************************************************************           
 ** File:   [GetSalesOrderPartView]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Sales Order Quote Part Data
 ** Purpose:         
 ** Date:   09/26/2024
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/26/2024   Vishal Suthar     Created
    2    11/11/2024   Vishal Suthar     Modified to fix Qty available and Qty OH
    3    11/15/2024   Vishal Suthar     Modified to fix Qty shipped
	4    11/21/2024   Amit Ghediya      Modified to WLH & weight
	5    11/22/2024   RAJESH GAMI       Modified to StatusId getting based on the condition (STK and Part)
	6    11/24/2024   Amit Ghediya      Modified to eccn & update cond.
	7    11/25/2024   RAJESH GAMI       Modified to change the condition for QtyAvailable and QtyOnHand (SC.SalesOrderStocklineId IS NOT NULL to Stk.SalesOrderStocklineId IS NOT NULL)
	8    12/04/2024   RAJESH GAMI       Modified to Devide by 0 issue
	9    12/06/2024   Amit Ghediya      Modified to update cond.
	10   12/07/2014   Moin Bloch		Modified to add AltOrEqType
	11   18-12-2024   Shrey Chandegara  Modified to priorityid
	12   26-12-2024   Amit Ghediya		Modified to add SoPartId param set default value is o & get partwise data, if partid=0 then all part come.
	13   02-01-2025   Amit Ghediya		Modified to get part level Available & onhnad qty after reserve.
	14   09-01-2025   Amit Ghediya		Modified to get STK level Available & onhnad qty.
	15   17-01-2025   RAJESH GAMI		Modified to get Revised PN.     
	16   13-03-2025   Vishal Suthar		Fixed issue with duplicate records     
	17   05-01-2025	  ABHISHEK JIRAWLA  Allow Repair Management Customer Stock Stockline
	18   05-07-2025   BHARGAV SALIYA    get condition through the [SalesOrderPartV1] Join
	19   07-Aug-2025  RAJESH GAMI	    Getting LotNumber 
	20   19-SEP-2025  RAJESH GAMI	    Added return field: netSalesPricePerUnit
	21   05-NOV-2025  RAJESH GAMI	    Added return field: TotalPartCost
	22    20-NOV-2025  RAJESH GAMI	    Fixed TotalPartCost Issue
	23    19/06/2026  Abhishek Jirawla	Adding IsPiecePart condition in RepairOrderPart table 
	24    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	25    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	26    20/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters from QtyAvailable/QuantityOnHand rollup subqueries and StockLine/ItemMaster joins.
    27    05/Aug/2026			 KISHOR MAKWANA						[PN-17439] Return persisted part.SequenceNumber as ItemNo instead of hardcoded 0
-- EXEC [DBO].[GetSalesOrderPartView] 706,0
**************************************************************/
CREATE   PROCEDURE [dbo].[GetSalesOrderPartView]
    @SalesOrderId BIGINT,
	@SoPartId BIGINT = 0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	DECLARE @ApprovedStatus INT = 2;
	DECLARE @DefaultPriorityId INT = 2;
	DECLARE @DefaultPriorityName VARCHAR(50) = 'ROUTINE';
	DECLARE @DefaultStatusId INT = 1;
	DECLARE @DefaultStatusName VARCHAR(50) = 'OPEN';
	DECLARE @soModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
	DECLARE @LotId BIGINT = ISNULL((SELECT TOP 1 ISNULL(LotId,0) FROM dbo.SalesOrder WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId),0)
	DECLARE @LOTNumber VARCHAR(100)= ISNULL((SELECT TOP 1 LotNumber FROM dbo.LOT WITH(NOLOCK) WHERE LotId = @LotId),'')
	--Set SoPart null for all part for salesordor otherwise for perticular part only.
	IF(ISNULL(@SoPartId,0) = 0)
	BEGIN
		SET @SoPartId = NULL;
	END
		IF OBJECT_ID(N'tempdb..#tmpSOPartTblV1') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSOPartTblV1
		END
		IF OBJECT_ID(N'tempdb..#SOPartKey')   IS NOT NULL DROP TABLE #SOPartKey
		IF OBJECT_ID(N'tempdb..#StkRollup')   IS NOT NULL DROP TABLE #StkRollup
		IF OBJECT_ID(N'tempdb..#PickTicket')  IS NOT NULL DROP TABLE #PickTicket
		IF OBJECT_ID(N'tempdb..#FreightAgg')  IS NOT NULL DROP TABLE #FreightAgg
		IF OBJECT_ID(N'tempdb..#MiscAgg')     IS NOT NULL DROP TABLE #MiscAgg
		IF OBJECT_ID(N'tempdb..#ApprovedPart') IS NOT NULL DROP TABLE #ApprovedPart
		IF OBJECT_ID(N'tempdb..#ShippedAgg')  IS NOT NULL DROP TABLE #ShippedAgg
		IF OBJECT_ID(N'tempdb..#ShipRef')     IS NOT NULL DROP TABLE #ShipRef
		IF OBJECT_ID(N'tempdb..#BillingAgg')  IS NOT NULL DROP TABLE #BillingAgg
		IF OBJECT_ID(N'tempdb..#LotStk')      IS NOT NULL DROP TABLE #LotStk

	/****** PRE-AGGREGATION : each block replaces a correlated sub-query that previously ran once PER ROW ******/

	-- Scope key for this execution
	SELECT DISTINCT p.SalesOrderPartId, p.ItemMasterId, p.ConditionId,p.SequenceNumber
	INTO #SOPartKey
	FROM DBO.SalesOrderPartV1 p WITH (NOLOCK)
	WHERE p.SalesOrderId = @SalesOrderId
	  AND (@SoPartId IS NULL OR p.SalesOrderPartId = @SoPartId)
	  AND (p.IsDeleted IS NULL OR p.IsDeleted = 0)
	OPTION (RECOMPILE);
	CREATE CLUSTERED INDEX IX_SOPartKey ON #SOPartKey (ItemMasterId, ConditionId, SalesOrderPartId,SequenceNumber);

	-- Stockline roll-up by ItemMasterId + ConditionId  (was written 4x and executed 4x per row)
	SELECT k.ItemMasterId, k.ConditionId,k.SequenceNumber, s.QtyAvailable, s.QtyOnHand
	INTO #StkRollup
	FROM (SELECT DISTINCT ItemMasterId, ConditionId,SequenceNumber FROM #SOPartKey) k
	CROSS APPLY (SELECT SUM(Stk.QuantityAvailable) AS QtyAvailable, SUM(Stk.QuantityOnHand) AS QtyOnHand
				 FROM DBO.Stockline Stk WITH (NOLOCK)
				 WHERE Stk.ItemMasterId = k.ItemMasterId AND Stk.ConditionId = k.ConditionId AND Stk.IsParent = 1
				   AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0))) s;
	CREATE CLUSTERED INDEX IX_StkRollup ON #StkRollup (ItemMasterId, ConditionId,SequenceNumber);

	-- QtyToShip
	SELECT SalesOrderPartId, QtyToShip = SUM(QtyToShip)
	INTO #PickTicket
	FROM DBO.SOPickTicket WITH (NOLOCK)
	WHERE SalesOrderId = @SalesOrderId AND IsActive = 1 AND IsDeleted = 0
	GROUP BY SalesOrderPartId;
	CREATE CLUSTERED INDEX IX_PickTicket ON #PickTicket (SalesOrderPartId);

	-- Freight
	SELECT ItemMasterId, ConditionId, Freight = SUM(BillingAmount)
	INTO #FreightAgg
	FROM DBO.SalesOrderFreight WITH (NOLOCK)
	WHERE SalesOrderId = @SalesOrderId AND IsActive = 1 AND IsDeleted = 0
	GROUP BY ItemMasterId, ConditionId;
	CREATE CLUSTERED INDEX IX_FreightAgg ON #FreightAgg (ItemMasterId, ConditionId);

	-- Misc charges
	SELECT ItemMasterId, ConditionId, Misc = SUM(BillingAmount)
	INTO #MiscAgg
	FROM DBO.SalesOrderCharges WITH (NOLOCK)
	WHERE SalesOrderId = @SalesOrderId AND IsActive = 1 AND IsDeleted = 0
	GROUP BY ItemMasterId, ConditionId;
	CREATE CLUSTERED INDEX IX_MiscAgg ON #MiscAgg (ItemMasterId, ConditionId);

	-- IsApproved  (was EXISTS per row)
	SELECT DISTINCT sa.SalesOrderPartId
	INTO #ApprovedPart
	FROM DBO.SalesOrderApproval sa WITH (NOLOCK)
	INNER JOIN #SOPartKey k ON k.SalesOrderPartId = sa.SalesOrderPartId
	WHERE sa.IsDeleted = 0 AND sa.CustomerStatusId = @ApprovedStatus;
	CREATE CLUSTERED INDEX IX_ApprovedPart ON #ApprovedPart (SalesOrderPartId);

	-- qtyShipped
	SELECT sopt.SalesOrderPartStocklineId, qtyShipped = SUM(sosi.QtyShipped)
	INTO #ShippedAgg
	FROM DBO.SalesOrderShipping sos WITH (NOLOCK)
	INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId
	INNER JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SOPickTicketId = sosi.SOPickTicketId
	WHERE sos.SalesOrderId = @SalesOrderId AND sos.IsActive = 1 AND sos.IsDeleted = 0
	GROUP BY sopt.SalesOrderPartStocklineId;
	CREATE CLUSTERED INDEX IX_ShippedAgg ON #ShippedAgg (SalesOrderPartStocklineId);

	-- shipReference
	SELECT r.SalesOrderPartId, r.SOShippingNum
	INTO #ShipRef
	FROM (SELECT sosi.SalesOrderPartId, sos.SOShippingNum,
				 rn = ROW_NUMBER() OVER (PARTITION BY sosi.SalesOrderPartId ORDER BY sos.SalesOrderShippingId)
		  FROM DBO.SalesOrderShipping sos WITH (NOLOCK)
		  INNER JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId
		  WHERE sos.SalesOrderId = @SalesOrderId AND sos.IsActive = 1 AND sos.IsDeleted = 0) r
	WHERE r.rn = 1;
	CREATE CLUSTERED INDEX IX_ShipRef ON #ShipRef (SalesOrderPartId);

	-- qtyInvoiced / invoiceDate / invoiceNumber  (was 3 separate scans per row)
	SELECT b.StocklineId, b.SubReferenceId,
		   qtyInvoiced   = SUM(b.QtyBilled),
		   invoiceDate   = MAX(CASE WHEN b.rn = 1 THEN b.InvoiceDate END),
		   invoiceNumber = MAX(CASE WHEN b.rn = 1 THEN b.InvoiceNo   END)
	INTO #BillingAgg
	FROM (SELECT sobi.StocklineId, sobi.SubReferenceId, sobi.QtyBilled, sob.InvoiceDate, sob.InvoiceNo,
				 rn = ROW_NUMBER() OVER (PARTITION BY sobi.StocklineId, sobi.SubReferenceId ORDER BY sob.BillingInvoicingId)
		  FROM DBO.BillingInvoicing sob WITH (NOLOCK)
		  INNER JOIN DBO.BillingInvoicingItems sobi WITH (NOLOCK) ON sob.BillingInvoicingId = sobi.BillingInvoicingId
		  WHERE sob.ModuleId = @soModuleId AND sob.ReferenceId = @SalesOrderId
			AND ISNULL(sob.IsActive,0) = 1 AND ISNULL(sob.IsDeleted,0) = 0
			AND ISNULL(sobi.IsVersionIncrease,0) = 0 AND ISNULL(sobi.IsPerformaInvoice,0) = 0) b
	GROUP BY b.StocklineId, b.SubReferenceId;
	CREATE CLUSTERED INDEX IX_BillingAgg ON #BillingAgg (StocklineId, SubReferenceId);

	-- LotNumber
	CREATE TABLE #LotStk (StockLineId BIGINT NOT NULL PRIMARY KEY);
	IF (@LOTNumber <> '' AND @LotId > 0)
	BEGIN
		INSERT INTO #LotStk (StockLineId)
		SELECT DISTINCT LTI.StockLineId FROM dbo.LotTransInOutDetails LTI WITH (NOLOCK)
		WHERE LTI.LotId = @LotId AND LTI.StockLineId IS NOT NULL;
	END

    SELECT DISTINCT
        part.SalesOrderId,
        part.SalesOrderPartId,
		stk.SalesOrderStocklineId,
        SO.SalesOrderQuoteId,
        part.ItemMasterId,
        Stk.StockLineId,
        ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
        part.FxRate,
        CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN Stk.QtyOrder ELSE part.QtyOrder END AS Qty,
        part.QtyRequested,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitSalesPrice, 0) ELSE ISNULL(PS.UnitSalesPrice, 0) END AS UnitSalePrice,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarkUpPercentage, 0) ELSE ISNULL(PS.MarkUpPercentage, 0) END MarkUpPercentage,
        0 SalesBeforeDiscount,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.DiscountPercentage, 0) ELSE ISNULL(PS.DiscountPercentage, 0) END Discount,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN (CASE WHEN ISNULL(stk.QtyOrder,0)>0 THEN (ISNULL(SC.DiscountAmount, 0) / stk.QtyOrder) ELSE 0 END) ELSE (CASE WHEN ISNULL(part.QtyOrder,0) > 0 THEN (ISNULL(PS.DiscountAmount, 0) / part.QtyOrder) ELSE 0 END) END DiscountAmount,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS NetSales,
        part.MasterCompanyId,
        part.CreatedBy,
        part.CreatedDate,
        part.UpdatedBy,
        part.UpdatedDate,
        itemMaster.PartNumber,
        itemMaster.PartDescription,
        ISNULL(qs.OEM, 0) AS IsOEM,
        itemMaster.IsPma,
        itemMaster.IsDER,
        UPPER(ISNULL(itemMaster.ManufacturerName, '')) AS ManufacturerName,
        CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN 'S' ELSE 'I' END MethodType,
        '' AS Method,
        ISNULL(qs.IsSerialized, 0) AS IsSerialized,
        ISNULL(qs.SerialNumber, '') AS SerialNumber,
        ISNULL(qs.ControlNumber, '') AS ControlNumber,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitCost, 0) ELSE ISNULL(PS.UnitCost, 0) END UnitCost,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitSalesPriceExtended, 0) ELSE ISNULL(PS.UnitSalesPriceExtended, 0) END AS SalesPriceExtended,
        ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarkUpAmount, 0) ELSE ISNULL(PS.MarkUpAmount, 0) END) * stk.QtyOrder), 0) MarkupExtended,
        ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.DiscountAmount, 0) ELSE ISNULL(PS.DiscountAmount, 0) END) * stk.QtyOrder), 0) SalesDiscountExtended,
        ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END) * stk.QtyOrder), 0) NetSalePriceExtended,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitCostExtended, 0) ELSE ISNULL(PS.UnitCostExtended, 0) END UnitCostExtended,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarginAmount, 0) ELSE ISNULL(PS.MarginAmount, 0) END MarginAmount,
        ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarginAmount, 0) ELSE ISNULL(PS.MarginAmount, 0) END) * stk.QtyOrder), 0) MarginAmountExtended,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarginPercentage, 0) ELSE ISNULL(PS.MarginPercentage, 0) END AS MarginPercentage,
        ISNULL(fcu.Code, '') AS CurrencyDescription,
        part.CurrencyId,
        part.ConditionId,
        ISNULL(cp.Description, '') AS ConditionDescription,
		--CASE WHEN ISNULL(cp.Description, '') = '' THEN ISNULL(cpart.Description, '') ELSE ISNULL(cp.Description, '') END AS ConditionDescription,
        ISNULL(qs.IdNumber, '') AS IdNumber,
        ISNULL(qs.TraceableToName, '') AS TraceableToName,
        ISNULL(qs.CertifiedBy, '') AS CertifiedBy,
        ISNULL(qs.ObtainFromName, '') AS ObtainFrom,
        ISNULL(q.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
        ISNULL(q.OpenDate, GETDATE()) AS QuoteDate,
        --ISNULL(qs.QuantityAvailable, 0) AS QtyAvailable,
        --ISNULL(qs.QuantityOnHand, 0) AS QuantityOnHand,
        ISNULL(iu.ShortName, '') AS UOM,
        ISNULL(Stk.QtyReserved, NULL) AS QtyReserved,
        CASE WHEN appr.SalesOrderPartId IS NOT NULL THEN 1 ELSE 0 END AS IsApproved,
        ISNULL(SO.SalesOrderQuoteId, '') AS CustomerReference,
        --ISNULL(imx.ExportECCN, '') AS ECCN,
        ISNULL(imx.ITARNumber, '') AS ITAR,
        ISNULL(um.ShortName, '') AS UomName,
        part.CustomerRequestDate,
        part.PromisedDate,
        part.EstimatedShipDate,
		CASE WHEN Stk.PriorityId IS NOT NULL THEN Stk.PriorityId ELSE ISNULL(part.PriorityId, @DefaultPriorityId) END AS PriorityId,
		CASE WHEN Stk.PriorityId IS NOT NULL THEN prit.Description ELSE ISNULL(pri.Description, @DefaultPriorityName) END AS PriorityName,
		CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN ISNULL(Stk.StatusId,@DefaultStatusId) ELSE ISNULL(part.StatusId,@DefaultStatusId) END StatusId,
		ISNULL(sps.Description, @DefaultStatusName) AS StatusName,
        ISNULL(pkt.QtyToShip, 0) AS QtyToShip,
        CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN Stk.Notes ELSE part.Notes END Notes,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN (CASE WHEN ISNULL(stk.QtyOrder,0) >0 THEN (ISNULL(SC.MarkUpAmount, 0) / stk.QtyOrder) ELSE 0 END) ELSE(CASE WHEN ISNULL(part.QtyOrder,0) > 0 THEN (ISNULL(PS.MarkUpAmount, 0) / part.QtyOrder) ELSE 0 END)END MarkupPerUnit,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS GrossSalePricePerUnit,
        CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS GrossSalePrice,
        0 AS TaxPercentage,
        '' TaxType,
        ISNULL(PS.TaxAmount, 0) AS TaxAmount,
        ISNULL(part.AltOrEqType,'') AltOrEqType,
        ISNULL(frt.Freight, 0) AS Freight,
        ISNULL(msc.Misc, 0) AS Misc,
        CASE
            WHEN itemMaster.IsPma = 1 AND itemMaster.IsDER = 1 THEN 'PMA&DER'
            WHEN itemMaster.IsPma = 1 THEN 'PMA'
            WHEN itemMaster.IsDER = 1 THEN 'DER'
            ELSE 'OEM'
        END AS StockType,
        part.SequenceNumber AS ItemNo,
        part.POId,
        part.PONumber,
        part.PONextDlvrDate,
        rop.RepairOrderPartRecordId AS ROId,
        ro.RepairOrderNumber AS RONumber,
        rop.EstRecordDate,
        (CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitSalesPrice, 0) ELSE ISNULL(PS.UnitSalesPrice, 0) END) UnitSalesPricePerUnit,
        itemMaster.ItemClassificationName AS ItemClassification,
        itemMaster.ItemGroup,
        rop.EstRecordDate AS roNextDlvrDate,
		CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN
			ISNULL(qs.QuantityAvailable, 0)
		ELSE
			ISNULL(srl.QtyAvailable, 0)
		END StkQtyAvailable,
		ISNULL(srl.QtyAvailable, 0)
		 QtyAvailable,
		CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN
			ISNULL(qs.QuantityOnHand, 0)
		ELSE
			ISNULL(srl.QtyOnHand, 0)
		END StkQuantityOnHand,
		ISNULL(srl.QtyOnHand, 0)
		 QuantityOnHand,
		shp.qtyShipped qtyShipped,

		bil.qtyInvoiced qtyInvoiced,

		bil.invoiceDate invoiceDate,

		bil.invoiceNumber invoiceNumber,

		sref.SOShippingNum shipReference,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.ECCN ELSE part.ECCN END ECCN,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.HSCODE ELSE part.HSCODE END HSCODE,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.[Weight] ELSE part.[Weight] END [Weight],
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.SizeLength ELSE part.SizeLength END SizeLength,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.SizeWidth ELSE part.SizeWidth END SizeWidth,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.SizeHeight ELSE part.SizeHeight END SizeHeight,
		(CASE WHEN ISNULL(part.ItemMasterId,0) != 0 AND ISNULL(part.ItemMasterId,0) != ISNULL(qs.ItemMasterId,0) THEN qs.PartNumber ELSE '' END) as RevisedPN,
		(CASE WHEN ISNULL(part.ItemMasterId,0) != 0 AND ISNULL(part.ItemMasterId,0) != ISNULL(qs.ItemMasterId,0) THEN qs.ItemMasterId ELSE 0 END) as RevisedPNItemMasterId,
		CASE WHEN @LOTNumber = '' THEN '' ELSE (CASE WHEN lts.StockLineId IS NOT NULL THEN @LOTNumber ELSE '' END) END  AS LotNumber,
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmountPerUnit, 0) ELSE ISNULL(PS.NetSaleAmountPerUnit, 0) END AS netSalesPricePerUnit,
		part.UnitSalesPrice MainUnitSalesPrice,
		ISNULL((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END), 0) NetSalePriceExtendedPart,
		ISNULL(imps.SP_CalSPByPP_UnitSalePrice,0) AS ItemMasterUnitCost,
		ISNULL(PS.NetSaleAmount,0) AS TotalPartCost
		INTO #tmpSOPartTblV1
    FROM DBO.SalesOrderPartV1 part WITH (NOLOCK)
    LEFT JOIN DBO.SalesOrderStocklineV1 Stk WITH (NOLOCK) ON part.SalesOrderPartId = Stk.SalesOrderPartId
	LEFT JOIN DBO.SalesOrderPartCost PS WITH (NOLOCK) ON PS.SalesOrderPartId = part.SalesOrderPartId
    LEFT JOIN DBO.SalesOrderStockLineCost SC WITH (NOLOCK) ON SC.SalesOrderStocklineId = Stk.SalesOrderStocklineId
    LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON part.SalesOrderId = SO.SalesOrderId
    LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON Stk.StockLineId = qs.StockLineId
    LEFT JOIN DBO.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
    LEFT JOIN DBO.ItemMasterExportInfo imx WITH (NOLOCK) ON itemMaster.ItemMasterId = imx.ItemMasterId
    LEFT JOIN DBO.Condition cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
	LEFT JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuotePartId = part.SalesOrderQuotePartId
    LEFT JOIN DBO.SalesOrderQuote q WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = q.SalesOrderQuoteId
    LEFT JOIN DBO.UnitOfMeasure iu WITH (NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
    LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
    LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
    LEFT JOIN DBO.[Priority] pri WITH (NOLOCK) ON part.PriorityId = pri.PriorityId
    LEFT JOIN DBO.[Priority] prit WITH (NOLOCK) ON prit.PriorityId = Stk.PriorityId
    LEFT JOIN DBO.RepairOrderPart rop WITH (NOLOCK) ON qs.RepairOrderPartRecordId = rop.RepairOrderPartRecordId AND (ROP.[IsPiecePart] IS NULL OR ROP.[IsPiecePart] = 0)
    LEFT JOIN DBO.Currency fcu WITH (NOLOCK) ON part.CurrencyId = fcu.CurrencyId AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
	/****** pre-aggregated lookups (replace the old per-row correlated sub-queries) ******/
	LEFT JOIN #ApprovedPart appr ON appr.SalesOrderPartId = part.SalesOrderPartId
	LEFT JOIN #PickTicket   pkt  ON pkt.SalesOrderPartId  = part.SalesOrderPartId
	LEFT JOIN #FreightAgg   frt  ON frt.ItemMasterId = part.ItemMasterId AND frt.ConditionId = part.ConditionId
	LEFT JOIN #MiscAgg      msc  ON msc.ItemMasterId = part.ItemMasterId AND msc.ConditionId = part.ConditionId
	LEFT JOIN #StkRollup    srl  ON srl.ItemMasterId = part.ItemMasterId AND srl.ConditionId = part.ConditionId
	LEFT JOIN #ShippedAgg   shp  ON shp.SalesOrderPartStocklineId = Stk.SalesOrderStocklineId
	LEFT JOIN #ShipRef      sref ON sref.SalesOrderPartId = part.SalesOrderPartId
	LEFT JOIN #BillingAgg   bil  ON bil.StocklineId = Stk.StockLineId AND bil.SubReferenceId = part.SalesOrderPartId
	LEFT JOIN #LotStk       lts  ON lts.StockLineId = Stk.StockLineId
	LEFT JOIN DBO.SOPartStatus sps WITH (NOLOCK) ON sps.SOPartStatusId = CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN ISNULL(Stk.StatusId,@DefaultStatusId) ELSE ISNULL(part.StatusId,@DefaultStatusId) END
    LEFT JOIN ItemMasterPurchaseSale imps WITH (NOLOCK) ON imps.ItemMasterId = itemMaster.ItemMasterId and imps.ConditionId=part.ConditionId
	WHERE part.SalesOrderId = @SalesOrderId
	AND (@SoPartId IS NULL OR part.SalesOrderPartId = @SoPartId)
    AND (part.IsDeleted IS NULL OR part.IsDeleted = 0)
    AND (rop.isAsset IS NULL OR rop.isAsset = 0)
	ORDER BY part.SalesOrderPartId
	OPTION (RECOMPILE);

	CREATE CLUSTERED INDEX IX_tmpSOPartTblV1 ON #tmpSOPartTblV1 (SalesOrderPartId);

	/****** Total Part Wise COST Calculation ******/
	;WITH CTE_Cost AS (
			SELECT
				SalesOrderPartId,
				SUM(ISNULL(Qty, 0)) AS TotalQtyQuoted,
				SUM(ISNULL(NetSalePriceExtendedPart, 0)) AS TotalNetSalePriceExtended
			FROM #tmpSOPartTblV1
			GROUP BY SalesOrderPartId
		)
	/****** Final Table Return *******/
		SELECT
			main.*
			--,
			--(((main.QtyRequested - ISNULL(c.TotalQtyQuoted, 0)) * ISNULL(main.MainUnitSalesPrice, 0))
			--  + ISNULL(c.TotalNetSalePriceExtended, 0)) AS TotalPartCost
		FROM #tmpSOPartTblV1 main
		--LEFT JOIN CTE_Cost c ON main.SalesOrderPartId = c.SalesOrderPartId;
  END TRY
  BEGIN CATCH
  SELECT
    ERROR_NUMBER() AS ErrorNumber, ERROR_STATE() AS ErrorState, ERROR_SEVERITY() AS ErrorSeverity, ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,ERROR_MESSAGE() AS ErrorMessage;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[GetSalesOrderPartView]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END