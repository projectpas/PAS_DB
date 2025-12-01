/*************************************************************           
 ** File:		[dbo].[USP_GetAircraftMappedAudit]         
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used for getting history of ItemMasterAircraft
 ** Purpose:         
 ** Date:   26-09-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		-------------    	-------------------          
	 1	 26-09-2025			Nakul Chandigra		Created
	 EXEC  [dbo].[USP_GetAircraftMappedAudit] 82445,2
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetAircraftMappedAudit]
@ItemMasterAircraftMappingId BIGINT,
@EmpId BIGINT
AS
BEGIN

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmpId; 

	BEGIN TRY
		SELECT AuditItemMasterAircraftMappingId ,
			   ItemMasterAircraftMappingId,
			   ItemMasterId ,
			   AircraftModelId, 
			   AircraftTypeId, 
			   DashNumberId ,
			   PartNumber ,
			   DashNumber ,
			   AircraftType, 
			   AircraftModel, 
			   Memo ,
			   MasterCompanyId, 
			   CreatedBy ,
			   UpdatedBy ,
			   CASE WHEN CAST(CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
			   CASE WHEN CAST(UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate],
			   IsActive ,
			   IsDeleted ,
			   ATAReferenceId, 
			   ATAReference ,
		       Level1 ,
			   Level2,
		       Level3,
			   ATAChapter = Level1 
              + CASE WHEN Level2 IS NOT NULL AND Level2 <> '' THEN '-' + Level2 ELSE '' END
              + CASE WHEN Level3 IS NOT NULL AND Level3 <> '' THEN '-' + Level3 ELSE '' END

		FROM [dbo].ItemMasterAircraftMappingAudit WITH(NOLOCK)
		WHERE ItemMasterAircraftMappingId = @itemMasterAircraftMappingId
		ORDER BY AuditItemMasterAircraftMappingId DESC 

	END TRY 

	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteRestoreItemMasterAircraftStatus'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
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