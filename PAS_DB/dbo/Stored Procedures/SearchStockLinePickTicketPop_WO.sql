/*************************************************************           
 ** File:   [SearchStockLinePickTicketPop_WO]           
 ** Author:   
 ** Description: This SP is Used to get Stockline list for Pick Ticket    
 ** Purpose:         
 ** Date:     
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------  
	1    03/29/2023   Vishal Suthar		Modified SP for WO Materials KIT Changes

 --exec DBO.SearchStockLinePickTicketPop_WO @ItemMasterIdlist=20343,@ConditionId=7,@WorkOrderId=823,@WorkFlowWorkOrderId=828,@IsMPNPickTicket=0,@IsMultiplePickTicket=0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[SearchStockLinePickTicketPop_WO]
	@ItemMasterIdlist bigint, 
	@workOrderMaterialsId bigint, 
	@ConditionId BIGINT,
	@WorkOrderId bigint,
	@WorkFlowWorkOrderId bigint = 0,
	@IsMPNPickTicket bit = 0,
	@IsMultiplePickTicket bit = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF(@IsMultiplePickTicket = 1)
				BEGIN
					IF(@IsMPNPickTicket = 0)
						BEGIN
							SELECT DISTINCT
							wom.WorkOrderMaterialsId,
								im.PartNumber
								,sl.StockLineId
								,im.ItemMasterId As PartId
								,im.ItemMasterId As ItemMasterId
								,im.PartDescription AS Description
								,ig.Description AS ItemGroup
								,mf.Name AS Manufacturer
								,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
								,c.ConditionId
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
								,ISNULL(wom.QuantityReserved,0) AS QtyToReserve
								,(ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.WorkorderPickTicket wopt WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
								,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
								,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
								,ISNULL(sl.UnitCost, 0) AS unitCost
								,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
										WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
										WHEN sl.TraceableToType = 9 THEN leTraceble.Name
										WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
										ELSE '' END
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
									 ,0 AS IsKitType
							FROM DBO.ItemMaster im WITH (NOLOCK)
							JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
								--AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
								--						THEN @ConditionId ELSE sl.ConditionId 
								--						END
							LEFT JOIN DBO.WorkOrderMaterialStockLine wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
							LEFT JOIN DBO.WorkOrderMaterials wom WITH (NOLOCK) on wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId
							LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
							LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
							LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
							LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
							LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
							LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
							LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
							LEFT JOIN DBO.WorkorderPickTicket Pick WITH (NOLOCK) ON Pick.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(Pick.IsKitType, 0) = 0
							LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
							INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
									AND Smf.StockLineId = sl.StockLineId
							WHERE 
								--im.ItemMasterId = @ItemMasterIdlist AND 
								wo.WorkOrderId=@WorkOrderId AND wom.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(wom.QuantityReserved,0) > 0
								AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) > 0)
								AND 
								((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.WorkorderPickTicket wopt WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0)) >0

							UNION ALL

							SELECT DISTINCT
							wom.WorkOrderMaterialsKitId WorkOrderMaterialsId,
								im.PartNumber
								,sl.StockLineId
								,im.ItemMasterId As PartId
								,im.ItemMasterId As ItemMasterId
								,im.PartDescription AS Description
								,ig.Description AS ItemGroup
								,mf.Name AS Manufacturer
								,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
								,c.ConditionId
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
								,ISNULL(wom.QuantityReserved,0) AS QtyToReserve
								,(ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.WorkorderPickTicket wopt WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
								,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
								,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
								,ISNULL(sl.UnitCost, 0) AS unitCost
								,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
										WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
										WHEN sl.TraceableToType = 9 THEN leTraceble.Name
										WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
										ELSE '' END
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
									 ,1 AS IsKitType
							FROM DBO.ItemMaster im WITH (NOLOCK)
							JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
							LEFT JOIN DBO.WorkOrderMaterialStockLineKit wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
							LEFT JOIN DBO.WorkOrderMaterialsKit wom WITH (NOLOCK) on wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId
							LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
							LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
							LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
							LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
							LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
							LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
							LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
							LEFT JOIN DBO.WorkorderPickTicket Pick WITH (NOLOCK) ON Pick.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND ISNULL(Pick.IsKitType, 0) = 1
							LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
							INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
									AND Smf.StockLineId = sl.StockLineId
							WHERE 
								wo.WorkOrderId=@WorkOrderId AND wom.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(wom.QuantityReserved,0) > 0
								AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) > 0)
								AND 
								((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.WorkorderPickTicket wopt WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND wmsl.StockLineId = wopt.StockLineId  ),0)) >0
						END
						ELSE
							BEGIN
							SELECT DISTINCT
								CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE im.PartNumber END as 'PartNumber',
				                CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE im.PartDescription END as 'Description', 
								--im.PartNumber
								 sl.StockLineId
								,CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE im.ItemMasterId END As PartId
								,CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE im.ItemMasterId END As ItemMasterId
								--,im.PartDescription AS Description
								,ig.Description AS ItemGroup
								,mf.Name AS Manufacturer
								,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
								,c.ConditionId
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
								,ISNULL(sl.UnitCost, 0) AS unitCost
								,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
										WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
										WHEN sl.TraceableToType = 9 THEN leTraceble.Name
										WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
										ELSE '' END
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
								FROM DBO.ItemMaster im  WITH (NOLOCK)
								JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
									--AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
									--						THEN @ConditionId ELSE sl.ConditionId 
									--						END
								LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) on wop.StockLineId = sl.StockLineId
								LEFT JOIN DBO.WorkOrderWorkFlow wowf WITH (NOLOCK) on wop.ID = wowf.WorkFlowWorkOrderId
								LEFT JOIN DBO.WorkOrder so WITH (NOLOCK) on so.WorkOrderId = wop.WorkOrderId
								LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
								LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
								LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
								LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
								LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
								LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
								LEFT JOIN DBO.WOPickTicket Pick WITH (NOLOCK) ON Pick.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK) 
								INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
										AND Smf.StockLineId = sl.StockLineId
								WHERE 
								--im.ItemMasterId = @ItemMasterIdlist AND 
								so.WorkOrderId = @WorkOrderId
							END
				END
				ELSE
				BEGIN
					IF(@IsMPNPickTicket = 0)
						BEGIN
							SELECT DISTINCT
							wom.WorkOrderMaterialsId,
								im.PartNumber
								,sl.StockLineId
								,im.ItemMasterId As PartId
								,im.ItemMasterId As ItemMasterId
								,im.PartDescription AS Description
								,ig.Description AS ItemGroup
								,mf.Name AS Manufacturer
								,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
								,c.ConditionId
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
								,ISNULL(wom.QuantityReserved,0) AS QtyToReserve
								,(ISNULL(wmsl.QtyReserved,0)) - ISNULL((Select SUM(wopt.QtyToShip) + ISNULL(wmsl.QtyIssued,0) from dbo.WorkorderPickTicket wopt WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
								,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
								,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
								,ISNULL(sl.UnitCost, 0) AS unitCost
								,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
										WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
										WHEN sl.TraceableToType = 9 THEN leTraceble.Name
										WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
										ELSE '' END
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
									 ,0 AS IsKitType
							FROM DBO.ItemMaster im WITH (NOLOCK)
							JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
								AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
														THEN @ConditionId ELSE sl.ConditionId 
														END
							LEFT JOIN DBO.WorkOrderMaterialStockLine wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
							LEFT JOIN DBO.WorkOrderMaterials wom WITH (NOLOCK) on wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId
							LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
							LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
							LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
							LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
							LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
							LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
							LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
							LEFT JOIN DBO.WorkorderPickTicket Pick WITH (NOLOCK) ON Pick.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND ISNULL(Pick.IsKitType, 0) = 0
							LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
							INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
									AND Smf.StockLineId = sl.StockLineId
							WHERE 
								--im.ItemMasterId = @ItemMasterIdlist 
								WOM.WorkOrderMaterialsId = @workOrderMaterialsId
								AND wo.WorkOrderId=@WorkOrderId AND ISNULL(wom.QuantityReserved,0) > 0
								AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) > 0)
								AND
								(ISNULL(wmsl.QtyReserved,0) - ISNULL((Select SUM(wopt.QtyToShip) + ISNULL(wmsl.QtyIssued,0) from dbo.WorkorderPickTicket wopt WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0)) > 0

							UNION ALL

							SELECT DISTINCT
							wom.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
								im.PartNumber
								,sl.StockLineId
								,im.ItemMasterId As PartId
								,im.ItemMasterId As ItemMasterId
								,im.PartDescription AS Description
								,ig.Description AS ItemGroup
								,mf.Name AS Manufacturer
								,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
								,c.ConditionId
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
								,ISNULL(wom.QuantityReserved,0) AS QtyToReserve
								,(ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.WorkorderPickTicket wopt WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
								,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
								,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
								,ISNULL(sl.UnitCost, 0) AS unitCost
								,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
										WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
										WHEN sl.TraceableToType = 9 THEN leTraceble.Name
										WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
										ELSE '' END
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
									 ,1 AS IsKitType
							FROM DBO.ItemMaster im WITH (NOLOCK)
							JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
								AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
														THEN @ConditionId ELSE sl.ConditionId 
														END
							LEFT JOIN DBO.WorkOrderMaterialStockLineKit wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
							LEFT JOIN DBO.WorkOrderMaterialsKit wom WITH (NOLOCK) on wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId
							LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
							LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
							LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
							LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
							LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
							LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
							LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
							LEFT JOIN DBO.WorkorderPickTicket Pick WITH (NOLOCK) ON Pick.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND ISNULL(Pick.IsKitType, 0) = 1
							LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
							INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
									AND Smf.StockLineId = sl.StockLineId
							WHERE 
								--im.ItemMasterId = @ItemMasterIdlist 
								WOM.WorkOrderMaterialsKitId = @workOrderMaterialsId
								AND wo.WorkOrderId=@WorkOrderId AND ISNULL(wom.QuantityReserved,0) > 0
								AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) > 0)
								AND
								((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.WorkorderPickTicket wopt WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsKitId AND wmsl.StockLineId = wopt.StockLineId  ),0)) > 0
						END
						ELSE
							BEGIN
							SELECT DISTINCT
								CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE im.PartNumber END as 'PartNumber',
				                CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE im.PartDescription END as 'Description', 
								--im.PartNumber
								 sl.StockLineId
								,CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE im.ItemMasterId END As PartId
								,CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE im.ItemMasterId END As ItemMasterId
								--,im.PartDescription AS Description
								,ig.Description AS ItemGroup
								,mf.Name AS Manufacturer
								,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
								,c.ConditionId
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
								,ISNULL(sl.UnitCost, 0) AS unitCost
								,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
										WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
										WHEN sl.TraceableToType = 9 THEN leTraceble.Name
										WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
										ELSE '' END
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
								FROM DBO.ItemMaster im  WITH (NOLOCK)
								JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
									AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
															THEN @ConditionId ELSE sl.ConditionId 
															END
								LEFT JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK) on wop.StockLineId = sl.StockLineId
								LEFT JOIN DBO.WorkOrderWorkFlow wowf WITH (NOLOCK) on wop.ID = wowf.WorkFlowWorkOrderId
								LEFT JOIN DBO.WorkOrder so WITH (NOLOCK) on so.WorkOrderId = wop.WorkOrderId
								LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
								LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
								LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
								LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
								LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
								LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
								LEFT JOIN DBO.WOPickTicket Pick WITH (NOLOCK) ON Pick.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK) 
								INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
										AND Smf.StockLineId = sl.StockLineId
								WHERE 
								im.ItemMasterId = @ItemMasterIdlist AND 
								so.WorkOrderId = @WorkOrderId
							END
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
              , @AdhocComments     VARCHAR(150)    = 'SearchStockLinePickTicketPop_WO' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END