/*************************************************************
** File:  [USP_GetCheckAddressListByVendorId]
** Author:   Ayushi Patel
** Description: Get Address List By Vendor Id
** Purpose:  
** Date:     03-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    03-07-2025   Ayushi Patel   Created

-- EXEC [USP_GetCheckAddressListByVendorId] 4797
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCheckAddressListByVendorId]
    @VendorId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
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
				dbo.TimeZone ETZ WITH (NOLOCK)
				ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN
				dbo.LegalEntity LE WITH (NOLOCK)
				ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN
				dbo.TimeZone LTZ WITH (NOLOCK)
				ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE
				E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee


        SELECT
            -- Address fields
            ad.Line1 AS Address1,
            ad.Line2 AS Address2,
            ad.Line3 AS Address3,
            ad.City,
            ad.StateOrProvince,
            ad.AddressId,
            ad.CountryId,
            cont.countries_name AS CountryName,
            ad.PostalCode,

            -- VendorCheckPayment fields
            vc.VendorCheckPaymentId,
            vc.VendorId,
            vc.CheckPaymentId,
            vc.MasterCompanyId,
            vc.CreatedBy AS VC_CreatedBy,
			(Cast(DBO.ConvertUTCtoLocal(vc.CreatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) AS VC_CreatedDate,
            vc.UpdatedBy AS VC_UpdatedBy,
			(Cast(DBO.ConvertUTCtoLocal(vc.UpdatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) AS VC_UpdatedDate,
            vc.IsActive AS VC_IsActive,
            vc.IsDeleted AS VC_IsDeleted,

            -- CheckPayment fields
            c.CheckPaymentId AS CP_CheckPaymentId,
            c.RoutingNumber,
            c.AccountNumber,
            c.SiteName,
            c.IsPrimayPayment,
            c.AddressId AS CP_AddressId,
            c.ContactTagId,
            c.Attention,
            c.CreatedBy AS CP_CreatedBy,
			(Cast(DBO.ConvertUTCtoLocal(c.CreatedDate, @CurrntEmpTimeZoneDesc) as DATETIME))  AS CP_CreatedDate,
            c.UpdatedBy AS CP_UpdatedBy,
			(Cast(DBO.ConvertUTCtoLocal(c.UpdatedDate, @CurrntEmpTimeZoneDesc) as DATETIME)) AS CP_UpdatedDate,
            c.IsDeleted AS CP_IsDeleted,

            -- ContactTag
            ct.TagName

        FROM dbo.CheckPayment c WITH (NOLOCK)
        INNER JOIN dbo.Address ad WITH (NOLOCK) ON c.AddressId = ad.AddressId
        LEFT JOIN dbo.Countries cont WITH (NOLOCK) ON ad.CountryId = cont.countries_id
        INNER JOIN dbo.VendorCheckPayment vc WITH (NOLOCK) ON c.CheckPaymentId = vc.CheckPaymentId
        LEFT JOIN dbo.ContactTag ct WITH (NOLOCK) ON c.ContactTagId = ct.ContactTagId
        WHERE vc.VendorId = @VendorId;

    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetCheckAddressListByVendorId'
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