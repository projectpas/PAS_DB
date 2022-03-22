--- exec UpdateAssetInventoryDraftRoDetails  139
CREATE  PROCEDURE [dbo].[UpdateAssetInventoryDraftRoDetails]
@RepairOrderId  bigint
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	

BEGIN TRY
BEGIN TRANSACTION

DECLARE @MSID as bigint
DECLARE @Level1 as varchar(200)
DECLARE @Level2 as varchar(200)
DECLARE @Level3 as varchar(200)
DECLARE @Level4 as varchar(200)

IF OBJECT_ID(N'tempdb..#AssetInventoryDraftMSDATA') IS NOT NULL
BEGIN
DROP TABLE #AssetInventoryDraftMSDATA 
END
CREATE TABLE #AssetInventoryDraftMSDATA
(
 MSID bigint,
 Level1 varchar(200) NULL,
 Level2 varchar(200) NULL,
 Level3 varchar(200) NULL,
 Level4 varchar(200) NULL 
)

IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
BEGIN
DROP TABLE #MSDATA 
END
CREATE TABLE #MSDATA
(
	ID int IDENTITY, 
	MSID bigint 
)
INSERT INTO #MSDATA (MSID)
  SELECT RO.ManagementStructureId FROM dbo.AssetInventoryDraft RO Where RO.RepairOrderId = @RepairOrderId


DECLARE @LoopID as int 
SELECT  @LoopID = MAX(ID) FROM #MSDATA
WHILE(@LoopID > 0)
BEGIN
SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID

EXEC dbo.GetMSNameandCode @MSID,
 @Level1 = @Level1 OUTPUT,
 @Level2 = @Level2 OUTPUT,
 @Level3 = @Level3 OUTPUT,
 @Level4 = @Level4 OUTPUT

INSERT INTO #AssetInventoryDraftMSDATA (MSID, Level1,Level2,Level3,Level4)
                              SELECT @MSID,@Level1,@Level2,@Level3,@Level4
SET @LoopID = @LoopID - 1;
END

UPDATE dbo.AssetInventoryDraft SET ParentId =  (SELECT TOP 1 S.AssetInventoryDraftId FROM dbo.AssetInventoryDraft S WHERE 
	                                      S.InventoryNumber = SDF.InventoryNumber 
								          AND (ISNULL(IsParent,0) = 1))
	  FROM dbo.AssetInventoryDraft SDF WHERE SDF.RepairOrderId = @RepairOrderId AND ISNULL(SDF.IsParent,0) = 0 AND ISNULL(SDF.IsParent,0) = 0

