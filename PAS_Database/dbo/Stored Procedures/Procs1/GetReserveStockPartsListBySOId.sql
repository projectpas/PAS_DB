
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
	7    01/27/2025   Vishal Suthar		Fixed for issue when Qty is adjusted.
	8    05-01-2025	  ABHISHEK JIRAWLA  Allow Repair Management Customer Stock Stockline
	9    12/31/2025   Moin Bloch		UOM Related Changes
   	10   07/01/2026   Rajesh Gami		Added MasterCompanyId Parameter While Calling UOM Conversion Function  
	11   10-06-2026	  Rajesh Gami		Getting LOTID from the Stockline instead of PART PN-[16681] 
	12	 18/06/2026	  Ayushi			[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
 exec DBO.GetReserveStockPartsListBySOId @SalesOrderId=10851
**************************************************************/
CREATE     PROC [dbo].[GetReserveStockPartsListBySOId]
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
				--SOP.QtyRequested,
				(CASE WHEN ISNULL(itm.StockUnitOfMeasure,'') = ISNULL(itm.ConsumeUnitOfMeasure,'') THEN ISNULL(SOP.QtyRequested,0) ELSE dbo.fn_ConvertUOM(ISNULL(SOP.QtyRequested,0),itm.StockUnitOfMeasure,itm.ConsumeUnitOfMeasure,0,SOP.MasterCompanyId) END) AS QtyRequested,
				--SOP.QtyReserved,
				(CASE WHEN ISNULL(itm.StockUnitOfMeasure,'') = ISNULL(itm.ConsumeUnitOfMeasure,'') THEN ISNULL(SOP.QtyReserved,0) ELSE dbo.fn_ConvertUOM(ISNULL(SOP.QtyReserved,0),itm.StockUnitOfMeasure,itm.ConsumeUnitOfMeasure,0,SOP.MasterCompanyId) END) AS QtyReserved,
				SOP.LotId,
				SOP.IsLotAssigned,
				--(SELECT ISNULL(SUM(Stk.QtyOrder), 0) 
				-- FROM DBO.SalesOrderStocklineV1 Stk WITH (NOLOCK) 
				-- WHERE Stk.SalesOrderPartId = SOP.SalesOrderPartId) AS TotalQtyOrder
				 (SELECT SUM(CASE WHEN ISNULL(qs.StockUnitOfMeasure,'') = ISNULL(qs.ConsumeUnitOfMeasure,'') THEN ISNULL(Stk.QtyOrder,0) ELSE dbo.fn_ConvertUOM(ISNULL(Stk.QtyOrder,0),qs.StockUnitOfMeasure,qs.ConsumeUnitOfMeasure,0,Stk.MasterCompanyId) END) 
				 FROM dbo.SalesOrderStocklineV1 Stk WITH (NOLOCK) 
				 LEFT JOIN dbo.StockLine qs WITH (NOLOCK) ON Stk.StockLineId = qs.StockLineId
				 WHERE Stk.SalesOrderPartId = SOP.SalesOrderPartId) AS TotalQtyOrder
			FROM 
				dbo.SalesOrderPartV1 SOP WITH (NOLOCK)
				LEFT JOIN dbo.ItemMaster itm WITH (NOLOCK) ON SOP.ItemMasterId = itm.ItemMasterId
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
		--(ISNULL(sop.QtyRequested, 0) - 
		-- ISNULL(sop.QtyReserved, 0) - 
		-- (SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
		--  WHERE SOSI.SalesOrderPartId = SOP.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) AS QtyToBeReserved,
		 (ISNULL(sop.QtyRequested, 0) - ISNULL(sop.QtyReserved, 0) - 		 
		 (SELECT ISNULL(CASE WHEN ISNULL(MAX(itm.StockUnitOfMeasure),'') = ISNULL(MAX(itm.ConsumeUnitOfMeasure),'') THEN SUM(ISNULL(SOSI.QtyShipped,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(SOSI.QtyShipped,0)),MAX(itm.StockUnitOfMeasure),MAX(itm.ConsumeUnitOfMeasure),0,MAX(SOS.MasterCompanyId)) END,0)
		 FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
		  INNER JOIN dbo.SalesOrderShippingItem SOSI WITH (NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
		   LEFT JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOSI.SalesOrderPartId 
		   LEFT JOIN dbo.ItemMaster itm WITH (NOLOCK) ON SOP.ItemMasterId = itm.ItemMasterId
		  WHERE SOSI.SalesOrderPartId = SOP.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) AS QtyToBeReserved,
		  (ISNULL(sop.QtyRequested, 0) - ISNULL(sop.QtyReserved, 0) - 
		 --(SELECT ISNULL(SUM(SOSI.QtyShipped), 0) 
		 (SELECT ISNULL(CASE WHEN ISNULL(MAX(itm.StockUnitOfMeasure),'') = ISNULL(MAX(itm.ConsumeUnitOfMeasure),'') THEN SUM(ISNULL(SOSI.QtyShipped,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(SOSI.QtyShipped,0)),MAX(itm.StockUnitOfMeasure),MAX(itm.ConsumeUnitOfMeasure),0,MAX(SOS.MasterCompanyId)) END,0)		 
		 FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) 
		 INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
		 INNER JOIN DBO.SOPickTicket SOPick ON SOPick.SOPickTicketId = SOSI.SOPickTicketId
		 LEFT JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOSI.SalesOrderPartId 
		 LEFT JOIN dbo.ItemMaster itm WITH (NOLOCK) ON SOP.ItemMasterId = itm.ItemMasterId
		  WHERE SOPick.SalesOrderPartStocklineId = Stk.SalesOrderStocklineId AND SOS.SalesOrderId = @SalesOrderId)) AS StkQtyToBeReserved,
		ISNULL(sop.QtyReserved, 0) AS QuantityReserved,
		--ISNULL(sl.QuantityAvailable, 0)  AS QuantityAvailable, 
		(CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.QuantityAvailable,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.QuantityAvailable,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,SO.MasterCompanyId) END) AS QuantityAvailable,
		--ISNULL(sl.QuantityOnHand, 0) AS QuantityOnHand,
		(CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.QuantityOnHand,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.QuantityOnHand,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,SO.MasterCompanyId) END) AS QuantityOnHand,
		--ISNULL((SELECT ISNULL(Part.QtyRequested, 0)
		--FROM DBO.SalesOrderPartV1 Part WITH (NOLOCK)
		--LEFT JOIN dbo.ItemMaster itm WITH (NOLOCK) ON Part.ItemMasterId = itm.ItemMasterId
		--WHERE Part.SalesOrderPartId = SOP.SalesOrderPartId), 0) PartQuantityOnOrder,
		ISNULL((SELECT CASE WHEN ISNULL(itm.StockUnitOfMeasure,'') = ISNULL(itm.ConsumeUnitOfMeasure,'') THEN ISNULL(Part.QtyRequested,0) ELSE dbo.fn_ConvertUOM(ISNULL(Part.QtyRequested,0),itm.StockUnitOfMeasure,itm.ConsumeUnitOfMeasure,0,SO.MasterCompanyId) END		
		FROM DBO.SalesOrderPartV1 Part WITH (NOLOCK) 
		 LEFT JOIN dbo.ItemMaster itm WITH (NOLOCK) ON Part.ItemMasterId = itm.ItemMasterId
		WHERE Part.SalesOrderPartId = SOP.SalesOrderPartId), 0) PartQuantityOnOrder,
		--ISNULL((SELECT ISNULL(SUM(StkV1.QtyOrder), 0) FROM DBO.SalesOrderStocklineV1 StkV1 WITH (NOLOCK) WHERE StkV1.SalesOrderPartId = SOP.SalesOrderPartId ), 0) QuantityOnOrder, --AND StkV1.StockLineId = SL.StockLineId), 0) QuantityOnOrder, 		
		ISNULL((SELECT ISNULL(CASE WHEN ISNULL(MAX(qs.StockUnitOfMeasure),'') = ISNULL(MAX(qs.ConsumeUnitOfMeasure),'') THEN SUM(ISNULL(StkV1.QtyOrder,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(StkV1.QtyOrder,0)),MAX(qs.StockUnitOfMeasure),MAX(qs.ConsumeUnitOfMeasure),0,MAX(StkV1.MasterCompanyId)) END,0)
		FROM dbo.SalesOrderStocklineV1 StkV1 WITH (NOLOCK) 
		LEFT JOIN dbo.StockLine qs WITH (NOLOCK) ON StkV1.StockLineId = qs.StockLineId
		WHERE StkV1.SalesOrderPartId = SOP.SalesOrderPartId ), 0) QuantityOnOrder,		
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
		SL.LotId,
		CASE WHEN ISNULL(SL.LotId,0) > 0 THEN 1 ELSE 0 END AS IsLotQty
		FROM [dbo].[SalesOrder] SO WITH (NOLOCK)
		 LEFT JOIN SalesOrderPartsWithTotalQtyOrder SOP  WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
		 LEFT JOIN [dbo].[SalesOrderStocklineV1] Stk WITH (NOLOCK) ON SOP.SalesOrderPartId = Stk.SalesOrderPartId
		 LEFT JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
		INNER JOIN [dbo].[Customer] C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
		 LEFT JOIN [dbo].[StockLine] SL WITH (NOLOCK) ON ((sl.StockLineId = Stk.StockLineId AND SOP.TotalQtyOrder = SOP.QtyRequested) OR (SOP.TotalQtyOrder < SOP.QtyRequested AND SL.ItemMasterId = SOP.ItemMasterId AND SL.ConditionId = SOP.ConditionId))
		 LEFT JOIN [dbo].[Condition] cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
		 LEFT JOIN [dbo].[SalesOrderReserveParts] SOR WITH (NOLOCK) ON SOR.SalesOrderId = SO.SalesOrderId AND SOR.StockLineId = Stk.StockLineId
		WHERE 
		so.IsDeleted = 0 
		AND so.SalesOrderId = @SalesOrderId
		AND SL.QuantityAvailable > 0
		--AND SL.IsCustomerStock = 0
		AND ((sl.IsRepairManagement = 1) OR ((sl.IsRepairManagement = 0 OR sl.IsRepairManagement IS NULL) AND sl.IsCustomerStock = 0))
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
		Stk.SalesOrderStocklineId,
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
		SL.LotId,
		SOP.TotalQtyOrder,
		sl.[StockUnitOfMeasure],
		sl.[ConsumeUnitOfMeasure]
		)

