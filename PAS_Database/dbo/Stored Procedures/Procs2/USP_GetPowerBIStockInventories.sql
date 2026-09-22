/*************************************************************             
 ** File:   [USP_GetPowerBIStockInventories]             
 ** Author:   SUMIT KUMAR
 ** Description: Retrieve Consolidated Stock Inventories Data for Power BI Dashboards & Reports  
 ** Purpose:           
 ** Date:   21-SEP-2026        
            
 **************************************************************             
 ** CHANGE HISTORY:             
 **************************************************************             
 ** S NO   Date         Author           Change Description              
 ** 1      21-SEP-2026  SUMIT KUMAR      Created
 **************************************************************/  
CREATE PROCEDURE [dbo].[USP_GetPowerBIStockInventories]   
    @masterCompanyId INT
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
  
    BEGIN TRY
        SELECT 
            STL.StockLineId,
            STL.StockLineNumber,
            STL.ControlNumber,
            STL.IdNumber,
            STL.PartNumber,
            STL.PNDescription AS PartDescription,
            STL.Manufacturer,
            STL.itemGroup AS ItemGroup,
            STL.Condition,
            STL.Site,
            STL.Warehouse,
            STL.Location,
            STL.Shelf,
            STL.Bin,
            ISNULL(STL.QuantityOnHand, 0) AS QuantityOnHand,
            ISNULL(STL.QuantityAvailable, 0) AS QuantityAvailable,
            ISNULL(STL.QuantityReserved, 0) AS QuantityReserved,
            ISNULL(STL.QuantityIssued, 0) AS QuantityIssued,
            CAST(ISNULL(STL.UnitCost, 0) AS DECIMAL(18,2)) AS UnitCost,
            CAST(ISNULL(STL.QuantityOnHand, 0) * ISNULL(STL.UnitCost, 0) AS DECIMAL(18,2)) AS TotalCost,
            CAST(ISNULL(STL.PurchaseOrderUnitCost, 0) AS DECIMAL(18,2)) AS PurchaseOrderUnitCost,
            CAST(ISNULL(STL.RepairOrderUnitCost, 0) AS DECIMAL(18,2)) AS RepairOrderUnitCost,
            CAST(ISNULL(STL.UnitSalesPrice, 0) AS DECIMAL(18,2)) AS UnitSalesPrice,
            STL.InventoryGLAccName AS GLAccount,
            CAST(ISNULL(STL.IsCustomerStock, 0) AS BIT) AS IsCustomerStock,
            CAST(ISNULL(STL.isSerialized, 0) AS BIT) AS IsSerialized,
            STL.SerialNumber,
            CASE WHEN ISNULL(STL.IsNonStock, 0) = 1 THEN 'Non-Stock' ELSE 'Stock' END AS StockType,
            CAST(ISNULL(STL.IsNonStock, 0) AS BIT) AS IsNonStock,
            CASE WHEN STL.ReceivedDate IS NOT NULL THEN CONVERT(VARCHAR(30), STL.ReceivedDate, 127) + 'Z' ELSE NULL END AS ReceivedDate,
            CASE WHEN STL.ExpirationDate IS NOT NULL THEN CONVERT(VARCHAR(30), STL.ExpirationDate, 127) + 'Z' ELSE NULL END AS ExpirationDate,
            MSD.Level1Name AS LegalEntity,
            MSD.Level3Name AS Station
        FROM dbo.Stockline STL WITH(NOLOCK)
        LEFT JOIN dbo.StocklineManagementStructureDetails MSD WITH(NOLOCK) ON MSD.ModuleID = 2 AND MSD.ReferenceID = STL.StockLineId
        WHERE STL.MasterCompanyId = @masterCompanyId
          AND ISNULL(STL.IsDeleted, 0) = 0
          AND ISNULL(STL.IsActive, 1) = 1
          AND ISNULL(STL.IsParent, 1) = 1
        ORDER BY STL.CreatedDate DESC;
    END TRY    
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_GetPowerBIStockInventories'
        ,@ProcedureParameters VARCHAR(3000) = '@masterCompanyId = ''' + CAST(ISNULL(@masterCompanyId, '') AS varchar(100))
        ,@ApplicationName VARCHAR(100) = 'PAS';
        
        EXEC spLogException @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);           
    END CATCH
END
GO
