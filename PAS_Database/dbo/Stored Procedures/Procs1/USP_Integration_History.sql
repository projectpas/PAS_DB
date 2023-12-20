CREATE   PROCEDURE [DBO].[USP_Integration_History]
(
	@ThirdPartInegrationId BIGINT,
	@CreatedBy varchar(50)
)
AS
BEGIN
BEGIN TRY
	INSERT INTO [DBO].[ThirdPartInegrationAudit]
		([ThirdPartInegrationId], [LegalEntityId] ,[CageCode] ,[IntegrationIds] ,[SecretKey] ,[AccessKey] ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy]
		,[CreatedDate] , [UpdatedDate] ,[IsActive] ,[IsDeleted])

	SELECT	[ThirdPartInegrationId], [LegalEntityId] ,[CageCode] ,[IntegrationIds] ,[SecretKey] ,[AccessKey] ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy]
			,[CreatedDate] , [UpdatedDate] ,[IsActive] ,[IsDeleted] 
		FROM [ThirdPartInegration] 
		WHERE ThirdPartInegrationId = @ThirdPartInegrationId
END TRY
BEGIN CATCH
	DECLARE @ErrorLogID INT  
   ,@DatabaseName VARCHAR(100) = db_name()  
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
   ,@AdhocComments VARCHAR(150) = 'USP_Integration_History'  
   ,@ProcedureParameters VARCHAR(3000) = '@ThirdPartInegrationId = ''' + CAST(ISNULL(@ThirdPartInegrationId, '') AS varchar(100))  
    + '@EmployeeId = ''' + CAST(ISNULL(@CreatedBy, '') as varchar(100))          
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