/*************************************************************           
 ** File:   [USP_GetMultipleTenderedStockLineList]           
 ** Author:    Moin Bloch
 ** Description:  get  Multiple Tendered StockLine List
 ** Purpose:         
 ** Date:   18-SEP-2024
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------  
	1    18/09/2024		Moin Bloch  	     CREATED

EXEC [dbo].[USP_GetMultipleTenderedStockLineList] 4385,3908,1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetMultipleTenderedStockLineList]
@WorkOrderId BIGINT,
@WorkFlowWorkOrderId BIGINT,
@MasterCompanyId INT
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	
		DECLARE @RepairProvisionId INT = 0
		SELECT @RepairProvisionId  = [ProvisionId] FROM [dbo].[Provision] WITH(NOLOCK) WHERE UPPER([StatusCode]) = 'REPAIR';

		DECLARE @ModuleID INT = 2;
		SELECT @ModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WHERE UPPER([ModuleName]) = 'STOCKLINE';

		IF OBJECT_ID('tempdb..#MultipleTenderedStkListData') IS NOT NULL
			DROP TABLE #MultipleTenderedStkListData					

		CREATE TABLE #MultipleTenderedStkListData
		(		
			[WorkOrderMaterialsId] [bigint] NULL,
			[ItemMasterId] [bigint] NULL,
			[PartNumber] [varchar](50) NULL,
			[PartDescription] [nvarchar](MAX) NULL,
			[StockLineId] [bigint] NULL,
			[StockLineNumber] [varchar](50) NULL,
			[ControlNumber] [varchar](50) NULL,
			[IdNumber] [varchar](50) NULL,
			[ConditionId] [bigint] NULL,
			[Condition] [varchar](50) NULL,
			[QuantityRequested] [int] NULL,
			[QuantityTendered] [int] NULL,
			[QuantityOrder] [int] NULL,
			[IsSerialized] [bit] NULL, 
			[SerialNumber] [varchar](150) NULL, 			
			[UnitOfMeasureId] [bigint] NULL,
			[UOM] [varchar](50) NULL,
			[ProvisionId] [bigint] NULL,
			[Provision] [varchar](50) NULL,
			[WorkOrderId] [bigint] NULL,
			[WorkOrderNum] [varchar](50) NULL,
			[ManufacturerId] [bigint] NULL,
			[Manufacturer] [varchar](100) NULL,
			[SiteId] [bigint] NULL,
			[Site] [varchar](250) NULL,
			[WareHouseId] [bigint] NULL,
			[WareHouse] [varchar](250) NULL,
			[LocationId] [bigint] NULL,
			[Location] [varchar](250) NULL,
			[ShelfId] [bigint] NULL,
			[Shelf] [varchar](250) NULL,
			[BinId] [bigint] NULL,
			[Bin] [varchar](250) NULL,			
			[ManagementStructureId] [bigint] NULL,
			[LastMSLevel] [varchar](250) NULL,
			[AllMSlevels] [nvarchar](MAX) NULL,
			[IsKitType] [bit],
			[GLAccountId] [bigint] NULL, 
			[GlAccountName] [varchar](50) NULL,
			[UnitCost]  [DECIMAL](18,2) NULL,
			[AircraftTailNumber]  [varchar](100) NULL,
			[TraceableToType] [int] NULL,
			[TraceableTo]  [bigint] NULL, 
			[TraceableToName] [varchar](100) NULL,
			[TagTypeId] [bigint] NULL, 
			[TaggedByType] [int] NULL,
			[TaggedBy] [bigint] NULL, 
			[TaggedByName] [nvarchar](100) NULL,
			[TagDate] [DATETIME2](7),		  
			[StockType] [varchar](50) NULL
		)
			
		--Adding WorkOrder Material Data 
		INSERT INTO #MultipleTenderedStkListData ([WorkOrderMaterialsId],[ItemMasterId],[PartNumber],[PartDescription],[StockLineId],[StockLineNumber],
				[ControlNumber],[IdNumber],[ConditionId],[Condition],[QuantityRequested],[QuantityTendered],[QuantityOrder],[IsSerialized],
				[SerialNumber],[UnitOfMeasureId],[UOM],[ProvisionId],[Provision],[WorkOrderId],[WorkOrderNum],[ManufacturerId],[Manufacturer],
				[SiteId],[Site],[WareHouseId],[WareHouse],[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[ManagementStructureId],[LastMSLevel],[AllMSlevels],[IsKitType],
				[GLAccountId],[GlAccountName],[UnitCost],[AircraftTailNumber],[TraceableToType],[TraceableTo],[TraceableToName],
			    [TagTypeId],[TaggedByType],[TaggedBy],[TaggedByName],[TagDate],[StockType]) 
		SELECT WOMS.[WorkOrderMaterialsId],WOMS.[ItemMasterId],ITM.[PartNumber],ITM.[PartDescription],WOMS.[StockLineId],STK.[StockLineNumber],
		       STK.[ControlNumber],STK.[IdNumber],WOMS.[ConditionId],CND.[Description],WOMS.[Quantity],
			   CASE WHEN ISNULL(WOMS.[QuantityTurnIn],0) = 0 THEN WOMS.[Quantity] ELSE WOMS.[QuantityTurnIn] END,	
			   CASE WHEN ISNULL(WOMS.[QuantityTurnIn],0) = 0 THEN WOMS.[Quantity] ELSE WOMS.[QuantityTurnIn] END,			   
			   STK.[isSerialized],
		       STK.[SerialNumber],STK.[PurchaseUnitOfMeasureId],UOM.[ShortName],WOMS.[ProvisionId],ISNULL(PRV.[Description], ''),@WorkOrderId, WO.[WorkOrderNum],STK.[ManufacturerId],ISNULL(MFG.[Name], ''), 
			   STK.[SiteId],STK.[Site],STK.[WareHouseId],STK.[WareHouse],STK.[LocationId],STK.[Location],STK.[ShelfId],STK.[Shelf],STK.[BinId],STK.[Bin],
			   STK.[ManagementStructureId],MSD.[LastMSLevel],MSD.[AllMSlevels],0,
			   STK.[GLAccountId],STK.[GlAccountName], STK.[UnitCost],STK.[AircraftTailNumber], STK.[TraceableToType],STK.[TraceableTo],STK.[TraceableToName],
			   STK.[TagTypeId],STK.[TaggedByType],STK.[TaggedBy],STK.[TaggedByName],STK.[TagDate],			  
			   CASE WHEN ITM.[IsPma] = 1 AND ITM.[IsDER] = 1 THEN 'PMA&DER'
							 WHEN ITM.[IsPma] = 1 AND ITM.[IsDER] = 0 THEN 'PMA'
							 WHEN ITM.[IsPma] = 0 AND ITM.[IsDER] = 1 THEN 'DER'
							 ELSE 'OEM'
				END AS StockType
		FROM [dbo].[WorkOrderMaterialStockLine] WOMS WITH (NOLOCK) 
		    INNER JOIN [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK) ON WOM.[WorkOrderMaterialsId] = WOMS.[WorkOrderMaterialsId]  
			INNER JOIN [dbo].[ItemMaster] ITM WITH (NOLOCK) ON ITM.[ItemMasterId] = WOMS.[ItemMasterId]
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = WOMS.[StockLineId]
			INNER JOIN [dbo].[Condition] CND WITH (NOLOCK) ON CND.[ConditionId] = WOMS.[ConditionId]
			INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = STK.[PurchaseUnitOfMeasureId]			
			INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = @WorkOrderId
			 LEFT JOIN [dbo].[Provision] PRV WITH (NOLOCK) ON PRV.[ProvisionId] = WOMS.[ProvisionId]
			 LEFT JOIN [dbo].[Manufacturer] MFG WITH (NOLOCK) ON MFG.[ManufacturerId] = STK.[ManufacturerId]
			 LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @ModuleID AND MSD.[ReferenceID] = WOMS.[StockLineId] 
	   WHERE WOMS.[MasterCompanyId] = @MasterCompanyId
	     AND WO.[WorkOrderId] = @WorkOrderId 
		 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
		 AND WOMS.[ProvisionId] = @RepairProvisionId 
		 AND WOMS.[RepairOrderId] IS NULL
		 AND WOMS.[IsDeleted] = 0
							
		----Adding WorkOrder Material Kit Data 
		INSERT INTO #MultipleTenderedStkListData ([WorkOrderMaterialsId],[ItemMasterId],[PartNumber],[PartDescription],[StockLineId],[StockLineNumber],
				[ControlNumber],[IdNumber],[ConditionId],[Condition],[QuantityRequested],[QuantityTendered],[QuantityOrder],[IsSerialized],
				[SerialNumber],[UnitOfMeasureId],[UOM],[ProvisionId],[Provision],[WorkOrderId],[WorkOrderNum],[ManufacturerId],[Manufacturer],
				[SiteId],[Site],[WareHouseId],[WareHouse],[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[ManagementStructureId],[LastMSLevel],[AllMSlevels],[IsKitType], 
		        [GLAccountId],[GlAccountName],[UnitCost],[AircraftTailNumber],[TraceableToType],[TraceableTo],[TraceableToName],
			    [TagTypeId],[TaggedByType],[TaggedBy],[TaggedByName],[TagDate],[StockType])
		 SELECT WOMS.[WorkOrderMaterialsKitId],WOMS.[ItemMasterId],ITM.[PartNumber],ITM.[PartDescription],WOMS.[StockLineId],STK.[StockLineNumber],
		        STK.[ControlNumber],STK.[IdNumber],WOMS.[ConditionId],CND.[Description],WOMS.[Quantity],
				CASE WHEN ISNULL(WOMS.[QuantityTurnIn],0) = 0 THEN WOMS.[Quantity] ELSE WOMS.[QuantityTurnIn] END, 		
				CASE WHEN ISNULL(WOMS.[QuantityTurnIn],0) = 0 THEN WOMS.[Quantity] ELSE WOMS.[QuantityTurnIn] END, 				
				STK.[isSerialized],
		        STK.[SerialNumber],STK.[PurchaseUnitOfMeasureId],UOM.[ShortName],WOMS.[ProvisionId],ISNULL(PRV.[Description], ''),@WorkOrderId, WO.[WorkOrderNum],STK.[ManufacturerId],ISNULL(MFG.[Name], ''), 
			    STK.[SiteId],STK.[Site],STK.[WareHouseId],STK.[WareHouse],STK.[LocationId],STK.[Location],STK.[ShelfId],STK.[Shelf],STK.[BinId],STK.[Bin],
				STK.[ManagementStructureId],MSD.[LastMSLevel],MSD.[AllMSlevels],1,
				STK.[GLAccountId],STK.[GlAccountName],STK.[UnitCost],STK.[AircraftTailNumber],STK.[TraceableToType],
			    STK.[TraceableTo],STK.[TraceableToName],STK.[TagTypeId],STK.[TaggedByType],STK.[TaggedBy], STK.[TaggedByName],STK.[TagDate],			  
			    CASE WHEN ITM.[IsPma] = 1 AND ITM.[IsDER] = 1 THEN 'PMA&DER'
							 WHEN ITM.[IsPma] = 1 AND ITM.[IsDER] = 0 THEN 'PMA'
							 WHEN ITM.[IsPma] = 0 AND ITM.[IsDER] = 1 THEN 'DER'
							 ELSE 'OEM'
				END AS StockType
		FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH (NOLOCK) 
		    INNER JOIN [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK) ON WOM.[WorkOrderMaterialsKitId] = WOMS.[WorkOrderMaterialsKitId]  
			INNER JOIN [dbo].[ItemMaster] ITM WITH (NOLOCK) ON ITM.[ItemMasterId] = WOMS.[ItemMasterId]
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = WOMS.[StockLineId]
			INNER JOIN [dbo].[Condition] CND WITH (NOLOCK) ON CND.[ConditionId] = WOMS.[ConditionId]
			INNER JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = STK.[PurchaseUnitOfMeasureId]			
			INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = @WorkOrderId
			 LEFT JOIN [dbo].[Provision] PRV WITH (NOLOCK) ON PRV.[ProvisionId] = WOMS.[ProvisionId]
			 LEFT JOIN [dbo].[Manufacturer] MFG WITH (NOLOCK) ON MFG.[ManufacturerId] = STK.[ManufacturerId]
			 LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.[ModuleID] = @ModuleID AND MSD.[ReferenceID] = WOMS.[StockLineId] 
	   WHERE WOMS.[MasterCompanyId] = @MasterCompanyId 
	     AND WO.[WorkOrderId] = @WorkOrderId 
		 AND WOM.[WorkFlowWorkOrderId] = @WorkFlowWorkOrderId
		 AND WOMS.[ProvisionId] = @RepairProvisionId 
		 AND WOMS.[RepairOrderId] IS NULL
		 AND WOMS.[IsDeleted] = 0;
	
		SELECT  [WorkOrderMaterialsId],[ItemMasterId],[PartNumber],[PartDescription],[StockLineId],[StockLineNumber],
				[ControlNumber],[IdNumber],[ConditionId],[Condition],[QuantityRequested],[QuantityTendered],[QuantityOrder],[IsSerialized],
				[SerialNumber],[UnitOfMeasureId],[UOM],[ProvisionId],[Provision],[WorkOrderId],[WorkOrderNum],[ManufacturerId],[Manufacturer],
				[SiteId],[Site],[WareHouseId],[WareHouse],[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[ManagementStructureId],
				[LastMSLevel],[AllMSlevels],[IsKitType],[GLAccountId],[GlAccountName],[UnitCost],[AircraftTailNumber],[TraceableToType],[TraceableTo],[TraceableToName],
			    [TagTypeId],[TaggedByType],[TaggedBy],[TaggedByName],[TagDate],[StockType]
		FROM #MultipleTenderedStkListData ORDER BY [PartNumber]	

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetMultipleTenderedStockLineList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))			 
			  + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END