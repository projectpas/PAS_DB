
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_GetVendorCapabilityById   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetVendorCapabilityById.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************
** File:  [USP_GetVendorCapabilityById]
** Author:   Ayushi Patel
** Description: Get Vendor Capability By Id
** Purpose:  
** Date:     03-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    03-07-2025   Ayushi Patel   Created

-- EXEC [USP_GetVendorCapabilityById] 4797
	1    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetVendorCapabilityById]
    @VendorCapabilityId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            v.VendorName,
            v.VendorCode,
            im.PartNumber,
            im.PartDescription,
            im.ManufacturerId,
            ISNULL(man.Name, '') AS ManufacturerName,
            vc.VendorCapabilityId,
            vc.VendorId,
            vc.VendorRanking,
            vc.ItemMasterId,
            vc.TAT,
            vc.Cost,
            vc.CostDate,
            vc.Memo,
            vc.CreatedDate,
            vc.UpdatedDate,
            vc.CreatedBy,
            vc.UpdatedBy,
            vc.CapabilityTypeDescription,
            ISNULL(vc.IsActive,0) AS IsActive,
            vc.CapabilityTypeId,
            ISNULL(vc.IsPMA,0) AS IsPMA,
            ISNULL(vc.IsDER,0) AS IsDER,
            vcat.Description AS CapabilityType,
            vcat.CapabilityTypeDesc AS CapDescription,
            vc.EmployeeId,
            vc.Currency,
            vc.CurrencyId
        FROM dbo.VendorCapability vc WITH(NOLOCK)
        INNER JOIN dbo.Vendor v WITH(NOLOCK) ON vc.VendorId = v.VendorId
        LEFT JOIN dbo.ItemMaster im WITH(NOLOCK) ON vc.ItemMasterId = im.ItemMasterId
         AND ISNULL(im.IsNonStock,0) = 0
         LEFT JOIN dbo.Manufacturer man WITH(NOLOCK) ON im.ManufacturerId = man.ManufacturerId
        LEFT JOIN dbo.CapabilityType vcat WITH(NOLOCK) ON vc.CapabilityTypeId = vcat.CapabilityTypeId
        WHERE vc.VendorCapabilityId = @VendorCapabilityId
    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetVendorCapabilityById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END