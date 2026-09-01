/*************************************************************           
 ** File:   [dbo].[SearchStockLinePickTicketPop]          
 ** Author:   Vishal Suthar
 ** Description: Get pick ticket stockline data to pick
 ** Date: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/15/2023   Vishal Suthar		Updated the SP to handle invoice before shipping and versioning
    2    06/21/2023   Vishal Suthar		Updated the SP to include pick ticket even after invoice is created
    3    10/15/2024   Vishal Suthar		Modified SP to get Pick ticket stockline list from new SO Part tables
    4    10/29/2024   Vishal Suthar		Modified SP to get SalesOrderStocklineId
    5    11/15/2024   Vishal Suthar		Fixed issues with listing the stockline
	6	 01/22/2025	  Abhishek Jirawla	Fixed issue related to pick ticket display calculation
	7	 03/13/2025	  Vishal Suthar		Fixed issue with displaying picked records also in the multiple pick ticket create popup
	8    31/10/2025   Amit Ghediya		added for location
    9    30/03/2026   Moin Bloch	    Update (Added UOM Changes)
	10	 18/06/2026	  Ayushi		    [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	11    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	12    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	13    20/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 filters so Non-Stock parts appear on the pick ticket.
	14    31/July/2026			 MOIN BLOCH	  					    [PN-17513] - Added IsNonStock=1 filters so Non-Stock parts not appear on the pick ticket.
	15    03/Aug/2026			 MOIN BLOCH	  					    [PN-17542] - Fix For Non-Stock Non-Service data need to come
	16	 05/Aug/2026			 Kishor Makwana                     [PN-17439] - Added optional @SalesOrderPartId parameter and restored the missing sop.ConditionId = @ConditionId filter in the single-line popup WHERE clause, so duplicate Part+Condition lines (different SalesOrderPartId) are disambiguated correctly instead of showing each other's stockline data.
EXEC [dbo].[SearchStockLinePickTicketPop] 82050, 1, 1318, 0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[SearchStockLinePickTicketPop]
	@ItemMasterIdlist bigint,
	@ConditionId BIGINT,
	@SalesOrderId bigint,
	@IsMultiplePickTicket bit = 0,
	@SalesOrderPartId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	--  [dbo].[SearchStockLinePickTicketPop] 272,1,82,1
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF(@IsMultiplePickTicket =1)
		BEGIN
			SELECT DISTINCT
					sop.SalesOrderPartId
					,stk.SalesOrderStocklineId
					,im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,sop.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS StockType
					--,@MappingType AS MappingType
					,sl.StockLineNumber 
					,sl.[location]
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					--,uom.ShortName AS UomDescription
					--,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
					,ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.QuantityAvailable,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.QuantityAvailable,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QtyAvailable
					--,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
					,ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.QuantityOnHand,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.QuantityOnHand,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QtyOnHand
					--,ISNULL(sl.PurchaseOrderUnitCost, 0) AS unitCost
					,ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.PurchaseOrderUnitCost,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.PurchaseOrderUnitCost,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,1,sl.MasterCompanyId) END),0) AS unitCost
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
					   --,((stk.QtyReserved + 
						 ,((ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(stk.QtyReserved,0) ELSE dbo.fn_ConvertUOM(ISNULL(stk.QtyReserved,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) +

						--(SELECT ISNULL(SUM(ship_item.QtyShipped), 0)
						 (SELECT ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN SUM(ISNULL(ship_item.QtyShipped,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(ship_item.QtyShipped,0)),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0)
										  FROM [dbo].[SalesOrderShipping] ship WITH(NOLOCK)
										  INNER JOIN [dbo].[SalesOrderShippingItem] ship_item WITH(NOLOCK) ON ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @SalesOrderId AND ship_item.SalesOrderPartId = sop.SalesOrderPartId
										  INNER JOIN [dbo].[SOPickTicket] sopi WITH(NOLOCK) ON ship_item.SOPickTicketId = sopi.SOPickTicketId AND sopi.SOPickTicketId = Pick.SOPickTicketId)) -

						 --(SELECT ISNULL(SUM(s.QtyToShip), 0)
						 (SELECT ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN SUM(ISNULL(s.QtyToShip,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(s.QtyToShip,0)),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0)
										 FROM [dbo].[SOPickTicket] s WITH(NOLOCK)
										WHERE s.SalesOrderId = @SalesOrderId AND s.SalesOrderPartStocklineId = stk.SalesOrderStocklineId)) AS QtyToReserve
				FROM [dbo].[ItemMaster] im  WITH(NOLOCK)
				INNER JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0
				 LEFT JOIN [dbo].[SalesOrderStocklineV1] stk WITH(NOLOCK) ON stk.StockLineId = sl.StockLineId
				 LEFT JOIN [dbo].[SalesOrderPartV1] sop ON sop.SalesOrderPartId = stk.SalesOrderPartId
				 LEFT JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
				INNER JOIN [dbo].[SalesOrderReserveParts] sor WITH(NOLOCK) ON sor.SalesOrderId = @SalesOrderId AND sor.SalesOrderPartId = sop.SalesOrderPartId  AND SOR.StockLineId = stk.StockLineId
				 LEFT JOIN [dbo].[Condition] c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				 LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
				 LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				 LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				 LEFT JOIN [dbo].[Customer] cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				 LEFT JOIN [dbo].[Vendor] vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				 LEFT JOIN [dbo].[LegalEntity] leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				 LEFT JOIN [dbo].[SOPickTicket] Pick WITH(NOLOCK) ON Pick.SalesOrderPartId = sop.SalesOrderPartId and stk.SalesOrderStocklineId = pick.SalesOrderPartStocklineId
				 LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK) INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
				WHERE 
				    (ISNULL(im.[IsService],0) <> 1 OR ISNULL(im.[IsNonStock],0) <> 1) AND
					so.SalesOrderId = @SalesOrderId AND 
					((stk.QtyReserved + --sor.QtyToReserve + 
					(SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) 
						INNER JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @SalesOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId
						INNER JOIN SOPickTicket sopi with(nolock) on ship_item.SOPickTicketId = sopi.SOPickTicketId and sopi.SOPickTicketId = Pick.SOPickTicketId)) - 
					(SELECT ISNULL(SUM(QtyToShip), 0) FROM SOPickTicket s WITH(NOLOCK) Where s.SalesOrderId = @SalesOrderId AND s.SalesOrderPartStocklineId = stk.SalesOrderStocklineId)) > 0
		END
		ELSE
		BEGIN
			SELECT DISTINCT
					sop.SalesOrderPartId
					,stk.SalesOrderStocklineId
					,im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,sop.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS StockType
					,sl.StockLineNumber 
					,sl.[location]
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					--,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
					,ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.QuantityAvailable,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.QuantityAvailable,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QtyAvailable
					--,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
					,ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.QuantityOnHand,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.QuantityOnHand,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QtyOnHand
					--,ISNULL(sl.PurchaseOrderUnitCost, 0) AS unitCost
					,ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.PurchaseOrderUnitCost,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.PurchaseOrderUnitCost,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,1,sl.MasterCompanyId) END),0) AS unitCost
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
						--,((sor.QtyToReserve + (SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) 						 
						 ,((ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sor.QtyToReserve,0) ELSE dbo.fn_ConvertUOM(ISNULL(sor.QtyToReserve,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) +
						--(SELECT ISNULL(SUM(ship_item.QtyShipped), 0)
						 (SELECT ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN SUM(ISNULL(ship_item.QtyShipped,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(ship_item.QtyShipped,0)),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0)
										 FROM [dbo].[SalesOrderShipping] ship WITH(NOLOCK)
										INNER JOIN [dbo].[SalesOrderShippingItem] ship_item WITH(NOLOCK) ON ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @SalesOrderId AND ship_item.SalesOrderPartId = sop.SalesOrderPartId
										INNER JOIN [dbo].[SOPickTicket] sopi WITH(NOLOCK) ON ship_item.SOPickTicketId = sopi.SOPickTicketId AND sopi.SOPickTicketId = Pick.SOPickTicketId)) -
						--(SELECT ISNULL(SUM(s.QtyToShip), 0)
						(SELECT ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN SUM(ISNULL(s.QtyToShip,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(s.QtyToShip,0)),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0)
						 FROM [dbo].[SOPickTicket] s WITH(NOLOCK) WHERE s.SalesOrderId = @SalesOrderId AND s.SalesOrderPartStocklineId = stk.SalesOrderStocklineId))
						 AS QtyToReserve
				FROM DBO.ItemMaster im  WITH(NOLOCK)
				JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0
				LEFT JOIN DBO.SalesOrderStocklineV1 stk on stk.StockLineId = sl.StockLineId
				LEFT JOIN DBO.SalesOrderPartV1 sop on sop.SalesOrderPartId = stk.SalesOrderPartId
				LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on so.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.SalesOrderReserveParts sor WITH(NOLOCK) on sor.SalesOrderId = so.SalesOrderId AND sor.SalesOrderPartId = sop.SalesOrderPartId AND SOR.StockLineId = stk.StockLineId
				LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
				LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				LEFT JOIN DBO.SOPickTicket Pick WITH(NOLOCK) ON Pick.SalesOrderPartId = sop.SalesOrderPartId and stk.SalesOrderStocklineId = pick.SalesOrderPartStocklineId
				LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK) INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
				WHERE
				    (ISNULL(im.[IsService],0) <> 1 OR ISNULL(im.[IsNonStock],0) <> 1 ) AND
					im.ItemMasterId = @ItemMasterIdlist AND
					sop.ConditionId = @ConditionId AND
					(@SalesOrderPartId IS NULL OR sop.SalesOrderPartId = @SalesOrderPartId) AND
					so.SalesOrderId = @SalesOrderId AND
					--((sor.QtyToReserve + (SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK)
					((ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sor.QtyToReserve,0) ELSE dbo.fn_ConvertUOM(ISNULL(sor.QtyToReserve,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) +
					(SELECT ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN SUM(ISNULL(ship_item.QtyShipped,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(ship_item.QtyShipped,0)),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0)
									FROM [dbo].[SalesOrderShipping] ship WITH(NOLOCK)
									INNER JOIN [dbo].[SalesOrderShippingItem] ship_item WITH(NOLOCK) ON ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @SalesOrderId AND ship_item.SalesOrderPartId = sop.SalesOrderPartId
									INNER JOIN [dbo].[SOPickTicket] sopi WITH(NOLOCK) ON ship_item.SOPickTicketId = sopi.SOPickTicketId AND sopi.SOPickTicketId = Pick.SOPickTicketId)) -
					--(SELECT ISNULL(SUM(s.QtyToShip), 0)
					(SELECT ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN SUM(ISNULL(s.QtyToShip,0)) ELSE dbo.fn_ConvertUOM(SUM(ISNULL(s.QtyToShip,0)),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0)
									FROM [dbo].[SOPickTicket] s WITH(NOLOCK)
									WHERE s.SalesOrderId = @SalesOrderId AND s.SalesOrderPartStocklineId = stk.SalesOrderStocklineId)
					) > 0
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
            , @AdhocComments     VARCHAR(150)    = 'SearchStockLinePickTicketPop' 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterIdlist, '') AS VARCHAR(100))
												 + '@Parameter2 = ''' + CAST(ISNULL(@ConditionId, '') AS VARCHAR(100)) 
												 + '@Parameter3 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100)) 
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