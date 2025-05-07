/*************************************************************           
    ** File:  [GetShippingBillingAddressAudit]       
    ** Author:   Ekta Chandegra
    ** Description: This stored procedure is used to GetShippingBillingAddressAudit
    ** Purpose:         
    ** Date:  07-May-2025 
            
    ** RETURN VALUE: 
    **************************************************************           
     ** Change History           
    **************************************************************           
    ** PR   Date			Author			Change Description            
    ** --   --------		-------			--------------------------------          
       1    07-May-2025   Ekta Chandegra	Created
        
    exec [dbo].[GetShippingBillingAddressAudit] @ReferenceId=4299,@AddressId=5514,@AddressType=2,@ModuleId=1,@EmployeeId=223
 **************************************************************/
CREATE   PROCEDURE [dbo].[GetShippingBillingAddressAudit]
    @ReferenceId BIGINT,
    @AddressId BIGINT,
    @AddressType BIGINT,
    @ModuleId INT,
	@EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;	
	
		SELECT 
				vba.SiteName,
				ISNULL(vba.Attention,'') AS Attention,
				vba.ContactTagId,
				vba.SBAId,
				ISNULL(ct.TagName,'') AS TagName,
				vba.Line1 AS Address1,
				vba.Line2 AS Address2,
				vba.City,
				vba.StateOrProvince,
				vba.PostalCode,
				c.countries_name AS Country,
				(CAST(DBO.ConvertUTCtoLocal(vba.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS CreatedDate,
				vba.UpdatedBy,
				(CAST(DBO.ConvertUTCtoLocal(vba.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS UpdatedDate,
				vba.CreatedBy,
				ISNULL(vba.IsPrimary,0) AS IsPrimary,
				ISNULL(vba.IsActive,0) AS IsActive,
				ISNULL(vba.IsDeleted,0) AS IsDeleted
			FROM [dbo].[ShippingBillingAddressAudit] vba WITH(NOLOCK)
			LEFT JOIN [dbo].[Countries] c WITH(NOLOCK) ON vba.CountryId = c.countries_id
			LEFT JOIN [dbo].[ContactTag] ct WITH(NOLOCK) ON vba.ContactTagId = ct.ContactTagId
			WHERE vba.ReferenceId = @ReferenceId AND 
				  vba.AddressId = @AddressId AND 
				  vba.AddressType = @AddressType AND 
				  vba.ModuleId = @ModuleId
			ORDER BY vba.UpdatedDate DESC			
		
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
    	,@DatabaseName VARCHAR(100) = db_name()
    	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
    	,@AdhocComments VARCHAR(150) = 'GetShippingBillingAddressAudit'
    	,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS varchar(100)) + ''',
											   @Parameter2 = ''' + CAST(ISNULL(@AddressId, '') AS varchar(100)) + ''',
											   @Parameter3 = ''' + CAST(ISNULL(@AddressType, '') AS varchar(100)) + ''',
											   @Parameter4 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100)) + ''',
											   @Parameter5 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) + ''
    	,@ApplicationName VARCHAR(100) = 'PAS'
   		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
   		EXEC spLogException @DatabaseName = @DatabaseName
   			,@AdhocComments = @AdhocComments
   			,@ProcedureParameters = @ProcedureParameters
   			,@ApplicationName = @ApplicationName
   			,@ErrorLogID = @ErrorLogID OUTPUT;
    
   		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
   		RETURN (1);
	END CATCH
END