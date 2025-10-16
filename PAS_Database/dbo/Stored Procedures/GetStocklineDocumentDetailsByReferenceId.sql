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
    2     18-07-2025   Vishal Suthar	Added module for exchange sales order
    3     07-08-2025   Vishal Suthar	Added module for exchange quote, sales quote and vendor rma
    4     24-09-2025   Bhargav Saliya	Added module for SWO
	5     15-10-2025   Bhargav Saliya   Added Receiving Customer Documnet Case

EXEC [GetStocklineDocumentDetailsByReferenceId]  1139,1,46

**************************************************************/ 

CREATE     PROCEDURE [dbo].[GetStocklineDocumentDetailsByReferenceId]
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
				@WorkOrderId BIGINT = 0,
				@ESO_ModuleId INT = 0,
				@ESOQuote_ModuleId INT = 0,
				@SOQuote_ModuleId INT = 0,
				@VendorRMA_ModuleId INT = 0,
				@PartsStocklineId VARCHAR(MAX) = '',
				@SWO_ModuleId INT = 0,
				@ReceivingCustomerWork_ModuleId INT = 0;

		SELECT @Stockline_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'StockLine';
		SELECT @SO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'SalesOrder';
		SELECT @WO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'WorkOrder';
		SELECT @RO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'RepairOrder';
		SELECT @ESO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'ExchangeSalesOrder';
		SELECT @ESOQuote_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'ExchangeQuote';
		SELECT @SOQuote_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'SalesQuote';
		SELECT @VendorRMA_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'VendorRMA';
		SELECT @SWO_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'SubWorkOrder';
		SELECT @ReceivingCustomerWork_ModuleId = [AttachmentModuleId] FROM DBO.AttachmentModule WITH(NOLOCK) WHERE [Name] = 'ReceivingCustomerWork';

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

		--Sales Order Quote Part Stockline Documents
		IF(@ModuleId = @SOQuote_ModuleId)
		BEGIN
			 --Sales Order Quote Separate DECLARE 
			 DECLARE @SalesOrderQuotePartId BIGINT = 0;
	
			 --Get FROM SOPart data
			 IF OBJECT_ID(N'tempdb..#tmpSalesOrderQuotePartV1') IS NOT NULL
			 BEGIN
			 	DROP TABLE #tmpSalesOrderQuotePartV1
			 END
			 		  	  
			 CREATE TABLE #tmpSalesOrderQuotePartV1
			 (
			 	ID BIGINT NOT NULL IDENTITY, 
			 	SalesOrderQuotePartId BIGINT NULL,
			 	ItemMasterId BIGINT NULL
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
			 
			 INSERT INTO #tmpSalesOrderQuotePartV1 (SalesOrderQuotePartId,ItemMasterId) 
				  SELECT SalesOrderQuotePartId,ItemMasterId
			 FROM [DBO].[SalesOrderQuotePartV1] VRP WITH(NOLOCK) 
			 WHERE VRP.SalesOrderQuoteId = @ReferenceId;

			 SELECT  @MasterLoopID = MAX(ID) FROM #tmpSalesOrderQuotePartV1;
			 WHILE(@MasterLoopID > 0)
			 BEGIN
			 	  SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId,
			 	  	     @ItemMasterId = ItemMasterId
			 	  FROM #tmpSalesOrderQuotePartV1 WITH(NOLOCK) WHERE [ID] = @MasterLoopID;
			 	  
			 	  --Truncate #tmpSalesOrderQuoteStocklineV1
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

		--WorkOrder Material Stockline Documents
		IF(@ModuleId = @WO_ModuleId)
		BEGIN
			 --WorkOrder Separate DECLARE
			 DECLARE @WorkOrderMaterialsId BIGINT = 0;
			 
			 ---START Material PN Stockline	

				--Get WorkorderId from Workflow table,
				SELECT @WorkOrderId = WorkOrderId FROM [DBO].[WorkOrderWorkFlow] WITH(NOLOCK) 
				WHERE [WorkFlowWorkOrderId] = @ReferenceId;

				--Insert PN(Material) Data
				INSERT INTO #tmpSalesOrderStockline (StocklineId) 
							  SELECT VRP.StockLineId
				FROM [DBO].[WorkOrderMaterialStockLine] VRP WITH(NOLOCK) 
				JOIN [DBO].[WorkOrderMaterials] MST WITH(NOLOCK) ON MST.WorkOrderMaterialsId = VRP.WorkOrderMaterialsId
				WHERE MST.WorkOrderId = @WorkOrderId; -- get workorderid

				INSERT INTO #tmpSalesOrderStockline (StocklineId) 
							  SELECT StockLineId
				FROM [DBO].[WorkOrderPartNumber] VRP WITH(NOLOCK) 
				WHERE VRP.WorkOrderId = @WorkOrderId; -- get workorderid

			---END Material PN Stockline

			---START KIT PN Stockline
				INSERT INTO #tmpSalesOrderStockline (StocklineId) 
							  SELECT MST.StockLineId
				FROM [DBO].[WorkOrderMaterialStockLineKit] MST WITH(NOLOCK) 
				JOIN [DBO].[WorkOrderMaterialsKit] VRP WITH(NOLOCK) ON MST.WorkOrderMaterialsKitId = VRP.WorkOrderMaterialsKitId
				WHERE VRP.WorkOrderId = @WorkOrderId; -- get workorderid
			---END KIT PN Stockline

			--for ReceivingCustomerWork---
			INSERT INTO #tmpSalesOrderStockline (StocklineId)
			SELECT cd.ReferenceId
				FROM ReceivingCustomerWork rcw
				INNER JOIN CommonDocumentDetails cd on cd.ReferenceId = rcw.ReceivingCustomerWorkId AND ModuleId = @ReceivingCustomerWork_ModuleId
			WHERE WorkOrderId = @WorkOrderId

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

		IF(@ModuleId = @SWO_ModuleId)
		BEGIN			
			DECLARE @SWOPartId BIGINT = 0;
			 ---START Material PN Stockline	
			 SELECT @SWOPartId = SubWorkOrderId FROM [DBO].SubWorkOrderPartNumber WITH(NOLOCK) 
			 WHERE SubWOPartNoId = @ReferenceId

				--Insert PN(Material) Data
				INSERT INTO #tmpSalesOrderStockline (StocklineId) 
							  SELECT VRP.StockLineId
				FROM [DBO].[SubWorkOrderMaterialStockLine] VRP WITH(NOLOCK) 
				JOIN [DBO].[SubWorkOrderMaterials] MST WITH(NOLOCK) ON MST.SubWorkOrderMaterialsId = VRP.SubWorkOrderMaterialsId
				WHERE MST.SubWorkOrderId = @SWOPartId; -- get workorderid

				INSERT INTO #tmpSalesOrderStockline (StocklineId) 
							  SELECT StockLineId
				FROM [DBO].[SubWorkOrderPartNumber] VRP WITH(NOLOCK) 
				WHERE VRP.SubWorkOrderId = @SWOPartId; -- get workorderid

			---END Material PN Stockline

			---START KIT PN Stockline
				INSERT INTO #tmpSalesOrderStockline (StocklineId) 
							  SELECT MST.StockLineId
				FROM [DBO].[SubWorkOrderMaterialStockLineKit] MST WITH(NOLOCK) 
				JOIN [DBO].[SubWorkOrderMaterialsKit] VRP WITH(NOLOCK) ON MST.SubWorkOrderMaterialsKitId = VRP.SubWorkOrderMaterialsKitId
				WHERE VRP.SubWorkOrderId = @SWOPartId; -- get workorderid
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

		--Exchange Sales Order Part Stockline Documents
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
			 	ExchangeSalesOrderPartId BIGINT NULL,
			 	ItemMasterId BIGINT NULL
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
			 
			 INSERT INTO #tmpExchSalesOrderPartV1 (ExchangeSalesOrderPartId,ItemMasterId) 
				  SELECT ExchangeSalesOrderPartId,ItemMasterId
			 FROM [DBO].[ExchangeSalesOrderPart] VRP WITH(NOLOCK) 
			 WHERE VRP.ExchangeSalesOrderId = @ReferenceId;

			 SELECT  @MasterLoopID = MAX(ID) FROM #tmpExchSalesOrderPartV1;
			 WHILE(@MasterLoopID > 0)
			 BEGIN
			 	  SELECT @ExchSalesOrderPartId = ExchangeSalesOrderPartId,
			 	  	     @ItemMasterId = ItemMasterId
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
			 	ExchangeQuotePartId BIGINT NULL,
			 	ItemMasterId BIGINT NULL
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
			 
			 INSERT INTO #tmpExchSalesOrderQuotePartV1 (ExchangeQuotePartId,ItemMasterId) 
				  SELECT ExchangeQuotePartId,ItemMasterId
			 FROM [DBO].[ExchangeQuotePart] VRP WITH(NOLOCK) 
			 WHERE VRP.ExchangeQuoteId = @ReferenceId;

			 SELECT  @MasterLoopID = MAX(ID) FROM #tmpExchSalesOrderQuotePartV1;
			 WHILE(@MasterLoopID > 0)
			 BEGIN
			 	  SELECT @ExchangeQuotePartId = ExchangeQuotePartId,
			 	  	     @ItemMasterId = ItemMasterId
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

		--Vendor RMA Stockline Documents
		IF(@ModuleId = @VendorRMA_ModuleId)
		BEGIN
			 SELECT @PartsStocklineId = STRING_AGG([StocklineId], ',') 
			 FROM [DBO].[VendorRMADetail] WITH(NOLOCK) 
			 WHERE VendorRMAId = @ReferenceId 
			 AND MasterCompanyId = @MasterCompanyId
		END

		--For Common Select Doc for All Module (SO/WO/RO)
		IF(@ModuleId = @WO_ModuleId)
		BEGIN
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
			AND ISNULL(cdd.IsActive,1) = 1 
			AND ISNULL(cdd.IsDeleted,0) = 0
			AND cdd.ModuleId in(@Stockline_ModuleId,@ReceivingCustomerWork_ModuleId)
		END
		ELSE
		BEGIN
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
			AND ISNULL(cdd.IsActive,1) = 1 
			AND ISNULL(cdd.IsDeleted,0) = 0
			AND cdd.ModuleId = @Stockline_ModuleId
		END
		
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