/*************************************************************           
 ** File:   [USP_EmployeeCertificationInsertList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get EmployeeCertificationInsert List
 ** Purpose:         
 ** Date:   11-08-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    11-08-2025    Sahdev Saliya       Created  

	exec [USP_EmployeeCertificationInsertList] 
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_EmployeeCertificationInsertList]
    @EmployeeId BIGINT=NULL,
	@CertificationNumber varchar(256)=NULL,
    @EmployeeCertificationTypeId BIGINT=NULL,
	@CertifyingInstitution varchar(256)=NULL,
	@CertificationDate DATETIME=NULL,
	@IsCertificationInForce BIT=NULL,
	@MasterCompanyId BIGINT=NULL,
    @CreatedBy VARCHAR(256)=NULL,
	@UpdatedBy VARCHAR(256)=NULL,
	@IsActive BIT=NULL,
	@ExpirationDate DATETIME=NULL,
	@IsExpirationDate BIT=NULL,
	@IsDeleted BIT=NULL,
	@Memo varchar(256)=NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
    BEGIN TRY

	 INSERT INTO [dbo].[EmployeeCertification]
           (EmployeeId,
            CertificationNumber,
            EmployeeCertificationTypeId,
            CertifyingInstitution,
			CertificationDate,
			IsCertificationInForce,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy,
			CreatedDate,
			UpdatedDate,
			IsActive,
			ExpirationDate,
			IsExpirationDate,
			IsDeleted,
			Memo)
	   VALUES
           (@EmployeeId,
            @CertificationNumber,
            @EmployeeCertificationTypeId,
            @CertifyingInstitution,
			@CertificationDate,
			@IsCertificationInForce,
			@MasterCompanyId,
			@CreatedBy,
			@UpdatedBy,
			GETUTCDATE(),
			GETUTCDATE(),
			@IsActive,
			@ExpirationDate,
			ISNULL(@IsExpirationDate, 0),
			@IsDeleted,
			@Memo);
		
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
		    WHERE [EmployeeId] = @EmployeeId;

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