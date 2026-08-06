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
    2    24/July/2026  RAJESH GAMI    [PN-17350] - Converted legacy dbo.NonStockInventory/dbo.ItemMasterNonStock references to dbo.Stockline/dbo.ItemMaster with ISNULL(IsNonStock,0)=1
     
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
            -- Step 1: Stage only the relevant non-stock rows for this company
            SELECT  ItemMasterId,
                    ManufacturerId,
                    StockLineId
            FROM    dbo.Stockline WITH (NOLOCK)
            WHERE   ISNULL(IsNonStock, 0) = 1
              AND   MasterCompanyId = @MasterCompanyId
        ),
        CTE_Stockline AS
        (
            -- Step 2: Latest StockLineId per ItemMaster / Manufacturer combination
            SELECT  ItemMasterId,
                    ManufacturerId,
                    MAX(StockLineId) AS StockLineId
            FROM    CTE_NonStockLine
            GROUP BY ItemMasterId, ManufacturerId
		)

		SELECT CSTL.ItemMasterId, 
				CSTL.ManufacturerId, 
                StockLineNumber = STL.StockLineNumber,
				ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, 
				IM.isSerialized
        FROM    CTE_Stockline CSTL
                INNER JOIN dbo.Stockline STL WITH (NOLOCK)
                    ON  STL.StockLineId = CSTL.StockLineId
                    AND ISNULL(STL.IsNonStock, 0) = 1
                INNER JOIN dbo.ItemMaster IM WITH (NOLOCK)
                    ON  IM.ItemMasterId   = STL.ItemMasterId
                    AND IM.ManufacturerId = STL.ManufacturerId
                    AND ISNULL(IM.IsNonStock, 0) = 1;

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