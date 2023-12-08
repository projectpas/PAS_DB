
UPDATE FieldMaster SET FieldSortOrder = 1 WHERE FieldName = 'bulkStkLineAdjNumber' AND ModuleId = (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'BulkStocklineAdjustmentList');
UPDATE FieldMaster SET FieldSortOrder = 2 WHERE FieldName = 'adjustmentType' AND ModuleId = (SELECT GridModuleId FROM DBO.GridModule WHERE ModuleName = 'BulkStocklineAdjustmentList');