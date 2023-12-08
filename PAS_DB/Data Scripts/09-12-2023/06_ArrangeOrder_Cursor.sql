DECLARE @MinId BIGINT = 1;      
DECLARE @TotalRecord int = 0; 
DECLARE @FieldSortOrder int = 0; 
DECLARE @FieldMasterId BIGINT;
DECLARE @MasterCompanyId int;
DECLARE @conditionNameSortOrder int = 0;
DECLARE @currentIterationFieldName NVARCHAR(200) = '';
DECLARE db_cursor CURSOR FOR
SELECT MasterCompanyId FROM MasterCompany
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @MasterCompanyId  
WHILE @@FETCH_STATUS = 0  
BEGIN   	  	   	 
	 CREATE TABLE #tmpTblorderbyfieldmaster
	 (        
		[rowId] bigint IDENTITY,    
		[FieldMasterId] BIGINT,
		[FieldSortOrder] INT,
		[FieldName] NVARCHAR(200),
	 )

	 INSERT INTO #tmpTblorderbyfieldmaster([FieldMasterId],[FieldSortOrder],[FieldName])	
	 SELECT [FieldMasterId],[FieldSortOrder],[FieldName] FROM [dbo].[FieldMaster] WHERE MasterCompanyId = @MasterCompanyId AND ModuleId = (SELECT GridModuleId FROM GridModule WHERE ModuleName = 'SalesOrderHistory') ORDER BY [FieldSortOrder] ASC

	 SELECT @conditionNameSortOrder = [FieldSortOrder],  
	        @MinId = [rowid]+1 FROM #tmpTblorderbyfieldmaster WHERE [FieldName]='conditionName'
	 SELECT @TotalRecord = COUNT(*) FROM #tmpTblorderbyfieldmaster 

	 WHILE @MinId <= @TotalRecord   
	 BEGIN	
		SELECT @FieldMasterId = [FieldMasterId],@FieldSortOrder = [FieldSortOrder],@currentIterationFieldName=[FieldName]
		FROM #tmpTblorderbyfieldmaster WHERE [rowId] = @MinId;
	
        IF(@currentIterationFieldName = 'statusValue')
		BEGIN
		  UPDATE [dbo].[FieldMaster] SET  [FieldSortOrder] =@conditionNameSortOrder+1 WHERE [FieldMasterId] = @FieldMasterId;
		END
		ELSE
		BEGIN
		  UPDATE [dbo].[FieldMaster] SET  [FieldSortOrder] = @FieldSortOrder + 1 WHERE [FieldMasterId] = @FieldMasterId;
		END

		SET @MinId = @MinId + 1;
	 END	

	 IF OBJECT_ID(N'tempdb..#tmpTblorderbyfieldmaster') IS NOT NULL        
	 BEGIN        
			DROP TABLE #tmpTblorderbyfieldmaster        
	 END 

FETCH NEXT FROM db_cursor INTO @MasterCompanyId 
END
CLOSE db_cursor
DEALLOCATE db_cursor