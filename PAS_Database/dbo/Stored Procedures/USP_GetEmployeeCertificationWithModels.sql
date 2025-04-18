/*************************************************************           
 ** File:   [USP_GetEmployeeCertificationWithModels]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get Certification records by ID
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
CREATE     PROCEDURE [dbo].[USP_GetEmployeeCertificationWithModels]
    @EmployeeId INT,
    @EmployeeCertificationId INT
AS
BEGIN
    SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY  
		SELECT 
		     EC.EmployeeCertificationTypeId
			,EC.[EmployeeCertificationId]
			,EC.[EmployeeId]
			,EC.[CertificationNumber] as cert
            ,ECT.[Description] as certType 
			,EC.[CertifyingInstitution]
			,EC.[CertificationDate] AS certDate
			,EC.[CreatedBy]
			,EC.[CreatedDate]
			,EC.[IsExpirationDate]
			,EC.[ExpirationDate]
			,EC.[IsCertificationInForce] AS inforce
			,EC.[Memo]
			,EC.[IsActive]  
			,EC.[IsDeleted] 
			,EC.[MasterCompanyId]
			,EC.[UpdatedBy]
			,EC.[UpdatedDate]
		FROM [dbo].[EmployeeCertification] EC WITH(NOLOCK)  
				LEFT JOIN [dbo].[EmployeeCertificationType] ECT WITH(NOLOCK) ON EC.EmployeeCertificationTypeId = ECT.EmployeeCertificationTypeId
		WHERE EC.EmployeeId = @EmployeeId
		  AND EC.EmployeeCertificationId = @EmployeeCertificationId;
	END TRY 
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetEmployeeTrainingWithAircraftModels',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@EmployeeCertificationId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH   
END