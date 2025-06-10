/*************************************************************
 ** File:   [usp_CustVendorUpdatebyId]
 ** Author:   Bhargav Saliya
 ** Description: Update Customer or vendor When we Mapping vice versa
 ** Purpose:
 ** Date:   10-June-2025

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		  Change Description
 ** --   --------     -------		 --------------------------------
    1    10-June-2025   Bhargav Saliya   Created
**************************************************************/
Create      PROCEDURE [dbo].[usp_CustVendorUpdatebyId]
	@Id BIGINT,
	@MasterCompanyId BIGINT,
	@ModuleId BIGINT,
	@RefrenceId BIGINT = 0
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
	DECLARE @CustModuleIds BIGINT = (SELECT ModuleId from [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Customer');
	DECLARE @VendorModuleIds BIGINT = (SELECT ModuleId from [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor');

	IF(@CustModuleIds = @ModuleId)
	BEGIN
		UPDATE [dbo].[Customer]
		SET IsCustomerAlsoVendor = 1,UpdatedDate = GETUTCDATE() WHERE CustomerId = @Id AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0

		UPDATE [dbo].[Vendor]
		SET IsVendorAlsoCustomer = 1,RelatedCustomerId = @Id,UpdatedDate = GETUTCDATE() WHERE VendorId = @RefrenceId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0
	END

	ELSE IF(@VendorModuleIds = @ModuleId)
	BEGIN
		UPDATE [dbo].[Vendor]
		SET IsVendorAlsoCustomer = 1,RelatedCustomerId = @RefrenceId,UpdatedDate = GETUTCDATE() WHERE VendorId = @Id AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0

		UPDATE [dbo].[Customer] SET IsCustomerAlsoVendor = 1 WHERE CustomerId = @RefrenceId AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0 	
	END
	
  END TRY  
  BEGIN CATCH  
  
   DECLARE @ErrorLogID int,  
           @DatabaseName varchar(100) = DB_NAME(),  
           -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
           @AdhocComments varchar(150) = 'usp_CustVendorUpdatebyId',  
           @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Id, '') AS varchar(100)) +    
           '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) +  
           '@Parameter3 = ''' + CAST(ISNULL(@RefrenceId, '') AS varchar(100)) +  
		   '@Parameter4 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100)),  
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