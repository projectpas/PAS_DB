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
 ** PR   Date			 Author				Change Description              
 ** --   --------		-------				--------------------------------            
    1    03/06/2024		AMIT GHEDIYA		Created  
	2    13/06/2024		AMIT GHEDIYA		Update for get only part which is reserve qty. 
	3    11/05/2024		Vishal Suthar		Modified to make use of new SO Part tables
	4    07/11/2024		Devendra Shekh		added PartDescription and ShortName to select
	5	 05-12-2024     Shrey Chandegara	add [Customer]
	5	 20-12-2024     RAJESH GAMI			Add the PickTicket(ID) join with the SalesOrderShippingItem instead of SOPart ID
	6    26-12-2024		Amit Ghediya		Modified to add SoPartId param set default value is o & get partwise data, if partid=0 then all part come.
	7    28-10-2025		Vishal Suthar		Fixed issue with fetching wrong Qty from SalesOrderReserveParts table
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

-- exec GetSalesOrderPartsViewById 758,0
************************************************************************/   
CREATE   PROCEDURE [dbo].[GetSalesOrderPartsViewById]    
	@SalesOrderId BIGINT,
	@SoPartId BIGINT = 0    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN   
		
		IF OBJECT_ID(N'tempdb..#tmprShipDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmprShipDetails
		END

		--Set SoPart null for all part for salesordor otherwise for perticular part only.
		IF(ISNULL(@SoPartId,0) = 0)
		BEGIN
			SET @SoPartId = NULL;
		END
		
		CREATE TABLE #tmprShipDetails
		(
			[Qty] INT NULL,
			[StockLineNumber] VARCHAR(MAX) NULL,
			[SerialNumber] VARCHAR(MAX) NULL,
			[Condition] VARCHAR(MAX) NULL,
			[PartNumber] VARCHAR(MAX) NULL,
			[PartDescription] VARCHAR(MAX) NULL,
			[ShortName] VARCHAR(100) NULL,
			[Customer] VARCHAR(150) NULL
		)

		INSERT INTO #tmprShipDetails ([Qty],[StockLineNumber],[SerialNumber],[Condition],[PartNumber],[PartDescription],[ShortName],[Customer])	
		SELECT 
			rpart.QtyToReserve AS Qty,
			UPPER(qs.StockLineNumber) AS StockLineNumber,
			UPPER(qs.SerialNumber) AS SerialNumber,
			UPPER(ISNULL(cp.Description, '')) AS Condition,
			UPPER(itemMaster.PartNumber) AS PartNumber,
			UPPER(itemMaster.PartDescription) AS PartDescription,
			UPPER(uom.ShortName) AS ShortName,
			UPPER(CU.Name) AS Customer
		FROM  [dbo].[SalesOrderPartV1] part WITH(NOLOCK)
		        LEFT JOIN [dbo].[SalesOrderStocklineV1] Stk WITH(NOLOCK) ON part.SalesOrderPartId = Stk.SalesOrderPartId
				LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON Stk.StockLineId = qs.StockLineId
				LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
				 AND ISNULL(itemMaster.IsNonStock,0) = 0 LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
				INNER JOIN [dbo].[SalesOrderReserveParts] rPart WITH(NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId 
				AND rPart.SalesOrderId = @SalesOrderId AND rPart.QtyToReserve > 0 
				LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
				LEFT JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON part.SalesOrderId = SO.SalesOrderId
				LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = SO.CustomerId
		WHERE part.SalesOrderId = @SalesOrderId  AND part.IsDeleted = 0
			  AND (@SoPartId IS NULL OR part.SalesOrderPartId = @SoPartId)

		UNION 

		SELECT 
			sos.QtyShipped AS Qty,
			UPPER(qs.StockLineNumber) AS StockLineNumber,
			UPPER(qs.SerialNumber) AS SerialNumber,
			UPPER(ISNULL(cp.Description, '')) AS Condition,
			UPPER(itemMaster.PartNumber) AS PartNumber,
			UPPER(itemMaster.PartDescription) AS PartDescription,
			UPPER(uom.ShortName) AS ShortName,
			UPPER(CU.Name) AS Customer
		FROM  [dbo].[SalesOrderPartV1] part WITH(NOLOCK)
		        LEFT JOIN [dbo].[SalesOrderStocklineV1] Stk WITH(NOLOCK) ON part.SalesOrderPartId = Stk.SalesOrderPartId
				LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON Stk.StockLineId = qs.StockLineId
				LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
				 AND ISNULL(itemMaster.IsNonStock,0) = 0 LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
				LEFT JOIN [dbo].[SOPickTicket] SOPICK WITH(NOLOCK) ON SOPICK.SalesOrderPartStocklineId = Stk.SalesOrderStocklineId
				INNER JOIN [dbo].[SalesOrderShippingItem] sos WITH(NOLOCK) ON sos.SOPickTicketId = SOPICK.SOPickTicketId
				AND sos.IsActive = 1 AND sos.IsDeleted = 0
				LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
				LEFT JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON part.SalesOrderId = SO.SalesOrderId
				LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = SO.CustomerId
		WHERE part.SalesOrderId = @SalesOrderId  AND part.IsDeleted = 0
			  AND (@SoPartId IS NULL OR part.SalesOrderPartId = @SoPartId)
		
		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS row_num,
				 SUM(Qty) AS Qty,StockLineNumber,SerialNumber,Condition,PartNumber,PartDescription,ShortName,Customer
		FROM #tmprShipDetails
		GROUP BY PartNumber,StockLineNumber,SerialNumber,Condition,PartDescription,ShortName,Customer
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