
--- exec UpdateStocklineDraftDetailRo  132
CREATE  Procedure [dbo].[UpdateStocklineDraftDetailRo]
@RepairOrderId  bigint
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	

BEGIN TRY
BEGIN TRANSACTION

--DECLARE @MSID as bigint
--DECLARE @Level1 as varchar(200)
--DECLARE @Level2 as varchar(200)
--DECLARE @Level3 as varchar(200)
--DECLARE @Level4 as varchar(200)

--IF OBJECT_ID(N'tempdb..#StocklineDraftMSDATA') IS NOT NULL
--BEGIN
--DROP TABLE #StocklineDraftMSDATA 
--END
--CREATE TABLE #StocklineDraftMSDATA
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
--INSERT INTO #MSDATA (MSID)
--  SELECT RO.ManagementStructureEntityId FROM dbo.StocklineDraft RO Where RO.RepairOrderId = @RepairOrderId


--DECLARE @LoopID as int 
--SELECT  @LoopID = MAX(ID) FROM #MSDATA
--WHILE(@LoopID > 0)
--BEGIN
--SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID

--EXEC dbo.GetMSNameandCode @MSID,
-- @Level1 = @Level1 OUTPUT,
-- @Level2 = @Level2 OUTPUT,
-- @Level3 = @Level3 OUTPUT,
-- @Level4 = @Level4 OUTPUT

--INSERT INTO #StocklineDraftMSDATA (MSID, Level1,Level2,Level3,Level4)
--                              SELECT @MSID,@Level1,@Level2,@Level3,@Level4
--SET @LoopID = @LoopID - 1;
--END  


UPDATE dbo.StocklineDraft SET ParentId =  (SELECT TOP 1 S.StockLineDraftId FROM dbo.StocklineDraft S WHERE 
	                                      S.StockLineDraftNumber = SDF.StockLineDraftNumber 
								          AND (ISNULL(IsParent,0) = 1))
	  FROM dbo.StocklineDraft SDF WHERE SDF.RepairOrderId = @RepairOrderId AND ISNULL(SDF.IsParent,0) = 0 AND ISNULL(SDF.IsParent,0) = 0

UPDATE SD SET
--SD.Level1 = PMS.Level1,
--SD.Level2 = PMS.Level2,
--SD.Level3 = PMS.Level3,
--SD.Level4 = PMS.Level4,
Manufacturer = MF.[NAME],
Condition = CO.[Description],
Warehouse = WH.[Name],
[Location] = LC.[Name],
ObtainFromName = CASE WHEN SD.ObtainFromType = 1 THEN CUST.[Name] 
                          WHEN SD.ObtainFromType = 2 THEN VEN.VendorName
						  WHEN SD.ObtainFromType = 9 THEN COM.[Name]	
						  ELSE SD.ObtainFromName
			     END,
OwnerName =  CASE WHEN SD.OwnerType = 1 THEN CUSTON.[Name] 
                          WHEN SD.OwnerType = 2 THEN VENON.VendorName
						  WHEN SD.OwnerType = 9 THEN COMON.[Name]	
						  ELSE SD.OwnerName
			 END,
TraceableToName = CASE WHEN SD.TraceableToType = 1 THEN CUSTTTN.[Name] 
                          WHEN SD.TraceableToType = 2 THEN VENTTN.VendorName
						  WHEN SD.TraceableToType = 9 THEN COMTTN.[Name]	
						  ELSE SD.TraceableToName
			 END,
TaggedByName = CASE WHEN SD.TaggedByType = 1 THEN TAGCUST.[Name] 
                          WHEN SD.TaggedByType = 2 THEN TAGVEN.VendorName
						  WHEN SD.TaggedByType = 9 THEN TAGCOM.[Name]	
						  ELSE SD.TaggedByName
			 END,
CertifiedBy = CASE WHEN SD.CertifiedTypeId = 1 THEN CERCUST.[Name] 
                          WHEN SD.CertifiedTypeId = 2 THEN CERVEN.VendorName
						  WHEN SD.CertifiedTypeId = 9 THEN CERCOM.[Name]	
						  ELSE SD.CertifiedBy
				END,

GLAccount = (ISNULL(GLA.AccountCode,'')+'-'+ISNULL(GLA.AccountName,'')),
--AssetName =  AST.[Name],       always null need to verify
LegalEntityName = LE.[Name],
ShelfName = SF.[Name],
BinName = B.[Name],
SiteName = S.[Name],
ObtainFromTypeName = (select ModuleName from dbo.Module WITH (NOLOCK) Where Moduleid = SD.ObtainFromType),
OwnerTypeName =  (select ModuleName from dbo.Module WITH (NOLOCK) Where Moduleid = SD.OwnerType),
TraceableToTypeName =  (select ModuleName from dbo.Module WITH (NOLOCK) Where Moduleid = SD.TraceableToType),
TaggedByTypeName =  (select ModuleName from dbo.Module WITH (NOLOCK) Where Moduleid = SD.TaggedByType),
CertifiedType =  (select ModuleName from dbo.Module WITH (NOLOCK) Where Moduleid = SD.CertifiedTypeId),
ShippingVia = SV.[Name],
WorkOrder = WO.WorkOrderNum,
ShelfLife = im.ShelfLife,
OrderDate = Ro.OpenDate,
CoreUnitCost = IMPS.PP_UnitPurchasePrice,
IsHazardousMaterial = IM.IsHazardousMaterial,
IsPMA = IM.IsPma,
IsDER = IM.IsDER,
OEM = IM.IsOEM,
WorkOrderId = ROP.WorkOrderId,
--TaggedByName = (ISNULL(Emp.FirstName,'')+' '+ISNULL(Emp.LastName,'')),
UnitOfMeasure = UM.shortname,
RevisedPartNumber = RIM.partnumber,
TagType = TT.[Name]

