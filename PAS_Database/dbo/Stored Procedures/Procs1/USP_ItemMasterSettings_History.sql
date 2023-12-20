CREATE   PROCEDURE [DBO].[USP_ItemMasterSettings_History]
(
	@ItemMasterSettingsId BIGINT,
	@CreatedBy varchar(50)
)
AS
BEGIN
BEGIN TRY
	INSERT INTO [DBO].[ItemMasterSettingsAudit]
		([ItemMasterSettingsId], [GLAccountId] ,[GLAccount] , [MasterCompanyId] ,[CreatedBy] ,[UpdatedBy]
		,[CreatedDate] , [UpdatedDate] ,[IsActive] ,[IsDeleted])

	SELECT	[ItemMasterSettingsId], [GLAccountId] ,[GLAccount] ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy]
			,[CreatedDate] , [UpdatedDate] ,[IsActive] ,[IsDeleted] 
		FROM [ItemMasterSettings] 
		WHERE [ItemMasterSettingsId] = @ItemMasterSettingsId
END TRY
BEGIN CATCH
	DECLARE @ErrorLogID INT  
   ,@DatabaseName VARCHAR(100) = db_name()  
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
   ,@AdhocComments VARCHAR(150) = 'USP_ItemMasterSettings_History'  
   ,@ProcedureParameters VARCHAR(3000) = '@ItemMasterSettingsId = ''' + CAST(ISNULL(@ItemMasterSettingsId, '') AS varchar(100))  
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