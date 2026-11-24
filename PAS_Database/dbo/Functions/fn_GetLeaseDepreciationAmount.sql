/*************************************************************
 ** File:   [fn_GetLeaseDepreciationAmount]
 ** Author:  Kishor Makwana
 ** Description: Depreciation of ONE lease stockline for ONE accounting period. Used by USP_CreateBatch_DepreciableLeaseStockline (journal) and
 **              SaveLeaseDepreciationData (history) so both always post the same amount (the Asset process has the same two steps:
 **              USP_CreateBatch_DepreciableAssetInventory + SaveAssetDeprciationData).
 ** Purpose:     Source tables = LeaseStockline / LeaseHeader / Stockline instead of AssetInventory:
 **              Cost               = Stockline.UnitCost x lease qty (LeaseStockline.QtyOrder)
 **              Life / Frequency / Method / Residual % = Item Master Asset setup (ItemMaster.AssetDeprNonDeprTangibleAssetsId -> vw_DeprNonDeprTangibleAssets)
 **              Depreciation       = (Cost - Cost x Residual % / 100) / Life x 1 (monthly) / 3 (quarterly) / 12 (yearly), never more than what is left to depreciate
 **              AlreadyDepreciated = 1 when the period already has a LeaseDepreciationHistory row
 ** Change History
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    17/11/2026     Kishor Makwana          Created (Process Depreciation - Lease)
************************************************************************/
CREATE   FUNCTION [dbo].[fn_GetLeaseDepreciationAmount]
(
	@LeaseStocklineId BIGINT,
	@SelectedAccountingPeriodId BIGINT
)
RETURNS TABLE
AS
RETURN
(
	SELECT	LSL.LeaseStocklineId, LSL.LeaseHeaderId, LSL.StockLineId AS StocklineId, ISNULL(LSL.StocklineNumber, STK.StockLineNumber) AS StocklineNumber, LSL.SN AS SerialNo,
			LSL.ItemMasterId, LSL.PN AS PartNumber, LSL.StartDate AS InServiceDate, LSL.MasterCompanyId,
			LH.LeaseNumber, LH.CustomerId, LH.ManagementStructureId, CURR.Code AS CurrencyCode,
			X.Cost, ISNULL(dnd.AssetLife, 0) AS Life, CAST(ISNULL(dnd.ResidualPercentageName, 0) AS DECIMAL(18,6)) AS ResidualPercentage,
			UPPER(dnd.DepreciationFrequencyName) AS FrequencyName, UPPER(dnd.DepreciationMethodName) AS MethodName,
			ISNULL(P.AccumlatedDepr, 0) AS PrevAccum,
			CASE WHEN ISNULL(dnd.AssetLife, 0) <= 0 OR X.Cost <= 0 OR C.Remaining <= 0 THEN CAST(0 AS DECIMAL(18,6))
				 WHEN C.Monthly * C.Months > C.Remaining THEN CAST(C.Remaining AS DECIMAL(18,6))
				 ELSE CAST(C.Monthly * C.Months AS DECIMAL(18,6)) END AS DepreciationAmount,
			C.Depreciable AS DepreciableAmount,
			CAST(CASE WHEN EXISTS (SELECT 1 FROM [dbo].[LeaseDepreciationHistory] H WITH (NOLOCK)
								   WHERE H.LeaseStocklineId = LSL.LeaseStocklineId AND H.AccountingCalenderId = @SelectedAccountingPeriodId AND H.IsDelete = 0)
					  THEN 1 ELSE 0 END AS BIT) AS AlreadyDepreciated
	FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
	INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.LeaseHeaderId = LSL.LeaseHeaderId
	INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.StockLineId = LSL.StockLineId
	INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = LSL.ItemMasterId
	INNER JOIN [dbo].[vw_DeprNonDeprTangibleAssets] dnd WITH (NOLOCK) ON dnd.DeprNonDeprTangibleAssetsId = IM.AssetDeprNonDeprTangibleAssetsId
	LEFT JOIN [dbo].[Currency] CURR WITH (NOLOCK) ON CURR.CurrencyId = LH.LocalCurrencyId
	CROSS APPLY (SELECT CAST(ISNULL(STK.[UnitCost], 0) * LSL.[QtyOrder] AS DECIMAL(18,6)) AS Cost) X
	OUTER APPLY (SELECT TOP 1 H.AccumlatedDepr FROM [dbo].[LeaseDepreciationHistory] H WITH (NOLOCK)
				 WHERE H.LeaseStocklineId = LSL.LeaseStocklineId AND H.IsDelete = 0 ORDER BY H.ID DESC) P
	CROSS APPLY (
		SELECT (X.Cost - (X.Cost * ISNULL(dnd.ResidualPercentageName, 0) / 100.0)) AS Depreciable,
			   (X.Cost - (X.Cost * ISNULL(dnd.ResidualPercentageName, 0) / 100.0)) / NULLIF(dnd.AssetLife, 0) AS Monthly,
			   (X.Cost - (X.Cost * ISNULL(dnd.ResidualPercentageName, 0) / 100.0)) - ISNULL(P.AccumlatedDepr, 0) AS Remaining,
			   CASE WHEN UPPER(dnd.DepreciationFrequencyName) IN ('QUATERLY', 'QTLY') THEN 3
					WHEN UPPER(dnd.DepreciationFrequencyName) IN ('YEARLY', 'YRLY') THEN 12
					ELSE 1 END AS Months
	) C
	WHERE LSL.LeaseStocklineId = @LeaseStocklineId
)