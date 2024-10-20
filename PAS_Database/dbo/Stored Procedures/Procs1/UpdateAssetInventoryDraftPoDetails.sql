﻿/*************************************************************               
 ** File:   [UpdateAssetInventoryDraftPoDetails]               
 ** Author: Unknown    
 ** Description: This stored procedure isupdate asset inventory draft   
 ** Purpose:             
 ** Date:   Unknown
    
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------			--------------------------------              
    1    Unknown		Unknown				Created    
	2    11-04-2024   Abhishek Jirawla		In AssetInventoryDraft SET Assetlife and Asset Location, Calibration details, warranty details
           
**************************************************************/    
CREATE   PROCEDURE [dbo].[UpdateAssetInventoryDraftPoDetails]
@PurchaseOrderId  bigint
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		BEGIN TRANSACTION
		DECLARE @StockType int = 11;

	    --DECLARE @MSID as bigint
	    --DECLARE @Level1 as varchar(200)
	    --DECLARE @Level2 as varchar(200)
	    --DECLARE @Level3 as varchar(200)
	    --DECLARE @Level4 as varchar(200)
	    
	    --IF OBJECT_ID(N'tempdb..#AssetinventorypoDraftMSDATA') IS NOT NULL
	    --BEGIN
	    --DROP TABLE #AssetinventorypoDraftMSDATA 
	    --END
	    --CREATE TABLE #AssetinventorypoDraftMSDATA
	    --(
	    -- MSID bigint,
	    -- Level1 varchar(200) NULL,
	    -- Level2 varchar(200) NULL,
	    -- Level3 varchar(200) NULL,
	    -- Level4 varchar(200) NULL 
	    --)
	    
	    --IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	    --BEGIN
	    --DROP TABLE #MSDATA 
	    --END
	    --CREATE TABLE #MSDATA
	    --(
	    --	ID int IDENTITY, 
	    --	MSID bigint 
	    --)
	    --INSERT INTO #MSDATA (MSID) SELECT PO.ManagementStructureId FROM dbo.AssetInventoryDraft PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId
	    
	    
	    --DECLARE @LoopID AS int 
	    --SELECT  @LoopID = MAX(ID) FROM #MSDATA
	    --WHILE(@LoopID > 0)
	    --BEGIN
	    --SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID
	    
	    --EXEC dbo.GetMSNameandCode @MSID,
	    -- @Level1 = @Level1 OUTPUT,
	    -- @Level2 = @Level2 OUTPUT,
	    -- @Level3 = @Level3 OUTPUT,
	    -- @Level4 = @Level4 OUTPUT
	    
	    --INSERT INTO #AssetinventorypoDraftMSDATA (MSID, Level1,Level2,Level3,Level4) SELECT @MSID,@Level1,@Level2,@Level3,@Level4
	    --SET @LoopID = @LoopID - 1;
	    --END 
	    
	    UPDATE dbo.AssetInventoryDraft  SET ParentId = (SELECT TOP 1 S.AssetInventoryDraftId FROM dbo.AssetInventoryDraft S WITH (NOLOCK) WHERE 
	    	                                S.InventoryNumber = SDF.InventoryNumber AND (ISNULL(IsParent,0) = 1))
	    	  FROM dbo.AssetInventoryDraft SDF WITH (NOLOCK)  WHERE SDF.PurchaseOrderId = @PurchaseOrderId AND ISNULL(SDF.IsParent,0) = 0 AND ISNULL(SDF.IsParent,0) = 0;	     

		UPDATE SD SET	
			   SD.[AssetId] = POP.PartNumber	
	          ,SD.[AlternateAssetRecordId] = POP.AltEquiPartNumberId
			  ,SD.[Name] = AST.[Name]
			  ,SD.[Description] = AST.[Description]
			  ,SD.[CalibrationRequired] = ISNULL(ASTC.CalibrationRequired,0)
              ,SD.[CertificationRequired] = ISNULL(ASTC.CertificationRequired,0)
			  ,SD.[InspectionRequired] = ISNULL(ASTC.InspectionRequired,0)
			  ,SD.[VerificationRequired] = ISNULL(ASTC.VerificationRequired,0)
			  ,SD.[IsTangible] =ISNULL( AST.IsTangible,0)
              ,SD.[IsIntangible] =ISNULL( AST.IsIntangible  ,0)  
			  --,SD.[AssetAcquisitionTypeId] = AST.AssetAcquisitionTypeId
			  ,SD.[CurrencyId] = AST.CurrencyId
			  ,SD.[AssetParentRecordId] = AST.AssetParentRecordId
			  ,SD.[TangibleClassId] = AAT.TangibleClassId
              ,SD.[AssetIntangibleTypeId] = AST.AssetIntangibleTypeId
			  --,SD.[AssetCalibrationMin] = AST.AssetCalibrationMin                                       Neet To Discuss
			  --,SD.[AssetCalibrationMinTolerance] = AI.AssetCalibrationMinTolerance					  Neet To Discuss
              --,SD.[AssetCalibratonMax] = AI.AssetCalibratonMax										  Neet To Discuss
              --,SD.[AssetCalibrationMaxTolerance] = AI.AssetCalibrationMaxTolerance					  Neet To Discuss
              --,SD.[AssetCalibrationExpected] = AST.AssetCalibrationExpected							  Neet To Discuss
              --,SD.[AssetCalibrationExpectedTolerance] = AI.AssetCalibrationExpectedTolerance			  Neet To Discuss
              --,SD.[AssetCalibrationMemo] = AI.AssetCalibrationMemo									  Neet To Discuss
			  ,SD.[AssetIsMaintenanceReqd] = 0
			  ,SD.[AssetMaintenanceIsContract] = AST.AssetMaintenanceIsContract
			  ,SD.[AssetMaintenanceContractFile] = AST.AssetMaintenanceContractFile
			  ,SD.[MaintenanceFrequencyMonths] = 0
              --,SD.[MaintenanceFrequencyDays] = 0
              --,SD.[MaintenanceDefaultVendorId] = null
              --,SD.[MaintenanceGLAccountId] = null
			  --,SD.[MaintenanceMemo] = ''
			  ,SD.[IsWarrantyRequired] = 0
			  ,SD.[WarrantyCompany] = ASTM.WarrantyCompany
			  ,SD.[WarrantyDefaultVendorId] = ASTM.WarrantyDefaultVendorId
			  ,SD.[WarrantyGLAccountId] = ASTM.WarrantyGLAccountId
              --,SD.[WarrantyStartDate] = ASTM.WarrantyStartDate
              --,SD.[WarrantyEndDate] = ASTM.WarrantyEndDate
              --,SD.[WarrantyStatusId] = ASTM.WarrantyStatusId
              --,SD.[UnexpiredTime] = AI.UnexpiredTime      
			  ,SD.[Warranty] = 0
			  ,SD.[CalibrationDefaultVendorId] = ASTC.CalibrationDefaultVendorId
              ,SD.[CertificationDefaultVendorId] = ASTC.CertificationDefaultVendorId
              ,SD.[InspectionDefaultVendorId] = ASTC.InspectionDefaultVendorId
              ,SD.[VerificationDefaultVendorId] = ASTC.VerificationDefaultVendorId
			  ,SD.[CertificationFrequencyMonths] = ISNULL(ASTC.CertificationFrequencyMonths,0)
			  ,SD.[CertificationFrequencyDays] = ISNULL(ASTC.CertificationFrequencyDays,0)
			  ,SD.[InspectionFrequencyMonths] = ISNULL(ASTC.InspectionFrequencyMonths,0)
			  ,SD.[InspectionFrequencyDays] = ISNULL(ASTC.InspectionFrequencyDays,0)
			  ,SD.[VerificationFrequencyMonths] = ISNULL(ASTC.VerificationFrequencyMonths,0)
			  ,SD.[VerificationFrequencyDays] = ISNULL(ASTC.VerificationFrequencyDays,0)
			  ,SD.[CalibrationFrequencyMonths] = ISNULL(ASTC.CalibrationFrequencyMonths,0)
			  ,SD.[CalibrationFrequencyDays] = ISNULL(ASTC.CalibrationFrequencyDays,0)
			  ,SD.[CalibrationDefaultCost] = ISNULL(ASTC.CalibrationDefaultCost,0)
              ,SD.[CertificationDefaultCost] = ISNULL(ASTC.CertificationDefaultCost,0)
              ,SD.[InspectionDefaultCost] = ISNULL(ASTC.InspectionDefaultCost,0)
              ,SD.[VerificationDefaultCost] = ISNULL(ASTC.VerificationDefaultCost,0)
			  ,SD.[CalibrationCurrencyId] = ASTC.CalibrationCurrencyId
              ,SD.[CertificationCurrencyId] = ASTC.CertificationCurrencyId
              ,SD.[InspectionCurrencyId] = ASTC.InspectionCurrencyId
              ,SD.[VerificationCurrencyId] = ASTC.VerificationCurrencyId
			  ,SD.[CalibrationGlAccountId] = ASTC.CalibrationGlAccountId
              ,SD.[CertificationGlAccountId] = ASTC.CertificationGlAccountId
              ,SD.[InspectionGlaAccountId] = ASTC.InspectionGlaAccountId
              ,SD.[VerificationGlAccountId] = ASTC.VerificationGlAccountId
			  ,SD.[CalibrationMemo] = ISNULL(ASTC.CalibrationMemo, '')
              ,SD.[CertificationMemo] = ISNULL(ASTC.CertificationMemo, '')
              ,SD.[InspectionMemo] = ISNULL(ASTC.InspectionMemo, '')
              ,SD.[VerificationMemo] = ISNULL(ASTC.VerificationMemo, '')
			  ,SD.[IsDepreciable] =ISNULL(AST.IsDepreciable,0)
			  ,SD.[IsNonDepreciable] =ISNULL(AST.IsNonDepreciable,0)
			  ,SD.[IsAmortizable] = 0
			  ,SD.[IsNonAmortizable] = 0			  
              ,SD.[IsInsurance] = 0
              ,SD.[AssetLife] = ISNULL(AAT.AssetLife,0)
			  ,SD.[IsQtyReserved] = 0
			  --,SD.[InventoryStatusId] = AI.InventoryStatusId
              --,SD.[AssetStatusId] = AI.AssetStatusId
			  --,SD.[Level1] = PMS.Level1
     --         ,SD.[Level2] = PMS.Level2
     --         ,SD.[Level3] = PMS.Level3
     --         ,SD.[Level4] = PMS.Level4
			  ,SD.[ManufactureName] = MF.[NAME]
			  ,SD.[LocationName] = LC.[Name]      
			  ,SD.[PartNumber] = AST.ManufacturerPN
			  --,SD.[ControlNumber] = AI.ControlNumber
			  ,SD.ShippingVia = SV.[Name]
			  ,SD.GLAccount = (ISNULL(GLA.AccountCode,'')+'-'+ISNULL(GLA.AccountName,''))
			  ,SD.Warehouse = WH.[Name]
			  ,SD.[Location] = LC.[Name]
			  ,SD.ShelfName = SF.[Name]
			  ,SD.BinName = B.[Name]
			  ,SD.SiteName = S.[Name]	          
          FROM dbo.AssetInventoryDraft SD WITH (NOLOCK)
          INNER JOIN dbo.PurchaseOrderPart POP  WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId =  SD.PurchaseOrderPartRecordId and POP.ItemTypeId = @StockType
		  LEFT JOIN dbo.Asset AST  WITH (NOLOCK) ON AST.AssetRecordId = SD.AssetRecordId
		  LEFT JOIN dbo.AssetAttributeType AAT WITH (NOLOCK) ON AST.AssetAttributeTypeId = AAT.AssetAttributeTypeId
		  LEFT JOIN dbo.AssetCalibration ASTC  WITH (NOLOCK) ON AST.AssetRecordId = ASTC.AssetRecordId
		  LEFT JOIN dbo.AssetMaintenance ASTM  WITH (NOLOCK) ON AST.AssetRecordId = ASTM.AssetRecordId
          LEFT JOIN dbo.Manufacturer MF  WITH (NOLOCK) ON MF.ManufacturerId = SD.ManufacturerId
          LEFT JOIN dbo.Warehouse WH  WITH (NOLOCK) ON WH.WarehouseId = SD.WarehouseId
          LEFT JOIN dbo.[Location] LC  WITH (NOLOCK) ON LC.LocationId = SD.LocationId
          LEFT JOIN dbo.GLAccount GLA  WITH (NOLOCK) ON GLA.GLAccountId = SD.GLAccountId
          LEFT JOIN dbo.Shelf SF  WITH (NOLOCK) ON SF.ShelfId = SD.ShelfId
          LEFT JOIN dbo.Bin B  WITH (NOLOCK) ON B.BinId = SD.BinId
          LEFT JOIN dbo.[Site] S  WITH (NOLOCK) ON S.SiteId = SD.SiteId
          LEFT JOIN dbo.ShippingVia SV  WITH (NOLOCK) ON SV.ShippingViaId = SD.ShippingViaId
          WHERE SD.PurchaseOrderId = @PurchaseOrderId;	    
		
	    UPDATE dbo.PurchaseOrderPart  SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(Qty),0) FROM dbo.AssetInventory WITH (NOLOCK)
	    WHERE PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId AND isParent = 1)) FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)
	    WHERE POP.PurchaseOrderID = @PurchaseOrderId AND pop.ItemTypeId = @StockType; 
	    
	    --UPDATE dbo.PurchaseOrderPart SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(QuantityBackOrdered),0) FROM dbo.PurchaseOrderPart WITH (NOLOCK)
	    --where ParentId = POP.PurchaseOrderPartRecordId )) FROM dbo.PurchaseOrderPart POP  WITH (NOLOCK)
	    --where POP.PurchaseOrderID = @PurchaseOrderId AND POP.isParent = 1 AND POP.ItemTypeId = @StockType
	    --AND ISNULL((SELECT COUNT(PurchaseOrderPartRecordId)
	    --			from dbo.PurchaseOrderPart WITH (NOLOCK)
	    --			where ParentId = POP.PurchaseOrderPartRecordId),0) > 0;

		UPDATE dbo.PurchaseOrderPart SET  QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(QuantityOrdered) - SUM(QuantityBackOrdered),0) from dbo.PurchaseOrderPart WITH (NOLOCK)
	    where ParentId = POP.PurchaseOrderPartRecordId AND QuantityOrdered != QuantityBackOrdered)) FROM dbo.PurchaseOrderPart POP  WITH (NOLOCK)
	    where POP.PurchaseOrderID = @PurchaseOrderId AND POP.isParent = 1 AND POP.ItemTypeId = @StockType
	    AND ISNULL((SELECT COUNT(PurchaseOrderPartRecordId)
	    			from dbo.PurchaseOrderPart WITH (NOLOCK)
	    			where ParentId = POP.PurchaseOrderPartRecordId),0) > 0;
	    
	    SELECT PurchaseOrderNumber as value FROM dbo.PurchaseOrder PO WITH (NOLOCK) WHERE PurchaseOrderID = @PurchaseOrderId;

	   COMMIT TRANSACTION
    END TRY
    BEGIN CATCH  
	   IF @@trancount > 0	  
       ROLLBACK TRANSACTION;
	  -- IF OBJECT_ID(N'tempdb..#AssetinventorypoDraftMSDATA') IS NOT NULL
	  -- BEGIN
	  --  DROP TABLE #AssetinventorypoDraftMSDATA 
	  -- END
	  -- IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	  -- BEGIN
			--DROP TABLE #MSDATA 
	  -- END
	   -- temp table drop
	   DECLARE @ErrorLogID INT
	   ,@DatabaseName VARCHAR(100) = db_name()
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	   ,@AdhocComments VARCHAR(150) = 'UpdateStocklineDraftDetail'
	   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PurchaseOrderId, '') AS varchar(100))			  			                                           
	   ,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
	--IF OBJECT_ID(N'tempdb..#AssetinventorypoDraftMSDATA') IS NOT NULL
	--BEGIN
	--   DROP TABLE #AssetinventorypoDraftMSDATA 
	--END
	--IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	--BEGIN
	--	DROP TABLE #MSDATA 
	--END
END