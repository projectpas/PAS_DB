/*************************************************************
EXEC [dbo].[ReallocateItemNo]  62
**************************************************************/ 
CREATE PROCEDURE [dbo].[ReallocateItemNo]  
  @SalesOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			IF OBJECT_ID(N'tempdb..#tmpSalesOrderPart') IS NOT NULL
			BEGIN
				DROP TABLE #tmpSalesOrderPart
			END

			CREATE TABLE #tmpSalesOrderPart 
			( 
			  ID bigint IDENTITY,
			  SalesOrderPartid   bigint,
			  ItemMasterId bigint,
			  ConditionId bigint,
			  LineId int NULL default 0
			)

			INSERT INTO #tmpSalesOrderPart(SalesOrderPartid,ItemMasterId,ConditionId)
			       SELECT SalesOrderPartId,ItemMasterId,ConditionId
				       FROM dbo.SalesOrderPart WITH (NOLOCK) Where SalesOrderId = @SalesOrderId AND IsDeleted = 0  order by SalesOrderPartId DESC

			--SELECT * FROM #tmpSalesOrderPart

			DECLARE  @MasterLoopID as bigint  = 0;
			DECLARE  @ConditionID as bigint  = 0;
			DECLARE  @ItemMasterID as bigint  = 0;
			DECLARE  @RankID as bigint  = 1;
			SELECT @MasterLoopID = MAX(ID) FROM #tmpSalesOrderPart        
			WHILE (@MasterLoopID > 0)
			BEGIN
				 
				 SELECT  @ConditionID = ConditionId,
				         @ItemMasterID = ItemMasterId FROM #tmpSalesOrderPart WHERE ID = @MasterLoopID  

                 UPDATE #tmpSalesOrderPart 
				      SET LineId =  @RankID 
					  FROM #tmpSalesOrderPart WHERE ConditionId = @ConditionID 
					                          AND ItemMasterId = @ItemMasterID
											  AND LineId = 0

                 IF EXISTS (SELECT ID FROM #tmpSalesOrderPart wHERE LineId = 0 ) 
				 BEGIN
				    SET @RankID = @RankID +  1;
				 END

				 SET @MasterLoopID = @MasterLoopID - 1;
			END

		    --SELECT * FROM #tmpSalesOrderPart
			
			UPDATE SalesOrderPart
			SET ItemNo = t.LineId
			   FROM dbo.SalesOrderPart SOP WITH(NOLOCK)  INNER JOIN #tmpSalesOrderPart t
			        ON SOP.SalesOrderPartId = t.SalesOrderPartId		

			SELECT CustomerReference as [value] FROM SalesOrderPart WITH (NOLOCK) Where SalesOrderId = @SalesOrderId
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'ReallocateItemNo' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''''
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