
CREATE Procedure [dbo].[usp_GetAllAssetEditID]
@AssetID  bigint,
@tablename varchar(100)
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN  
			IF OBJECT_ID(N'tempdb..#AssetEditList') IS NOT NULL
				BEGIN
				DROP TABLE #AssetEditList 
				END
				CREATE TABLE #AssetEditList 
				(
					ID bigint NOT NULL IDENTITY,
					[Value] bigint null,
					Label varchar(100) null
				)

				if(LOWER(@tablename) = LOWER('Asset'))
					begin
						INSERT INTO #AssetEditList ([Value], Label)
						SELECT A.AssetLocationId, (al.Code + '-' + al.Name) FROM  dbo.Asset A WITH (NOLOCK) Inner Join AssetLocation al WITH (NOLOCK) on A.AssetLocationId = al.AssetLocationId  Where A.AssetRecordId = @AssetID
				end
				else if(LOWER(@tablename)=LOWER('AssetInventory'))
				begin
				INSERT INTO #AssetEditList ([Value], Label)
						SELECT A.AssetLocationId, (al.Code + '-' + al.Name) FROM  dbo.AssetInventory A WITH (NOLOCK) Inner Join AssetLocation al WITH (NOLOCK) on A.AssetLocationId = al.AssetLocationId  Where A.AssetInventoryId = @AssetID
				end

				SELECT * FROM #AssetEditList
		END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetAllAssetEditID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetID, '') + ''',
			                                        @Parameter2 = ' + ISNULL(@tablename ,'') +''
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