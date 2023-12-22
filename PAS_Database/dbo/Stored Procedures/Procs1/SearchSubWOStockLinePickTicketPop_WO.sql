/*************************************************************           
 ** File:   [SearchSubWOStockLinePickTicketPop_WO]           
 ** Author:   
 ** Description: This SP is Used to get Stockline list for Pick Ticket for sub wo   
 ** Purpose:         
 ** Date:     
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------  
	1										
	2    09/20/2023   Devendra Shekh        pick ticket qty issue resovled 
	3    09/20/2023   Devendra Shekh        changes for partwise data

EXEC DBO.SearchSubWOStockLinePickTicketPop_WO @ItemMasterIdlist=20751,@ConditionId=10,@WorkOrderId=3555,@SubWorkOrderId=222,@IsMultiplePickTicket=0,@SubWOPartNoId=231
**************************************************************/ 
CREATE   PROCEDURE [dbo].[SearchSubWOStockLinePickTicketPop_WO]
	@ItemMasterIdlist BIGINT, 
	@ConditionId BIGINT,
	@WorkOrderId BIGINT,
	@SubWorkOrderId BIGINT,
	@IsMultiplePickTicket bit = 0,
	@SubWOPartNoId BIGINT,
	@SubWorkOrderMaterialsId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @ConditionGroup VARCHAR(50);
		DECLARE @MasterCompanyId INT;
		

		IF OBJECT_ID(N'tempdb..#ConditionGroup') IS NOT NULL
		BEGIN
			DROP TABLE #ConditionGroup 
		END

		CREATE TABLE #ConditionGroup 
		(
			ID BIGINT NOT NULL IDENTITY, 
			[ConditionId] [bigint] NULL
		)

		SELECT @MasterCompanyId = MasterCompanyId FROM dbo.SubWorkOrderPartNumber WITH (NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId
		SELECT @ConditionGroup = C.GroupCode FROM dbo.Condition C WITH (NOLOCK) WHERE C.ConditionId = @ConditionId AND C.MasterCompanyId = @MasterCompanyId
			
		INSERT INTO #ConditionGroup (ConditionId)
		SELECT ConditionId FROM dbo.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND GroupCode = @ConditionGroup

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF(@IsMultiplePickTicket = 1)
				BEGIN
					SELECT DISTINCT
						wom.SubWorkOrderMaterialsId
						,im.PartNumber
						,sl.StockLineId
						,im.ItemMasterId As PartId
						,im.ItemMasterId As ItemMasterId
						,im.PartDescription AS Description
						,wom.SubWorkOrderMaterialsId as WorkOrderMaterialsId
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
						,(ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.SubWorkorderPickTicket wopt WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
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
					LEFT JOIN DBO.SubWorkOrderMaterialStockLine wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
					LEFT JOIN DBO.SubWorkOrderMaterials wom WITH (NOLOCK) on wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId
					LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
					LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
					LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
					LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
					LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
					LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
					LEFT JOIN DBO.SubWorkorderPickTicket Pick WITH (NOLOCK) ON Pick.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId AND ISNULL(Pick.IsKitType, 0) = 0
					LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
					INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
							AND Smf.StockLineId = sl.StockLineId
					WHERE 
						--im.ItemMasterId = @ItemMasterIdlist AND 
						wo.WorkOrderId=@WorkOrderId AND wom.SubWorkOrderId = @SubWorkOrderId AND ISNULL(wom.QuantityReserved,0) > 0
						AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) > 0)
						AND wom.SubWOPartNoId = @SubWOPartNoId
						AND
						((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.SubWorkorderPickTicket wopt WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0)) >0

				UNION ALL

					SELECT DISTINCT
						wom.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
						im.PartNumber
						,sl.StockLineId
						,im.ItemMasterId As PartId
						,im.ItemMasterId As ItemMasterId
						,im.PartDescription AS Description
						,wom.SubWorkOrderMaterialsKitId as WorkOrderMaterialsId
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
						,(ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.SubWorkorderPickTicket wopt WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsKitId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
						,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
						,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
						,ISNULL(sl.UnitCost, 0) AS unitCost
						,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
								WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
								WHEN sl.TraceableToType = 9 THEN leTraceble.Name
								WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
						ELSE '' END AS TracableToName
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
						LEFT JOIN DBO.SubWorkOrderMaterialStockLineKit wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
						LEFT JOIN DBO.SubWorkOrderMaterialsKit wom WITH (NOLOCK) on wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId
						LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
						LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
						LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
						LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
						LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
						LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
						LEFT JOIN DBO.SubWorkorderPickTicket Pick WITH (NOLOCK) ON Pick.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsKitId AND ISNULL(Pick.IsKitType, 0) = 1
						LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
						INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
								AND Smf.StockLineId = sl.StockLineId
					WHERE 
						wo.WorkOrderId=@WorkOrderId AND wom.SubWorkOrderId = @SubWorkOrderId AND ISNULL(wom.QuantityReserved,0) > 0
						AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) > 0)
						AND wom.SubWOPartNoId = @SubWOPartNoId
						AND 
						((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.SubWorkorderPickTicket wopt WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsKitId AND wmsl.StockLineId = wopt.StockLineId  ),0)) >0

				END
				ELSE
				BEGIN
					SELECT DISTINCT
						wom.SubWorkOrderMaterialsId
						,im.PartNumber
						,sl.StockLineId
						,im.ItemMasterId As PartId
						,im.ItemMasterId As ItemMasterId
						,im.PartDescription AS Description
						,wom.SubWorkOrderMaterialsId as WorkOrderMaterialsId
						,ig.Description AS ItemGroup
						,mf.Name AS Manufacturer
						,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
						,wmsl.ConditionId
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
						,(ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.SubWorkorderPickTicket wopt WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
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
					JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) 
						--AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
						--						THEN @ConditionId ELSE sl.ConditionId 
						--						END
					LEFT JOIN DBO.SubWorkOrderMaterialStockLine wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
					LEFT JOIN DBO.SubWorkOrderMaterials wom WITH (NOLOCK) on wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId
					LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
					--LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
					LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
					LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
					LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
					LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
					LEFT JOIN DBO.SubWorkorderPickTicket Pick WITH (NOLOCK) ON Pick.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId AND ISNULL(Pick.IsKitType, 0) = 0
					LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
					INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
							AND Smf.StockLineId = sl.StockLineId
					WHERE 
						--im.ItemMasterId = @ItemMasterIdlist AND 
						wo.WorkOrderId=@WorkOrderId AND wom.SubWorkOrderId = @SubWorkOrderId AND ISNULL(wom.QuantityReserved,0) > 0
						AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) > 0)
							AND wom.SubWOPartNoId = @SubWOPartNoId
							AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
							AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.SubWorkorderPickTicket wopt WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0)) >0
				
				UNION ALL
								
					SELECT DISTINCT
						wom.SubWorkOrderMaterialsKitId AS SubWorkOrderMaterialsId,
						im.PartNumber
						,sl.StockLineId
						,im.ItemMasterId As PartId
						,im.ItemMasterId As ItemMasterId
						,im.PartDescription AS Description
						,wom.SubWorkOrderMaterialsKitId as WorkOrderMaterialsId
						,ig.Description AS ItemGroup
						,mf.Name AS Manufacturer
						,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
						,wmsl.ConditionId
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
						,(ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.SubWorkorderPickTicket wopt WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsKitId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
						,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
						,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
						,ISNULL(sl.UnitCost, 0) AS unitCost
						,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
							  WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
							  WHEN sl.TraceableToType = 9 THEN leTraceble.Name
							  WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
						ELSE '' END AS TracableToName
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
						JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup) 
							--AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
							--						THEN @ConditionId ELSE sl.ConditionId 
							--						END
						LEFT JOIN DBO.SubWorkOrderMaterialStockLineKit wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
						LEFT JOIN DBO.SubWorkOrderMaterialsKit wom WITH (NOLOCK) on wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId
						LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
						--LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
						LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
						LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
						LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
						LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
						LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
						LEFT JOIN DBO.SubWorkorderPickTicket Pick WITH (NOLOCK) ON Pick.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsKitId AND ISNULL(Pick.IsKitType, 0) = 1
						LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
						INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
								AND Smf.StockLineId = sl.StockLineId
					WHERE 
						--im.ItemMasterId = @ItemMasterIdlist AND 
						wo.WorkOrderId=@WorkOrderId AND wom.SubWorkOrderId = @SubWorkOrderId AND ISNULL(wom.QuantityReserved,0) > 0
						AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) > 0)
							AND wom.SubWOPartNoId = @SubWOPartNoId
							AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId
						AND ((ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) FROM dbo.SubWorkorderPickTicket wopt WITH (NOLOCK) WHERE wopt.SubWorkOrderMaterialsId = wom.SubWorkOrderMaterialsKitId AND wmsl.StockLineId = wopt.StockLineId  ),0)) > 0

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