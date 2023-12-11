DECLARE @MasterCompanyId int;
DECLARE @ModuleId BIGINT = 0;
SET @ModuleId = (SELECT [GridModuleId] FROM [dbo].[GridModule] WITH(NOLOCK) WHERE [ModuleName] = 'Work Order Material')

DECLARE db_cursor CURSOR FOR 
SELECT MasterCompanyId  
FROM [dbo].[MasterCompany] WITH(NOLOCK)
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @MasterCompanyId  
WHILE @@FETCH_STATUS = 0  

BEGIN  

	BEGIN

		DECLARE @NewSortOrder BIGINT = 1, @TotalRec BIGINT = 0, @SelectedRec BIGINT = 0, @StartLoopId BIGINT = 1;

		IF OBJECT_ID(N'tempdb..#FieldMasterUpdate') IS NOT NULL
		BEGIN
			DROP TABLE #FieldMasterUpdate
		END 

		CREATE TABLE #FieldMasterUpdate 
		(
			ID BIGINT NOT NULL IDENTITY,
			FieldMasterId [bigint] NULL,
			FieldName [varchar](150) NULL,
			FieldSortOrder [bigint] NULL
		)

		INSERT INTO #FieldMasterUpdate ([FieldMasterId], [FieldName], [FieldSortOrder])
		SELECT [FieldMasterId], [FieldName], [FieldSortOrder] FROM [dbo].[FieldMaster] WITH(NOLOCK) WHERE [ModuleId] = @ModuleId AND [MasterCompanyId] = @MasterCompanyId

		SET @TotalRec = (SELECT COUNT(ID) FROM #FieldMasterUpdate)

		PRINT @MasterCompanyId

		IF(ISNULL(@TotalRec ,0) > 0)
		BEGIN
			WHILE(@StartLoopId <= @TotalRec)
			BEGIN
		
				SET @SelectedRec = (SELECT FieldMasterId FROM #FieldMasterUpdate WHERE @StartLoopId = ID)

				UPDATE [dbo].[FieldMaster]
				SET [FieldSortOrder] = @StartLoopId
				WHERE FieldMasterId = @SelectedRec

				SET @StartLoopId = @StartLoopId + 1
			END
		END

	END
  FETCH NEXT FROM db_cursor INTO @MasterCompanyId 
END 
CLOSE db_cursor  
DEALLOCATE db_cursor
GO