/*************************************************************           
 ** File:  [GetStocklineDocumentDetailsByReferenceId]  
 ** Author:   Amit Ghediya
 ** Description: Retrieve Documents list based on refferenceId
 ** Purpose:         
 ** Date:   30-06-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR     Date         Author		     	Change Description            
 ** --    --------     -------			-------------------------------          
    1     30-06-2025   Amit Ghediya		Created

EXEC [GetStocklineDocumentDetailsByReferenceId] '201842,201854,201855', 1 , 53
EXEC [GetStocklineDocumentDetailsByReferenceId]  925,1,57

**************************************************************/ 

CREATE    PROCEDURE [dbo].[GetStocklineDocumentDetailsByReferenceId]
	--@ReferenceId VARCHAR(MAX) = NULL,
	@ReferenceId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL,
	@ModuleId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 

		DECLARE @Stockline_ModuleId INT = 0,
				@SO_ModuleId INT = 0,
				@WO_ModuleId INT = 0;

		SELECT @Stockline_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'StockLine';
		SELECT @SO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'SalesOrder';
		SELECT @WO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'WorkOrder';
		
		--Salesorder Part Stockline Documents
		IF(@ModuleId = @SO_ModuleId)
		BEGIN
			 --Salesorder Separate DECLARE 
			 DECLARE @MasterLoopID INT = 0,
					 @ChildMasterLoopID INT,
					 @SalesOrderPartId BIGINT = 0,
					 @ItemMasterId BIGINT = 0,
					 --@StocklineId BIGINT = 0,
					 @PartsStocklineId VARCHAR(MAX) = '';
	
			 --Get FROM SOPart data
			 IF OBJECT_ID(N'tempdb..#tmpSalesOrderPartV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpSalesOrderPartV1
			 END
			 		  	  
			 CREATE TABLE #tmpSalesOrderPartV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	SalesOrderPartId BIGINT NULL,
			 	ItemMasterId BIGINT NULL
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
			 
			 --Get FROM Stockline data
			 IF OBJECT_ID(N'tempdb..#tmpSalesOrderStockline') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpSalesOrderStockline
			 END
			 		  	  
			 CREATE TABLE #tmpSalesOrderStockline
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	StocklineId BIGINT NULL
			 )

			 INSERT INTO #tmpSalesOrderPartV1 (SalesOrderPartId,ItemMasterId) 
				  SELECT SalesOrderPartId,ItemMasterId
			 FROM [DBO].[SalesOrderPartV1] VRP WITH(NOLOCK) 
			 WHERE VRP.SalesOrderId = @ReferenceId;

			 SELECT  @MasterLoopID = MAX(ID) FROM #tmpSalesOrderPartV1;
			 WHILE(@MasterLoopID > 0)
			 BEGIN
			 	  SELECT @SalesOrderPartId = SalesOrderPartId,
			 	  	     @ItemMasterId = ItemMasterId
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
			 	  	   --SELECT @StocklineId = StockLineId
			 	  	   --FROM #tmpSalesOrderStocklineV1 WITH(NOLOCK) WHERE [ID] = @ChildMasterLoopID;
			 	  	   
			 	  	   INSERT INTO #tmpSalesOrderStockline (StocklineId) 
			 	  	   		SELECT StocklineId
			 	  	   FROM #tmpSalesOrderStocklineV1 WITH(NOLOCK) WHERE [ID] = @ChildMasterLoopID
			 	  	   
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
            , @AdhocComments     VARCHAR(150)    = '[GetStocklineDocumentDetailsByReferenceId]' 
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