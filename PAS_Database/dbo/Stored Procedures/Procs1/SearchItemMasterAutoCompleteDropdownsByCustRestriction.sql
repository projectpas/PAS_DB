/*************************************************************           
 ** File:   [SearchItemMasterAutoCompleteDropdownsByRestriction]           
 ** Author		:   Hemant Saliya
 ** Description	:	Get Item Master Details By Customer Restriction    
 ** Purpose		:   Get Item Master Details By Customer Restriction      
 ** Date		:   14-Dec-2020        
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author			Change Description            
 ** --   --------			-------			-------------------          
    1    02-April-2020		Hemant Saliya	Created
     
 EXECUTE [SearchItemMasterAutoCompleteDropdownsByCustRestriction] 303, 1, 1,'','0',1
**************************************************************/ 
 CREATE   PROCEDURE [dbo].[SearchItemMasterAutoCompleteDropdownsByCustRestriction]  
  @CustomerId INT,
  @CustRestrictedDer BIT,
  @CustRestrictedPMA BIT,
  @partSarchText VARCHAR(50) = '',
  @Idlist VARCHAR(MAX) = '0',
  @MasterCompanyId bigint
  AS
	BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
				BEGIN
					DROP TABLE #TempTable 
				END
				CREATE TABLE #TempTable(      
							ItemClassificationId BIGINT,
							ItemClassification VARCHAR(MAX),
							UnitOfMeasureId BIGINT,
							UnitOfMeasure VARCHAR(MAX),
							UnitCost DECIMAL(18,2),
							ConditionId BIGINT,
							StockLineId BIGINT,
							PartId BIGINT,      
							PartNumber VARCHAR(MAX),
							Label VARCHAR(MAX),
							ManufacturerName VARCHAR(MAX),
							PartDescription VARCHAR(MAX),
							StockType VARCHAR(50),
							QuantityOnHand INT,
							QtyAvailable INT)

				IF OBJECT_ID(N'tempdb..#Result') IS NOT NULL
				BEGIN
					DROP TABLE #Result 
				END

				CREATE TABLE #Result(  
								ItemClassificationId BIGINT,
								ItemClassification VARCHAR(MAX),
								UnitOfMeasureId BIGINT,
								UnitOfMeasure VARCHAR(MAX),
								UnitCost DECIMAL(18,2),
								ConditionId BIGINT,
								StockLineId BIGINT,
								PartId BIGINT,      
								PartNumber VARCHAR(MAX),
								Label VARCHAR(MAX),
								ManufacturerName VARCHAR(MAX),
								PartDescription VARCHAR(MAX),
								StockType VARCHAR(50),
								QuantityOnHand INT,
								QtyAvailable INT) 

				IF OBJECT_ID(N'tempdb..#RestrictedPart') IS NOT NULL
				BEGIN
					DROP TABLE #RestrictedPart 
				END

				CREATE TABLE #RestrictedPart(PartId BIGINT) 

				INSERT INTO #TempTable (PartId, PartNumber,Label,ManufacturerNamem, PartDescription, StockType, ItemClassificationId, ItemClassification, UnitOfMeasureId, UnitOfMeasure, UnitCost, ConditionId, StockLineId, QuantityOnHand, QtyAvailable)
				SELECT DISTINCT TOP 20
					  im.ItemMasterId AS PartId,
					  im.partnumber AS PartNumber,
					  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS label,
					  im.ManufacturerName AS ManufacturerName,
					  im.PartDescription AS PartDescription,
					  (CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
						WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
						ELSE 'OEM' END) AS StockType,
					  im.ItemClassificationId, 
					  Ic.Description AS ItemClassification,
					  im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
					  uom.ShortName AS UnitOfMeasure,
					  imps.PP_UnitPurchasePrice AS UnitCost,
					  --UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL on SL.ItemMasterId = im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId),
					  sl.ConditionId,
					  sl.StockLineId,
					  sl.QuantityOnHand,
					  sl.QuantityAvailable
					  --ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND s.ManufacturerId = im.ManufacturerId),
					  --QuantityOnHand = (select top 1 s.QuantityOnHand from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND s.ManufacturerId = im.ManufacturerId),
					  --QuantityAvailable = (select top 1 s.QuantityAvailable from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND s.ManufacturerId = im.ManufacturerId)
				FROM DBO.ItemMaster im WITH (NOLOCK)
					JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
					JOIN Stockline sl WITH (NOLOCK) ON sl.ItemMasterId = im.ItemMasterId
					LEFT JOIN ItemMasterPurchaseSale imps WITH (NOLOCK) ON im.ItemMasterId = imps.ItemMasterId AND sl.ConditionId = imps.ConditionId
					LEFT JOIN [dbo].[RestrictedParts] rpDER WITH (NOLOCK) ON im.ItemMasterId = rpDER.ItemMasterId
							AND rpDER.PartType = 'DER' AND rpDER.ReferenceId  = @CustomerId 
							AND rpDER.IsActive = 1 AND rpDER.IsDeleted = 0
					LEFT JOIN [dbo].[RestrictedParts] rpPMA WITH (NOLOCK) ON im.ItemMasterId = rpPMA.ItemMasterId
							AND rpPMA.PartType = 'PMA' AND rpPMA.ReferenceId  = @CustomerId 
							AND rpPMA.IsActive = 1 AND rpPMA.IsDeleted = 0
					LEFT JOIN ItemClassification Ic WITH (NOLOCK) ON im.ItemClassificationId = Ic.ItemClassificationId
				WHERE im.IsActive = 1 AND im.IsDeleted = 0 AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
					 AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
					 AND (
						(@CustRestrictedDer = CONVERT(BIT, 0) AND @CustRestrictedPMA = CONVERT(BIT, 0))
						OR 
						(@CustRestrictedDer = CONVERT(BIT, 1) AND @CustRestrictedPMA = CONVERT(BIT, 1) AND im.IsDER =  CONVERT(BIT, 0) AND im.IsPma =  CONVERT(BIT, 0))
						OR 
						(@CustRestrictedDer = CONVERT(BIT, 0) AND @CustRestrictedPMA = CONVERT(BIT, 1) AND im.IsDER =  CONVERT(BIT, 1) AND im.IsPma =  CONVERT(BIT, 0))
						OR 
						(@CustRestrictedDer = CONVERT(BIT, 1) AND @CustRestrictedPMA = CONVERT(BIT, 0) AND im.IsDER =  CONVERT(BIT, 0) AND im.IsPma =  CONVERT(BIT, 1))
						OR
						(rpPMA.ItemMasterId IS NOT NULL OR rpDER.ItemMasterId IS NOT NULL)
						)
					AND im.MasterCompanyId = @MasterCompanyId
					Order BY partnumber

				INSERT INTO #Result SELECT DISTINCT TOP 20 * FROM #TempTable t ORDER BY t.PartNumber

				IF(@Idlist IS NOT NULL)
				BEGIN
					INSERT INTO #Result(PartId, PartNumber,Label,ManufacturerNamem, PartDescription, StockType, ItemClassificationId, ItemClassification, UnitOfMeasureId, UnitOfMeasure, UnitCost, ConditionId, StockLineId, QuantityOnHand, QtyAvailable)
					SELECT DISTINCT TOP 20
						  im.ItemMasterId AS PartId,
						  im.partnumber  AS PartNumber,
						  im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS label,
					      im.ManufacturerName AS ManufacturerName,
						  im.PartDescription AS PartDescription,
						  (CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
							WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
							WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END) AS StockType,
						  im.ItemClassificationId, 
						  Ic.Description AS ItemClassification,
						  im.PurchaseUnitOfMeasureId AS UnitOfMeasureId,
						  uom.ShortName AS UnitOfMeasure,
						  imps.PP_UnitPurchasePrice AS UnitCost,
						  --UnitCost = (select top 1 imps.PP_UnitPurchasePrice FROM dbo.ItemMasterPurchaseSale imps with(NoLock) INNER JOIN dbo.Stockline SL on SL.ItemMasterId = im.ItemMasterId AND SL.ConditionId = imps.ConditionId Where imps.ItemMasterId = im.ItemMasterId),
						  sl.ConditionId,
						  sl.StockLineId,
						  sl.QuantityOnHand,
						  sl.QuantityAvailable
						  --ConditionId = (select top 1 s.ConditionId from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId),
						  --QuantityOnHand = (select top 1 s.QuantityOnHand from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND s.ManufacturerId = im.ManufacturerId),
						  --QuantityAvailable = (select top 1 s.QuantityAvailable from dbo.Stockline s with(NoLock) Where s.ItemMasterId = im.ItemMasterId AND s.ManufacturerId = im.ManufacturerId)
				 FROM DBO.ItemMaster im WITH (NOLOCK)
					 JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) on im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
					 JOIN Stockline sl WITH (NOLOCK) ON sl.ItemMasterId = im.ItemMasterId
					 LEFT JOIN ItemMasterPurchaseSale imps WITH (NOLOCK) ON im.ItemMasterId = imps.ItemMasterId AND sl.ConditionId = imps.ConditionId
					 LEFT JOIN ItemClassification Ic WITH (NOLOCK) ON im.ItemClassificationId = Ic.ItemClassificationId
				 WHERE im.ItemMasterId  IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))
				END

				SELECT TOP 20 
					PartId AS Value, 
					label AS Label,
					PartId AS ItemMasterId, 
					PartNumber, 
					ManufacturerName,
					PartDescription, 
					StockType, 
					ItemClassificationId, 
					ItemClassification, 
					UnitOfMeasureId, 
					UnitOfMeasure, 
					UnitCost, 
					ConditionId,
					StockLineId,
					QuantityOnHand,
					QtyAvailable
				FROM #Result

				DROP Table #TempTable  
				DROP Table #RestrictedPart 
				DROP Table #Result

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchItemMasterAutoCompleteDropdownsByCustRestriction' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerId, '') + ''', @Parameter2 = ' + ISNULL(@partSarchText,'') + ', @Parameter3 = ' + ISNULL(@Idlist ,'') +''
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