/*************************************************************           
 ** File:   [UpdateNonStocklineColumnsWithId]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Update Non Stockline Details based on Stockline Id.    
 ** Purpose:         
 ** Date:    02/04/2020       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/04/2020   Subhash Saliya Created

     
--  EXEC [UpdateNonStocklineColumnsWithId] 1
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateNonStocklineColumnsWithId]
	@NonStockInventoryId int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ManagmnetStructureId as bigInt	
	DECLARE @Level1 as varchar(200)
	DECLARE @Level2 as varchar(200)
	DECLARE @Level3 as varchar(200)
	DECLARE @Level4 as varchar(200)

	SELECT @ManagmnetStructureId = ManagementStructureId FROM [dbo].[NonStockInventory] WITH(NOLOCK) WHERE NonStockInventoryId = @NonStockInventoryId;

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				EXEC dbo.GetMSNameandCode @ManagmnetStructureId,
				 @Level1 = @Level1 OUTPUT,
				 @Level2 = @Level2 OUTPUT,
				 @Level3 = @Level3 OUTPUT,
				 @Level4 = @Level4 OUTPUT

				UPDATE SL SET 
					SL.Level1 = @Level1,
					SL.Level2 = @Level2,
					SL.Level3 = @Level3,
					SL.Level4 = @Level4,
					SL.Condition = CN.Description,
					SL.GLAccount = GL.AccountName,
					SL.UnitOfMeasure = um.ShortName,
					SL.Manufacturer = MF.Name,
					SL.Site = S.Name,
					SL.Warehouse = W.Name,
					SL.Location = L.Name,
					SL.Shelf = SF.Name,
					SL.Bin = B.Name,
					SL.Currency = cr.DisplayName,
					SL.PartDescription = IM.PartDescription,
					SL.PartNumber = IM.partnumber,
					SL.NonStockClassification=IC.Description,
					SL.VendorName = V.VendorName,
					SL.Requisitioner=E.FirstName
				
				FROM [dbo].[NonStockInventory] SL WITH(NOLOCK)
					INNER JOIN dbo.ItemMasterNonStock IM WITH(NOLOCK) ON IM.MasterPartId = SL.MasterPartId
					INNER JOIN dbo.Condition CN WITH(NOLOCK) ON CN.ConditionId = SL.ConditionId
					INNER JOIN dbo.Manufacturer MF WITH(NOLOCK) ON SL.ManufacturerId = MF.ManufacturerId
					INNER JOIN dbo.Site S WITH(NOLOCK) ON S.SiteId = SL.SiteId
					LEFT JOIN dbo.ItemType IT WITH(NOLOCK) ON IM.ItemTypeId = IT.ItemTypeId
					LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId = GL.GLAccountId 
					LEFT JOIN dbo.Warehouse W WITH(NOLOCK) ON W.WarehouseId = SL.WarehouseId
					LEFT JOIN dbo.Location L WITH(NOLOCK) ON L.LocationId = SL.LocationId
					LEFT JOIN dbo.Shelf SF WITH(NOLOCK) ON SF.ShelfId = SL.ShelfId
					LEFT JOIN dbo.Bin B WITH(NOLOCK) ON B.BinId = SL.BinId
					LEFT JOIN dbo.Vendor V WITH(NOLOCK) ON V.VendorId = SL.VendorId
					LEFT JOIN dbo.Employee E WITH(NOLOCK) ON E.EmployeeId = SL.RequisitionerId
					LEFT JOIN dbo.UnitOfMeasure um WITH(NOLOCK) ON SL.UnitOfMeasureId = um.UnitOfMeasureId 
					LEFT JOIN dbo.PurchaseOrder po WITH(NOLOCK) ON SL.PurchaseOrderId = po.PurchaseOrderId
					LEFT JOIN dbo.Currency cr WITH(NOLOCK) ON SL.CurrencyId = cr.CurrencyId
				    LEFT JOIN dbo.ItemClassification IC WITH(NOLOCK) ON SL.ItemNonStockClassificationId = IC.ItemClassificationId
				WHERE SL.NonStockInventoryId = @NonStockInventoryId

				UPDATE [dbo].[NonStockInventory] SET IsParent = 1 WHERE ISNULL(ParentId, 0) = 0 AND IsParent = 0
			
			END		   
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateStocklineColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@NonStockInventoryId, '') + ''
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