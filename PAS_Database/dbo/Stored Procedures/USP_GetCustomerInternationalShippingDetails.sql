/*************************************************************           
   ** File:   [USP_GetCustomerInternationalShippingDetails]           
   ** Author:   Ekta Chandegra
   ** Description: This stored procedure is used to GetCustomerInternationalShippingDetails
   ** Purpose:         
   ** Date:  01-May-2025 
           
   ** RETURN VALUE: 
   **************************************************************           
    ** Change History           
   **************************************************************           
   ** PR   Date			Author			Change Description            
   ** --   --------		-------			--------------------------------          
      1    01-May-2025   Ekta Chandegra	Created
       
   exec [dbo].[USP_GetCustomerInternationalShippingDetails] @ReferenceId=4293,@ModuleId=1,@ContactId=6564,@EmployeeId=223
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerInternationalShippingDetails]
    @CustomerId BIGINT,
	@EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @CurrntEmpTimeZoneDesc NVARCHAR(100);
  		SELECT @CurrntEmpTimeZoneDesc = COALESCE(
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
  				E.EmployeeId = @EmployeeId;

		SELECT 
			c.CustomerInternationalShippingId,
			c.Amount,
			c.StartDate,
			c.ExpirationDate,
			c.Description,
			(CAST(DBO.ConvertUTCtoLocal(c.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
			(CAST(DBO.ConvertUTCtoLocal(c.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS UpdatedDate,
			c.CustomerId,
			c.IsActive,
			c.IsDeleted,
			c.IsPrimary,
			c.ExportLicense,
			co.countries_name AS ShipToCountry,
			co.countries_id AS ShipToCountryId,
			c.CreatedBy,
			c.UpdatedBy
		FROM [dbo].[CustomerInternationalShipping] c WITH(NOLOCK)
		LEFT JOIN [dbo].[Countries] co WITH(NOLOCK) ON c.ShipToCountryId = co.countries_id
		WHERE c.CustomerId = @CustomerId
		ORDER BY c.CreatedDate DESC;
	END TRY
	BEGIN CATCH
	END CATCH
END