FROM dbo.StocklineDraft SD WITH (NOLOCK)
INNER JOIN dbo.RepairOrderPart ROP  WITH (NOLOCK) ON ROP.RepairOrderPartRecordId =  SD.RepairOrderPartRecordId and ROP.ItemTypeId=1
--LEFT JOIN #StocklineDraftMSDATA PMS  WITH (NOLOCK) ON PMS.MSID = SD.ManagementStructureEntityId
LEFT JOIN dbo.Manufacturer MF  WITH (NOLOCK) ON MF.ManufacturerId = SD.ManufacturerId
LEFT JOIN dbo.Condition CO  WITH (NOLOCK) ON CO.ConditionId = SD.ConditionId
LEFT JOIN dbo.ItemMaster IM  WITH (NOLOCK) ON ROP.ItemMasterId=IM.ItemMasterId
LEFT JOIN dbo.ItemMasterPurchaseSale IMPS  WITH (NOLOCK) ON IMPS.ItemMasterId = SD.ItemMasterId AND  IMPS.ConditionId = SD.ConditionId
LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping NHA  WITH (NOLOCK) ON IMPS.ItemMasterId = SD.ItemMasterId AND  IMPS.ConditionId = SD.ConditionId
LEFT JOIN dbo.Warehouse WH  WITH (NOLOCK) ON WH.WarehouseId = SD.WarehouseId
LEFT JOIN dbo.[Location] LC  WITH (NOLOCK) ON LC.LocationId = SD.LocationId
LEFT JOIN dbo.GLAccount GLA  WITH (NOLOCK) ON GLA.GLAccountId = SD.GlAccountId
LEFT JOIN dbo.Asset    AST  WITH (NOLOCK) ON AST.AssetId = SD.AssetId
LEFT JOIN dbo.LegalEntity LE  WITH (NOLOCK) ON LE.LegalEntityId = SD.LegalEntityId
LEFT JOIN dbo.Shelf SF  WITH (NOLOCK) ON SF.ShelfId = SD.ShelfId
LEFT JOIN dbo.Bin B  WITH (NOLOCK) ON B.BinId = SD.BinId
LEFT JOIN dbo.[Site] S  WITH (NOLOCK) ON S.SiteId = SD.SiteId
LEFT JOIN dbo.ShippingVia SV  WITH (NOLOCK) ON SV.ShippingViaId = SD.ShippingViaId
LEFT JOIN dbo.WorkOrder WO  WITH (NOLOCK) ON WO.WorkOrderId = SD.WorkOrderId
LEFT JOIN dbo.Customer CUST  WITH (NOLOCK) ON CUST.CustomerId = SD.ObtainFrom
LEFT JOIN dbo.Customer CUSTON  WITH (NOLOCK) ON CUSTON.CustomerId = SD.[Owner]
LEFT JOIN dbo.Customer CUSTTTN  WITH (NOLOCK) ON CUSTTTN.CustomerId = SD.TraceableTo
LEFT JOIN dbo.Vendor VEN  WITH (NOLOCK) ON VEN.VendorId = SD.ObtainFrom
LEFT JOIN dbo.Vendor VENON  WITH (NOLOCK) ON VENON.VendorId = SD.[Owner]
LEFT JOIN dbo.Vendor VENTTN  WITH (NOLOCK) ON VENTTN.VendorId = SD.TraceableTo
LEFT JOIN dbo.LegalEntity COM  WITH (NOLOCK) ON COM.LegalEntityId = ObtainFrom
LEFT JOIN dbo.LegalEntity COMON  WITH (NOLOCK) ON COMON.LegalEntityId = [Owner]
LEFT JOIN dbo.LegalEntity COMTTN  WITH (NOLOCK) ON COMTTN.LegalEntityId = TraceableTo
LEFT JOIN dbo.Customer TAGCUST  WITH (NOLOCK) ON TAGCUST.CustomerId = SD.TaggedBy
LEFT JOIN dbo.Vendor TAGVEN  WITH (NOLOCK) ON TAGVEN.VendorId = SD.TaggedBy
LEFT JOIN dbo.LegalEntity TAGCOM  WITH (NOLOCK) ON TAGCOM.LegalEntityId = SD.TaggedBy
LEFT JOIN dbo.Customer CERCUST  WITH (NOLOCK) ON CERCUST.CustomerId = SD.CertifiedById
LEFT JOIN dbo.Vendor CERVEN  WITH (NOLOCK) ON CERVEN.VendorId = SD.CertifiedById
LEFT JOIN dbo.LegalEntity CERCOM  WITH (NOLOCK) ON CERCOM.LegalEntityId = SD.CertifiedById
LEFT JOIN dbo.RepairOrder Ro  WITH (NOLOCK) ON Ro.RepairOrderId =  SD.RepairOrderId
LEFT JOIN dbo.Employee Emp   WITH (NOLOCK) ON Emp.EmployeeId = SD.TaggedBy
LEFT JOIN dbo.UnitOfMeasure UM  WITH (NOLOCK) ON UM.unitOfMeasureId = SD.UnitOfMeasureId
LEFT JOIN ItemMaster RIM  WITH (NOLOCK) ON RIM.ItemMasterId =  SD.RevisedPartId	
LEFT JOIN dbo.TagType  TT WITH (NOLOCK) ON TT.TagTypeId = SD.TagTypeId
WHERE SD.RepairOrderId = @RepairOrderId

