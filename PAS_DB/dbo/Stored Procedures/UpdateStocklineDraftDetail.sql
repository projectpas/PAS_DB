
------------------------------------------------------------------------------------------------------------------------------

--exec UpdateStocklineDraftDetail 251
CREATE  Procedure [dbo].[UpdateStocklineDraftDetail]
@PurchaseOrderId  bigint
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		BEGIN TRANSACTION
		DECLARE @StockType int = 1;

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
	    --INSERT INTO #MSDATA (MSID) SELECT PO.ManagementStructureEntityId FROM dbo.StocklineDraft PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId
	    
	    
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
	    
	    --INSERT INTO #StocklineDraftMSDATA (MSID, Level1,Level2,Level3,Level4) SELECT @MSID,@Level1,@Level2,@Level3,@Level4
	    --SET @LoopID = @LoopID - 1;
	    --END 
	    
	    UPDATE dbo.StocklineDraft  SET ParentId = (SELECT TOP 1 S.StockLineDraftId FROM dbo.StocklineDraft S WITH (NOLOCK) WHERE 
	    	                                S.StockLineDraftNumber = SDF.StockLineDraftNumber AND (ISNULL(IsParent,0) = 1))
	    	  FROM dbo.StocklineDraft SDF WITH (NOLOCK)  WHERE SDF.PurchaseOrderId = @PurchaseOrderId AND ISNULL(SDF.IsParent,0) = 0 AND ISNULL(SDF.IsParent,0) = 0
	     
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
	    ObtainFromTypeName = (SELECT ModuleName FROM dbo.Module WITH (NOLOCK) WHERE Moduleid = SD.ObtainFromType),
	    OwnerTypeName =  (SELECT ModuleName FROM dbo.Module WITH (NOLOCK) Where Moduleid = SD.OwnerType),
	    TraceableToTypeName =  (SELECT ModuleName FROM dbo.Module WITH (NOLOCK) WHERE Moduleid = SD.TraceableToType),
	    TaggedByTypeName =  (SELECT ModuleName FROM dbo.Module WITH (NOLOCK) WHERE Moduleid = SD.TaggedByType),
	    CertifiedType =  (SELECT ModuleName FROM dbo.Module WITH (NOLOCK) WHERE Moduleid = SD.CertifiedTypeId),	    
	    ShippingVia = SV.[Name],
	    WorkOrder = WO.WorkOrderNum,
	    ShelfLife = im.ShelfLife,
	    OrderDate = po.OpenDate,
	    CoreUnitCost = IMPS.PP_UnitPurchasePrice,
	    IsHazardousMaterial = IM.IsHazardousMaterial,
	    IsPMA = IM.IsPma,
	    IsDER = IM.IsDER,
	    OEM = IM.IsOEM,
	    WorkOrderId = POP.WorkOrderId,
	    --TaggedByName = (ISNULL(Emp.FirstName,'')+' '+ISNULL(Emp.LastName,'')),
	    UnitOfMeasure = UM.shortname,
		TagType = TT.[Name]
	    
	    FROM dbo.StocklineDraft SD WITH (NOLOCK)
	    INNER JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId =  SD.PurchaseOrderPartRecordId AND POP.ItemTypeId = @StockType
	    --LEFT JOIN #StocklineDraftMSDATA PMS WITH (NOLOCK) ON PMS.MSID = SD.ManagementStructureEntityId
	    LEFT JOIN dbo.Manufacturer MF WITH (NOLOCK) ON MF.ManufacturerId = SD.ManufacturerId
	    LEFT JOIN dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = SD.ConditionId
	    LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON POP.ItemMasterId=IM.ItemMasterId	
	    LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK) ON IMPS.ItemMasterId = SD.ItemMasterId AND  IMPS.ConditionId = SD.ConditionId
	    LEFT JOIN dbo.Nha_Tla_Alt_Equ_ItemMapping NHA WITH (NOLOCK) ON IMPS.ItemMasterId = SD.ItemMasterId AND  IMPS.ConditionId = SD.ConditionId
	    LEFT JOIN dbo.Warehouse WH WITH (NOLOCK) ON WH.WarehouseId = SD.WarehouseId
	    LEFT JOIN dbo.[Location] LC WITH (NOLOCK) ON LC.LocationId = SD.LocationId
	    LEFT JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = SD.GlAccountId
	    LEFT JOIN dbo.Asset    AST WITH (NOLOCK) ON AST.AssetId = SD.AssetId
	    LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON LE.LegalEntityId = SD.LegalEntityId
	    LEFT JOIN dbo.Shelf SF WITH (NOLOCK) ON SF.ShelfId = SD.ShelfId
	    LEFT JOIN dbo.Bin B WITH (NOLOCK) ON B.BinId = SD.BinId
	    LEFT JOIN dbo.[Site] S WITH (NOLOCK) ON S.SiteId = SD.SiteId
	    LEFT JOIN dbo.ShippingVia SV WITH (NOLOCK) ON SV.ShippingViaId = SD.ShippingViaId
	    LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = POP.WorkOrderId
	    LEFT JOIN dbo.Customer CUST WITH (NOLOCK) ON CUST.CustomerId = SD.ObtainFrom
	    LEFT JOIN dbo.Vendor VEN WITH (NOLOCK) ON VEN.VendorId = SD.ObtainFrom
	    LEFT JOIN dbo.LegalEntity COM WITH (NOLOCK) ON COM.LegalEntityId = ObtainFrom 
        LEFT JOIN dbo.Customer CUSTON  WITH (NOLOCK) ON CUSTON.CustomerId = SD.[Owner]
        LEFT JOIN dbo.Customer CUSTTTN  WITH (NOLOCK) ON CUSTTTN.CustomerId = SD.TraceableTo        
        LEFT JOIN dbo.Vendor VENON  WITH (NOLOCK) ON VENON.VendorId = SD.[Owner]
        LEFT JOIN dbo.Vendor VENTTN  WITH (NOLOCK) ON VENTTN.VendorId = SD.TraceableTo 
        LEFT JOIN dbo.LegalEntity COMON  WITH (NOLOCK) ON COMON.LegalEntityId = [Owner]
        LEFT JOIN dbo.LegalEntity COMTTN  WITH (NOLOCK) ON COMTTN.LegalEntityId = TraceableTo
	    LEFT JOIN dbo.Customer TAGCUST WITH (NOLOCK) ON TAGCUST.CustomerId = SD.TaggedBy
	    LEFT JOIN dbo.Vendor TAGVEN WITH (NOLOCK) ON TAGVEN.VendorId = SD.TaggedBy
	    LEFT JOIN dbo.LegalEntity TAGCOM WITH (NOLOCK) ON TAGCOM.LegalEntityId = SD.TaggedBy	    
	    LEFT JOIN dbo.Customer CERCUST WITH (NOLOCK) ON CERCUST.CustomerId = SD.CertifiedById
	    LEFT JOIN dbo.Vendor CERVEN WITH (NOLOCK) ON CERVEN.VendorId = SD.CertifiedById
	    LEFT JOIN dbo.LegalEntity CERCOM WITH (NOLOCK) ON CERCOM.LegalEntityId = SD.CertifiedById	    
	    LEFT JOIN dbo.PurchaseOrder Po WITH (NOLOCK) ON Po.purchaseorderid =  SD.PurchaseOrderID
	    --LEFT JOIN dbo.Employee Emp  ON Emp.EmployeeId = SD.TaggedBy
	    LEFT JOIN dbo.UnitOfMeasure  UM WITH (NOLOCK) ON UM.unitOfMeasureId = SD.UnitOfMeasureId
		LEFT JOIN dbo.TagType  TT WITH (NOLOCK) ON TT.TagTypeId = SD.TagTypeId		
	    WHERE SD.PurchaseOrderID = @PurchaseOrderId
	    
		--UPDATE dbo.PurchaseOrderPart  SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(COUNT(StockLineId),0) from dbo.Stockline WITH (NOLOCK)

	    UPDATE dbo.PurchaseOrderPart  SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(Quantity),0) from dbo.Stockline WITH (NOLOCK)
	    where PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId AND isParent = 1)) FROM dbo.PurchaseOrderPart POP WITH (NOLOCK)
	    where POP.PurchaseOrderID = @PurchaseOrderId AND pop.ItemTypeId = @StockType; 
	    
	    UPDATE dbo.PurchaseOrderPart SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(QuantityBackOrdered),0) from dbo.PurchaseOrderPart WITH (NOLOCK)
	    where ParentId = POP.PurchaseOrderPartRecordId )) FROM dbo.PurchaseOrderPart POP  WITH (NOLOCK)
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
	--IF OBJECT_ID(N'tempdb..#StocklineDraftMSDATA') IS NOT NULL
	--BEGIN
	--   DROP TABLE #StocklineDraftMSDATA 
	--END
	--IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	--BEGIN
	--	DROP TABLE #MSDATA 
	--END
END