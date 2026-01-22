/*************************************************************           
  ** File:   [USP_GetCustomerContactsByCustomerId]           
  ** Author:   Ekta Chandegra
  ** Description: This stored procedure is used to GetCustomerContactsByCustomerId
  ** Purpose:         
  ** Date:  29-Apr-2025 
          
  ** RETURN VALUE: 
  **************************************************************           
   ** Change History           
  **************************************************************           
  ** PR   Date			Author			Change Description            
  ** --   --------		-------			--------------------------------          
     1    29-Apr-2025   Ekta Chandegra	Created
      
  exec [dbo].[USP_GetCustomerContactsByCustomerId] @CustomerId=4293,@EmployeeId=223
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerContactsByCustomerId]
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
			c.ContactId,
			c.ContactTitle,
			c.AlternatePhone,
			c.CreatedBy,
			c.UpdatedBy,
			c.Email,
			c.Tag,
			c.Fax,
			c.FirstName,
			c.LastName,
			c.MiddleName,
			c.MobilePhone,
			c.Notes,
			c.Prefix,
			c.Suffix,
			c.WebsiteURL,
			c.WorkPhone,
			c.IsActive,
			vc.CustomerContactId,
			vc.IsDefaultContact,
			vc.CustomerId,
			(CAST(DBO.ConvertUTCtoLocal(c.CreatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
			(CAST(DBO.ConvertUTCtoLocal(c.UpdatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS UpdatedDate,
			c.WorkPhoneExtn,
			vc.IsDeleted,
			c.ContactTagId,
			ISNULL(c.Attention, '') AS Attention,
			CASE 
				WHEN c.WorkPhone IS NOT NULL AND c.WorkPhoneExtn IS NOT NULL AND LTRIM(RTRIM(c.WorkPhoneExtn)) <> ''
					THEN c.WorkPhone + '-' + c.WorkPhoneExtn
				ELSE c.WorkPhone
			END AS FullContactNo,
			vc.IsRestrictedParty,
			CASE 
				WHEN vc.IsRestrictedParty IS NULL THEN NULL
				WHEN vc.IsRestrictedParty = 0 THEN 'No'
				ELSE 'Yes'
			END AS IsRestrictedPartyfilter,
			c.FirstName + ' ' + c.LastName AS contactName
		FROM [dbo].[Contact] c WITH(NOLOCK)
		INNER JOIN [dbo].[CustomerContact] vc WITH(NOLOCK) ON c.ContactId = vc.ContactId
		WHERE vc.CustomerId = @CustomerId;
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
 			,@DatabaseName VARCHAR(100) = db_name()
 			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
 			,@AdhocComments VARCHAR(150) = 'USP_GetCustomerContactsByCustomerId'
 			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)) + ''' ,
 												   @Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) + '' 
      
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