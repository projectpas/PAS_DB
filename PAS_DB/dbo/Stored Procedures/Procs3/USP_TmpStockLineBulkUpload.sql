/*************************************************************           
 ** File:   [USP_TmpStockLineBulkUpload]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to GetJournalBatchHeaderById
 ** Purpose:         
 ** Date:   07/13/2022      
          
 ** PARAMETERS: @tbl_StockLineBulkUpload type
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/12/2023  Amit Ghediya     Created
     
-- EXEC USP_TmpStockLineBulkUpload
************************************************************************/
CREATE       PROCEDURE [dbo].[USP_TmpStockLineBulkUpload]  
	@tbl_StockLineBulkUpload StockLineBulkUploadType READONLY,
	@isDeleted INT = 0,
	@fileName VARCHAR(100) = NULL
AS  
BEGIN  
   
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN  
		DECLARE @TotalCounts INT,@count INT,@isValid INT,@partNumber VARCHAR(250),@partDescription NVARCHAR(MAX),
				@manufacturerName VARCHAR(100),@condition VARCHAR(256),@unitCost DECIMAL(18,2),@StockLineId BIGINT,@tmpStockLineBulkUploadId BIGINT,
				@createdBy VARCHAR(100),@masterCompanyId INT;
		SET @count = 1;

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
		
		-- For return response
		CREATE TABLE #StockLineBulkUploadReturn   
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
		)  

		INSERT INTO #StockLineBulkUploadType ([partNumber],[partDescription],[manufacturerName],[condition],[unitCost],[message],[srno],[tmpStockLineBulkUploadId],[createdBy],[masterCompanyId])  
			SELECT [partNumber],[partDescription],[manufacturerName],[condition],[unitCost],[message],[srno],[tmpStockLineBulkUploadId],[createdBy],[masterCompanyId]
		FROM @tbl_StockLineBulkUpload;

		IF(@isDeleted = 1)
		BEGIN 
			TRUNCATE TABLE TmpStockLineBulkUpload;
		END

		IF NOT EXISTS(SELECT partNumber FROM @tbl_StockLineBulkUpload)
		BEGIN
			TRUNCATE TABLE TmpStockLineBulkUpload;
		END

		SELECT @TotalCounts = COUNT(ID) FROM #StockLineBulkUploadType;
		WHILE @count<= @TotalCounts
		BEGIN 
			SELECT @partNumber = partNumber, @partDescription = partDescription, @manufacturerName = manufacturerName,@condition = condition, @unitCost = unitCost ,@tmpStockLineBulkUploadId = tmpStockLineBulkUploadId, @createdBy = createdBy, @masterCompanyId = masterCompanyId
			FROM #StockLineBulkUploadType stkbulk WHERE stkbulk.ID = @count;

			SELECT TOP 1 @StockLineId = ISNULL(stk.StockLineId,0) FROM Stockline stk WITH (NOLOCK) 
					WHERE stk.PartNumber = @partNumber AND stk.Manufacturer = @manufacturerName AND stk.Condition = @condition;

			IF EXISTS(SELECT TOP 1 partNumber FROM TmpStockLineBulkUpload tmpstock WITH (NOLOCK) 
				WHERE tmpStockLineBulkUploadId = @tmpStockLineBulkUploadId)
			BEGIN 
				IF(@StockLineId > 0)
				BEGIN
					UPDATE TmpStockLineBulkUpload SET partNumber = @partNumber, partDescription = @partDescription, manufacturerName=@manufacturerName, condition = @condition, unitCost = @unitCost,message = 'Valid Records' 
						WHERE tmpStockLineBulkUploadId = @tmpStockLineBulkUploadId;
				END
			END
			ELSE
			BEGIN
				IF(@isDeleted = 1)
				BEGIN
					IF(@StockLineId > 0)
					BEGIN
						--INSERT INTO #StockLineBulkUploadReturn ([partNumber],[partDescription],[manufacturerName],[condition],[unitCost],[message],[srno]) 
						--	SELECT [partNumber],[partDescription],[manufacturerName],[condition],[unitCost],'Valid Records',[srno] 
						--FROM #StockLineBulkUploadType stkbulkr WHERE stkbulkr.ID = @count;
						INSERT INTO TmpStockLineBulkUpload ([partNumber],[partDescription],[manufacturerName],[condition],[unitCost],[message],[srno],
															[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate])  
							SELECT [partNumber],[partDescription],[manufacturerName],[condition],[unitCost],'Valid Records',[srno],
								   @masterCompanyId,@createdBy,@createdBy,GETDATE(),GETDATE()
						FROM #StockLineBulkUploadType stkbulkr WHERE stkbulkr.ID = @count;
					END
					ELSE
					BEGIN
						INSERT INTO TmpStockLineBulkUpload ([partNumber],[partDescription],[manufacturerName],[condition],[unitCost],[message],[srno],
															[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate])  
							SELECT [partNumber],[partDescription],[manufacturerName],[condition],[unitCost],'InValid Records',[srno],
								   @masterCompanyId,@createdBy,@createdBy,GETDATE(),GETDATE()
						FROM #StockLineBulkUploadType stkbulkr WHERE stkbulkr.ID = @count;
					END
				END
			END
			
			SET @StockLineId = 0;
			SET @count = @count + 1;
		END
		
		--Insert file name for refrence
		IF(@fileName != '')
		BEGIN
			INSERT INTO StockLineBulkUploadFile ([FileName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate] ) 
			VALUES(@fileName,@masterCompanyId,@createdBy,@createdBy,GETDATE(),GETDATE());
		END
		
		SELECT TmpStockLineBulkUploadId,partNumber,partDescription,manufacturerName,
			   condition,unitCost,message,srno,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate 
		FROM TmpStockLineBulkUpload;
      
    END  
    COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
                    ROLLBACK TRAN;  
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_TmpStockLineBulkUpload'   
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