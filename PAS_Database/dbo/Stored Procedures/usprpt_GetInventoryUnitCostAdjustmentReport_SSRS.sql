/*************************************************************           
 ** File:   [usprpt_GetInventoryUnitCostAdjustmentReport_SSRS]
 ** Author:   
 ** Description: Get Data for Stock Report for Unit Cost AdjustMent For SSRS
 ** Purpose:          
 ** Date:   30-Jan-2026
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
  ** S NO   Date            Author				Change Description              
 ** --   --------			-------				--------------------------------            
    1    30-Jan-2026		Devendra Shekh        created

**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_GetInventoryUnitCostAdjustmentReport_SSRS]     
@mastercompanyid INT,
@id DATETIME2,
@id2 DATETIME2,
@id3 VARCHAR(100) = NULL,
@id4 VARCHAR(100) = NULL,
@strFilter VARCHAR(MAX) = NULL 
AS    
BEGIN    
  SET NOCOUNT ON;    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  BEGIN TRY    
    	   
	DECLARE	@level1Ids VARCHAR(MAX) = NULL,    
			@level2Ids VARCHAR(MAX) = NULL,    
			@level3Ids VARCHAR(MAX) = NULL,    
			@level4Ids VARCHAR(MAX) = NULL,    
			@level5Ids VARCHAR(MAX) = NULL,    
			@level6Ids VARCHAR(MAX) = NULL,    
			@level7Ids VARCHAR(MAX) = NULL,    
			@level8Ids VARCHAR(MAX) = NULL,    
			@level9Ids VARCHAR(MAX) = NULL,    
			@level10Ids VARCHAR(MAX) = NULL,    
			@CostType INT = 0,   
			@CycleCountStatusId INT = 0,
			@StockLineAdjustmentTypeId INT = 0,
			@BulkStocklineAdjustmentStatusId INT = 0,
			@PartNumber varchar(40) = NULL;
			
	SELECT @CostType = [StocklineAdjustmentDataTypeId] FROM [dbo].[StocklineAdjustmentDataType] WITH(NOLOCK) WHERE [Description] = 'Unit Cost';

	SELECT @CycleCountStatusId = [CycleCountStatusId] FROM [dbo].[CycleCountStatus] WITH(NOLOCK) WHERE [Status] = 'Closed';
	SELECT @StockLineAdjustmentTypeId = [StockLineAdjustmentTypeId] FROM [dbo].[StockLineAdjustmentType] WITH(NOLOCK) WHERE [Name] = 'Unit Price';
	SELECT @BulkStocklineAdjustmentStatusId = [Id] FROM [dbo].[StocklineAdjustmentStatus] WITH(NOLOCK) WHERE [Name] = 'Posted';
	
	/* --------------START: Get the timzone and UTC offset -------------- */
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
	SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
	FROM dbo.Employee E WITH (NOLOCK) 
	LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
	LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
	LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @id4;		
				
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
  
	DECLARE @ModuleID INT = 2; -- MS Module ID     
	SELECT @ModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline';

	SET @PartNumber = CASE WHEN ISNULL(@id3, '') <> '' AND CAST(@id3 AS BIGINT) > 0 THEN @id3 ELSE NULL END;

	;WITH rptCTE(	[pn], [pndescription], [cond], [sernum], [slnum], [ctrlnum], [qtyoh], [origunitcost], [newunitcost], [unitcostchange], [unitcostadjustmentamount], [reasoncode], [uom], [ponum], [ronum], [location],
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
		ISNULL(stl.[QuantityOnHand], 0) 'qtyoh',
		ISNULL(stladj.[ChangedFrom], 0) 'origunitcost',
		ISNULL(stladj.[ChangedTo], 0) 'newunitcost',
		(ISNULL(CAST(stladj.[ChangedTo] AS DECIMAL), 0) - ISNULL(CAST(stladj.[ChangedFrom] AS DECIMAL), 0)) AS 'unitcostchange',
		(ISNULL(stl.[QuantityOnHand], 0) * (ISNULL(CAST(stladj.[ChangedTo] AS DECIMAL), 0) - ISNULL(CAST(stladj.[ChangedFrom] AS DECIMAL), 0))) 'unitcostadjustmentamount',
		sar.[Description] 'reasoncode',
		UPPER(uom.[ShortName]) 'uom',
		UPPER(pox.[PurchaseOrderNumber]) 'ponum',
        UPPER(rox.[RepairOrderNumber]) 'ronum',  
		UPPER(stl.[Location]) 'location',
		stladj.[CreatedBy] 'adjby',
		CONVERT(DATETIME2, DATEADD(SECOND, @BaseUtcOffsetSec, stladj.[CreatedDate])) AS 'adjdate',
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
	AND stladj.[StocklineAdjustmentDataTypeId] IN(@CostType)
	AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, stladj.[CreatedDate])) BETWEEN CAST(@id AS DATE) AND CAST(@id2 AS DATE)  
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
		 ISNULL(stl.[QuantityOnHand], 0) 'qtyoh',
		 ISNULL(bsajd.[UnitCost], 0) 'origunitcost',
		 ISNULL(bsajd.[NewUnitCost], 0) 'newunitcost',
		 ISNULL(bsajd.[UnitCostAdjustment], 0) 'unitcostchange',
		 ISNULL(bsajd.[AdjustmentAmount], 0) 'unitcostadjustmentamount',
		 sar.[Description] 'reasoncode',
		 UPPER(uom.[ShortName]) 'uom',
		 UPPER(pox.[PurchaseOrderNumber]) 'ponum',
         UPPER(rox.[RepairOrderNumber]) 'ronum',
		 UPPER(stl.[Location]) 'location',
		 bsaj.[CreatedBy] 'adjby',
		 CONVERT(DATETIME2, DATEADD(SECOND, @BaseUtcOffsetSec, bsaj.[CreatedDate])) AS 'adjdate',
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
	AND CONVERT(DATE, DATEADD(SECOND, @BaseUtcOffsetSec, bsaj.[CreatedDate])) BETWEEN CAST(@id AS DATE) AND CAST(@id2 AS DATE) 
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

	,FinalCTE([pn], [pndescription], [cond], [sernum], [slnum], [ctrlnum], [qtyoh], [origunitcost], [newunitcost], [unitcostchange], [unitcostadjustmentamount],
			[reasoncode], [uom], [ponum], [ronum], [location], [adjby], [adjdate], [adjustedfrom],
			[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],[masterCompanyId]) 

	AS (SELECT DISTINCT [pn], [pndescription], [cond], [sernum], [slnum], [ctrlnum], [qtyoh], [origunitcost], [newunitcost], [unitcostchange], [unitcostadjustmentamount],
			[reasoncode], [uom], [ponum], [ronum], [location], [adjby], [adjdate], [adjustedfrom],
			[level1],[level2],[level3],[level4],[level5],[level6],[level7],[level8],[level9],[level10],[masterCompanyId]
	   FROM rptCTE)

	SELECT COUNT(1) OVER () AS [NumberOfItems], 
	                FC.[pn],
					FC.[pndescription], 
					FC.[cond], 
					FC.[sernum],
					FC.[slnum],
					FC.[ctrlnum],
			        FC.[qtyoh],
					FC.[origunitcost],
					FC.[newunitcost],
					FC.[unitcostchange],
					FC.[unitcostadjustmentamount],
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
					FC.[masterCompanyId]			   
				FROM FinalCTE FC
				ORDER BY adjdate DESC 
    
	END TRY
	BEGIN CATCH    
	DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME()    
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            ,    
            @AdhocComments varchar(150) = '[usprpt_GetInventoryUnitCostAdjustmentReport_SSRS]',    
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS VARCHAR(100)) +      
            '@Parameter2 = ''' + CAST(ISNULL(@id, '') AS VARCHAR(100)) +      
            '@Parameter3 = ''' + CAST(ISNULL(@id2, '') AS VARCHAR(100)) +      
            '@Parameter4 = ''' + CAST(ISNULL(@id3, '') AS VARCHAR(100)) +      
            '@Parameter5 = ''' + CAST(ISNULL(@id4, '') AS VARCHAR(100)) +      
            '@Parameter6 = ''' + CAST(ISNULL(@strFilter, '') AS VARCHAR(MAX)),  
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