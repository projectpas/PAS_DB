/*************************************************************           
 ** File:   [dbo].[SearchStockLinePickTicketPopForRO]          
 ** Author:   Vishal Suthar
 ** Description: Get pick ticket stockline data to pick
 ** Date: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    04/14/2025   Vishal Suthar		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	4	 07/13/2026   Abhishek Jirawla  Added checking for Approval (PN-17234)
EXEC [dbo].[SearchStockLinePickTicketPopForRO] 20751, 1, 2547, 0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[SearchStockLinePickTicketPopForRO]
	@ItemMasterIdlist BIGINT, 
	@ConditionId BIGINT,
	@RepairOrderId BIGINT,
	@IsMultiplePickTicket BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		DECLARE @ApprovalStatusId INT = 0;
		SELECT @ApprovalStatusId = ApprovalStatusId FROM DBO.[ApprovalStatus] WITH(NOLOCK) WHERE Name = 'Approved'

		IF (@IsMultiplePickTicket = 1)
		BEGIN
			SELECT DISTINCT
					rop.RepairOrderPartRecordId RepairOrderPartId
					,im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,rop.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
					END AS StockType
					,sl.StockLineNumber 
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
					,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
					,ISNULL(sl.PurchaseOrderUnitCost, 0) AS unitCost
					,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
							WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
							WHEN sl.TraceableToType = 9 THEN leTraceble.Name
							WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
							ELSE
								''
							END
						 AS TracableToName
						 ,sl.TagDate
						 ,sl.TagType
						 ,sl.CertifiedBy
						 ,sl.CertifiedDate
						 ,sl.Memo
						 ,'Stock Line' AS Method
						 ,'S' AS MethodType
						 ,CONVERT(BIT,0) AS PMA
						 ,Smf.Name as StkLineManufacturer
						 ,((rop.QuantityReserved + 0
						 --(SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) 
							--INNER JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @RepairOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId
							--INNER JOIN SOPickTicket sopi with(nolock) on ship_item.SOPickTicketId = sopi.SOPickTicketId and sopi.SOPickTicketId = Pick.SOPickTicketId)
						 ) - 
						 (SELECT ISNULL(SUM(QtyToShip), 0) FROM ROPickTicket s WITH(NOLOCK) Where s.RepairOrderId = @RepairOrderId AND s.StocklineId = sl.StocklineId)) AS QtyToReserve
				FROM DBO.ItemMaster im  WITH(NOLOCK)
				JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0
				LEFT JOIN DBO.RepairOrderPart rop on rop.ItemMasterId = im.ItemMasterId AND rop.StockLineId = sl.StockLineId AND rop.IsParent = 1
				LEFT JOIN DBO.RepairOrder so WITH(NOLOCK) on so.RepairOrderId = rop.RepairOrderId
				LEFT JOIN DBO.RepairOrderApproval roa WITH (NOLOCK) ON roa.RepairOrderPartId = rop.RepairOrderPartRecordId
				LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
				LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				LEFT JOIN DBO.ROPickTicket Pick WITH(NOLOCK) ON Pick.RepairOrderPartId = rop.RepairOrderPartRecordId and sl.StocklineId = pick.StocklineId
				LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK) INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId WHERE ISNULL(S.IsNonStock,0) = 0) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
				WHERE 
					so.RepairOrderId = @RepairOrderId AND 
					(
						so.IsEnforce IS NULL OR so.IsEnforce = 0
						OR (so.IsEnforce = 1 AND roa.StatusId = @ApprovalStatusId)
						OR (ISNULL(rop.IsPiecePart, 0) = 1)
					) AND
					((rop.QuantityReserved + 0
					--(SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) 
					--	INNER JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @RepairOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId
					--	INNER JOIN ROPickTicket sopi with(nolock) on ship_item.SOPickTicketId = sopi.SOPickTicketId and sopi.SOPickTicketId = Pick.SOPickTicketId)
					) - 
					(SELECT ISNULL(SUM(QtyToShip), 0) FROM ROPickTicket s WITH(NOLOCK) Where s.RepairOrderId = @RepairOrderId AND s.StocklineId = sl.StocklineId)) > 0
		 AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(sl.IsNonStock,0) = 0
		END
		ELSE
		BEGIN
			SELECT DISTINCT
					rop.RepairOrderPartRecordId RepairOrderPartId
					,im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,rop.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS StockType
					,sl.StockLineNumber 
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
					,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
					,ISNULL(sl.PurchaseOrderUnitCost, 0) AS unitCost
					,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
							WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
							WHEN sl.TraceableToType = 9 THEN leTraceble.Name
							WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
							ELSE
								''
							END
						 AS TracableToName
						 ,sl.TagDate
						 ,sl.TagType
						 ,sl.CertifiedBy
						 ,sl.CertifiedDate
						 ,sl.Memo
						 ,'Stock Line' AS Method
						 ,'S' AS MethodType
						 ,CONVERT(BIT,0) AS PMA
						 ,Smf.Name as StkLineManufacturer
						 ,((rop.QuantityReserved + 0
						 -- (SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) 
						 --INNER JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @RepairOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId
						 --INNER JOIN SOPickTicket sopi with(nolock) on ship_item.SOPickTicketId = sopi.SOPickTicketId and sopi.SOPickTicketId = Pick.SOPickTicketId)
						 ) - 
						 (SELECT ISNULL(SUM(QtyToShip), 0) FROM ROPickTicket s WITH(NOLOCK) Where s.RepairOrderId = @RepairOrderId AND s.StocklineId = sl.StocklineId))
						 AS QtyToReserve
				FROM DBO.ItemMaster im  WITH(NOLOCK)
				JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0
				--LEFT JOIN DBO.SalesOrderStocklineV1 stk on stk.StockLineId = sl.StockLineId
				LEFT JOIN DBO.RepairOrderPart rop on rop.ItemMasterId = im.ItemMasterId AND rop.StockLineId = sl.StockLineId AND rop.IsParent = 1
				LEFT JOIN DBO.RepairOrder so WITH(NOLOCK) on so.RepairOrderId = rop.RepairOrderId
				LEFT JOIN DBO.RepairOrderApproval roa WITH (NOLOCK) ON roa.RepairOrderPartId = rop.RepairOrderPartRecordId
				--INNER JOIN DBO.SalesOrderReserveParts sor WITH(NOLOCK) on sor.SalesOrderId = so.RepairOrderId AND sor.SalesOrderPartId = sop.SalesOrderPartId AND SOR.StockLineId = stk.StockLineId
				LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
				LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				LEFT JOIN DBO.ROPickTicket Pick WITH(NOLOCK) ON Pick.RepairOrderPartId = rop.RepairOrderPartRecordId and sl.StockLineId = pick.StockLineId
				LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK) INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId WHERE ISNULL(S.IsNonStock,0) = 0) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
				WHERE 
					im.ItemMasterId = @ItemMasterIdlist AND 
					so.RepairOrderId = @RepairOrderId AND 
					(
						so.IsEnforce IS NULL OR so.IsEnforce = 0
						OR (so.IsEnforce = 1 AND roa.StatusId = @ApprovalStatusId)
						OR (ISNULL(rop.IsPiecePart, 0) = 1)
					) AND
					((rop.QuantityReserved + 0
					--(SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) 
					--	INNER JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @RepairOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId
					--	INNER JOIN SOPickTicket sopi with(nolock) on ship_item.SOPickTicketId = sopi.SOPickTicketId and sopi.SOPickTicketId = Pick.SOPickTicketId)
					) - 
					(SELECT ISNULL(SUM(QtyToShip), 0) FROM ROPickTicket s WITH(NOLOCK) Where s.RepairOrderId = @RepairOrderId AND s.StocklineId = sl.StocklineId)
					) > 0
		 AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(sl.IsNonStock,0) = 0
		END

				
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SearchStockLinePickTicketPopForRO' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''',
													 @Parameter2 = ' + ISNULL(@ConditionId,'') + ',
													 @Parameter3 = ' + ISNULL(@RepairOrderId,'') + ''
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