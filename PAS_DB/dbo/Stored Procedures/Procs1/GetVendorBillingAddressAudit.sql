/*******************************************************************************************
 ** File:   [GetVendorBillingAddressAudit]           
 ** Author:  Ayushi Patel
 ** Description: This stored procedure is used to get audit history of Vendor Billing Address
 ** Purpose:  Get billing address audit log with timezone adjusted dates       
 ** Date:   30/04/2025      
          
 ** PARAMETERS: 
    @VendorId BIGINT,
    @VendorBillingAddressId BIGINT,
    @EmployeeId BIGINT
         
 ** RETURN VALUE:  Address audit list           
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    30/04/2025  Ayushi Patel	    Created
     
-- exec [dbo].[GetVendorBillingAddressAudit] @VendorId=1, @VendorBillingAddressId=10, @EmployeeId=5
********************************************************************************************/

CREATE   PROCEDURE [dbo].[GetVendorBillingAddressAudit]
    @VendorId BIGINT,
    @VendorBillingAddressId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

        SELECT 
            @CurrntEmpTimeZoneDesc = COALESCE(
                ETZ.[Description],  -- Prefer Employee's TimeZone description if available
                LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
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
            ad.SiteName,
            ad.SBAId,
            ad.AddressId,
            ad.Line1,
            ad.Line2,
            ad.City,
            ad.StateOrProvince,
            ad.ContactTagId,
            ad.Attention,
            ct.TagName,
            ad.PostalCode,
            ad.CountryId,
            cont.countries_name AS CountryName,
            CAST(dbo.ConvertUTCtoLocal(ad.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS CreatedDate,
            CAST(dbo.ConvertUTCtoLocal(ad.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS UpdatedDate,
            ad.CreatedBy,
            ad.UpdatedBy,
            ad.IsPrimary,
            ISNULL(ad.IsActive,0) AS IsActive,
            ISNULL(ad.IsDeleted,0) AS IsDeleted
        FROM 
            dbo.ShippingBillingAddressAudit ad WITH (NOLOCK)
        LEFT JOIN 
            dbo.Countries cont WITH (NOLOCK) ON ad.CountryId = cont.countries_id
        LEFT JOIN 
            dbo.ContactTag ct WITH (NOLOCK) ON ad.ContactTagId = ct.ContactTagId
        WHERE 
            ad.AddressId = @VendorBillingAddressId
            AND ad.ReferenceId = @VendorId
        ORDER BY 
            ad.SBAId DESC;

    END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetVendorBillingAddressAudit' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END