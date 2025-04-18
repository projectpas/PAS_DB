/*************************************************************           
 ** File:   [USP_GetEmployeeCertificationHistoryById]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get Certification Informations history List
 ** Purpose:         
 ** Date:   18-04-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    18-04-2025    Sahdev Saliya       Created  

**************************************************************/    
CREATE   PROCEDURE [dbo].[USP_GetEmployeeCertificationHistoryById]    
@EmployeeCertificationId BIGINT = NULL,
@EmployeeId BIGINT
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY      
 
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

   BEGIN   
		SELECT ECA.[EmployeeCertificationId]
			,ECA.EmployeeId
			,ECA.[CertificationNumber] as cert
            ,ECT.[Description] as certType 
			,ECA.[CertifyingInstitution]
			,ECA.[CertificationDate] AS certDate
			,ECA.[ExpirationDate]
			,ECA.[IsCertificationInForce] AS inforce
			,ECA.[Memo]
			,ECA.[CreatedBy] 
			,ECA.[UpdatedBy]  
			,CASE WHEN CAST(ECA.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(ECA.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate]
			,ECA.MasterCompanyId
			,ECA.[IsActive]  
			,ECA.[IsDeleted]  
		FROM [dbo].[EmployeeCertificationAudit] ECA WITH(NOLOCK)  
				LEFT JOIN [dbo].[EmployeeCertificationType] ECT WITH(NOLOCK) ON ECA.EmployeeCertificationTypeId = ECT.EmployeeCertificationTypeId
		WHERE ECA.[EmployeeCertificationId] = @EmployeeCertificationId 
	ORDER BY ECA.[EmployeeCertificationId] DESC	
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetEmployeeCertificationHistoryById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeCertificationId, '') + ''    
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1);    
 END CATCH    
END