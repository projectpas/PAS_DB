/*************************************************************           
   ** File:   [USP_GetContactAuditHistory]           
   ** Author:   Ekta Chandegra
   ** Description: This stored procedure is used to GetContactAuditHistory
   ** Purpose:         
   ** Date:  01-May-2025 
           
   ** RETURN VALUE: 
   **************************************************************           
    ** Change History           
   **************************************************************           
   ** PR   Date			Author			Change Description            
   ** --   --------		-------			--------------------------------          
      1    01-May-2025   Ekta Chandegra	Created
       
   exec [dbo].[USP_GetContactAuditHistory] @ReferenceId=4293,@ModuleId=1,@ContactId=6564,@EmployeeId=223
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetContactAuditHistory]
    @ReferenceId BIGINT,
    @ModuleId INT,
    @ContactId BIGINT,
	@EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @LegalEntityModuleId INT;
		SELECT @LegalEntityModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity';
    
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

		IF @ModuleId = @LegalEntityModuleId -- If @ModuleId is LegalEntity Module Id
		BEGIN
			SELECT 
				ca.AuditContactId,
				ca.ContactId,
				ca.Notes,
				ca.LastName,
				ca.FirstName,
				ca.Tag AS TagName,
				ca.Attention,
				ca.MiddleName,
				ca.ContactTitle,
				ca.WorkPhone,
				ca.MobilePhone,
				ca.Prefix,
				ca.Suffix,
				ca.AlternatePhone,
				ca.WorkPhoneExtn,
				ca.Fax,
				ca.Email,
				ca.WebsiteURL,
				ca.MasterCompanyId,
				(CAST(DBO.ConvertUTCtoLocal(ca.CreatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
				(CAST(DBO.ConvertUTCtoLocal(ca.UpdatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS UpdatedDate,
				ca.CreatedBy,
				ca.UpdatedBy,
				ca.IsActive,
				CASE 
					WHEN ca.WorkPhone IS NOT NULL AND ca.WorkPhoneExtn IS NOT NULL AND LTRIM(RTRIM(ca.WorkPhoneExtn)) <> '' 
					THEN ca.WorkPhone + '-' + ca.WorkPhoneExtn 
					ELSE ca.WorkPhone 
				END AS FullContact,
				ca.IsDefaultContact,
				ca.IsDeleted
			FROM [dbo].[ContactAudit] ca WITH(NOLOCK)
			WHERE ca.ReferenceId = @ReferenceId 
			  AND ca.ModuleId = @ModuleId 
			  AND ca.ContactId = @ContactId
			ORDER BY ca.AuditContactId DESC
		END
		ELSE -- If @ModuleId is not LegalEntity Module Id
		BEGIN
			SELECT 
				ca.AuditContactId,
				ca.ContactId,
				ca.Notes,
				ca.LastName,
				ca.FirstName,
				ca.Tag AS TagName,
				ca.Attention,
				ca.MiddleName,
				ca.ContactTitle,
				ca.WorkPhone,
				ca.MobilePhone,
				ca.Prefix,
				ca.Suffix,
				ca.AlternatePhone,
				ca.WorkPhoneExtn,
				ca.Fax,
				ca.Email,
				ca.WebsiteURL,
				ca.MasterCompanyId,
				(CAST(DBO.ConvertUTCtoLocal(ca.CreatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
				(CAST(DBO.ConvertUTCtoLocal(ca.UpdatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS UpdatedDate,
				ca.CreatedBy,
				ca.UpdatedBy,
				ca.IsActive,
				CASE 
					WHEN ca.WorkPhone IS NOT NULL AND ca.WorkPhoneExtn IS NOT NULL AND LTRIM(RTRIM(ca.WorkPhoneExtn)) <> '' 
					THEN ca.WorkPhone + '-' + ca.WorkPhoneExtn 
					ELSE ca.WorkPhone 
				END AS FullContact,
				ca.IsDefaultContact,
				ca.IsDeleted
			FROM [dbo].[ContactAudit] ca WITH(NOLOCK)
			LEFT JOIN [dbo].[ContactTag] ct WITH(NOLOCK) ON ca.ContactTagId = ct.ContactTagId
			WHERE ca.ReferenceId = @ReferenceId 
			  AND ca.ModuleId = @ModuleId 
			  AND ca.ContactId = @ContactId
			ORDER BY ca.UpdatedDate DESC
		END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
  			,@DatabaseName VARCHAR(100) = db_name()
  			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
  			,@AdhocComments VARCHAR(150) = 'USP_GetContactAuditHistory'
  			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS varchar(100)) + ''' ,
  												   @Parameter2 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100)) + ''', 
							        			   @Parameter3 = ''' + CAST(ISNULL(@ContactId, '') AS varchar(100)) + ''',
												   @Parameter4 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) + ''
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