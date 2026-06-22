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
	23    07/01/2026   Rajesh Gami		Added MasterCompanyId Parameter While Calling UOM Conversion Function
	24    13/05/2026   Bhargav Saliya	Modified UOM Changes [pn-15067]
	25    14/06/2026   Bhargav Saliya	Select Consume UOM [PN-16224]
	26    18/06/2026   Bhargav Saliya	Added Case For Skip UOM Function If FROM uom and TO uom Both are Same

-- EXEC [DBO].[GetSalesOrderPartView] 10850,0
**************************************************************/
CREATE PROCEDURE [dbo].[GetSalesOrderPartView]
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
	DECLARE @LOTNumber VARCHAR(100) = ISNULL((SELECT LotNumber FROM dbo.LOT WITH(NOLOCK) WHERE LotId = (SELECT ISNULL(LotId,0) FROM dbo.SalesOrder WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId)),'')
	-- Set SoPart null for all part for salesordor otherwise for perticular part only.
	IF(ISNULL(@SoPartId,0) = 0)
	BEGIN
		SET @SoPartId = NULL;
	END

		IF OBJECT_ID(N'tempdb..#tmpSOPartTblV1') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSOPartTblV1
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
                -- CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN Stk.QtyOrder ELSE part.QtyOrder END AS Qty,
		  CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL 
		          THEN (CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(Stk.[QtyOrder], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(Stk.[QtyOrder],0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END)
			   ELSE (CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(part.[QtyOrder], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.[QtyOrder],0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END) END AS Qty, 			
                -- part.QtyRequested,
		(CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(part.[QtyRequested], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.[QtyRequested],0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END) QtyRequested,
                -- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitSalesPrice, 0) ELSE ISNULL(PS.UnitSalesPrice, 0) END AS UnitSalePrice,
                  CASE WHEN SC.SalesOrderStocklineId IS NOT NULL 
		   THEN (CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SC.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.UnitSalesPrice, 0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		   ELSE (CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(PS.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.UnitSalesPrice, 0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		   END AS UnitSalePrice,
		-- NEED TO DISCUSS --
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarkUpPercentage, 0) ELSE ISNULL(PS.MarkUpPercentage, 0) END MarkUpPercentage,
                0 SalesBeforeDiscount,
		-- NEED TO DISCUSS --
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.DiscountPercentage, 0) ELSE ISNULL(PS.DiscountPercentage, 0) END Discount,
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL 
		THEN (CASE WHEN ISNULL(stk.QtyOrder,0) > 0 THEN (
			ISNULL(SC.DiscountAmount, 0)
			/ NULLIF(CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(stk.[QtyOrder], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.[QtyOrder], 0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END, 0)
		) ELSE 0 END) 
		ELSE (CASE WHEN ISNULL(part.QtyOrder,0) > 0 THEN (
			ISNULL(PS.DiscountAmount, 0)
			/ NULLIF(CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(part.[QtyOrder], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.[QtyOrder], 0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END, 0)
		) ELSE 0 END) END DiscountAmount,                
		-- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS NetSales,
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
                -- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitCost, 0) ELSE ISNULL(PS.UnitCost, 0) END UnitCost,
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL 
		THEN (CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SC.UnitCost, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.UnitCost, 0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		ELSE (CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(PS.UnitCost, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.UnitCost, 0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		END [UnitCost],
                -- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitSalesPriceExtended, 0) ELSE ISNULL(PS.UnitSalesPriceExtended, 0) END AS SalesPriceExtended,
                CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitSalesPriceExtended, 0) ELSE ISNULL(PS.UnitSalesPriceExtended, 0) END [SalesPriceExtended],
		-- ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarkUpAmount, 0) ELSE ISNULL(PS.MarkUpAmount, 0) END) * stk.QtyOrder), 0) MarkupExtended,                
		ISNULL(CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.MarkUpAmount ELSE PS.MarkUpAmount END, 0) [MarkupExtended],
	        -- ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.DiscountAmount, 0) ELSE ISNULL(PS.DiscountAmount, 0) END) * stk.QtyOrder), 0) SalesDiscountExtended,                
	       	ISNULL(CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.DiscountAmount ELSE PS.DiscountAmount END, 0) [SalesDiscountExtended], 	  
	        --   ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END) * stk.QtyOrder), 0) NetSalePriceExtended,                
	        ISNULL(CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.NetSaleAmount END, 0) [NetSalePriceExtended], 	
		-- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitCostExtended, 0) ELSE ISNULL(PS.UnitCostExtended, 0) END UnitCostExtended,
		ISNULL(CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.UnitCostExtended ELSE PS.UnitCostExtended END, 0) [UnitCostExtended],     	        
	        --   CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarginAmount, 0) ELSE ISNULL(PS.MarginAmount, 0) END MarginAmount,
                CASE WHEN SC.SalesOrderStocklineId IS NOT NULL 
		THEN (CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SC.MarginAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.MarginAmount, 0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		ELSE (CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(PS.MarginAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.MarginAmount, 0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		END [MarginAmount], 	  
		-- ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarginAmount, 0) ELSE ISNULL(PS.MarginAmount, 0) END) * stk.QtyOrder), 0) MarginAmountExtended,                
		ISNULL(((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL 
		THEN (CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SC.MarginAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.MarginAmount, 0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		ELSE (CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(PS.MarginAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.MarginAmount, 0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END) END)
		* (CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(stk.[QtyOrder], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.[QtyOrder],0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END)), 0)
		[MarginAmountExtended], 	
		-- NEED TO DISCUSS --
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.MarginPercentage, 0) ELSE ISNULL(PS.MarginPercentage, 0) END AS MarginPercentage,
                ISNULL(fcu.Code, '') AS CurrencyDescription,
                part.CurrencyId,
                part.ConditionId,
                ISNULL(cp.Description, '') AS ConditionDescription,
                ISNULL(qs.IdNumber, '') AS IdNumber,
                ISNULL(qs.TraceableToName, '') AS TraceableToName,
                ISNULL(qs.CertifiedBy, '') AS CertifiedBy,
                ISNULL(qs.ObtainFromName, '') AS ObtainFrom,
                ISNULL(q.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
                ISNULL(q.OpenDate, GETDATE()) AS QuoteDate,
                -- ISNULL(qs.QuantityAvailable, 0) AS QtyAvailable,
                -- ISNULL(qs.QuantityOnHand, 0) AS QuantityOnHand,
                ISNULL(iu.ShortName, '') AS UOM,
                -- ISNULL(Stk.QtyReserved, NULL) AS QtyReserved,
		(CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(Stk.[QtyReserved], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(Stk.[QtyReserved],0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END) [QtyReserved],
                CASE 
                        WHEN EXISTS (SELECT 1 FROM DBO.SalesOrderApproval WITH (NOLOCK) WHERE SalesOrderPartId = part.SalesOrderPartId AND IsDeleted = 0 AND CustomerStatusId = @ApprovedStatus) 
                        THEN 1 ELSE 0 
                END AS IsApproved,
                ISNULL(SO.SalesOrderQuoteId, '') AS CustomerReference,
                -- ISNULL(imx.ExportECCN, '') AS ECCN,
                ISNULL(imx.ITARNumber, '') AS ITAR,
                ISNULL(iu.ShortName, '') AS UomName,
                part.CustomerRequestDate,
                part.PromisedDate,
                part.EstimatedShipDate,
		CASE WHEN Stk.PriorityId IS NOT NULL THEN Stk.PriorityId ELSE ISNULL(part.PriorityId, @DefaultPriorityId) END AS PriorityId,
		CASE WHEN Stk.PriorityId IS NOT NULL THEN prit.Description ELSE ISNULL(pri.Description, @DefaultPriorityName) END AS PriorityName,
		CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN ISNULL(Stk.StatusId,@DefaultStatusId) ELSE ISNULL(part.StatusId,@DefaultStatusId) END StatusId,
		ISNULL((SELECT Description FROM SOPartStatus WHERE SOPartStatusId = (CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN ISNULL(Stk.StatusId,@DefaultStatusId) ELSE ISNULL(part.StatusId,@DefaultStatusId) END) ), @DefaultStatusName) AS StatusName,                	
		-- ISNULL((SELECT SUM(QtyToShip) FROM DBO.SOPickTicket WHERE SalesOrderId = part.SalesOrderId AND SalesOrderPartId = part.SalesOrderPartId AND IsActive = 1 AND IsDeleted = 0), 0) AS QtyToShip,
		ISNULL((SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM([QtyToShip]), 0) ELSE [dbo].[fn_ConvertUOM](SUM([QtyToShip]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END FROM [dbo].[SOPickTicket] WITH(NOLOCK) WHERE [SalesOrderId] = part.[SalesOrderId] AND [SalesOrderPartId] = part.[SalesOrderPartId] AND [IsActive] = 1 AND [IsDeleted] = 0), 0) AS QtyToShip,                
		CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN Stk.Notes ELSE part.Notes END Notes,
                -- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN (CASE WHEN ISNULL(stk.QtyOrder,0) >0 THEN (ISNULL(SC.MarkUpAmount, 0) / stk.QtyOrder) ELSE 0 END) ELSE(CASE WHEN ISNULL(part.QtyOrder,0) > 0 THEN (ISNULL(PS.MarkUpAmount, 0) / part.QtyOrder) ELSE 0 END) END MarkupPerUnit,
                CASE WHEN SC.SalesOrderStocklineId IS NOT NULL 
		THEN (CASE WHEN ISNULL(stk.QtyOrder,0) > 0 THEN (
			ISNULL(SC.MarkUpAmount, 0)
			/ NULLIF(CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(stk.[QtyOrder], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(stk.[QtyOrder],0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END, 0)
		) ELSE 0 END) 
		ELSE (CASE WHEN ISNULL(part.QtyOrder,0) > 0 THEN (
			ISNULL(PS.MarkUpAmount, 0)
			/ NULLIF(CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(part.[QtyOrder], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.[QtyOrder],0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END, 0)
		) ELSE 0 END) END MarkupPerUnit, 				
		-- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS GrossSalePricePerUnit,
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS [GrossSalePricePerUnit],                
		-- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS GrossSalePrice,
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END AS [GrossSalePrice],
                0 AS TaxPercentage,
                '' TaxType,
                -- ISNULL(PS.TaxAmount, 0) AS TaxAmount,
		(CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(PS.TaxAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.TaxAmount, 0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END) [TaxAmount],
                ISNULL(part.AltOrEqType,'') AltOrEqType, 		
                ISNULL((SELECT SUM(BillingAmount) FROM SalesOrderFreight WHERE SalesOrderId = part.SalesOrderId AND ItemMasterId = part.ItemMasterId AND ConditionId = part.ConditionId AND IsActive = 1 AND IsDeleted = 0), 0) AS Freight,
                ISNULL((SELECT SUM(BillingAmount) FROM SalesOrderCharges WHERE SalesOrderId = part.SalesOrderId AND ItemMasterId = part.ItemMasterId AND ConditionId = part.ConditionId AND IsActive = 1 AND IsDeleted = 0), 0) AS Misc,
                CASE 
                        WHEN itemMaster.IsPma = 1 AND itemMaster.IsDER = 1 THEN 'PMA&DER'
                        WHEN itemMaster.IsPma = 1 THEN 'PMA'
                        WHEN itemMaster.IsDER = 1 THEN 'DER'
                        ELSE 'OEM'
                END AS StockType,
                0 AS ItemNo,
                part.POId,
                part.PONumber,
                part.PONextDlvrDate,
                rop.RepairOrderPartRecordId AS ROId,
                ro.RepairOrderNumber AS RONumber,
                rop.EstRecordDate,
                --   (CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.UnitSalesPrice, 0) ELSE ISNULL(PS.UnitSalesPrice, 0) END) UnitSalesPricePerUnit,                
                (CASE WHEN SC.SalesOrderStocklineId IS NOT NULL 
		THEN (CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SC.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.UnitSalesPrice, 0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		ELSE (CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(PS.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.UnitSalesPrice, 0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		END) UnitSalesPricePerUnit,
		itemMaster.ItemClassificationName AS ItemClassification,
                itemMaster.ItemGroup,
                rop.EstRecordDate AS roNextDlvrDate,
		-- CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN
		-- 	(SELECT ISNULL(SUM(Stkl.QuantityAvailable),0) FROM DBO.Stockline Stkl WITH (NOLOCK) WHERE Stkl.StockLineId = Stk.StockLineId)  
		-- ELSE
		-- 	(SELECT ISNULL(SUM(Stk.QuantityAvailable),0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0)))  
		-- END StkQtyAvailable,
		CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN
			(SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM(Stkl.[QuantityAvailable]), 0) ELSE [dbo].[fn_ConvertUOM](SUM(Stkl.[QuantityAvailable]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END			
			FROM DBO.Stockline Stkl WITH (NOLOCK) WHERE Stkl.StockLineId = Stk.StockLineId)  
		ELSE
			(SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM(Stk.[QuantityAvailable]), 0) ELSE [dbo].[fn_ConvertUOM](SUM(Stk.[QuantityAvailable]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END
			FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0)))  
		END StkQtyAvailable, 	
		-- (SELECT ISNULL(SUM(Stk.QuantityAvailable),0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0))) QtyAvailable,
		(SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM(Stk.[QuantityAvailable]), 0) ELSE [dbo].[fn_ConvertUOM](SUM(Stk.[QuantityAvailable]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END FROM [dbo].[Stockline] Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0))) [QtyAvailable],
		  	       
		-- CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN
		-- 	(SELECT ISNULL(SUM(Stkl.QuantityOnHand),0) FROM DBO.Stockline Stkl WITH (NOLOCK) WHERE Stkl.StockLineId = Stk.StockLineId)  
		-- ELSE
		-- 	(SELECT ISNULL(SUM(Stk.QuantityOnHand),0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0)))  
		-- END StkQuantityOnHand,
		CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN
			(SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM(Stkl.[QuantityOnHand]), 0) ELSE [dbo].[fn_ConvertUOM](SUM(Stkl.[QuantityOnHand]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END			
			FROM dbo.Stockline Stkl WITH (NOLOCK) WHERE Stkl.StockLineId = Stk.StockLineId)  
		ELSE
			(SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM(Stk.[QuantityOnHand]), 0) ELSE [dbo].[fn_ConvertUOM](SUM(Stk.[QuantityOnHand]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END
			FROM dbo.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0)))  
		END StkQuantityOnHand, 				
		-- (SELECT ISNULL(SUM(Stk.QuantityOnHand),0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0))) QuantityOnHand,
		
		   (SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM(Stk.[QuantityOnHand]), 0) ELSE [dbo].[fn_ConvertUOM](SUM(Stk.[QuantityOnHand]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END FROM dbo.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = part.ItemMasterId AND Stk.ConditionId = part.ConditionId AND Stk.IsParent = 1 AND ((Stk.IsRepairManagement = 1) OR ((Stk.IsRepairManagement = 0 OR Stk.IsRepairManagement IS NULL) AND Stk.IsCustomerStock = 0))) QuantityOnHand,
		  	       
		-- (SELECT SUM(sosi.QtyShipped) FROM DBO.SalesOrderShipping sos WITH (NOLOCK) 
		-- LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId
		-- LEFT JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SOPickTicketId = sosi.SOPickTicketId
		-- WHERE sos.SalesOrderId = @SalesOrderId AND sopt.SalesOrderPartStocklineId = Stk.SalesOrderStocklineId AND sos.IsActive = 1 AND sos.IsDeleted = 0) qtyShipped, 	
		
		(SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM(sosi.[QtyShipped]), 0) ELSE [dbo].[fn_ConvertUOM](SUM(sosi.[QtyShipped]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END	
		   FROM DBO.SalesOrderShipping sos WITH (NOLOCK) 
		   LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId
		   LEFT JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SOPickTicketId = sosi.SOPickTicketId
		   WHERE sos.SalesOrderId = @SalesOrderId AND sopt.SalesOrderPartStocklineId = Stk.SalesOrderStocklineId AND sos.IsActive = 1 AND sos.IsDeleted = 0) qtyShipped,
		
		-- (SELECT SUM(sobi.QtyBilled) FROM DBO.BillingInvoicing sob WITH (NOLOCK) LEFT JOIN DBO.BillingInvoicingItems sobi WITH (NOLOCK) ON sob.BillingInvoicingId = sobi.BillingInvoicingId
		-- WHERE sob.ModuleId = @soModuleId AND sob.ReferenceId = @SalesOrderId AND sobi.StocklineId = stk.StockLineId AND sobi.SubReferenceId = part.SalesOrderPartId AND ISNULL(sob.IsActive,0) = 1 AND ISNULL(sob.IsDeleted,0) = 0 AND ISNULL(sobi.IsVersionIncrease,0) = 0 AND ISNULL(sobi.IsPerformaInvoice,0) = 0) qtyInvoiced,
		
		(SELECT CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SUM(sobi.[QtyBilled]), 0) ELSE [dbo].[fn_ConvertUOM](SUM(sobi.[QtyBilled]), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 0, part.MasterCompanyId) END	
		FROM DBO.BillingInvoicing sob WITH (NOLOCK) LEFT JOIN DBO.BillingInvoicingItems sobi WITH (NOLOCK) ON sob.BillingInvoicingId = sobi.BillingInvoicingId
		WHERE sob.ModuleId = @soModuleId AND sob.ReferenceId = @SalesOrderId AND sobi.StocklineId = stk.StockLineId AND sobi.SubReferenceId = part.SalesOrderPartId AND ISNULL(sob.IsActive,0) = 1 AND ISNULL(sob.IsDeleted,0) = 0 AND ISNULL(sobi.IsVersionIncrease,0) = 0 AND ISNULL(sobi.IsPerformaInvoice,0) = 0) qtyInvoiced,
		
		(SELECT TOP 1 sob.InvoiceDate FROM DBO.BillingInvoicing sob WITH (NOLOCK) LEFT JOIN DBO.BillingInvoicingItems sobi WITH (NOLOCK) ON sob.BillingInvoicingId = sobi.BillingInvoicingId
		WHERE sob.ModuleId = @soModuleId AND sob.ReferenceId = @SalesOrderId AND sobi.StocklineId = stk.StockLineId AND   sobi.SubReferenceId = part.SalesOrderPartId AND ISNULL(sob.IsActive,0) = 1 AND ISNULL(sob.IsDeleted,0) = 0 AND ISNULL(sobi.IsVersionIncrease,0) = 0 AND ISNULL(sobi.IsPerformaInvoice,0) = 0) invoiceDate,
		
		(SELECT TOP 1 sob.InvoiceNo FROM DBO.BillingInvoicing sob WITH (NOLOCK) LEFT JOIN DBO.BillingInvoicingItems sobi WITH (NOLOCK) ON sob.BillingInvoicingId = sobi.BillingInvoicingId
		WHERE sob.ModuleId = @soModuleId AND sob.ReferenceId = @SalesOrderId AND sobi.StocklineId = stk.StockLineId AND sobi.SubReferenceId = part.SalesOrderPartId AND ISNULL(sob.IsActive,0) = 1 AND ISNULL(sob.IsDeleted,0) = 0 AND ISNULL(sobi.IsVersionIncrease,0) = 0 AND ISNULL(sobi.IsPerformaInvoice,0) = 0) invoiceNumber,
		
		(SELECT TOP 1 sos.SOShippingNum FROM DBO.SalesOrderShipping sos WITH (NOLOCK) LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId
		WHERE sos.SalesOrderId = @SalesOrderId AND sosi.SalesOrderPartId = part.SalesOrderPartId AND sos.IsActive = 1 AND sos.IsDeleted = 0) shipReference,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.ECCN ELSE part.ECCN END ECCN,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.HSCODE ELSE part.HSCODE END HSCODE,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.[Weight] ELSE part.[Weight] END [Weight],
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.SizeLength ELSE part.SizeLength END SizeLength,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.SizeWidth ELSE part.SizeWidth END SizeWidth,
		CASE WHEN Stk.StockLineId IS NOT NULL THEN Stk.SizeHeight ELSE part.SizeHeight END SizeHeight,

		(CASE WHEN ISNULL(part.ItemMasterId,0) != 0 AND ISNULL(part.ItemMasterId,0) != ISNULL(qs.ItemMasterId,0) THEN qs.PartNumber ELSE '' END) as RevisedPN,
		(CASE WHEN ISNULL(part.ItemMasterId,0) != 0 AND ISNULL(part.ItemMasterId,0) != ISNULL(qs.ItemMasterId,0) THEN qs.ItemMasterId ELSE 0 END) as RevisedPNItemMasterId,
		CASE WHEN @LOTNumber = '' THEN '' ELSE (CASE WHEN (SELECT LotId FROM dbo.LotTransInOutDetails LTI WHERE LTI.LotId = SO.LotId AND LTI.StockLineId = Stk.StockLineId ) > 0 THEN @LOTNumber ELSE '' END) END  AS LotNumber, 	
		-- CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmountPerUnit, 0) ELSE ISNULL(PS.NetSaleAmountPerUnit, 0) END AS netSalesPricePerUnit,
		CASE WHEN SC.SalesOrderStocklineId IS NOT NULL 
		THEN (CASE WHEN ISNULL(qs.[StockUnitOfMeasure],'') = ISNULL(qs.[ConsumeUnitOfMeasure],'') THEN ISNULL(SC.NetSaleAmountPerUnit, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SC.NetSaleAmountPerUnit, 0), qs.[StockUnitOfMeasure], qs.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		ELSE (CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(PS.NetSaleAmountPerUnit, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(PS.NetSaleAmountPerUnit, 0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END)
		END AS [netSalesPricePerUnit], 	   	   
		-- part.UnitSalesPrice MainUnitSalesPrice,
		(CASE WHEN ISNULL(itemMaster.[StockUnitOfMeasure],'') = ISNULL(itemMaster.[ConsumeUnitOfMeasure],'') THEN ISNULL(part.[UnitSalesPrice],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(part.[UnitSalesPrice],0), itemMaster.[StockUnitOfMeasure], itemMaster.[ConsumeUnitOfMeasure], 1, part.MasterCompanyId) END) MainUnitSalesPrice, 	
		-- ISNULL((CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(PS.NetSaleAmount, 0) END), 0) NetSalePriceExtendedPart
		ISNULL(CASE WHEN SC.SalesOrderStocklineId IS NOT NULL THEN SC.NetSaleAmount ELSE PS.NetSaleAmount END, 0) AS [NetSalePriceExtendedPart]

		INTO #tmpSOPartTblV1    
        FROM DBO.SalesOrderPartV1 part WITH (NOLOCK)
        LEFT JOIN DBO.SalesOrderStocklineV1 Stk WITH (NOLOCK) ON part.SalesOrderPartId = Stk.SalesOrderPartId
	LEFT JOIN DBO.SalesOrderPartCost PS WITH (NOLOCK) ON PS.SalesOrderPartId = part.SalesOrderPartId
        LEFT JOIN DBO.SalesOrderStockLineCost SC WITH (NOLOCK) ON SC.SalesOrderStocklineId = Stk.SalesOrderStocklineId
        LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON part.SalesOrderId = SO.SalesOrderId
        LEFT JOIN DBO.StockLine qs WITH (NOLOCK) ON Stk.StockLineId = qs.StockLineId
        LEFT JOIN DBO.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
        LEFT JOIN DBO.ItemMasterExportInfo imx WITH (NOLOCK) ON itemMaster.ItemMasterId = imx.ItemMasterId
        LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON itemMaster.ManufacturerId = mf.ManufacturerId
        LEFT JOIN DBO.Condition cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
	LEFT JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuotePartId = part.SalesOrderQuotePartId
        LEFT JOIN DBO.SalesOrderQuote q WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = q.SalesOrderQuoteId
        LEFT JOIN DBO.UnitOfMeasure iu WITH (NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
        -- LEFT JOIN DBO.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
        LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON qs.PurchaseOrderId = po.PurchaseOrderId
        LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON qs.RepairOrderId = ro.RepairOrderId
        LEFT JOIN DBO.[Priority] pri WITH (NOLOCK) ON part.PriorityId = pri.PriorityId
        LEFT JOIN DBO.[Priority] prit WITH (NOLOCK) ON prit.PriorityId = Stk.PriorityId
        LEFT JOIN DBO.RepairOrderPart rop WITH (NOLOCK) ON qs.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
        LEFT JOIN DBO.Currency fcu WITH (NOLOCK) ON part.CurrencyId = fcu.CurrencyId AND fcu.IsActive = 1 AND fcu.IsDeleted = 0
        WHERE part.SalesOrderId = @SalesOrderId 
	AND (@SoPartId IS NULL OR part.SalesOrderPartId = @SoPartId)
        AND ISNULL(part.IsDeleted,0) = 0
        AND ISNULL(rop.isAsset, 0) = 0
	ORDER BY part.SalesOrderPartId;

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
			main.*,
			(((main.QtyRequested - ISNULL(c.TotalQtyQuoted, 0)) * ISNULL(main.MainUnitSalesPrice, 0))
			    + ISNULL(c.TotalNetSalePriceExtended, 0)) AS TotalPartCost
		FROM #tmpSOPartTblV1 main
		LEFT JOIN CTE_Cost c ON main.SalesOrderPartId = c.SalesOrderPartId;

    END TRY
    BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS ErrorNumber,   ERROR_STATE() AS ErrorState,   ERROR_SEVERITY() AS ErrorSeverity,   ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine, ERROR_MESSAGE() AS ErrorMessage;
        DECLARE @ErrorLogID int,
                        @DatabaseName varchar(100) = DB_NAME(),
                        ----------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------
                        @AdhocComments varchar(150) = '[GetSalesOrderPartView]',
                        @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100)),
                        @ApplicationName varchar(100) = 'PAS'
        ---------PLEASE DO NOT EDIT BELOW---------
        EXEC Splogexception @DatabaseName = @DatabaseName,
                                                @AdhocComments = @AdhocComments,
                                                @ProcedureParameters = @ProcedureParameters,
                                                @ApplicationName = @ApplicationName,
                                                @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END