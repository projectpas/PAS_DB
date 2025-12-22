


/*************************************************************           
 ** File:   [USP_CycleCountDetail_AddUpdate]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to INSERT AND UPDATE Cycle Count Details
 ** Purpose:         
 ** Date:   23/10/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    23/10/2024   Moin Bloch		Created
	2    26/12/2024   Moin Bloch		Added LegalEntityId Field	
	3    14/05/2025   Amit Ghediya      Added Adjustment Reason.
	4    22/12/2025   Rajesh Gami		Modify the type and SP (Change the type INT to DECIMAL for QTY related fields)
  EXEC [dbo].[USP_CycleCountDetail_AddUpdate]  
************************************************************************/
CREATE       PROCEDURE [dbo].[USP_CycleCountDetail_AddUpdate]
@TableCycleCountDetailType CycleCountDetailType READONLY  
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
				 DECLARE @TotalRecord int = 0;   
				 DECLARE @MinId BIGINT = 1; 
				 IF OBJECT_ID(N'tempdb..#TempCycleCountDetail') IS NOT NULL
			     BEGIN
					DROP TABLE #TempCycleCountDetail
			     END

				CREATE TABLE #TempCycleCountDetail(
				[ID] BIGINT NOT NULL IDENTITY,
				[CycleCountDetailId] [bigint] NULL,
				[CycleCountId] [bigint] NULL,
				[StockLineId] [bigint] NULL,
				[StockLineNumber] [varchar](50) NULL,
				[ControlNumber] [varchar](50) NULL,
				[IdNumber] [varchar](50) NULL,
				[SerialNumber] [varchar](50) NULL,
				[ItemMasterId] [bigint]  NULL,
				[PartNumber] [varchar](50) NULL,
				[PartDescription] [nvarchar](max) NULL,
				[ManufacturerId] [bigint] NULL,
				[ManufacturerName] [varchar](50) NULL,
				[ConditionId] [bigint] NULL,
				[ConditionName] [varchar](50) NULL,
				[UnitOfMeasureId] [bigint] NULL,
				[UnitOfMeasureName] [varchar](50) NULL,
				[UnitCost] [decimal](18, 2) NULL,
				[CurrencyId] [bigint] NULL,
				[CurrencyName] [varchar](50) NULL,
				[SiteId] [bigint] NULL,
				[Site] [varchar](50) NULL,
				[WarehouseId] [bigint] NULL,
				[Warehouse] [varchar](50) NULL,
				[LocationId] [bigint] NULL,
				[Location] [varchar](50) NULL,
				[ShelfId] [bigint] NULL,
				[Shelf] [varchar](50) NULL,
				[BinId] [bigint] NULL,
				[Bin] [varchar](50) NULL,
				[CurrentStockQuantity] [decimal](18, 6) NULL,
				[CountedQuantity] [decimal](18, 6) NULL,
				[DifferenceQuantity] [decimal](18, 6) NULL,
				[DifferenceAmount] [decimal](18, 6) NULL,
				[IsCustomerStock] [bit] NULL,
				[ManagementStructureId] [bigint] NULL,
				[LegalEntityId] [bigint] NULL,
				[MasterCompanyId] [int] NULL,
				[CreatedBy] [varchar](256) NULL,
				[UpdatedBy] [varchar](256) NULL,
				[AdjustmentReasonId] [bigint] NULL)
				
				INSERT INTO #TempCycleCountDetail([CycleCountDetailId],[CycleCountId],[StockLineId],[StockLineNumber],[ControlNumber],
				            [IdNumber],[SerialNumber],[ItemMasterId],[PartNumber],[PartDescription],[ManufacturerId],
							[ManufacturerName],[ConditionId],[ConditionName],[UnitOfMeasureId],[UnitOfMeasureName],
							[UnitCost],[CurrencyId],[CurrencyName],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],
							[Location],[ShelfId],[Shelf],[BinId],[Bin],[CurrentStockQuantity],[CountedQuantity],
							[DifferenceQuantity],[DifferenceAmount],[IsCustomerStock],[ManagementStructureId],[LegalEntityId],
							[MasterCompanyId],[CreatedBy],[UpdatedBy],[AdjustmentReasonId])
					 SELECT [CycleCountDetailId],[CycleCountId],[StockLineId],[StockLineNumber],[ControlNumber],
				            [IdNumber],[SerialNumber],[ItemMasterId],[PartNumber],[PartDescription],[ManufacturerId],
							[ManufacturerName],[ConditionId],[ConditionName],[UnitOfMeasureId],[UnitOfMeasureName],
							[UnitCost],[CurrencyId],[CurrencyName],[SiteId],[Site],[WarehouseId],[Warehouse],[LocationId],
							[Location],[ShelfId],[Shelf],[BinId],[Bin],[CurrentStockQuantity],[CountedQuantity],
							[DifferenceQuantity],[DifferenceAmount],[IsCustomerStock],[ManagementStructureId],[LegalEntityId],
							[MasterCompanyId],[CreatedBy],[UpdatedBy],[AdjustmentReasonId]
					   FROM @TableCycleCountDetailType;
				
				SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #TempCycleCountDetail    
		
				WHILE @MinId <= @TotalRecord
				BEGIN
				
					DECLARE @CycleCountDetailId BIGINT = 0;

					SELECT @CycleCountDetailId = ISNULL([CycleCountDetailId],0) FROM #TempCycleCountDetail WHERE [ID] = @MinId;

					IF(@CycleCountDetailId = 0)
					BEGIN
						INSERT INTO [dbo].[CycleCountDetail]([CycleCountId],[StockLineId],[StockLineNumber],[ControlNumber],[IdNumber],[SerialNumber],
									[ItemMasterId],[PartNumber],[PartDescription],[ManufacturerId],[ManufacturerName],[ConditionId],[ConditionName],
									[UnitOfMeasureId],[UnitOfMeasureName],[UnitCost],[CurrencyId],[CurrencyName],[SiteId],[Site],[WarehouseId],[Warehouse],
									[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[CurrentStockQuantity],[CountedQuantity],[DifferenceQuantity],
									[DifferenceAmount],[IsCustomerStock],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
									[UpdatedDate],[IsActive],[IsDeleted],[AdjustmentReasonId])
							 SELECT [CycleCountId],[StockLineId],[StockLineNumber],[ControlNumber],[IdNumber],[SerialNumber],
									[ItemMasterId],[PartNumber],[PartDescription],[ManufacturerId],[ManufacturerName],[ConditionId],[ConditionName],
									[UnitOfMeasureId],[UnitOfMeasureName],[UnitCost],[CurrencyId],[CurrencyName],[SiteId],[Site],[WarehouseId],[Warehouse],
									[LocationId],[Location],[ShelfId],[Shelf],[BinId],[Bin],[CurrentStockQuantity],[CountedQuantity],[DifferenceQuantity],
									[DifferenceAmount],[IsCustomerStock],[ManagementStructureId],[LegalEntityId],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),
									GETUTCDATE(),1,0,[AdjustmentReasonId]					
							   FROM #TempCycleCountDetail WHERE [ID] = @MinId;

						     SELECT @CycleCountDetailId = SCOPE_IDENTITY();  

							 EXEC [dbo].[USP_CycleCountDetail_UpdateColumnsWithId] @CycleCountDetailId;
					END
					ELSE 
					BEGIN
							UPDATE CD 
							   SET CD.[ManufacturerId] = TR.[ManufacturerId]
								  ,CD.[ManufacturerName] = TR.[ManufacturerName]
								  ,CD.[UnitOfMeasureId] = TR.[UnitOfMeasureId]
								  ,CD.[UnitOfMeasureName] = TR.[UnitOfMeasureName]
								  ,CD.[SiteId] = TR.[SiteId]
								  ,CD.[Site] = TR.[Site]
								  ,CD.[WarehouseId] = TR.[WarehouseId]
								  ,CD.[Warehouse] = TR.[Warehouse]
								  ,CD.[LocationId] = TR.[LocationId]
								  ,CD.[Location] = TR.[Location]
								  ,CD.[ShelfId] = TR.[ShelfId]
								  ,CD.[Shelf] = TR.[Shelf] 
								  ,CD.[BinId] = TR.[BinId]
								  ,CD.[Bin] = TR.[Bin]
								  ,CD.[CurrentStockQuantity] = TR.[CurrentStockQuantity]
								  ,CD.[CountedQuantity] = TR.[CountedQuantity]
								  ,CD.[DifferenceQuantity] = TR.[DifferenceQuantity]
								  ,CD.[DifferenceAmount] = TR.[DifferenceAmount]
								  ,CD.[UpdatedBy] = TR.[UpdatedBy]
								  ,CD.[UpdatedDate] = GETUTCDATE()
								  ,CD.[AdjustmentReasonId] = TR.[AdjustmentReasonId]
							 FROM [dbo].[CycleCountDetail] CD WITH(NOLOCK)
							 INNER JOIN #TempCycleCountDetail TR ON CD.[CycleCountDetailId] = TR.[CycleCountDetailId]
				           WHERE CD.[CycleCountDetailId] = @CycleCountDetailId;
						  
						  EXEC [dbo].[USP_CycleCountDetail_UpdateColumnsWithId] @CycleCountDetailId;
					END					
					SET @MinId = @MinId + 1;
				END
			  END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CycleCountDetail_AddUpdate' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''													   
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