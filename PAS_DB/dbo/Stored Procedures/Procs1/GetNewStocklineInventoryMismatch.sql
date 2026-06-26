-- =============================================
-- Author:		HEMNAT SALIYA
-- Create date: 23-12-2024
-- Description:	This stored procedure is used to count UPdate Stockline Inventory mismatch.
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    23-12-2024   HEMNAT SALIYA			Created
	2    02-12-2025   Moin Bloch 			Modified Added MasterCompanyId Parameter 
	3    19-06-2026   Abhishek Jirawla		Adding IsPiecePart condition in RepairOrderPart table 
	
	EXEC [GetNewStocklineInventoryMismatch]
**************************************************************/

CREATE   PROCEDURE [dbo].[GetNewStocklineInventoryMismatch]
	@MasterCompanyId INT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN

			  DECLARE @StocklineId BIGINT;
			  DECLARE @DisplayType INT;
			  --DECLARE @MasterCompanyId VARCHAR(100);
			  
			  
			  --SET @MasterCompanyId = '11, 12, 18, 19, 20'
			  SET @DisplayType = 1
			  
			  DECLARE @WOModule varchar(50) = 'WorkOrder',  @SubWorkOrderModule varchar(50) = 'SubWorkOrder',@SOModule varchar(50) = 'SalesOrder',
			  @ROModule varchar(50) = 'RepairOrder',  @ExchangeModule varchar(50) = 'Exchange',  @RMAModule varchar(50) = 'RMA',  @BulkAdjModule varchar(50) = 'BulkAdjustments';
			  DECLARE @RecordFrom INT;
			  DECLARE @Total int;
			  DECLARE @Count INT;
			  DECLARE @WOCloseStatusId INT;
			  DECLARE @ExchClosedStatusId INT;
			  DECLARE @ExchCancelStatusId INT;
			  DECLARE @ROClosedStatusId INT;
			  DECLARE @ROCancelStatusId INT;
			  DECLARE @RMAShipToVendor INT;
			  DECLARE @RMAReplaced INT;
			  DECLARE @RMARefunded INT;
			  DECLARE @RMACancel INT, @AdjPostedStatusId INT;
			  SET @WOCloseStatusId = (SELECT Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE Description = 'Closed')
			  SET @ROClosedStatusId = (SELECT ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Closed')
			  SET @ExchClosedStatusId = (SELECT ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Closed')
			  SET @ROCancelStatusId = (SELECT ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Canceled')
			  SET @ExchCancelStatusId = (SELECT ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Cancelled')
			  SET @RMAShipToVendor = (SELECT VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Shipped To Vendor')
			  SET @RMAReplaced = (SELECT VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Replaced')
			  SET @RMARefunded = (SELECT VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Refunded')
			  SET @RMACancel = (SELECT VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Canceled')
			  SET @AdjPostedStatusId =(SELECT TOP 1 Id FROM StocklineAdjustmentstatus where [Name]='Posted')

			BEGIN
			 IF OBJECT_ID(N'tempdb..#tmpOriginalStockline') IS NOT NULL      
			 BEGIN      
			  DROP TABLE #tmpOriginalStockline      
			 END   

			 CREATE TABLE #tmpOriginalStockline     
			 (      
			  ID BIGINT NOT NULL IDENTITY,      
			  StockLineId BIGINT NULL,
			  ItemMasterId BIGINT NULL,
			  ConditionId BIGINT NULL,
			  StocklineNumber VARCHAR(200) NULL,
			  ControlNumber VARCHAR(200) NULL,
			  ReferenceNumber VARCHAR(200) NULL,
			  IdNumber VARCHAR(200) NULL,
			  PartNumber VARCHAR(200) NULL,
			  PartDescription VARCHAR(MAX) NULL,
			  Condition VARCHAR(200) NULL,
			  QuantityReserved INT NULL,
			  QuantityIssued INT NULL,
			  QuantityOnHand INT NULL,
			  QuantityAvailable INT NULL,
			  ModuleQuantityReserved INT NULL,
			  ModuleQuantityIssued INT NULL,
			  ModuleQuantityOnHand INT NULL,
			  ModuleQuantityAvailable INT NULL
			  )

			  INSERT INTO #tmpOriginalStockline(StockLineId, ItemMasterId, ConditionId, StocklineNumber, ControlNumber, IdNumber, PartNumber, PartDescription, Condition, QuantityReserved, QuantityIssued, QuantityOnHand, QuantityAvailable)
			  SELECT StockLineId, ItemMasterId, ConditionId, StocklineNumber, ControlNumber, IdNumber, PartNumber, PNDescription, Condition, QuantityReserved, QuantityIssued, QuantityOnHand, QuantityAvailable 
			  FROM dbo.Stockline WHERE (ISNULL(QuantityIssued, 0) > 0 OR ISNULL(QuantityReserved, 0) > 0 ) AND ISNULL(IsParent, 0) = 1


			 IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL      
			 BEGIN      
			  DROP TABLE #tmpStockline      
			 END    
	 
			 IF OBJECT_ID(N'tempdb..#finalResult') IS NOT NULL      
			 BEGIN      
			  DROP TABLE #finalResult    
			 END 

			 IF OBJECT_ID(N'tempdb..#tmptmpStockline') IS NOT NULL      
			 BEGIN      
			  DROP TABLE #tmptmpStockline    
			 END 
          
			 CREATE TABLE #tmptmpStockline     
			 (      
			  ID BIGINT NOT NULL IDENTITY,       
			  PartNumber VARCHAR(200) NULL,
			  PartDescription VARCHAR(MAX) NULL,
			  Condition VARCHAR(200) NULL,
			  StockLineId BIGINT NULL,
			  StocklineNumber VARCHAR(200) NULL,
			  ControlNumber VARCHAR(200) NULL,
			  IdNumber VARCHAR(200) NULL,
			  QuantityReserved INT NULL,
			  QuantityIssued INT NULL,
			  Module VARCHAR(80) NULL,
			  ReferenceNumber VARCHAR(100) NULL,
			  level1 VARCHAR(MAX)  NULL,
			  level2 VARCHAR(MAX)  NULL,
			  level3 VARCHAR(MAX)  NULL,
			  level4 VARCHAR(MAX)  NULL,
			  level5 VARCHAR(MAX)  NULL,
			  level6 VARCHAR(MAX)  NULL,
			  level7 VARCHAR(MAX)  NULL,
			  level8 VARCHAR(MAX)  NULL,
			  level9 VARCHAR(MAX)  NULL,
			  level10 VARCHAR(MAX) NULL,
			  ReservationDate DATETIME2 NULL,
			  ReservedBy VARCHAR(Max) NULL DEFAULT '',
			  IssuedDate DATETIME2 NULL,
			  IssuedBy VARCHAR(Max) NULL DEFAULT '',
			  Quantity INT NULL  DEFAULT 0,
			  QuantityOnHand INT NULL  DEFAULT 0,
			  QuantityAvailable INT NULL  DEFAULT 0,
			  [Location] VARCHAR(Max) NULL DEFAULT '',
			  SerialNumber VARCHAR(Max) NULL DEFAULT '',
			  Comments VARCHAR(Max) NULL DEFAULT '',
			  ReferenceId BIGINT NULL DEFAULT 0,
			  SubReferenceId BIGINT NULL DEFAULT 0,
			  VendorCode VARCHAR(100) NULL DEFAULT '',
			  VendorName VARCHAR(Max) NULL DEFAULT '',	
			  MpnId BIGINT NULL DEFAULT 0,
			  Manufacturer VARCHAR(200) NULL DEFAULT '',
			  ReservedIssuedDate DATETIME2 NULL,
			  ReservedIssuedBy VARCHAR(Max) NULL DEFAULT '',
			  IsVendor BIT NULL DEFAULT 0,
			  StlQtyReserved INT NULL  DEFAULT 0,
			  StlQtyIssued INT NULL  DEFAULT 0,
			 )    
		 IF(@DisplayType = 1 OR @DisplayType = 3)
		 BEGIN
			--* Start: WorkOrderPartNumber For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WOP.Quantity QtyReserved,
					0,
					@WOModule AS Module,
					WO.WorkOrderNum ,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					WOP.CreatedDate  ReservationDate,
					WOP.CreatedBy ReservedBy,
					WOP.CreatedDate  IssuedDate,
					WOP.CreatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					WO.WorkOrderId as ReferenceId,
					SL.Manufacturer,
					WOP.CreatedDate  ReservedIssuedDate,
					WOP.CreatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId AND ISNULL(WO.IsDeleted, 0) = 0
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = WOP.MasterCompanyId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = WOP.StockLineId
					WHERE WOP.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) AND ISNULL(WOP.Quantity,0) > 0 AND ISNULL(WOP.IsClosed,0) = 0 AND ISNULL(WOP.IsFinishGood,0) = 0 AND ISNULL(WOP.RepairOrderId,0) = 0

				
				--* END: WorkOrderPartNumber For Reserve *--

				--* START: RepairOrder For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,VendorCode,VendorName,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued )
				SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					ROP.QuantityReserved,
					0 ,
					@ROModule AS Module,
					RO.RepairOrderNumber,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					ROP.CreatedDate  ReservationDate,
					ROP.CreatedBy ReservedBy,
					ROP.CreatedDate  IssuedDate,
					ROP.CreatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					RO.RepairOrderId as ReferenceId,
					Ro.VendorId as SubReferenceId,
					Ro.VendorCode as VendorCode,
					Ro.VendorName as VendorName,
					SL.Manufacturer,
					ROP.CreatedDate  ReservedIssuedDate,
					ROP.CreatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued	
				FROM dbo.[RepairOrderPart] ROP WITH(NOLOCK)
					INNER JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = ROP.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = ROP.MasterCompanyId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = ROP.StockLineId
					WHERE ROP.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND ISNULL(RO.IsActive,0) = 1 AND ISNULL(ROP.IsActive,0) = 1
					AND ISNULL(ROP.IsDeleted,0) = 0 AND ISNULL(ROP.IsParent,0) = 1
					AND ISNULL(ROP.QuantityReserved,0) > 0  AND ISNULL(ROP.IsDeleted,0) = 0  
					AND ISNULL(RO.StatusId,0) != @ROClosedStatusId AND ISNULL(RO.StatusId,0) != @ROCancelStatusId 
					AND ISNULL(ROP.[IsPiecePart], 0) = 0
						
				--* END: RepairOrder For Reserve *--

				--* START: ExchangeSalesOrder For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,SubReferenceId,IsVendor,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					ESR.QtyToReserve,
					0 ,
					@ExchangeModule AS Module,
					ESO.ExchangeSalesOrderNumber,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					ESR.ReservedDate  ReservationDate,
					EM.FirstName + ' ' + EM.LastName as  ReservedBy,
					ESR.IssuedDate  IssuedDate,
					ESR.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					ESO.ExchangeSalesOrderId as ReferenceId,
					SL.Manufacturer,
					ESR.ReservedDate  ReservedIssuedDate,
					EM.FirstName + ' ' + EM.LastName ReservedIssuedBy,
					ESO.CustomerId as SubReferenceId,
					ISNULL(ESO.IsVendor,0) as IsVendor,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[ExchangeSalesOrderReserveParts] ESR WITH(NOLOCK)
					INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH(NOLOCK) ON ESO.ExchangeSalesOrderId = ESR.ExchangeSalesOrderId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = ESR.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = ESR.MasterCompanyId
					INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = ESR.ReservedById
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = ESR.StockLineId
					WHERE ESR.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND ISNULL(ESO.IsDeleted,0) = 0 
					AND ISNULL(ESR.QtyToReserve,0) > 0 
					AND (ISNULL(ESO.StatusId,0) != @ExchClosedStatusId OR ISNULL(ESR.PartStatusId,0) != @ExchCancelStatusId OR ISNULL(ESO.IsVendor,0) != 1)
			
				--* END: ExchangeSalesOrder For Reserve *--

				--* START: RMA For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					VRD.Qty,
					0 ,
					@RMAModule AS Module,
					VRD.RMANum,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					VRD.UpdatedDate  ReservationDate,
					VRD.UpdatedBy ReservedBy,
					VRD.UpdatedDate  IssuedDate,
					VRD.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					VRD.VendorRMAId as ReferenceId,
					SL.Manufacturer,
					VRD.UpdatedDate  ReservedIssuedDate,
					VRD.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[VendorRMADetail] VRD WITH(NOLOCK)
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = VRD.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = VRD.MasterCompanyId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = VRD.StockLineId
					WHERE VRD.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND ISNULL(VRD.IsActive,0) = 1 AND ISNULL(VRD.IsDeleted,0) = 0 
					AND ISNULL(VRD.Qty,0) > 0 
					AND (ISNULL(VRD.VendorRMAStatusId,0) NOT IN(@RMAShipToVendor,@RMAReplaced,@RMARefunded,@RMACancel))
		
				--* END: RMA For Reserve *--

				--* START: SalesOrder For Reserve *--
				
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,SubReferenceId,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					Sl.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SSTL.QtyReserved,
					0 ,
					@SOModule AS Module,
					ESO.SalesOrderNumber,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					SOR.ReservedDate  ReservationDate,
					emp.FirstName + ' ' + emp.LastName as ReservedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					ESO.SalesOrderId as ReferenceId,
					SL.Manufacturer,
					SOR.ReservedDate  ReservedIssuedDate,
					emp.FirstName + ' ' + emp.LastName as ReservedIssuedBy,
					ESO.CustomerId as SubReferenceId,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[SalesOrderStocklineV1] SSTL WITH(NOLOCK)
					INNER JOIN dbo.SalesOrderPartV1 SOP WITH(NOLOCK) ON SSTL.SalesOrderPartId = SOP.SalesOrderPartId
					INNER JOIN [dbo].[SalesOrder] ESO WITH(NOLOCK) ON SOP.SalesOrderId = ESO.SalesOrderId					
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SSTL.StockLineId AND SL.MasterCompanyId = SSTL.MasterCompanyId
					INNER JOIN dbo.SalesOrderReserveParts SOR WITH(NOLOCK) ON SOR.SalesOrderId = ESO.SalesOrderId AND SOR.StockLineId = SSTL.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = SSTL.MasterCompanyId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SSTL.StockLineId
					LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON SOR.ReservedById = emp.EmployeeId
					WHERE SSTL.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND ISNULL(ESO.IsDeleted,0) = 0 
					AND ISNULL(SSTL.QtyReserved,0) > 0 
				--* END: SalesOrder For Reserve *--

				--* START: Stockline Bulk Adjustment For Reserve *--
				
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  ReservationDate,ReservedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SSTL.NewQty,
					0 ,
					@BulkAdjModule AS Module,
					ESO.BulkStkLineAdjNumber,				
					SSTL.UpdatedDate  ReservationDate,
					SSTL.UpdatedBy  as ReservedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					ESO.BulkStkLineAdjId as ReferenceId,
					SL.Manufacturer,
					SSTL.UpdatedDate  ReservedIssuedDate,
					SSTL.UpdatedBy as ReservedIssuedBy,
					SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[BulkStockLineAdjustmentDetails] SSTL WITH(NOLOCK)
					INNER JOIN [dbo].[BulkStockLineAdjustment] ESO WITH(NOLOCK) ON SSTL.BulkStkLineAdjId = ESO.BulkStkLineAdjId					
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SSTL.StockLineId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SSTL.StockLineId
					WHERE SSTL.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND ISNULL(ESO.IsDeleted,0) = 0 AND ISNULL(SSTL.IsDeleted,0) = 0
					AND ISNULL(SSTL.NewQty,0) > 0 AND  ISNULL(SSTL.QtyAdjustment,0) > 0
					AND ESO.StatusId != @AdjPostedStatusId
				--* END: Stockline Bulk Adjustment For Reserve *--
		 END
		 IF(@DisplayType = 1)
		 BEGIN
				--* Start: WorkOrderMaterialStockline For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WMS.QtyReserved,
					WMS.QtyIssued,
					@WOModule AS Module,
					WO.WorkOrderNum ,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					WMS.UpdatedDate  ReservationDate,
					WMS.UpdatedBy ReservedBy,
					WMS.UpdatedDate  IssuedDate,
					WMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					WO.WorkOrderId as ReferenceId,
					SL.Manufacturer,
					WMS.UpdatedDate  ReservedIssuedDate,
					WMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[WorkOrderMaterialStockLine] WMS WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderMaterials] WM WITH(NOLOCK) ON WM.WorkOrderMaterialsId = WMS.WorkOrderMaterialsId
					INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = WMS.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = WMS.StockLineId
					WHERE WMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ','))   AND ISNULL(WMS.QtyReserved,0) > 0 
						 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId)
			
				--* END: WorkOrderMaterialStockline For Reserve *--

				--* Start: WorkOrderMaterialStocklineKit For Reserve *--					
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WMS.QtyReserved,
					WMS.QtyIssued,
					@WOModule AS Module,
					WO.WorkOrderNum ,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					WMS.UpdatedDate  ReservationDate,
					WMS.UpdatedBy ReservedBy,
					WMS.UpdatedDate  IssuedDate,
					WMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					WO.WorkOrderId as ReferenceId,
					SL.Manufacturer,
					WMS.UpdatedDate  ReservedIssuedDate,
					WMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[WorkOrderMaterialStockLineKit] WMS  WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderMaterialsKit] WM WITH(NOLOCK) ON WM.WorkOrderMaterialsKitId = WMS.WorkOrderMaterialsKitId
					INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)  ON WOP.ID = WF.WorkOrderPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = WMS.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = WMS.StockLineId
					WHERE WMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND ISNULL(WMS.QtyReserved,0) > 0 
					AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId)
						
				--* END: WorkOrderMaterialStocklineKit For Reserve *--

				--* START: SubWorkOrderMaterialStockline For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
												QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					@SubWorkOrderModule AS Module,
					SWO.SubWorkOrderNo ,
		
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					SWMS.UpdatedDate  ReservationDate,
					SWMS.UpdatedBy ReservedBy,
					SWMS.UpdatedDate  IssuedDate,
					SWMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					SWO.SubWorkOrderId as ReferenceId,
					SWO.WorkOrderId as SubReferenceId,
					SWO.WorkOrderPartNumberId as MpnId,
					SL.Manufacturer,
					SWMS.UpdatedDate  ReservedIssuedDate,
					SWMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[SubWorkOrderMaterialStockLine] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterials] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsId = SWMS.SubWorkOrderMaterialsId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = SWMS.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SWMS.StockLineId
					WHERE SWMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND ISNULL(SWMS.QtyReserved,0) > 0 
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId)
						
				--* END: SubWorkOrderMaterialStockline For Reserve *--

				--* START: SubWorkOrderMaterialStocklineKit For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued  )
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					@SubWorkOrderModule AS Module,
					SWO.SubWorkOrderNo ,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					SWMS.UpdatedDate  ReservationDate,
					SWMS.UpdatedBy ReservedBy,
					SWMS.UpdatedDate  IssuedDate,
					SWMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					SWO.SubWorkOrderId as ReferenceId,
					SWO.WorkOrderId SubReferenceId,
					SWO.WorkOrderPartNumberId as MpnId,
					SL.Manufacturer,
					SWMS.UpdatedDate  ReservedIssuedDate,
					SWMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[SubWorkOrderMaterialStockLineKit] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterialsKit] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsKitId = SWMS.SubWorkOrderMaterialsKitId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = SWMS.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SWMS.StockLineId
					WHERE SWMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND ISNULL(SWMS.QtyReserved,0) > 0 
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId)
					
				--* END: SubWorkOrderMaterialStocklineKit For Reserve *--
				
		 END
		 ELSE IF(@DisplayType = 2)
		 BEGIN

				--* Start: WorkOrderMaterialStockline For Issued *--
				 INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
						SELECT
						SL.PartNumber,
						SL.PNDescription,
						SL.Condition,
						SL.StockLineId,
						SL.StockLineNumber,
						SL.ControlNumber,
						SL.IdNumber,
						WMS.QtyReserved,
						WMS.QtyIssued,
						@WOModule AS Module,
						WO.WorkOrderNum ,
						UPPER(SLM.Level1Name) AS level1,  
						UPPER(SLM.Level2Name) AS level2, 
						UPPER(SLM.Level3Name) AS level3, 
						UPPER(SLM.Level4Name) AS level4, 
						UPPER(SLM.Level5Name) AS level5, 
						UPPER(SLM.Level6Name) AS level6, 
						UPPER(SLM.Level7Name) AS level7, 
						UPPER(SLM.Level8Name) AS level8, 
						UPPER(SLM.Level9Name) AS level9, 
						UPPER(SLM.Level10Name) AS level10,
						WMS.UpdatedDate  ReservationDate,
						WMS.UpdatedBy ReservedBy,
						WMS.UpdatedDate  IssuedDate,
						WMS.UpdatedBy IssuedBy,
						ISNULL(SL.Quantity,0) as Quantity,
						ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
						ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
						SL.[Location] as [Location],
						SL.SerialNumber SerialNumber,
						'' as Comments,
						WO.WorkOrderId as ReferenceId,
						SL.Manufacturer,
						WMS.UpdatedDate  ReservedIssuedDate,
						WMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
					FROM dbo.[WorkOrderMaterialStockLine] WMS  WITH(NOLOCK)
						INNER JOIN [dbo].[WorkOrderMaterials] WM  WITH(NOLOCK) ON WM.WorkOrderMaterialsId = WMS.WorkOrderMaterialsId
						INNER JOIN [dbo].[WorkOrderWorkFlow] WF  WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
						INNER JOIN [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
						INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = WMS.MasterCompanyId
						INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
						INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = WMS.StockLineId
						WHERE WMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
						AND ISNULL(WMS.QtyIssued,0) > 0 
						AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId)
							
				--* END: WorkOrderMaterialStockline For Issued *--

				--* START: WorkOrderMaterialStocklineKit For Issued *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WMS.QtyReserved,
					WMS.QtyIssued,
					@WOModule AS Module,
					WO.WorkOrderNum ,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					WMS.UpdatedDate  ReservationDate,
					WMS.UpdatedBy ReservedBy,
					WMS.UpdatedDate  IssuedDate,
					WMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					WO.WorkOrderId as ReferenceId,
					SL.Manufacturer,
					WMS.UpdatedDate  ReservedIssuedDate,
					WMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[WorkOrderMaterialStockLineKit] WMS  WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderMaterialsKit] WM  WITH(NOLOCK) ON WM.WorkOrderMaterialsKitId = WMS.WorkOrderMaterialsKitId
					INNER JOIN [dbo].[WorkOrderWorkFlow] WF  WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
					INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = WMS.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = WMS.StockLineId
					WHERE WMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ','))  AND ISNULL(WMS.QtyIssued,0) > 0 
					AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId)
						
				--* END: WorkOrderMaterialStocklineKit For Issued *--

				--* START: SUBWorkOrderMaterialStockline For Issued *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)

					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					@SubWorkOrderModule AS Module,
					SWO.SubWorkOrderNo , 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					SWMS.UpdatedDate  ReservationDate,
					SWMS.UpdatedBy ReservedBy,
					SWMS.UpdatedDate  IssuedDate,
					SWMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					SWO.SubWorkOrderId as ReferenceId,
					SWO.WorkOrderId SubReferenceId , 
					SWO.WorkOrderPartNumberId as MpnId,
					SL.Manufacturer,
					SWMS.UpdatedDate  ReservedIssuedDate,
					SWMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[SubWorkOrderMaterialStockLine] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterials] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsId = SWMS.SubWorkOrderMaterialsId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = SWMS.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SWMS.StockLineId
					WHERE SWMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ','))  AND ISNULL(SWMS.QtyIssued,0) > 0  
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId)
				--* END: SUBWorkOrderMaterialStockline For Issued *--

				--* START: SUBWorkOrderMaterialStocklineKit For Issued *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued )

					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					@SubWorkOrderModule AS Module,
					SWO.SubWorkOrderNo ,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					SWMS.UpdatedDate  ReservationDate,
					SWMS.UpdatedBy ReservedBy,
					SWMS.UpdatedDate  IssuedDate,
					SWMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					SWO.SubWorkOrderId as ReferenceId,
					SWO.WorkOrderId as SubReferenceId,
					SWO.WorkOrderPartNumberId as MpnId,
					SL.Manufacturer,
					SWMS.UpdatedDate  ReservedIssuedDate,
					SWMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[SubWorkOrderMaterialStockLineKit] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterialsKit] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsKitId = SWMS.SubWorkOrderMaterialsKitId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = SWMS.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SWMS.StockLineId
					WHERE SWMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ','))  AND ISNULL(SWMS.QtyIssued,0) > 0 
					AND ISNULL(SWO.IsDeleted,0) = 0  AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId)

				--* END: SUBWorkOrderMaterialStockline For Issued *--
		 END		 
		 ELSE IF(@DisplayType = 3)
		 BEGIN

				 --* Start: WorkOrderMaterialStockline For ALL *--
				 INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
						SELECT
						SL.PartNumber,
						SL.PNDescription,
						SL.Condition,
						SL.StockLineId,
						SL.StockLineNumber,
						SL.ControlNumber,
						SL.IdNumber,
						WMS.QtyReserved,
						WMS.QtyIssued,
						@WOModule AS Module,
						WO.WorkOrderNum ,
						UPPER(SLM.Level1Name) AS level1,  
						UPPER(SLM.Level2Name) AS level2, 
						UPPER(SLM.Level3Name) AS level3, 
						UPPER(SLM.Level4Name) AS level4, 
						UPPER(SLM.Level5Name) AS level5, 
						UPPER(SLM.Level6Name) AS level6, 
						UPPER(SLM.Level7Name) AS level7, 
						UPPER(SLM.Level8Name) AS level8, 
						UPPER(SLM.Level9Name) AS level9, 
						UPPER(SLM.Level10Name) AS level10,
						WMS.UpdatedDate  ReservationDate,
						WMS.UpdatedBy ReservedBy,
						WMS.UpdatedDate  IssuedDate,
						WMS.UpdatedBy IssuedBy,
						ISNULL(SL.Quantity,0) as Quantity,
						ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
						ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
						SL.[Location] as [Location],
						SL.SerialNumber SerialNumber,
						'' as Comments,
						WO.WorkOrderId as ReferenceId,
						SL.Manufacturer,
						WMS.UpdatedDate  ReservedIssuedDate,
						WMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
					FROM dbo.[WorkOrderMaterialStockLine] WMS  WITH(NOLOCK) 
						INNER JOIN [dbo].[WorkOrderMaterials] WM  WITH(NOLOCK) ON WM.WorkOrderMaterialsId = WMS.WorkOrderMaterialsId
						INNER JOIN [dbo].[WorkOrderWorkFlow] WF  WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
						INNER JOIN [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
						INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = WMS.MasterCompanyId
						INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
						INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = WMS.StockLineId
						WHERE (ISNULL(WMS.QtyIssued,0) > 0 OR ISNULL(WMS.QtyReserved,0) > 0)  
						AND WMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
						AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId)
				
				--* END: WorkOrderMaterialStockline For ALL *--

				--* Start: WorkOrderMaterialStocklineKit For ALL *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy ,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WMS.QtyReserved,
					WMS.QtyIssued,
					@WOModule AS Module,
					WO.WorkOrderNum ,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					WMS.UpdatedDate  ReservationDate,
					WMS.UpdatedBy ReservedBy,
					WMS.UpdatedDate  IssuedDate,
					WMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					WO.WorkOrderId as ReferenceId,
					SL.Manufacturer,
					WMS.UpdatedDate  ReservedIssuedDate,
					WMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[WorkOrderMaterialStockLineKit] WMS  WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderMaterialsKit] WM  WITH(NOLOCK) ON WM.WorkOrderMaterialsKitId = WMS.WorkOrderMaterialsKitId
					INNER JOIN [dbo].[WorkOrderWorkFlow] WF  WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
					INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = WMS.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = WMS.StockLineId
					WHERE (ISNULL(WMS.QtyIssued,0) > 0 OR ISNULL(WMS.QtyReserved,0) > 0) 
					AND WMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId)
				
				--* End: WorkOrderMaterialStocklinekit For ALL *--

				--* Start: SubWorkOrderMaterialStockline For ALL *--				
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)

					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					@SubWorkOrderModule AS Module,
					SWO.SubWorkOrderNo ,  
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					SWMS.UpdatedDate  ReservationDate,
					SWMS.UpdatedBy ReservedBy,
					SWMS.UpdatedDate  IssuedDate,
					SWMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					SWO.SubWorkOrderId as ReferenceId,
					SWO.WorkOrderId as SubReferenceId ,
					SWO.WorkOrderPartNumberId as MpnId,
					SL.Manufacturer,
					SWMS.UpdatedDate  ReservedIssuedDate,
					SWMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[SubWorkOrderMaterialStockLine] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterials] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsId = SWMS.SubWorkOrderMaterialsId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = SWMS.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SWMS.StockLineId
					WHERE (ISNULL(SWMS.QtyIssued,0) > 0 OR ISNULL(SWMS.QtyReserved,0) > 0)  
					AND SWMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId)
				
				--* END: SubWorkOrderMaterialStockline For ALL *--				

				--* Start: SubWorkOrderMaterialStocklineKIT For ALL *--				
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StockLineId,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)

					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineId,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					@SubWorkOrderModule AS Module,
					SWO.SubWorkOrderNo ,
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10,
					SWMS.UpdatedDate  ReservationDate,
					SWMS.UpdatedBy ReservedBy,
					SWMS.UpdatedDate  IssuedDate,
					SWMS.UpdatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					SWO.SubWorkOrderId as ReferenceId,
					SWO.WorkOrderId as SubReferenceId,
					SWO.WorkOrderPartNumberId as MpnId,
					SL.Manufacturer,
					SWMS.UpdatedDate  ReservedIssuedDate,
					SWMS.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.[SubWorkOrderMaterialStockLineKit] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterialsKit] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsKitId = SWMS.SubWorkOrderMaterialsKitId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SLM.MasterCompanyId = SWMS.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SWMS.StockLineId
					WHERE (ISNULL(SWMS.QtyIssued,0) > 0 OR ISNULL(SWMS.QtyReserved,0) > 0)  
					AND SWMS.MasterCompanyId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@MasterCompanyId, ',')) 
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId)
					
				--* END: SubWorkOrderMaterialStockline For ALL *--

		 END

		 --SELECT * FROM #tmptmpStockline where StockLineId = 63029


		 UPDATE #tmpOriginalStockline
		 SET ModuleQuantityAvailable = GropWOM.QuantityAvailable, ModuleQuantityReserved = GropWOM.QuantityReserved, ModuleQuantityIssued = GropWOM.QuantityIssued, 
			 ModuleQuantityOnHand = GropWOM.QuantityOnHand--, ReferenceNumber = GropWOM.ReferenceNumber
		 FROM(
		 	SELECT  SUM(sl.QuantityAvailable) QuantityAvailable, SUM(sl.QuantityOnHand) QuantityOnHand, SUM(SL.QuantityReserved) QuantityReserved, SUM(sl.QuantityIssued) QuantityIssued ,SL.StockLineId
				--,SL.ReferenceNumber
			 FROM #tmptmpStockline SL INNER JOIN #tmpOriginalStockline OSL ON OSL.StockLineId = SL.StockLineId
			 GROUP BY Sl.StockLineId--, SL.ReferenceNumber
		 ) GropWOM WHERE GropWOM.StockLineId = #tmpOriginalStockline.StockLineId --AND 

		 -- SELECT * FROM #tmpOriginalStockline WHERE (ISNULL(ModuleQuantityReserved,0) <> ISNULL(QuantityReserved,0))
			--AND (ISNULL(ModuleQuantityReserved,0) != 0 )

		--SELECT * FROM #tmpOriginalStockline WHERE (ISNULL(ModuleQuantityIssued,0) <> ISNULL(QuantityIssued,0))
		--	AND (ISNULL(ModuleQuantityIssued,0) != 0)

		 SELECT Quantity,
			  SL.QuantityOnHand,
		      (ISNULL(SL.QuantityAvailable,0) + ISNULL(SL.QuantityReserved,0)) AS [AV_RES],
		      SL.QuantityAvailable,SL.QuantityReserved,
			  ModuleQuantityReserved As AllReserve,
			  ModuleQuantityIssued AS AllIssue, 
			  0 ReserevinWOM,
			  0 ReserevinWOKIT,
			  0 ReserevinRO,
			  0 Reserve_In_WO_MPN, 
			  0 Reserve_In_VendorRMA,
			  SL.QuantityIssued AS QuantityIssued,		      
			  0 IssueWOM, 
			  0 IssueWOKIT,			  
			  tmpSL.StockLineId,
			  0 ParentId,
			  0 IsParent,
			  Sl.IsCustomerStock,
			  SL.CreatedDate,
			  (SELECT MAX(UpdatedDate) FROM dbo.Stkline_History SH WITH(NOLOCK) WHERE SH.StocklineId = SL.StockLineId) AS UpdatedDate,
			  tmpSL.StockLineNumber,
			  SL.SerialNumber,
			  tmpSL.PartNumber,
			  tmpSL.PartDescription AS PNDescription,
			  tmpSL.ControlNumber,
			  SL.MasterCompanyId,
			  tmpSL.IdNumber,
		      tmpSL.ReferenceNumber
		 FROM #tmpOriginalStockline tmpSL
			JOIN Stockline SL ON SL.StockLineId = tmpSL.StockLineId
		 WHERE (ISNULL(ModuleQuantityReserved,0) <> ISNULL(tmpSL.QuantityReserved,0)) -- OR ISNULL(ModuleQuantityIssued,0) <> ISNULL(tmpSL.QuantityIssued,0))
			AND (ISNULL(ModuleQuantityReserved,0) != 0 OR ISNULL(ModuleQuantityIssued,0) != 0 )
		ORDER BY SL.MasterCompanyId DESC
			
	END

	END
	END TRY    
	BEGIN CATCH    
	 SELECT 
            ERROR_MESSAGE() AS ErrorMessage, 
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_LINE() AS ErrorLine;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
			
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetNewStocklineInventoryMismatch' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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