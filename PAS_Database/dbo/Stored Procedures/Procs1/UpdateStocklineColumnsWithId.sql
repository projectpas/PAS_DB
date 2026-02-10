
/*************************************************************           
 ** File:   [UpdateStocklineColumnsWithId]           
 ** Author:   MOIN BLOCH
 ** Description: This stored procedure is used Update Stockline Details
 ** Purpose:         
 ** Date:   06/06/2023      
          
 ** PARAMETERS:  @StocklineId INT          
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/06/2023   MOIN BLOCH    UPDATED
	2    06/06/2023   MOIN BLOCH    Added @IsCustStock For Update IsCustomerStock Or Not
	3    07/14/2023   Amit Ghediya  Update UnitCost set 0 if NULL
	4    04/25/2024   Devendra Shekh  Updatting GLAccountName issue resolved
	5    20/09/2024   MOIN BLOCH      UPDATED for nullable to blanck
    6    24/12/2024   BHAVESH RAVAL   For the UpdateGLAccount Details in Stockline Table 
	7    09/01/2025   BHAVESH RAVAL   For the add new column in COGS_ExchSalesOrderGLAcc 
	8    11/02/2025   Bhargav Saliya  Update GL Account
	9    16/05/2025   Devendra Shekh  Updatting RepairOrderNumber, PurchaseOrderNumber, IsDocument
	10   11/12/2025   Rajesh Gami	  UPDATE: StockUnitOfMeasure,ConsumeUnitOfMeasure
	11   09/02/2026   Sahdev Saliya   UPDATED: ItemGroup

-- EXEC [dbo].[UpdateStocklineColumnsWithId] 1
**************************************************************/

