/*************************************************************           
 ** File:   [GetSalesOrderQuotePartView]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Sales Order Quote Part Data
 ** Purpose:         
 ** Date:   09/06/2024
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/06/2024   Vishal Suthar     Created
	2    12-11-2024   Shrey Chandegara  Updated because TraceableToName,tagdate,tagtype not bind. 
	3    13-11-2024   Vishal Suthar		Fixed the QtyAvail and QtyOH
	4    03-12-2024   AMIT GHEDIYA		Fixed Get Saved CurrId from part table.
	5    12-12-2024   Vishal Suthar		Fixed Qty Quoted when no stockline is added
	6    09-01-2025   Amit Ghediya		Modified to get STK level Available & onhnad qty.
  	7    19-SEP-2025  RAJESH GAMI	    Added return field: netSalesPricePerUnit
	8    05-NOV-2025  RAJESH GAMI	    Added return field: TotalPartCost
	9    20-NOV-2025  RAJESH GAMI	    Fixed TotalPartCost Issue
	10   30-MAR-2026  Vishal Suthar	    Fixed Order By clause with order it based on SalesOrderQuotePartId
	11   10-Apr-026   Bhargav Saliya	 UOM Changes
	12   20-MAY-2026  RAJESH GAMI	    Fixed: Get the CustomerStatusId from ApprovalStatus Table instead of Static  [PN-16505]
	13   29/05/2026   Ayushi Patel      [PN-16645]Added default value for @CurrencyDisplayName to handle null currency
    14   18/06/2026   Bhargav Saliya	Added Case For Skip UOM Function If FROM uom and TO uom Both are Same
 EXEC [DBO].[GetSalesOrderQuotePartView] 980, 'USD'
**************************************************************/
CREATE PROCEDURE [dbo].[GetSalesOrderQuotePartView]
    @SalesQuoteId BIGINT,
    @CurrencyDisplayName NVARCHAR(100) = ''
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY

    IF OBJECT_ID(N'tempdb..#tmpSOPartTbl') IS NOT NULL
    BEGIN
        DROP TABLE #tmpSOPartTbl
    END

    SELECT DISTINCT
        part.SalesOrderQuotePartId,
        stk.SalesOrderQuoteStocklineId,
        part.SalesOrderQuoteId,
        part.ItemMasterId,
        stk.StockLineId,
        ISNULL(qs.StockLineNumber, '') AS stockLineNumber,
        part.FxRate,
        CASE WHEN stk.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(stk.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
            ELSE (CASE WHEN
                (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(Part.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(Part.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END) > 0
                THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(Part.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(Part.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
                ELSE (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(Part.QtyRequested, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(Part.QtyRequested, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
            END)
        END AS QtyQuoted,
        (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(part.QtyRequested, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.QtyRequested, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END) AS QtyRequested,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(SC.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.UnitSalesPrice, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
            ELSE (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(PS.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.UnitSalesPrice, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
        END UnitSalePrice,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SC.MarkUpPercentage, 0) ELSE ISNULL(PS.MarkUpPercentage, 0) END MarkUpPercentage,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.DiscountAmount, 0)
            ELSE ISNULL(PS.DiscountAmount, 0)
        END SalesBeforeDiscount,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SC.DiscountPercentage, 0) ELSE ISNULL(PS.DiscountPercentage, 0) END Discount,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (
                ISNULL(SC.DiscountAmount, 0)
                / CASE WHEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(stk.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END) > 0
                    THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(stk.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
                    ELSE 1 END
            )
            ELSE (
                ISNULL(PS.DiscountAmount, 0)
                / CASE WHEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(part.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END) > 0
                    THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(part.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
                    ELSE 1 END
            )
        END DiscountAmount,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.NetSaleAmount, 0)
            ELSE ISNULL(PS.NetSaleAmount, 0)
        END NetSales,
        part.MasterCompanyId,
        part.CreatedBy,
        part.CreatedDate,
        part.UpdatedBy,
        part.UpdatedDate,
        itemMaster.PartNumber,
        itemMaster.PartDescription,
        ISNULL(qs.OEM, 0) AS isOEM,
        itemMaster.IsPma AS isPMA,
        itemMaster.IsDER AS isDER,
        CASE WHEN stk.StockLineId IS NOT NULL THEN 'S' ELSE 'I' END MethodType,
        '' AS Method,
        ISNULL(qs.SerialNumber, '') AS SerialNumber,
        ISNULL(qs.ControlNumber, '') AS ControlNumber,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(SC.UnitCost, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.UnitCost, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
            ELSE (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(PS.UnitCost, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.UnitCost, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
        END UnitCost,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.UnitSalesPriceExtended, 0)
            ELSE ISNULL(PS.UnitSalesPriceExtended, 0)
        END SalesPriceExtended,
        ISNULL(CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.MarkUpAmount, 0)
            ELSE ISNULL(PS.MarkUpAmount, 0)
        END, 0) MarkupExtended,
        ISNULL(CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.DiscountAmount, 0)
            ELSE ISNULL(PS.DiscountAmount, 0)
        END, 0) SalesDiscountExtended,
        ISNULL(CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.NetSaleAmount, 0)
            ELSE ISNULL(PS.NetSaleAmount, 0)
        END, 0) NetSalePriceExtended,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.UnitCostExtended, 0)
            ELSE ISNULL(PS.UnitCostExtended, 0)
        END UnitCostExtended,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(SC.MarginAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.MarginAmount, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
            ELSE (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(PS.MarginAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.MarginAmount, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
        END MarginAmount,
        ISNULL((
            (CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
                THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(SC.MarginAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.MarginAmount, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
                ELSE (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(PS.MarginAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.MarginAmount, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
            END)
            * (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(stk.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
        ), 0) MarginAmountExtended,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SC.MarginPercentage, 0) ELSE ISNULL(PS.MarginPercentage, 0) END MarginPercentage,
        --@CurrencyDisplayName AS CurrencyDescription,
        ISNULL(cp.ConditionId, 0) AS ConditionId,
        ISNULL(cp.Description, '') AS ConditionDescription,
        ISNULL(qs.IdNumber, '') AS IdNumber,
        CASE WHEN EXISTS (
                SELECT 1
                FROM SalesOrderQuoteApproval sqap
                WHERE sqap.SalesOrderQuotePartId = part.SalesOrderQuotePartId 
                  AND sqap.IsDeleted = 0 
                  AND sqap.CustomerStatusId = (SELECT TOP 1 ApprovalStatusId FROM dbo.ApprovalStatus WITH(NOLOCK) WHERE Name = 'Approved' AND ISNULL(isDeleted,0) = 0 AND isActive = 1)
            ) THEN 1 ELSE 0 END AS IsApproved,
        ISNULL(UPPER(itemMaster.ConsumeUnitOfMeasure), '') AS UomName,
        ISNULL(po.PurchaseOrderNumber, '') AS PoNumber,
        ISNULL(ro.RepairOrderNumber, '') AS RoNumber,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.CustomerRequestDate ELSE part.CustomerRequestDate END CustomerRequestDate,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.PromisedDate ELSE part.PromisedDate END AS PromisedDate,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.EstimatedShipDate ELSE part.EstimatedShipDate END AS EstimatedShipDate,
        CASE WHEN part.PriorityId = 0 THEN 2 ELSE part.PriorityId END AS PriorityId,
        CASE WHEN part.PriorityId = 0 THEN 'Routine' ELSE ISNULL(pri.Description, 'Routine') END AS PriorityName,
        ISNULL(part.StatusId, 1) AS StatusId,
        ISNULL(st.Description, 'Open') AS StatusName,
        soq.CustomerReference CustomerReference,
        CASE WHEN stk.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.Notes ELSE part.Notes END AS Notes,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (
                ISNULL(SC.MarkUpAmount, 0)
                / CASE WHEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(stk.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END) > 0
                    THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(stk.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
                    ELSE 1 END
            )
            ELSE (
                ISNULL(PS.MarkUpAmount, 0)
                / CASE WHEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(part.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END) > 0
                    THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(part.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
                    ELSE 1 END
            )
        END MarkupPerUnit,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (
                ISNULL(SC.NetSaleAmount, 0)
                / CASE WHEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(stk.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END) > 0
                    THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(stk.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
                    ELSE 1 END
            )
            ELSE (
                ISNULL(PS.GrossSaleAmount, 0)
                / CASE WHEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(part.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END) > 0
                    THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(part.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.QtyQuoted, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],0,part.MasterCompanyId) END)
                    ELSE 1 END
            )
        END GrossSalePricePerUnit,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.NetSaleAmount, 0)
            ELSE ISNULL(PS.GrossSaleAmount, 0)
        END GrossSalePrice,
        TaxPercentage = 0,--dbo.GetCustomerTaxBaseOnPartDetail(part.SalesOrderQuoteId, part.SalesOrderQuotePartId, soq.CustomerId), 
        '' AS TaxType,
        (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(PS.TaxAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.TaxAmount, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END) AS TaxAmount,
        0 AS QtyPrevQuoted,
        '' AltOrEqType,
        Freight = ISNULL((
            SELECT SUM(sqf.BillingAmount) 
            FROM SalesOrderQuoteFreight sqf
            WHERE sqf.SalesOrderQuoteId = @SalesQuoteId
              AND sqf.ItemMasterId = part.ItemMasterId
              AND sqf.ConditionId = part.ConditionId
              AND sqf.IsActive = 1
              AND sqf.IsDeleted = 0), 0),
        Misc = ISNULL((
            SELECT SUM(sqc.BillingAmount) 
            FROM SalesOrderQuoteCharges sqc
            WHERE sqc.SalesOrderQuoteId = @SalesQuoteId
              AND sqc.ItemMasterId = part.ItemMasterId
              AND sqc.ConditionId = part.ConditionId
              AND sqc.IsActive = 1
              AND sqc.IsDeleted = 0), 0),
        StockType = CASE 
            WHEN itemMaster.IsPma = 1 AND itemMaster.IsDER = 1 THEN 'PMA&DER'
            WHEN itemMaster.IsPma = 1 THEN 'PMA'
            WHEN itemMaster.IsDER = 1 THEN 'DER'
            ELSE 'OEM'
        END,
        CASE WHEN Stk.SalesOrderQuoteStocklineId IS NOT NULL THEN
            (SELECT ISNULL(SUM(Stkl.QuantityAvailable),0) FROM DBO.Stockline Stkl WITH (NOLOCK) WHERE Stkl.StockLineId = Stk.StockLineId) 
        ELSE
            (SELECT ISNULL(SUM(Stk.QuantityAvailable),0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0) 
        END StkQtyAvailable,
        (SELECT SUM(CASE WHEN Stk.[StockUnitOfMeasure] = Stk.[ConsumeUnitOfMeasure] THEN ISNULL(Stk.[QuantityAvailable], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(Stk.[QuantityAvailable], 0),Stk.[StockUnitOfMeasure],Stk.[ConsumeUnitOfMeasure],0,Stk.MasterCompanyId) END)
         FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0) QtyAvailable,
        CASE WHEN Stk.SalesOrderQuoteStocklineId IS NOT NULL THEN
            (SELECT ISNULL(SUM(Stkl.QuantityOnHand),0) FROM DBO.Stockline Stkl WITH (NOLOCK) WHERE Stkl.StockLineId = Stk.StockLineId) 
        ELSE
            (SELECT ISNULL(SUM(Stk.QuantityOnHand),0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0) 
        END StkQuantityOnHand,
        (SELECT SUM(CASE WHEN Stk.[StockUnitOfMeasure] = Stk.[ConsumeUnitOfMeasure] THEN ISNULL(Stk.[QuantityOnHand], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(Stk.[QuantityOnHand], 0),Stk.[StockUnitOfMeasure],Stk.[ConsumeUnitOfMeasure],0,Stk.MasterCompanyId) END)
         FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0) QuantityOnHand,
        part.IsConvertedToSalesOrder,
        0 AS ItemNo,
        (CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(SC.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.UnitSalesPrice, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
            ELSE (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(PS.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.UnitSalesPrice, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
        END) UnitSalesPricePerUnit,
        itemMaster.ItemClassificationName AS ItemClassification,
        itemMaster.ItemGroup,
        ISNULL(mf.Name, '') AS ManufacturerName,
        NULL SalesPriceExpiryDate,
        part.IsNoQuote,
        qs.TraceableToName,
        qs.TagDate,
        qs.TagType,
        ISNULL(fcu.Code, '') AS CurrencyDescription,
        part.CurrencyId,
        CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(SC.NetSaleAmountPerUnit, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.NetSaleAmountPerUnit, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
            ELSE (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(PS.NetSaleAmountPerUnit, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.NetSaleAmountPerUnit, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END)
        END netSalesPricePerUnit,
        (CASE WHEN itemMaster.[StockUnitOfMeasure] = itemMaster.[ConsumeUnitOfMeasure] THEN ISNULL(part.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.UnitSalesPrice, 0),itemMaster.[StockUnitOfMeasure],itemMaster.[ConsumeUnitOfMeasure],1,part.MasterCompanyId) END) MainUnitSalesPrice,
        ISNULL(CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL
            THEN ISNULL(SC.NetSaleAmount, 0)
            ELSE ISNULL(PS.NetSaleAmount, 0)
        END, 0) NetSalePriceExtendedPart

    INTO #tmpSOPartTbl 
    FROM DBO.SalesOrderQuotePartV1 part  WITH (NOLOCK)
    LEFT JOIN DBO.SalesOrderQuoteStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderQuotePartId = part.SalesOrderQuotePartId
    LEFT JOIN DBO.SalesOrderQuotePartCost PS WITH (NOLOCK) ON PS.SalesOrderQuotePartId = part.SalesOrderQuotePartId
    LEFT JOIN DBO.SalesOrderQuoteStockLineCost SC WITH (NOLOCK) ON SC.SalesOrderQuoteStocklineId = stk.SalesOrderQuoteStocklineId
    LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON stk.StockLineId = qs.StockLineId
    INNER JOIN DBO.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
    LEFT JOIN DBO.[Condition] cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
    LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON itemMaster.ManufacturerId = mf.ManufacturerId
    LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
    LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
    LEFT JOIN DBO.Priority pri WITH (NOLOCK) ON part.PriorityId = pri.PriorityId
    LEFT JOIN DBO.SalesOrderQuote soq WITH (NOLOCK) ON part.SalesOrderQuoteId = soq.SalesOrderQuoteId
    LEFT JOIN DBO.SOPartStatus st WITH (NOLOCK) ON part.StatusId = st.SOPartStatusId
    LEFT JOIN DBO.Currency fcu WITH (NOLOCK) ON part.CurrencyId = fcu.CurrencyId AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
    WHERE part.SalesOrderQuoteId = @SalesQuoteId AND part.IsDeleted = 0
    ORDER BY part.SalesOrderQuotePartId;

    /****** Total Part Wise COST Calculation ******/
    ;WITH CTE_Cost AS (
        SELECT 
            SalesOrderQuotePartId,
            SUM(ISNULL(QtyQuoted, 0)) AS TotalQtyQuoted,
            SUM(ISNULL(NetSalePriceExtendedPart, 0)) AS TotalNetSalePriceExtended
        FROM #tmpSOPartTbl
        GROUP BY SalesOrderQuotePartId
    )

    /****** Final Table Return *******/
    SELECT 
        main.*,
        (((main.QtyRequested - ISNULL(c.TotalQtyQuoted, 0)) * ISNULL(main.MainUnitSalesPrice, 0))
          + ISNULL(c.TotalNetSalePriceExtended, 0)) AS TotalPartCost
    FROM #tmpSOPartTbl main
    LEFT JOIN CTE_Cost c ON main.SalesOrderQuotePartId = c.SalesOrderQuotePartId
    ORDER BY main.SalesOrderQuotePartId;

  END TRY

	BEGIN CATCH
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[GetSalesOrderQuotePartView]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesQuoteId, '') AS VARCHAR(100)),
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