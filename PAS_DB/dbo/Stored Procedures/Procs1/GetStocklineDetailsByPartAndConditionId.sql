/*************************************************************           
 ** File:   [GetStocklineDetailsByPartAndConditionId]           
 ** Author:  MOIN BLOCH
 ** Description: This stored procedure is used GET Stockline Details By Part And ConditionId   
 ** Purpose:         
 ** Date:   08/05/2023      
          
 ** PARAMETERS:  @ItemMasterId BIGINT = 0,@ConditionId  BIGINT = 0 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/05/2023  MOIN BLOCH 		Created
     
-- EXEC GetStocklineDetailsByPartAndConditionId 25319,182
**************************************************************/
CREATE    PROCEDURE [dbo].[GetStocklineDetailsByPartAndConditionId]
@ItemMasterId BIGINT = 0,
@ConditionId  BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		IF OBJECT_ID(N'tempdb..#StocklineDetailsByPartAndCondition') IS NOT NULL
		BEGIN
			DROP TABLE #StocklineDetailsByPartAndCondition
		END

		CREATE TABLE #StocklineDetailsByPartAndCondition
		(	
			 [PartNumber] VARCHAR(50) NULL,
			 [PartDescription] NVARCHAR(MAX) NULL,
			 [ManufacturerId] BIGINT NULL,
			 [Name] VARCHAR(50) NULL,
			 [PurchaseUnitOfMeasureId]  BIGINT NULL,
			 [PurchaseUnitOfMeasure] VARCHAR(50) NULL, 
			 [UnitCost] DECIMAL(18,2) NULL
		)

		INSERT INTO #StocklineDetailsByPartAndCondition([PartNumber],[PartDescription],[ManufacturerId],
			   [Name],[PurchaseUnitOfMeasureId],[PurchaseUnitOfMeasure],[UnitCost])

		SELECT TOP 1 I.PartNumber,
		       I.PartDescription,
			   I.ManufacturerId,
			   M.[Name],
			   I.PurchaseUnitOfMeasureId,
			   I.PurchaseUnitOfMeasure,
			   ISNULL(S.UnitCost,0) AS UnitCost
		FROM [dbo].[ItemMaster] I WITH(NOLOCK)
		LEFT JOIN [dbo].[Manufacturer] M WITH(NOLOCK) ON I.[ManufacturerId] = M.[ManufacturerId]
		LEFT JOIN [dbo].[Stockline] S WITH(NOLOCK) ON I.[ItemMasterId] = S.[ItemMasterId]   
		WHERE S.[ItemMasterId] = @ItemMasterId 
		  AND S.[ConditionId] = @ConditionId 
		  AND S.[IsParent] = 1 
	      AND S.[IsCustomerStock] = 0 ORDER BY [StocklineId] DESC

		DECLARE @StockLineCount INT = 0;

		SELECT @StockLineCount = COUNT(*) FROM #StocklineDetailsByPartAndCondition;

		IF(@StockLineCount > 0)
		BEGIN			
			SELECT * FROM #StocklineDetailsByPartAndCondition;
		END
		ELSE 
		BEGIN 		    
			IF OBJECT_ID(N'tempdb..#StocklineDetailsByPartAndCondition2') IS NOT NULL
			BEGIN
				DROP TABLE #StocklineDetailsByPartAndCondition2
			END

			CREATE TABLE #StocklineDetailsByPartAndCondition2
			(	
				 [PartNumber] VARCHAR(50) NULL,
				 [PartDescription] NVARCHAR(MAX) NULL,
				 [ManufacturerId] BIGINT NULL,
				 [Name] VARCHAR(50) NULL,
				 [PurchaseUnitOfMeasureId]  BIGINT NULL,
				 [PurchaseUnitOfMeasure] VARCHAR(50) NULL, 
				 [UnitCost] DECIMAL(18,2) NULL
			)

			INSERT INTO #StocklineDetailsByPartAndCondition2([PartNumber],[PartDescription],[ManufacturerId],
			   [Name],[PurchaseUnitOfMeasureId],[PurchaseUnitOfMeasure],[UnitCost])
			SELECT TOP 1  I.PartNumber,
			        I.PartDescription,
					I.ManufacturerId,
			        M.[Name],
					I.PurchaseUnitOfMeasureId,
					I.PurchaseUnitOfMeasure,
					0 AS UnitCost
			  FROM [dbo].[ItemMaster] I WITH(NOLOCK)
		 LEFT JOIN [dbo].[Manufacturer] M WITH(NOLOCK) ON I.[ManufacturerId] = M.[ManufacturerId]		 
		 WHERE I.[ItemMasterId] = @ItemMasterId 
			
		 SELECT * FROM #StocklineDetailsByPartAndCondition2;

		END
	END TRY    
		BEGIN CATCH 
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetStocklineDetailsByPartAndConditionId'
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') as varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
		END CATCH
END