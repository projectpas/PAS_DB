

/*************************************************************           
 ** File:   [GetNonStockPNManufacturerCombinationCreated]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to get CurrentStlNo
 ** Purpose:         
 ** Date:   02/02/2022        
          
 ** PARAMETERS: @@PurchaseOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/02/2022  Moin Bloch     Created
     
-- EXEC [GetNonStockPNManufacturerCombinationCreated] 179
************************************************************************/
CREATE PROCEDURE [dbo].[GetNonStockPNManufacturerCombinationCreated]
@MasterCompanyId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 
		;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS
		(
			SELECT ItemMasterId = ac.MasterPartId, 
				   ac.ManufacturerId, 
				MAX(ac.NonStockInventoryId) StockLineId
			FROM (SELECT DISTINCT MasterPartId FROM DBO.NonStockInventory WITH (NOLOCK)) ac1 CROSS JOIN
				(SELECT DISTINCT ManufacturerId FROM DBO.NonStockInventory WITH (NOLOCK)) ac2 LEFT JOIN
				DBO.NonStockInventory ac WITH (NOLOCK)
				ON ac.MasterPartId = ac1.MasterPartId AND ac.ManufacturerId = ac2.ManufacturerId
			WHERE ac.MasterCompanyId = @MasterCompanyId
			GROUP BY ac.MasterPartId, ac.ManufacturerId
			HAVING COUNT(ac.MasterPartId) > 0
		)

		SELECT CSTL.ItemMasterId, 
				CSTL.ManufacturerId, 
				StockLineNumber = STL.NonStockInventoryNumber, 
				ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, 
				IM.isSerialized
		FROM CTE_Stockline CSTL INNER JOIN DBO.NonStockInventory STL WITH (NOLOCK) 
		INNER JOIN DBO.ItemMasterNonStock IM ON STL.MasterPartId = IM.MasterPartId AND STL.ManufacturerId = IM.ManufacturerId
		ON CSTL.StockLineId = STL.NonStockInventoryId

	END TRY
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetNonStockPNManufacturerCombinationCreated' 
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