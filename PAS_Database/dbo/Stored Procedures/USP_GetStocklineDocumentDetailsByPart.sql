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
		DECLARE @SOQuote_ModuleId INT = 0,
				@SO_ModuleId INT = 0,
				@ESO_ModuleId INT = 0,
				@ESOQuote_ModuleId INT = 0,
				@WO_ModuleId INT = 0,
				@MasterLoopID INT = 0,
				@ChildMasterLoopID INT,
				@PartsStocklineId VARCHAR(MAX) = '',
				@Stockline_ModuleId INT = 0;

		SELECT @Stockline_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'StockLine';
		SELECT @SOQuote_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'SalesQuote';
		SELECT @SO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'SalesOrder';
		SELECT @ESO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'ExchangeSalesOrder';
		SELECT @ESOQuote_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'ExchangeQuote';
		SELECT @WO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'WorkOrder';

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
		
		--Salesorder Part Stockline Documents
		IF(@ModuleId = @SO_ModuleId)
		BEGIN
			 --Salesorder Separate DECLARE 
			 DECLARE @SalesOrderPartId BIGINT = 0;
	
			 --Get FROM SOPart data
			 IF OBJECT_ID(N'tempdb..#tmpSalesOrderPartV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpSalesOrderPartV1
			 END
			 		  	  
			 CREATE TABLE #tmpSalesOrderPartV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	SalesOrderPartId BIGINT NULL
			 )
			 
			 --Get FROM SOPart Stockline data
			 IF OBJECT_ID(N'tempdb..#tmpSalesOrderStocklineV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpSalesOrderStocklineV1
			 END
			 		  	  
			 CREATE TABLE #tmpSalesOrderStocklineV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	StocklineId BIGINT NULL
			 )		 
			 
			 INSERT INTO #tmpSalesOrderPartV1(SalesOrderPartId) SELECT ([Value]) FROM @PartsId

			 SELECT  @MasterLoopID = MAX(ID) FROM #tmpSalesOrderPartV1;
			 WHILE(@MasterLoopID > 0)
			 BEGIN
			 	  SELECT @SalesOrderPartId = SalesOrderPartId
			 	  FROM #tmpSalesOrderPartV1 WITH(NOLOCK) WHERE [ID] = @MasterLoopID;
			 	  
			 	  --Truncate #tmpSalesOrderStocklineV1
			 	  TRUNCATE TABLE #tmpSalesOrderStocklineV1;
			 	  
			 	  INSERT INTO #tmpSalesOrderStocklineV1 (StocklineId) 
			 	  	   SELECT StocklineId
			 	  FROM [DBO].[SalesOrderStocklineV1] SOST WITH(NOLOCK) 
			 	  WHERE SOST.SalesOrderPartId = @SalesOrderPartId;
			 	  
			 	  SELECT  @ChildMasterLoopID = MAX(ID) FROM #tmpSalesOrderStocklineV1;
			 	  WHILE(@ChildMasterLoopID > 0)
			 	  BEGIN
			 	  	   INSERT INTO #tmpSalesOrderStockline (StocklineId) 
			 	  	   		SELECT StocklineId
			 	  	   FROM #tmpSalesOrderStocklineV1 WITH(NOLOCK) WHERE [ID] = @ChildMasterLoopID
			 	  	   
			 	  	   SET @ChildMasterLoopID = @ChildMasterLoopID - 1;
			 	  END
			 	  
			 	  SET @MasterLoopID = @MasterLoopID - 1;
			 END

			 SELECT @PartsStocklineId = STRING_AGG([StocklineId], ',') FROM #tmpSalesOrderStockline
		END

		IF(@ModuleId = @ESO_ModuleId)
		BEGIN
			 --Salesorder Separate DECLARE 
			 DECLARE @ExchSalesOrderPartId BIGINT = 0;
	
			 --Get FROM SOPart data
			 IF OBJECT_ID(N'tempdb..#tmpExchSalesOrderPartV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpExchSalesOrderPartV1
			 END
			 		  	  
			 CREATE TABLE #tmpExchSalesOrderPartV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	ExchangeSalesOrderPartId BIGINT NULL
			 )
			 
			 --Get FROM SOPart Stockline data
			 IF OBJECT_ID(N'tempdb..#tmpExchSalesOrderStocklineV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpExchSalesOrderStocklineV1
			 END
			 		  	  
			 CREATE TABLE #tmpExchSalesOrderStocklineV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	StocklineId BIGINT NULL
			 )		 
			 
			 INSERT INTO #tmpExchSalesOrderPartV1(ExchangeSalesOrderPartId) SELECT ([Value]) FROM @PartsId

			 SELECT  @MasterLoopID = MAX(ID) FROM #tmpExchSalesOrderPartV1;
			 WHILE(@MasterLoopID > 0)
			 BEGIN
			 	  SELECT @ExchSalesOrderPartId = ExchangeSalesOrderPartId
			 	  FROM #tmpExchSalesOrderPartV1 WITH(NOLOCK) WHERE [ID] = @MasterLoopID;
			 	  
			 	  --Truncate #tmpExchSalesOrderStocklineV1
			 	  TRUNCATE TABLE #tmpExchSalesOrderStocklineV1;
			 	  
			 	  INSERT INTO #tmpExchSalesOrderStocklineV1 (StocklineId) 
			 	  	   SELECT StocklineId
			 	  FROM [DBO].[ExchangeSalesOrderStockLine] SOST WITH(NOLOCK) 
			 	  WHERE SOST.ExchangeSalesOrderPartId = @ExchSalesOrderPartId;
			 	  
			 	  SELECT  @ChildMasterLoopID = MAX(ID) FROM #tmpExchSalesOrderStocklineV1;
			 	  WHILE(@ChildMasterLoopID > 0)
			 	  BEGIN
			 	  	   INSERT INTO #tmpSalesOrderStockline (StocklineId) 
			 	  	   		SELECT StocklineId
			 	  	   FROM #tmpExchSalesOrderStocklineV1 WITH(NOLOCK) WHERE [ID] = @ChildMasterLoopID
			 	  	   
			 	  	   SET @ChildMasterLoopID = @ChildMasterLoopID - 1;
			 	  END
			 	  
			 	  SET @MasterLoopID = @MasterLoopID - 1;
			 END

			 SELECT @PartsStocklineId = STRING_AGG([StocklineId], ',') FROM #tmpSalesOrderStockline
		END

		--Exchange Quote Part Stockline Documents
		IF(@ModuleId = @ESOQuote_ModuleId)
		BEGIN
			 --Salesorder Separate DECLARE 
			 DECLARE @ExchangeQuotePartId BIGINT = 0;
	
			 --Get FROM SOPart data
			 IF OBJECT_ID(N'tempdb..#tmpExchSalesOrderQuotePartV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpExchSalesOrderQuotePartV1
			 END
			 		  	  
			 CREATE TABLE #tmpExchSalesOrderQuotePartV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	ExchangeQuotePartId BIGINT NULL
			 )
			 
			 --Get FROM SOPart Stockline data
			 IF OBJECT_ID(N'tempdb..#tmpExchSalesOrderQuoteStocklineV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpExchSalesOrderQuoteStocklineV1
			 END
			 		  	  
			 CREATE TABLE #tmpExchSalesOrderQuoteStocklineV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	StocklineId BIGINT NULL
			 )		 
			 
			 INSERT INTO #tmpExchSalesOrderQuotePartV1(ExchangeQuotePartId) SELECT ([Value]) FROM @PartsId

			 SELECT  @MasterLoopID = MAX(ID) FROM #tmpExchSalesOrderQuotePartV1;
			 WHILE(@MasterLoopID > 0)
			 BEGIN
			 	  SELECT @ExchangeQuotePartId = ExchangeQuotePartId
			 	  FROM #tmpExchSalesOrderQuotePartV1 WITH(NOLOCK) WHERE [ID] = @MasterLoopID;
			 	  
			 	  --Truncate #tmpExchSalesOrderQuoteStocklineV1
			 	  TRUNCATE TABLE #tmpExchSalesOrderQuoteStocklineV1;
			 	  
			 	  INSERT INTO #tmpExchSalesOrderQuoteStocklineV1 (StocklineId) 
			 	  	   SELECT StocklineId
			 	  FROM [DBO].[ExchangeQuotePart] SOST WITH(NOLOCK) 
			 	  WHERE SOST.ExchangeQuotePartId = @ExchangeQuotePartId;
			 	  
			 	  SELECT  @ChildMasterLoopID = MAX(ID) FROM #tmpExchSalesOrderQuoteStocklineV1;
			 	  WHILE(@ChildMasterLoopID > 0)
			 	  BEGIN
			 	  	   INSERT INTO #tmpSalesOrderStockline (StocklineId) 
			 	  	   		SELECT StocklineId
			 	  	   FROM #tmpExchSalesOrderQuoteStocklineV1 WITH(NOLOCK) WHERE [ID] = @ChildMasterLoopID
			 	  	   
			 	  	   SET @ChildMasterLoopID = @ChildMasterLoopID - 1;
			 	  END
			 	  
			 	  SET @MasterLoopID = @MasterLoopID - 1;
			 END

			 SELECT @PartsStocklineId = STRING_AGG([StocklineId], ',') FROM #tmpSalesOrderStockline
		END

		IF(@ModuleId = @WO_ModuleId)
		BEGIN
			 --WorkOrder Separate DECLARE
			 DECLARE @WorkOrderMPNId BIGINT = 0;
			 DECLARE @MaxId BIGINT = 0;
			 
			 --Get FROM WOPart data
			 IF OBJECT_ID(N'tempdb..#tmpWOMPNPart') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpWOMPNPart
			 END
			 		  	  
			 CREATE TABLE #tmpWOMPNPart
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	MPNId BIGINT NULL
			 )

			 INSERT INTO #tmpWOMPNPart(MPNId) SELECT ([Value]) FROM @PartsId
			 
			 SELECT @MaxId = MAX(ID) FROM #tmpWOMPNPart
			 WHILE(@MaxId > 0)
			 BEGIN
				SELECT @WorkOrderMPNId = MPNId
			 	  FROM #tmpWOMPNPart WITH(NOLOCK) WHERE [ID] = @MaxId;

				INSERT INTO #tmpSalesOrderStockline (StocklineId)
				SELECT StockLineId
				FROM [DBO].[WorkOrderPartNumber] VRP WITH(NOLOCK) 
				WHERE VRP.ID = @WorkOrderMPNId;

				SET @MaxId = @MaxId - 1;
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