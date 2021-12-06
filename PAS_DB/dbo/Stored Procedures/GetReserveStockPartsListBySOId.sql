
-- EXEC [dbo].[GetReserveStockPartsListBySOId] 190
CREATE PROC [dbo].[GetReserveStockPartsListBySOId]
@SalesOrderId  bigint
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		--SELECT DISTINCT so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description as Condition, 0 AS SalesOrderPartId,
		--im.PartNumber, im.PartDescription, CASE WHEN sop.MethodType = 'I' THEN ISNULL(sop.QtyRequested, 0) ELSE ISNULL(sop.Qty, 0) END as Quantity
		--, ISNULL(sor.ReservedById, 0) ReservedById
		--, ISNULL(sor.IssuedById, 0) IssuedById
		--, '1' as PartStatusId
		--, ISNULL(sor.IsAltPart, 0) IsAltPart, ISNULL(sor.IsEquPart, 0) IsEquPart
		--, sor.AltPartMasterPartId, sor.EquPartMasterPartId
		--, 0 AS QtyToReserve
		--, (CASE WHEN sop.MethodType = 'I' THEN ISNULL(sop.QtyRequested, 0) ELSE ISNULL(sop.Qty, 0) END - SUM(ISNULL(sor.TotalReserved, 0))) AS QtyToBeReserved
		--, SUM(ISNULL(sor.TotalReserved, 0)) QuantityReserved
		--, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
		--, sl.StockLineNumber, sl.ControlNumber,
		--CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' ELSE (CASE WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' ELSE (CASE WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER' ELSE 'OEM' END) END) END as StockType
		--,SO.MasterCompanyId
		--FROM SalesOrder SO WITH (NOLOCK)
		--INNER JOIN SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
		--LEFT JOIN ItemMaster im WITH (NOLOCK) on sop.ItemMasterId = im.ItemMasterId
		--INNER JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
		--LEFT JOIN SalesOrderReserveParts SOR WITH (NOLOCK) ON sop.SalesOrderPartId = SOR.SalesOrderPartId
		--LEFT JOIN StockLine SL WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId
		--LEFT JOIN Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
		--WHERE so.IsDeleted = 0 AND sop.IsDeleted = 0 AND so.SalesOrderId = @SalesOrderId
		--AND SL.QuantityAvailable > 0
		--AND SL.ItemMasterId = sop.ItemMasterId
		--AND 
		--((sop.MethodType <> 'I' AND sl.StockLineId = sop.StockLineId)
  --      OR (sop.MethodType = 'I' AND sl.ItemMasterId = sop.ItemMasterId AND sl.ConditionId = sop.ConditionId))
		--GROUP BY so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description,
		--im.PartNumber, im.PartDescription
		--, sor.ReservedById
		--, sor.IssuedById
		--, sor.IsAltPart
		--, sor.AltPartMasterPartId, sor.EquPartMasterPartId
		--, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
		--, sl.QuantityReserved
		--, sl.StockLineNumber, sl.ControlNumber
		--,SO.MasterCompanyId
		--,im.IsPma
		--,im.IsDER
		--, sor.IsAltPart, sor.IsEquPart
		--,sop.QtyRequested
		--,sop.Qty
		--,sop.MethodType
		--Having (CASE WHEN sop.MethodType = 'I' THEN ISNULL(sop.QtyRequested, 0) ELSE ISNULL(sop.Qty, 0) END - SUM(ISNULL(sor.TotalReserved, 0))) > 0
		--Order By Sl.StockLineId



		--SELECT DISTINCT so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description as Condition, 0 AS SalesOrderPartId,
		--im.PartNumber, im.PartDescription, CASE WHEN sop.MethodType = 'I' THEN ISNULL(sop.QtyRequested, 0) ELSE ISNULL(sop.Qty, 0) END as Quantity
		----, ISNULL(sor.ReservedById, 0) ReservedById
		--, (SELECT ISNULL(sor.ReservedById, 0) FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS ReservedById
		----, ISNULL(sor.IssuedById, 0) IssuedById
		--, (SELECT ISNULL(sor.IssuedById, 0) FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS IssuedById
		--, '1' as PartStatusId
		----, ISNULL(sor.IsAltPart, 0) IsAltPart
		--, IsAltPart = ISNULL((SELECT sor.IsAltPart FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId), 0)
		----, ISNULL(sor.IsEquPart, 0) IsEquPart
		--, IsEquPart = ISNULL((SELECT sor.IsEquPart FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId), 0)
		----, sor.AltPartMasterPartId
		--, (SELECT sor.AltPartMasterPartId FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS AltPartMasterPartId
		----, sor.EquPartMasterPartId
		--, (SELECT sor.EquPartMasterPartId FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS EquPartMasterPartId
		--, 0 AS QtyToReserve
		--, (CASE WHEN sop.MethodType = 'I' THEN ISNULL(sop.QtyRequested, 0) ELSE ISNULL(sop.Qty, 0) END - 
		--CASE WHEN sop.MethodType = 'I' THEN 
		--(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM SalesOrderReserveParts SOR WHERE IM.ItemMasterId = SOR.ItemMasterId AND SOR.SalesOrderId = @SalesOrderId)
		--ELSE
		--(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM SalesOrderReserveParts SOR WHERE SOP.StockLineId = SOR.StockLineId AND SOR.SalesOrderId = @SalesOrderId) 
		--END - 
		--(SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId Where SOSI.SalesOrderPartId = SOP.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) AS QtyToBeReserved
		----, SUM(ISNULL(sor.TotalReserved, 0)) QuantityReserved
		--, QuantityReserved = ISNULL((SELECT SUM(sor.TotalReserved) FROM SalesOrderReserveParts SOR WHERE SL.StockLineId = SOR.StockLineId AND SOR.SalesOrderId = @SalesOrderId), 0)
		--, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
		--, sl.StockLineNumber, sl.ControlNumber,
		--CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' ELSE (CASE WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' ELSE (CASE WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER' ELSE 'OEM' END) END) END as StockType
		--,SO.MasterCompanyId
		--FROM SalesOrder SO WITH (NOLOCK)
		--INNER JOIN SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
		--LEFT JOIN ItemMaster im WITH (NOLOCK) on sop.ItemMasterId = im.ItemMasterId
		--INNER JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
		----LEFT JOIN SalesOrderReserveParts SOR WITH (NOLOCK) ON sop.SalesOrderPartId = SOR.SalesOrderPartId
		--LEFT JOIN StockLine SL WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId
		--LEFT JOIN Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
		--WHERE so.IsDeleted = 0 AND sop.IsDeleted = 0 AND so.SalesOrderId = @SalesOrderId
		--AND SL.QuantityAvailable > 0
		--AND SL.ItemMasterId = sop.ItemMasterId
		--AND SL.IsCustomerStock = 0
		--AND SL.IsParent = 1
		--AND 
		--((sop.MethodType <> 'I' AND sl.StockLineId = sop.StockLineId)
  --      OR (sop.MethodType = 'I' AND sl.ItemMasterId = sop.ItemMasterId AND sl.ConditionId = sop.ConditionId))
		--GROUP BY so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description,
		--im.PartNumber, im.PartDescription
		----, sor.ReservedById
		----, sor.IssuedById
		----, sor.IsAltPart
		----, sor.AltPartMasterPartId, sor.EquPartMasterPartId
		--, sl.QuantityAvailable
		--, sl.QuantityOnHand
		--, sl.QuantityOnOrder
		--, sl.StockLineId
		----, sl.QuantityReserved
		--, sl.StockLineNumber, sl.ControlNumber
		--,SO.MasterCompanyId
		--,im.IsPma
		--,im.IsDER
		----, sor.IsAltPart
		----, sor.IsEquPart
		--,sop.QtyRequested
		--,sop.Qty
		--,sop.MethodType
		--,sop.SalesOrderPartId
		--,SOP.StockLineId
		--Having (CASE WHEN sop.MethodType = 'I' THEN ISNULL(sop.QtyRequested, 0) ELSE ISNULL(sop.Qty, 0) END - (SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM SalesOrderReserveParts SOR WHERE SL.StockLineId = SOR.StockLineId AND SOR.SalesOrderId = @SalesOrderId)) > 0
		--Order By Sl.StockLineId

		;WITH CTE AS (SELECT DISTINCT so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description as Condition, 0 AS SalesOrderPartId,
		im.PartNumber, im.PartDescription, CASE WHEN (sop.MethodType = 'I' AND sop.StockLineId is null) THEN ISNULL(sop.QtyRequested, 0) ELSE ISNULL(sop.Qty, 0) END as Quantity
		, (SELECT ISNULL(sor.ReservedById, 0) FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS ReservedById
		, (SELECT ISNULL(sor.IssuedById, 0) FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS IssuedById
		, '1' as PartStatusId
		, IsAltPart = ISNULL((SELECT sor.IsAltPart FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId), 0)
		, IsEquPart = ISNULL((SELECT sor.IsEquPart FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId), 0)
		, (SELECT sor.AltPartMasterPartId FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS AltPartMasterPartId
		, (SELECT sor.EquPartMasterPartId FROM SalesOrderReserveParts SOR WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS EquPartMasterPartId
		, 0 AS QtyToReserve
		, (CASE WHEN (sop.MethodType = 'I' AND sop.StockLineId is null) THEN ISNULL(sop.QtyRequested, 0) ELSE ISNULL(sop.Qty, 0) END - 
		CASE WHEN (sop.MethodType = 'I' AND sop.StockLineId is null) THEN 
		(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM SalesOrderReserveParts SOR WHERE IM.ItemMasterId = SOR.ItemMasterId AND SOR.SalesOrderId = @SalesOrderId)
		ELSE
		(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM SalesOrderReserveParts SOR WHERE SOP.StockLineId = SOR.StockLineId AND SOR.SalesOrderId = @SalesOrderId) 
		END - 
		(SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId Where SOSI.SalesOrderPartId = SOP.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) AS QtyToBeReserved
		, QuantityReserved = ISNULL((SELECT SUM(sor.TotalReserved) FROM SalesOrderReserveParts SOR WHERE SL.StockLineId = SOR.StockLineId AND SOR.SalesOrderId = @SalesOrderId), 0)
		, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
		, sl.StockLineNumber, sl.ControlNumber,
		CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' ELSE (CASE WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' ELSE (CASE WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER' ELSE 'OEM' END) END) END as StockType
		,SO.MasterCompanyId
		FROM SalesOrder SO WITH (NOLOCK)
		INNER JOIN SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
		LEFT JOIN ItemMaster im WITH (NOLOCK) on sop.ItemMasterId = im.ItemMasterId
		INNER JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
		LEFT JOIN StockLine SL WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId
		LEFT JOIN Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
		WHERE so.IsDeleted = 0 AND sop.IsDeleted = 0 AND so.SalesOrderId = @SalesOrderId
		AND SL.QuantityAvailable > 0
		AND SL.ItemMasterId = sop.ItemMasterId
		AND SL.IsCustomerStock = 0
		AND SL.IsParent = 1
		AND 
		((sop.MethodType <> 'I' AND sl.StockLineId = sop.StockLineId)
        OR ((sop.MethodType = 'I' AND sop.StockLineId is null) AND sl.ItemMasterId = sop.ItemMasterId AND sl.ConditionId = sop.ConditionId)
        OR ((sop.MethodType = 'I' AND sl.StockLineId = sop.StockLineId) AND sl.ItemMasterId = sop.ItemMasterId AND sl.ConditionId = sop.ConditionId))
		GROUP BY so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description,
		im.PartNumber, im.PartDescription
		, sl.QuantityAvailable
		, sl.QuantityOnHand
		, sl.QuantityOnOrder
		, sl.StockLineId
		, sl.StockLineNumber, sl.ControlNumber
		,SO.MasterCompanyId
		,im.IsPma
		,im.IsDER
		,sop.QtyRequested
		,sop.Qty
		,sop.MethodType
		,sop.SalesOrderPartId
		,SOP.StockLineId
		Having (
			CASE WHEN (sop.MethodType = 'I') 
				THEN ISNULL(sop.QtyRequested, 0) 
			ELSE ISNULL(sop.Qty, 0) END - 
		(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM SalesOrderReserveParts SOR WHERE SL.StockLineId = SOR.StockLineId AND SOR.SalesOrderId = @SalesOrderId)) > 0
		)

		SELECT * FROM CTE WHERE QtyToBeReserved > 0 ORDER BY StockLineId 
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReserveStockPartsListBySOId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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