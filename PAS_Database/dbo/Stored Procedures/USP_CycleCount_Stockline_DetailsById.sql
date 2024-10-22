/*************************************************************           
 ** File:   [USP_CycleCount_Stockline_DetailsById]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Get Cycle Count Stockline Details
 ** Purpose:         
 ** Date:   18/10/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    21/10/2024   Moin Bloch    Created

   EXEC [dbo].[USP_CycleCount_Stockline_DetailsById] @UnitCost=10.00,@IsCustomerStock=0,@SiteId=2,@WarehouseId=0,@LocationId=0,@ShelfId=0,@BinId=0,@ManagementStructureId=1,@MasterCompanyId=1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CycleCount_Stockline_DetailsById]
@UnitCost DECIMAL(18,2),
@IsCustomerStock BIT,
@SiteId BIGINT,
@WarehouseId BIGINT,
@LocationId BIGINT,
@ShelfId BIGINT,
@BinId BIGINT,
@ManagementStructureId BIGINT,
@MasterCompanyId INT
AS  
BEGIN  
	SET NOCOUNT ON;	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		    
	BEGIN TRY
					
		IF(@UnitCost = 0)
		BEGIN
			SET @UnitCost = NULL;
		END
		IF(@SiteId = 0)
		BEGIN
			SET @SiteId = NULL;
		END
		IF(@WarehouseId = 0)
		BEGIN
			SET @WarehouseId = NULL;
		END
		IF(@LocationId = 0)
		BEGIN
			SET @LocationId = NULL;
		END
		IF(@ShelfId = 0)
		BEGIN
			SET @ShelfId = NULL;
		END
		IF(@BinId = 0)
		BEGIN
			SET @BinId = NULL;
		END
		
		SELECT SL.[StockLineId],
			   SL.[StockLineNumber],
			   SL.[ItemMasterId],
			   IM.[PartNumber],
			   IM.[PartDescription],
			   SL.[ControlNumber],
			   SL.[IdNumber],
			   SL.[SerialNumber],
			   SL.[ManufacturerId],
			   MF.[Name] [ManufacturerName],
			   SL.[ConditionId],
			   CO.[Description] [ConditionName],
			   SL.[PurchaseUnitOfMeasureId],
			   UM.[ShortName] [UnitOfMeasureName],
			   ISNULL(SL.[QuantityAvailable],0) [QuantityAvailable],
			   SL.[QuantityOnHand],
			   ISNULL(SL.[UnitCost],0) [UnitCost],
			   IM.[PurchaseCurrencyId],
			   CR.[Code] [CurrencyName],
			   SL.[SiteId],
			   SI.[Name] [Site],
			   SL.[WarehouseId],
			   WH.[Name] [Warehouse],
			   SL.[LocationId],
			   LO.[Name] [Location],
			   SL.[ShelfId],
			   SF.[Name] [Shelf],
			   SL.[BinId],
			   BI.[Name] [Bin],
			   CASE WHEN SL.[IsCustomerStock] = 1 THEN 1 ELSE 0 END [IsCustomerStock],	
			   SL.[ManagementStructureId]
		  FROM [dbo].[Stockline] SL WITH(NOLOCK)
		  JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId] 
		  JOIN [dbo].[Site] SI WITH(NOLOCK) ON SL.[SiteId] = SI.[SiteId]			
		  LEFT JOIN [dbo].[Manufacturer] MF WITH(NOLOCK) ON SL.[ManufacturerId] = MF.[ManufacturerId] 
		  LEFT JOIN [dbo].[Condition] CO WITH(NOLOCK) ON SL.[ConditionId] = CO.[ConditionId] 
		  LEFT JOIN [dbo].[UnitOfMeasure] UM WITH(NOLOCK) ON SL.[PurchaseUnitOfMeasureId] = UM.[UnitOfMeasureId]		       		 
		  LEFT JOIN [dbo].[Warehouse] WH WITH(NOLOCK) ON SL.[WarehouseId] = WH.[WarehouseId]
		  LEFT JOIN [dbo].[Location] LO WITH(NOLOCK) ON SL.[LocationId] = LO.[LocationId]
		  LEFT JOIN [dbo].[Shelf] SF WITH(NOLOCK) ON SL.[ShelfId] = SF.[ShelfId]
		  LEFT JOIN [dbo].[Bin] BI WITH(NOLOCK) ON SL.[BinId] = BI.[BinId]
		  LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON  IM.[PurchaseCurrencyId] = CR.[CurrencyId]
		 WHERE SL.[IsParent] = 1 AND SL.[QuantityOnHand] > 0 AND
			   (@MasterCompanyId IS NULL OR SL.[MasterCompanyId] = @MasterCompanyId) AND
		       (@UnitCost IS NULL OR SL.[UnitCost] >= @UnitCost) AND
		       (@IsCustomerStock IS NULL OR SL.[IsCustomerStock] = @IsCustomerStock) AND
		       (@SiteId IS NULL OR SL.[SiteId] = @SiteId) AND
               (@WarehouseId IS NULL OR SL.[WarehouseId] = @WarehouseId) AND
               (@LocationId IS NULL OR SL.[LocationId] = @LocationId) AND        
               (@ShelfId IS NULL OR SL.[ShelfId] = @ShelfId) AND
               (@BinId IS NULL OR SL.[BinId] = @BinId) AND
               (@ManagementStructureId IS NULL OR SL.[ManagementStructureId] = @ManagementStructureId) 		
	END TRY  
		BEGIN CATCH      
			IF @@trancount > 0			
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CycleCount_Stockline_DetailsById' 
			  , @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH    
END