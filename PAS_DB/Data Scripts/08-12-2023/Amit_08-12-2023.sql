
UPDATE FieldMaster SET FieldSortOrder = 1 WHERE FieldName = 'bulkStkLineAdjNumber' AND ModuleId = (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'BulkStocklineAdjustmentList');
UPDATE FieldMaster SET FieldSortOrder = 2 WHERE FieldName = 'adjustmentType' AND ModuleId = (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'BulkStocklineAdjustmentList');

GO

DECLARE @MasterCompanyId int=1;
DECLARE db_cursor CURSOR FOR 
SELECT MasterCompanyId 
FROM MasterCompany
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @MasterCompanyId  

WHILE @@FETCH_STATUS = 0  
BEGIN  
  print @MasterCompanyId

BEGIN
	
	IF NOT EXISTS (SELECT * FROM [DBO].[FieldMaster] WHERE [FieldName] = 'traceableTo' AND ModuleId IN (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'RepairOrderHistory') AND MasterCompanyId = @MasterCompanyId)
	BEGIN
		INSERT INTO [DBO].[FieldMaster] (ModuleId,FieldName,HeaderName,FieldWidth,FieldType,FieldAlign,FieldFormate,FieldSortOrder,IsMultiValue,IsToolTipShow,IsRequired,IsHidden,IsNumString,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
		VALUES ((SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'RepairOrderHistory'), 'traceableTo', 'TraceableTo', '130px', 'string', 1, '', 17, 0, 0, NULL, NULL, 0, @MasterCompanyId, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), 1, 0)
	END

	IF NOT EXISTS (SELECT * FROM [DBO].[FieldMaster] WHERE [FieldName] = 'tagType' AND ModuleId IN (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'RepairOrderHistory') AND MasterCompanyId = @MasterCompanyId)
	BEGIN
		INSERT INTO [DBO].[FieldMaster] (ModuleId,FieldName,HeaderName,FieldWidth,FieldType,FieldAlign,FieldFormate,FieldSortOrder,IsMultiValue,IsToolTipShow,IsRequired,IsHidden,IsNumString,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
		VALUES ((SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'RepairOrderHistory'), 'tagType', 'Tag Type', '120px', 'string', 1, '', 18, 0, 0, NULL, NULL, 0, @MasterCompanyId, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), 1, 0)
	END

	IF NOT EXISTS (SELECT * FROM [DBO].[FieldMaster] WHERE [FieldName] = 'taggedBy' AND ModuleId IN (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'RepairOrderHistory') AND MasterCompanyId = @MasterCompanyId)
	BEGIN
		INSERT INTO [DBO].[FieldMaster] (ModuleId,FieldName,HeaderName,FieldWidth,FieldType,FieldAlign,FieldFormate,FieldSortOrder,IsMultiValue,IsToolTipShow,IsRequired,IsHidden,IsNumString,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
		VALUES ((SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'RepairOrderHistory'), 'taggedBy', 'Tagged By', '100px', 'string', 1, '', 19, 0, 0, NULL, NULL, 0, @MasterCompanyId, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), 1, 0)
	END

	IF NOT EXISTS (SELECT * FROM [DBO].[FieldMaster] WHERE [FieldName] = 'taggedDate' AND ModuleId IN (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'RepairOrderHistory') AND MasterCompanyId = @MasterCompanyId)
	BEGIN
		INSERT INTO [DBO].[FieldMaster] (ModuleId,FieldName,HeaderName,FieldWidth,FieldType,FieldAlign,FieldFormate,FieldSortOrder,IsMultiValue,IsToolTipShow,IsRequired,IsHidden,IsNumString,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
		VALUES ((SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'RepairOrderHistory'), 'taggedDate', 'Tagged Date', '120px', 'string', 1, '', 20, 0, 0, NULL, NULL, 0, @MasterCompanyId, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), 1, 0)
	END

END
  FETCH NEXT FROM db_cursor INTO @MasterCompanyId 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor

GO

DECLARE @MasterCompanyId int=1;
DECLARE db_cursor CURSOR FOR 
SELECT MasterCompanyId 
FROM MasterCompany
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @MasterCompanyId  

WHILE @@FETCH_STATUS = 0  
BEGIN  
  print @MasterCompanyId

BEGIN
	
	IF NOT EXISTS (SELECT * FROM [DBO].[FieldMaster] WHERE [FieldName] = 'traceableTo' AND ModuleId IN (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'VendorRepairQuoteHistory') AND MasterCompanyId = @MasterCompanyId)
	BEGIN
		INSERT INTO [DBO].[FieldMaster] (ModuleId,FieldName,HeaderName,FieldWidth,FieldType,FieldAlign,FieldFormate,FieldSortOrder,IsMultiValue,IsToolTipShow,IsRequired,IsHidden,IsNumString,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
		VALUES ((SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'VendorRepairQuoteHistory'), 'traceableTo', 'TraceableTo', '130px', 'string', 1, '', 13, 0, 0, NULL, NULL, 0, @MasterCompanyId, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), 1, 0)
	END

	IF NOT EXISTS (SELECT * FROM [DBO].[FieldMaster] WHERE [FieldName] = 'tagType' AND ModuleId IN (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'VendorRepairQuoteHistory') AND MasterCompanyId = @MasterCompanyId)
	BEGIN
		INSERT INTO [DBO].[FieldMaster] (ModuleId,FieldName,HeaderName,FieldWidth,FieldType,FieldAlign,FieldFormate,FieldSortOrder,IsMultiValue,IsToolTipShow,IsRequired,IsHidden,IsNumString,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
		VALUES ((SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'VendorRepairQuoteHistory'), 'tagType', 'Tag Type', '120px', 'string', 1, '', 14, 0, 0, NULL, NULL, 0, @MasterCompanyId, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), 1, 0)
	END

	IF NOT EXISTS (SELECT * FROM [DBO].[FieldMaster] WHERE [FieldName] = 'taggedBy' AND ModuleId IN (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'VendorRepairQuoteHistory') AND MasterCompanyId = @MasterCompanyId)
	BEGIN
		INSERT INTO [DBO].[FieldMaster] (ModuleId,FieldName,HeaderName,FieldWidth,FieldType,FieldAlign,FieldFormate,FieldSortOrder,IsMultiValue,IsToolTipShow,IsRequired,IsHidden,IsNumString,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
		VALUES ((SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'VendorRepairQuoteHistory'), 'taggedBy', 'Tagged By', '100px', 'string', 1, '', 15, 0, 0, NULL, NULL, 0, @MasterCompanyId, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), 1, 0)
	END

	IF NOT EXISTS (SELECT * FROM [DBO].[FieldMaster] WHERE [FieldName] = 'taggedDate' AND ModuleId IN (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'VendorRepairQuoteHistory') AND MasterCompanyId = @MasterCompanyId)
	BEGIN
		INSERT INTO [DBO].[FieldMaster] (ModuleId,FieldName,HeaderName,FieldWidth,FieldType,FieldAlign,FieldFormate,FieldSortOrder,IsMultiValue,IsToolTipShow,IsRequired,IsHidden,IsNumString,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
		VALUES ((SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'VendorRepairQuoteHistory'), 'taggedDate', 'Tagged Date', '120px', 'string', 1, '', 16, 0, 0, NULL, NULL, 0, @MasterCompanyId, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), 1, 0)
	END

END
  FETCH NEXT FROM db_cursor INTO @MasterCompanyId 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor

GO