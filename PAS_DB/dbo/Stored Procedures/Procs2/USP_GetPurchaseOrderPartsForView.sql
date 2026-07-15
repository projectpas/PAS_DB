-- ===== PROCEDURE: [dbo].[USP_GetPurchaseOrderPartsForView]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs2/USP_GetPurchaseOrderPartsForView.sql) =====
/*************************************************************           
 ** File:   [USP_GetPurchaseOrderPartsForView]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to get PurchaseOrderPartRecordId from StockLineDraft NonStockInventoryDraft  AssetInventoryDraft Tables
 ** Purpose:         
 ** Date:   15/04/2025        
          
 ** PARAMETERS: @PurchaseOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/04/2025   Moin Bloch     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
     
--  EXEC [dbo].[USP_GetPurchaseOrderPartsForView] 6732,1
--  EXEC [dbo].[USP_GetPurchaseOrderPartsForView] 6743,12853,0,1
--  EXEC [dbo].[USP_GetPurchaseOrderPartsForView] 6743,12855,0,3
exec dbo.USP_GetPurchaseOrderPartsForView @PurchaseOrderId=6743,@PurchaseOrderPartRecordId=12855,@StockLineId=default,@Opr=3
************************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_GetPurchaseOrderPartsForView]
@PurchaseOrderId BIGINT=NULL,
@PurchaseOrderPartRecordId BIGINT=NULL,
@StockLineId BIGINT=NULL,
@Opr INT=NULL
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @Stock INT=1,@NonStock INT=2,@Asset INT=11, @PurchaseOrderPartMSId INT,@AssetMSID INT,@StocklineMSID INT,@NonStocklineMSID INT
						
		SELECT @PurchaseOrderPartMSId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'POPart'

		SELECT @StocklineMSID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline'
	
  	    SELECT @NonStocklineMSID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'NonStockStockline'

		SELECT @AssetMSID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'AssetInventoryTangible'
				
		IF(@Opr=1)
		BEGIN
			IF OBJECT_ID(N'tempdb..#tblPurchaseOrderPartRecordIds') IS NOT NULL
			BEGIN
				DROP TABLE #tblPurchaseOrderPartRecordIds
			END

			CREATE TABLE #tblPurchaseOrderPartRecordIds
			(			
				[PurchaseOrderPartRecordId] [BIGINT] NULL
			)

			INSERT INTO #tblPurchaseOrderPartRecordIds([PurchaseOrderPartRecordId])		
			SELECT [PurchaseOrderPartRecordId] FROM [dbo].[StockLineDraft] WITH(NOLOCK) WHERE [PurchaseOrderId] = @PurchaseOrderId AND [isDeleted] = 0 AND (([IsParent] = 1 AND [isSerialized] = 1) OR ([IsParent] = 0 AND [isSerialized] = 0)) AND [StockLineId] IS NOT NULL --> 0
			UNION
			SELECT [PurchaseOrderPartRecordId] FROM [dbo].[NonStockInventoryDraft] WITH(NOLOCK) WHERE [PurchaseOrderId] = @PurchaseOrderId AND [isDeleted] = 0 AND (([IsParent] = 1 AND [isSerialized] = 1) OR ([IsParent] = 0 AND [isSerialized] = 0)) AND [NonStockInventoryId] > 0
			UNION
			SELECT [PurchaseOrderPartRecordId] FROM [dbo].[AssetInventoryDraft] WITH(NOLOCK) WHERE [PurchaseOrderId] = @PurchaseOrderId AND [isDeleted] = 0 AND (([IsParent] = 1 AND [isSerialized] = 1) OR ([IsParent] = 0 AND [isSerialized] = 0))  AND [AssetInventoryId] > 0

			SELECT DISTINCT
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN [itm].[SiteId]
				WHEN [part].[ItemTypeId] = @NonStock THEN [nsi].[SiteId]
				ELSE [asi].[SiteId]
			END AS [SiteId],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN [itm].[WarehouseId]
				WHEN [part].[ItemTypeId] = @NonStock THEN [nsi].[WarehouseId]
				ELSE [asi].[WarehouseId]
			END AS [WarehouseId],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN [itm].[LocationId]
				WHEN [part].[ItemTypeId] = @NonStock THEN [nsi].[LocationId]
				ELSE [asi].[AssetLocationId]
			END AS [LocationId],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN [itm].[ShelfId]
				WHEN [part].[ItemTypeId] = @NonStock THEN [nsi].[ShelfId]
				ELSE [asi].[ShelfId]
			END AS [ShelfId],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN [itm].[BinId]
				WHEN [part].[ItemTypeId] = @NonStock THEN [nsi].[BinId]
				ELSE [asi].[BinId]
			END AS [BinId],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN [part].[ConditionId]
				ELSE 0
			END AS [ConditionId],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN itm.[GLAccountId]
				WHEN [part].[ItemTypeId] = @NonStock THEN [nsi].[GLAccountId]
				ELSE 0
			END AS [GLAccountId],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN ISNULL(itm.[IsTimeLife],0)				
				ELSE 0
			END AS [IsTimeLife],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN itm.[IsSerialized]
				WHEN [part].[ItemTypeId] = @NonStock THEN [nsi].[IsSerialized]
				ELSE [asi].[IsSerialized]
			END AS [IsSerialized],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN itm.[ManufacturerId]
				WHEN [part].[ItemTypeId] = @NonStock THEN [nsi].[ManufacturerId]
				ELSE [asi].[ManufacturerId]
			END AS [ManufacturerId],			 
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN ISNULL(itm.[IsPma],0)				
				ELSE 0
			END AS [IsPma],
			CASE 
				WHEN [part].[ItemTypeId] = @Stock THEN ISNULL(itm.[IsDER],0)				
				ELSE 0
			END AS [IsDER],                                 								 
			[part].[PurchaseOrderId],
			[part].[PurchaseOrderPartRecordId],
			[part].[ItemMasterId],
			[part].[PartNumber],
			[part].[PartDescription],
			[part].[QuantityOrdered],
			([part].[QuantityOrdered] - ISNULL([part].[QuantityReceived], 0)) AS [QuantityBackOrdered],
			ISNULL([part].[QuantityReceived], 0) AS [QuantityReceived],			
			[part].[Manufacturer],
			(
				SELECT TOP 1 [LastMSLevel]
				FROM [dbo].[PurchaseOrderManagementStructureDetails] WITH(NOLOCK)
				WHERE [ReferenceID] = [part].[PurchaseOrderPartRecordId] 
				  AND [ModuleID] = @PurchaseOrderPartMSId
			) AS [LastMSLevel],
			(
				SELECT TOP 1 [AllMSlevels]
				FROM [dbo].[PurchaseOrderManagementStructureDetails] WITH(NOLOCK)
				WHERE [ReferenceID] = [part].[PurchaseOrderPartRecordId] 
				  AND [ModuleID] = @PurchaseOrderPartMSId
			) AS [AllMSlevels],
			[part].[ManagementStructureId],
			[part].[UnitOfMeasure],
			[part].[UnitCost],
			[part].[ExtendedCost],
			[part].[DiscountPerUnit],
			[part].[WorkOrderNo],
			[part].[SubWorkOrderNo],
			[part].[SalesOrderNo],
			[part].[ReapairOrderNo],
			[part].[AltEquiPartNumberId],
			[part].[AltEquiPartNumber],
			[part].[AltEquiPartDescription],
			[part].[ItemType],
			[part].[ItemTypeId],
			[part].[StockType],		
			ISNULL([part].[QuantityReceived],0) [StockLineCount],
			[part].[POPartSplitUser] AS [PoPartSplitUserName]
		FROM [dbo].[PurchaseOrderPart] part WITH(NOLOCK)
		LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON [part].[ItemMasterId] = [itm].[ItemMasterId]
		 AND ISNULL(itm.IsNonStock,0) = 0
		 LEFT JOIN [dbo].[Asset] asi WITH(NOLOCK) ON [part].[ItemMasterId] = [asi].[AssetRecordId]
		LEFT JOIN [dbo].[ItemMasterNonStock] nsi WITH(NOLOCK) ON [part].[ItemMasterId] = [nsi].[MasterPartId]
		WHERE [part].[PurchaseOrderPartRecordId] IN (SELECT [PurchaseOrderPartRecordId] FROM #tblPurchaseOrderPartRecordIds)
   
		END
		IF(@Opr=2)
		BEGIN
			SELECT 	
			[ItemTypeId] = @Stock,
			MD.[LastMSLevel],
			MD.[AllMSlevels],
			SL.[StockLineNumber],
			SL.[ControlNumber],
			SL.[IdNumber],
            SL.[SerialNumber],		
			CASE WHEN [SL].[IsSerialized] = 1 THEN [SL].[Quantity]
			ELSE (
			  SELECT ISNULL(SUM([x].[Quantity]),0)
			  FROM [dbo].[StocklineDraft] AS [x] WITH(NOLOCK)
			  WHERE [x].[PurchaseOrderId] = [SL].[PurchaseOrderId]
				AND [x].[PurchaseOrderPartRecordId] = [SL].[PurchaseOrderPartRecordId]
				AND [x].[StockLineId] = SL.[StockLineId]
			)
			END [Quantity],
			ISNULL(SL.[PurchaseOrderUnitCost],0) [PurchaseOrderUnitCost],
			SL.[PurchaseOrderExtendedCost],
			SL.[ReceiverNumber],
			SL.[OwnerType],
            SL.[ObtainFromType],
            SL.[TraceableToType],
            (SELECT [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleID] = SL.[OwnerType]) AS [OwnerTypeName],
            (SELECT [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleID] = SL.[ObtainFromType]) AS [ObtainFromTypeName],
            (SELECT [ModuleName] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleID] = SL.[TraceableToType]) AS [TraceableToTypeName],
            SL.[ManufacturingTrace] [ManufacturingTraceName],
            SL.[ManufacturingTrace],
            SL.[ManufacturerId],
            SL.[ManufacturerLotNumber],
			--CASE WHEN [SL].[ManufacturingDate] IS NOT NULL THEN FORMAT([SL].[ManufacturingDate], 'MM/dd/yyyy') ELSE NULL END AS [ManufacturingDate],
			SL.[ManufacturingDate],
			SL.[ManufacturingBatchNumber],
			SL.[PartCertificationNumber],			
            SL.[EngineSerialNumber],
            SL.[ShippingViaId],
            SL.[ShippingReference],
            SL.[ShippingAccount],	
			--CASE 
			--	WHEN SL.[CertifiedDate] IS NOT NULL THEN FORMAT(SL.[CertifiedDate], 'MM/dd/yyyy')
			--	ELSE NULL
			--END AS [CertifiedDate],
			SL.[CertifiedDate],
			SL.[CertifiedBy],
			--CASE 
			--	WHEN SL.[TagDate] IS NOT NULL THEN FORMAT(SL.[TagDate], 'MM/dd/yyyy')
			--	ELSE NULL
			--END AS [TagDate],
			SL.[TagDate],
			--CASE 
			--	WHEN SL.[ExpirationDate] IS NOT NULL THEN FORMAT(SL.[ExpirationDate], 'MM/dd/yyyy')
			--	ELSE NULL
			--END AS [ExpirationDate],
			SL.[ExpirationDate],
			--CASE 
			--	WHEN SL.[CertifiedDueDate] IS NOT NULL THEN FORMAT(SL.[CertifiedDueDate], 'MM/dd/yyyy')
			--	ELSE NULL
			--END AS [CertifiedDueDate],
			SL.[CertifiedDueDate],
			SL.[AircraftTailNumber],
			SL.[GLAccountId],
			SL.[GlAccountName] AS [GLAccountText],
			SL.[ConditionId],
			SL.[Condition] AS [ConditionText],
			SL.[ManagementStructureId] [ManagementStructureEntityId],
			SL.[SiteId],
			SL.[WarehouseId],
			SL.[LocationId],
			SL.[ShelfId],
			SL.[BinId],
			SL.[Manufacturer] AS [ManufacturerText],			
			SV.[Name] AS ShippingViaText,
			SL.[Site] AS SiteText,
			SL.[Warehouse] AS WarehouseText,
			SL.[Location] AS LocationText,
			SL.[Shelf] AS ShelfText,
			SL.[Bin] AS BinText,
			SL.[ObtainFrom],
			SL.[Owner],
			SL.[TraceableTo],
			SL.[ObtainFromName] AS [ObtainFromText],
			SL.[OwnerName] AS [OwnerText],
			SL.[TraceableToName] AS [TraceableToText],	
			SL.[TaggedBy],
			SL.[TaggedByName],
			SL.[TaggedByType],
			SL.[TaggedByTypeName],
			SL.[PurchaseUnitOfMeasureId] [UnitOfMeasureId],
			SL.[UnitOfMeasure],
			SL.[TagType],
			SL.[TagTypeId],
			SL.[CertifiedType],
			SL.[CertType],
			SL.[CertTypeId],			
			CASE WHEN SL.[PurchaseOrderUnitCost] > 0 THEN SL.[PurchaseOrderUnitCost] ELSE 0 END [UnitCost],
			SL.[StockLineId] 
		FROM [dbo].[Stockline] SL WITH(NOLOCK) 
		LEFT JOIN [dbo].[ShippingVia] SV WITH(NOLOCK) ON SL.[ShippingViaId] = SV.[ShippingViaId]
		LEFT JOIN [dbo].[StockLineManagementStructureDetails] MD WITH(NOLOCK) ON MD.[ReferenceID] = SL.[StockLineId] AND [ModuleID] = @StocklineMSID
		WHERE SL.[PurchaseOrderId] = @PurchaseOrderId AND SL.[PurchaseOrderPartRecordId] = @PurchaseOrderPartRecordId AND SL.isDeleted = 0 AND ISNULL(SL.IsNonStock,0) = 0
		
		END
		IF(@Opr=3)
		BEGIN
			SELECT 	
			[ItemTypeId] = @NonStock,		
			MD.[LastMSLevel],
			MD.[AllMSlevels],
			SL.[NonStockInventoryNumber] [StockLineNumber],
            SL.[ControlNumber],
            SL.[IdNumber],
            SL.[SerialNumber],
            ISNULL(SL.[Quantity],0) [Quantity],
            ISNULL(SL.[UnitCost],0) [PurchaseOrderUnitCost],
            (ISNULL(SL.[UnitCost],0) * SL.[Quantity]) [PurchaseOrderExtendedCost],
			ISNULL(SL.[ReceiverNumber],'') [ReceiverNumber],
			0 [OwnerType],
			0 [ObtainFromType],
			0 [TraceableToType],
			'' [OwnerTypeName],
            '' [ObtainFromTypeName],
            '' [TraceableToTypeName],
			'' [ManufacturingTraceName],
            '' [ManufacturingTrace],
			SL.[ManufacturerId],
			'' [ManufacturerLotNumber],
			NULL AS [ManufacturingDate],
			'' [ManufacturingBatchNumber],
			'' [PartCertificationNumber],
			'' [EngineSerialNumber],
			SL.[ShippingViaId],
            SL.[ShippingReference],
            SL.[ShippingAccount],
			NULL [CertifiedDate],
			'' [CertifiedBy],
			NULL AS [TagDate],
			--CASE WHEN SL.[MfgExpirationDate] IS NOT NULL THEN FORMAT(SL.[MfgExpirationDate], 'MM/dd/yyyy') ELSE NULL END AS [ExpirationDate],
			SL.[MfgExpirationDate] AS [ExpirationDate],
			NULL AS [CertifiedDueDate],
			''  [AircraftTailNumber],
            NULL AS [LastCalibrationDate],
			NULL AS [NextCalibrationDate],
			SL.[GLAccountId],
			SL.[GLAccount] [GLAccountText],
			0 AS [ConditionId],
			SL.[Condition] AS [ConditionText],
			SL.[ManagementStructureId] [ManagementStructureEntityId],			
            SL.[SiteId],
            SL.[WarehouseId],
            SL.[LocationId],
            SL.[ShelfId],
            SL.[BinId],
            SL.[Manufacturer] [ManufacturerText],
            SL.[ShippingVia] [ShippingViaText],
            SL.[Site] SiteText,
            SL.[Warehouse] WarehouseText,
            SL.[Location] LocationText,
            SL.[Shelf] ShelfText,
            SL.[Bin] BinText,
			0 [ObtainFrom],
			0 [Owner],
			0 [TraceableTo],
			'' [ObtainFromText],
			'' [OwnerText],
			'' [TraceableToText],
			 0 [TaggedBy],
			'' [TaggedByName],
			 0 [TaggedByType],
		    '' [TaggedByTypeName],
			SL.[UnitOfMeasureId],
			'' [UnitOfMeasure],
			'' [TagType],
			 0 [TagTypeId],
			'' [CertifiedType],
            '' [CertType],
			'' [CertTypeId],
            SL.[UnitCost],
			 0 [StockLineId] 
		FROM [dbo].[NonStockInventory] SL WITH(NOLOCK) 
		LEFT JOIN [dbo].[NonStocklineManagementStructureDetails] MD WITH(NOLOCK) ON MD.[ReferenceID] = SL.[NonStockInventoryId] AND [ModuleID] = @NonStocklineMSID
		WHERE SL.[PurchaseOrderId] = @PurchaseOrderId AND SL.[PurchaseOrderPartRecordId] = @PurchaseOrderPartRecordId AND SL.isDeleted = 0
					
		END
		IF(@Opr=4)
		BEGIN
			SELECT
			[ItemTypeId] = @Asset,
			MD.[LastMSLevel],
			MD.[AllMSlevels],
			SL.[StklineNumber] StockLineNumber,
			SL.[ControlNumber],
			'' IdNumber,
			SL.[SerialNo] AS [SerialNumber],
            ISNULL(SL.Qty,0) [Quantity],
            ISNULL(SL.UnitCost,0) [PurchaseOrderUnitCost],
            (ISNULL(SL.UnitCost,0) * ISNULL(SL.Qty,0)) [PurchaseOrderExtendedCost],
			CASE WHEN SL.ReceiverNumber IS NULL THEN '' ELSE SL.ReceiverNumber END ReceiverNumber,
			0 [OwnerType],
			0 [ObtainFromType],
			0 [TraceableToType],			
			'' [OwnerTypeName],
            '' [ObtainFromTypeName],
            '' [TraceableToTypeName],
			'' [ManufacturingTraceName],
            '' [ManufacturingTrace],
			SL.ManufacturerId,
			'' [ManufacturerLotNumber],
		    --CASE WHEN SL.[ManufacturedDate] IS NOT NULL THEN FORMAT(SL.[ManufacturedDate], 'MM/dd/yyyy') ELSE NULL END AS ManufacturingDate,
			SL.[ManufacturedDate] AS [ManufacturingDate],
			'' [ManufacturingBatchNumber],
			'' [PartCertificationNumber],
			'' [EngineSerialNumber],
			NULL [ShippingViaId],
            NULL [ShippingReference],
            NULL [ShippingAccount],
			NULL [CertifiedDate],
			'' [CertifiedBy],
			NULL [TagDate],
			--CASE WHEN SL.[ExpirationDate] IS NOT NULL THEN FORMAT(SL.[ExpirationDate], 'MM/dd/yyyy') ELSE NULL END AS [ExpirationDate],
			SL.[ExpirationDate] AS [ExpirationDate],
			NULL AS [CertifiedDueDate],
			''  [AircraftTailNumber],
			SL.IntangibleGLAccountId  [GLAccountId], 
			SL.IntangibleGLAccountName GLAccountText,
			0  AS [ConditionId],
			'' AS [ConditionText],
			NULL AS [LastCalibrationDate],
			NULL AS [NextCalibrationDate],
            SL.[IntangibleGLAccountId],            
			SL.[ManagementStructureId] [ManagementStructureEntityId],
            SL.[SiteId],
            SL.[WarehouseId],
            SL.[LocationId],
            SL.[ShelfId],
            SL.[BinId],
            SL.[ManufactureName] [ManufacturerText],
            '' [ShippingViaText],
            SL.[SiteName] SiteText,
            SL.[Warehouse] WarehouseText,
            SL.[Location] LocationText,
            SL.[ShelfName] ShelfText,
            SL.[BinName] BinText,
			0 [ObtainFrom],
			0 [Owner],
			0 [TraceableTo],
			'' [ObtainFromText],
			'' [OwnerText],
			'' [TraceableToText],
			 0 [TaggedBy],
			'' [TaggedByName],
			 0 [TaggedByType],
		    '' [TaggedByTypeName],	
            SL.[UnitOfMeasureId],    
			'' [UnitOfMeasure],
			'' [TagType],
			 0 [TagTypeId],
			'' [CertifiedType],
			'' [CertType],
			'' [CertTypeId],
            SL.[UnitCost] ,
			 0 [StockLineId] 
		FROM [dbo].[AssetInventory] SL WITH(NOLOCK) 
		LEFT JOIN [dbo].[AssetManagementStructureDetails] MD WITH(NOLOCK) ON MD.[ReferenceID] = SL.[AssetInventoryId] AND [ModuleID] = @AssetMSID
		WHERE SL.[PurchaseOrderId] = @PurchaseOrderId AND SL.[PurchaseOrderPartRecordId] = @PurchaseOrderPartRecordId AND SL.isDeleted = 0
				
		END
		IF(@Opr=5)
		BEGIN
			SELECT TOP 1 [TimeLifeCyclesId] AS [TimeLifeDraftCyclesId]
				  ,[CyclesRemaining]
				  ,[CyclesSinceNew]
				  ,[CyclesSinceOVH]
				  ,[CyclesSinceInspection]
				  ,[CyclesSinceRepair]
				  ,[TimeRemaining]
				  ,[TimeSinceNew]
				  ,[TimeSinceOVH]
				  ,[TimeSinceInspection]
				  ,[TimeSinceRepair]
				  ,[LastSinceNew]
				  ,[LastSinceOVH]
				  ,[LastSinceInspection]
				  ,[DetailsNotProvided]
			  FROM [dbo].[TimeLife] WITH(NOLOCK)
			 WHERE [StockLineId] = @StockLineId;
		END
			
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetPurchaseOrderPartsForView' 
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@PurchaseOrderId AS VARCHAR(100)), '') + ''
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