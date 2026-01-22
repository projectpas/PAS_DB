/***************************************************************  
 ** File:   [USP_ItemMasterSettings_list]             
 ** Author:   Unknown
 ** Description: This stored procedure is used to get ItemMaster Settings List
 ** Date:  Unknown
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    ***********		Unknown				Created
    2    17-Feb-2025		Divyesh Kathiriya	Update CreatedDate and UpdateDate based on Employee time zone 
		
	exec dbo.USP_ItemMasterSettings_list  @MasterCompanyId=1, @EmployeeId=226

**************************************************************/

CREATE   PROCEDURE [dbo].[USP_ItemMasterSettings_list]
@MasterCompanyId bigint,
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
					ims.[ItemMasterSettingsId],
					ims.[GLAccountId],
					ims.[GLAccount],
					ims.[MasterCompanyId],
					ims.[CreatedBy],
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(ims.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ims.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					ELSE (CAST(ims.CreatedDate AS DATETIME)) END CreatedDate,
					ims.[UpdatedBy],
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(ims.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ims.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					ELSE (CAST(ims.UpdatedDate AS DATETIME)) END UpdatedDate,
					ims.[IsActive],
					ims.[IsDeleted]
				FROM [DBO].[ItemMasterSettings] ims WITH (NOLOCK)				
				WHERE ims.[MasterCompanyId] = @MasterCompanyId
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ItemMasterSettings_list' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''
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