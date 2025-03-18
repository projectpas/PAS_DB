/*************************************************************          
 ** File:   [USP_GetGLAllocationDetailsHistoryById]           
 ** Author:   SAHDEV SALIYA
 ** Description: Get Data for GetGLAllocationDetailsHistory
 ** Purpose:         
 ** Date:   03-07-2024    
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
**************************************************************           
  ** Change History           
**************************************************************            
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    03-07-2024			SAHDEV SALIYA		Created
	2    26-07-2024			SAHDEV SALIYA		Set DistributionSetupAuditId Order by desc
	3    17-09-2024			AMIT GHEDIYA		added AutoPost..
	4    04-Mar-2025		Divyesh Kathiriya	Update CreatedDate and UpdateDate based on Employee time zone

	exec [USP_GetGLAllocationDetailsHistoryById] 16,1,226

**************************************************************/ 

CREATE      PROCEDURE [dbo].[USP_GetGLAllocationDetailsHistoryById]
	@journalTypeID bigint = null,
	@MasterCompanyId bigint = null,
	@EmployeeId bigint = Null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
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

				Select	
                    jt.JournalTypeName,
					jt.JournalTypeCode,
					Dt.JournalTypeId,
					Dt.MasterCompanyId,
					Dt.Name as DistributionName,
					Dt.CreatedBy,
                    Dt.UpdatedBy,
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(Dt.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(Dt.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					ELSE (CAST(Dt.CreatedDate AS DATETIME)) END CreatedDate,
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(Dt.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(Dt.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					ELSE (CAST(Dt.UpdatedDate AS DATETIME)) END UpdatedDate,
					Dt.CRDRType,
					CASE WHEN Dt.CRDRType=1 THEN 'DR'  WHEN Dt.CRDRType=0 THEN 'CR' WHEN Dt.CRDRType=2 THEN 'DR/CR' ELSE '' END as 'CRDRTypeName',
					Dt.GlAccountNumber,
					Dt.GlAccountName,
					Dt.IsAutoPost
				FROM DBO.DistributionSetupAudit DT  WITH(NOLOCK)
				LEFT JOIN DBO.JournalType JT WITH (NOLOCK) ON JT.ID = DT.JournalTypeId
				WHERE DT.JournalTypeId = @journalTypeID and Dt.MasterCompanyId = @MasterCompanyId
				ORDER BY DT.DistributionSetupAuditId DESC;

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetGLAllocationDetailsHistoryById' 
              , @ProcedureParameters VARCHAR(3000)  = '@journalTypeID = '''+ ISNULL(@journalTypeID, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END