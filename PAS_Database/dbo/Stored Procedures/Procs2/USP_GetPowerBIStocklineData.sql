/*************************************************************             
 ** File:   [USP_GetPowerBIStocklineData]             
 ** Author:   SUMIT KUMAR
 ** Description: Retrieve Detailed Stockline Metrics and Line Item Tracking for Power BI Reports  
 ** Purpose:           
 ** Date:   21-SEP-2026        
            
 **************************************************************             
 ** CHANGE HISTORY:             
 **************************************************************             
 ** S NO   Date         Author           Change Description              
 ** 1      21-SEP-2026  SUMIT KUMAR      Created
 **************************************************************/  
CREATE PROCEDURE [dbo].[USP_GetPowerBIStocklineData]   
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
            STL.SerialNumber,
            STL.Condition,
            ISNULL(STL.QuantityOnHand, 0) AS QuantityOnHand,
            ISNULL(STL.QuantityAvailable, 0) AS QuantityAvailable,
            ISNULL(STL.QuantityReserved, 0) AS QuantityReserved,
            ISNULL(STL.QuantityIssued, 0) AS QuantityIssued,
            CAST(ISNULL(STL.UnitCost, 0) AS DECIMAL(18,2)) AS UnitCost,
            CAST(ISNULL(STL.PurchaseOrderUnitCost, 0) AS DECIMAL(18,2)) AS PurchaseOrderUnitCost,
            CAST(ISNULL(STL.RepairOrderUnitCost, 0) AS DECIMAL(18,2)) AS RepairOrderUnitCost,
            CAST(ISNULL(STL.UnitSalesPrice, 0) AS DECIMAL(18,2)) AS UnitSalesPrice,
            CAST(ISNULL(STL.QuantityOnHand, 0) * ISNULL(STL.UnitCost, 0) AS DECIMAL(18,2)) AS ExtendedCost,
            STL.PurchaseOrderNumber,
            STL.RepairOrderNumber,
            STL.WorkOrderNumber,
            STL.ReceiverNumber,
            V.VendorName,
            C.Name AS CustomerName,
            STL.Site,
            STL.Warehouse,
            STL.Location,
            STL.ObtainFromName,
            STL.OwnerName,
            STL.TraceableToName,
            STL.TagType,
            CASE WHEN STL.TagDate IS NOT NULL THEN CONVERT(VARCHAR(30), STL.TagDate, 127) + 'Z' ELSE NULL END AS TagDate,
            STL.CertifiedBy,
            CASE WHEN STL.CertifiedDate IS NOT NULL THEN CONVERT(VARCHAR(30), STL.CertifiedDate, 127) + 'Z' ELSE NULL END AS CertifiedDate,
            CASE WHEN STL.ReceivedDate IS NOT NULL THEN CONVERT(VARCHAR(30), STL.ReceivedDate, 127) + 'Z' ELSE NULL END AS ReceivedDate,
            CASE WHEN STL.ExpirationDate IS NOT NULL THEN CONVERT(VARCHAR(30), STL.ExpirationDate, 127) + 'Z' ELSE NULL END AS ExpirationDate,
            CASE WHEN STL.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY, STL.ReceivedDate, GETUTCDATE()) ELSE 0 END AS DaysInStock,
            CAST(ISNULL(STL.IsCustomerStock, 0) AS BIT) AS IsCustomerStock,
            CAST(ISNULL(STL.isSerialized, 0) AS BIT) AS IsSerialized,
            CAST(ISNULL(STL.IsStkTimeLife, 0) AS BIT) AS IsTimeLife,
            CAST(ISNULL(STL.IsPMA, 0) AS BIT) AS IsPMA,
            CAST(ISNULL(STL.IsDER, 0) AS BIT) AS IsDER,
            CAST(ISNULL(STL.OEM, 0) AS BIT) AS IsOEM,
            CAST(ISNULL(STL.IsNonStock, 0) AS BIT) AS IsNonStock,
            STL.InventoryGLAccName AS GLAccountName
        FROM dbo.Stockline STL WITH(NOLOCK)
        LEFT JOIN dbo.Vendor V WITH(NOLOCK) ON STL.VendorId = V.VendorId
        LEFT JOIN dbo.Customer C WITH(NOLOCK) ON STL.CustomerId = C.CustomerId
        WHERE STL.MasterCompanyId = @masterCompanyId
          AND ISNULL(STL.IsDeleted, 0) = 0
          AND ISNULL(STL.IsActive, 1) = 1
          AND ISNULL(STL.IsParent, 1) = 1
        ORDER BY STL.CreatedDate DESC;
    END TRY    
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_GetPowerBIStocklineData'
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
