/*************************************************************           
 ** File:   [USP_VendorRMA_Edit_Receiving_DetailsById]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Get Vendor RMA Receiving List Details
 ** Date:   06/23/2023
 ** PARAMETERS: @VendorRMAId BIGINT          
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    06/23/2023   Moin Bloch     Created
*******************************************************************************
EXEC USP_VendorRMA_Edit_Receiving_DetailsById 39,64,2
*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_Edit_Receiving_DetailsById] 
@VendorRMAId BIGINT,
@VendorRMADetailId BIGINT,
@Opr INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
			DECLARE @Ids VARCHAR(MAX)= NULL;
			DECLARE @StocklineModuleId INT;
			DECLARE @ReceivingRMADraftModuleId INT;

			SELECT @StocklineModuleId = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'Stockline');
			SELECT @ReceivingRMADraftModuleId = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'ReceivingRMADraft');

		BEGIN TRY
		IF(@Opr=1)
		BEGIN						
			SET @Ids = (SELECT STRING_AGG([VendorRMADetailId], ',') FROM [dbo].[StockLineDraft] WITH(NOLOCK) 
				         WHERE [VendorRMAId]  = @VendorRMAId AND [IsDeleted] = 0 AND [IsParent] = 1);
				    
            SELECT VD.[VendorRMADetailId]
				  ,VD.[VendorRMAId]	
				  ,VD.[RMANum]
				  ,IM.[SiteId]
				  ,IM.[WarehouseId] 
                  ,IM.[LocationId] 
                  ,IM.[ShelfId]
                  ,IM.[BinId]
                  ,IM.[IsManufacturingDateAvailable]
                  ,IM.[IsReceivedDateAvailable]
                  ,IM.[IsTagDateAvailable]
                  ,IM.[IsExpirationDateAvailable]
				  ,SL.[ConditionId]
				  ,'' AS [Condition]
				  ,0 AS [IsIntangible]
				  ,VD.[ItemMasterId]	
				  ,IM.[PartNumber]
				  ,IM.[PartDescription]
				--,VD.[Qty] AS [QuantityOrdered]
				--,[QuantityBackOrdered] = (VD.[Qty] - (SELECT ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) FROM [dbo].[StockLine] SL WITH (NOLOCK) WHERE SL.[VendorRMADetailId] = VD.[VendorRMADetailId] AND SL.[IsDeleted] = 0 AND SL.[IsParent] = 1))
				  ,VD.[QtyShipped] AS [QuantityOrdered]
				  ,[QuantityBackOrdered] = (VD.[QtyShipped] - (SELECT ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) FROM [dbo].[StockLine] SL WITH (NOLOCK) WHERE SL.[VendorRMADetailId] = VD.[VendorRMADetailId] AND SL.[IsDeleted] = 0 AND SL.[IsParent] = 1))
				  ,SL.[ManufacturerId]
				  ,SL.[Manufacturer] AS [ManufacturerName]
				  ,SL.[ManagementStructureId]
				  ,'' AS [LastMSLevel]
				  ,'' AS [AllMSlevels]
				  ,SL.[PurchaseUnitOfMeasureId] AS [UOMId]		
				  ,UM.[ShortName] AS [UomText]
				  ,VD.[UnitCost]
				  ,VD.[ExtendedCost]
				  ,VD.[SerialNumber]
				  ,0 AS [DiscountPerUnit]  --> Default SET 0  
				  ,0  AS [AltEquiPartNumberId]
                  ,'' AS [AltEquiPartNumber]
                  ,'' AS [AltEquiPartDescription]
				  ,'Stock' AS [ItemType]
				  ,1 AS [ItemTypeId]
				  ,'' AS [StockType]
				  ,'' AS [ManufacturerPN]
				  ,'' AS [AssetClass]
                  ,'' AS [AssetModel]
				  ,0 AS [AssetAcquisitionTypeId]
				  ,0 AS [StockLineCount] 
				  ,1 AS [IsParent]
				  ,IM.[IsTimeLife]
			  FROM [dbo].[VendorRMADetail] VD WITH(NOLOCK) 
			  INNER JOIN [dbo].[VendorRMA] VR WITH(NOLOCK) ON VD.[VendorRMAId] = VR.[VendorRMAId]			  
			  INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON VD.[StockLineId] = SL.[StockLineId]
			  INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON VD.[ItemMasterId] = IM.[ItemMasterId]	
			   LEFT JOIN [dbo].[VendorRMAHeaderStatus] HS WITH (NOLOCK) ON VR.[VendorRMAStatusId] = HS.[VendorRMAStatusId]
			   LEFT JOIN [dbo].[UnitOfMeasure] UM WITH (NOLOCK) ON SL.[PurchaseUnitOfMeasureId] = UM.[UnitOfMeasureId]
			   LEFT JOIN [dbo].[StocklineManagementStructureDetails] MS WITH (NOLOCK) ON MS.[ReferenceID] = VD.[StockLineId] AND MS.[ModuleID] = @StocklineModuleId			
			  WHERE VD.[VendorRMADetailId] IN (SELECT * FROM dbo.SplitString(@Ids,','));
		END
		ELSE IF(@Opr=2)
		BEGIN
			SELECT SL.[VendorRMADetailId]
			      ,SL.[VendorRMAId]	
				  ,MS.[LastMSLevel]
				  ,MS.[AllMSlevels]	
				  ,SL.[StockLineDraftId]
				  ,SL.[StockLineNumber]
				  ,SL.[StockLineId]
				  ,SL.[ControlNumber]
				  ,SL.[IdNumber]
				  ,SL.[ConditionId]
				  ,SL.[SerialNumber]
				  ,SL.[Quantity]
				  ,SL.[RepairOrderUnitCost]
				  ,SL.[RepairOrderExtendedCost]
				  ,SL.[ReceiverNumber]
				  ,'' AS [WorkOrder]
                  ,'' AS [SalesOrder]
                  ,'' AS [SubWorkOrder]
				  ,SL.[OwnerType]
                  ,SL.[ObtainFromType]
                  ,SL.[TraceableToType]
                  ,SL.[ManufacturingTrace]
                  ,SL.[ManufacturerId]
                  ,SL.[ManufacturerLotNumber]
				  ,SL.[ManufacturingDate]
				  ,SL.[ManufacturingBatchNumber]
				  ,SL.[PartCertificationNumber]
				  ,SL.[EngineSerialNumber]
				  ,SL.[ShippingViaId]
				  ,SL.[ShippingReference]
				  ,SL.[ShippingAccount]
				  ,SL.[CertifiedDate]
				  ,SL.[CertifiedBy]
				  ,SL.[TagDate]
				  ,SL.[ExpirationDate]
				  ,SL.[CertifiedDueDate]
				  ,SL.[AircraftTailNumber]
				  ,SL.[GLAccountId]
				  ,SL.[GLAccount] AS [GLAccountText]
				  ,SL.[Condition] AS [ConditionText]
				  ,SL.[ManagementStructureEntityId]
				  ,SL.[SiteId]
				  ,SL.[WarehouseId] 
                  ,SL.[LocationId] 
                  ,SL.[ShelfId]
                  ,SL.[BinId]
				  ,SL.[SiteName] AS [SiteText]
                  ,SL.[Warehouse] AS [WarehouseText]
                  ,SL.[Location] AS [LocationText]
                  ,SL.[ShelfName] AS [ShelfText]
                  ,SL.[BinName] AS [BinText]
				  ,SL.[ObtainFrom]
				  ,SL.[Owner]
				  ,SL.[TraceableTo]
				  ,SL.[IsDeleted]
				  ,SL.[IsSerialized]
                  ,SL.[ObtainFromName]
                  ,SL.[OwnerName]
                  ,SL.[TraceableToName]
				  ,SL.[TaggedBy]
                  ,SL.[TaggedByName]
                  ,SL.[UnitOfMeasureId]
                  ,SL.[UnitOfMeasure]
                  ,SL.[RevisedPartId]
                  ,SL.[RevisedPartNumber]
                  ,SL.[TagType]
                  ,SL.[TagTypeId]
                  ,SL.[TaggedByType]
                  ,SL.[TaggedByTypeName]
                  ,SL.[CertifiedById]
                  ,SL.[CertifiedTypeId]
                  ,SL.[CertifiedType]
                  ,SL.[CertType]
                  ,SL.[CertTypeId]     
				  ,1 AS [ItemTypeId]
			FROM [dbo].[StockLineDraft] SL WITH(NOLOCK) 
			LEFT JOIN [dbo].[StockLineDraftManagementStructureDetails] MS WITH (NOLOCK) ON MS.[ReferenceID] = SL.[StockLineDraftId] AND MS.ModuleID = @ReceivingRMADraftModuleId						
			WHERE SL.[VendorRMAId] = @VendorRMAId AND 
			      SL.[VendorRMADetailId] = @VendorRMADetailId AND 
				  SL.[IsParent] = 1;
		END
		ELSE IF(@Opr=3)
		BEGIN
			SELECT [TimeLifeDraftCyclesId]
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
                  ,[MasterCompanyId]
                  ,[CreatedBy]
                  ,[UpdatedBy]
                  ,[CreatedDate]
                  ,[UpdatedDate]
                  ,[IsActive]                  
                  ,[StockLineDraftId]
                  ,[DetailsNotProvided]                  
                  ,[VendorRMAId]
                  ,[VendorRMADetailId]
			  FROM [dbo].[TimeLifeDraft] 
		     WHERE [VendorRMAId] = @VendorRMAId AND 
			       [VendorRMADetailId] = @VendorRMADetailId;
        END
	END TRY
    BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorRMA_Edit_Receiving_DetailsById]'			
			,@ProcedureParameters VARCHAR(3000) = '@VendorRMAId = ''' + CAST(ISNULL(@VendorRMAId, '') AS varchar(100))				 
            ,@ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END