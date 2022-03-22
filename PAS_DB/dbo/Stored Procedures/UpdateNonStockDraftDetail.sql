

/*************************************************************           
 ** File:   [UpdateNonStockDraftDetail]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Update NonStock Draft Detail ID Value Wise
 ** Purpose:         
 ** Date:   02/02/2022        
          
 ** PARAMETERS: @@PurchaseOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/02/2022  Moin Bloch     Created
     
-- EXEC [UpdateNonStockDraftDetail] 179
************************************************************************/
CREATE PROCEDURE [dbo].[UpdateNonStockDraftDetail]
@PurchaseOrderId  bigint
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		BEGIN TRANSACTION
		DECLARE @StockType int = 2;

	    DECLARE @MSID as bigint
	    DECLARE @Level1 as varchar(200)
	    DECLARE @Level2 as varchar(200)
	    DECLARE @Level3 as varchar(200)
	    DECLARE @Level4 as varchar(200)
	    
	    IF OBJECT_ID(N'tempdb..#NonStockDraftMSDATA') IS NOT NULL
	    BEGIN
	    DROP TABLE #NonStockDraftMSDATA 
	    END
	    CREATE TABLE #NonStockDraftMSDATA
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
	    INSERT INTO #MSDATA (MSID) SELECT PO.ManagementStructureId FROM dbo.NonStockInventoryDraft PO WITH (NOLOCK) WHERE PO.PurchaseOrderId = @PurchaseOrderId	    
	    
	    DECLARE @LoopID AS int 
	    SELECT  @LoopID = MAX(ID) FROM #MSDATA
	    WHILE(@LoopID > 0)
	    BEGIN
	    SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID
	    
	    EXEC dbo.GetMSNameandCode @MSID,
	     @Level1 = @Level1 OUTPUT,
	     @Level2 = @Level2 OUTPUT,
	     @Level3 = @Level3 OUTPUT,
	     @Level4 = @Level4 OUTPUT
	    
	    INSERT INTO #NonStockDraftMSDATA (MSID, Level1,Level2,Level3,Level4) SELECT @MSID,@Level1,@Level2,@Level3,@Level4
	    SET @LoopID = @LoopID - 1;
	    END 
	    
	    UPDATE dbo.NonStockInventoryDraft  SET ParentId = (SELECT TOP 1 S.NonStockInventoryDraftId FROM dbo.NonStockInventoryDraft S WITH (NOLOCK) WHERE 
	    	                                S.NonStockDraftNumber = SDF.NonStockDraftNumber AND (ISNULL(IsParent,0) = 1))
	    	  FROM dbo.NonStockInventoryDraft SDF WITH (NOLOCK)  WHERE SDF.PurchaseOrderId = @PurchaseOrderId AND ISNULL(SDF.IsParent,0) = 0 AND ISNULL(SDF.IsParent,0) = 0
	     
	    UPDATE SD SET
	    SD.Level1 = PMS.Level1,
	    SD.Level2 = PMS.Level2,
	    SD.Level3 = PMS.Level3,
	    SD.Level4 = PMS.Level4,
		PurchaseOrderNumber = PO.PurchaseOrderNumber,
		PartNumber = POP.PartNumber,
		PartDescription = POP.PartDescription,
		CurrencyId = IMNS.CurrencyId,
        Currency = CR.Code,
		Condition = CO.[Description],  
		GLAccount = (ISNULL(GLA.AccountCode,'')+'-'+ISNULL(GLA.AccountName,'')), 
		UnitOfMeasure = UM.ShortName,	
		Manufacturer = MF.[NAME],
		Acquired = IMNS.IsAcquiredMethodBuy, 
		IsHazardousMaterial = IMNS.IsHazardousMaterial,
		ItemNonStockClassificationId = IMNS.ItemNonStockClassificationId,
		NonStockClassification = ICLF.ItemClassificationCode,
		Site = S.[Name],	
		Warehouse = WH.[Name],
		Location = LC.[Name],	 
		Shelf = SF.[Name],
		Bin = B.[Name],
		ShippingVia = SV.[Name],   
		VendorId = PO.VendorId,
		VendorName =  PO.VendorName,
		RequisitionerId = PO.RequestedBy,
		Requisitioner = PO.Requisitioner,
		OrderDate = PO.OpenDate,
		EntryDate =  PO.OpenDate
	    -- CoreUnitCost = IMPS.PP_UnitPurchasePrice,

	    FROM dbo.NonStockInventoryDraft SD WITH (NOLOCK)
	    INNER JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.PurchaseOrderPartRecordId =  SD.PurchaseOrderPartRecordId AND POP.ItemTypeId = @StockType
	    LEFT JOIN #NonStockDraftMSDATA PMS WITH (NOLOCK) ON PMS.MSID = SD.ManagementStructureId	    
		LEFT JOIN dbo.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId =  SD.PurchaseOrderID
		LEFT JOIN dbo.ItemMasterNonStock IMNS WITH (NOLOCK) ON IMNS.MasterPartId =  SD.MasterPartId
		LEFT JOIN dbo.ItemClassification ICLF WITH (NOLOCK) ON ICLF.ItemClassificationId =  SD.ItemNonStockClassificationId
		LEFT JOIN dbo.Currency CR WITH (NOLOCK) ON CR.CurrencyId = IMNS.CurrencyId
		LEFT JOIN dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = SD.ConditionId
		LEFT JOIN dbo.GLAccount GLA WITH (NOLOCK) ON GLA.GLAccountId = SD.GLAccountId
		LEFT JOIN dbo.UnitOfMeasure  UM WITH (NOLOCK) ON UM.unitOfMeasureId = SD.UnitOfMeasureId
		LEFT JOIN dbo.Manufacturer MF WITH (NOLOCK) ON MF.ManufacturerId = SD.ManufacturerId
		LEFT JOIN dbo.[Site] S WITH (NOLOCK) ON S.SiteId = SD.SiteId
		LEFT JOIN dbo.Warehouse WH WITH (NOLOCK) ON WH.WarehouseId = SD.WarehouseId
	    LEFT JOIN dbo.[Location] LC WITH (NOLOCK) ON LC.LocationId = SD.LocationId
		LEFT JOIN dbo.Shelf SF WITH (NOLOCK) ON SF.ShelfId = SD.ShelfId
	    LEFT JOIN dbo.Bin B WITH (NOLOCK) ON B.BinId = SD.BinId	    
	    LEFT JOIN dbo.ShippingVia SV WITH (NOLOCK) ON SV.ShippingViaId = SD.ShippingViaId    			
	    WHERE SD.PurchaseOrderID = @PurchaseOrderId
	    		
	    UPDATE dbo.PurchaseOrderPart  SET QuantityBackOrdered = (QuantityOrdered - (SELECT ISNULL(SUM(Quantity),0) from dbo.NonStockInventory WITH (NOLOCK)
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
	   IF OBJECT_ID(N'tempdb..#NonStockDraftMSDATA') IS NOT NULL
	   BEGIN
	    DROP TABLE #NonStockDraftMSDATA
	   END
	   IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	   BEGIN
			DROP TABLE #MSDATA 
	   END
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
	IF OBJECT_ID(N'tempdb..#NonStockDraftMSDATA') IS NOT NULL
	BEGIN
	   DROP TABLE #NonStockDraftMSDATA
	END
	IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	BEGIN
		DROP TABLE #MSDATA 
	END
END