/*************************************************************           
 ** File:   [usp_GetEmployeeCertificationList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get Certification Informations List
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
CREATE   PROCEDURE [dbo].[usp_GetEmployeeCertificationList]
@EmployeeId BIGINT,
@MasterCompanyId BIGINT, 
@IsdeleteStatus BIT = 0  

AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
			 ;WITH rptCTE (TotalRecordsCount, EmployeeCertificationId,EmployeeId, CertificationNumber, certType, CertifyingInstitution, CertificationDate, ExpirationDate,
				IsCertificationInForce, Memo, IsActive, IsDeleted, MasterCompanyId) 
				 AS (

		 SELECT COUNT(1) OVER () AS TotalRecordsCount,
				    EC.[EmployeeCertificationId],
	  				EC.EmployeeId,
					EC.CertificationNumber AS cert, 
			        ECT.[Description] AS certType,  
					EC.CertifyingInstitution AS ascertifyingInstitution,  
					EC.CertificationDate AS certDate, 
					EC.ExpirationDate AS expirationDate,
					EC.[IsCertificationInForce] AS inforce,
					EC.[Memo], 
					EC.[IsActive],
					EC.[IsDeleted],
					EC.[MasterCompanyId]
				FROM [dbo].[EmployeeCertification] EC WITH(NOLOCK)				
					LEFT JOIN [dbo].[EmployeeCertificationType] ECT WITH(NOLOCK) ON EC.EmployeeCertificationTypeId = ECT.EmployeeCertificationTypeId

				WHERE EC.EmployeeId = @EmployeeId AND EC.MasterCompanyId = @MasterCompanyId AND EC.IsDeleted = @IsdeleteStatus 

				GROUP BY EC.EmployeeCertificationId,EC.EmployeeId, EC.[CertificationNumber],ECT.[Description],EC.[CertifyingInstitution],EC.[CertificationDate],
			             EC.[ExpirationDate],EC.[IsCertificationInForce],EC.[IsCertificationInForce],EC.[Memo],EC.[IsActive],EC.[IsDeleted],EC.[CreatedBy],EC.[UpdatedBy],EC.[UpdatedDate],EC.[MasterCompanyId]
						 )
				         ,FinalCTE(TotalRecordsCount, EmployeeCertificationId,EmployeeId, CertificationNumber, certType, CertifyingInstitution, CertificationDate, ExpirationDate,
				          IsCertificationInForce, Memo, IsActive, IsDeleted, MasterCompanyId) 
				
			             AS (SELECT DISTINCT TotalRecordsCount, EmployeeCertificationId,EmployeeId, CertificationNumber, certType, CertifyingInstitution, CertificationDate, ExpirationDate,
				           IsCertificationInForce, Memo, IsActive, IsDeleted, MasterCompanyId FROM rptCTE)

			             SELECT COUNT(2) OVER () AS TotalRecordsCount, EmployeeCertificationId,EmployeeId, CertificationNumber, certType, CertifyingInstitution, CertificationDate, ExpirationDate,
				             IsCertificationInForce, Memo, IsActive, IsDeleted, MasterCompanyId
		                 FROM FinalCTE FC

	                    ORDER BY EmployeeCertificationId DESC	
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_GetEmployeeCertificationList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) + 
			  '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) +    
              '@Parameter3 = ''' + CAST(ISNULL(@IsdeleteStatus, '') AS varchar(max)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END