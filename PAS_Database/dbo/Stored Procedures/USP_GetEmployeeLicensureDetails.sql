/*************************************************************           
 ** File:   [USP_GetEmployeeLicensureDetails]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get Employee LicensureDetails List
 ** Purpose:         
 ** Date:   17-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    17-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetEmployeeLicensureDetails]
    @EmployeeId  BIGINT       
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
		BEGIN TRY


			SELECT 
			        EC.EmployeeCertificationId,
					EC.EmployeeId,
					EC.CertificationNumber,
					EC.EmployeeCertificationTypeId,
					EC.CertifyingInstitution,
					EC.CertificationDate,
					EC.IsCertificationInForce,
					EC.ExpirationDate,
					EC.IsExpirationDate,
					EC.Memo,
					'' AS CertType,
				    '' AS Inforce,
					EC.MasterCompanyId,
					EC.CreatedBy,
					EC.CreatedDate,
					EC.UpdatedBy,
					EC.UpdatedDate,
					EC.IsActive,
					EC.IsDeleted
			FROM [DBO].EmployeeCertification EC WITH(NOLOCK)
			WHERE EC.EmployeeId = @EmployeeId;
	    END TRY

   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetEmployeeLicensureDetails' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '') 

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