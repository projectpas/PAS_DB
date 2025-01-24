/*************************************************************           
 ** File:   [GetReserveStockPartsListBySOId]          
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get the stocklines to be reserved from SO Parts
 ** Purpose:         
 ** Date: 
         
 ** PARAMETERS:
         
 ** RETURN VALUE:           
 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    12/08/2021   Vishal Suthar		Modified the logic
    2    01/10/2024   Vishal Suthar		Modified to make use of New SO Part Tables
    3    11/12/2024   Vishal Suthar		Fixed issues with listing the proper stocklines for reservation
    4    11/13/2024   Vishal Suthar		Fixed issues with stockline after unreserve
    5    01/22/2025   Abhishek Jirawla  Pick Ticket Mismatch
	6    01/24/2025   AMIT GHEDIYA		Fixed for get Reserved list after qty adjust.
     
 exec DBO.GetReserveStockPartsListBySOId @SalesOrderId=1269
**************************************************************/
CREATE    PROC [dbo].[GetReserveStockPartsListBySOId]
	@SalesOrderId  BIGINT,
	@ItemMasterId BIGINT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF(@ItemMasterId = 0) 
		BEGIN
			SET @ItemMasterId = NULL;	
		END

		;WITH SalesOrderPartsWithTotalQtyOrder AS (
			SELECT 
				SOP.SalesOrderPartId,
				SOP.SalesOrderId,
				SOP.ItemMasterId,
				SOP.ConditionId,
				SOP.QtyRequested,
				SOP.QtyReserved,
				SOP.LotId,
				SOP.IsLotAssigned,
				(SELECT ISNULL(SUM(Stk.QtyOrder), 0) 
				 FROM DBO.SalesOrderStocklineV1 Stk WITH (NOLOCK) 
				 WHERE Stk.SalesOrderPartId = SOP.SalesOrderPartId) AS TotalQtyOrder
			FROM 
				DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
		),
		FinalSalesOrderParts AS (SELECT DISTINCT 
		so.SalesOrderId, 
		im.ItemMasterId, 
		sop.ConditionId, 
		cond.Description as Condition, 
		SOP.SalesOrderPartId AS SalesOrderPartId,
		im.PartNumber, 
		im.PartDescription,
		im.ManufacturerName AS ManufacturerName, 
		SOP.QtyRequested AS Quantity,
		ISNULL(sor.ReservedById, 0) AS ReservedById,
		ISNULL(sor.IssuedById, 0) AS IssuedById,
		'1' AS PartStatusId,
		ISNULL(sor.IsAltPart, 0) AS IsAltPart,
		ISNULL(sor.IsEquPart, 0) AS IsEquPart,
		sor.AltPartMasterPartId AS AltPartMasterPartId,
		sor.EquPartMasterPartId AS EquPartMasterPartId,
		0 AS QtyToReserve,
		(ISNULL(sop.QtyRequested, 0) - 
		 ISNULL(sop.QtyReserved, 0) - 
		 (SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
		  WHERE SOSI.SalesOrderPartId = SOP.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) AS QtyToBeReserved,
		ISNULL(sop.QtyReserved, 0) AS QuantityReserved,
		sl.QuantityAvailable, 
		sl.QuantityOnHand, 
		--ISNULL(Stk.QtyOrder, 0) QuantityOnOrder, 
		ISNULL(sop.QtyRequested, 0) QuantityOnOrder,
		--ISNULL((SELECT ISNULL(StkV1.QtyOrder, 0) FROM DBO.SalesOrderStocklineV1 StkV1 WITH (NOLOCK) WHERE StkV1.SalesOrderPartId = SOP.SalesOrderPartId AND StkV1.StockLineId = SL.StockLineId), 0) QuantityOnOrder, 
		sl.StockLineId,
		sl.StockLineNumber, 
		sl.ControlNumber,
		CASE 
			WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' 
			WHEN im.IsPma = 1 THEN 'PMA' 
			WHEN im.IsDER = 1 THEN 'DER' 
			ELSE 'OEM' 
		END AS StockType,
		SO.MasterCompanyId,
		SOP.LotId,
		SOP.IsLotAssigned AS IsLotQty
		FROM DBO.SalesOrder SO WITH (NOLOCK)
		LEFT JOIN SalesOrderPartsWithTotalQtyOrder SOP ON SO.SalesOrderId = SOP.SalesOrderId
		--INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
		LEFT JOIN DBO.SalesOrderStocklineV1 Stk WITH (NOLOCK) ON SOP.SalesOrderPartId = Stk.SalesOrderPartId
		LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
		INNER JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
		LEFT JOIN DBO.StockLine SL WITH (NOLOCK) ON ((sl.StockLineId = Stk.StockLineId AND SOP.TotalQtyOrder = SOP.QtyRequested) OR (SOP.TotalQtyOrder < SOP.QtyRequested AND SL.ItemMasterId = SOP.ItemMasterId AND SL.ConditionId = SOP.ConditionId))
		LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
		LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) ON SOR.SalesOrderId = SO.SalesOrderId AND SOR.StockLineId = Stk.StockLineId
		WHERE 
		so.IsDeleted = 0 
		AND so.SalesOrderId = @SalesOrderId
		AND SL.QuantityAvailable > 0
		AND SL.IsCustomerStock = 0
		AND SL.IsParent = 1
		AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId)
		GROUP BY 
		so.SalesOrderId, 
		im.ItemMasterId, 
		sop.ConditionId, 
		cond.Description,
		im.PartNumber, 
		im.PartDescription,
		im.ManufacturerName, 
		sl.QuantityAvailable,
		sl.QuantityOnHand, 
		Stk.QtyOrder, 
		SOP.QtyRequested,
		SOP.QtyReserved,
		Stk.QtyReserved,
		SOP.SalesOrderPartId,
		sl.StockLineId,
		sl.StockLineNumber, 
		sl.ControlNumber,
		SO.MasterCompanyId,
		im.IsPma,
		im.IsDER,
		SOR.ReservedById,
		SOR.IssuedById,
		SOR.IsAltPart,
		SOR.IsEquPart, 
		SOR.AltPartMasterPartId, 
		SOR.EquPartMasterPartId,
		SOP.LotId,
		SOP.IsLotAssigned,
		SOP.TotalQtyOrder)

		,FinalReserveList AS(
		SELECT DISTINCT SalesOrderId, 
		ItemMasterId, 
		SOP.ConditionId, 
		Condition, 
		SOP.SalesOrderPartId,
		PartNumber, 
		PartDescription,
		ManufacturerName, 
		Quantity,
		ReservedById,
		IssuedById,
		PartStatusId,
		IsAltPart,
		IsEquPart,
		AltPartMasterPartId,
		EquPartMasterPartId,
		QtyToReserve,
		CASE WHEN (QuantityOnOrder IS NOT NULL AND ISNULL(QuantityOnOrder, 0) > 0 AND ISNULL(QuantityOnOrder, 0) < QtyToBeReserved) THEN (ISNULL(QuantityOnOrder, 0) - ISNULL(Stk.QtyReserved, 0)) ELSE QtyToBeReserved END QtyToBeReserved,
		--Quantity - ISNULL(Stk.QtyReserved, 0) AS QtyToBeReserved,
		--CASE WHEN Stk.SalesOrderStocklineId IS NOT NULL THEN ISNULL(Stk.QtyReserved, 0) ELSE QuantityReserved END QuantityReserved,
		ISNULL(Stk.QtyReserved, 0) QuantityReserved,
		ISNULL(QuantityReserved, 0) TotalReserved,
		QuantityAvailable, 
		QuantityOnHand, 
		QuantityOnOrder, 
		SOP.StockLineId,
		SOP.StockLineNumber, 
		ControlNumber,
		StockType,
		SOP.MasterCompanyId,
		LotId,
		IsLotQty FROM FinalSalesOrderParts SOP
		LEFT JOIN DBO.SalesOrderStocklineV1 Stk WITH (NOLOCK) ON SOP.SalesOrderPartId = Stk.SalesOrderPartId AND SOP.StockLineId = Stk.StockLineId)

		SELECT DISTINCT SalesOrderId, 
		ItemMasterId, 
		ConditionId, 
		Condition, 
		SalesOrderPartId,
		PartNumber, 
		PartDescription,
		ManufacturerName, 
		Quantity,
		ReservedById,
		IssuedById,
		PartStatusId,
		IsAltPart,
		IsEquPart,
		AltPartMasterPartId,
		EquPartMasterPartId,
		QtyToReserve,
		((CASE WHEN ISNULL(QuantityOnOrder, 0) = 0 THEN QtyToBeReserved ELSE
		CASE WHEN (QuantityReserved - QuantityOnOrder) > 0 THEN QtyToBeReserved ELSE (QuantityOnOrder - QuantityReserved) END
		END)
		---
		--(SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
		--  WHERE SOSI.SalesOrderPartId = SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)
		)QtyToBeReserved,
		QuantityReserved,
		TotalReserved,
		QuantityAvailable, 
		QuantityOnHand, 
		QuantityOnOrder, 
		StockLineId,
		StockLineNumber, 
		ControlNumber,
		StockType,
		MasterCompanyId,
		LotId,
		IsLotQty FROM FinalReserveList 
		WHERE 
		((CASE WHEN ISNULL(QuantityOnOrder, 0) = 0 THEN QtyToBeReserved ELSE
			CASE WHEN (QuantityReserved - QuantityOnOrder) > 0 THEN QtyToBeReserved 
			ELSE (QuantityOnOrder - QuantityReserved - (SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
				WHERE SOSI.SalesOrderPartId = SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) END
		END)
		---
		--(SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
		--  WHERE SOSI.SalesOrderPartId = SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)
		) 
		> 0;
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