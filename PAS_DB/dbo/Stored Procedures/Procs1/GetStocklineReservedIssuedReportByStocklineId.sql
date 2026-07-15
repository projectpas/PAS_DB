/*************************************************************               
 ** File:   [GetStocklineReservedIssuedReportByStocklineId]               
 ** Author: RAJESH GAMI 
 ** Description: Get Stockline Reserved/Issued Report By Stockline Id (Module wise)
 ** Purpose:             
 ** Date:   07-Nov-2024        
 ** PARAMETERS:             
 ** RETURN VALUE:              
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------			--------------------------------              
    1    07-Nov-2024   RAJESH GAMI		CREATED 
	2    18-Nov-2024   RAJESH GAMI		Remove the partId condition from the SORervervation table join and some other required changes
	3    19-Nov-2024   RAJESH GAMI		Implemented BulkAdjustments
	4    22-Nov-2024   RAJESH GAMI		handle Deleted condition in bulkadjustment
	5    22-Nov-2024   RAJESH GAMI		handle QtyAdjustment in bulkadjustment
	6    16-12-2024    RAJESH GAMI      Get only data where RepairOrderId is null in WorkOrderPartNumber, If already created RO then no need to show
	7    18-12-2024    RAJESH GAMI		Skip the record if WO,RO,SO,Exch deleted
	8    19-12-2024    RAJESH GAMI		Add MastercompanyId in the managementstructure JOIN
	9    26-12-2024    RAJESH GAMI		Modified WPN to check RO is closed or not
    10   13-02-2025    Ayushi Patel     converted the date into utc (RESERVED,ISSUED,RESERVEISSUE) , Added a case to get timeZone
    11   12-02-2026    Moin Bloch		Modified Added TearDown Work Order Issue Operation PN-15435
	12   26-03-2026    Moin Bloch	    Rename TearDown To Internal Teardown PN-15850
	13	 26-06-2026	   Abhishek Jirawla Added Repair Order Piece part listing and calculations in the SP.
	14	 09/July/2026   RAJESH GAMI   [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

	EXEC [dbo].[GetStocklineReservedIssuedReportByStocklineId] 183296,1,1

**************************************************************/    
CREATE  PROCEDURE [dbo].[GetStocklineReservedIssuedReportByStocklineId]
@StocklineId BIGINT,
@DisplayType INT NULL,
@MasterCompanyId INT NULL,
@EmployeeId bigint
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	  DECLARE @WOModule varchar(50) = 'WorkOrder',  @SubWorkOrderModule varchar(50) = 'SubWorkOrder',@SOModule varchar(50) = 'SalesOrder', @OModule varchar(50) = 'SalesOrder',
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
	  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	  DECLARE @TearDown INT
		
				SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
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
	  SET @TearDown = (SELECT [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Teardown');
	BEGIN TRY 
	BEGIN
	 IF OBJECT_ID(N'tempdb..#tmpStockline') IS NOT NULL      
     BEGIN      
      DROP TABLE #tmpStockline      
     END    
	 
	 IF OBJECT_ID(N'tempdb..#finalResult') IS NOT NULL      
     BEGIN      
      DROP TABLE #finalResult    
     END 
          
     CREATE TABLE #tmptmpStockline     
     (      
      ID BIGINT NOT NULL IDENTITY,       
      PartNumber VARCHAR(200) NULL,
	  PartDescription VARCHAR(MAX) NULL,
	  Condition VARCHAR(200) NULL,
	  StocklineNumber VARCHAR(200) NULL,
	  ControlNumber VARCHAR(200) NULL,
	  IdNumber VARCHAR(200) NULL,
	  QuantityReserved INT NULL,
	  QuantityIssued INT NULL,
	  Module VARCHAR(80) NULL,
	  ReferenceNumber VARCHAR(100) NULL,
	  --ReservationDate DATETIME2 NULL,
	  --IssueDate DATETIME2 NULL,
	  --ReservedORIssuedBy VARCHAR(100) NULL,
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
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					--WOP.CreatedDate  ReservationDate,
					case when CAST(WOP.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(WOP.CreatedDate, @CurrntEmpTimeZoneDesc) as Date))end ReservationDate,
					WOP.CreatedBy ReservedBy,
					--WOP.CreatedDate  IssuedDate,
					case when CAST(WOP.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(WOP.CreatedDate, @CurrntEmpTimeZoneDesc) as Date))end IssuedDate,
					WOP.CreatedBy IssuedBy,
					ISNULL(SL.Quantity,0) as Quantity,
					ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
					ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
					SL.[Location] as [Location],
					SL.SerialNumber SerialNumber,
					'' as Comments,
					WO.WorkOrderId as ReferenceId,
					SL.Manufacturer,
					--WOP.CreatedDate  ReservedIssuedDate,
					case when CAST(WOP.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(WOP.CreatedDate, @CurrntEmpTimeZoneDesc) as Date))end ReservedIssuedDate,
					WOP.CreatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
				FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WOP.MasterCompanyId = SLM.MasterCompanyId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = WM.ReservedById
					WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.StockLineId = @StocklineId AND ISNULL(WOP.Quantity,0) > 0 AND ISNULL(WOP.IsClosed,0) = 0 AND ISNULL(WOP.IsFinishGood,0) = 0
					AND (ISNULL(WOP.RepairOrderId,0) = 0 OR ISNULL((SELECT RO.StatusId FROM Dbo.RepairOrder RO WITH (NOLOCK) WHERE Ro.RepairOrderId = ISNULL(WOP.RepairOrderId,0)),0) = @ROClosedStatusId ) AND ISNULL(SL.IsNonStock,0) = 0
				   --AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId)
				   --AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
				--* END: WorkOrderPartNumber For Reserve *--

				--* START: RepairOrder For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,VendorCode,VendorName,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued )
				SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND ROP.MasterCompanyId = SLM.MasterCompanyId
					WHERE ROP.MasterCompanyId = @MasterCompanyId AND ROP.StockLineId = @StocklineId
					AND ISNULL(RO.IsActive,0) = 1 AND ISNULL(ROP.IsActive,0) = 1
					AND ISNULL(ROP.IsDeleted,0) = 0 AND ISNULL(RO.IsDeleted,0) = 0 AND ISNULL(ROP.IsParent,0) = 1
					AND ISNULL(ROP.QuantityReserved,0) > 0  AND ISNULL(ROP.IsDeleted,0) = 0
					AND ISNULL(RO.StatusId,0) != @ROClosedStatusId AND ISNULL(RO.StatusId,0) != @ROCancelStatusId
					AND ISNULL(ROP.IsPiecePart, 0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
						
				--* END: RepairOrder For Reserve *--

				--* START: ExchangeSalesOrder For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,SubReferenceId,IsVendor,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND ESR.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = ESR.ReservedById
					WHERE ESR.MasterCompanyId = @MasterCompanyId AND ESR.StockLineId = @StocklineId 
					AND ISNULL(ESR.IsActive,0) = 1 AND ISNULL(ESO.IsActive,0) = 1 AND ISNULL(ESR.IsDeleted,0) = 0 
					AND ISNULL(ESO.IsDeleted,0) = 0 
					AND ISNULL(ESR.QtyToReserve,0) > 0 
					AND (ISNULL(ESO.StatusId,0) != @ExchClosedStatusId OR ISNULL(ESR.PartStatusId,0) != @ExchCancelStatusId OR ISNULL(ESO.IsVendor,0) != 1) AND ISNULL(SL.IsNonStock,0) = 0
			
				--* END: ExchangeSalesOrder For Reserve *--

				--* START: RMA For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND VRD.MasterCompanyId = SLM.MasterCompanyId
					WHERE VRD.MasterCompanyId = @MasterCompanyId AND VRD.StockLineId = @StocklineId 
					AND ISNULL(VRD.IsActive,0) = 1 AND ISNULL(VRD.IsDeleted,0) = 0 
					AND ISNULL(VRD.Qty,0) > 0 
					AND (ISNULL(VRD.VendorRMAStatusId,0) NOT IN(@RMAShipToVendor,@RMAReplaced,@RMARefunded,@RMACancel)) AND ISNULL(SL.IsNonStock,0) = 0
		
				--* END: RMA For Reserve *--

				--* START: SalesOrder For Reserve *--
				
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,SubReferenceId,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SSTL.StockLineId
					INNER JOIN dbo.SalesOrderReserveParts SOR WITH(NOLOCK) ON SOR.SalesOrderId = ESO.SalesOrderId AND SOR.StockLineId = SSTL.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SSTL.MasterCompanyId = SLM.MasterCompanyId
					LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON SOR.ReservedById = emp.EmployeeId
					WHERE SSTL.MasterCompanyId = @MasterCompanyId AND SSTL.StockLineId = @StocklineId 
					AND ISNULL(ESO.IsDeleted,0) = 0 
					AND ISNULL(SSTL.QtyReserved,0) > 0 AND ISNULL(SOP.IsActive,0) = 1 AND ISNULL(ESO.IsActive,0) = 1 AND ISNULL(SOP.IsDeleted,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0
				--* END: SalesOrder For Reserve *--

				--* START: Stockline Bulk Adjustment For Reserve *--
				
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  ReservationDate,ReservedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					WHERE SSTL.MasterCompanyId = @MasterCompanyId AND SSTL.StockLineId = @StocklineId 
					AND ISNULL(ESO.IsDeleted,0) = 0 AND ISNULL(SSTL.IsDeleted,0) = 0
					AND ISNULL(SSTL.NewQty,0) > 0 AND  ISNULL(SSTL.QtyAdjustment,0) > 0
					AND ESO.StatusId != @AdjPostedStatusId AND ISNULL(SL.IsNonStock,0) = 0
				--* END: Stockline Bulk Adjustment For Reserve *--
		 END
		 IF(@DisplayType = 1)
		 BEGIN
				--* Start: WorkOrderMaterialStockline For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = WM.ReservedById
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND WMS.StockLineId = @StocklineId AND ISNULL(WMS.QtyReserved,0) > 0 
						 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
						 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
			
				--* END: WorkOrderMaterialStockline For Reserve *--

				--* Start: WorkOrderMaterialStocklineKit For Reserve *--					
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.ReservedById
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND WMS.StockLineId = @StocklineId 
					AND ISNULL(WMS.QtyReserved,0) > 0 
					AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
					AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
						
				--* END: WorkOrderMaterialStocklineKit For Reserve *--

				--* START: SubWorkOrderMaterialStockline For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
												QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.ReservedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId  AND SWMS.StockLineId = @StocklineId 
					AND ISNULL(SWMS.QtyReserved,0) > 0 
					AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 
					AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0 
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
						
				--* END: SubWorkOrderMaterialStockline For Reserve *--

				--* START: SubWorkOrderMaterialStocklineKit For Reserve *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued  )
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.ReservedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND SWMS.StockLineId = @StocklineId 
					AND ISNULL(SWMS.QtyReserved,0) > 0 
					AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 
					AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0 
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
					
				--* END: SubWorkOrderMaterialStocklineKit For Reserve *--

				--* Start: Repair Order Part For Issued (Incase of piece part) *--
				 INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
						SELECT
							SL.PartNumber,
							SL.PNDescription,
							SL.Condition,
							SL.StockLineNumber,
							SL.ControlNumber,
							SL.IdNumber,
							ROP.QuantityReserved,
							SL.QuantityIssued,
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
							ROP.UpdatedDate  ReservationDate,
							ROP.UpdatedBy ReservedBy,
							ROP.UpdatedDate  IssuedDate,
							ROP.UpdatedBy IssuedBy,
							ISNULL(SL.Quantity,0) as Quantity,
							ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
							ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
							SL.[Location] as [Location],
							SL.SerialNumber SerialNumber,
							'' as Comments,
							RO.RepairOrderId as ReferenceId,
							SL.Manufacturer,
							ROP.UpdatedDate  ReservedIssuedDate,
							ROP.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
						FROM dbo.[RepairOrderPart] ROP  WITH(NOLOCK)
							INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = ROP.StockLineId
							INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND ROP.MasterCompanyId = SLM.MasterCompanyId
							INNER JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
							--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.IssuedById
						WHERE ROP.MasterCompanyId = @MasterCompanyId AND ROP.StockLineId = @StocklineId
						AND ISNULL(RO.IsActive,0) = 1 AND ISNULL(ROP.IsActive,0) = 1 AND ISNULL(ROP.IsDeleted,0) = 0 AND ISNULL(RO.IsDeleted,0) = 0 
						AND ISNULL(ROP.QuantityReserved,0) > 0
						AND ISNULL(ROP.IsPiecePart, 0) = 1 AND ISNULL(SL.IsNonStock,0) = 0

				--* END: Repair Order Part For Issued (Incase of piece part) *--

		 END
		 ELSE IF(@DisplayType = 2)
		 BEGIN

				--* Start: WorkOrderMaterialStockline For Issued *--
				 INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
						SELECT
						SL.PartNumber,
						SL.PNDescription,
						SL.Condition,
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
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
						INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
						--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.IssuedById
						WHERE WMS.MasterCompanyId = @MasterCompanyId AND WMS.StockLineId = @StocklineId
						AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
						AND ISNULL(WMS.QtyIssued,0) > 0 
						AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
							
				--* END: WorkOrderMaterialStockline For Issued *--

				--* START: WorkOrderMaterialStocklineKit For Issued *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.IssuedById
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND WMS.StockLineId = @StocklineId AND ISNULL(WMS.QtyIssued,0) > 0 
					AND ISNULL(WO.IsActive,0) = 1  AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
					AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
						
				--* END: WorkOrderMaterialStocklineKit For Issued *--

				--* START: SUBWorkOrderMaterialStockline For Issued *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)

					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.IssuedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND SWMS.StockLineId = @StocklineId  AND ISNULL(SWMS.QtyIssued,0) > 0  
					AND ISNULL(SWO.IsActive,0) = 1 
					AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
				--* END: SUBWorkOrderMaterialStockline For Issued *--

				--* START: SUBWorkOrderMaterialStocklineKit For Issued *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued )

					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.IssuedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND SWMS.StockLineId = @StocklineId AND ISNULL(SWMS.QtyIssued,0) > 0 
					AND ISNULL(SWMS.IsActive,0) = 1AND ISNULL(SWMS.IsDeleted,0) = 0  AND ISNULL(SWO.IsActive,0) = 1  
					AND ISNULL(SWO.IsDeleted,0) = 0  AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0

				--* END: SUBWorkOrderMaterialStockline For Issued *--


				--* START: TearDown WorkOrder For Issued *--

				 INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
				SELECT	SL.PartNumber,
						SL.PNDescription,
						SL.Condition,
						SL.StockLineNumber,
						SL.ControlNumber,
						SL.IdNumber,
						SL.QtyReserved,
						SL.QuantityIssued,
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
						SL.UpdatedDate  ReservationDate,
						SL.UpdatedBy ReservedBy,
						SL.UpdatedDate  IssuedDate,
						SL.UpdatedBy IssuedBy,
						ISNULL(SL.Quantity,0) AS Quantity,
						ISNULL(SL.QuantityOnHand,0) AS QuantityOnHand,
						ISNULL(SL.QuantityAvailable,0) AS QuantityAvailable,
						SL.[Location] AS [Location],
						SL.SerialNumber SerialNumber,
						'' AS Comments,
						WO.WorkOrderId AS ReferenceId,
						SL.Manufacturer,
						WOP.UpdatedDate  ReservedIssuedDate,
						WOP.UpdatedBy ReservedIssuedBy,
						SL.QuantityReserved,
						SL.QuantityIssued
					FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)
						INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WOP.MasterCompanyId = SLM.MasterCompanyId
						INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId AND WO.[WorkOrderTypeId] = @TearDown
					WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.StockLineId = @StocklineId
						AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WOP.IsActive,0) = 1 AND ISNULL(WOP.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
						AND ISNULL(SL.[QuantityIssued],0) > 0 AND ISNULL(SL.IsNonStock,0) = 0 

				--* END: TearDown WorkOrder For Issued *--

				--* Start: Repair Order Part For Issued (Incase of piece part) *--
				 INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
						SELECT
							SL.PartNumber,
							SL.PNDescription,
							SL.Condition,
							SL.StockLineNumber,
							SL.ControlNumber,
							SL.IdNumber,
							ROP.QuantityReserved,
							SL.QuantityIssued,
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
							ROP.UpdatedDate  ReservationDate,
							ROP.UpdatedBy ReservedBy,
							ROP.UpdatedDate  IssuedDate,
							ROP.UpdatedBy IssuedBy,
							ISNULL(SL.Quantity,0) as Quantity,
							ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
							ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
							SL.[Location] as [Location],
							SL.SerialNumber SerialNumber,
							'' as Comments,
							RO.RepairOrderId as ReferenceId,
							SL.Manufacturer,
							ROP.UpdatedDate  ReservedIssuedDate,
							ROP.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
						FROM dbo.[RepairOrderPart] ROP  WITH(NOLOCK)
							INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = ROP.StockLineId
							INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND ROP.MasterCompanyId = SLM.MasterCompanyId
							INNER JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
							--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.IssuedById
						WHERE ROP.MasterCompanyId = @MasterCompanyId AND ROP.StockLineId = @StocklineId
						AND ISNULL(RO.IsActive,0) = 1 AND ISNULL(ROP.IsActive,0) = 1 AND ISNULL(ROP.IsDeleted,0) = 0 AND ISNULL(RO.IsDeleted,0) = 0 
						AND ISNULL(SL.QuantityIssued,0) > 0 
						AND ISNULL(ROP.IsPiecePart, 0) = 1 AND ISNULL(SL.IsNonStock,0) = 0
							
				--* END: Repair Order Part For Issued (Incase of piece part) *--

		 END		 
		 ELSE IF(@DisplayType = 3)
		 BEGIN

				 --* Start: WorkOrderMaterialStockline For ALL *--
				 INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
						SELECT
						SL.PartNumber,
						SL.PNDescription,
						SL.Condition,
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
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
						INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
						WHERE (ISNULL(WMS.QtyIssued,0) > 0 OR ISNULL(WMS.QtyReserved,0) > 0)  AND WMS.StockLineId = @StocklineId
						AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
						AND WMS.MasterCompanyId = @MasterCompanyId 
						AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
				
				--* END: WorkOrderMaterialStockline For ALL *--

				--* Start: WorkOrderMaterialStocklineKit For ALL *--
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy ,StlQtyReserved,StlQtyIssued)
					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					WHERE (ISNULL(WMS.QtyIssued,0) > 0 OR ISNULL(WMS.QtyReserved,0) > 0)  AND WMS.StockLineId = @StocklineId
					AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
					AND WMS.MasterCompanyId = @MasterCompanyId 
					AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
				
				--* End: WorkOrderMaterialStocklinekit For ALL *--

				--* Start: SubWorkOrderMaterialStockline For ALL *--				
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)

					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					WHERE (ISNULL(SWMS.QtyIssued,0) > 0 OR ISNULL(SWMS.QtyReserved,0) > 0)  AND SWMS.StockLineId = @StocklineId
					AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  
					AND SWMS.MasterCompanyId = @MasterCompanyId 
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
				
				--* END: SubWorkOrderMaterialStockline For ALL *--				

				--* Start: SubWorkOrderMaterialStocklineKIT For ALL *--				
				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,SubReferenceId,MpnId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)

					SELECT
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					WHERE (ISNULL(SWMS.QtyIssued,0) > 0 OR ISNULL(SWMS.QtyReserved,0) > 0)  AND SWMS.StockLineId = @StocklineId
					AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  
					AND SWMS.MasterCompanyId = @MasterCompanyId 
					AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOCloseStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOCloseStatusId) AND ISNULL(SL.IsNonStock,0) = 0
					
				--* END: SubWorkOrderMaterialStockline For ALL *--

				--* START: TearDown WorkOrder For Issued *--

				INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
				SELECT	SL.PartNumber,
						SL.PNDescription,
						SL.Condition,
						SL.StockLineNumber,
						SL.ControlNumber,
						SL.IdNumber,
						SL.QtyReserved,
						SL.QuantityIssued,
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
						SL.UpdatedDate  ReservationDate,
						SL.UpdatedBy ReservedBy,
						SL.UpdatedDate  IssuedDate,
						SL.UpdatedBy IssuedBy,
						ISNULL(SL.Quantity,0) AS Quantity,
						ISNULL(SL.QuantityOnHand,0) AS QuantityOnHand,
						ISNULL(SL.QuantityAvailable,0) AS QuantityAvailable,
						SL.[Location] AS [Location],
						SL.SerialNumber SerialNumber,
						'' AS Comments,
						WO.WorkOrderId AS ReferenceId,
						SL.Manufacturer,
						WOP.UpdatedDate  ReservedIssuedDate,
						WOP.UpdatedBy ReservedIssuedBy,
						SL.QuantityReserved,
						SL.QuantityIssued
					FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)
						INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WOP.MasterCompanyId = SLM.MasterCompanyId
						INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId AND WO.[WorkOrderTypeId] = @TearDown
					WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.StockLineId = @StocklineId
						AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WOP.IsActive,0) = 1 AND ISNULL(WOP.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 
						AND ISNULL(SL.[QuantityIssued],0) > 0 AND ISNULL(SL.IsNonStock,0) = 0 

				--* END: TearDown WorkOrder For Issued *--

				--* Start: Repair Order Part For Issued (Incase of piece part) *--
				 INSERT INTO #tmptmpStockline (PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,ReservationDate,ReservedBy,IssuedDate,IssuedBy,Quantity,
											  QuantityOnHand,QuantityAvailable,[Location],SerialNumber,Comments,ReferenceId,Manufacturer,ReservedIssuedDate,ReservedIssuedBy,StlQtyReserved,StlQtyIssued)
						SELECT
							SL.PartNumber,
							SL.PNDescription,
							SL.Condition,
							SL.StockLineNumber,
							SL.ControlNumber,
							SL.IdNumber,
							ROP.QuantityReserved,
							SL.QuantityIssued,
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
							ROP.UpdatedDate  ReservationDate,
							ROP.UpdatedBy ReservedBy,
							ROP.UpdatedDate  IssuedDate,
							ROP.UpdatedBy IssuedBy,
							ISNULL(SL.Quantity,0) as Quantity,
							ISNULL(SL.QuantityOnHand,0) as QuantityOnHand,
							ISNULL(SL.QuantityAvailable,0) as QuantityAvailable,
							SL.[Location] as [Location],
							SL.SerialNumber SerialNumber,
							'' as Comments,
							RO.RepairOrderId as ReferenceId,
							SL.Manufacturer,
							ROP.UpdatedDate  ReservedIssuedDate,
							ROP.UpdatedBy ReservedIssuedBy,SL.QuantityReserved,SL.QuantityIssued
						FROM dbo.[RepairOrderPart] ROP  WITH(NOLOCK)
							INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = ROP.StockLineId
							INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND ROP.MasterCompanyId = SLM.MasterCompanyId
							INNER JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
							--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.IssuedById
						WHERE ROP.MasterCompanyId = @MasterCompanyId AND ROP.StockLineId = @StocklineId
						AND ISNULL(RO.IsActive,0) = 1 AND ISNULL(ROP.IsActive,0) = 1 AND ISNULL(ROP.IsDeleted,0) = 0 AND ISNULL(RO.IsDeleted,0) = 0 
						AND (ISNULL(ROP.QuantityReserved,0) > 0 OR ISNULL(SL.QuantityIssued,0) > 0)
						AND ISNULL(ROP.IsPiecePart, 0) = 1 AND ISNULL(SL.IsNonStock,0) = 0
							
				--* END: Repair Order Part For Issued (Incase of piece part) *--

		 END
		 SELECT * INTO #finalResult
		 FROM #tmptmpStockline
		
		 SET @Total = (SELECT TOP 1 COUNT(1) OVER () AS TotalRecordsCount FROM #finalResult); 
		  
		 SELECT @Total AS NumberOfItems, * FROM #finalResult
			
	END
	END TRY

 BEGIN CATCH          
   IF @@trancount > 0    
    PRINT 'ROLLBACK'   
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    ROLLBACK TRANSACTION;    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'GetStocklineReservedIssuedReportByStocklineId'     
        , @ProcedureParameters VARCHAR(3000)  = '@StocklineId = ' +  CAST(ISNULL(@StocklineId, '') AS varchar(100))  +''+  ' @DisplayType= ' +  CAST(ISNULL(@DisplayType, '') AS varchar(100))  +'' 
		+  '@MasterCompanyId = ' +  CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  +'' 
        , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
        exec spLogException     
                @DatabaseName           =  @DatabaseName    
                , @AdhocComments          =  @AdhocComments    
                , @ProcedureParameters    =  @ProcedureParameters    
                , @ApplicationName        =  @ApplicationName    
                , @ErrorLogID             =  @ErrorLogID OUTPUT ;    
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
        RETURN(1);    
  END CATCH 
 END