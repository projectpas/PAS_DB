/*************************************************************           
 ** File:   [GetNonPNManufacturerCombinationCreated]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used CHECK  Non Stockline combination Details.    
 ** Purpose:         
 ** Date:    02/04/2020       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/04/2020   Subhash Saliya Created

     
--  EXEC [GetNonPNManufacturerCombinationCreated] 1
**************************************************************/

Create PROCEDURE [dbo].[GetNonPNManufacturerCombinationCreated]
	@MasterCompanyId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 
		;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS
		(
			SELECT ac.MasterPartId as ItemMasterId, ac.ManufacturerId, MAX(ac.NonStockInventoryId) StockLineId
			FROM (SELECT DISTINCT MasterPartId as ItemMasterId FROM DBO.NonStockInventory WITH (NOLOCK)) ac1 CROSS JOIN
				(SELECT DISTINCT ManufacturerId FROM DBO.NonStockInventory WITH (NOLOCK)) ac2 LEFT JOIN
				DBO.NonStockInventory ac WITH (NOLOCK)
				ON ac.MasterPartId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId
			WHERE ac.MasterCompanyId = @MasterCompanyId
			GROUP BY ac.MasterPartId, ac.ManufacturerId
			HAVING COUNT(ac.MasterPartId) > 0
		)

		SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, NonStockInventoryNumber as  StockLineNumber, ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, IM.isSerialized
		FROM CTE_Stockline CSTL INNER JOIN DBO.NonStockInventory STL WITH (NOLOCK) 
		INNER JOIN DBO.ItemMasterNonStock IM ON STL.MasterPartId = IM.MasterPartId AND STL.ManufacturerId = IM.ManufacturerId
		ON CSTL.StockLineId = STL.NonStockInventoryId

	END TRY
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetNonPNManufacturerCombinationCreated' 
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