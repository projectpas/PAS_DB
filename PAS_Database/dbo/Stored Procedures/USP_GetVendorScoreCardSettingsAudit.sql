/*************************************************************           
 ** File:   [dbo].[USP_GetVendorScoreCardSettingsAudit]          
 ** Author:   BHARGAV SALIA
 ** Description: Get Vendor Score Card Setup History
 ** Date:   26-Mar-2025  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
	1    26-Mar-2025   BHARGAV SALIA			Created

**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetVendorScoreCardSettingsAudit]
    @VendorScoreCardSettingsId INT,
	@EmployeeId BIGINT
AS
BEGIN
		SET NOCOUNT ON;	
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			DECLARE @EmpLegalEntiyId BIGINT = 0;
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
			SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description],LTZ.[Description])
				FROM dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE E.EmployeeId = @EmployeeId; 
				
			SELECT 
				VSC.VendorScoreCardSettingsAuditId,
				VSC.VendorScoreCardSettingsId,
				VSC.Rating,
				VSC.OnTimeDelivery,
				VSC.Description,
				VSC.StatusId,
				VSC.MasterCompanyId,
				VSC.CreatedBy,
				VSC.UpdatedBy,
				CASE WHEN CAST(VSC.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(VSC.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END CreatedDate,
				CASE WHEN CAST(VSC.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(VSC.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END UpdatedDate,
				VSC.IsActive,
				VSC.IsDeleted,
				VSC.MasterCompanyId

			FROM [DBO].VendorScoreCardSettingsAudit VSC WITH(NOLOCK)
			WHERE VSC.VendorScoreCardSettingsId = @VendorScoreCardSettingsId
			ORDER BY VSC.VendorScoreCardSettingsAuditId DESC;
		END TRY
		BEGIN CATCH      
			IF @@trancount > 0			
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorScoreCardSettingsAudit' 
			  , @ProcedureParameters VARCHAR(3000) = '@SalesOrderId = ''' + CAST(ISNULL(@VendorScoreCardSettingsId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH    
END