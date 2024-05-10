/*********************             
 ** File:   GET WIP REPORTS DATA          
 ** Author:  HEMANT SALIYA  
 ** Description: This SP Is Used to Get WIP reports Data
 ** Purpose:           
 ** Date:  08-MAY-2024
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    05/08/2024   HEMANT SALIYA      Created  for Initial Requirements	

     
EXECUTE USP_WIPReports 1,NULL, NULL, 0, NULL, 0, NULL

*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_WIPReports] 	
@mastercompanyid INT,
@id VARCHAR(100),
@id2 VARCHAR(100),
@id3 bit,
@id5 VARCHAR(MAX),
@id6 BIGINT,
@strFilter VARCHAR(MAX) = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY
		DECLARE @ModuleID INT = 12; -- WO MPN MS Module ID 
		DECLARE @FromDate DATETIME; 
		DECLARE @ToDate DATETIME; 
		DECLARE @ProvisionId INT;

		--SET Tempararly Records 
		SET @mastercompanyid = 1;
		SET @FromDate = GETUTCDATE() - 2;
		SET @ToDate = GETUTCDATE();

		SELECT @ProvisionId = ProvisionId FROM dbo.Provision  WHERE StatusCode = 'REPLACE'		

		IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPMSFilter
		END
		IF OBJECT_ID(N'tempdb..#TEMPOriginalWorkOrderRecords') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPOriginalWorkOrderRecords
		END

		CREATE TABLE #TEMPMSFilter
		(        
			ID BIGINT  IDENTITY(1,1),        
			LevelIds VARCHAR(MAX)			 
		) 

		CREATE TABLE #TEMPOriginalStocklineRecords
		(        
			ID BIGINT IDENTITY(1,1),  
			WorkOrderId BIGINT NULL,
			WorkOrderPartNoId BIGINT NULL,
			StockLineId BIGINT NULL,
			CustomerId BIGINT NULL,
			MasterCompanyId INT NULL,
			PartNumber VARCHAR(50) NULL,
			PartDescription VARCHAR(MAX) NULL,
			SerialNumber VARCHAR(30) NULL,
			StockLineNumber VARCHAR(50) NULL,
			ControlNumber VARCHAR(50) NULL,
			Condition VARCHAR(100) NULL,
			ItemGroup VARCHAR(256) NULL,
			IsCustomerStock BIT NULL,
			Manufacturer VARCHAR(100) NULL,
			[Priority] VARCHAR(100) NULL,
			CustomerName VARCHAR(100),
			WorkOrderType VARCHAR(100),
			WorkOrderNum VARCHAR(100),
			WorkScope VARCHAR(100),
			OpenDate DATETIME,
			WOAge INT,
			Qty INT,
			PartCost DECIMAL(18,2) NULL,
			DirectLabor DECIMAL(18,2) NULL,
			OHCost DECIMAL(18,2) NULL,
			MiscCost DECIMAL(18,2) NULL,
			OtherCost DECIMAL(18,2) NULL,
			TotalWIPCost DECIMAL(18,2) NULL,
			legalEntity VARCHAR(100) NULL,
			level1 VARCHAR(500) NULL,
			level2 VARCHAR(500) NULL,
			level3 VARCHAR(500) NULL,
			level4 VARCHAR(500) NULL,
			level5 VARCHAR(500) NULL,
			level6 VARCHAR(500) NULL,
			level7 VARCHAR(500) NULL,
			level8 VARCHAR(500) NULL,
			level9 VARCHAR(500) NULL,
			level10 VARCHAR(500) NULL,
		)

		INSERT INTO #TEMPMSFilter(LevelIds)
		SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!')
		
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

		INSERT INTO #TEMPOriginalStocklineRecords(WorkOrderId, WorkOrderPartNoId, StockLineId, CustomerId, MasterCompanyId,
			PartNumber, PartDescription, SerialNumber, CustomerName, WorkOrderType, WorkOrderNum, OpenDate, WorkScope, StockLineNumber,Manufacturer,
			[Priority], ControlNumber, Condition, ItemGroup, IsCustomerStock, WOAge, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
			legalEntity, Qty)
		SELECT WO.WorkOrderId, WOP.ID, WOP.StockLineId, WO.CustomerId, WO.MasterCompanyId, SL.PartNumber,  SL.PNDescription AS PartDescription, 
			CASE WHEN ISNULL(RevisedSerialNumber, '') != '' THEN RevisedSerialNumber ELSE SL.SerialNumber END AS SerialNumber,			
			WO.CustomerName, WT.[Description] AS WorkOrderType, WO.WorkOrderNum, WO.OpenDate, WOP.WorkScope, SL.StockLineNumber,
			SL.Manufacturer, P.[Description] As [Priority], SL.ControlNumber, C.[Description] As Condition, SL.ItemGroup, SL.IsCustomerStock,
			DATEDIFF(day, WO.OpenDate, GETUTCDATE()),
			UPPER(MSD.Level1Name) AS level1, UPPER(MSD.Level2Name) AS level2, UPPER(MSD.Level3Name) AS level3, UPPER(MSD.Level4Name) AS level4,    
			UPPER(MSD.Level5Name) AS level5, UPPER(MSD.Level6Name) AS level6, UPPER(MSD.Level7Name) AS level7, UPPER(MSD.Level8Name) AS level8,    
			UPPER(MSD.Level9Name) AS level9, UPPER(MSD.Level10Name) AS level10, LE.[Name] AS legalEntity, 1
		FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
			JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
			JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
			JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOP.ID 
			JOIN dbo.Stockline SL WITH(NOLOCK) ON WOP.StockLineId = SL.StockLineId
			JOIN dbo.Condition C WITH(NOLOCK) ON WOP.RevisedConditionId = C.ConditionId
			JOIN dbo.WorkOrderType WT WITH(NOLOCK) ON WO.WorkOrderTypeId = WT.Id
			LEFT JOIN dbo.[Priority] P WITH(NOLOCK) ON WOP.WorkOrderPriorityId = P.PriorityId
			LEFT JOIN dbo.ManagementStructureLevel MSL ON MSL.ID = MSD.Level1Id
			LEFT JOIN dbo.LegalEntity LE ON MSL.LegalEntityId = LE.LegalEntityId
		WHERE WO.MasterCompanyId = @mastercompanyid AND CAST(WO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
			 AND  ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1 AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1
			 AND  (ISNULL(@level1,'') = '' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level1,',')))    
			 AND  (ISNULL(@level2,'') = '' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level2,',')))    
			 AND  (ISNULL(@level3,'') = '' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level3,',')))    
			 AND  (ISNULL(@level4,'') = '' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level4,',')))
			 AND  (ISNULL(@level5,'') = '' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level5,',')))
			 AND  (ISNULL(@level6,'') = '' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level6,',')))
			 AND  (ISNULL(@level7,'') = '' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level7,',')))
			 AND  (ISNULL(@level8,'') = '' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level8,',')))
			 AND  (ISNULL(@level9,'') = '' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level9,',')))
			 AND  (ISNULL(@level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10,',')))

		--UPDATE #TEMPOriginalStocklineRecords SET PartCost = 0 FROM(
		--	SELECT WO.WorkOrderId, WOP.ID AS WorkOrderPartNoId, WOP.StockLineId, WO.CustomerId, WO.MasterCompanyId, 
		--			SUM(ISNULL(WOMS.QtyIssued, 0) * ISNULL(WOMS.UnitCost, 0)) AS PartCost
		--	FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK)
		--		JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
		--		JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
		--		JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
		--		JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
		--	WHERE WO.MasterCompanyId = @mastercompanyid AND CAST(WO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
		--		 AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 0) = 1 AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1
		--		 AND ISNULL(WOMS.QtyIssued, 0) > 0 AND WOMS.ProvisionId = @ProvisionId AND ISNULL(WOP.IsFinishGood, 0) = 0
		--	GROUP BY WO.WorkOrderId, WOP.ID, WOP.StockLineId, WO.CustomerId, WO.MasterCompanyId
		--) results WHERE results.StockLineId = #TEMPOriginalStocklineRecords.StockLineId AND results.WorkOrderPartNoId = #TEMPOriginalStocklineRecords.WorkOrderPartNoId

		UPDATE tmporg SET PartCost = ISNULL(WCD.PartsCost, 0), DirectLabor = ISNULL(WCD.LaborCost, 0) - ISNULL(WCD.OverHeadCost, 0), OHCost = ISNULL(WCD.OverHeadCost, 0),
				MiscCost = ISNULL(WCD.FreightCost, 0), OtherCost = ISNULL(WCD.OtherCost, 0), 
				TotalWIPCost = ISNULL(WCD.PartsCost, 0) + ISNULL(WCD.LaborCost, 0) + ISNULL(WCD.FreightCost, 0) + ISNULL(WCD.OtherCost, 0)
		FROM #TEMPOriginalStocklineRecords tmporg 
			JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON tmporg.WorkOrderPartNoId = WOP.ID
			JOIN dbo.WorkOrderMPNCostDetails WCD WITH(NOLOCK) ON tmporg.WorkOrderPartNoId = WCD.WOPartNoId
		WHERE ISNULL(WOP.IsFinishGood, 0) = 0 AND ISNULL(WOP.IsDeleted, 0) = 0 AND ISNULL(WOP.IsActive, 0) = 1

		SELECT * FROM #TEMPOriginalStocklineRecords WHERE ISNULL(TotalWIPCost, 0) > 0

 END TRY      
 BEGIN CATCH  
	--SELECT
 --   ERROR_NUMBER() AS ErrorNumber,
 --   ERROR_STATE() AS ErrorState,
 --   ERROR_SEVERITY() AS ErrorSeverity,
 --   ERROR_PROCEDURE() AS ErrorProcedure,
 --   ERROR_LINE() AS ErrorLine,
 --   ERROR_MESSAGE() AS ErrorMessage;
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_CheckAllowReopenWorkOrder'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100))   
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
 END CATCH  
END