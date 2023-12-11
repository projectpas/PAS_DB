-----------------------------------------------------------------
--For adding New Condition, mastercompany wise in Condition Table
-----------------------------------------------------------------
DECLARE @MasterCompanyId int;
--DECLARE @EmployeeId BIGINT= 0;
DECLARE db_cursor CURSOR FOR 
SELECT MasterCompanyId 
FROM MasterCompany
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @MasterCompanyId  

WHILE @@FETCH_STATUS = 0  
BEGIN  
  --print @MasterCompanyId
BEGIN

IF NOT EXISTS (SELECT TOP 1 1 FROM FieldMaster(nolock) WHERE FieldName = 'statusValue' AND ModuleId = (SELECT TOP 1 GridModuleId FROM GridModule(nolock) WHERE ModuleName = 'SalesOrderQuoteHistory') AND MasterCompanyId=@MasterCompanyId)
BEGIN
	INSERT INTO FieldMaster([ModuleId],[FieldName],[HeaderName],[FieldWidth],[FieldType],[FieldAlign],[FieldFormate],[FieldSortOrder],[IsMultiValue],
	                        [IsToolTipShow],[IsRequired],[IsHidden],[IsNumString],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted])
	VALUES ((SELECT TOP 1 GridModuleId FROM GridModule(nolock) WHERE ModuleName = 'SalesOrderQuoteHistory') ,'statusValue','Status','120px','string',1,'',15,0,0,null,null,0,@MasterCompanyId,'AUTO SCRIPT',GETUTCDATE(),'AUTO SCRIPT',GETUTCDATE(),1,0)
END


END
  FETCH NEXT FROM db_cursor INTO @MasterCompanyId 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor

GO