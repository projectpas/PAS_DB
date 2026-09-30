/*****************************************************************************************           
 ** File:   [RPT_GetCommonBillingInvoicingItems_Lease]           
 ** Author:   Kishor Makwana 
 ** Description: This stored procedure is used to Get the Lease Invoice line-item grid data for
 **              the Lease Invoice SSRS report (LeaseBilling.rdl). 
 ** Purpose:         
 ** Date:   24/SEP/2026     
 ** RETURN VALUE:           
 ******************************************************************************************           
 ** Change History           
 ******************************************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    24/SEP/2026   Kishor Makwana	CREATED [PN-18072]
    2    28/SEP/2026   Kishor Makwana	[PN-17949 follow-up] Time/Cycle billing now persists a base-usage breakdown (TimeUsageQty/Rate/Amount, CycleUsageQty/Rate/Amount) on
	                                        LeaseBillingInvoicingItemDetails alongside the existing overage-only columns, because TimeBillingAmount/CycleBillingAmount now include
	                                        BOTH the base (Min-Max range) usage and the overage, so the old 'Time Overrun'/'Cycle Overrun' rows (Qty=TimeOver, Price=OverageRate,
	                                        Total=TimeBillingAmount) no longer had Qty*Price=Total. Added new 'Time Usage'/'Cycle Usage' line items reading the new persisted
	                                        columns, and tightened the Overrun rows to use TimeOver/CycleOver > 0 (with LineTotal recomputed as TimeOver/CycleOver * OverageRate * Qty)
	                                        so every row's Qty*UnitPrice=Total again. SortOrder renumbered: 1 Flat Rate, 2 Time Usage, 3 Time Overrun, 4 Cycle Usage,
	                                        5 Cycle Overrun, 6 Maintenance, 7 Insurance, 8 Taxes, 9 Other, 10 Charges, 0 fallback.
    
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingItems_Lease] 1,72
********************************************************************************************/
CREATE     PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingItems_Lease]
@BillingInvoicingId BIGINT = NULL,
@ModuleId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @LeaseModuleId INT
		SELECT @LeaseModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'Leasing';

		IF(@ModuleId = @LeaseModuleId) /*********START: LEASE ********/
		BEGIN
			;WITH Base AS (
				SELECT
					BII.[BillingInvoicingItemId],
					BII.[BillingInvoicingId],
					LSL.[LeaseStocklineId] AS SubReferenceId,
					BII.[ItemMasterId],
					UPPER(ISNULL(LSL.[PN], '')) AS PNumber,
					UPPER(ISNULL(LSL.[PNDescription], '')) AS PNDescription,
					UPPER(COALESCE(BII.[SerialNumber], STK.[SerialNumber], LSL.[SN], '')) AS SerialNumber,
					UPPER(ISNULL(LSL.[StocklineNumber], '')) AS StockLineNumber,
					UPPER(COALESCE(IM.[ConsumeUnitOfMeasure], IM.[StockUnitOfMeasure], '')) AS UOM,
					ISNULL(LSL.[QtyReserved], 0) AS Qty,
					COALESCE(LBID.[BillingMethod], LSL.[BillingMethod], '') AS BillingMethod,
					LBID.[FlatRate],
					LBID.[FlatRateAmount],
					LBID.[TimeOver],
					LBID.[TimeOverageRate],
					LBID.[TimeBillingAmount],
					LBID.[CycleOver],
					LBID.[CycleOverageRate],
					LBID.[CycleBillingAmount],
					LBID.[TimeUsageQty],
					LBID.[TimeUsageRate],
					LBID.[TimeUsageAmount],
					LBID.[CycleUsageQty],
					LBID.[CycleUsageRate],
					LBID.[CycleUsageAmount],
					ISNULL(BII.[GrandTotal], 0) AS GrandTotal,
					ISNULL(ChargesAgg.Charges, 0) AS Charges,
					LSL.[Maintenance],
					LSL.[Insurance],
					LSL.[Taxes],
					ISNULL(SC_SUM.OtherComponentAmount, 0) AS OtherComponentAmount
				FROM [dbo].[BillingInvoicingItems] BII WITH(NOLOCK)
				INNER JOIN [dbo].[LeaseStockline] LSL WITH(NOLOCK) ON BII.[SubReferenceId] = LSL.[LeaseStocklineId]
				LEFT JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON BII.[StocklineId] = STK.[StockLineId]
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON BII.[ItemMasterId] = IM.[ItemMasterId]
				LEFT JOIN [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH(NOLOCK) ON LBID.[BillingInvoicingItemId] = BII.[BillingInvoicingItemId] AND ISNULL(LBID.[IsDeleted],0) = 0
				OUTER APPLY (
					SELECT SUM(ISNULL(LC.ExtendedCost, 0)) AS Charges
					FROM [dbo].[LeaseCharges] LC WITH (NOLOCK)
					WHERE LC.LeaseStocklineId = LSL.LeaseStocklineId AND LC.IsDeleted = 0
				) ChargesAgg
				LEFT JOIN (
					SELECT LeaseStocklineId, SUM(ISNULL(Amount, 0)) AS OtherComponentAmount
					FROM [dbo].[LeaseStocklineServiceComponent] WITH (NOLOCK)
					WHERE IsDeleted = 0
					GROUP BY LeaseStocklineId
				) SC_SUM ON SC_SUM.LeaseStocklineId = LSL.LeaseStocklineId
				WHERE BII.[BillingInvoicingId] = @BillingInvoicingId AND ISNULL(BII.[IsDeleted],0) = 0
			),
			Lines AS (
				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Flat Rate' AS LineBillingMethod,
					CAST(Qty AS DECIMAL(18,6)) AS LineQty,
					ISNULL(FlatRate, 0) AS LineUnitPrice,
					FlatRateAmount AS LineTotal,
					1 AS SortOrder
				FROM Base WHERE FlatRateAmount IS NOT NULL

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Time Usage' AS LineBillingMethod,
					CAST(TimeUsageQty AS DECIMAL(18,6)) AS LineQty,
					ISNULL(TimeUsageRate, 0) AS LineUnitPrice,
					TimeUsageAmount AS LineTotal,
					2 AS SortOrder
				FROM Base WHERE TimeUsageQty IS NOT NULL AND TimeUsageQty > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Time Overrun' AS LineBillingMethod,
					CAST(TimeOver AS DECIMAL(18,6)) AS LineQty,
					ISNULL(TimeOverageRate, 0) AS LineUnitPrice,
					ISNULL(TimeOver, 0) * ISNULL(TimeOverageRate, 0) * Qty AS LineTotal,
					3 AS SortOrder
				FROM Base WHERE TimeOver IS NOT NULL AND TimeOver > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Cycle Usage' AS LineBillingMethod,
					CAST(CycleUsageQty AS DECIMAL(18,6)) AS LineQty,
					ISNULL(CycleUsageRate, 0) AS LineUnitPrice,
					CycleUsageAmount AS LineTotal,
					4 AS SortOrder
				FROM Base WHERE CycleUsageQty IS NOT NULL AND CycleUsageQty > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Cycle Overrun' AS LineBillingMethod,
					CAST(CycleOver AS DECIMAL(18,6)) AS LineQty,
					ISNULL(CycleOverageRate, 0) AS LineUnitPrice,
					ISNULL(CycleOver, 0) * ISNULL(CycleOverageRate, 0) * Qty AS LineTotal,
					5 AS SortOrder
				FROM Base WHERE CycleOver IS NOT NULL AND CycleOver > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Maintenance' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Maintenance, 0) AS LineUnitPrice,
					ISNULL(Maintenance, 0) AS LineTotal,
					6 AS SortOrder
				FROM Base WHERE ISNULL(Maintenance, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Insurance' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Insurance, 0) AS LineUnitPrice,
					ISNULL(Insurance, 0) AS LineTotal,
					7 AS SortOrder
				FROM Base WHERE ISNULL(Insurance, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Taxes' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Taxes, 0) AS LineUnitPrice,
					ISNULL(Taxes, 0) AS LineTotal,
					8 AS SortOrder
				FROM Base WHERE ISNULL(Taxes, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Other' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(OtherComponentAmount, 0) AS LineUnitPrice,
					ISNULL(OtherComponentAmount, 0) AS LineTotal,
					9 AS SortOrder
				FROM Base WHERE ISNULL(OtherComponentAmount, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Charges' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Charges, 0) AS LineUnitPrice,
					ISNULL(Charges, 0) AS LineTotal,
					10 AS SortOrder
				FROM Base WHERE ISNULL(Charges, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					CASE BillingMethod
						WHEN 'FlatRateOnly' THEN 'Flat Rate Only'
						WHEN 'FlatRatePlusOverrun' THEN 'Flat Rate + Overrun'
						WHEN 'UsageBased' THEN 'Usage Based'
						ELSE ISNULL(BillingMethod, '')
					END AS LineBillingMethod,
					CAST(Qty AS DECIMAL(18,6)) AS LineQty,
					CAST(0 AS DECIMAL(18,6)) AS LineUnitPrice,
					GrandTotal AS LineTotal,
					0 AS SortOrder
				FROM Base
				WHERE NOT (TimeUsageQty IS NOT NULL AND TimeUsageQty > 0)
				  AND NOT (TimeOver IS NOT NULL AND TimeOver > 0)
				  AND NOT (CycleUsageQty IS NOT NULL AND CycleUsageQty > 0)
				  AND NOT (CycleOver IS NOT NULL AND CycleOver > 0)
				  --FlatRateAmount IS NULL AND (kept out intentionally, same as before)
			)
			SELECT
				ROW_NUMBER() OVER (ORDER BY SubReferenceId, SortOrder) AS ItemNo,
				BillingInvoicingItemId,
				BillingInvoicingId,
				SubReferenceId,
				ItemMasterId,
				PNumber,
				PNDescription,
				SerialNumber,
				StockLineNumber,
				LineBillingMethod AS BillingMethod,
				UOM,
				LineQty AS Qty,
				LineUnitPrice AS UnitPrice,
				LineTotal AS Total
			FROM Lines
			ORDER BY SubReferenceId, SortOrder;
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonBillingInvoicingItems_Lease' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@BillingInvoicingId, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END