CREATE   PROCEDURE [dbo].[UpdateStocklineColumnsWithId]
@StocklineId INT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @MSModuleID INT;
				SET @MSModuleID = 2; -- FOR STOCKLINE
				DECLARE @AttachmentModuleId INT = 0;
				SELECT @AttachmentModuleId = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'StockLine';

				DECLARE @CustomerAffiliationId INT;
				DECLARE @IsCustStock BIT;

				SELECT @CustomerAffiliationId = CU.[CustomerAffiliationId]
				  FROM [dbo].[Stockline] SL WITH(NOLOCK) 
				INNER JOIN [dbo].[Customer] CU WITH(NOLOCK) ON SL.CustomerId = CU.CustomerId	
				WHERE SL.StocklineId = @StocklineId;

				IF(@CustomerAffiliationId = 2)  -- 2 For External Customer
				BEGIN
					SET @IsCustStock = 1;
				END
				ELSE
				BEGIN
					SET @IsCustStock = 0;
				END
								
				UPDATE SL SET 
					SL.Condition = CN.[Description],
					--SL.GlAccountName = CASE WHEN ISNULL(GL.AccountName, '') != '' THEN GL.AccountCode + ' - ' + GL.AccountName ELSE SL.glAccountname END,
					SL.UnitOfMeasure = ISNULL(um.ShortName,''),
					SL.StockUnitOfMeasure = ISNULL(umStock.ShortName,''),
					SL.ConsumeUnitOfMeasure = ISNULL(umConsume.ShortName,''),
					SL.Manufacturer = ISNULL(MF.[Name],''),
					SL.Site = ISNULL(S.[Name],''),
					SL.Warehouse = ISNULL(W.[Name],''),
					SL.Location = ISNULL(L.[Name],''),
					SL.Shelf = ISNULL(SF.[Name],''),
					SL.Bin = ISNULL(B.[Name],''),
					SL.WorkOrderNumber = ISNULL(WO.WorkOrderNum,''),
					SL.SubWorkOrderNumber = ISNULL(SWO.SubWorkOrderNo,''),
					SL.itemGroup = ISNULL(IG.[ItemGroupCode],''),
					SL.TLAPartNumber = ISNULL(IMTLA.partnumber,''),
					SL.NHAPartNumber = ISNULL(IMNHA.partnumber,''),
					SL.TLAPartDescription = ISNULL(IMTLA.PartDescription,''),
					SL.NHAPartDescription = ISNULL(CAST(IMNHA.PartDescription AS NVARCHAR(100)),''),
					SL.itemType = ISNULL(IT.[Name],''),
					SL.PNDescription = ISNULL(IM.PartDescription,''),
					SL.PartNumber = ISNULL(IM.partnumber,''),
					SL.RevicedPNNumber = ISNULL(IMRI.partnumber,''),
					SL.OEMPNNumber = ISNULL(IMoem.partnumber,''),
					SL.TaggedByTypeName =  ISNULL((SELECT ModuleName FROM dbo.Module WITH(NOLOCK) WHERE Moduleid = SL.TaggedByType),''),			
					SL.CertifiedType =  ISNULL((SELECT ModuleName FROM dbo.Module WITH(NOLOCK) WHERE Moduleid = SL.CertifiedTypeId),''),
					SL.TagType = ISNULL(tagT.[Name],''),
					SL.LotNumber = CASE WHEN ISNULL(SL.LotNumber,'') = '' THEN lot.LotNumber ELSE SL.LotNumber END,
					SL.LotId = CASE WHEN ISNULL(SL.LotId,0) = 0 AND ISNULL(SL.LotNumber,'') != '' THEN (SELECT Top 1 LotId FROM dbo.LOT lot WITH(NOLOCK) WHERE lot.LotNumber =SL.LotNumber) ELSE SL.LotId END,
					SL.IsLotAssigned = CASE WHEN ISNULL(SL.LotId,0) = 0 AND ISNULL(SL.LotNumber,'') != '' AND (SELECT Top 1 LotId FROM dbo.LOT lot WITH(NOLOCK) WHERE lot.LotNumber =SL.LotNumber) > 0 THEN 1 ELSE 0 END,
					SL.IsCustomerStock = @IsCustStock,
					SL.UnitCost = CASE WHEN ISNULL(SL.UnitCost,0) = 0 THEN 0 ELSE SL.UnitCost END,
					SL.RepairOrderNumber = ro.RepairOrderNumber,
					SL.PurchaseOrderNumber = po.PurchaseOrderNumber,
					SL.IsDocument = CASE WHEN ISNULL((SELECT COUNT(CommonDocumentDetailId) FROM [DBO].[CommonDocumentDetails] CDD WITH(NOLOCK) WHERE SL.StockLineId = CDD.ReferenceId AND CDD.ModuleId = @AttachmentModuleId AND ISNULL(CDD.IsDeleted, 0) = 0), 0) > 0 THEN 1 ELSE 0 END
				FROM [dbo].[Stockline] SL WITH(NOLOCK)
					INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
					INNER JOIN [dbo].[Condition] CN WITH(NOLOCK) ON CN.ConditionId = SL.ConditionId
					INNER JOIN [dbo].[Manufacturer] MF WITH(NOLOCK) ON SL.ManufacturerId = MF.ManufacturerId
					INNER JOIN [dbo].[Site] S WITH(NOLOCK) ON S.SiteId = SL.SiteId
					 LEFT JOIN [dbo].[ItemMaster] IMRI WITH(NOLOCK) ON IMRI.ItemMasterId = SL.RevicedPNId
					 LEFT JOIN [dbo].[ItemMaster] IMoem WITH(NOLOCK) ON IMoem.ItemMasterId = SL.IsOemPNId
					 LEFT JOIN [dbo].[ItemMaster] IMTLA WITH(NOLOCK) ON IMTLA.ItemMasterId = SL.TLAItemMasterId
					 LEFT JOIN [dbo].[ItemMaster] IMNHA WITH(NOLOCK) ON IMNHA.ItemMasterId = SL.NHAItemMasterId
					 LEFT JOIN [dbo].[Itemgroup] IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemgroupId
					 LEFT JOIN [dbo].[ItemType] IT WITH(NOLOCK) ON IM.ItemTypeId = IT.ItemTypeId
					 LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON SL.GLAccountId = GL.GLAccountId 
					 LEFT JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON SL.WorkOrderId = WO.WorkOrderId 
					 LEFT JOIN [dbo].[Warehouse] W WITH(NOLOCK) ON W.WarehouseId = SL.WarehouseId
					 LEFT JOIN [dbo].[Location] L WITH(NOLOCK) ON L.LocationId = SL.LocationId
					 LEFT JOIN [dbo].[Shelf] SF WITH(NOLOCK) ON SF.ShelfId = SL.ShelfId
					 LEFT JOIN [dbo].[Bin] B WITH(NOLOCK) ON B.BinId = SL.BinId
					 LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON SL.PurchaseUnitOfMeasureId = um.UnitOfMeasureId 
					 LEFT JOIN [dbo].[UnitOfMeasure] umStock WITH(NOLOCK) ON SL.StockUnitOfMeasureId = umStock.UnitOfMeasureId 
					 LEFT JOIN [dbo].[UnitOfMeasure] umConsume WITH(NOLOCK) ON SL.ConsumeUnitOfMeasureId = umConsume.UnitOfMeasureId 
					 LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON SL.PurchaseOrderId = po.PurchaseOrderId
					 LEFT JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON SL.RepairOrderId = ro.RepairOrderId
					 LEFT JOIN [dbo].[TagType] tagT WITH(NOLOCK) ON SL.TagTypeId = tagT.TagTypeId
					 LEFT JOIN [dbo].[SubWorkOrder] SWO WITH(NOLOCK) ON SL.SubWorkOrderId = SWO.SubWorkOrderId 
					 LEFT JOIN [dbo].[LOT] lot WITH(NOLOCK) ON SL.LotId = lot.LotId
			  WHERE SL.StocklineId = @StocklineId
				
				UPDATE [dbo].[Stockline] 
					SET LegalEntityId = MSL.LegalEntityId
				FROM dbo.Stockline STL WITH(NOLOCK) 
					JOIN dbo.StocklineManagementStructureDetails SMD WITH(NOLOCK) ON STL.StockLineId = SMD.ReferenceID AND SMD.ModuleID = @MSModuleID
					JOIN dbo.ManagementStructureLevel MSL WITH(NOLOCK) ON MSL.ID = SMD.Level1Id
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

					-- update glaccount details by bhavesh raval
				DECLARE @ItemMasterId INT;
				DECLARE @InventoryGLSettingId INT;
				DECLARE @IMInventoryGLSettingId INT;
				SELECT TOP 1 @InventoryGLSettingId=InventoryGLSettingId FROM dbo.Stockline SL WITH (NOLOCK)  where SL.StockLineId=@StocklineId
				
				IF ISNULL(@InventoryGLSettingId,0)=0
				BEGIN
				
					UPDATE SL
					SET
					SL.InventoryGLSettingId=I.InventoryGLSettingId,
					 SL.GLAccountId=IM.GLAccountId,
					 SL.GlAccountName = GA.AccountCode+'-'+ GA.AccountName,
					 SL.InventoryGLAccName = GA.AccountCode+'-'+ GA.AccountName, 
					SL.GoodsReceivedNotInvoicesGLAccId = I.GoodsReceivedNotInvoicesGLAccId,
					SL.GoodsReceivedNotInvoicesGLAccName = GL2.AccountCode + '-' + GL2.AccountName,
					SL.WorkInProgressGLAccId = I.WorkInProgressGLAccId,
					SL.WorkInProgressGLAccName = GL3.AccountCode + '-' + GL3.AccountName,
					SL.InventoryToBillGLAccId = I.InventoryToBillGLAccId,
					SL.InventoryToBillGLAccName = GL4.AccountCode + '-' + GL4.AccountName,
					SL.FinishedGoodsGLAccId = I.FinishedGoodsGLAccId,
					SL.FinishedGoodsGLAccName = GL5.AccountCode + '-' + GL5.AccountName, 
					SL.InventoryExchAgreementGLAccId = I.InventoryExchAgreementGLAccId,
					SL.InventoryExchAgreementGLAccName = GL6.AccountCode + '-' + GL6.AccountName,
					SL.InventoryReserveGLAccId = I.InventoryReserveGLAccId,
					SL.InventoryReserveGLAccName = GL7.AccountCode + '-' + GL7.AccountName, 
					SL.COGS_WorkOrderGLAccId = I.COGS_WorkOrderGLAccId,
					SL.COGS_WorkOrderGLAccName = GL8.AccountCode + '-' + GL8.AccountName, 
					SL.COGS_SalesOrderGLAccId = I.COGS_SalesOrderGLAccId,
					SL.COGS_SalesOrderGLAccName = GL9.AccountCode + '-' + GL9.AccountName, 
					SL.COGS_QtyVarianceGLAccId = I.COGS_QtyVarianceGLAccId,
					SL.COGS_QtyVarianceGLAccName = GL10.AccountCode + '-' + GL10.AccountName, 
					SL.COGS_UnitCostVarianceGLAccId = I.COGS_UnitCostVarianceGLAccId,
					SL.COGS_UnitCostVarianceGLAccName = GL11.AccountCode + '-' + GL11.AccountName,
					SL.RevenueMroGLAccId = I.RevenueMroGLAccId,
					SL.RevenueMroGLAccName = GL12.AccountCode + '-' + GL12.AccountName,
					SL.RevenueSoGLAccId = I.RevenueSoGLAccId,
					SL.RevenueSoGLAccName = GL13.AccountCode + '-' + GL13.AccountName,
					SL.RevenueExchGLAccId = I.RevenueExchGLAccId,
					SL.RevenueExchGLAccName = GL14.AccountCode + '-' + GL14.AccountName,
					SL.COGS_ExchSalesOrderGLAccId = I.COGS_ExchSalesOrderGLAccId,
					SL.COGS_ExchSalesOrderGLAccName = GL15.AccountCode + '-' + GL15.AccountName
					FROM
					dbo.ItemMaster IM WITH (NOLOCK) 
					JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.ItemMasterId=IM.ItemMasterId
					JOIN dbo.GLAccount GA WITH (NOLOCK) ON  GA.GLAccountId=IM.GLAccountId
					LEFT JOIN
					InventoryGLSetting I WITH (NOLOCK) ON IM.InventoryGLSettingId = I.InventoryGLSettingId
					LEFT JOIN
					GLAccount GL1 WITH (NOLOCK) ON I.InventoryGLAccId = GL1.GLAccountId
					LEFT JOIN
					GLAccount GL2 WITH (NOLOCK) ON I.GoodsReceivedNotInvoicesGLAccId = GL2.GLAccountId
					LEFT JOIN
					GLAccount GL3 WITH (NOLOCK) ON I.WorkInProgressGLAccId = GL3.GLAccountId
					LEFT JOIN
					GLAccount GL4 WITH (NOLOCK) ON I.InventoryToBillGLAccId = GL4.GLAccountId
					LEFT JOIN
					GLAccount GL5 WITH (NOLOCK) ON I.FinishedGoodsGLAccId = GL5.GLAccountId
					LEFT JOIN
					GLAccount GL6 WITH (NOLOCK) ON I.InventoryExchAgreementGLAccId = GL6.GLAccountId
					LEFT JOIN
					GLAccount GL7 WITH (NOLOCK) ON I.InventoryReserveGLAccId = GL7.GLAccountId
					LEFT JOIN
					GLAccount GL8 WITH (NOLOCK) ON I.COGS_WorkOrderGLAccId = GL8.GLAccountId
					LEFT JOIN
					GLAccount GL9 WITH (NOLOCK) ON I.COGS_SalesOrderGLAccId = GL9.GLAccountId
					LEFT JOIN
					GLAccount GL10 WITH (NOLOCK) ON I.COGS_QtyVarianceGLAccId = GL10.GLAccountId
					LEFT JOIN
					GLAccount GL11 WITH (NOLOCK) ON I.COGS_UnitCostVarianceGLAccId = GL11.GLAccountId
					LEFT JOIN
					GLAccount GL12 WITH (NOLOCK) ON I.RevenueMroGLAccId = GL12.GLAccountId
					LEFT JOIN
					GLAccount GL13 WITH (NOLOCK) ON I.RevenueSoGLAccId = GL13.GLAccountId
					LEFT JOIN
					GLAccount GL14 WITH (NOLOCK) ON I.RevenueExchGLAccId = GL14.GLAccountId
					LEFT JOIN
					GLAccount GL15 WITH (NOLOCK) ON I.COGS_ExchSalesOrderGLAccId = GL15.GLAccountId
					WHERE SL.StockLineId=@StocklineId
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