UPDATE SD SET	
	   SD.[AlternateAssetRecordId] = AI.AlternateAssetRecordId
      ,SD.[Description] = AI.Description
      ,SD.[IsTangible] =ISNULL( AI.IsTangible,0)
      ,SD.[IsIntangible] =ISNULL( AI.IsIntangible  ,0)  
      ,SD.[Model] = AI.Model
      ,SD.[Memo] = AI.Memo
      ,SD.[AssetParentRecordId] = AI.AssetParentRecordId
      ,SD.[TangibleClassId] = AI.TangibleClassId
      ,SD.[AssetIntangibleTypeId] = AI.AssetIntangibleTypeId
      ,SD.[AssetCalibrationMin] = AI.AssetCalibrationMin
      ,SD.[AssetCalibrationMinTolerance] = AI.AssetCalibrationMinTolerance
      ,SD.[AssetCalibratonMax] = AI.AssetCalibratonMax
      ,SD.[AssetCalibrationMaxTolerance] = AI.AssetCalibrationMaxTolerance
      ,SD.[AssetCalibrationExpected] = AI.AssetCalibrationExpected
      ,SD.[AssetCalibrationExpectedTolerance] = AI.AssetCalibrationExpectedTolerance
      ,SD.[AssetCalibrationMemo] = AI.AssetCalibrationMemo
      ,SD.[AssetIsMaintenanceReqd] = AI.AssetIsMaintenanceReqd
      ,SD.[AssetMaintenanceIsContract] = AI.AssetMaintenanceIsContract
      ,SD.[AssetMaintenanceContractFile] = AI.AssetMaintenanceContractFile
      ,SD.[MaintenanceFrequencyMonths] = AI.MaintenanceFrequencyMonths
      ,SD.[MaintenanceFrequencyDays] = AI.MaintenanceFrequencyDays
      ,SD.[MaintenanceDefaultVendorId] = AI.MaintenanceDefaultVendorId
      ,SD.[MaintenanceGLAccountId] = AI.MaintenanceGLAccountId
      ,SD.[MaintenanceMemo] = AI.MaintenanceMemo
      ,SD.[IsWarrantyRequired] = AI.IsWarrantyRequired
      ,SD.[WarrantyCompany] = AI.WarrantyCompany
      ,SD.[WarrantyStartDate] = AI.WarrantyStartDate
      ,SD.[WarrantyEndDate] = AI.WarrantyEndDate
      ,SD.[WarrantyStatusId] = AI.WarrantyStatusId
      ,SD.[UnexpiredTime] = AI.UnexpiredTime    
      ,SD.[AssetLocationId] = AI.AssetLocationId
      ,SD.[Warranty] = AI.Warranty
      ,SD.[CalibrationDefaultVendorId] = AI.CalibrationDefaultVendorId
      ,SD.[CertificationDefaultVendorId] = AI.CertificationDefaultVendorId
      ,SD.[InspectionDefaultVendorId] = AI.InspectionDefaultVendorId
      ,SD.[VerificationDefaultVendorId] = AI.VerificationDefaultVendorId
      ,SD.[CertificationFrequencyMonths] = AI.CertificationFrequencyMonths
      ,SD.[CertificationFrequencyDays] = AI.CertificationFrequencyDays
      ,SD.[CertificationDefaultCost] = AI.CertificationDefaultCost
      ,SD.[CertificationGlAccountId] = AI.CertificationGlAccountId
      ,SD.[CertificationMemo] = AI.CertificationMemo
      ,SD.[InspectionMemo] = AI.InspectionMemo
      ,SD.[InspectionGlaAccountId] = AI.InspectionGlaAccountId
      ,SD.[InspectionDefaultCost] = AI.InspectionDefaultCost
      ,SD.[InspectionFrequencyMonths] = AI.InspectionFrequencyMonths
      ,SD.[InspectionFrequencyDays] = AI.InspectionFrequencyDays
      ,SD.[VerificationFrequencyDays] = AI.VerificationFrequencyDays
      ,SD.[VerificationFrequencyMonths] = AI.VerificationFrequencyMonths
      ,SD.[VerificationDefaultCost] = AI.VerificationDefaultCost
      ,SD.[CalibrationDefaultCost] = AI.CalibrationDefaultCost
      ,SD.[CalibrationFrequencyMonths] = AI.CalibrationFrequencyMonths
      ,SD.[CalibrationFrequencyDays] = AI.CalibrationFrequencyDays
      ,SD.[CalibrationGlAccountId] = AI.CalibrationGlAccountId
      ,SD.[CalibrationMemo] = AI.CalibrationMemo
      ,SD.[VerificationMemo] = AI.VerificationMemo
      ,SD.[VerificationGlAccountId] = AI.VerificationGlAccountId
      ,SD.[CalibrationCurrencyId] = AI.CalibrationCurrencyId
      ,SD.[CertificationCurrencyId] = AI.CertificationCurrencyId
      ,SD.[InspectionCurrencyId] = AI.InspectionCurrencyId
      ,SD.[VerificationCurrencyId] = AI.VerificationCurrencyId    
      ,SD.[AssetMaintenanceContractFileExt] = AI.AssetMaintenanceContractFileExt
      ,SD.[WarrantyFile] = AI.WarrantyFile
      ,SD.[WarrantyFileExt] = AI.WarrantyFileExt
      ,SD.[EntryDate] = AI.EntryDate
      ,SD.[InstallationCost] = AI.InstallationCost
      ,SD.[Freight] = AI.Freight
      ,SD.[Insurance] = AI.Insurance
      ,SD.[Taxes] = AI.Taxes
      ,SD.[TotalCost] = AI.TotalCost
      ,SD.[WarrantyDefaultVendorId] = AI.WarrantyDefaultVendorId
      ,SD.[WarrantyGLAccountId] = AI.WarrantyGLAccountId
      ,SD.[IsDepreciable] = AI.IsDepreciable
      ,SD.[IsNonDepreciable] = AI.IsNonDepreciable
      ,SD.[IsAmortizable] = AI.IsAmortizable
      ,SD.[IsNonAmortizable] = AI.IsNonAmortizable
      ,SD.[IsInsurance] = AI.IsInsurance
      ,SD.[AssetLife] = AI.AssetLife
      ,SD.[WarrantyCompanyId] = AI.WarrantyCompanyId
      ,SD.[WarrantyCompanyName] = AI.WarrantyCompanyName
      ,SD.[WarrantyCompanySelectId] = AI.WarrantyCompanySelectId
      ,SD.[WarrantyMemo] = AI.WarrantyMemo
      ,SD.[IsQtyReserved] = AI.IsQtyReserved
      ,SD.[InventoryStatusId] = AI.InventoryStatusId
      ,SD.[AssetStatusId] = AI.AssetStatusId
      ,SD.[Level1] = PMS.Level1
      ,SD.[Level2] = PMS.Level2
      ,SD.[Level3] = PMS.Level3
      ,SD.[Level4] = PMS.Level4
      ,SD.[ManufactureName] = MF.[NAME]
      ,SD.[LocationName] = LC.[Name]
      ,SD.[PartNumber] = AI.PartNumber
      ,SD.[ControlNumber] = AI.ControlNumber,
	  SD.ShippingVia = SV.[Name],
	  SD.GLAccount = (ISNULL(GLA.AccountCode,'')+'-'+ISNULL(GLA.AccountName,'')),
	  SD.Warehouse = WH.[Name],
		SD.[Location] = LC.[Name],
		SD.ShelfName = SF.[Name],
		SD.BinName = B.[Name],
		SD.SiteName = S.[Name]

