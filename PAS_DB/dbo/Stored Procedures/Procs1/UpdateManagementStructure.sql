-- EXEC [UpdateManagementStructure] 16,'97,98','ManagementSite'
CREATE PROCEDURE [dbo].[UpdateManagementStructure]
@parentSiteId VARCHAR(100),
@removedData VARCHAR(1000),
@managementStructureTable VARCHAR(50)

AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN
			DECLARE @sqlStr VARCHAR (MAX)
			DECLARE @sqlStr_del_bin VARCHAR(1000)
			DECLARE @sqlStr_del_shelf VARCHAR(1000)
			DECLARE @sqlStr_del_location VARCHAR(1000)
			DECLARE @sqlStr_del_warehouse VARCHAR(1000)
			DECLARE @sqlStr_del_site VARCHAR(1000)
		
			SET @sqlStr = 'DELETE FROM ManagementBin WHERE binid IN (
					SELECT BinId FROM bin WITH (NOLOCK) WHERE ShelfId IN (\
					SELECT ShelfId FROM shelf WITH (NOLOCK) WHERE locationid IN (
					SELECT Locationid FROM location WITH (NOLOCK) WHERE warehouseid IN (
					SELECT WarehouseId FROM Warehouse WITH (NOLOCK) WHERE Warehouse.SiteId IN (
					SELECT siteid FROM site WITH (NOLOCK) WHERE siteid = '
			SET @sqlStr = @sqlStr + str(@parentSiteId) + ')))) AND ManagementStructureId IN ('
			SET @sqlStr = @sqlStr + @removedData
			SET @sqlStr = @sqlStr + ')'
			SET @sqlStr = @sqlStr + ')'
    
			SET @sqlStr_del_bin = @sqlStr
        
			SET @sqlStr = 'DELETE FROM ManagementShelf WHERE ShelfId IN (
					SELECT ShelfId FROM shelf WITH (NOLOCK) WHERE locationid IN (
					SELECT Locationid FROM location WITH (NOLOCK) WHERE warehouseid IN (
					SELECT WarehouseId FROM Warehouse WITH (NOLOCK) WHERE Warehouse.SiteId IN (
					SELECT siteid FROM site WITH (NOLOCK) WHERE siteid = '
			SET @sqlStr = @sqlStr + str(@parentSiteId) + '))) AND ManagementStructureId IN ('
			SET @sqlStr = @sqlStr + @removedData
			SET @sqlStr = @sqlStr + ')'
			SET @sqlStr = @sqlStr + ')'
    
			SET @sqlStr_del_shelf = @sqlStr
        
			SET @sqlStr  = 'DELETE FROM ManagementLocation WHERE locationid IN (
					SELECT Locationid FROM location WITH (NOLOCK) WHERE warehouseid IN (
					SELECT WarehouseId FROM Warehouse WITH (NOLOCK) WHERE Warehouse.SiteId IN (
					SELECT siteid FROM site WITH (NOLOCK) WHERE siteid = '
			SET @sqlStr  = @sqlStr + str(@parentSiteId) + ')) AND ManagementStructureId IN ('
			SET @sqlStr  = @sqlStr + @removedData
			SET @sqlStr  = @sqlStr + ')'
			SET @sqlStr  = @sqlStr + ')'
    
			SET @sqlStr_del_location = @sqlStr
       
			SET @sqlStr = 'DELETE FROM ManagementWarehouse WHERE warehouseid IN (
					SELECT WarehouseId FROM Warehouse WITH (NOLOCK) WHERE Warehouse.SiteId IN (
					SELECT siteid FROM site WITH (NOLOCK) WHERE siteid = '
			SET @sqlStr = @sqlStr + str(@parentSiteId) + ') AND ManagementStructureId IN ('
			SET @sqlStr = @sqlStr + @removedData
			SET @sqlStr = @sqlStr + ')'
			SET @sqlStr = @sqlStr + ')'
    
			SET @sqlStr_del_warehouse = @sqlStr
        
			SET @sqlStr = 'DELETE FROM ManagementSite WHERE siteid = '
			SET @sqlStr = @sqlStr + str(@parentSiteId) + ' AND ManagementStructureId IN ('
			SET @sqlStr = @sqlStr + @removedData
			SET @sqlStr = @sqlStr + ')'
    
			SET @sqlStr_del_site = @sqlStr

			PRINT @sqlStr_del_bin
			PRINT @sqlStr_del_shelf
			PRINT @sqlStr_del_location
			PRINT @sqlStr_del_warehouse
			PRINT @sqlStr_del_site

			IF @managementStructureTable = 'ManagementSite'
				BEGIN
					EXECUTE(@sqlStr_del_bin) 
					EXECUTE(@sqlStr_del_shelf) 
					EXECUTE(@sqlStr_del_location) 
					EXECUTE(@sqlStr_del_warehouse) 
					EXECUTE(@sqlStr_del_site) 
				 
				END
			ELSE IF @managementStructureTable = 'ManagementWarehouse'
				BEGIN
					EXECUTE(@sqlStr_del_bin)
					EXECUTE(@sqlStr_del_shelf)
					EXECUTE(@sqlStr_del_location)
					EXECUTE(@sqlStr_del_warehouse)
				END
            
			ELSE IF @managementStructureTable = 'ManagementLocation'
				BEGIN
					EXECUTE(@sqlStr_del_bin)
					EXECUTE(@sqlStr_del_shelf)
					EXECUTE(@sqlStr_del_location)
				END
            
			ELSE IF @managementStructureTable = 'ManagementShelf'
				BEGIN
					EXECUTE(@sqlStr_del_bin)
					EXECUTE(@sqlStr_del_shelf)
				END
			ELSE IF @managementStructureTable = 'ManagementBin'
			BEGIN
			EXECUTE(@sqlStr_del_bin)
			END
		END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateManagementStructure' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@parentSiteId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END