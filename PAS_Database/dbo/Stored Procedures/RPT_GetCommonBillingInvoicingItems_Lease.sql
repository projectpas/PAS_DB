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
    
--   EXEC [dbo].[RPT_GetCommonBillingInvoicingItems_Lease] 1,72
********************************************************************************************/
CREATE    PROCEDURE [dbo].[RPT_GetCommonBillingInvoicingItems_Lease]
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
					'Time Overrun' AS LineBillingMethod,
					CAST(TimeOver AS DECIMAL(18,6)) AS LineQty,
					ISNULL(TimeOverageRate, 0) AS LineUnitPrice,
					TimeBillingAmount AS LineTotal,
					2 AS SortOrder
				FROM Base WHERE TimeBillingAmount IS NOT NULL

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Cycle Overrun' AS LineBillingMethod,
					CAST(CycleOver AS DECIMAL(18,6)) AS LineQty,
					ISNULL(CycleOverageRate, 0) AS LineUnitPrice,
					CycleBillingAmount AS LineTotal,
					3 AS SortOrder
				FROM Base WHERE CycleBillingAmount IS NOT NULL

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Maintenance' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Maintenance, 0) AS LineUnitPrice,
					ISNULL(Maintenance, 0) AS LineTotal,
					4 AS SortOrder
				FROM Base WHERE ISNULL(Maintenance, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Insurance' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Insurance, 0) AS LineUnitPrice,
					ISNULL(Insurance, 0) AS LineTotal,
					5 AS SortOrder
				FROM Base WHERE ISNULL(Insurance, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Taxes' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Taxes, 0) AS LineUnitPrice,
					ISNULL(Taxes, 0) AS LineTotal,
					6 AS SortOrder
				FROM Base WHERE ISNULL(Taxes, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Other' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(OtherComponentAmount, 0) AS LineUnitPrice,
					ISNULL(OtherComponentAmount, 0) AS LineTotal,
					7 AS SortOrder
				FROM Base WHERE ISNULL(OtherComponentAmount, 0) > 0

				UNION ALL

				SELECT BillingInvoicingItemId, BillingInvoicingId, SubReferenceId, ItemMasterId, PNumber, PNDescription, SerialNumber, StockLineNumber, UOM,
					'Charges' AS LineBillingMethod,
					CAST(1 AS DECIMAL(18,6)) AS LineQty,
					ISNULL(Charges, 0) AS LineUnitPrice,
					ISNULL(Charges, 0) AS LineTotal,
					8 AS SortOrder
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
				WHERE  TimeBillingAmount IS NULL AND CycleBillingAmount IS NULL --FlatRateAmount IS NULL AND
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