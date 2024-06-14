/*************************************************************             
 ** File:   [GetSalesOrderPartsViewById]             
 ** Author:  AMIT GHEDIYA 
 ** Description: This stored procedure is used GetSalesOrderPartsViewById 
 ** Purpose:           
 ** Date:  03/06/2024        
            
 ** PARAMETERS: @SalesOrderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    03/06/2024		AMIT GHEDIYA	 Created  
	2    13/06/2024		AMIT GHEDIYA	 Update for get only part which is reserve qty. 

-- exec GetSalesOrderPartsViewById 50 
************************************************************************/   
CREATE     PROCEDURE [dbo].[GetSalesOrderPartsViewById]    
	@SalesOrderId BIGINT    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN   
		--SELECT 
		--	 ROW_NUMBER() OVER (
		--		ORDER BY part.SalesOrderId
		--	 ) row_num, 
		--	UPPER(part.PONumber) AS PONumber,
		--	UPPER(itemMaster.PartNumber) AS PartNumber,
		--	UPPER(itemMaster.PartDescription) AS PartDescription,
		--	UPPER(ISNULL(qs.StockLineNumber, '')) AS StockLineNumber,
		--	UPPER(qs.SerialNumber) AS SerialNumber,
		--	rPart.QtyToReserve AS Qty,
		--	UPPER(ISNULL(cp.Description, '')) AS Condition
		--FROM  [dbo].[SalesOrderPart] part WITH(NOLOCK)
		--INNER JOIN [dbo].[SalesOrderReserveParts] rPart WITH(NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId AND rPart.QtyToReserve > 0
		--LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
		--LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		--LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
		--WHERE part.SalesOrderId = @SalesOrderId  AND part.IsDeleted = 0
		--ORDER BY part.ItemNo;

		IF OBJECT_ID(N'tempdb..#tmprShipDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmprShipDetails
		END
		
		CREATE TABLE #tmprShipDetails
		(
			[Qty] INT NULL,
			[StockLineNumber] VARCHAR(MAX) NULL,
			[SerialNumber] VARCHAR(MAX) NULL,
			[Condition] VARCHAR(MAX) NULL,
			[PartNumber] VARCHAR(MAX) NULL,
		)

		INSERT INTO #tmprShipDetails ([Qty],[StockLineNumber],[SerialNumber],[Condition],[PartNumber])	
		SELECT 
			rpart.QtyToReserve AS Qty,
			UPPER(qs.StockLineNumber) AS StockLineNumber,
			UPPER(qs.SerialNumber) AS SerialNumber,
			UPPER(ISNULL(cp.Description, '')) AS Condition,
			UPPER(itemMaster.PartNumber) AS PartNumber
		FROM  [dbo].[SalesOrderPart] part WITH(NOLOCK)
				LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
				LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
				LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
				INNER JOIN [dbo].[SalesOrderReserveParts] rPart WITH(NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId 
				AND rPart.QtyToReserve > 0 
		WHERE part.SalesOrderId = @SalesOrderId  AND part.IsDeleted = 0

		UNION 

		SELECT 
			sos.QtyShipped AS Qty,
			UPPER(qs.StockLineNumber) AS StockLineNumber,
			UPPER(qs.SerialNumber) AS SerialNumber,
			UPPER(ISNULL(cp.Description, '')) AS Condition,
			UPPER(itemMaster.PartNumber) AS PartNumber
		FROM  [dbo].[SalesOrderPart] part WITH(NOLOCK)
				LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
				LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
				LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
				INNER JOIN [dbo].[SalesOrderShippingItem] sos WITH(NOLOCK) ON part.SalesOrderPartId = sos.SalesOrderPartId
				AND sos.IsActive = 1 AND sos.IsDeleted = 0
		WHERE part.SalesOrderId = @SalesOrderId  AND part.IsDeleted = 0
		
		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS row_num,
				 SUM(Qty) AS Qty,StockLineNumber,SerialNumber,Condition,PartNumber 
		FROM #tmprShipDetails
		GROUP BY PartNumber,StockLineNumber,SerialNumber,Condition
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderPartsViewById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''    
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