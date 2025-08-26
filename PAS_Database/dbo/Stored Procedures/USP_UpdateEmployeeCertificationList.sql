/*************************************************************           
 ** File:   [USP_UpdateEmployeeCertificationList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get UpdateEmployeeCertification List
 ** Purpose:         
 ** Date:   25-08-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    25-08-2025    Sahdev Saliya       Created  

	exec [USP_UpdateEmployeeCertificationList] 
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateEmployeeCertificationList]
    @id  BIGINT=NULL,
    @MasterCompanyId BIGINT,
    @IsActive BIT,
    @CertificationDate DATETIME = NULL,
    @ExpirationDate DATETIME = NULL,
    @CertifyingInstitution NVARCHAR(200) = NULL,
    @EmployeeId BIGINT,
    @CertificationNumber NVARCHAR(100) = NULL,
    @EmployeeCertificationTypeId BIGINT = NULL, 
    @IsCertificationInForce BIT = NULL,
    @IsExpirationDate BIT = NULL,
    @UpdatedBy NVARCHAR(256) = NULL,
    @Memo NVARCHAR(MAX) = NULL

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

        UPDATE [dbo].[EmployeeCertification]
        SET MasterCompanyId = @MasterCompanyId,
            IsActive = @IsActive,
            CertificationDate = @CertificationDate,
            ExpirationDate = @ExpirationDate,
            CertifyingInstitution = @CertifyingInstitution,
            EmployeeId = @EmployeeId,
            CertificationNumber = @CertificationNumber,
            EmployeeCertificationTypeId = @EmployeeCertificationTypeId,
            IsCertificationInForce = @IsCertificationInForce,
            IsExpirationDate = @IsExpirationDate,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy,
            Memo = @Memo

        WHERE EmployeeCertificationId = @id;

		BEGIN TRY
		SELECT [EmployeeId]
			,[EmployeeCertificationId]
			,[CertificationNumber]
			,[EmployeeCertificationTypeId]
			,[CertifyingInstitution]
			,[CertificationDate]
			,[IsCertificationInForce]
			,[ExpirationDate]
			,[IsExpirationDate]
			,[Memo]
			,[MasterCompanyId]
			,[CreatedBy]
			,[UpdatedBy]
			,[CreatedDate]
			,[UpdatedDate]
			,[IsActive]
			,[IsDeleted]
		    FROM [dbo].[EmployeeCertification] WITH(NOLOCK) 
		    WHERE [EmployeeCertificationId] = @id;

     END TRY
     BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_EmployeeCertificationInsertList' 
				  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') as varchar(100))   
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