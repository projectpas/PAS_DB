/*************************************************************           
 ** File:   [UpdateStocklineColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Update Stockline Details based on Stockline Id.    
 ** Purpose:         
 ** Date:   04/21/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/30/2020   Hemant Saliya Created
	2    07/10/2021   Hemant Saliya Added SQL Content Managment
	3    11/16/2021   Vishal Suthar Added IsDeleted in the condition
     
--  EXEC [UpdateStocklineColumnsWithId] 917
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateStocklineColumnsWithId]
	@StocklineId int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ManagmnetStructureId as bigInt	
	DECLARE @Level1 as varchar(200)
	DECLARE @Level2 as varchar(200)
	DECLARE @Level3 as varchar(200)
	DECLARE @Level4 as varchar(200)

	SELECT @ManagmnetStructureId = ManagementStructureId FROM [dbo].[Stockline] WITH(NOLOCK) WHERE StockLineId = @StocklineId;

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
					SL.GlAccountName = GL.AccountName,
					SL.UnitOfMeasure = um.ShortName,
					SL.Manufacturer = MF.Name,
					SL.Site = S.Name,
					SL.Warehouse = W.Name,
					SL.Location = L.Name,
					SL.Shelf = SF.Name,
					SL.Bin = B.Name,
					SL.WorkOrderNumber = WO.WorkOrderNum,
					SL.itemGroup = IG.Description,
					SL.TLAPartNumber = IMTLA.partnumber,
					SL.NHAPartNumber = IMNHA.partnumber,
					SL.TLAPartDescription = IMTLA.PartDescription,
					SL.NHAPartDescription = IMNHA.PartDescription,
					SL.itemType = IT.Name,
					SL.PNDescription = IM.PartDescription,
					SL.PartNumber = IM.partnumber,
					SL.RevicedPNNumber = IMRI.partnumber,
					SL.OEMPNNumber = IMoem.partnumber,
					SL.TaggedByTypeName =  (SELECT ModuleName FROM dbo.Module WITH(NOLOCK) WHERE Moduleid = SL.TaggedByType),				
					SL.CertifiedType =  (SELECT ModuleName FROM dbo.Module WITH(NOLOCK) WHERE Moduleid = SL.CertifiedTypeId),
					SL.TagType = tagT.[Name]
				FROM [dbo].[Stockline] SL WITH(NOLOCK)
					INNER JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
					INNER JOIN dbo.Condition CN WITH(NOLOCK) ON CN.ConditionId = SL.ConditionId
					INNER JOIN dbo.Manufacturer MF WITH(NOLOCK) ON SL.ManufacturerId = MF.ManufacturerId
					INNER JOIN dbo.Site S WITH(NOLOCK) ON S.SiteId = SL.SiteId
					LEFT JOIN dbo.ItemMaster IMRI WITH(NOLOCK) ON IMRI.ItemMasterId = SL.RevicedPNId
					LEFT JOIN dbo.ItemMaster IMoem WITH(NOLOCK) ON IMoem.ItemMasterId = SL.IsOemPNId
					LEFT JOIN dbo.ItemMaster IMTLA WITH(NOLOCK) ON IMTLA.ItemMasterId = SL.TLAItemMasterId
					LEFT JOIN dbo.ItemMaster IMNHA WITH(NOLOCK) ON IMNHA.ItemMasterId = SL.NHAItemMasterId
					LEFT JOIN dbo.Itemgroup IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemgroupId
					LEFT JOIN dbo.ItemType IT WITH(NOLOCK) ON IM.ItemTypeId = IT.ItemTypeId
					LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId = GL.GLAccountId 
					LEFT JOIN dbo.WorkOrder WO WITH(NOLOCK) ON SL.WorkOrderId = WO.WorkOrderId 
					LEFT JOIN dbo.Warehouse W WITH(NOLOCK) ON W.WarehouseId = SL.WarehouseId
					LEFT JOIN dbo.Location L WITH(NOLOCK) ON L.LocationId = SL.LocationId
					LEFT JOIN dbo.Shelf SF WITH(NOLOCK) ON SF.ShelfId = SL.ShelfId
					LEFT JOIN dbo.Bin B WITH(NOLOCK) ON B.BinId = SL.BinId
					LEFT JOIN dbo.UnitOfMeasure um WITH(NOLOCK) ON SL.PurchaseUnitOfMeasureId = um.UnitOfMeasureId 
					LEFT JOIN dbo.PurchaseOrder po WITH(NOLOCK) ON SL.PurchaseOrderId = po.PurchaseOrderId
					LEFT JOIN dbo.RepairOrder ro WITH(NOLOCK) ON SL.RepairOrderId = ro.RepairOrderId
					LEFT JOIN dbo.TagType tagT WITH(NOLOCK) ON SL.TagTypeId = tagT.TagTypeId
				WHERE SL.StocklineId = @StocklineId

				UPDATE [dbo].[Stockline] 
					SET LegalEntityId = MS.LegalEntityId
				FROM dbo.Stockline STL WITH(NOLOCK) 
					JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON STL.ManagementStructureId=MS.ManagementStructureId
				WHERE STL.StocklineId = @StocklineId AND STL.LegalEntityId IS NULL AND IsParent = 1

				UPDATE [dbo].[Stockline] SET IsParent = 1 WHERE ISNULL(ParentId, 0) = 0 AND IsParent = 0
			
				UPDATE [dbo].[Stockline] 
					SET NHAItemMasterId = (SELECT TOP 1 NHA.MappingItemMasterId FROM dbo.Nha_Tla_Alt_Equ_ItemMapping NHA WITH(NOLOCK)
											WHERE NHA.ItemMasterId = SD.ItemMasterId AND NHA.MappingType = 3 AND NHA.IsDeleted = 0)
				FROM [dbo].[Stockline]  SD
				WHERE SD.StockLineId = @StocklineId AND ISNULL(SD.NHAItemMasterId,0) = 0 AND IsParent = 1

				UPDATE [dbo].[Stockline] 
					SET TLAItemMasterId = (SELECT TOP 1 NHA.MappingItemMasterId FROM dbo.Nha_Tla_Alt_Equ_ItemMapping NHA WITH(NOLOCK)
											WHERE NHA.ItemMasterId = SD.ItemMasterId AND NHA.MappingType = 4 AND NHA.IsDeleted = 0)
				FROM [dbo].[Stockline]  SD
				WHERE SD.StockLineId = @StocklineId AND ISNULL(SD.TLAItemMasterId,0) = 0 AND IsParent = 1
				
				UPDATE [dbo].[Stockline] 
					SET DaysReceived = IM.DaysReceived
				FROM dbo.Stockline STL WITH(NOLOCK) 
					JOIN dbo.ItemMaster IM WITH(NOLOCK) ON STL.ItemMasterId=IM.ItemMasterId
				WHERE STL.StocklineId = @StocklineId AND IM.DaysReceived > 0 AND STL.DaysReceived IS NULL AND IsParent = 1

				UPDATE [dbo].[Stockline] 
					SET ManufacturingDays = IM.ManufacturingDays
				FROM dbo.Stockline STL WITH(NOLOCK) 
					JOIN dbo.ItemMaster IM WITH(NOLOCK) ON STL.ItemMasterId=IM.ItemMasterId
				WHERE STL.StocklineId = @StocklineId AND IM.ManufacturingDays > 0 AND STL.ManufacturingDays IS NULL AND IsParent = 1

				UPDATE [dbo].[Stockline] 
					SET TagDays = IM.TagDays
				FROM dbo.Stockline STL WITH(NOLOCK) 
					JOIN dbo.ItemMaster IM WITH(NOLOCK) ON STL.ItemMasterId=IM.ItemMasterId
				WHERE STL.StocklineId = @StocklineId AND IM.TagDays > 0 AND STL.TagDays IS NULL AND IsParent = 1

				UPDATE [dbo].[Stockline] 
					SET OpenDays = IM.OpenDays
				FROM dbo.Stockline STL WITH(NOLOCK) 
					JOIN dbo.ItemMaster IM WITH(NOLOCK) ON STL.ItemMasterId=IM.ItemMasterId
				WHERE STL.StocklineId = @StocklineId AND IM.OpenDays > 0 AND STL.OpenDays IS NULL AND IsParent = 1

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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StocklineId, '') + ''
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