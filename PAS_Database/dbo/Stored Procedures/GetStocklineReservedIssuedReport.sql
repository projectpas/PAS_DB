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
	3    21-11-2024   Shrey Chandegara	    Updated Because managementstructure filter is not working.
	4    22-11-2024   RAJESH GAMI           Optimize the SP due to performance issue
	5    16-12-2024   RAJESH GAMI           Get only data where RepairOrderId is null in WorkOrderPartNumber, If already created RO then no need to show
	6    18-12-2024   RAJESH GAMI			handle QtyAdjustment in bulkadjustment
	7    19-12-2024   RAJESH GAMI		    Add MastercompanyId in the managementstructure JOIN
	8    26-12-2024   RAJESH GAMI		    Modified WPN to check RO is closed or not
exec GetStocklineReservedIssuedReport @PageNumber=1,@PageSize=20,@SortColumn=NULL,@SortOrder=1,@GlobalFilter=N'',@strFilter=N'1,5,6,52,84!2,7,8,9!3,11,10!4,13,12!!!!!!',@ViewType=N'1',@StockLineId=0,@PartNumber=N'0856AE15',@PartDescription=NULL,@Condition=NULL,@StocklineNumber=NULL,@ControlNumber=NULL,@IdNumber=NULL,@QuantityReserved=NULL,@QuantityIssued=NULL,@Module=NULL,@ReferenceNumber=NULL,@level1Str=NULL,@level2Str=NULL,@level3Str=NULL,@level4Str=NULL,@level5Str=NULL,@level6Str=NULL,@level7Str=NULL,@level8Str=NULL,@level9Str=NULL,@level10Str=NULL,@MasterCompanyId=1    
**************************************************************/    
CREATE   PROCEDURE [dbo].[GetStocklineReservedIssuedReport]
@PageNumber INT = NULL,
@PageSize INT = NULL,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@GlobalFilter varchar(50) = NULL,
@strFilter VARCHAR(MAX) = NULL,
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
@level1Str VARCHAR(MAX) = NULL,
@level2Str VARCHAR(MAX) = NULL,
@level3Str VARCHAR(MAX) = NULL,
@level4Str VARCHAR(MAX) = NULL,
@level5Str VARCHAR(MAX) = NULL,
@level6Str VARCHAR(MAX) = NULL,
@level7Str VARCHAR(MAX) = NULL,
@level8Str VARCHAR(MAX) = NULL,
@level9Str VARCHAR(MAX) = NULL,
@level10Str VARCHAR(MAX) = NULL,
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
	  DECLARE @RMACancel INT, @AdjPostedStatusId INT,  @BulkAdjModule varchar(50) = 'BulkAdjustments';
	  SET @WOStatusId = (SELECT  Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE Description = 'Closed')
	  SET @ROStatusId = (SELECT  ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Closed')
	  SET @ExchStatusId = (SELECT  ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Closed')
	  SET @ROCancelStatusId = (SELECT  ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Canceled')
	  SET @ExchCancelStatusId = (SELECT  ROStatusId FROM dbo.ROStatus WITH(NOLOCK) WHERE Description = 'Cancelled')
	  SET @RMAShipToVendor = (SELECT  VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Shipped To Vendor')
	  SET @RMAReplaced = (SELECT VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Replaced')
	  SET @RMARefunded = (SELECT  VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Refunded')
	  SET @RMACancel = (SELECT  VendorRMAStatusId FROM dbo.VendorRMAStatus WITH(NOLOCK) WHERE VendorRMAStatus = 'Canceled')
	  SET @AdjPostedStatusId =(SELECT TOP 1 Id FROM StocklineAdjustmentstatus where [Name]='Posted')

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

		IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPMSFilter
		END

		CREATE TABLE #TEMPMSFilter([ID] BIGINT  IDENTITY(1,1),[LevelIds] VARCHAR(MAX)); 

		INSERT INTO #TEMPMSFilter(LevelIds)	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!');

		DECLARE   
		@level1 VARCHAR(MAX) = NULL,  
		@level2 VARCHAR(MAX) = NULL,  
		@level3 VARCHAR(MAX) = NULL,  
		@level4 VARCHAR(MAX) = NULL,  
		@Level5 VARCHAR(MAX) = NULL,  
		@Level6 VARCHAR(MAX) = NULL,  
		@Level7 VARCHAR(MAX) = NULL,  
		@Level8 VARCHAR(MAX) = NULL,  
		@Level9 VARCHAR(MAX) = NULL,  
		@Level10 VARCHAR(MAX) = NULL 

		SELECT @level1 = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
		SELECT @level2 = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
		SELECT @level3 = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
		SELECT @level4 = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
		SELECT @level5 = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
		SELECT @level6 = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
		SELECT @level7 = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
		SELECT @level8 = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
		SELECT @level9 = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
		SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10 


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
			
		 IF(@ViewType = '1' OR @ViewType = '3')
		 BEGIN
				--* Start: WorkOrderPartNumber For ALL *--
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
						WOP.Quantity AS QtyReserved,
						0,
						'Workorder' AS Module,
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
						UPPER(SLM.Level10Name) AS level10
					FROM [dbo].[WorkOrderPartNumber] WOP   WITH(NOLOCK)
						INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON SL.StockLineId = WOP.StockLineId
						INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WOP.MasterCompanyId = SLM.MasterCompanyId
						WHERE ISNULL(WOP.Quantity,0) > 0 AND ISNULL(WOP.IsActive,0) = 1 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WOP.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND WOP.MasterCompanyId = @MasterCompanyId AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
							AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') 
							AND (ISNULL(WOP.RepairOrderId,0) = 0 OR ISNULL((SELECT RO.StatusId FROM Dbo.RepairOrder RO WITH (NOLOCK) WHERE Ro.RepairOrderId = ISNULL(WOP.RepairOrderId,0)),0) = @ROStatusId ) AND
						  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
						  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
						  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
						  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
						  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
						  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
						  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
						  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
						  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
						  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
						  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
						  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
						  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
						  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
						  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
						  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
						  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
						  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
						  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: WorkOrderPartNumber For ALL *--

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
				FROM [dbo].[RepairOrder] RO  WITH(NOLOCK)
					INNER JOIN [RepairOrderPart] ROP WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = ROP.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND RO.MasterCompanyId = SLM.MasterCompanyId
					WHERE ROP.MasterCompanyId = @MasterCompanyId AND ISNULL(RO.IsActive,0) = 1 AND ISNULL(ROP.IsParent,0) = 1 AND ISNULL(ROP.IsActive,0) = 1 AND ISNULL(ROP.IsDeleted,0) = 0 AND ISNULL(RO.IsDeleted,0) = 0  AND ISNULL(ROP.QuantityReserved,0) > 0 AND ISNULL(RO.StatusId,0) != @ROStatusId AND ISNULL(RO.StatusId,0) != @ROCancelStatusId 
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
				FROM [dbo].[ExchangeSalesOrder] ESO  WITH(NOLOCK)
					INNER JOIN [ExchangeSalesOrderReserveParts] ESR WITH(NOLOCK) ON ESO.ExchangeSalesOrderId = ESR.ExchangeSalesOrderId
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = ESR.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND ESO.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = ESR.ReservedById
					WHERE ESR.MasterCompanyId = @MasterCompanyId AND ISNULL(ESR.IsActive,0) = 1 AND ISNULL(ESO.IsActive,0) = 1 AND ISNULL(ESR.QtyToReserve,0) > 0 AND ISNULL(ESR.IsDeleted,0) = 0 AND ISNULL(ESO.IsDeleted,0) = 0 AND (ISNULL(ESO.StatusId,0) != @ExchStatusId OR ISNULL(ESR.PartStatusId,0) != @ExchCancelStatusId OR ISNULL(ESO.IsVendor,0) != 1)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND VRD.MasterCompanyId = SLM.MasterCompanyId
					WHERE VRD.MasterCompanyId = @MasterCompanyId AND ISNULL(VRD.IsActive,0) = 1 AND ISNULL(VRD.IsDeleted,0) = 0 AND ISNULL(VRD.Qty,0) > 0 AND (ISNULL(VRD.VendorRMAStatusId,0) NOT IN(@RMAShipToVendor,@RMAReplaced,@RMARefunded,@RMACancel))
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: RMA For Reserve *--

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
					SSTL.QtyReserved,
					'' ,
					'SalesOrder' AS Module,
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
					UPPER(SLM.Level10Name) AS level10
				FROM [dbo].[SalesOrderStocklineV1] SSTL  WITH(NOLOCK)
					INNER JOIN dbo.SalesOrderPartV1 SOP WITH(NOLOCK) ON SSTL.SalesOrderPartId = SOP.SalesOrderPartId
					INNER JOIN [dbo].[SalesOrder] ESO WITH(NOLOCK) ON SOP.SalesOrderId = ESO.SalesOrderId					
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SSTL.StockLineId
					INNER JOIN dbo.SalesOrderReserveParts SOR WITH(NOLOCK) ON SOR.SalesOrderId = ESO.SalesOrderId AND SOR.StockLineId = SSTL.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SSTL.MasterCompanyId = SLM.MasterCompanyId
					LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON SOR.ReservedById = emp.EmployeeId
					WHERE ESO.MasterCompanyId = @MasterCompanyId AND ISNULL(ESO.IsActive,0) = 1 AND ISNULL(SOP.IsActive,0) = 1 AND ISNULL(SSTL.QtyReserved,0) > 0 AND ISNULL(ESO.IsDeleted,0) = 0 AND ISNULL(SOP.IsDeleted,0) = 0
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: ExchangeSalesOrder For Reserve *--
				--* START: Stockline Bulk Adjustment For Reserve *--		
				
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
					SSTL.NewQty QtyReserved,
					'' ,
					'SalesOrder' AS Module,
					ESO.BulkStkLineAdjNumber,
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
				FROM dbo.[BulkStockLineAdjustmentDetails] SSTL WITH(NOLOCK)
					INNER JOIN [dbo].[BulkStockLineAdjustment] ESO WITH(NOLOCK) ON SSTL.BulkStkLineAdjId = ESO.BulkStkLineAdjId					
					INNER JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.StockLineId = SSTL.StockLineId
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SSTL.MasterCompanyId = SLM.MasterCompanyId
					WHERE SSTL.MasterCompanyId = @MasterCompanyId AND SSTL.StockLineId = @StocklineId 
					AND ISNULL(ESO.IsDeleted,0) = 0 AND ISNULL(SSTL.IsDeleted,0) = 0
					AND ISNULL(SSTL.NewQty,0) > 0 AND  ISNULL(SSTL.QtyAdjustment,0) > 0
					AND ESO.StatusId != @AdjPostedStatusId
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))


				
				--* END: Stockline Bulk Adjustment For Reserve *--
				
		 END

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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND ISNULL(WMS.QtyReserved,0) > 0 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND ISNULL(WMS.QtyReserved,0) > 0 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND ISNULL(SWMS.QtyReserved,0) > 0 AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0 AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					--INNER JOIN [dbo].[Employee] EM WITH(NOLOCK) ON EM.EmployeeId = SWM.ReservedById
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND ISNULL(SWMS.QtyReserved,0) > 0 AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0 AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: SubWorkOrderMaterialStocklineKit For Reserve *--


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
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
						INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
						--INNER JOIN [dbo].[Employee] EM  WITH(NOLOCK) ON EM.EmployeeId = WM.IssuedById
						WHERE WMS.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND ISNULL(WMS.QtyIssued,0) > 0 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
							AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
						  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
						  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
						  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
						  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
						  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
						  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
						  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
						  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
						  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
						  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
						  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
						  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
						  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
						  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
						  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
						  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
						  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
						  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
						  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					WHERE WMS.MasterCompanyId = @MasterCompanyId AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND ISNULL(WMS.QtyIssued,0) > 0 AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
						  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
						  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
						  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
						  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
						  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
						  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
						  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
						  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
						  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
						  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
						  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
						  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
						  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
						  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
						  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
						  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
						  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
						  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
						  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.QtyIssued,0) > 0  AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
						  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
						  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
						  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
						  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
						  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
						  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
						  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
						  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
						  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
						  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
						  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
						  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
						  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
						  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
						  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
						  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
						  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
						  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
						  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					WHERE SWMS.MasterCompanyId = @MasterCompanyId AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.QtyIssued,0) > 0 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

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
						INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
						INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
						WHERE   ISNULL(WMS.QtyIssued,0) > 0 OR ISNULL(WMS.QtyReserved,0) > 0 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND WMS.MasterCompanyId = @MasterCompanyId AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
							AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
						  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
						  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
						  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
						  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
						  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
						  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
						  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
						  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
						  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
						  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
						  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
						  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
						  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
						  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
						  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
						  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
						  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
						  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
						  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM  WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND WMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[WorkOrder] WO  WITH(NOLOCK) ON WO.WorkOrderId = WM.WorkOrderId
					WHERE ISNULL(WMS.QtyIssued,0) > 0 OR ISNULL(WMS.QtyReserved,0) > 0 AND ISNULL(WO.IsActive,0) = 1 AND ISNULL(WMS.IsActive,0) = 1 AND ISNULL(WMS.IsDeleted,0) = 0 AND ISNULL(WO.IsDeleted,0) = 0 AND WMS.MasterCompanyId = @MasterCompanyId AND (ISNULL(WOP.IsFinishGood,0) != 1 OR ISNULL(WOP.IsClosed,0) != 1 OR ISNULL(WOP.WorkOrderStatusId,0) != @WOStatusId OR ISNULL(WO.WorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					WHERE ISNULL(SWMS.QtyIssued,0) > 0 OR ISNULL(SWMS.QtyReserved,0) > 0 AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  AND SWMS.MasterCompanyId = @MasterCompanyId AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
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
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON SLM.ReferenceID = SL.StockLineId AND SWMS.MasterCompanyId = SLM.MasterCompanyId
					INNER JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId
					WHERE ISNULL(SWMS.QtyIssued,0) > 0 OR ISNULL(SWMS.QtyReserved,0) > 0 AND ISNULL(SWO.IsActive,0) = 1 AND ISNULL(SWMS.IsActive,0) = 1 AND ISNULL(SWMS.IsDeleted,0) = 0 AND ISNULL(SWO.IsDeleted,0) = 0  AND SWMS.MasterCompanyId = @MasterCompanyId AND (ISNULL(SWOP.IsFinishGood,0) != 1 OR ISNULL(SWOP.IsClosed,0) != 1 OR ISNULL(SWOP.SubWorkOrderStatusId,0) != @WOStatusId OR ISNULL(SWO.SubWorkOrderStatusId,0) != @WOStatusId)
						AND(ISNULL(@level1Str,'') ='' OR [Level1Name] LIKE '%' + @level1Str + '%') AND
					  (ISNULL(@level2Str,'') ='' OR [level2Name] LIKE '%' + @level2Str + '%') AND
					  (ISNULL(@level3Str,'') ='' OR [level3Name] LIKE '%' + @level3Str + '%') AND
					  (ISNULL(@level4Str,'') ='' OR [level4Name] LIKE '%' + @level4Str + '%') AND
					  (ISNULL(@level5Str,'') ='' OR [level5Name] LIKE '%' + @level5Str + '%') AND
					  (ISNULL(@level6Str,'') ='' OR [level6Name] LIKE '%' + @level6Str + '%') AND
					  (ISNULL(@level7Str,'') ='' OR [level7Name] LIKE '%' + @level7Str + '%') AND
					  (ISNULL(@level8Str,'') ='' OR [level8Name] LIKE '%' + @level8Str + '%') AND
					  (ISNULL(@level9Str,'') ='' OR [level9Name] LIKE '%' + @level9Str + '%') AND
					  (ISNULL(@level10Str,'') ='' OR [level10Name] LIKE '%' + @level10Str + '%') AND
					  (ISNULL(@Level1,'') ='' OR [Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,','))) AND      
					  (ISNULL(@Level2,'') ='' OR [Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,','))) AND      
					  (ISNULL(@Level3,'') ='' OR [Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,','))) AND     
					  (ISNULL(@Level4,'') ='' OR [Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,','))) AND     
					  (ISNULL(@Level5,'') ='' OR [Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,','))) AND     
					  (ISNULL(@Level6,'') ='' OR [Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,','))) AND     
					  (ISNULL(@Level7,'') ='' OR [Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,','))) AND     
					  (ISNULL(@Level8,'') ='' OR [Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,','))) AND     
					  (ISNULL(@Level9,'') ='' OR [Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,','))) AND     
					  (ISNULL(@Level10,'') =''  OR [Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
				--* END: SubWorkOrderMaterialStockline For ALL *--

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
		 (ISNULL(@ReferenceNumber,'') ='' OR [ReferenceNumber] LIKE '%' + @ReferenceNumber+'%') 
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