UPDATE dbo.RepairOrderPart SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(Quantity),0) FROM dbo.Stockline  WITH (NOLOCK)
WHERE RepairOrderPartRecordId = ROP.RepairOrderPartRecordId AND isParent = 1 and ROP.ItemTypeId=1)) FROM dbo.RepairOrderPart ROP  WITH (NOLOCK)
WHERE ROP.RepairOrderId = @RepairOrderId and ROP.ItemTypeId=1

--UPDATE dbo.RepairOrderPart SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(QuantityBackOrdered),0) FROM dbo.RepairOrderPart 
--WHERE ParentId = ROP.RepairOrderPartRecordId )) FROM dbo.RepairOrderPart ROP 
--WHERE ROP.RepairOrderId = @RepairOrderId AND ROP.isParent = 1;


UPDATE dbo.RepairOrderPart SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(QuantityBackOrdered),0) from dbo.RepairOrderPart  WITH (NOLOCK)
where ParentId = POP.RepairOrderPartRecordId and POP.ItemTypeId=1 )) FROM dbo.RepairOrderPart POP  WITH (NOLOCK)
where POP.RepairOrderId = @RepairOrderId AND POP.isParent = 1 and POP.ItemTypeId=1
AND ISNULL((SELECT COUNT(RepairOrderPartRecordId)
			from dbo.RepairOrderPart  WITH (NOLOCK)
			where POP.ItemTypeId=1 and ParentId = POP.RepairOrderPartRecordId),0) > 0


--UPDATE StocklineDraft SET NHAItemMasterId = (
--SELECT TOP 1 NHA.MappingItemMasterId from dbo.StocklineDraft SLD 
--inner join dbo.Nha_Tla_Alt_Equ_ItemMapping NHA 
--           ON NHA.ItemMasterId = SLD.ItemMasterId AND NHA.MappingType = 3 AND  SLD.StockLineDraftId = SD.StockLineDraftId)
--FROM dbo.StocklineDraft SD
--		   WHERE SD.RepairOrderId = @RepairOrderId AND SD.NHAItemMasterId IS NULL

--UPDATE StocklineDraft SET TLAItemMasterId = (
--SELECT TOP 1 NHA.MappingItemMasterId from dbo.StocklineDraft SLD 
--inner join dbo.Nha_Tla_Alt_Equ_ItemMapping NHA 
--           ON NHA.ItemMasterId = SLD.ItemMasterId AND NHA.MappingType = 4 AND  SLD.StockLineDraftId = SD.StockLineDraftId)
--FROM dbo.StocklineDraft SD WHERE SD.RepairOrderId = @RepairOrderId AND SD.TLAItemMasterId IS NULL

SELECT RepairOrderNumber as value FROM dbo.RepairOrder PO WITH (NOLOCK) WHERE RepairOrderId = @RepairOrderId	


COMMIT TRANSACTION
END TRY
  BEGIN CATCH  
	   IF @@trancount > 0	  
       ROLLBACK TRANSACTION;
	  -- IF OBJECT_ID(N'tempdb..#StocklineDraftMSDATA') IS NOT NULL
	  -- BEGIN
	  --  DROP TABLE #StocklineDraftMSDATA 
	  -- END
	  -- IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	  -- BEGIN
			--DROP TABLE #MSDATA 
	  -- END
	   -- temp table drop
	   DECLARE @ErrorLogID INT
	   ,@DatabaseName VARCHAR(100) = db_name()
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	   ,@AdhocComments VARCHAR(150) = 'UpdateStocklineDraftDetailRo'
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
	--IF OBJECT_ID(N'tempdb..#StocklineDraftMSDATA') IS NOT NULL
	--BEGIN
	--   DROP TABLE #StocklineDraftMSDATA 
	--END
	--IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	--BEGIN
	--	DROP TABLE #MSDATA 
	--END

END