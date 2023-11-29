
-- EXEC [dbo].[GetReserveStockPartsListByExchangeSOId] 190
CREATE   PROC [dbo].[GetReserveStockPartsListByExchangeSOId]
@SalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			SELECT DISTINCT so.ExchangeSalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description as Condition, 0 AS ExchangeSalesOrderPartId,
			im.PartNumber, im.PartDescription, 
			im.ManufacturerName ManufacturerName,
			sop.QtyQuoted as Quantity
			, ISNULL(sor.ReservedById, 0) ReservedById
			, ISNULL(sor.IssuedById, 0) IssuedById
			, '1' as PartStatusId
			, ISNULL(sor.IsAltPart, 0) IsAltPart, ISNULL(sor.IsEquPart, 0) IsEquPart
			, sor.AltPartMasterPartId, sor.EquPartMasterPartId
			, 0 AS QtyToReserve
			, (sop.QtyQuoted) - SUM(ISNULL(sor.TotalReserved, 0)) AS QtyToBeReserved
			, SUM(ISNULL(sor.TotalReserved, 0)) QuantityReserved
			, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
			, sl.StockLineNumber, sl.ControlNumber,
			CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' ELSE (CASE WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' ELSE (CASE WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER' ELSE 'OEM' END) END) END as StockType
			,SO.MasterCompanyId
	
			FROM ExchangeSalesOrder SO WITH (NOLOCK)
			INNER JOIN ExchangeSalesOrderPart SOP WITH (NOLOCK) ON SO.ExchangeSalesOrderId = SOP.ExchangeSalesOrderId
			LEFT JOIN ItemMaster im WITH (NOLOCK) on sop.ItemMasterId = im.ItemMasterId
			INNER JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
			LEFT JOIN ExchangeSalesOrderReserveParts SOR WITH (NOLOCK) ON sop.ExchangeSalesOrderPartId = SOR.ExchangeSalesOrderPartId
			LEFT JOIN StockLine SL WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId
			LEFT JOIN Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
			WHERE so.IsDeleted = 0 AND sop.IsDeleted = 0 AND so.ExchangeSalesOrderId = @SalesOrderId
			AND SL.QuantityAvailable > 0
			AND SL.ItemMasterId = sop.ItemMasterId
			AND SL.IsCustomerStock = 0
			AND 
			((sop.MethodType <> 'I' AND sl.StockLineId = sop.StockLineId)
			OR (sop.MethodType = 'I' AND sl.ItemMasterId = sop.ItemMasterId AND sl.ConditionId = sop.ConditionId))
			GROUP BY so.ExchangeSalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description,
			im.PartNumber, im.PartDescription,im.ManufacturerName
			, sor.ReservedById
			, sor.IssuedById
			, sor.IsAltPart
			, sor.AltPartMasterPartId, sor.EquPartMasterPartId
			, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
			, sl.QuantityReserved
			, sl.StockLineNumber, sl.ControlNumber
			,SO.MasterCompanyId
			,im.IsPma
			,im.IsDER
			, sor.IsAltPart, sor.IsEquPart
			,sop.QtyQuoted
			,sop.MethodType
			Having (sop.QtyQuoted) - SUM(ISNULL(sor.TotalReserved, 0)) > 0
			Order By Sl.StockLineId
		END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReserveStockPartsListByExchangeSOId' 
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