FROM dbo.AssetInventoryDraft SD WITH (NOLOCK)
INNER JOIN dbo.RepairOrderPart ROP  WITH (NOLOCK) ON ROP.RepairOrderPartRecordId =  SD.RepairOrderPartRecordId and ROP.ItemTypeId<>1
LEFT JOIN #AssetInventoryDraftMSDATA PMS  WITH (NOLOCK) ON PMS.MSID = SD.ManagementStructureId
LEFT JOIN dbo.Manufacturer MF  WITH (NOLOCK) ON MF.ManufacturerId = SD.ManufacturerId
LEFT JOIN dbo.AssetInventory AI WITH (NOLOCK) on AI.AssetInventoryId=SD.AssetInventoryId
LEFT JOIN dbo.Warehouse WH  WITH (NOLOCK) ON WH.WarehouseId = SD.WarehouseId
LEFT JOIN dbo.[Location] LC  WITH (NOLOCK) ON LC.LocationId = SD.LocationId
LEFT JOIN dbo.GLAccount GLA  WITH (NOLOCK) ON GLA.GLAccountId = SD.GLAccountId
LEFT JOIN dbo.Shelf SF  WITH (NOLOCK) ON SF.ShelfId = SD.ShelfId
LEFT JOIN dbo.Bin B  WITH (NOLOCK) ON B.BinId = SD.BinId
LEFT JOIN dbo.[Site] S  WITH (NOLOCK) ON S.SiteId = SD.SiteId
LEFT JOIN dbo.ShippingVia SV  WITH (NOLOCK) ON SV.ShippingViaId = SD.ShippingViaId
WHERE SD.RepairOrderId = @RepairOrderId

UPDATE dbo.RepairOrderPart SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(Qty),0) FROM dbo.AssetInventory   WITH (NOLOCK)
WHERE RepairOrderPartRecordId = ROP.RepairOrderPartRecordId AND isParent = 1
)) FROM dbo.RepairOrderPart ROP  WITH (NOLOCK)
WHERE ROP.RepairOrderId = @RepairOrderId and ROP.ItemTypeId<>1


UPDATE dbo.RepairOrderPart SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(QuantityBackOrdered),0) from dbo.RepairOrderPart  WITH (NOLOCK)
where ParentId = POP.RepairOrderPartRecordId and POP.ItemTypeId<>1 )) FROM dbo.RepairOrderPart POP  WITH (NOLOCK)
where POP.RepairOrderId = @RepairOrderId AND POP.isParent = 1 and POP.ItemTypeId<>1
AND ISNULL((SELECT COUNT(RepairOrderPartRecordId)
			from dbo.RepairOrderPart  WITH (NOLOCK)
			where POP.ItemTypeId<>1 and ParentId = POP.RepairOrderPartRecordId),0) > 0

SELECT RepairOrderNumber as value FROM dbo.RepairOrder PO WITH (NOLOCK) WHERE RepairOrderId = @RepairOrderId	


COMMIT TRANSACTION
END TRY
  BEGIN CATCH  
	   IF @@trancount > 0	  
       ROLLBACK TRANSACTION;
	   IF OBJECT_ID(N'tempdb..#AssetInventoryDraftMSDATA') IS NOT NULL
	   BEGIN
	    DROP TABLE #AssetInventoryDraftMSDATA 
	   END
	   IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	   BEGIN
			DROP TABLE #MSDATA 
	   END
	   -- temp table drop
	   DECLARE @ErrorLogID INT
	   ,@DatabaseName VARCHAR(100) = db_name()
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	   ,@AdhocComments VARCHAR(150) = 'UpdateAssetInventoryDraftRoDetails'
	   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderId, '') AS varchar(100))			  			                                           
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
	IF OBJECT_ID(N'tempdb..#AssetInventoryDraftMSDATA') IS NOT NULL
	BEGIN
	   DROP TABLE #AssetInventoryDraftMSDATA 
	END
	IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	BEGIN
		DROP TABLE #MSDATA 
	END

END