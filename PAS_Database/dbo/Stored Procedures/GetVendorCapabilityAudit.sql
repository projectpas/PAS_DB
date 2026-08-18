/*******************************************************************************************
 ** File:   [GetVendorCapabilityAudit]           
 ** Author:  Ayushi Patel
 ** Description: This SP gets audit history of Vendor Capability with timezone adjusted dates
 ** Date:   01/05/2025   
 ** Parameters: 
    @VendorCapabilityId BIGINT, 
    @VendorId BIGINT, 
    @EmployeeId BIGINT        
 ** RETURN VALUE:  Vendor Capability Audit list
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    01/05/2025  Ayushi Patel	    Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
 *******************************************************************************************/           

CREATE   PROCEDURE [dbo].[GetVendorCapabilityAudit]
    @VendorCapabilityId BIGINT,
    @VendorId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

        SELECT 
            @CurrntEmpTimeZoneDesc = COALESCE(
                ETZ.[Description],
                LTZ.[Description]
            )
        FROM 
            dbo.Employee E WITH (NOLOCK)
        LEFT JOIN 
            dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN 
            dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN 
            dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE 
            E.EmployeeId = @EmployeeId;

        SELECT 
            vca.AuditVendorCapabilityId,
            v.VendorName,
            v.VendorCode,
            vca.VendorCapabilityId,
            vca.VendorId,
            vca.VendorRanking,
            vca.ItemMasterId,
            ISNULL(man.Name, '') AS manufacturerName,
            vca.TAT,
            vca.IsDER,
            vca.IsPMA,
            vca.Cost,
            vca.Memo,
            CAST(dbo.ConvertUTCtoLocal(vca.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS CreatedDate,
            CAST(dbo.ConvertUTCtoLocal(vca.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS UpdatedDate,
            vca.CreatedBy,
            vca.UpdatedBy,
            vca.CapabilityTypeDescription,
            ISNULL(vca.IsActive,0) AS IsActive,
            vcat.CapabilityTypeDesc AS CapabilityType,
            itm.PartNumber,
            itm.PartDescription,
            ISNULL(vca.IsDeleted,0) AS IsDeleted
        FROM 
            dbo.VendorCapabilityAudit vca WITH (NOLOCK)
        LEFT JOIN 
            dbo.Vendor v WITH (NOLOCK) ON vca.VendorId = v.VendorId
        LEFT JOIN 
            dbo.CapabilityType vcat WITH (NOLOCK) ON CONVERT(INT, vca.CapabilityTypeId) = vcat.CapabilityTypeId
        LEFT JOIN 
            dbo.ItemMaster itm WITH (NOLOCK) ON vca.ItemMasterId = itm.ItemMasterId
         AND ISNULL(itm.IsNonStock,0) = 0
        LEFT JOIN 
            dbo.Manufacturer man WITH (NOLOCK) ON itm.ManufacturerId = man.ManufacturerId
        WHERE 
            vca.VendorCapabilityId = @VendorCapabilityId 
            AND vca.VendorId = @VendorId
        ORDER BY 
            vca.UpdatedDate DESC;

    END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetVendorCapabilityAudit' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
					  @DatabaseName        = @DatabaseName
                    , @AdhocComments       = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName     =  @ApplicationName
                    , @ErrorLogID          = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END