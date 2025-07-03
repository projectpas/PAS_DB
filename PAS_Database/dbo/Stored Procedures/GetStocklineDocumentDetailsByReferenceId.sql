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

EXEC [GetStocklineDocumentDetailsByReferenceId]  925,1,57

**************************************************************/ 

CREATE    PROCEDURE [dbo].[GetStocklineDocumentDetailsByReferenceId]
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
				@WO_ModuleId INT = 0,
				@RO_ModuleId INT = 0,
				@MasterLoopID INT = 0,
				@ChildMasterLoopID INT,
				@ItemMasterId BIGINT = 0,
				@PartsStocklineId VARCHAR(MAX) = '';

		SELECT @Stockline_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'StockLine';
		SELECT @SO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'SalesOrder';
		SELECT @WO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'WorkOrder';
		SELECT @RO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'RepairOrder';

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
			 	  	   INSERT INTO #tmpSalesOrderStockline (StocklineId) 
			 	  	   		SELECT StocklineId
			 	  	   FROM #tmpSalesOrderStocklineV1 WITH(NOLOCK) WHERE [ID] = @ChildMasterLoopID
			 	  	   
			 	  	   SET @ChildMasterLoopID = @ChildMasterLoopID - 1;
			 	  END
			 	  
			 	  SET @MasterLoopID = @MasterLoopID - 1;
			 END

			 SELECT @PartsStocklineId = STRING_AGG([StocklineId], ',') FROM #tmpSalesOrderStockline
		END

		--WorkOrder Material Stockline Documents
		IF(@ModuleId = @WO_ModuleId)
		BEGIN
			 --WorkOrder Separate DECLARE
			 DECLARE @WorkOrderMaterialsId BIGINT = 0;
			 
			 ---START Material PN Stockline	
				--Get FROM Wo Material data
				IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterials') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWorkOrderMaterials
				END
					  	  
				CREATE TABLE #tmpWorkOrderMaterials
				(
					ID BIGINT NOT NULL IDENTITY, 
					WorkOrderMaterialsId BIGINT NULL,
					ItemMasterId BIGINT NULL
				)

				--Get FROM WO Material Stockline data
				IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialStockLine') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWorkOrderMaterialStockLine
				END
					  	  
				CREATE TABLE #tmpWorkOrderMaterialStockLine
				(
					ID BIGINT NOT NULL IDENTITY, 
					StocklineId BIGINT NULL
				)

				--Insert PN(Material) Data
				INSERT INTO #tmpWorkOrderMaterials (WorkOrderMaterialsId,ItemMasterId) 
							  SELECT WorkOrderMaterialsId,ItemMasterId
				FROM [DBO].[WorkOrderMaterials] VRP WITH(NOLOCK) 
				WHERE VRP.WorkFlowWorkOrderId = @ReferenceId;

				SELECT  @MasterLoopID = MAX(ID) FROM #tmpWorkOrderMaterials;
				WHILE(@MasterLoopID > 0)
				BEGIN
					SELECT @WorkOrderMaterialsId = WorkOrderMaterialsId,
						   @ItemMasterId = ItemMasterId
					FROM #tmpWorkOrderMaterials WITH(NOLOCK) WHERE [ID] = @MasterLoopID;

					--Truncate #tmpWorkOrderMaterialStockLine
					TRUNCATE TABLE #tmpWorkOrderMaterialStockLine;

					INSERT INTO #tmpWorkOrderMaterialStockLine (StocklineId) 
						 SELECT StocklineId
					FROM [DBO].[WorkOrderMaterialStockLine] WOST WITH(NOLOCK) 
					WHERE WOST.WorkOrderMaterialsId = @WorkOrderMaterialsId;

					SELECT  @ChildMasterLoopID = MAX(ID) FROM #tmpWorkOrderMaterialStockLine;
					WHILE(@ChildMasterLoopID > 0)
					BEGIN
						   INSERT INTO #tmpSalesOrderStockline (StocklineId) 
					   			SELECT StocklineId
						   FROM #tmpWorkOrderMaterialStockLine WITH(NOLOCK) WHERE [ID] = @ChildMasterLoopID
					   
						   SET @ChildMasterLoopID = @ChildMasterLoopID - 1;
					END
					SET @MasterLoopID = @MasterLoopID - 1;
				END
			---END Material PN Stockline

			---START KIT PN Stockline
				DECLARE @KITMasterLoopID INT = 0,
						@KITChildMasterLoopID INT,
						@WorkOrderMaterialsKitId BIGINT = 0;

				IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialsKit') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWorkOrderMaterialsKit
				END
						  	  
				CREATE TABLE #tmpWorkOrderMaterialsKit
				(
					ID BIGINT NOT NULL IDENTITY, 
					WorkOrderMaterialskitId BIGINT NULL,
					ItemMasterId BIGINT NULL
				)

				--Get FROM WOPartKIT Stockline data
				IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterialStockLineKit') IS NOT NULL
				BEGIN
					DROP TABLE #tmpWorkOrderMaterialStockLineKit
				END
						  	  
				CREATE TABLE #tmpWorkOrderMaterialStockLineKit
				(
					ID BIGINT NOT NULL IDENTITY, 
					StocklineId BIGINT NULL
				)

				--Insert PN(KIT) Data
				INSERT INTO #tmpWorkOrderMaterialsKit (WorkOrderMaterialskitId,ItemMasterId) 
							  SELECT WorkOrderMaterialskitId,ItemMasterId
				FROM [DBO].[WorkOrderMaterialsKit] WOP WITH(NOLOCK) 
				WHERE WOP.WorkFlowWorkOrderId = @ReferenceId;

				SELECT  @KITMasterLoopID = MAX(ID) FROM #tmpWorkOrderMaterialsKit;
				WHILE(@KITMasterLoopID > 0)
				BEGIN
					SELECT @WorkOrderMaterialsKitId = WorkOrderMaterialskitId,
						   @ItemMasterId = ItemMasterId
					FROM #tmpWorkOrderMaterialsKit WITH(NOLOCK) WHERE [ID] = @KITMasterLoopID;

					--Truncate #tmpWorkOrderMaterialStockLineKit
					TRUNCATE TABLE #tmpWorkOrderMaterialStockLineKit;

					INSERT INTO #tmpWorkOrderMaterialStockLineKit (StocklineId) 
						 SELECT StocklineId
					FROM [DBO].[WorkOrderMaterialStockLineKit] WOST WITH(NOLOCK) 
					WHERE WOST.WorkOrderMaterialskitId = @WorkOrderMaterialsKitId;

					SELECT  @KITChildMasterLoopID = MAX(ID) FROM #tmpWorkOrderMaterialStockLineKit;
					WHILE(@KITChildMasterLoopID > 0)
					BEGIN
						   INSERT INTO #tmpSalesOrderStockline (StocklineId) 
						   		SELECT StocklineId
						   FROM #tmpWorkOrderMaterialStockLineKit WITH(NOLOCK) WHERE [ID] = @KITChildMasterLoopID
						   
						   SET @KITChildMasterLoopID = @KITChildMasterLoopID - 1;
					END

					SET @KITMasterLoopID = @KITMasterLoopID - 1;
				END
				
			---END KIT PN Stockline

			SELECT @PartsStocklineId = STRING_AGG([StocklineId], ',') FROM #tmpSalesOrderStockline
		END

		--RepairOrder Part Stockline Documents
		ELSE IF(@ModuleId = @RO_ModuleId)
		BEGIN
			 SELECT @PartsStocklineId = STRING_AGG([StocklineId], ',') 
			 FROM [DBO].[RepairOrderPart] WITH(NOLOCK) 
			 WHERE RepairOrderId = @ReferenceId 
			 AND MasterCompanyId = @MasterCompanyId
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