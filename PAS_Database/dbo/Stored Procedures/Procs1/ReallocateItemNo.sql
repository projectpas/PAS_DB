/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <12/30/2021>  
** Description: <Update Ssales Order Index>  
  
EXEC [ReallocateItemNo] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			 Author				 Change Description  
** --   --------		-------			--------------------------------
** 1    12/30/2021		HEMANT SALIYA	Update Ssales Order Index
   2	11/04/2024		Vishal Suthar	Modified to make use of new SO Part tables
   3    24/08/2026      Kishor Makwana  [PN-17439] - Added Sequence NUmber with all Places

*************************************************************
EXEC [dbo].[ReallocateItemNo]  1010
**************************************************************/ 
CREATE       PROCEDURE [dbo].[ReallocateItemNo]  
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
			  QtyRequested DECIMAL(18,6),
			  qty DECIMAL(18,6),
			  SequenceNumber BIGINT,
			  LineId int NULL default 0
			)

			INSERT INTO #tmpSalesOrderPart(SalesOrderPartid,ItemMasterId,ConditionId,QtyRequested,qty,SequenceNumber)
			SELECT SalesOrderPartId,ItemMasterId,ConditionId,QtyRequested,QtyOrder,SequenceNumber FROM dbo.SalesOrderPartV1 WITH (NOLOCK) Where SalesOrderId = @SalesOrderId AND IsDeleted = 0  order by SalesOrderPartId DESC

			DECLARE  @MasterLoopID as BIGINT  = 0;
			DECLARE  @ConditionID as BIGINT  = 0;
			DECLARE  @ItemMasterID as BIGINT  = 0;
			DECLARE  @RankID as BIGINT  = 0;
			DECLARE  @QtyRequested as BIGINT  = 0;
			DECLARE @SequenceNumber AS BIGINT =0;
			
			SELECT @MasterLoopID = MAX(ID) FROM #tmpSalesOrderPart

			WHILE (@MasterLoopID > 0)
			BEGIN	 
				 SELECT  @ConditionID = ConditionId, @ItemMasterID = ItemMasterId, @QtyRequested = QtyRequested,@SequenceNumber =SequenceNumber  FROM #tmpSalesOrderPart WHERE ID = @MasterLoopID

				 IF EXISTS (SELECT ID FROM #tmpSalesOrderPart wHERE LineId = 0 AND ID = @MasterLoopID) 
				 BEGIN
				    SET @RankID = @RankID +  1;
				 END

                 UPDATE #tmpSalesOrderPart 
				      SET LineId =  @RankID 
					  FROM #tmpSalesOrderPart WHERE ConditionId = @ConditionID 
					                          AND ItemMasterId = @ItemMasterID
											  AND LineId = 0
									  AND SequenceNumber = @SequenceNumber

				If( (SELECT SUM(ISNULL(qty, 0)) FROM #tmpSalesOrderPart WHERE ConditionId = @ConditionID AND ItemMasterID = @ItemMasterId AND SequenceNumber= @SequenceNumber) > @QtyRequested)
				BEGIN
					UPDATE SalesOrderPartV1
					SET QtyRequested = tmp.QtyRequested
					FROM(
						SELECT SUM(ISNULL(SOP.QtyOrder, 0)) AS QtyRequested, SalesOrderId, ConditionId, ItemMasterID,SequenceNumber
						   FROM dbo.SalesOrderPartV1 SOP WITH(NOLOCK) 
						   WHERE ConditionId = @ConditionID AND ItemMasterID = @ItemMasterId AND SalesOrderId = @SalesOrderId AND SequenceNumber=@SequenceNumber
						   GROUP BY SalesOrderId, ConditionId, ItemMasterID,SequenceNumber
					)tmp WHERE tmp.SalesOrderId = SalesOrderPartV1.SalesOrderId AND tmp.ItemMasterID = SalesOrderPartV1.ItemMasterID AND tmp.ConditionId = SalesOrderPartV1.ConditionId AND tmp.SequenceNumber= SalesOrderPartV1.SequenceNumber
				END
				
				SET @MasterLoopID = @MasterLoopID - 1;
			END

			--UPDATE SalesOrderPart
			--SET ItemNo = t.LineId
			--   FROM dbo.SalesOrderPart SOP WITH(NOLOCK)  INNER JOIN #tmpSalesOrderPart t
			--        ON SOP.SalesOrderPartId = t.SalesOrderPartId		

			SELECT CustomerReference as [value] FROM SalesOrder WITH (NOLOCK) Where SalesOrderId = @SalesOrderId
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'ReallocateItemNo' 
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100))  
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