,FinalReserveList AS(
		SELECT DISTINCT SOP.SalesOrderId, 
		SOP.ItemMasterId, 
		SOP.ConditionId, 
		SOP.Condition, 
		SOP.SalesOrderPartId,
		SOP.PartNumber, 
		SOP.PartDescription,
		SOP.ManufacturerName, 
		SOP.Quantity,
		SOP.ReservedById,
		0 IssuedById,
		SOP.PartStatusId,
		SOP.IsAltPart,
		SOP.IsEquPart,
		ISNULL(SOP.AltPartMasterPartId, 0) AltPartMasterPartId,
		ISNULL(SOP.EquPartMasterPartId, 0) EquPartMasterPartId,
		SOP.QtyToReserve,
		CASE WHEN (SOP.QuantityOnOrder IS NOT NULL AND ISNULL(SOP.QuantityOnOrder,0) > 0 AND ISNULL(SOP.QuantityOnOrder,0) < SOP.QtyToBeReserved)
		THEN (ISNULL(SOP.QuantityOnOrder,0) - ISNULL((CASE WHEN ISNULL(qs.StockUnitOfMeasure,'') = ISNULL(qs.ConsumeUnitOfMeasure,'') THEN ISNULL(Stk.QtyReserved,0) ELSE dbo.fn_ConvertUOM(ISNULL(Stk.QtyReserved,0),qs.StockUnitOfMeasure,qs.ConsumeUnitOfMeasure,0,SOP.MasterCompanyId) END),0))
		ELSE SOP.QtyToBeReserved END QtyToBeReserved,		
		SOP.PartQuantityOnOrder,
		SOP.StkQtyToBeReserved,
		--ISNULL(Stk.QtyReserved, 0) QuantityReserved,
		ISNULL(SOP.QuantityReserved, 0) QuantityReserved,
		ISNULL(SOP.QuantityReserved, 0) TotalReserved,
		SOP.QuantityAvailable, 
		SOP.QuantityOnHand, 
		SOP.QuantityOnOrder, 
		SOP.StockLineId,
		SOP.StockLineNumber, 
		SOP.ControlNumber,
		SOP.StockType,
		SOP.MasterCompanyId,
		SOP.LotId,
		SOP.IsLotQty FROM FinalSalesOrderParts SOP
		LEFT JOIN [dbo].[SalesOrderStocklineV1] Stk WITH(NOLOCK) ON SOP.SalesOrderPartId = Stk.SalesOrderPartId AND SOP.StockLineId = Stk.StockLineId
		LEFT JOIN [dbo].[StockLine] qs WITH (NOLOCK) ON Stk.StockLineId = qs.StockLineId
		)

		SELECT DISTINCT SalesOrderId, 
		ItemMasterId, 
		ConditionId, 
		Condition, 
		SalesOrderPartId,
		PartNumber, 
		PartDescription,
		ManufacturerName, 
		Quantity,
		0 ReservedById,
		IssuedById,
		PartStatusId,
		IsAltPart,
		IsEquPart,
		AltPartMasterPartId,
		EquPartMasterPartId,
		QtyToReserve,
		((CASE WHEN ISNULL(QuantityOnOrder, 0) = 0 THEN QtyToBeReserved ELSE
		CASE WHEN (QuantityReserved - QuantityOnOrder) > 0 THEN QtyToBeReserved ELSE (PartQuantityOnOrder - QuantityReserved) END
		END)
		) QtyToBeReserved,
		StkQtyToBeReserved,
		QuantityReserved,
		TotalReserved,
		QuantityAvailable, 
		QuantityOnHand, 
		QuantityOnOrder, 
		PartQuantityOnOrder,
		StockLineId,
		StockLineNumber, 
		ControlNumber,
		StockType,
		MasterCompanyId,
		LotId,
		IsLotQty FROM FinalReserveList 
		WHERE 
		((CASE WHEN ISNULL(QuantityOnOrder,0) = 0 THEN QtyToBeReserved ELSE
			CASE WHEN (QuantityReserved - PartQuantityOnOrder) > 0 THEN QtyToBeReserved
			ELSE (PartQuantityOnOrder - QuantityReserved - (SELECT ISNULL(CASE WHEN ISNULL(MAX(qs.StockUnitOfMeasure),'') = ISNULL(MAX(qs.ConsumeUnitOfMeasure),'') THEN SUM(ISNULL(SOSI.QtyShipped,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(SOSI.QtyShipped,0)),MAX(qs.StockUnitOfMeasure),MAX(qs.ConsumeUnitOfMeasure),0,MAX(SOS.MasterCompanyId)) END,0)
			--ISNULL(SUM(SOSI.QtyShipped), 0)
			FROM [dbo].[SalesOrderShipping] SOS WITH (NOLOCK) 
			INNER JOIN [dbo].[SalesOrderShippingItem] SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId 
			INNER JOIN [dbo].[SOPickTicket] SOPick ON SOPick.SOPickTicketId = SOSI.SOPickTicketId
			INNER JOIN [dbo].[SalesOrderStocklineV1] Stk ON Stk.SalesOrderStocklineId = SOPick.SalesOrderPartStocklineId
			 LEFT JOIN [dbo].[StockLine] qs WITH (NOLOCK) ON Stk.StockLineId = qs.StockLineId
			WHERE  Stk.StockLineId = FinalReserveList.StockLineId AND SOSI.SalesOrderPartId = FinalReserveList.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) END
		END)) > 0;
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
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100))  
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