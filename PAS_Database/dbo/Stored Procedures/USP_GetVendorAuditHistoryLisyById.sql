/***************************************************************************************          
 ** File:   [USP_GetVendorAuditHistoryLisyById]            
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Get JournalBatchDetailsById for PO List
 ** Purpose:           
 ** Date:   24-03-2025   
           
 ** RETURN VALUE:             
 ********             
 ** Change History             
 ********             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    24-03-2025    Bhargav Saliya		Created  

	exec dbo.USP_GetVendorAuditHistoryLisyById @VendorAuditInfoId=1,@EmployeeId=219
********************************************************************************/   
Create     PROCEDURE [dbo].[USP_GetVendorAuditHistoryLisyById]    
@VendorAuditInfoId bigint,
@EmployeeId bigint
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
		SELECT VAA.[VendorAuditInfoAuditId]
			,VAA.[VendorAuditInfoId] 
			,VAA.[VendorId]  
			,VOT.[VendorOrderTypeId]
			,VOT.[OrderTypeName] 
			,VAT.[VendorAuditTypeId]
			,VAT.[VendorAuditType]  
			,VAA.[FrequencyDays] 
			,VAA.LastAuditDate
			,VAA.[NextAuditDate]  
			,VAA.[Expired]  
			,VAA.[AuditFindings]  
			,VAA.[ActionsTaken]  
			,VAA.[CreatedBy] 
			,VAA.[UpdatedBy]  
			,CASE WHEN CAST(VAA.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(VAA.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [CreatedDate]
			,CASE WHEN CAST(VAA.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(VAA.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate]
			,VAA.MasterCompanyId
			,VAA.[IsActive]  
			,VAA.[IsDeleted]  
		FROM [dbo].[VendorAuditInfoAudit] VAA WITH(NOLOCK)  
		INNER JOIN [dbo].[VendorOrderType] VOT WITH(NOLOCK) ON VAA.VendorOrderTypeId = VOT.VendorOrderTypeId
		INNER JOIN [dbo].[VendorAuditType] VAT WITH(NOLOCK) ON VAA.VendorAuditTypeId = VAT.VendorAuditTypeId
		WHERE VAA.[VendorAuditInfoId] = @VendorAuditInfoId  
	order by VAA.[VendorAuditInfoAuditId] desc	
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorAuditHistoryLisyById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorAuditInfoId, '') + ''    
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
 END CATCH    
END