/***************************************************************************************          
 ** File:   [USP_GetCertificationTypeList]           
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used Get Certification Type
 ** Purpose:           
 ** Date:  04-15-2025  
           
 ** RETURN VALUE:             
 ********             
 ** Change History             
 ********             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			--------------------------------            
    1    04-15-2025    Bhargav Saliya		Created  

	--EXEC [USP_GetCertificationTypeList] @MasterCompanyId= 1
********************************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetCertificationTypeList]
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 
		SELECT 
			ECT.EmployeeCertificationTypeId,
			ECT.Description,
			ECT.MasterCompanyId,
			ECT.CreatedBy,
			ECT.CreatedDate,
			ECT.UpdatedBy,
			ECT.UpdatedDate,
			ECT.IsActive,
			ECT.IsDeleted
		FROM [dbo].EmployeeCertificationType ECT WITH(NOLOCK)
		WHERE ECT.IsDeleted = 0 AND ECT.MasterCompanyId = @MasterCompanyId
		ORDER BY ECT.UpdatedDate DESC;
	END TRY 
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetCertificationTypeList',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),  
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