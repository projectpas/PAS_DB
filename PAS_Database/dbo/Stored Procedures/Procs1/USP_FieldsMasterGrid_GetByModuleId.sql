/*************************************************************
 ** File:   [USP_FieldsMasterGrid_GetByModuleId]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used retrieve field name List    
 ** Purpose:         
 ** Date:   06/19/2023
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/19/2023   Vishal Suthar Created

 EXECUTE USP_FieldsMasterGrid_GetByModuleId 1, 0, 0, 0, 0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_FieldsMasterGrid_GetByModuleId]  
 @ModuleId BIGINT,  
 @EmployeeId BIGINT = NULL,  
 @GolbelFilter BIT = 0,  
 @ShowAll BIT = 0,  
 @MasterCompanyId INT  
AS  
BEGIN  
SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
 BEGIN TRY  
   
 IF EXISTS(SELECT FieldMasterId FROM [dbo].[EmployeeFieldMaster] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ModuleId = @ModuleId AND EmployeeId = @EmployeeId AND IsActive = 1)  
  BEGIN  
   IF (@ShowAll = 0)  
   BEGIN 
    SELECT EmployeeFieldMasterId, FieldMasterId, ModuleId, FieldName, HeaderName, FieldWidth, FieldType, FieldFormate, IsMultiValue, FieldSortOrder, IsActive, IsToolTipShow, [IsRequired], [IsHidden], FieldAlign, IsNumString   
    FROM [dbo].[EmployeeFieldMaster] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ModuleId = @ModuleId AND EmployeeId = @EmployeeId AND IsActive = 1 ORDER BY FieldSortOrder  
   END  
   ELSE  
   BEGIN  
    SELECT EmployeeFieldMasterId, FieldMasterId, ModuleId, FieldName, HeaderName, FieldWidth, FieldType, FieldFormate, IsMultiValue, FieldSortOrder, IsActive, IsToolTipShow, [IsRequired], [IsHidden], FieldAlign, IsNumString   
    FROM [dbo].[EmployeeFieldMaster] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ModuleId = @ModuleId AND EmployeeId = @EmployeeId ORDER BY FieldSortOrder  
   END  
  END  
 ELSE  
  BEGIN  
   IF (@ShowAll = 0)  
   BEGIN  
    SELECT FieldMasterId, ModuleId, FieldName, HeaderName, FieldWidth, FieldType, FieldAlign, FieldFormate, IsMultiValue, FieldSortOrder, IsActive, IsToolTipShow, IsRequired, IsHidden, IsNumString  
    FROM dbo.FieldMaster WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ModuleId = @ModuleId AND IsActive = 1 ORDER BY FieldSortOrder  
   END  
   ELSE  
   BEGIN  
    SELECT FieldMasterId, ModuleId, FieldName, HeaderName, FieldWidth, FieldType, FieldAlign, FieldFormate, IsMultiValue, FieldSortOrder, IsActive, IsToolTipShow, IsRequired, IsHidden, IsNumString  
    FROM dbo.FieldMaster WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ModuleId = @ModuleId ORDER BY FieldSortOrder  
   END  
  END  
  
 IF (@GolbelFilter = 1)  
 BEGIN  
  DECLARE @Sql NVARCHAR(MAX) = '';  
  CREATE TABLE #TempTable(        
   Value BIGINT,        
   Label VARCHAR(MAX),    
   MasterCompanyId INT,  
   AutoId BIGINT  
  );  
  
  DECLARE @AutoId BIGINT;  
  DECLARE @TableName NVARCHAR(100);  
  DECLARE @IDName NVARCHAR(50);  
  DECLARE @ValueName NVARCHAR(50);  
  
  DECLARE tablefeildcursor CURSOR FOR   
  SELECT AutoId, TableName, IDName, ValueName  
  FROM [dbo].[GlobalFilter] WITH (NOLOCK) WHERE ModuleId = @ModuleId AND ISNULL(TableName, '') != '' AND IsActive = 1  
  
  OPEN tablefeildcursor    
  FETCH NEXT FROM tablefeildcursor INTO @AutoId, @TableName, @IDName, @ValueName  
  WHILE @@FETCH_STATUS = 0    
  BEGIN           
  SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId, AutoId)     
   SELECT DISTINCT TOP 20 CAST ('+ @IDName +' AS BIGINT) AS Value,    
     CAST ( '+ @ValueName+  ' AS VARCHAR) AS Label, MasterCompanyId, ' + CONVERT(VARCHAR, @AutoId) + ' FROM [dbo].' + @TableName+         
   ' WITH(NOLOCK) ORDER BY Label'  
   EXEC sp_executesql @Sql;   
   FETCH NEXT FROM tablefeildcursor INTO @AutoId,@TableName,@IDName,@ValueName  
  END  
  
  CLOSE tablefeildcursor    
  DEALLOCATE tablefeildcursor   
  
  --SELECT AutoId, [ModuleId], [LabelName], [FieldType], [Sequence], [TableName], [IDName], [ValueName], [IsActive],  
  --CASE WHEN ISNULL(TableName, '') != '' THEN   
  --(SELECT TT.Value, TT.Label FROM #TempTable TT WHERE TT.AutoId = GF.AutoId FOR JSON PATH ) ELSE '' END   
  --AS FilterListValue  
  --FROM [dbo].[GlobalFilter] GF WITH (NOLOCK)  
  --WHERE ModuleId = @ModuleId AND IsActive = 1  
 END  
 END TRY  
 BEGIN CATCH  
   DECLARE @ErrorLogID INT  
   ,@DatabaseName VARCHAR(100) = db_name()  
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
   ,@AdhocComments VARCHAR(150) = 'USP_FieldsMaster_GetByModuleId'  
   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100))+  
   ',@Parameter2 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100))  
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