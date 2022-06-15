/*************************************************************           
 ** File:   [WOPartSearchAutoCompleteDropdowns]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Search WO Part for add to Materials List
 ** Purpose:         
 ** Date:   17/11/2021       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    17/11/2021   Hemant Saliya Created
     
--EXEC [WOPartSearchAutoCompleteDropdowns] 5
**************************************************************/
CREATE PROCEDURE [dbo].[WOAddPNPartSearchAutoCompleteDropdowns]  
  @CustomerId INT,
  @RestrictDER BIT = 0 ,
  @RestrictPMA BIT = 0,
  @IncludeAlternatePN BIT = NULL,
  @IncludeEquiPN BIT = NULL,
  @PartSarchText VARCHAR(50) = '',
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
					PartDescription VARCHAR(MAX),
					StockType VARCHAR(50))

		IF OBJECT_ID(N'tempdb..#Result') IS NOT NULL
		BEGIN
			DROP TABLE #Result 
		END

		CREATE TABLE #Result(      
						PartId BIGINT,      
						PartNumber VARCHAR(MAX),
						PartDescription VARCHAR(MAX),
						StockType VARCHAR(50)) 
	
		--- FOR OEM
		INSERT INTO #TempTable (PartId, PartNumber, PartDescription, StockType)
		SELECT DISTINCT 
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			im.PartDescription AS PartDescription,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)			
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
			AND im.IsOEM = 1 AND IsDER = 0

		--FOR PMA
		IF( @RestrictPMA <> 1	)
		BEGIN
		INSERT INTO #TempTable (PartId, PartNumber, PartDescription, StockType)
		SELECT DISTINCT 
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			im.PartDescription AS PartDescription,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)			
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
			AND im.IsPma  =  1	AND IsDER = 0
        END
			
		--FOR DER
		IF( @RestrictDER <> 1	)
		BEGIN
		INSERT INTO #TempTable (PartId, PartNumber, PartDescription, StockType)
		SELECT DISTINCT 
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			im.PartDescription AS PartDescription,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)			
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
			AND im.IsDER  = 1	
        END

		--IF( @IncludePMA = 1)
		--BEGIN 
		--INSERT INTO #TempTable (PartId, PartNumber, PartDescription, StockType)
		--SELECT DISTINCT 
		--	im.ItemMasterId AS PartId,
		--	im.partnumber AS PartNumber,
		--	im.PartDescription AS PartDescription,
		--	(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
		--	WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
		--	WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
		--	ELSE 'OEM'
		--	END) AS StockType
		--	FROM DBO.ItemMaster im WITH(NOLOCK)	
		--		 INNER JOIN [dbo].[RestrictedParts] rpDER WITH(NOLOCK) ON 
		--					im.ItemMasterId = rpDER.ItemMasterId
		--					AND rpDER.PartType = 'PMA' 
		--					AND rpDER.ReferenceId  = @CustomerId 
		--					AND rpDER.ModuleId = 1--This is wrong actully Module id in restricted part itself is coming wrong
		--					AND rpDER.IsActive = 1
		--					AND rpDER.IsDeleted = 0
		--	WHERE im.IsActive = 1
		--	AND im.IsDeleted = 0
		--	AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
		--	AND im.MasterCompanyId = @MasterCompanyId
		--	AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
		--END 

		--IF( @IncludeDER = 1)
		--BEGIN 
		--INSERT INTO #TempTable (PartId, PartNumber, PartDescription, StockType)
		--SELECT DISTINCT 
		--	im.ItemMasterId AS PartId,
		--	im.partnumber AS PartNumber,
		--	im.PartDescription AS PartDescription,
		--	(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
		--	WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
		--	WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
		--	ELSE 'OEM'
		--	END) AS StockType
		--	FROM DBO.ItemMaster im WITH(NOLOCK)	
		--		 INNER JOIN [dbo].[RestrictedParts] rpDER WITH(NOLOCK) ON 
		--					im.ItemMasterId = rpDER.ItemMasterId
		--					AND rpDER.PartType = 'DER' 
		--					AND rpDER.ReferenceId  = @CustomerId 
		--					AND rpDER.ModuleId = 1--This is wrong actully Module id in restricted part itself is coming wrong
		--					AND rpDER.IsActive = 1
		--					AND rpDER.IsDeleted = 0
		--	WHERE im.IsActive = 1
		--	AND im.IsDeleted = 0
		--	AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
		--	AND im.MasterCompanyId = @MasterCompanyId
		--	AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')
		--END 

		INSERT INTO #Result 
				SELECT 
				DISTINCT TOP 20 * 
				FROM #TempTable t
				ORDER BY t.PartNumber

		IF(@Idlist IS NOT NULL)
		BEGIN
			INSERT INTO #Result(PartId, PartNumber, PartDescription, StockType)
			SELECT DISTINCT 
					im.ItemMasterId AS PartId,
					im.partnumber AS PartNumber,
					im.PartDescription AS PartDescription,
					(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER' 
					WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
					WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
					ELSE 'OEM'
					END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			WHERE im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))
		END

		SELECT DISTINCT TOP 20 
			r.PartId,
			r.PartNumber,
			r.PartDescription,
			r.StockType
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
            , @AdhocComments     VARCHAR(150)    = 'WOPartSearchAutoCompleteDropdowns' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerId, '') + ''',
													 @Parameter2 = ' + ISNULL(@RestrictDER,'') + ',
													 @Parameter3 = ' + ISNULL(@RestrictPMA,'') + ',
													 @Parameter4 = ' + ISNULL(@IncludeAlternatePN,'') + ',
													 @Parameter5 = ' + ISNULL(@IncludeEquiPN,'') + ',
													 @Parameter6 = ' + ISNULL(@PartSarchText,'') + ',
													 @Parameter7 = ' + ISNULL(@Idlist,'') + ',
													 @Parameter8 = ' + ISNULL(@MasterCompanyId,'') + ''
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