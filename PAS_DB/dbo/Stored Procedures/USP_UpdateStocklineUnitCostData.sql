/*************************************************************           
 ** File:   [USP_UpdateStocklineUnitCostData]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to update stockline unitcost data.
 ** Purpose:         
 ** Date:   07/13/2022      
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/13/2023  Amit Ghediya     Created
	2    07/14/2023  Amit Ghediya     Added records in StocklineAdjustment
     
-- EXEC USP_UpdateStocklineUnitCostData
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateStocklineUnitCostData]  
	@tbl_StockLineBulkUpload StockLineBulkUploadType READONLY
AS  
BEGIN  
   
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN  
		DECLARE @TotalCounts INT,@count INT,@StkTotalCounts INT,@Stkcount INT,@isValid INT,@partNumber VARCHAR(250),@partDescription NVARCHAR(MAX),
				@manufacturerName VARCHAR(100),@condition VARCHAR(256),@UnitCost DECIMAL(18,2),@StkUnitCost DECIMAL(18,2),@StkMasterCompanyId INT,@StkUnitCostAdjustmnet DECIMAL(18,2),
				@StockLineId BIGINT,@tmpStockLineBulkUploadId BIGINT,@StkQuantity INT,@StkPurchaseOrderUnitCost DECIMAL(18,2),@StkRepairOrderUnitCost DECIMAL(18,2),@StkAdjustmentDataTypeId INT,
				@createdBy VARCHAR(100),@masterCompanyId INT;
		SET @count = 1;
		SET @Stkcount = 1;
		SET @StkAdjustmentDataTypeId = 11; --For UnitCost

		IF OBJECT_ID(N'tempdb..#StockLineBulkUploadType') IS NOT NULL  
		BEGIN  
			DROP TABLE #StockLineBulkUploadType  
		END

		IF OBJECT_ID(N'tempdb..#StockLineBulkUploadReturn') IS NOT NULL  
		BEGIN  
			DROP TABLE #StockLineBulkUploadReturn   
		END 
		
		-- For inernal used
		CREATE TABLE #StockLineBulkUploadType   
		(  
		 ID BIGINT NOT NULL IDENTITY,   
		 [partNumber] [varchar](250) NULL,
		 [partDescription] [nvarchar](max) NULL,
		 [manufacturerName] [varchar](100) NULL,
		 [condition] [varchar](256) NULL,
		 [unitCost] [decimal](18, 2) NULL,
		 [message] [varchar](100) NULL,
		 [srno] [varchar](100) NULL,
		 [tmpStockLineBulkUploadId] [bigint] NULL,
		 [createdBy] [varchar](100) NULL,
		 [masterCompanyId] [int] NULL,
		);

		CREATE TABLE #StockLineBulkUploadReturn   
		(  
		 ID BIGINT NOT NULL IDENTITY,   
		 [StockLineId] [bigint] NULL,
		 [Quantity] [int] NULL,
		 [PurchaseOrderUnitCost] [decimal](18, 2) NULL,
		 [RepairOrderUnitCost] [decimal](18, 2) NULL,
		 [unitCost] [decimal](18, 2) NULL,
		 [createdBy] [varchar](100) NULL,
		 [MasterCompanyId] [INT] NULL,
		);  
		
		INSERT INTO #StockLineBulkUploadType ([partNumber],[partDescription],[manufacturerName],[condition],[unitCost],[message],[srno],[tmpStockLineBulkUploadId],[createdBy],[masterCompanyId] )  
			SELECT [partNumber],[partDescription],[manufacturerName],[condition],[unitCost],[message],[srno],[tmpStockLineBulkUploadId],[createdBy],[masterCompanyId]
		FROM TmpStockLineBulkUpload WHERE message = 'Valid Records';

		SELECT @TotalCounts = COUNT(ID) FROM #StockLineBulkUploadType;
		WHILE @count<= @TotalCounts
		BEGIN 
			SELECT @UnitCost= unitCost,@partNumber = partNumber, @partDescription = partDescription, @manufacturerName = manufacturerName,@condition = condition, @createdBy = createdBy, @masterCompanyId = masterCompanyId
			FROM #StockLineBulkUploadType stkbulk WHERE stkbulk.ID = @count;
			
			INSERT INTO #StockLineBulkUploadReturn ([StockLineId],[Quantity],[unitCost],[PurchaseOrderUnitCost],[RepairOrderUnitCost],[MasterCompanyId])  
				SELECT [StockLineId],[Quantity],[unitCost],[PurchaseOrderUnitCost],[RepairOrderUnitCost],[MasterCompanyId]
			FROM Stockline WHERE PartNumber = @partNumber AND Manufacturer = @manufacturerName AND Condition = @condition;
			
			SELECT @StkTotalCounts = COUNT(ID) FROM #StockLineBulkUploadReturn;
			WHILE @Stkcount <= @StkTotalCounts
			BEGIN 
				SELECT  @StockLineId = StockLineId,@StkQuantity = Quantity,@StkUnitCost = unitCost ,
						@StkPurchaseOrderUnitCost = PurchaseOrderUnitCost,@StkRepairOrderUnitCost = RepairOrderUnitCost,@StkMasterCompanyId = MasterCompanyId
					FROM #StockLineBulkUploadReturn stkupd WHERE stkupd.ID = @Stkcount;
				IF(@StkQuantity > 0)
				BEGIN
					
					SET @StkUnitCostAdjustmnet = @UnitCost - (@StkPurchaseOrderUnitCost + @StkRepairOrderUnitCost);

					-- Adjustment added & Update UnitCost
					UPDATE Stockline SET UnitCost =  @UnitCost , Adjustment = @StkUnitCostAdjustmnet  
						WHERE StockLineId = @StockLineId;

					--Added records in StocklineAdjustment
					INSERT INTO [dbo].[StocklineAdjustment]
								([StocklineId],[StocklineAdjustmentDataTypeId],[ChangedFrom],[ChangedTo],[AdjustmentMemo],[MasterCompanyId]
								,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[AdjustmentReasonId],[IsDeleted]
								,[CurrencyId],[AdjustmentReason])
					VALUES (@StockLineId,@StkAdjustmentDataTypeId,@StkUnitCost,@UnitCost,'',@masterCompanyId
							,@createdBy,@createdBy,GETDATE(),GETDATE(),1,NULL,0,NULL,NULL);
				END

				SET @StockLineId = 0;
				SET @StkQuantity = 0;
				SET @StkUnitCost = 0;
				SET @Stkcount = @Stkcount + 1;
			END

			SET @count = @count + 1;
		END

		--After Full upload
		TRUNCATE TABLE TmpStockLineBulkUpload;
    END  
    COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
                    ROLLBACK TRAN;  
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateStocklineUnitCostData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''  
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