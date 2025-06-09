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
    1    09-05-2025     Moin Bloch        created
	2    14-05-2025     Amit Ghediya      added Adjusted By filed.
	3    09-06-2025     Amit Ghediya      decimal format.

**************************************************************/
CREATE     PROCEDURE [dbo].[usprpt_GetInventoryQuantityAdjustmentReport]     
@PageNumber int = 1,    
@PageSize int = NULL,    
@mastercompanyid int,    
@xmlFilter XML        
AS    
BEGIN    
  SET NOCOUNT ON;    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    

	   
    DECLARE @Fromdate DATETIME2,    
			@Todate  DATETIME2,    
			@AdjustmentReason VARCHAR(50) = NULL,    
			@level1 VARCHAR(MAX) = NULL,    
			@level2 VARCHAR(MAX) = NULL,    
			@level3 VARCHAR(MAX) = NULL,    
			@level4 VARCHAR(MAX) = NULL,    
			@Level5 VARCHAR(MAX) = NULL,    
			@Level6 VARCHAR(MAX) = NULL,    
			@Level7 VARCHAR(MAX) = NULL,    
			@Level8 VARCHAR(MAX) = NULL,    
			@Level9 VARCHAR(MAX) = NULL,    
			@Level10 VARCHAR(MAX) = NULL,    
			@IsDownload BIT = NULL,    
			@IncType INT = 0,   
			@DecType INT = 0,
			@CycleCountStatusId INT = 0,
			@StockLineAdjustmentTypeId INT = 0,
			@BulkStocklineAdjustmentStatusId INT = 0;

			
	SELECT @IncType = [StocklineAdjustmentDataTypeId] FROM [dbo].[StocklineAdjustmentDataType] WITH(NOLOCK) WHERE [Description] = 'Increase Qty On Hand';
	SELECT @DecType = [StocklineAdjustmentDataTypeId] FROM [dbo].[StocklineAdjustmentDataType] WITH(NOLOCK) WHERE [Description] = 'Reduce Qty On Hand';

	SELECT @CycleCountStatusId = [CycleCountStatusId] FROM [dbo].[CycleCountStatus] WITH(NOLOCK) WHERE [Status] = 'Closed';
	SELECT @StockLineAdjustmentTypeId = [StockLineAdjustmentTypeId] FROM [dbo].[StockLineAdjustmentType] WITH(NOLOCK) WHERE [Name] = 'Quantity';
	select @BulkStocklineAdjustmentStatusId = [Id] from [dbo].[StocklineAdjustmentStatus] WHERE [Name] = 'Posted';
    
  BEGIN TRY    

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
    @AdjustmentReason = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Reason Code' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @AdjustmentReason 
    END,
    @level1 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level1' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level1 
    END,
    @level2 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level2' 
        THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') 
		ELSE @level2     
    END,
    @level3 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level3' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level3 
    END,
    @level4 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level4' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level4 
    END,
    @level5 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level5' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level5 
    END,
    @level6 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level6' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level6 
    END,
    @level7 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level7' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level7 
    END,
    @level8 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level8' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level8 
    END,
    @level9 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level9' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level9 
    END,
    @level10 = CASE 
        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level10' 
        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') 
        ELSE @level10 
    END    
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby)    
  
   DECLARE @ModuleID INT = 2; -- MS Module ID     
   SELECT @ModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';

   SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END    
  
  IF ISNULL(@PageSize,0)=0    
  BEGIN     
    SELECT @PageSize = COUNT(*)    
    FROM [dbo].[StocklineAdjustment] stla WITH(NOLOCK) 
   INNER JOIN [dbo].[Stockline] stl WITH(NOLOCK) ON stl.[StockLineId] = stl.[StockLineId]    
   INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.[ModuleID] = @ModuleID AND MSD.[ReferenceID] = stl.[StockLineId]    
    LEFT JOIN [dbo].[EntityStructureSetup] ES  WITH(NOLOCK) ON ES.[EntityStructureId]=MSD.[EntityMSID]    
    LEFT JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.[ItemMasterId] = im.[ItemMasterId]   
    LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON stl.[PurchaseUnitOfMeasureId] = uom.[UnitOfMeasureId]   
    LEFT JOIN [dbo].[PurchaseOrder] pox WITH(NOLOCK) ON stl.[PurchaseOrderId] = pox.[PurchaseOrderId]    
    LEFT JOIN [dbo].[RepairOrder] rox WITH(NOLOCK) ON stl.[RepairOrderId] = rox.[RepairOrderId]    
    LEFT JOIN [dbo].[StocklineAdjustmentReason] sar WITH(NOLOCK) ON stla.[AdjustmentReasonId] = sar.[AdjustmentReasonId]	 
   WHERE stl.[MasterCompanyId] = @mastercompanyid 
     AND stl.[IsParent] = 1 
	 AND stl.[IsDeleted] = 0 
	 AND stla.[StocklineAdjustmentDataTypeId] IN(@IncType,@DecType)
	 AND CAST(stla.[CreatedDate] AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)     
     AND (ISNULL(@AdjustmentReason,'')='' OR stla.[AdjustmentReasonId] IN(SELECT value FROM String_split(ISNULL(@AdjustmentReason,''), ',')))    
     AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))    
     AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
     AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
     AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
     AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
     AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
     AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
     AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
     AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
     AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))     
   END    
       
   SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END    
   SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END    

   ;WITH rptCTE ([TotalRecordsCount], [pn], [pndescription], [cond], [location], [sernum], [slnum], [ctrlnum], [ponum], [ronum], [unitcost], [uom], 
                 [priviousqtyonhand], [updatedqtyonhand], [qtyadjusted], [adjustmentamount], [reasoncode],[adjdate],[adjby],[adjustedfrom],[level1], [level2], [level3], [level4], 
				 [level5], [level6], [level7], [level8], [level9], [level10], [masterCompanyId])
	AS (     
	 SELECT COUNT(1) OVER () AS TotalRecordsCount,    
        UPPER(im.[partnumber]) AS 'pn',    
        UPPER(im.[PartDescription]) AS 'pndescription',   
		UPPER(stl.[Condition]) 'cond',    
		UPPER(stl.[Location]) 'location',    
		UPPER(stl.[SerialNumber]) 'sernum',    
        UPPER(stl.[stocklineNumber]) 'slnum',    
		UPPER(stl.[ControlNumber]) 'ctrlnum',   
		UPPER(pox.[PurchaseOrderNumber]) 'ponum',    
        UPPER(rox.[RepairOrderNumber]) 'ronum',    
		ISNULL(stl.[UnitCost], 0) 'unitcost',   
		UPPER(uom.[ShortName]) 'uom',  		 
		ISNULL(CAST(stladj.[ChangedFrom] AS INT), 0) 'priviousqtyonhand',
		ISNULL(CAST(stladj.[ChangedTo] AS INT), 0) 'updatedqtyonhand',       
		CASE WHEN stladj.StocklineAdjustmentDataTypeId = @IncType THEN (ISNULL(CAST(stladj.[ChangedTo] AS INT), 0) - ISNULL(CAST(stladj.[ChangedFrom] AS INT), 0))
		     ELSE (ISNULL(CAST(stladj.[ChangedFrom] AS INT), 0) - ISNULL(CAST(stladj.[ChangedTo] AS INT), 0)) * (-1) END 'qtyadjusted',
		CASE WHEN stladj.StocklineAdjustmentDataTypeId = @IncType THEN (ISNULL(stl.[UnitCost], 0) * (ISNULL(CAST(stladj.[ChangedTo] AS INT), 0) - ISNULL(CAST(stladj.[ChangedFrom] AS INT), 0)))
		     ELSE (ISNULL(stl.[UnitCost], 0) * (ISNULL(CAST(stladj.[ChangedFrom] AS INT), 0) - ISNULL(CAST(stladj.[ChangedTo] AS INT), 0))) * (-1) END 'adjustmentamount',		
		sar.[Description] 'reasoncode',
		stladj.[CreatedDate] 'adjdate',
		stladj.[CreatedBy] 'adjby',
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
		 AND stladj.[StocklineAdjustmentDataTypeId] IN(@IncType,@DecType)
	     AND CAST(stladj.[CreatedDate] AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)  
   AND (ISNULL(@AdjustmentReason,'')='' OR stladj.[AdjustmentReasonId] IN(SELECT value FROM STRING_SPLIT(ISNULL(@AdjustmentReason,''), ',')))    
   AND (ISNULL(@Level1,'') =''  OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))    
   AND (ISNULL(@Level2,'') =''  OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
   AND (ISNULL(@Level3,'') =''  OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
   AND (ISNULL(@Level4,'') =''  OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
   AND (ISNULL(@Level5,'') =''  OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
   AND (ISNULL(@Level6,'') =''  OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
   AND (ISNULL(@Level7,'') =''  OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
   AND (ISNULL(@Level8,'') =''  OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
   AND (ISNULL(@Level9,'') =''  OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
   AND (ISNULL(@Level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
   
   UNION

   SELECT  COUNT(1) OVER () AS TotalRecordsCount,    
		 UPPER(im.[partnumber]) AS 'pn',
		 UPPER(im.[PartDescription]) AS 'pndescription',
		 UPPER(stl.[Condition]) 'cond',    
		 UPPER(stl.[Location]) 'location',    
		 UPPER(stl.[SerialNumber]) 'sernum',    
         UPPER(stl.[stocklineNumber]) 'slnum',    
		 UPPER(stl.[ControlNumber]) 'ctrlnum',   
		 UPPER(pox.[PurchaseOrderNumber]) 'ponum',    
         UPPER(rox.[RepairOrderNumber]) 'ronum' ,
		 ISNULL(stl.[UnitCost], 0) 'unitcost',
		 UPPER(uom.[ShortName]) 'uom',
		 ISNULL(CAST(cycd.[CurrentStockQuantity] AS INT), 0) 'priviousqtyonhand',
		 ISNULL(CAST(cycd.[CountedQuantity] AS INT), 0) 'updatedqtyonhand',
		 ISNULL(CAST(cycd.[DifferenceQuantity] AS INT), 0) 'qtyadjusted',
		 ISNULL(CAST(cycd.[DifferenceAmount] AS INT), 0) 'adjustmentamount',
		 sar.[Description] 'reasoncode',
		 cyc.[CreatedDate] 'adjdate',
		 cyc.[CreatedBy] 'adjby',
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
       WHERE cyc.[MasterCompanyId] = 1 
	     AND stl.[IsParent] = 1 
	     AND stl.[IsDeleted] = 0 
		 AND cyc.[StatusId] = @CycleCountStatusId
	     AND CAST(cyc.[CreatedDate] AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) 
	 AND (ISNULL(@Level1,'') =''  OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))    
	 AND (ISNULL(@Level2,'') =''  OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
	 AND (ISNULL(@Level3,'') =''  OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
	 AND (ISNULL(@Level4,'') =''  OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
	 AND (ISNULL(@Level5,'') =''  OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
	 AND (ISNULL(@Level6,'') =''  OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
	 AND (ISNULL(@Level7,'') =''  OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
	 AND (ISNULL(@Level8,'') =''  OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
	 AND (ISNULL(@Level9,'') =''  OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
	 AND (ISNULL(@Level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

	 UNION

	 SELECT COUNT(1) OVER () AS TotalRecordsCount,    
		 UPPER(im.[partnumber]) AS 'pn',
		 UPPER(im.[PartDescription]) AS 'pndescription',
		 UPPER(stl.[Condition]) 'cond',    
		 UPPER(stl.[Location]) 'location',    
		 UPPER(stl.[SerialNumber]) 'sernum',    
         UPPER(stl.[stocklineNumber]) 'slnum',    
		 UPPER(stl.[ControlNumber]) 'ctrlnum',   
		 UPPER(pox.[PurchaseOrderNumber]) 'ponum',    
         UPPER(rox.[RepairOrderNumber]) 'ronum' ,
		 ISNULL(stl.[UnitCost], 0) 'unitcost',
		 UPPER(uom.[ShortName]) 'uom',
		 ISNULL(CAST(bsajd.[Qty] AS INT), 0) 'priviousqtyonhand',
		 ISNULL(CAST(bsajd.[NewQty] AS INT), 0) 'updatedqtyonhand',
		 ISNULL(CAST(bsajd.[QtyAdjustment] AS INT), 0) 'qtyadjusted',
		 ISNULL(CAST(bsajd.[AdjustmentAmount] AS INT), 0) 'adjustmentamount',
		 sar.[Description] 'reasoncode',
		 bsaj.[CreatedDate] 'adjdate',
		 bsaj.[CreatedBy] 'adjby',
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
       WHERE bsaj.[MasterCompanyId] = 1 
	     AND stl.[IsParent] = 1 
	     AND stl.[IsDeleted] = 0 
		 AND bsaj.StockLineAdjustmentTypeId = @StockLineAdjustmentTypeId
		 AND bsaj.StatusId = @BulkStocklineAdjustmentStatusId
	     AND CAST(bsaj.[CreatedDate] AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE) 
		 AND (ISNULL(@Level1,'') =''  OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))    
		 AND (ISNULL(@Level2,'') =''  OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
		 AND (ISNULL(@Level3,'') =''  OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
		 AND (ISNULL(@Level4,'') =''  OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
		 AND (ISNULL(@Level5,'') =''  OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
		 AND (ISNULL(@Level6,'') =''  OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
		 AND (ISNULL(@Level7,'') =''  OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
		 AND (ISNULL(@Level8,'') =''  OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
		 AND (ISNULL(@Level9,'') =''  OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
		 AND (ISNULL(@Level10,'') ='' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
   )

   ,FinalCTE([TotalRecordsCount], [pn], [pndescription], [cond], [location], [sernum], [slnum], [ctrlnum],[ponum],[ronum],
             [unitcost],[uom],[priviousqtyonhand],[updatedqtyonhand],[qtyadjusted],[adjustmentamount],[reasoncode],[adjdate],[adjby],[adjustedfrom],
			 [level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],[masterCompanyId]) 

    AS (SELECT DISTINCT [TotalRecordsCount], [pn], [pndescription], [cond], [location], [sernum], [slnum], [ctrlnum],[ponum],[ronum],
	        [unitcost],[uom],[priviousqtyonhand],[updatedqtyonhand],[qtyadjusted],[adjustmentamount],[reasoncode],[adjdate],[adjby],[adjustedfrom],
			[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],[masterCompanyId]
	   FROM rptCTE)

	,WithTotal ([masterCompanyId], [TotalUnitPrice]) 
	        AS (SELECT [masterCompanyId], 				
				FORMAT(SUM([adjustmentamount]), 'N', 'en-us') TotalUnitPrice				
				FROM FinalCTE GROUP BY [masterCompanyId])

	SELECT COUNT(2) OVER () AS [TotalRecordsCount], 
	                FC.[pn],
					FC.[pndescription], 
					FC.[cond], 
					FC.[location], 
					FC.[sernum], 
					FC.[slnum], 
					FC.[ctrlnum],
					FC.[ponum],
					FC.[ronum],
			        FORMAT(FC.[unitcost], 'N2') unitcost,
					FC.[uom],
					FORMAT(FC.[priviousqtyonhand] , 'N2') priviousqtyonhand,
					FORMAT(FC.[updatedqtyonhand] , 'N2') updatedqtyonhand, 					
					CASE WHEN FC.[qtyadjusted] < 0 THEN '(' + CAST(FORMAT(ABS(FC.[qtyadjusted]), 'N2') AS VARCHAR) + ')' ELSE CAST(FORMAT(FC.[qtyadjusted], 'N2') AS VARCHAR) END [qtyadjusted],
					CASE WHEN FC.[adjustmentamount] < 0 THEN '(' + CAST(FORMAT(ABS(FC.[adjustmentamount]), 'N2') AS VARCHAR(100)) + ')' ELSE CAST(FORMAT(FC.[adjustmentamount], 'N2') AS VARCHAR(100)) END [adjustmentamount],
					FC.[reasoncode],
					FC.[adjdate],
					FC.[adjby],
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
				ORDER BY adjdate DESC
				
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