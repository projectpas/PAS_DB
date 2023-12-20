



/*************************************************************           
 ** File:   [UpdateItemMasterDetail]           
 ** Author:   Moin Bloch
 ** Description: Update Item Master All Id Wise Names
 ** Purpose: Reducing Joins         
 ** Date:   30-Mar-2021     
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    30-Mar-2021   Moin Bloch   Created

 EXEC UpdateItemMasterDetail 268
**************************************************************/ 

CREATE Procedure [dbo].[UpdateItemMasterDetail]
@ItemMasterId  bigint
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		BEGIN TRANSACTION
---------  Item Master --------------------------------------------------------------

		UPDATE IM SET
		RevisedPart	 = RPART.PartNumber,
		OEMPN = IMST.PartNumber,
		ItemClassificationName = IMCLS.[ItemClassificationCode],	 
		ItemGroup = ITG.[ItemGroupCode],	
		AssetAcquistionType	 = IATY.[Name],
		ManufacturerName = MFG.[Name],
		PurchaseUnitOfMeasure =  IPUOM.ShortName,
		StockUnitOfMeasure = ISUOM.ShortName,	
		ConsumeUnitOfMeasure = ICUOM.ShortName,	
		PurchaseCurrency = 	PCU.Code + ' ' + PCU.Symbol,
		SalesCurrency	= SCU.Code + ' ' + SCU.Symbol,
		GLAccount = (ISNULL(GL.AccountCode,'')+'-'+ISNULL(GL.AccountName,'')),
		Priority =	PR.[Description],
		SiteName = 	ST.Name,
		WarehouseName = WH.Name,	
		LocationName = 	LC.Name,
		ShelfName = SF.Name,	
		BinName	 =  BN.Name
		  
		FROM  dbo.ItemMaster IM WITH (NOLOCK)
		      INNER JOIN dbo.Manufacturer MFG WITH (NOLOCK) ON IM.ManufacturerId = MFG.ManufacturerId
			  LEFT JOIN  dbo.ItemMaster RPART WITH (NOLOCK) ON IM.RevisedPartId = RPART.ItemMasterId 
		      LEFT JOIN  dbo.ItemMaster IMST WITH (NOLOCK) ON IM.IsOemPNId = IMST.ItemMasterId
			  LEFT JOIN  dbo.ItemClassification IMCLS WITH (NOLOCK) ON IM.ItemClassificationId = IMCLS.ItemClassificationId
			  LEFT JOIN  dbo.Itemgroup ITG WITH (NOLOCK) ON IM.ItemGroupId = ITG.ItemGroupId
			  LEFT JOIN  dbo.AssetAcquisitionType IATY WITH (NOLOCK) ON IM.ItemMasterAssetTypeId = IATY.AssetAcquisitionTypeId
			  LEFT JOIN  dbo.UnitOfMeasure IPUOM WITH (NOLOCK) ON IM.PurchaseUnitOfMeasureId = IPUOM.UnitOfMeasureId
			  LEFT JOIN  dbo.UnitOfMeasure ISUOM WITH (NOLOCK) ON IM.StockUnitOfMeasureId = ISUOM.UnitOfMeasureId
			  LEFT JOIN  dbo.UnitOfMeasure ICUOM WITH (NOLOCK) ON IM.ConsumeUnitOfMeasureId = ICUOM.UnitOfMeasureId
			  LEFT JOIN  dbo.Currency PCU  WITH (NOLOCK) ON IM.PurchaseCurrencyId = PCU.CurrencyId
			  LEFT JOIN  dbo.Currency SCU  WITH (NOLOCK) ON IM.SalesCurrencyId = SCU.CurrencyId
			  LEFT JOIN  dbo.GLAccount GL WITH (NOLOCK) ON IM.GLAccountId = GL.GLAccountId
			  LEFT JOIN  dbo.Priority PR WITH (NOLOCK) ON IM.PriorityId = PR.PriorityId 
			  LEFT JOIN  dbo.Site ST WITH (NOLOCK) ON IM.SiteId = ST.SiteId
			  LEFT JOIN  dbo.Warehouse WH WITH (NOLOCK) ON IM.WarehouseId = WH.WarehouseId
			  LEFT JOIN  dbo.Location LC WITH (NOLOCK) ON IM.LocationId = LC.LocationId
			  LEFT JOIN  dbo.Shelf SF WITH (NOLOCK) ON IM.ShelfId = SF.ShelfId
			  LEFT JOIN  dbo.Bin BN WITH (NOLOCK) ON IM.BinId = BN.BinId
			  
		WHERE IM.ItemMasterId  = @ItemMasterId 
		
		SELECT partnumber AS value FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId  = @ItemMasterId ;
		
		COMMIT TRANSACTION
     END TRY
     BEGIN CATCH  
	   IF @@trancount > 0	  
       ROLLBACK TRANSACTION;
	   -- temp table drop
	   DECLARE @ErrorLogID INT
	   ,@DatabaseName VARCHAR(100) = db_name()
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	   ,@AdhocComments VARCHAR(150) = 'UpdateItemMasterDetail'
	   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100))			  			                                           
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
END