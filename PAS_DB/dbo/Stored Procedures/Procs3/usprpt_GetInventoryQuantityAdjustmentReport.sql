-- ===== PROCEDURE: [dbo].[usprpt_GetInventoryQuantityAdjustmentReport]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs3/usprpt_GetInventoryQuantityAdjustmentReport.sql) =====
/*************************************************************           
 ** File:   [usprpt_GetInventoryQuantityAdjustmentReport]
 ** Author:   
 ** Description: Get Data for Stock Report
 ** Purpose:          
 ** Date:   09-05-2025
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    09-05-2025     Moin Bloch			created
	2    14-05-2025     Amit Ghediya		added Adjusted By filed.
	3    09-06-2025     Amit Ghediya		decimal format.
	4    29-01-2026     Devendra Shekh		Modified to Handle Column Filters
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	6    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	7    24/July/2026			 RAJESH GAMI						[PN-17350] - Removed obsolete ItemMaster/Stockline IsNonStock=0 filters (6) to allow Non-Stock items in Inventory Quantity Adjustment Report
	8    02-Sep-2026    Bhargav Saliya                              [PN-17849] Part Number filter: normalize dashes(-)/slashes("\","/")/underscore(_)
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetInventoryQuantityAdjustmentReport]     
@PageNumber INT = NULL,
@PageSize INT = NULL,
@SortColumn VARCHAR(50) = NULL,
@SortOrder INT = NULL,
@GlobalFilter VARCHAR(50) = NULL,
@Pn VARCHAR(100) = NULL,
@PnDescription VARCHAR(MAX) = NULL,
@Cond VARCHAR(100) = NULL,
@SerNum VARCHAR(100) = NULL,
@SlNum VARCHAR(100) = NULL,
@CtrlNum VARCHAR(100) = NULL,
@UnitCost VARCHAR(50) = NULL,
@OrigQty VARCHAR(50) = NULL,
@NewQty VARCHAR(50) = NULL,
@QtyChange VARCHAR(50) = NULL,
@QtyAdjustmentAmount VARCHAR(50) = NULL,
@ReasonCode VARCHAR(200) = NULL,
@Uom VARCHAR(50) = NULL,
@PoNum VARCHAR(100) = NULL,
@RoNum VARCHAR(100) = NULL,
@Location VARCHAR(100) = NULL,
@AdjBy VARCHAR(256) = NULL,
@AdjDate DATETIME2 = NULL,
@Level1 VARCHAR(500) = NULL,
@Level2 VARCHAR(500) = NULL,
@Level3 VARCHAR(500) = NULL,
@Level4 VARCHAR(500) = NULL,
@Level5 VARCHAR(500) = NULL,
@Level6 VARCHAR(500) = NULL,
@Level7 VARCHAR(500) = NULL,
@Level8 VARCHAR(500) = NULL,
@Level9 VARCHAR(500) = NULL,
@Level10 VARCHAR(500) = NULL,
@MasterCompanyId INT,
@UserEmployeeId BIGINT,
@strFilter VARCHAR(MAX) = NULL,
@xmlFilter XML      
AS    
BEGIN    
  SET NOCOUNT ON;    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  BEGIN TRY    
    	   
	DECLARE @Fromdate DATETIME2,    
			@Todate  DATETIME2,    
			@level1Ids VARCHAR(MAX) = NULL,    
			@level2Ids VARCHAR(MAX) = NULL,    
			@level3Ids VARCHAR(MAX) = NULL,    
			@level4Ids VARCHAR(MAX) = NULL,    
			@level5Ids VARCHAR(MAX) = NULL,    
			@level6Ids VARCHAR(MAX) = NULL,    
			@level7Ids VARCHAR(MAX) = NULL,    
			@level8Ids VARCHAR(MAX) = NULL,    
			@level9Ids VARCHAR(MAX) = NULL,    
			@level10Ids VARCHAR(MAX) = NULL,    
			@IncType INT = 0,   
			@DecType INT = 0,
			@CycleCountStatusId INT = 0,
			@StockLineAdjustmentTypeId INT = 0,
			@BulkStocklineAdjustmentStatusId INT = 0,
			@PartNumber varchar(40) = NULL;
			
	SELECT @IncType = [StocklineAdjustmentDataTypeId] FROM [dbo].[StocklineAdjustmentDataType] WITH(NOLOCK) WHERE [Description] = 'Increase Qty On Hand';
	SELECT @DecType = [StocklineAdjustmentDataTypeId] FROM [dbo].[StocklineAdjustmentDataType] WITH(NOLOCK) WHERE [Description] = 'Reduce Qty On Hand';

	SELECT @CycleCountStatusId = [CycleCountStatusId] FROM [dbo].[CycleCountStatus] WITH(NOLOCK) WHERE [Status] = 'Closed';
	SELECT @StockLineAdjustmentTypeId = [StockLineAdjustmentTypeId] FROM [dbo].[StockLineAdjustmentType] WITH(NOLOCK) WHERE [Name] = 'Quantity';
	SELECT @BulkStocklineAdjustmentStatusId = [Id] FROM [dbo].[StocklineAdjustmentStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';

	/* --------------START: Get the timzone and UTC offset -------------- */
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
	SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
	FROM dbo.Employee E WITH (NOLOCK) 
	LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
	LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
	LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @UserEmployeeId;		
				
	SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc
	/* -------------- END: Get the timzone and UTC offset -------------- */

	IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPMSFilter
	END

	CREATE TABLE #TEMPMSFilter([ID] BIGINT  IDENTITY(1,1),[LevelIds] VARCHAR(MAX)); 

	INSERT INTO #TEMPMSFilter(LevelIds)	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!');

	SELECT @level1Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
	SELECT @level2Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
	SELECT @level3Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
	SELECT @level4Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
	SELECT @level5Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
	SELECT @level6Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
	SELECT @level7Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
	SELECT @level8Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
	SELECT @level9Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
	SELECT @level10Ids = LevelIds FROM #TEMPMSFilter WHERE ID = 10 

	SELECT 
    @Fromdate = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'From Date' 
        THEN CONVERT(DATE, filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')) 
        ELSE @Fromdate 
    END,
    @Todate = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'To Date' 
        THEN CONVERT(DATE, filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')) 
        ELSE @Todate 
    END,     	 
	@PartNumber = CASE 
		WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN(Optional)' 
		THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') 
		ELSE @PartNumber END
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby)    
  
	DECLARE @ModuleID INT = 2; -- MS Module ID     
	SELECT @ModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';

	SET @PartNumber = CASE WHEN ISNULL(@PartNumber, '') <> '' AND CAST(@PartNumber AS BIGINT) > 0 THEN @PartNumber ELSE NULL END;
  
	SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END    
	SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END    

	;WITH rptCTE(	[pn], [pndescription], [cond], [sernum], [slnum], [ctrlnum], [unitcost], [origqty], [newqty], [qtychange], [qtyadjustmentamount], [reasoncode], [uom], [ponum], [ronum], [location],
					[adjby], [adjdate], [adjustedfrom], [level1], [level2], [level3], [level4], [level5], [level6], [level7], [level8], [level9], [level10], [masterCompanyId]
				)
	AS (
	SELECT 
        UPPER(im.[partnumber]) AS 'pn',    
        UPPER(im.[PartDescription]) AS 'pndescription',   
		UPPER(stl.[Condition]) 'cond',    
		UPPER(stl.[SerialNumber]) 'sernum',    
        UPPER(stl.[stocklineNumber]) 'slnum',
		UPPER(stl.[ControlNumber]) 'ctrlnum',   
		ISNULL(stl.[UnitCost], 0) 'unitcost',   
		ISNULL(CAST(stladj.[ChangedFrom] AS DECIMAL), 0) 'origqty',
		ISNULL(CAST(stladj.[ChangedTo] AS DECIMAL), 0) 'newqty',       
		CASE WHEN stladj.StocklineAdjustmentDataTypeId = @IncType THEN (ISNULL(CAST(stladj.[ChangedTo] AS DECIMAL), 0) - ISNULL(CAST(stladj.[ChangedFrom] AS DECIMAL), 0))
		     ELSE (ISNULL(CAST(stladj.[ChangedFrom] AS DECIMAL), 0) - ISNULL(CAST(stladj.[ChangedTo] AS DECIMAL), 0)) * (-1) END 'qtychange',
		CASE WHEN stladj.StocklineAdjustmentDataTypeId = @IncType THEN (ISNULL(stl.[UnitCost], 0) * (ISNULL(CAST(stladj.[ChangedTo] AS DECIMAL), 0) - ISNULL(CAST(stladj.[ChangedFrom] AS DECIMAL), 0)))
		     ELSE (ISNULL(stl.[UnitCost], 0) * (ISNULL(CAST(stladj.[ChangedFrom] AS DECIMAL), 0) - ISNULL(CAST(stladj.[ChangedTo] AS DECIMAL), 0))) * (-1) END 'qtyadjustmentamount',		
		sar.[Description] 'reasoncode',
		UPPER(uom.[ShortName]) 'uom',
		UPPER(pox.[PurchaseOrderNumber]) 'ponum',    
        UPPER(rox.[RepairOrderNumber]) 'ronum',    
		UPPER(stl.[Location]) 'location',
		stladj.[CreatedBy] 'adjby',
		stladj.[CreatedDate] 'adjdate',
		'Stockline Adjustment' AS 'adjustedfrom',
		UPPER(MSD.[Level1Name]) AS 'level1',     
		UPPER(MSD.[Level2Name]) AS 'level2',    
		UPPER(MSD.[Level3Name]) AS 'level3',    
		UPPER(MSD.[Level4Name]) AS 'level4',    
		UPPER(MSD.[Level5Name]) AS 'level5',    
		UPPER(MSD.[Level6Name]) AS 'level6',    
		UPPER(MSD.[Level7Name]) AS 'level7',    
		UPPER(MSD.[Level8Name]) AS 'level8',    
		UPPER(MSD.[Level9Name]) AS 'level9', 
		UPPER(MSD.[Level10Name]) AS 'level10',
		stl.[MasterCompanyId]		
	FROM [dbo].[StocklineAdjustment] stladj WITH(NOLOCK) 
	INNER JOIN [dbo].[Stockline] stl WITH(NOLOCK) ON stladj.[StockLineId] = stl.[StockLineId]    
	INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.[ModuleID] = @ModuleID AND MSD.[ReferenceID] = stl.[StockLineId]    
	LEFT JOIN  [dbo].[EntityStructureSetup] ES WITH(NOLOCK) ON ES.[EntityStructureId]=MSD.[EntityMSID]    
	LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.[ItemMasterId] = im.[ItemMasterId]
	 LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON stl.[PurchaseUnitOfMeasureId] = uom.[UnitOfMeasureId]  
	LEFT JOIN [dbo].[PurchaseOrder] pox WITH(NOLOCK) ON stl.[PurchaseOrderId] = pox.[PurchaseOrderId]    
	LEFT JOIN [dbo].[RepairOrder] rox WITH(NOLOCK) ON stl.[RepairOrderId] = rox.[RepairOrderId]
	LEFT JOIN [dbo].[StocklineAdjustmentReason] sar WITH(NOLOCK) ON stladj.[AdjustmentReasonId] = sar.[AdjustmentReasonId]	
	WHERE stl.[MasterCompanyId] = @mastercompanyid 
	AND stl.[IsParent] = 1 
	AND stl.[IsDeleted] = 0 
	AND (@PartNumber IS NULL OR im.ItemMasterId = @PartNumber)
	AND stladj.[StocklineAdjustmentDataTypeId] IN(@IncType,@DecType)
	AND CAST(stladj.[CreatedDate] AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)  
	AND (ISNULL(@level1Ids,'') =''  OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level1Ids,',')))    
	AND (ISNULL(@level2Ids,'') =''  OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level2Ids,',')))    
	AND (ISNULL(@level3Ids,'') =''  OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level3Ids,',')))    
	AND (ISNULL(@level4Ids,'') =''  OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level4Ids,',')))    
	AND (ISNULL(@level5Ids,'') =''  OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level5Ids,',')))    
	AND (ISNULL(@level6Ids,'') =''  OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level6Ids,',')))    
	AND (ISNULL(@level7Ids,'') =''  OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level7Ids,',')))    
	AND (ISNULL(@level8Ids,'') =''  OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level8Ids,',')))    
	AND (ISNULL(@level9Ids,'') =''  OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level9Ids,',')))    
	AND (ISNULL(@level10Ids,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10Ids,',')))
   
	UNION

	SELECT    
		 UPPER(im.[partnumber]) AS 'pn',
		 UPPER(im.[PartDescription]) AS 'pndescription',
		 UPPER(stl.[Condition]) 'cond',
		 UPPER(stl.[SerialNumber]) 'sernum',
         UPPER(stl.[stocklineNumber]) 'slnum',
		 UPPER(stl.[ControlNumber]) 'ctrlnum',
		 ISNULL(stl.[UnitCost], 0) 'unitcost',
		 ISNULL(cycd.[CurrentStockQuantity], 0) 'origqty',
		 ISNULL(cycd.[CountedQuantity], 0) 'newqty',
		 ISNULL(cycd.[DifferenceQuantity], 0) 'qtychange',
		 ISNULL(cycd.[DifferenceAmount], 0) 'qtyadjustmentamount',
		 sar.[Description] 'reasoncode',
		 UPPER(uom.[ShortName]) 'uom',
		 UPPER(pox.[PurchaseOrderNumber]) 'ponum',
         UPPER(rox.[RepairOrderNumber]) 'ronum',
		 UPPER(stl.[Location]) 'location',    
		 cyc.[CreatedBy] 'adjby',
		 cyc.[CreatedDate] 'adjdate',
		 'Cycle Count Adjustment' AS 'adjustedfrom',
		 UPPER(MSD.[Level1Name]) AS 'level1',     
		 UPPER(MSD.[Level2Name]) AS 'level2',    
		 UPPER(MSD.[Level3Name]) AS 'level3',    
		 UPPER(MSD.[Level4Name]) AS 'level4',    
		 UPPER(MSD.[Level5Name]) AS 'level5',    
		 UPPER(MSD.[Level6Name]) AS 'level6',    
		 UPPER(MSD.[Level7Name]) AS 'level7',    
		 UPPER(MSD.[Level8Name]) AS 'level8',    
		 UPPER(MSD.[Level9Name]) AS 'level9', 
		 UPPER(MSD.[Level10Name]) AS 'level10',
		 stl.[MasterCompanyId]		
	FROM [dbo].[CycleCount] cyc WITH(NOLOCK) 
	INNER JOIN [dbo].[CycleCountDetail] cycd WITH(NOLOCK) ON cyc.[CycleCountId] = cycd.[CycleCountId]
	INNER JOIN [dbo].[Stockline] stl WITH(NOLOCK) ON cycd.[StockLineId] = stl.[StockLineId]    
	INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.[ModuleID] = @ModuleID AND MSD.[ReferenceID] = stl.[StockLineId]    
	LEFT JOIN  [dbo].[EntityStructureSetup] ES WITH(NOLOCK) ON ES.[EntityStructureId]=MSD.[EntityMSID]    
	LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.[ItemMasterId] = im.[ItemMasterId]
	 LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON stl.[PurchaseUnitOfMeasureId] = uom.[UnitOfMeasureId]  
	LEFT JOIN [dbo].[PurchaseOrder] pox WITH(NOLOCK) ON stl.[PurchaseOrderId] = pox.[PurchaseOrderId]    
	LEFT JOIN [dbo].[RepairOrder] rox WITH(NOLOCK) ON stl.[RepairOrderId] = rox.[RepairOrderId]
	LEFT JOIN [dbo].[StocklineAdjustmentReason] sar WITH(NOLOCK) ON cycd.[AdjustmentReasonId] = sar.[AdjustmentReasonId]	
	WHERE cyc.[MasterCompanyId] = @mastercompanyid 
	AND stl.[IsParent] = 1 
	AND stl.[IsDeleted] = 0 
	AND cyc.[StatusId] = @CycleCountStatusId
	AND (@PartNumber IS NULL OR im.ItemMasterId = @PartNumber)
	AND CAST(cyc.[CreatedDate] AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) 
	AND (ISNULL(@level1Ids,'') =''  OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level1Ids,',')))    
	AND (ISNULL(@level2Ids,'') =''  OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level2Ids,',')))    
	AND (ISNULL(@level3Ids,'') =''  OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level3Ids,',')))    
	AND (ISNULL(@level4Ids,'') =''  OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level4Ids,',')))    
	AND (ISNULL(@level5Ids,'') =''  OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level5Ids,',')))    
	AND (ISNULL(@level6Ids,'') =''  OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level6Ids,',')))    
	AND (ISNULL(@level7Ids,'') =''  OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level7Ids,',')))    
	AND (ISNULL(@level8Ids,'') =''  OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level8Ids,',')))    
	AND (ISNULL(@level9Ids,'') =''  OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level9Ids,',')))    
	AND (ISNULL(@level10Ids,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10Ids,',')))

	UNION

	SELECT  
		 UPPER(im.[partnumber]) AS 'pn',
		 UPPER(im.[PartDescription]) AS 'pndescription',
		 UPPER(stl.[Condition]) 'cond', 
		 UPPER(stl.[SerialNumber]) 'sernum',
         UPPER(stl.[stocklineNumber]) 'slnum',
		 UPPER(stl.[ControlNumber]) 'ctrlnum',
		 ISNULL(stl.[UnitCost], 0) 'unitcost',
		 ISNULL(bsajd.[Qty], 0) 'origqty',
		 ISNULL(bsajd.[NewQty], 0) 'newqty',
		 ISNULL(bsajd.[QtyAdjustment], 0) 'qtychange',
		 ISNULL(bsajd.[AdjustmentAmount], 0) 'qtyadjustmentamount',
		 sar.[Description] 'reasoncode',
		 UPPER(uom.[ShortName]) 'uom',
		 UPPER(pox.[PurchaseOrderNumber]) 'ponum',
         UPPER(rox.[RepairOrderNumber]) 'ronum',
		 UPPER(stl.[Location]) 'location',
		 bsaj.[CreatedBy] 'adjby',
		 bsaj.[CreatedDate] 'adjdate',		 
		 'Bulk Adjustment' AS 'adjustedfrom',
		 UPPER(MSD.[Level1Name]) AS 'level1',     
		 UPPER(MSD.[Level2Name]) AS 'level2',    
		 UPPER(MSD.[Level3Name]) AS 'level3',    
		 UPPER(MSD.[Level4Name]) AS 'level4',    
		 UPPER(MSD.[Level5Name]) AS 'level5',    
		 UPPER(MSD.[Level6Name]) AS 'level6',    
		 UPPER(MSD.[Level7Name]) AS 'level7',    
		 UPPER(MSD.[Level8Name]) AS 'level8',    
		 UPPER(MSD.[Level9Name]) AS 'level9', 
		 UPPER(MSD.[Level10Name]) AS 'level10',
		 stl.[MasterCompanyId]		
	FROM [dbo].[BulkStockLineAdjustment] bsaj WITH(NOLOCK) 
	INNER JOIN [dbo].[BulkStockLineAdjustmentDetails] bsajd WITH(NOLOCK) ON bsaj.[BulkStkLineAdjId] = bsajd.[BulkStkLineAdjId]
	INNER JOIN [dbo].[Stockline] stl WITH(NOLOCK) ON bsajd.[StockLineId] = stl.[StockLineId]    
	INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.[ModuleID] = @ModuleID AND MSD.[ReferenceID] = stl.[StockLineId]    
	LEFT JOIN  [dbo].[EntityStructureSetup] ES WITH(NOLOCK) ON ES.[EntityStructureId]=MSD.[EntityMSID]    
	LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.[ItemMasterId] = im.[ItemMasterId]
	 LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON stl.[PurchaseUnitOfMeasureId] = uom.[UnitOfMeasureId]  
	LEFT JOIN [dbo].[PurchaseOrder] pox WITH(NOLOCK) ON stl.[PurchaseOrderId] = pox.[PurchaseOrderId]    
	LEFT JOIN [dbo].[RepairOrder] rox WITH(NOLOCK) ON stl.[RepairOrderId] = rox.[RepairOrderId]
	LEFT JOIN [dbo].[StocklineAdjustmentReason] sar WITH(NOLOCK) ON bsajd.[AdjustmentReasonId] = sar.[AdjustmentReasonId]	
	WHERE bsaj.[MasterCompanyId] = @mastercompanyid
	AND stl.[IsParent] = 1 
	AND stl.[IsDeleted] = 0 
	AND bsaj.StockLineAdjustmentTypeId = @StockLineAdjustmentTypeId
	AND bsaj.StatusId = @BulkStocklineAdjustmentStatusId
	AND (@PartNumber IS NULL OR im.ItemMasterId = @PartNumber)
	AND CAST(bsaj.[CreatedDate] AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) 
	AND (ISNULL(@level1Ids,'') =''  OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level1Ids,',')))    
	AND (ISNULL(@level2Ids,'') =''  OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level2Ids,',')))    
	AND (ISNULL(@level3Ids,'') =''  OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level3Ids,',')))    
	AND (ISNULL(@level4Ids,'') =''  OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level4Ids,',')))    
	AND (ISNULL(@level5Ids,'') =''  OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level5Ids,',')))    
	AND (ISNULL(@level6Ids,'') =''  OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level6Ids,',')))    
	AND (ISNULL(@level7Ids,'') =''  OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level7Ids,',')))    
	AND (ISNULL(@level8Ids,'') =''  OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level8Ids,',')))    
	AND (ISNULL(@level9Ids,'') =''  OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level9Ids,',')))    
	AND (ISNULL(@level10Ids,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10Ids,',')))
   )

	,FinalCTE([pn], [pndescription], [cond], [sernum], [slnum], [ctrlnum], [unitcost], [origqty], [newqty], [qtychange], [qtyadjustmentamount],
			[reasoncode], [uom], [ponum], [ronum], [location], [adjby], [adjdate], [adjustedfrom],
			[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],[masterCompanyId]) 

	AS (SELECT DISTINCT [pn], [pndescription], [cond], [sernum], [slnum], [ctrlnum], [unitcost], [origqty], [newqty], [qtychange], [qtyadjustmentamount],
			[reasoncode], [uom], [ponum], [ronum], [location], [adjby], [adjdate], [adjustedfrom],
			[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],[masterCompanyId]
	   FROM rptCTE
	   WHERE (ISNULL(@Pn,'') ='' OR pn LIKE '%' + @Pn+'%' OR dbo.fn_NormalizePartNumber(pn) LIKE '%' + dbo.fn_NormalizePartNumber(@Pn) + '%')
		AND (ISNULL(@PnDescription,'') = '' OR pndescription LIKE '%' + @PnDescription + '%')
		AND (ISNULL(@Cond,'') = '' OR cond LIKE '%' + @Cond + '%')
		AND (ISNULL(@SerNum,'') = '' OR sernum LIKE '%' + @SerNum + '%')
		AND (ISNULL(@SlNum,'') = '' OR slnum LIKE '%' + @SlNum + '%')
		AND (ISNULL(@CtrlNum,'') = '' OR ctrlnum LIKE '%' + @CtrlNum + '%')
		AND (ISNULL(@UnitCost,'') = '' OR unitcost LIKE '%' + @UnitCost + '%')
		AND (ISNULL(@OrigQty,'') = '' OR origqty LIKE '%' + @OrigQty + '%')
		AND (ISNULL(@NewQty,'') = '' OR newqty LIKE '%' + @NewQty + '%')
		AND (ISNULL(@QtyChange,'') = '' OR qtychange LIKE '%' + @QtyChange + '%')
		AND (ISNULL(@QtyAdjustmentAmount,'') = '' OR qtyadjustmentamount LIKE '%' + @QtyAdjustmentAmount + '%')
		AND (ISNULL(@ReasonCode,'') = '' OR reasoncode LIKE '%' + @ReasonCode + '%')
		AND (ISNULL(@Uom,'') = '' OR uom LIKE '%' + @Uom + '%')
		AND (ISNULL(@PoNum,'') = '' OR ponum LIKE '%' + @PoNum + '%')
		AND (ISNULL(@RoNum,'') = '' OR ronum LIKE '%' + @RoNum + '%')
		AND (ISNULL(@Location,'') = '' OR location LIKE '%' + @Location + '%')
		AND (ISNULL(@AdjBy,'') = '' OR adjby LIKE '%' + @AdjBy + '%')
		AND (@AdjDate IS NULL OR CAST(adjdate AS DATE) = CAST(@AdjDate AS DATE))
	   
	   )

	,WithTotal ([masterCompanyId], [TotalUnitPrice]) 
	        AS (SELECT [masterCompanyId], 				
				FORMAT(SUM([qtyadjustmentamount]), 'N', 'en-us') TotalUnitPrice				
				FROM FinalCTE GROUP BY [masterCompanyId])

	SELECT COUNT(1) OVER () AS [NumberOfItems], 
	                FC.[pn],
					FC.[pndescription], 
					FC.[cond], 
					FC.[sernum],
					FC.[slnum],
					FC.[ctrlnum],
			        FORMAT(FC.[unitcost], 'N2') [unitcost],
					FORMAT(FC.[origqty] , 'N2') [origqty],
					FORMAT(FC.[newqty] , 'N2') [newqty],
					CASE WHEN FC.[qtychange] < 0 THEN CAST(FORMAT((FC.[qtychange]), 'N2') AS VARCHAR) ELSE CAST(FORMAT(FC.[qtychange], 'N2') AS VARCHAR) END [qtychange],
					CASE WHEN FC.[qtyadjustmentamount] < 0 THEN CAST(FORMAT((FC.[qtyadjustmentamount]), 'N2') AS VARCHAR(100)) ELSE CAST(FORMAT(FC.[qtyadjustmentamount], 'N2') AS VARCHAR(100)) END [qtyadjustmentamount],
					FC.[reasoncode],
					FC.[uom],
					FC.[ponum],
					FC.[ronum],
					FC.[location], 
					FC.[adjby],
					FC.[adjdate],
					FC.[adjustedfrom],
					FC.[level1],
					FC.[level2],
					FC.[level3],
					FC.[level4],
					FC.[level5],
					FC.[level6],
					FC.[level7],
					FC.[level8],
					FC.[level9],
					FC.[level10],	
					FC.[masterCompanyId],					
				    WC.[TotalUnitPrice]
				FROM FinalCTE FC
				INNER JOIN WithTotal WC ON FC.masterCompanyId = WC.masterCompanyId
				ORDER BY
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'pn') THEN pn END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'pn') THEN pn END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'pndescription') THEN pndescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'pndescription') THEN pndescription END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'cond') THEN cond END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'cond') THEN cond END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'sernum') THEN sernum END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'sernum') THEN sernum END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'slnum') THEN slnum END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'slnum') THEN slnum END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'ctrlnum') THEN ctrlnum END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ctrlnum') THEN ctrlnum END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'unitcost') THEN unitcost END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'unitcost') THEN unitcost END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'origqty') THEN origqty END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'origqty') THEN origqty END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'newqty') THEN newqty END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'newqty') THEN newqty END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'qtychange') THEN qtychange END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'qtychange') THEN qtychange END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'qtyadjustmentamount') THEN qtyadjustmentamount END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'qtyadjustmentamount') THEN qtyadjustmentamount END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'reasoncode') THEN reasoncode END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'reasoncode') THEN reasoncode END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'uom') THEN uom END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'uom') THEN uom END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'ponum') THEN ponum END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ponum') THEN ponum END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'ronum') THEN ronum END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ronum') THEN ronum END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'location') THEN location END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'location') THEN location END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'adjby') THEN adjby END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'adjby') THEN adjby END DESC,
				CASE WHEN (@SortOrder = 1  AND @SortColumn = 'adjdate') THEN adjdate END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn = 'adjdate') THEN adjdate END DESC
				
				OFFSET((@PageNumber-1) * @pageSize) ROWS FETCH NEXT @pageSize ROWS ONLY; 
    
	END TRY
	BEGIN CATCH    
	DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME()    
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            ,    
            @AdhocComments varchar(150) = '[usprpt_GetInventoryQuantityAdjustmentReport]',    
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100)) +      
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) +      
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS VARCHAR(100)) +      
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS VARCHAR(MAX)),    
            @ApplicationName VARCHAR(100) = 'PAS'     
    
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
    EXEC Splogexception @DatabaseName = @DatabaseName,    
                        @AdhocComments = @AdhocComments,    
                        @ProcedureParameters = @ProcedureParameters,    
                        @ApplicationName = @ApplicationName,    
                        @ErrorLogID = @ErrorLogID OUTPUT;    
    
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	RETURN (1);    
	END CATCH
END