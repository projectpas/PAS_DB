/*************************************************************
EXEC [dbo].[ReallocateSOQItemNo]  96
**************************************************************/ 
CREATE PROCEDURE [dbo].[ReallocateSOQItemNo]  
  @SalesOrderQuoteId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			IF OBJECT_ID(N'tempdb..#tmpSalesOrderQuotePart') IS NOT NULL
			BEGIN
				DROP TABLE #tmpSalesOrderQuotePart 
			END

			CREATE TABLE #tmpSalesOrderQuotePart 
			( 
			  ID bigint IDENTITY,
			  SalesOrderQuotePartid   bigint,
			  ItemMasterId bigint,
			  ConditionId bigint,
			  LineId int NULL default 0
			)

			INSERT INTO #tmpSalesOrderQuotePart(SalesOrderQuotePartid,ItemMasterId,ConditionId)
			SELECT SalesOrderQuotePartId, ItemMasterId, ConditionId FROM dbo.SalesOrderQuotePart WITH (NOLOCK) Where SalesOrderQuoteId = @SalesOrderQuoteId AND IsDeleted = 0  order by SalesOrderQuotePartId DESC

			DECLARE  @MasterLoopID as bigint  = 0;
			DECLARE  @ConditionID as bigint  = 0;
			DECLARE  @ItemMasterID as bigint  = 0;
			DECLARE  @RankID as bigint  = 0;
			SELECT @MasterLoopID = MAX(ID) FROM #tmpSalesOrderQuotePart
			
			WHILE (@MasterLoopID > 0)
			BEGIN
				 SELECT  @ConditionID = ConditionId, @ItemMasterID = ItemMasterId FROM #tmpSalesOrderQuotePart WHERE ID = @MasterLoopID  
				
                 IF EXISTS (SELECT ID FROM #tmpSalesOrderQuotePart wHERE LineId = 0 AND ID = @MasterLoopID) 
				 BEGIN
				    SET @RankID = @RankID +  1;
				 END

				 UPDATE #tmpSalesOrderQuotePart 
				      SET LineId =  @RankID 
					  FROM #tmpSalesOrderQuotePart WHERE ConditionId = @ConditionID 
					                          AND ItemMasterId = @ItemMasterID
											  AND LineId = 0

				 SET @MasterLoopID = @MasterLoopID - 1;
			END
			 
			UPDATE SalesOrderQuotePart
			SET ItemNo = t.LineId
			   FROM dbo.SalesOrderQuotePart SOP WITH(NOLOCK) INNER JOIN #tmpSalesOrderQuotePart t
			        ON SOP.SalesOrderQuotePartId = t.SalesOrderQuotePartId		

			SELECT CustomerReference as [value] FROM SalesOrderQuotePart WITH (NOLOCK) Where SalesOrderQuoteId = @SalesOrderQuoteId
		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'ReallocateSOQItemNo' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteId, '') + ''''
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