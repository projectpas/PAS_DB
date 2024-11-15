/*************************************************************               
 ** File:   [GetStocklineReservedIssuedReport]               
 ** Author: Shrey Chandegara    
 ** Description:  
 ** Purpose:             
 ** Date:   29-10-2024    
    
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------			--------------------------------              
    1    29-10-2024   Shrey Chandegara		Created    
	2    14-11-2024   Rajesh Gami			Return StockLineId

 exec GetStocklineReservedIssuedReport @PageNumber=1,@PageSize=20,@SortColumn=NULL,@SortOrder=1,@GlobalFilter=N'',@ViewType=N'1',
		@StockLineId=0,@PartNumber=NULL,@PartDescription=NULL,@Condition=NULL,@StocklineNumber=NULL,@ControlNumber=NULL,@IdNumber=NULL,
		@QuantityReserved=NULL,@QuantityIssued=NULL,@Module=NULL,@ReferenceNumber=NULL,@ReservationDate=NULL,@IssueDate=NULL,@ReservedOrIssuedBy=NULL,
		@level1=NULL,@level2=NULL,@level3=NULL,@level4=NULL,@level5=NULL,@level6=NULL,@level7=NULL,@level8=NULL,@level9=NULL,@level10=NULL,@MasterCompanyId=1    
**************************************************************/    
CREATE   PROCEDURE [dbo].[GetStocklineReservedIssuedReport]
@PageNumber INT = NULL,
@PageSize INT = NULL,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@GlobalFilter varchar(50) = NULL,
@ViewType varchar(50) = NULL,
@StockLineId BIGINT,
@PartNumber NVARCHAR(50),
@PartDescription NVARCHAR(255),
@Condition NVARCHAR(50),
@StocklineNumber NVARCHAR(50),
@ControlNumber NVARCHAR(50),
@IdNumber NVARCHAR(50),
@QuantityReserved INT = NULL,
@QuantityIssued INT = NULL,
@Module NVARCHAR(50),
@ReferenceNumber NVARCHAR(50),
--@ReservationDate DATETIME = NULL,
--@IssueDate DATETIME = NULL,
--@ReservedOrIssuedBy NVARCHAR(100),
@level1 VARCHAR(500) = NULL,
@level2 VARCHAR(500) = NULL,
@level3 VARCHAR(500) = NULL,
@level4 VARCHAR(500) = NULL,
@level5 VARCHAR(500) = NULL,
@level6 VARCHAR(500) = NULL,
@level7 VARCHAR(500) = NULL,
@level8 VARCHAR(500) = NULL,
@level9 VARCHAR(500) = NULL,
@level10 VARCHAR(500) = NULL,
@Mastercompanyid INT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


      DECLARE @RecordFrom INT;
	  DECLARE @Total int;
	  DECLARE @Count INT;
	  DECLARE @WOStatusId INT;
	  DECLARE @ExchStatusId INT;
	  DECLARE @ExchCancelStatusId INT;
	  DECLARE @ROStatusId INT;
	  DECLARE @ROCancelStatusId INT;
	  DECLARE @RMAShipToVendor INT;
	  DECLARE @RMAReplaced INT;
	  DECLARE @RMARefunded INT;
	  DECLARE @RMACancel INT;
	  SET @WOStatusId = (SELECT  Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE Description = 'Closed')
	  SET @ROStatusId = (SELECT  ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Closed')
	  SET @ExchStatusId = (SELECT  ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Closed')
	  SET @ROCancelStatusId = (SELECT  ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Canceled')
	  SET @ExchCancelStatusId = (SELECT  ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Cancelled')
	  SET @RMAShipToVendor = (SELECT  VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Shipped To Vendor')
	  SET @RMAReplaced = (SELECT VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Replaced')
	  SET @RMARefunded = (SELECT  VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Refunded')
	  SET @RMACancel = (SELECT  VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Canceled')

	  SET @RecordFrom = (@PageNumber - 1) * @PageSize;
	  IF @SortColumn IS NULL
	  BEGIN
	  	SET @SortColumn = UPPER('QUANTITYRESERVED')		
	  END 
	  ELSE
	  BEGIN 
	  	SET @SortColumn = UPPER(@SortColumn)		
	  END	
	
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
	  StockLineId BIGINT NULL,
      PartNumber VARCHAR(100) NULL,
	  PartDescription VARCHAR(MAX) NULL,
	  Condition VARCHAR(100) NULL,
	  StocklineNumber VARCHAR(100) NULL,
	  ControlNumber VARCHAR(100) NULL,
	  IdNumber VARCHAR(100) NULL,
	  QuantityReserved INT NULL,
	  QuantityIssued INT NULL,
	  Module VARCHAR(50) NULL,
	  ReferenceNumber VARCHAR(50) NULL,
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
	  level10 VARCHAR(MAX) NULL
     )    
		 IF(@ViewType = '1')
		 BEGIN

				--* Start: WorkOrderMaterialStockline For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					Sl.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WMS.QtyReserved,
					WMS.QtyIssued,
					'WorkOrderMaterial' AS Module,
					WO.WorkOrderNum ,
					--WM.ReservedDate ,
					--WM.IssuedDate ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [WorkOrderMaterialStockLine] WMS WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderMaterials] WM WITH(NOLOCK) ON WM.WorkOrderMaterialsId = WMS.WorkOrderMaterialsId
					INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = WM.ReservedById
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND ISNULL(WMS.QtyReserved,0) > 0 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: WorkOrderMaterialStockline For Reserve *--

				--* Start: WorkOrderMaterialStocklineKit For Reserve *--					
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					sl.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WMS.QtyReserved,
					WMS.QtyIssued,
					'WorkOrderMaterialKit' AS Module,
					WO.WorkOrderNum ,
					--WM.ReservedDate,
					--WM.IssuedDate ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [WorkOrderMaterialStockLineKit] WMS  WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderMaterialsKit] WM WITH(NOLOCK) ON WM.WorkOrderMaterialsKitId = WMS.WorkOrderMaterialsKitId
					INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)  ON WOP.ID = WF.WorkOrderPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.ReservedById
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND ISNULL(WMS.QtyReserved,0) > 0 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: WorkOrderMaterialStocklineKit For Reserve *--

				--* START: SubWorkOrderMaterialStockline For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					sl.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					'SubWorkOrderMaterial' AS Module,
					SWO.SubWorkOrderNo ,
					--SWM.ReservedDate ,
					--SWM.IssuedDate ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [SubWorkOrderMaterialStockLine] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterials] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsId = SWMS.SubWorkOrderMaterialsId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.ReservedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND ISNULL(SWMS.QtyReserved,0) > 0 AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0 AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: SubWorkOrderMaterialStockline For Reserve *--

				--* START: SubWorkOrderMaterialStocklineKit For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					sl.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					'SubWorkOrderMaterialKit' AS Module,
					SWO.SubWorkOrderNo ,
					--SWM.ReservedDate ,
					--SWM.IssuedDate ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [SubWorkOrderMaterialStockLineKit] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterialsKit] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsKitId = SWMS.SubWorkOrderMaterialsKitId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.ReservedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND ISNULL(SWMS.QtyReserved,0) > 0 AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0 AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: SubWorkOrderMaterialStocklineKit For Reserve *--


				--* START: RepairOrder For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
				SELECT
					sl.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					ROP.QuantityReserved,
					'' ,
					'RepairOrder' AS Module,
					RO.RepairOrderNumber,
					--ROP.CreatedDate,
					--null ,				
					--(ROP.CreatedBy), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [RepairOrderPart] ROP WITH(NOLOCK)
					INNER JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = ROP.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					WHERE ROP.MasterCompanyId = @MasterCompanyId AND ISNULL(RO.IsActive,0) = 1 AND ISNULL(ROP.IsActive,0) = 1 AND ISNULL(ROP.IsDeleted,0) = 0 AND ISNULL(RO.IsDeleted,0) = 0 AND ISNULL(ROP.QuantityReserved,0) > 0  AND ISNULL(RO.StatusId,0) != @ROStatusId AND ISNULL(RO.StatusId,0) != @ROCancelStatusId 
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: RepairOrder For Reserve *--

				--* START: ExchangeSalesOrder For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					ESR.QtyToReserve,
					'' ,
					'ExchangeSalesOrder' AS Module,
					ESO.ExchangeSalesOrderNumber,
					--ESR.ReservedDate,
					--null ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [ExchangeSalesOrderReserveParts] ESR WITH(NOLOCK)
					INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH(NOLOCK) ON ESO.ExchangeSalesOrderId = ESR.ExchangeSalesOrderId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = ESR.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = ESR.ReservedById
					WHERE ESR.MasterCompanyId = @MasterCompanyId AND ISNULL(ESR.IsActive,0) = 1 AND ISNULL(ESO.IsActive,0) = 1 AND ISNULL(ESR.IsDeleted,0) = 0 AND ISNULL(ESO.IsDeleted,0) = 0 AND ISNULL(ESR.QtyToReserve,0) > 0 AND (ISNULL(ESO.StatusId,0) != @ExchStatusId OR ISNULL(ESR.PartStatusId,0) != @ExchCancelStatusId OR ISNULL(ESO.IsVendor,0) != 1)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: ExchangeSalesOrder For Reserve *--

				--* START: RMA For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					VRD.Qty,
					'' ,
					'RMA' AS Module,
					VRD.RMANum,
					--VRD.CreatedDate,
					--null ,				
					--VRD.CreatedBy, 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [VendorRMADetail] VRD WITH(NOLOCK)
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = VRD.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					WHERE VRD.MasterCompanyId = @MasterCompanyId AND ISNULL(VRD.IsActive,0) = 1 AND ISNULL(VRD.IsDeleted,0) = 0 AND ISNULL(VRD.Qty,0) > 0 AND (ISNULL(VRD.VendorRMAStatusId,0) NOT IN(@RMAShipToVendor,@RMAReplaced,@RMARefunded,@RMACancel))
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: RMA For Reserve *--


		 END
		 IF(@ViewType = '2')
		 BEGIN

				--* Start: WorkOrderMaterialStockline For Issued *--
				 INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
						SELECT
						SL.StockLineId,
						SL.PartNumber,
						SL.PNDescription,
						SL.Condition,
						SL.StockLineNumber,
						SL.ControlNumber,
						SL.IdNumber,
						WMS.QtyReserved,
						WMS.QtyIssued,
						'WorkOrderMaterial' AS Module,
						WO.WorkOrderNum ,
						--WM.ReservedDate ,
						--WM.IssuedDate,				
						--(EM.FirstName + ' '+ EM.LastName), 
						UPPER(SLM.Level1Name) AS level1,  
						UPPER(SLM.Level2Name) AS level2, 
						UPPER(SLM.Level3Name) AS level3, 
						UPPER(SLM.Level4Name) AS level4, 
						UPPER(SLM.Level5Name) AS level5, 
						UPPER(SLM.Level6Name) AS level6, 
						UPPER(SLM.Level7Name) AS level7, 
						UPPER(SLM.Level8Name) AS level8, 
						UPPER(SLM.Level9Name) AS level9, 
						UPPER(SLM.Level10Name) AS level10
					FROM [WorkOrderMaterialStockLine] WMS  WITH(NOLOCK)
						INNER JOIN [dbo].[WorkOrderMaterials] WM  WITH(NOLOCK) ON WM.WorkOrderMaterialsId = WMS.WorkOrderMaterialsId
						INNER JOIN [dbo].[WorkOrderWorkFlow] WF  WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
						INNER JOIN [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
						INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
						INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
						--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.IssuedById
						WHERE WMS.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND ISNULL(WMS.QtyIssued,0) > 0 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
							AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
							AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
							AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
							AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
							AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
							AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
							AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
							AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
							AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
							AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: WorkOrderMaterialStockline For Issued *--

				--* START: WorkOrderMaterialStocklineKit For Issued *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WMS.QtyReserved,
					WMS.QtyIssued,
					'WorkOrderMaterialKit' AS Module,
					WO.WorkOrderNum ,
					--WM.ReservedDate,
					--WM.IssuedDate ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [WorkOrderMaterialStockLineKit] WMS  WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderMaterialsKit] WM  WITH(NOLOCK) ON WM.WorkOrderMaterialsKitId = WMS.WorkOrderMaterialsKitId
					INNER JOIN [dbo].[WorkOrderWorkFlow] WF  WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
					INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.IssuedById
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND ISNULL(WMS.QtyIssued,0) > 0 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: WorkOrderMaterialStocklineKit For Issued *--

				--* START: SUBWorkOrderMaterialStockline For Issued *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)

					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					'SubWorkOrderMaterial' AS Module,
					SWO.SubWorkOrderNo ,
					--SWM.ReservedDate ,
					--SWM.IssuedDate ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [SubWorkOrderMaterialStockLine] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterials] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsId = SWMS.SubWorkOrderMaterialsId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.IssuedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.QtyIssued,0) > 0  AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

				--* END: SUBWorkOrderMaterialStockline For Issued *--

				--* START: SUBWorkOrderMaterialStocklineKit For Issued *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)

					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					'SubWorkOrderMaterialKit' AS Module,
					SWO.SubWorkOrderNo ,
					--SWM.ReservedDate ,
					--SWM.IssuedDate ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [SubWorkOrderMaterialStockLineKit] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterialsKit] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsKitId = SWMS.SubWorkOrderMaterialsKitId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.IssuedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.QtyIssued,0) > 0 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

				--* END: SUBWorkOrderMaterialStockline For Issued *--


		 END
		 IF(@ViewType = '3')
		 BEGIN

				 --* Start: WorkOrderMaterialStockline For ALL *--
				 INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
												  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
						SELECT
						SL.StockLineId,
						SL.PartNumber,
						SL.PNDescription,
						SL.Condition,
						SL.StockLineNumber,
						SL.ControlNumber,
						SL.IdNumber,
						WMS.QtyReserved,
						WMS.QtyIssued,
						'WorkOrderMaterial' AS Module,
						WO.WorkOrderNum ,
						--WM.ReservedDate ,
						--WM.IssuedDate,				
						--CASE WHEN WMS.QtyReserved > WMS.QtyIssued THEN (EM.FirstName + ' '+ EM.LastName) ELSE (EMP.FirstName + ' '+ EMP.LastName) END, 
						UPPER(SLM.Level1Name) AS level1,  
						UPPER(SLM.Level2Name) AS level2, 
						UPPER(SLM.Level3Name) AS level3, 
						UPPER(SLM.Level4Name) AS level4, 
						UPPER(SLM.Level5Name) AS level5, 
						UPPER(SLM.Level6Name) AS level6, 
						UPPER(SLM.Level7Name) AS level7, 
						UPPER(SLM.Level8Name) AS level8, 
						UPPER(SLM.Level9Name) AS level9, 
						UPPER(SLM.Level10Name) AS level10
					FROM [WorkOrderMaterialStockLine] WMS  WITH(NOLOCK)
						INNER JOIN [dbo].[WorkOrderMaterials] WM  WITH(NOLOCK) ON WM.WorkOrderMaterialsId = WMS.WorkOrderMaterialsId
						INNER JOIN [dbo].[WorkOrderWorkFlow] WF  WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
						INNER JOIN [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
						INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
						INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
						--INNER JOIN [dbo].[Employee] EM   WITH(NOLOCK)ON EM.EmployeeId = WM.ReservedById
						--INNER JOIN [dbo].[Employee] EMP  WITH(NOLOCK) ON EMP.EmployeeId = WM.IssuedById
						WHERE   ISNULL(WMS.QtyIssued,0) > 0 OR ISNULL(WMS.QtyReserved,0) > 0 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND WMS.MasterCompanyId = @MasterCompanyId AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
							AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
							AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
							AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
							AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
							AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
							AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
							AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
							AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
							AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
							AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: WorkOrderMaterialStockline For ALL *--

				--* Start: WorkOrderMaterialStocklineKit For ALL *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					WMS.QtyReserved,
					WMS.QtyIssued,
					'WorkOrderMaterialKit' AS Module,
					WO.WorkOrderNum ,
					--WM.ReservedDate,
					--WM.IssuedDate ,				
					--CASE WHEN WMS.QtyReserved > WMS.QtyIssued THEN (EM.FirstName + ' '+ EM.LastName) ELSE (EMP.FirstName + ' '+ EMP.LastName) END,  
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [WorkOrderMaterialStockLineKit] WMS  WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderMaterialsKit] WM  WITH(NOLOCK) ON WM.WorkOrderMaterialsKitId = WMS.WorkOrderMaterialsKitId
					INNER JOIN [dbo].[WorkOrderWorkFlow] WF  WITH(NOLOCK) ON WF.WorkFlowWorkOrderId = WM.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK) ON WOP.ID = WF.WorkOrderPartNoId
					INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					--INNER JOIN [dbo].[Employee] EM   WITH(NOLOCK)ON EM.EmployeeId = WM.ReservedById
					--INNER JOIN [dbo].[Employee] EMP  WITH(NOLOCK) ON EMP.EmployeeId = WM.IssuedById
					WHERE ISNULL(WMS.QtyIssued,0) > 0 OR ISNULL(WMS.QtyReserved,0) > 0 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND WMS.MasterCompanyId = @MasterCompanyId AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* End: WorkOrderMaterialStocklinekit For ALL *--

				--* Start: SubWorkOrderMaterialStockline For ALL *--				
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)

					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					'SubWorkOrderMaterial' AS Module,
					SWO.SubWorkOrderNo ,
					--SWM.ReservedDate ,
					--SWM.IssuedDate ,				
					--CASE WHEN SWMS.QtyReserved > SWMS.QtyIssued THEN (EM.FirstName + ' '+ EM.LastName) ELSE (EMP.FirstName + ' '+ EMP.LastName) END,   
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [SubWorkOrderMaterialStockLine] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterials] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsId = SWMS.SubWorkOrderMaterialsId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.ReservedById
					--INNER JOIN [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = SWM.IssuedById
					WHERE ISNULL(SWMS.QtyIssued,0) > 0 OR ISNULL(SWMS.QtyReserved,0) > 0 AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  AND SWMS.MasterCompanyId = @MasterCompanyId AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: SubWorkOrderMaterialStockline For ALL *--				

				--* Start: SubWorkOrderMaterialStocklineKIT For ALL *--				
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)

					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					SWMS.QtyReserved,
					SWMS.QtyIssued,
					'SubWorkOrderMaterialKit' AS Module,
					SWO.SubWorkOrderNo ,
					--SWM.ReservedDate ,
					--SWM.IssuedDate ,				
					--CASE WHEN SWMS.QtyReserved > SWMS.QtyIssued THEN (EM.FirstName + ' '+ EM.LastName) ELSE (EMP.FirstName + ' '+ EMP.LastName) END,   
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [SubWorkOrderMaterialStockLineKit] SWMS WITH(NOLOCK)
					INNER JOIN [dbo].[SubWorkOrderMaterialsKit] SWM WITH(NOLOCK) ON SWM.SubWorkOrderMaterialsKitId = SWMS.SubWorkOrderMaterialsKitId
					INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOP WITH(NOLOCK) ON SWOP.SubWOPartNoId = SWM.SubWOPartNoId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SWMS.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.ReservedById
					--INNER JOIN [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = SWM.IssuedById
					WHERE ISNULL(SWMS.QtyIssued,0) > 0 OR ISNULL(SWMS.QtyReserved,0) > 0 AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  AND SWMS.MasterCompanyId = @MasterCompanyId AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: SubWorkOrderMaterialStockline For ALL *--

				--* START: RepairOrder For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					ROP.QuantityReserved,
					'' ,
					'RepairOrder' AS Module,
					RO.RepairOrderNumber,
					--ROP.CreatedDate,
					--null ,				
					--(ROP.CreatedBy), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [RepairOrderPart] ROP WITH(NOLOCK)
					INNER JOIN [dbo].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = ROP.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					WHERE ROP.MasterCompanyId = @MasterCompanyId AND ISNULL(RO.IsActive,0) = 1 AND ISNULL(ROP.IsActive,0) = 1 AND ISNULL(ROP.IsDeleted,0) = 0 AND ISNULL(RO.IsDeleted,0) = 0  AND ISNULL(ROP.QuantityReserved,0) > 0 AND ISNULL(RO.StatusId,0) != @ROStatusId AND ISNULL(RO.StatusId,0) != @ROCancelStatusId 
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: RepairOrder For Reserve *--

				--* START: ExchangeSalesOrder For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					ESR.QtyToReserve,
					'' ,
					'ExchangeSalesOrder' AS Module,
					ESO.ExchangeSalesOrderNumber,
					--ESR.ReservedDate,
					--null ,				
					--(EM.FirstName + ' '+ EM.LastName), 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [ExchangeSalesOrderReserveParts] ESR WITH(NOLOCK)
					INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH(NOLOCK) ON ESO.ExchangeSalesOrderId = ESR.ExchangeSalesOrderId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = ESR.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = ESR.ReservedById
					WHERE ESR.MasterCompanyId = @MasterCompanyId AND ISNULL(ESR.IsActive,0) = 1 AND ISNULL(ESO.IsActive,0) = 1 AND ISNULL(ESR.QtyToReserve,0) > 0 AND ISNULL(ESR.IsDeleted,0) = 0 AND ISNULL(ESO.IsDeleted,0) = 0 AND (ISNULL(ESO.StatusId,0) != @ExchStatusId OR ISNULL(ESR.PartStatusId,0) != @ExchCancelStatusId OR ISNULL(ESO.IsVendor,0) != 1)
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: ExchangeSalesOrder For Reserve *--

				--* START: RMA For Reserve *--
				INSERT INTO #tmptmpStockline (StockLineId,PartNumber,PartDescription,Condition,StocklineNumber,ControlNumber,IdNumber,QuantityReserved,QuantityIssued,Module,ReferenceNumber,
											  level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
					SELECT
					SL.StockLineId,
					SL.PartNumber,
					SL.PNDescription,
					SL.Condition,
					SL.StockLineNumber,
					SL.ControlNumber,
					SL.IdNumber,
					VRD.Qty,
					'' ,
					'RMA' AS Module,
					VRD.RMANum,
					--VRD.CreatedDate,
					--null ,				
					--VRD.CreatedBy, 
					UPPER(SLM.Level1Name) AS level1,  
					UPPER(SLM.Level2Name) AS level2, 
					UPPER(SLM.Level3Name) AS level3, 
					UPPER(SLM.Level4Name) AS level4, 
					UPPER(SLM.Level5Name) AS level5, 
					UPPER(SLM.Level6Name) AS level6, 
					UPPER(SLM.Level7Name) AS level7, 
					UPPER(SLM.Level8Name) AS level8, 
					UPPER(SLM.Level9Name) AS level9, 
					UPPER(SLM.Level10Name) AS level10
				FROM [VendorRMADetail] VRD WITH(NOLOCK)
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = VRD.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId
					WHERE VRD.MasterCompanyId = @MasterCompanyId AND ISNULL(VRD.IsActive,0) = 1 AND ISNULL(VRD.IsDeleted,0) = 0 AND ISNULL(VRD.Qty,0) > 0 AND (ISNULL(VRD.VendorRMAStatusId,0) NOT IN(@RMAShipToVendor,@RMAReplaced,@RMARefunded,@RMACancel))
						AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
						AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
						AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
						AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
						AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
						AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
						AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
						AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
						AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
						AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: RMA For Reserve *--


		 END
		  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
		  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
		 
		 select * into #finalResult
		 FROM #tmptmpStockline
		 WHERE (
		 (ISNULL(@PartNumber,'') ='' OR [PartNumber] LIKE '%' + @PartNumber+'%') AND
		 (ISNULL(@PartDescription,'') ='' OR [PartDescription] LIKE '%' + @PartDescription+'%') AND
		 (ISNULL(@Condition,'') ='' OR [Condition] LIKE '%' + @Condition+'%') AND
		 (ISNULL(@StocklineNumber,'') ='' OR [StocklineNumber] LIKE '%' + @StocklineNumber+'%') AND
		 (ISNULL(@ControlNumber,'') ='' OR [ControlNumber] LIKE '%' + @ControlNumber+'%') AND
		 (ISNULL(@IdNumber,'') ='' OR [IdNumber] LIKE '%' + @IdNumber+'%') AND
		 (ISNULL(@QuantityReserved,0) = 0 OR [QuantityReserved] = @QuantityReserved) AND
		 (ISNULL(@QuantityIssued,0) = 0 OR [QuantityIssued] = @QuantityIssued) AND
		 (ISNULL(@Module,'') ='' OR [Module] LIKE '%' + @Module+'%') AND
		 (ISNULL(@ReferenceNumber,'') ='' OR [ReferenceNumber] LIKE '%' + @ReferenceNumber+'%') AND
		 --(ISNULL(@ReservationDate,'') ='' OR CAST([ReservationDate] AS DATE) = CAST(@ReservationDate AS DATE)) AND
		 --(ISNULL(@IssueDate,'') ='' OR CAST([IssueDate] AS DATE) = CAST(@IssueDate AS DATE)) AND
		 --(ISNULL(@ReservedOrIssuedBy,'') ='' OR [ReservedOrIssuedBy] LIKE '%' + @ReservedOrIssuedBy+'%') AND
		 (ISNULL(@level1,'') ='' OR [level1] LIKE '%' + @level1 + '%') AND
		 (ISNULL(@level2,'') ='' OR [level2] LIKE '%' + @level2 + '%') AND
		 (ISNULL(@level3,'') ='' OR [level3] LIKE '%' + @level3 + '%') AND
		 (ISNULL(@level4,'') ='' OR [level4] LIKE '%' + @level4 + '%') AND
		 (ISNULL(@level5,'') ='' OR [level5] LIKE '%' + @level5 + '%') AND
		 (ISNULL(@level6,'') ='' OR [level6] LIKE '%' + @level6 + '%') AND
		 (ISNULL(@level7,'') ='' OR [level7] LIKE '%' + @level7 + '%') AND
		 (ISNULL(@level8,'') ='' OR [level8] LIKE '%' + @level8 + '%') AND
		 (ISNULL(@level9,'') ='' OR [level9] LIKE '%' + @level9 + '%') AND
		 (ISNULL(@level10,'') ='' OR [level10] LIKE '%' + @level10 + '%')
		 )




		 SET @Total = (SELECT TOP 1 COUNT(1) OVER () AS TotalRecordsCount FROM #finalResult); 

		  
		 select @Total as NumberOfItems, * from #finalResult
		 ORDER BY  					 
			CASE WHEN (@SortOrder=1  AND @SortColumn='PARTNUMBER') THEN [PartNumber] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER') THEN [PartNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTDESCRIPTION') THEN [PartDescription] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTION') THEN [PartDescription] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CONDITION') THEN [Condition] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONDITION') THEN [Condition] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'STOCKLINENUMBER') THEN [StocklineNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'STOCKLINENUMBER') THEN [StocklineNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CONTROLNUMBER') THEN [ControlNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONTROLNUMBER') THEN [ControlNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'IDNUMBER') THEN [IdNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'IDNUMBER') THEN [IdNumber] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QUANTITYRESERVED') THEN [QuantityReserved] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUANTITYRESERVED') THEN [QuantityReserved] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QUANTITYISSUED') THEN [QuantityIssued] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUANTITYISSUED') THEN [QuantityIssued] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MODULE') THEN [Module] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MODULE') THEN [Module] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'REFERENCENUMBER') THEN [ReferenceNumber] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'REFERENCENUMBER') THEN [ReferenceNumber] END DESC,
			--CASE WHEN (@SortOrder = 1 AND @SortColumn = 'RESERVATIONDATE') THEN [ReservationDate] END ASC,
			--CASE WHEN (@SortOrder = -1 AND @SortColumn = 'RESERVATIONDATE') THEN [ReservationDate] END DESC,
			--CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ISSUEDATE') THEN [IssueDate] END ASC,
			--CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ISSUEDATE') THEN [IssueDate] END DESC,
			--CASE WHEN (@SortOrder = 1 AND @SortColumn = 'RESERVEDORISSUEDBY') THEN [ReservedORIssuedBy] END ASC,
			--CASE WHEN (@SortOrder = -1 AND @SortColumn = 'RESERVEDORISSUEDBY') THEN [ReservedORIssuedBy] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL1') THEN [Level1] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL1') THEN [Level1] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL2') THEN [Level2] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL2') THEN [Level2] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL3') THEN [Level3] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL3') THEN [Level3] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL4') THEN [Level4] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL4') THEN [Level4] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL5') THEN [Level5] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL5') THEN [Level5] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL6') THEN [Level6] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL6') THEN [Level6] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL7') THEN [Level7] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL7') THEN [Level7] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL8') THEN [Level8] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL8') THEN [Level8] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL9') THEN [Level9] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL9') THEN [Level9] END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LEVEL10') THEN [Level10] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LEVEL10') THEN [Level10] END DESC
			OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY
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
        , @AdhocComments     VARCHAR(150)    = 'GetStocklineReservedIssuedReport'     
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' +  CAST(ISNULL(@PageNumber, '') AS varchar(100))  +''    
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