/*************************************************************           
 ** File: GetPartUploadToILS
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used All part for ils upload.
 ** Purpose:         
 ** Date:   25/06/2025        
          
 ** PARAMETERS: @MasterCompanyId bigint      
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			-------------------------------          
    1    25/06/2025   Amit Ghediya		Created
    2    10/03/2026   Vishal Suthar     Modified to include both ILS and PartsBase
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	4    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	5    14/Oct/2026   Vishal Suthar     Added @StockLineIds to download PartsBase inventory for the selected stocklines
	6    14/Oct/2026   Vishal Suthar     PartsBase: one row per stockline (first alternate PN), integer quantity, 2-decimal price, trimmed values
 EXEC GetPartUploadToILS 1, 'PARTSBASE'
 EXEC GetPartUploadToILS 1, 'PARTSBASE', '101,102'
**************************************************************/

CREATE PROCEDURE [dbo].[GetPartUploadToILS]
	@MasterCompanyId BIGINT,
	@Portal VARCHAR(50),
	@StockLineIds VARCHAR(MAX) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	SET NOCOUNT ON  
	BEGIN TRY
			
			IF (@Portal = 'ILS')
			BEGIN
				DECLARE @Condition_Code VARCHAR(100) = 'AR,NE,NS,OH,SVC',
						@NHA_MappingType INT = 1,
						@SiteId BIGINT = 0,
						@WarehouseId BIGINT = 0,
						@LocationId BIGINT = 0,
						@ShelfId BIGINT = 0,
						@BinId BIGINT = 0;

				SELECT @SiteId = [SiteId],@WarehouseId = [WarehouseId],@LocationId = [LocationId],@ShelfId = [ShelfId],@BinId = [BinId] FROM [dbo].[StocklineSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;

				IF(@SiteId = 0)
				BEGIN
					SET @SiteId = NULL;
				END

				IF(@WarehouseId = 0)
				BEGIN
					SET @WarehouseId = NULL;
				END

				IF(@LocationId = 0)
				BEGIN
					SET @LocationId = NULL;
				END

				IF(@ShelfId = 0)
				BEGIN
					SET @ShelfId = NULL;
				END

				IF(@BinId = 0)
				BEGIN
					SET @BinId = NULL;
				END

				SELECT 
					1 AS ITEMNUMBER,
					'' AS 'COMPANYID',
					IM.Partnumber AS 'PARTNUMBER',
					IM1.partnumber AS 'ALTERNATEPARTNUMBER',
					STK.Condition AS CONDITIONCD,
					'Y' AS ILSLISTCD,
					0 AS PARTVALUE,
					IM.PartDescription AS 'DESCRIPTION',
					--IM.PartAlternatePartId,
					'' AS CAGE,
					STK.Quantity AS QUANTITY,
					STK.UnitOfMeasure AS UNITOFMEASURE,
					STK.UnitCost AS PRICE,
					'' AS PARTCATEGORY,
					'' AS 'CONTROL',
					'' AS EXCHANGESEL
					--STK.Condition,
					--STK.ConditionId
				FROM [dbo].[Stockline] STK WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = STK.ItemMasterId
				LEFT JOIN [dbo].[Nha_Tla_Alt_Equ_ItemMapping] TLA WITH(NOLOCK) ON STK.ItemMasterId = TLA.ItemMasterId AND TLA.MappingType = @NHA_MappingType
				LEFT JOIN [dbo].[ItemMaster] IM1 WITH(NOLOCK) ON IM1.ItemMasterId = TLA.MappingItemMasterId
				 AND ISNULL(IM1.IsNonStock,0) = 0
				 INNER JOIN [dbo].[Condition] CON WITH(NOLOCK) ON CON.ConditionId = STK.ConditionId
				WHERE ISNULL(IM.IsNonStock,0) = 0 AND ( STK.MasterCompanyId = @MasterCompanyId 
				AND @SiteId IS NULL OR STK.SiteId = @SiteId
				AND @WarehouseId IS NULL OR STK.WarehouseId = @WarehouseId
				AND @LocationId IS NULL OR STK.LocationId = @LocationId
				AND @ShelfId IS NULL OR STK.ShelfId = @ShelfId
				AND @BinId IS NULL OR STK.BinId = @BinId
				AND STK.isActive = 1
				AND STK.isDeleted = 0
				AND STk.MasterCompanyId = @MasterCompanyId
				AND CON.[Description] IN(SELECT item FROM SplitString(@Condition_Code,','))
				) AND ISNULL(STK.IsNonStock,0) = 0 ORDER BY STK.CreatedDate DESC
			END
			ELSE IF (@Portal = 'PARTSBASE')
			BEGIN
				DECLARE @Condition_Code_PartsBase VARCHAR(100) = 'AR,NE,NS,OH,SVC',
						@NHA_MappingType_PartsBase INT = 1,
						@SiteId_PartsBase BIGINT = 0,
						@WarehouseId_PartsBase BIGINT = 0,
						@LocationId_PartsBase BIGINT = 0,
						@ShelfId_PartsBase BIGINT = 0,
						@BinId_PartsBase BIGINT = 0;

				SELECT @SiteId_PartsBase = [PartsBaseSiteId],@WarehouseId_PartsBase = [PartsBaseWarehouseId],@LocationId_PartsBase = [PartsBaseLocationId],@ShelfId_PartsBase = [PartsBaseShelfId],@BinId_PartsBase = [PartsBaseBinId] FROM [dbo].[StocklineSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;

				IF(@SiteId_PartsBase = 0)
				BEGIN
					SET @SiteId_PartsBase = NULL;
				END

				IF(@WarehouseId_PartsBase = 0)
				BEGIN
					SET @WarehouseId_PartsBase = NULL;
				END

				IF(@LocationId_PartsBase = 0)
				BEGIN
					SET @LocationId_PartsBase = NULL;
				END

				IF(@ShelfId_PartsBase = 0)
				BEGIN
					SET @ShelfId_PartsBase = NULL;
				END

				IF(@BinId_PartsBase = 0)
				BEGIN
					SET @BinId_PartsBase = NULL;
				END

				SELECT 
					1 AS ITEMNUMBER,
					'' AS 'COMPANYID',
					LTRIM(RTRIM(IM.Partnumber)) AS 'PartNumber',
					LTRIM(RTRIM(ALT.PartNumber)) AS 'AlternatePartNumber',
					LTRIM(RTRIM(STK.Condition)) AS Condition,
					'Y' AS ILSLISTCD,
					0 AS PARTVALUE,
					LTRIM(RTRIM(IM.PartDescription)) AS 'PartDescription',
					'' AS CAGE,
					CAST(ROUND(ISNULL(STK.Quantity, 0), 0) AS INT) AS Quantity,
					LTRIM(RTRIM(STK.UnitOfMeasure)) AS UOM,
					CAST(ISNULL(STK.UnitCost, 0) AS DECIMAL(18,2)) AS Price,
					'' AS PARTCATEGORY,
					'' AS 'CONTROL',
					'' AS EXCHANGESEL,
					LTRIM(RTRIM(STK.Manufacturer)) AS Manufacturer,
					STK.Location AS Location,
					'' AS EngineModel,
					STK.SerialNumber AS SerialNumber,
					STK.PartCertificationNumber AS Certification,
					STK.TraceableTo AS Trace,
					'' AS Images,
					'' AS Documents,
					'' AS Capabilities
				FROM [dbo].[Stockline] STK WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = STK.ItemMasterId
				OUTER APPLY (SELECT TOP 1 IM1.partnumber AS PartNumber
							 FROM [dbo].[Nha_Tla_Alt_Equ_ItemMapping] TLA WITH(NOLOCK)
							 INNER JOIN [dbo].[ItemMaster] IM1 WITH(NOLOCK) ON IM1.ItemMasterId = TLA.MappingItemMasterId AND ISNULL(IM1.IsNonStock,0) = 0
							 WHERE TLA.ItemMasterId = STK.ItemMasterId AND TLA.MappingType = @NHA_MappingType_PartsBase
							 ORDER BY IM1.partnumber) ALT
				 INNER JOIN [dbo].[Condition] CON WITH(NOLOCK) ON CON.ConditionId = STK.ConditionId
				WHERE ISNULL(IM.IsNonStock,0) = 0 AND (
				(ISNULL(@StockLineIds, '') <> ''
				AND STK.MasterCompanyId = @MasterCompanyId
				AND STK.isActive = 1
				AND STK.isDeleted = 0
				AND STK.StockLineId IN (SELECT item FROM SplitString(@StockLineIds,',')))
				OR (ISNULL(@StockLineIds, '') = '' AND ( STK.MasterCompanyId = @MasterCompanyId
				AND @SiteId_PartsBase IS NULL OR STK.SiteId = @SiteId_PartsBase
				AND @WarehouseId_PartsBase IS NULL OR STK.WarehouseId = @WarehouseId_PartsBase
				AND @LocationId_PartsBase IS NULL OR STK.LocationId = @LocationId_PartsBase
				AND @ShelfId_PartsBase IS NULL OR STK.ShelfId = @ShelfId_PartsBase
				AND @BinId_PartsBase IS NULL OR STK.BinId = @BinId_PartsBase
				AND STK.isActive = 1
				AND STK.isDeleted = 0
				AND STk.MasterCompanyId = @MasterCompanyId
				AND CON.[Description] IN(SELECT item FROM SplitString(@Condition_Code_PartsBase,','))
				))) AND ISNULL(STK.IsNonStock,0) = 0 ORDER BY STK.CreatedDate DESC
			END
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPartUploadToILS' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@MasterCompanyId AS varchar(MAX)) ,'') +''
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