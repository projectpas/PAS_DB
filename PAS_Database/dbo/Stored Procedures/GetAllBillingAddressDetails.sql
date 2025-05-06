/*******************************************************************************************
 ** File:   [GetAllBillingAddressDetails]           
 ** Author:  Ayushi Patel
 ** Description: This SP gets All Billing Address Details List
 ** Date:   01/05/2025    
 ** Parameters: 
    @VendorId BIGINT,
    @EmployeeId BIGINT        
 ** RETURN VALUE: 
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    01/05/2025  Ayushi Patel	    Created
 *******************************************************************************************/           

CREATE   PROCEDURE dbo.GetAllBillingAddressDetails
    @VendorId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

    BEGIN TRY

        -- Get Current Employee Timezone
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
        ad.Line1 AS Address1,
        ad.Line2 AS Address2,
        ad.Line3 AS Address3,
        ad.AddressId,
        ad.CountryId,
        cont.countries_name AS CountryName,
        ct.TagName,
        ad.PostalCode,
        ad.City,
        ad.StateOrProvince,
        v.SiteName,
        v.ContactTagId,
        v.Attention,
        v.VendorBillingAddressId,
		CAST(dbo.ConvertUTCtoLocal(v.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS CreatedDate,
        CAST(dbo.ConvertUTCtoLocal(v.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS UpdatedDate,
        v.CreatedBy,
        v.UpdatedBy,
        v.VendorId,
        ISNULL(v.IsActive,0),
        ISNULL(v.IsPrimary,0),
        ISNULL(v.IsDeleted,0)
    FROM dbo.VendorBillingAddress v WITH (NOLOCK)
    INNER JOIN dbo.Address ad WITH (NOLOCK) ON v.AddressId = ad.AddressId
    LEFT JOIN dbo.Countries cont WITH (NOLOCK) ON ad.CountryId = cont.countries_id
    LEFT JOIN dbo.ContactTag ct WITH (NOLOCK) ON v.ContactTagId = ct.ContactTagId
    WHERE v.VendorId = @VendorId;
	END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetAllBillingAddressDetails' 
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