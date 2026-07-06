/*************************************************************
** File:    [USP_GetVendorCapabilityList]
** Author:   Ayushi Patel
** Description: Get Vendor CapabilityList
** Purpose:  
** Date:     02-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    02-07-2025   Ayushi Patel   Created
** 2    05-12-2025   Moin Bloch   Added EmployeeName

-- EXEC USP_GetVendorCapabilityList 4797
	1    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetVendorCapabilityList]
    @VendorId BIGINT = 0,
    @Status VARCHAR(10) = 'all'
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        DECLARE @sStatus BIT = NULL;

        IF LOWER(@Status) = 'active'
            SET @sStatus = 1;
        ELSE IF LOWER(@Status) = 'inactive'
            SET @sStatus = 0;

        SELECT 
            v.VendorName,
            v.VendorCode,
            im.PartNumber,
            im.PartDescription,
            im.ManufacturerId,
            ISNULL(man.Name, '') AS manufacturerName,
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
            vcat.Description AS CapabilityType,
            vc.CapabilityTypeId,
            ISNULL(vc.IsPMA,0) AS IsPMA,
            ISNULL(vc.IsDER,0) AS IsDER,
            ISNULL(vc.IsDeleted,0) AS IsDeleted,
            vc.CurrencyId,
            vc.Currency,
            vc.EmployeeId,
			E.FirstName + ' ' + E.LastName [EmployeeName]
        FROM [dbo].[VendorCapability] vc WITH (NOLOCK)
        INNER JOIN [dbo].[Vendor] v WITH (NOLOCK) ON vc.VendorId = v.VendorId
         LEFT JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON vc.ItemMasterId = im.ItemMasterId
          AND ISNULL(im.IsNonStock,0) = 0
          LEFT JOIN [dbo].[Manufacturer] man WITH (NOLOCK) ON im.ManufacturerId = man.ManufacturerId
         LEFT JOIN [dbo].[CapabilityType] vcat WITH (NOLOCK) ON CONVERT(INT, vc.CapabilityTypeId) = vcat.CapabilityTypeId
		 LEFT JOIN [dbo].[Employee] E WITH(NOLOCK) ON vc.EmployeeId = E.EmployeeId
        WHERE (@VendorId = 0 OR vc.VendorId = @VendorId)
          AND (@sStatus IS NULL OR ISNULL(vc.IsActive,0) = @sStatus)
        ORDER BY vc.CreatedDate;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetVendorCapabilityList',
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(@VendorId AS VARCHAR) + ', @Status = ' + ISNULL(@Status, 'NULL'),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END