/*************************************************************           
 ** File:   [GetCustomerList]           
 ** Author:   Hemant Saliya
 ** Description: Save QuickBooks Params Detaiils for Logging
 ** Purpose:         
 ** Date:   15-July-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    15-July-2024   Hemant Saliya	Created (Save QuickBooks Params Detaiils for Logging)
     
 EXECUTE [QuickBooks_SaveRequestParamsDetails] 1, 10, '150'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_SaveRequestParamsDetails]
@IntegrationTypeId INT = NULL,
@ModuleId BIGINT = NULL,
@ReferenceId BIGINT = NULL,
@Payload VARCHAR(MAX),
@MasterCompanyId INT,
@UpdatedBy VARCHAR(200)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @ModuleName VARCHAR(200);
		SELECT @ModuleName = ModuleName FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = @ModuleId

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			INSERT INTO AccountingIntegrationLogs(IntegrationId,ModuleId,ReferenceId,ModuleName,Payload,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted)	
			VALUES (@IntegrationTypeId, @ModuleId, @ReferenceId, @ModuleName, @Payload, @MasterCompanyId, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
		END

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_SaveRequestParamsDetails'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END