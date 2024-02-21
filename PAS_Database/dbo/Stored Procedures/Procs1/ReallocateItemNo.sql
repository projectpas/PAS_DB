/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Update Ssales Order Index>  
  
EXEC [ReallocateItemNo] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			 Author				 Change Description  
** --   --------		-------			 --------------------------------
** 1    12/30/2021		HEMANT SALIYA	  Update Ssales Order Index

*************************************************************
EXEC [dbo].[ReallocateItemNo]  1010
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
			  QtyRequested INT,
			  qty INT,
			  LineId int NULL default 0
			)

			INSERT INTO #tmpSalesOrderPart(SalesOrderPartid,ItemMasterId,ConditionId,QtyRequested,qty)
			SELECT SalesOrderPartId,ItemMasterId,ConditionId,QtyRequested,qty FROM dbo.SalesOrderPart WITH (NOLOCK) Where SalesOrderId = @SalesOrderId AND IsDeleted = 0  order by SalesOrderPartId DESC

			DECLARE  @MasterLoopID as BIGINT  = 0;
			DECLARE  @ConditionID as BIGINT  = 0;
			DECLARE  @ItemMasterID as BIGINT  = 0;
			DECLARE  @RankID as BIGINT  = 0;
			DECLARE  @QtyRequested as BIGINT  = 0;
			
			SELECT @MasterLoopID = MAX(ID) FROM #tmpSalesOrderPart

			WHILE (@MasterLoopID > 0)
			BEGIN	 
				 SELECT  @ConditionID = ConditionId, @ItemMasterID = ItemMasterId, @QtyRequested = QtyRequested FROM #tmpSalesOrderPart WHERE ID = @MasterLoopID  

				 IF EXISTS (SELECT ID FROM #tmpSalesOrderPart wHERE LineId = 0 AND ID = @MasterLoopID) 
				 BEGIN
				    SET @RankID = @RankID +  1;
				 END

                 UPDATE #tmpSalesOrderPart 
				      SET LineId =  @RankID 
					  FROM #tmpSalesOrderPart WHERE ConditionId = @ConditionID 
					                          AND ItemMasterId = @ItemMasterID
											  AND LineId = 0

				If( (SELECT SUM(ISNULL(qty, 0)) FROM #tmpSalesOrderPart WHERE ConditionId = @ConditionID AND ItemMasterID = @ItemMasterId) > @QtyRequested)
				BEGIN
					UPDATE SalesOrderPart
					SET QtyRequested = tmp.QtyRequested
					FROM(
						SELECT SUM(ISNULL(SOP.qty, 0)) AS QtyRequested, SalesOrderId, ConditionId, ItemMasterID
						   FROM dbo.SalesOrderPart SOP WITH(NOLOCK) 
						   WHERE ConditionId = @ConditionID AND ItemMasterID = @ItemMasterId AND SalesOrderId = @SalesOrderId
						   GROUP BY SalesOrderId, ConditionId, ItemMasterID
					)tmp WHERE tmp.SalesOrderId = SalesOrderPart.SalesOrderId AND tmp.ItemMasterID = SalesOrderPart.ItemMasterID AND tmp.ConditionId = SalesOrderPart.ConditionId
				END
				
				SET @MasterLoopID = @MasterLoopID - 1;
			END

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