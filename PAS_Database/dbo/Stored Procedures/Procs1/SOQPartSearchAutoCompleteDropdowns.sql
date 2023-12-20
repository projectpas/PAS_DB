

CREATE     PROCEDURE [dbo].[SOQPartSearchAutoCompleteDropdowns]  
  @CustomerId INT=0,
  @CustRestrictedDer BIT=0,
  @CustRestrictedPMA BIT=0,
  @IncludeDER BIT = 0 ,
  @IncludePMA BIT = 0,
  @IncludeAlternatePN BIT = NULL,
  @IncludeEquiPN BIT = NULL,
  @partSarchText VARCHAR(50) = '',
  @Idlist VARCHAR(MAX) = '0',
  @MasterCompanyId INT = 1
  AS
  BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
		BEGIN
			DROP TABLE #TempTable 
		END
		CREATE TABLE #TempTable(      
					PartId BIGINT,      
					PartNumber VARCHAR(MAX),
					Label VARCHAR(Max),
					PartDescription VARCHAR(MAX),
					ManufacturerName VARCHAR(MAX),
					StockType VARCHAR(50))

		IF OBJECT_ID(N'tempdb..#Result') IS NOT NULL
		BEGIN
			DROP TABLE #Result 
		END

		CREATE TABLE #Result(      
						PartId BIGINT,      
						PartNumber VARCHAR(MAX),
						Label VARCHAR(MAX),
						PartDescription VARCHAR(MAX),
						ManufacturerName VARCHAR(MAX),
						StockType VARCHAR(50)) 
	
		--- FOR OEM
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT 
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)			
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
			AND im.IsOEM = 1 AND IsDER = 0

		--FOR PMA
		IF( @CustRestrictedPMA <> 1	)
		BEGIN
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT 
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)		
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
			AND im.IsPma  =  1	AND IsDER = 0
        END
			
		--FOR DER
		IF( @CustRestrictedDer <> 1	)
		BEGIN
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT 
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)			
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
			AND im.IsDER  = 1	
        END

		IF( @IncludePMA = 1)
		BEGIN 
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT 
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)			
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
			AND im.IsPma  =  1	AND IsDER = 0
		END 

		IF( @IncludeDER = 1)
		BEGIN 
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT 
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)			
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
			AND im.IsDER  = 1	
		END 

		INSERT INTO #Result 
				SELECT 
				DISTINCT TOP 20 * 
				FROM #TempTable t
				ORDER BY t.PartNumber

		IF(@Idlist IS NOT NULL)
		BEGIN
			INSERT INTO #Result(PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
			SELECT DISTINCT 
					im.ItemMasterId AS PartId,
					im.partnumber AS PartNumber,
					im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ M.[Name] ELSE '' END) AS Label,
					im.PartDescription AS PartDescription,
					im.ManufacturerName AS ManufacturerName,
					(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
					WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
					WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
					ELSE 'OEM'
					END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))
		END

		SELECT DISTINCT TOP 20 r.PartId,
			r.PartNumber,
			r.PartDescription,
			r.ManufacturerName,
			r.StockType,
			r.Label
			FROM #Result r

		DROP Table #TempTable 
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
            , @AdhocComments     VARCHAR(150)    = 'SOQPartSearchAutoCompleteDropdowns' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerId, '') + ''',
													 @Parameter2 = ' + ISNULL(@CustRestrictedDer,'') + ',
													 @Parameter3 = ' + ISNULL(@CustRestrictedPMA,'') + ',
													 @Parameter4 = ' + ISNULL(@IncludeDER,'') + ',
													 @Parameter5 = ' + ISNULL(@IncludePMA,'') + ',
													 @Parameter6 = ' + ISNULL(@IncludeAlternatePN,'') + ',
													 @Parameter7 = ' + ISNULL(@IncludeEquiPN,'') + ',
													 @Parameter8 = ' + ISNULL(@partSarchText,'') + ',
													 @Parameter9 = ' + ISNULL(@Idlist,'') + ',
													 @Parameter10 = ' + ISNULL(@MasterCompanyId,'') + ''
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