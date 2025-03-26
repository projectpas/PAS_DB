/***************************************************************  
 ** File:   [USP_ItemMasterSettings_GetHistorById]             
 ** Author:   Unknown
 ** Description: This stored procedure is used to get ItemMaster Settings Audit History List
 ** Date:  Unknown
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    ***********		Unknown				Created
    2    14-Feb-2025		Divyesh Kathiriya	Update CreatedDate and UpdateDate based on Employee time zone 
		
	exec dbo.USP_ItemMasterSettings_GetHistorById  @ItemMasterSettingsId=1, @EmployeeId=226

**************************************************************/

CREATE   PROCEDURE [dbo].[USP_ItemMasterSettings_GetHistorById]
@ItemMasterSettingsId bigint,
@EmployeeId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
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
					t.[ItemMasterSettingsId],
					t.[GLAccountId],
					t.[GLAccount],
					t.[MasterCompanyId],
					t.[CreatedBy],
					t.[UpdatedBy],
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(t.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(t.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					ELSE (CAST(t.CreatedDate AS DATETIME)) END CreatedDate,
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(t.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(t.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					ELSE (CAST(t.UpdatedDate AS DATETIME)) END UpdatedDate,
					t.[IsActive],
					t.[IsDeleted]
				FROM [DBO].[ItemMasterSettingsAudit] t WITH (NOLOCK) 
				WHERE t.[ItemMasterSettingsId] = @ItemMasterSettingsId ORDER BY t.[ItemMasterSettingsAuditId] DESC
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ItemMasterSettings_GetHistorById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterSettingsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END