/*************************************************************           
 ** File:  [USP_GetStocklineDocumentDetailsByPart]  
 ** Author:   Bhargav Saliya
 ** Description: Retrieve Documents list based on PartId
 ** Purpose:         
 ** Date:   30-06-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR     Date         Author		     	Change Description            
 ** --    --------     -------			-------------------------------          
    1     04-06-2025   Bhargav Saliya		Created

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetStocklineDocumentDetailsByPart]
	@ModuleId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL,
	@PartsId TVP_BigInt READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 
		DECLARE @SOQuote_ModuleId INT = 0,@MasterLoopID INT = 0,@ChildMasterLoopID INT,@PartsStocklineId VARCHAR(MAX) = '',@Stockline_ModuleId INT = 0;

		SELECT @Stockline_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'StockLine';
		SELECT @SOQuote_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'SalesQuote';

		--Common Get FROM Stockline data
		IF OBJECT_ID(N'tempdb..#tmpSalesOrderStockline') IS NOT NULL
		BEGIN
			DROP TABLE #tmpSalesOrderStockline
		END
				  	  
		CREATE TABLE #tmpSalesOrderStockline
		(
			ID BIGINT NOT NULL IDENTITY, 
			StocklineId BIGINT NULL
		)
		IF(@ModuleId = @SOQuote_ModuleId)
		BEGIN
			 --Sales Order Quote Separate DECLARE 
			 DECLARE @SalesOrderQuotePartId BIGINT = 0;
	
			--Get FROM SOPart data
			IF OBJECT_ID(N'tempdb..#tmpSalesOrderQuoteParts') IS NOT NULL
			BEGIN
				DROP TABLE #tmpSalesOrderQuoteParts
			END

			CREATE TABLE #tmpSalesOrderQuoteParts
			(
				ID BIGINT NOT NULL IDENTITY, 
				SalesOrderQuotePartId BIGINT NULL,
			)
			 
			 --Get FROM SOQPart Stockline data
			 IF OBJECT_ID(N'tempdb..#tmpSalesOrderQuoteStocklineV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpSalesOrderQuoteStocklineV1
			 END
			 		  	  
			 CREATE TABLE #tmpSalesOrderQuoteStocklineV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	StocklineId BIGINT NULL
			 )		 
			 
			 INSERT INTO #tmpSalesOrderQuoteParts(SalesOrderQuotePartId) SELECT ([Value]) FROM @PartsId

			 SELECT  @MasterLoopID = MAX(ID) FROM #tmpSalesOrderQuoteParts;
			 WHILE(@MasterLoopID > 0)
			 BEGIN
			 	  SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId
			 	  FROM #tmpSalesOrderQuoteParts WITH(NOLOCK) WHERE [ID] = @MasterLoopID;
			 	  
			 	  TRUNCATE TABLE #tmpSalesOrderQuoteStocklineV1;
			 	  
			 	  INSERT INTO #tmpSalesOrderQuoteStocklineV1 (StocklineId) 
			 	  	   SELECT StocklineId
			 	  FROM [DBO].[SalesOrderQuoteStocklineV1] SOST WITH(NOLOCK) 
			 	  WHERE SOST.SalesOrderQuotePartId = @SalesOrderQuotePartId;
			 	  
			 	  SELECT  @ChildMasterLoopID = MAX(ID) FROM #tmpSalesOrderQuoteStocklineV1;
			 	  WHILE(@ChildMasterLoopID > 0)
			 	  BEGIN
			 	  	   INSERT INTO #tmpSalesOrderStockline (StocklineId) 
			 	  	   		SELECT StocklineId
			 	  	   FROM #tmpSalesOrderQuoteStocklineV1 WITH(NOLOCK) WHERE [ID] = @ChildMasterLoopID
			 	  	   
			 	  	   SET @ChildMasterLoopID = @ChildMasterLoopID - 1;
			 	  END
			 	  
			 	  SET @MasterLoopID = @MasterLoopID - 1;
			 END

			 SELECT @PartsStocklineId = STRING_AGG([StocklineId], ',') FROM #tmpSalesOrderStockline
		END		
		
		--For Common Select Doc for All Module (SO/WO/RO)
		SELECT cdd.DocName, 
			   cdd.IsActive,
			   cdd.IsDeleted, 
			   ad.FileName,
			   ad.FileType,
			   ad.Link,
			   ad.FileSize, 
			   ad.AttachmentId , 
			   ad.AttachmentDetailId
		FROM DBO.AttachmentDetails ad WITH(NOLOCK)
		INNER JOIN DBO.CommonDocumentDetails cdd WITH(NOLOCK) ON ad.AttachmentId = cdd.AttachmentId
		WHERE cdd.MasterCompanyId = @MasterCompanyId
		AND cdd.ReferenceId IN(SELECT ITEM FROM DBO.SplitString(@PartsStocklineId,',')) 
		AND cdd.IsActive = 1 
		AND cdd.IsDeleted = 0 
		AND cdd.ModuleId = @Stockline_ModuleId

	END TRY
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = '[USP_GetStocklineDocumentDetailsByPart]' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH 
END