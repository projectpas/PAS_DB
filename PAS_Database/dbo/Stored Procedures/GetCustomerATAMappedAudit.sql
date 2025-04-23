/*************************************************************           
 ** File:   [GetCustomerATAMappedAudit]           
 ** Author:   Ekta Chandegra
 ** Description: This stored procedure is used to GetCustomerATAMappedAudit
 ** Purpose:         
 ** Date:  23-Apr-2025 
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    23-Apr-2025   Ekta Chandegra	Created
     
 exec dbo.GetCustomerATAMappedAudit @CustomerContactATAMappingId=110,@EmployeeId=223
**************************************************************/
CREATE   PROCEDURE [dbo].[GetCustomerATAMappedAudit]
    @CustomerContactATAMappingId BIGINT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Get the employee's time zone description
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
            ca.AuditCustomerContactATAMappingId,
            ca.CustomerContactATAMappingId,
            ca.CustomerId,
            ca.ATAChapterId,
            ca.ATASubChapterDescription,
            ct.FirstName,
            ct.ContactId,
            ca.UpdatedBy,
            (CAST(DBO.ConvertUTCtoLocal(ca.UpdatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS UpdatedDate,
            ca.CreatedBy,
            (CAST(DBO.ConvertUTCtoLocal(ca.CreatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate,
            ca.IsDeleted,
            '' AS ATASubChapterCode,
            ca.Level1 +
                CASE WHEN ISNULL(ca.Level2, 0) > 0 THEN '-' + CAST(ca.Level2 AS VARCHAR) ELSE '' END +
                CASE WHEN ISNULL(ca.Level3, 0) > 0 THEN '-' + CAST(ca.Level3 AS VARCHAR) ELSE '' END AS ATAChapterName
        FROM [dbo].[CustomerContactATAMappingAudit] ca WITH(NOLOCK)
        INNER JOIN [dbo].[CustomerContact] cc WITH(NOLOCK) ON ca.CustomerContactId = cc.CustomerContactId
        LEFT JOIN [dbo].[Contact] ct WITH(NOLOCK) ON cc.ContactId = ct.ContactId
        WHERE ca.CustomerContactATAMappingId = @CustomerContactATAMappingId
        ORDER BY (CAST(DBO.ConvertUTCtoLocal(ca.UpdatedDate, @CurrntEmpTimeZoneDesc)AS DATETIME)) DESC;
    END TRY
    BEGIN CATCH
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'GetCustomerATAMappedAudit'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerContactATAMappingId, '') AS varchar(100)) + ''' ,
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