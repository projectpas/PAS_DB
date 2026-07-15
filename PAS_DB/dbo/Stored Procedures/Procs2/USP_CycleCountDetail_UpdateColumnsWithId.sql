
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_CycleCountDetail_UpdateColumnsWithId   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_CycleCountDetail_UpdateColumnsWithId.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [USP_CycleCountDetail_UpdateColumnsWithId]           
 ** Author:   MOIN BLOCH
 ** Description: This stored procedure is used Update Cycle Count Stockline Details
 ** Purpose:         
 ** Date:   23/10/2024
          
 ** PARAMETERS:  @CycleCountDetailId INT          
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    23/10/2024   MOIN BLOCH    CREATED
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
-- EXEC [dbo].[USP_CycleCountDetail_UpdateColumnsWithId] 1
**************************************************************/

CREATE     PROCEDURE [dbo].[USP_CycleCountDetail_UpdateColumnsWithId]
@CycleCountDetailId INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
												
				UPDATE SL SET 
				    SL.[PartNumber] = IM.[partnumber],
					SL.[PartDescription] = IM.[PartDescription],
					SL.[ManufacturerName] = ISNULL(MF.[Name],''),
					SL.[ConditionName] = CN.[Description],
					SL.[UnitOfMeasureName] = ISNULL(UM.ShortName,''),
				    SL.[CurrencyName] = CR.[Code],
					SL.[Site] = ISNULL(S.[Name],''),
					SL.[Warehouse] = ISNULL(W.[Name],''),
					SL.[Location] = ISNULL(L.[Name],''),
					SL.[Shelf] = ISNULL(SF.[Name],''),
					SL.[Bin] = ISNULL(B.[Name],''),
					SL.[UnitCost] = CASE WHEN ISNULL(SL.[UnitCost],0) = 0 THEN 0 ELSE SL.[UnitCost] END
				FROM [dbo].[CycleCountDetail] SL WITH(NOLOCK)
					INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = SL.[ItemMasterId]
					INNER JOIN [dbo].[Condition] CN WITH(NOLOCK) ON CN.[ConditionId] = SL.[ConditionId]
					INNER JOIN [dbo].[Manufacturer] MF WITH(NOLOCK) ON MF.[ManufacturerId] = SL.[ManufacturerId]
					INNER JOIN [dbo].[Site] S WITH(NOLOCK) ON S.[SiteId] = SL.[SiteId]
					 LEFT JOIN [dbo].[Warehouse] W WITH(NOLOCK) ON W.[WarehouseId] = SL.[WarehouseId]
					 LEFT JOIN [dbo].[Location] L WITH(NOLOCK) ON L.[LocationId] = SL.[LocationId]
					 LEFT JOIN [dbo].[Shelf] SF WITH(NOLOCK) ON SF.[ShelfId] = SL.[ShelfId]
					 LEFT JOIN [dbo].[Bin] B WITH(NOLOCK) ON B.[BinId] = SL.[BinId]
					 LEFT JOIN [dbo].[UnitOfMeasure] UM WITH(NOLOCK) ON UM.[UnitOfMeasureId] = SL.[UnitOfMeasureId] 	
					 LEFT JOIN [dbo].[Currency] CR WITH(NOLOCK) ON  IM.[PurchaseCurrencyId] = CR.[CurrencyId]
			   WHERE SL.[CycleCountDetailId] = @CycleCountDetailId AND ISNULL(IM.IsNonStock,0) = 0 ;
							
			END		   
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CycleCountDetail_UpdateColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CycleCountDetailId, '') + ''
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