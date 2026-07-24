

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
    2    24/July/2026	 RAJESH GAMI	[PN-17350] - Converted legacy dbo.NonStockInventory/dbo.ItemMasterNonStock references to dbo.Stockline/dbo.ItemMaster with ISNULL(IsNonStock,0)=1

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
			SELECT ItemMasterId = ac.ItemMasterId,
				   ac.ManufacturerId,
				MAX(ac.StockLineId) StockLineId
			FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK) WHERE ISNULL(IsNonStock,0) = 1) ac1 CROSS JOIN
				(SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK) WHERE ISNULL(IsNonStock,0) = 1) ac2 LEFT JOIN
				DBO.Stockline ac WITH (NOLOCK)
				ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId AND ISNULL(ac.IsNonStock,0) = 1
			WHERE ac.MasterCompanyId = @MasterCompanyId
			GROUP BY ac.ItemMasterId, ac.ManufacturerId
			HAVING COUNT(ac.ItemMasterId) > 0
		)

		SELECT CSTL.ItemMasterId,
				CSTL.ManufacturerId,
				StockLineNumber = STL.StockLineNumber,
				ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo,
				IM.isSerialized
		FROM CTE_Stockline CSTL INNER JOIN DBO.Stockline STL WITH (NOLOCK)
		INNER JOIN DBO.ItemMaster IM ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId AND ISNULL(IM.IsNonStock,0) = 1
		ON CSTL.StockLineId = STL.StockLineId
		WHERE ISNULL(STL.IsNonStock,0) = 1

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