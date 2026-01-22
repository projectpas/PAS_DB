/*************************************************************           
  ** File:   [USP_GetCustomerAircraftMappingAudit]           
  ** Author:   Ekta Chandegra
  ** Description: This stored procedure is used to GetCustomerAircraftMappingAudit
  ** Purpose:         
  ** Date:  29-Apr-2025 
          
  ** RETURN VALUE: 
  **************************************************************           
   ** Change History           
  **************************************************************           
  ** PR   Date			Author			Change Description            
  ** --   --------		-------			--------------------------------          
     1    29-Apr-2025   Ekta Chandegra	Created
      
  exec [dbo].[USP_GetCustomerAircraftMappingAudit] @CustomerAircraftMappingId=327,@EmployeeId=223
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerAircraftMappingAudit]
    @CustomerAircraftMappingId BIGINT,
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
			c.CustomerAircraftMappingId,
			c.AuditCustomerAircraftMappingId,
			c.CustomerId,
			c.AircraftTypeId,
			c.AircraftType,
			c.AircraftModelId,
			c.DashNumberId,
			c.CreatedBy,
			c.UpdatedBy,
			(CAST(DBO.ConvertUTCtoLocal(c.UpdatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS UpdatedDate,
			(CAST(DBO.ConvertUTCtoLocal(c.CreatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
			c.DashNumber,
			c.AircraftModel,
			c.Inventory,
			c.MasterCompanyId,
			c.IsDeleted,
			c.IsActive
		FROM [dbo].[CustomerAircraftMappingAudit] c WITH(NOLOCK)
		WHERE c.CustomerAircraftMappingId = @CustomerAircraftMappingId
		ORDER BY c.AuditCustomerAircraftMappingId DESC;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
 			,@DatabaseName VARCHAR(100) = db_name()
 			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
 			,@AdhocComments VARCHAR(150) = 'USP_GetCustomerAircraftMappingAudit'
 			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerAircraftMappingId, '') AS varchar(100)) + ''' ,
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