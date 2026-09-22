/*************************************************************             
 ** File:   [USP_GetPowerBIItemMasterData]             
 ** Author:   SUMIT KUMAR
 ** Description: Retrieve Item Master Catalog & Stocking Metrics for Power BI Reports  
 ** Purpose:           
 ** Date:   21-SEP-2026        
            
 **************************************************************             
 ** CHANGE HISTORY:             
 **************************************************************             
 ** S NO   Date         Author           Change Description              
 ** 1      21-SEP-2026  SUMIT KUMAR      Created
 **************************************************************/  
CREATE PROCEDURE [dbo].[USP_GetPowerBIItemMasterData]   
    @masterCompanyId INT
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
  
    BEGIN TRY
        SELECT 
            IM.ItemMasterId,
            IM.partnumber AS PartNumber,
            IM.PartDescription,
            IM.ManufacturerName,
            IM.ItemClassificationName,
            IM.ItemGroup,
            IT.Description AS ItemType,
            IM.NationalStockNumber,
            CAST(ISNULL(IM.ReorderPoint, 0) AS DECIMAL(18,2)) AS ReorderPoint,
            CAST(ISNULL(IM.ReorderQuantiy, 0) AS DECIMAL(18,2)) AS ReorderQuantity,
            CAST(ISNULL(IM.MinimumOrderQuantity, 0) AS DECIMAL(18,2)) AS MinimumOrderQuantity,
            CAST(ISNULL(IM.StockLevel, 0) AS DECIMAL(18,2)) AS StockLevel,
            ISNULL(IM.LeadTimeDays, 0) AS LeadTimeDays,
            ISNULL(IM.OverhaulHours, 0) AS OverhaulHours,
            ISNULL(IM.RPHours, 0) AS RPHours,
            ISNULL(IM.TestHours, 0) AS TestHours,
            ISNULL(IM.TurnTimeOverhaulHours, 0) AS TurnTimeOverhaulHours,
            ISNULL(IM.TurnTimeRepairHours, 0) AS TurnTimeRepairHours,
            CAST(ISNULL(IM.UnitCost, 0) AS DECIMAL(18,2)) AS UnitCost,
            CAST(ISNULL(IM.ListPrice, 0) AS DECIMAL(18,2)) AS ListPrice,
            CAST(ISNULL(IM.PartListPrice, 0) AS DECIMAL(18,2)) AS PartListPrice,
            IM.PurchaseUnitOfMeasure,
            IM.StockUnitOfMeasure,
            IM.GLAccount,
            CAST(ISNULL(IM.isSerialized, 0) AS BIT) AS IsSerialized,
            CAST(ISNULL(IM.isTimeLife, 0) AS BIT) AS IsTimeLife,
            CAST(ISNULL(IM.IsPma, 0) AS BIT) AS IsPMA,
            CAST(ISNULL(IM.IsDER, 0) AS BIT) AS IsDER,
            CAST(ISNULL(IM.IsOEM, 0) AS BIT) AS IsOEM,
            CAST(ISNULL(IM.IsHazardousMaterial, 0) AS BIT) AS IsHazardousMaterial,
            CAST(ISNULL(IM.IsActive, 1) AS BIT) AS IsActive,
            CASE WHEN IM.CreatedDate IS NOT NULL THEN CONVERT(VARCHAR(30), IM.CreatedDate, 127) + 'Z' ELSE NULL END AS CreatedDate
        FROM dbo.ItemMaster IM WITH(NOLOCK)
        LEFT JOIN dbo.ItemType IT WITH(NOLOCK) ON IM.ItemTypeId = IT.ItemTypeId
        WHERE IM.MasterCompanyId = @masterCompanyId
          AND ISNULL(IM.IsDeleted, 0) = 0
          AND ISNULL(IM.IsActive, 1) = 1
        ORDER BY IM.CreatedDate DESC;
    END TRY    
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_GetPowerBIItemMasterData'
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
