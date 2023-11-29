﻿/*************************************************************               
 ** File:   [GetPNTileStocklineHistoryList]              
 ** Author:   Devendra      
 ** Description: Get stockline history detail by itemmasterid  
 ** Purpose:             
 ** Date:   10-July-2023           
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 **  S NO   Date    Author    Change Description                
 **  --   --------   -------  --------------------------------              
 1  12-July-2023   Devendra  created    
 2  13-July-2023   Devendra  changed sp for filtering 
 3  25-July-2023   Shrey Chandegara Add Parameter QtyOnAction For Filtering.
         
exec USP_GetStocklineHistoryDetailById @PageSize=10,@PageNumber=1,@SortColumn=N'StocklineHistoryId',@SortOrder=1,  
@GlobalFilter=N'',@StocklineId=164065,@QuantityAvailable=0,@QuantityIssued=0,@QuantityOnHand=0,@QuantityReserved=0,  
@TextMessage=NULL,@RefferenceId=NULL,@ModuleName=NULL,@UpdatedDate=NULL,@UpdatedBy=NULL,@Action=NULL,@SubModuleName=NULL,@SubRefferenceNumber=NULL  
  
**************************************************************/    
CREATE   PROCEDURE [dbo].[GetPNTileStocklineHistoryList]
 @PageNumber INT,
 @PageSize INT,
 @SortColumn VARCHAR(50)=NULL,
 @SortOrder INT,
 @GlobalFilter VARCHAR(50) = NULL,
 @ItemMasterId INT = NULL,
 @StockLineId INT = NULL,
 @QuantityAvailable INT = NULL,
 @QuantityIssued INT = NULL,
 @QuantityOnHand INT = NULL,
 @QuantityReserved INT = NULL,
 @TextMessage VARCHAR(MAX) = NULL,
 @RefferenceId VARCHAR(50) = NULL,
 @ModuleName VARCHAR(50) = NULL,
 @UpdatedDate  DATETIME = NULL,
 @UpdatedBy VARCHAR(50) = NULL,
 @Action VARCHAR(50) = NULL,
 @SubModuleName VARCHAR(50) = NULL,
 @SubRefferenceNumber VARCHAR(50) = NULL,
 @QtyOnAction INT = NULL,
 @ConditionIds VARCHAR(250) = NULL
AS
BEGIN
 SET NOCOUNT ON;
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 BEGIN TRY

 DECLARE @RecordFrom INT;
 SET @RecordFrom = (@PageNumber-1) * @PageSize;

 IF @SortColumn IS NULL
 BEGIN    
  SET @SortColumn=Upper('UpdatedDate')    
 END     
 Else    
 BEGIN     
  SET @SortColumn=Upper(@SortColumn)    
 END    
  
 ;With Result AS(    
 SELECT M.ModuleName, STL.StockLineNumber,  
 StlHist.RefferenceNumber AS RefferenceId,  
 StlHist.StklineHistoryId,  
 StlHist.ModuleId,  
 StlHist.StocklineId,  
 StlHist.QtyAvailable as 'QuantityAvailable',  
 StlHist.QtyOH as 'QuantityOnHand',  
 StlHist.QtyReserved as 'QuantityReserved',  
 StlHist.QtyIssued as 'QuantityIssued',  
 ISNULL(StlHist.QtyOnAction, 0) as 'QtyOnAction',  
 StlHist.Notes as 'TextMessage',  
 StlHist.UpdatedBy,  
 StlHist.UpdatedDate,  
 StlHist.[Type] as 'Action',  
 ISNULL(SM.ModuleName, '') AS 'SubModuleName',  
 ISNULL(StlHist.SubRefferenceNumber, '') AS 'SubRefferenceNumber'  
 --StlHist.MasterCompanyId   
 FROM DBO.Stkline_History StlHist   
 INNER JOIN DBO.Module M WITH (NOLOCK) ON StlHist.ModuleId = M.ModuleId  
 INNER JOIN DBO.Stockline STL WITH (NOLOCK) ON StlHist.StocklineId = STL.StockLineId  
 INNER JOIN DBO.ItemMaster IM WITH (NOLOCK) ON STL.ItemMasterId = IM.ItemMasterId
 LEFT JOIN DBO.Module SM WITH (NOLOCK) ON StlHist.SubModuleId = SM.ModuleId  
 WHERE IM.ItemMasterId = @ItemMasterId
 AND (@ConditionIds IS NULL OR STL.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionIds, ',')))),
   FinalResult AS (
 SELECT ModuleName, StockLineNumber, RefferenceId, StklineHistoryId, ModuleId, StocklineId, QuantityAvailable, QuantityOnHand, QuantityReserved, QuantityIssued
  , QtyOnAction, TextMessage, UpdatedBy, UpdatedDate, [Action], SubModuleName, SubRefferenceNumber  FROM Result
 WHERE (
  (@GlobalFilter <>'' AND ((ModuleName like '%' +@GlobalFilter+'%') OR
  (RefferenceId like '%' +@GlobalFilter+'%') OR
  (CAST(QuantityOnHand AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR
  (CAST(QtyOnAction AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR
  (CAST(QuantityReserved AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR
  (CAST(QuantityIssued AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR
  (CAST(QuantityAvailable AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR
  (CAST(QtyOnAction AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR
  (UpdatedBy like '%' +@GlobalFilter+'%') OR
  (UpdatedDate like '%' +@GlobalFilter+'%') OR
  (TextMessage like '%' +@GlobalFilter+'%') OR
  (Action like '%' +@GlobalFilter+'%')  OR
  (SubModuleName like '%' +@GlobalFilter+'%')  OR
  (SubRefferenceNumber like '%' +@GlobalFilter+'%')
  ))
  OR
  (@GlobalFilter='' AND
  (ISNULL(@ModuleName,'') ='' OR ModuleName LIKE  '%'+@ModuleName+'%') AND
  (ISNULL(@RefferenceId,'') ='' OR RefferenceId LIKE  '%'+@RefferenceId+'%') AND
  (ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%'+ CAST(@QuantityOnHand AS VARCHAR(100)) +'%') AND
  (ISNULL(@QtyOnAction,'') ='' OR QtyOnAction LIKE '%'+ CAST(@QtyOnAction AS VARCHAR(100)) +'%') AND
  (ISNULL(@QuantityReserved, '') = '' OR QuantityReserved LIKE '%'+ CAST(@QuantityReserved AS VARCHAR(100)) +'%') AND
  (ISNULL(@QuantityIssued, '') = '' OR QuantityIssued LIKE '%'+  CAST(@QuantityIssued AS VARCHAR(100)) +'%') AND
  (ISNULL(@QuantityAvailable, '') = '' OR QuantityAvailable LIKE '%'+ CAST(@QuantityAvailable AS VARCHAR(100)) +'%') AND
  (ISNULL(@UpdatedBy, '') = '' OR UpdatedBy LIKE '%'+ @UpdatedBy +'%') AND
  (ISNULL(@Action, '') = '' OR Action LIKE '%'+ @Action +'%') AND
  (ISNULL(@UpdatedDate, '') = '' OR CAST(UpdatedDate AS DATE) = Cast(@UpdatedDate AS DATE)) AND
  (ISNULL(@TextMessage, '') = '' OR TextMessage LIKE '%'+ @TextMessage +'%') and   
  (ISNULL(@SubModuleName, '') = '' OR SubModuleName LIKE '%'+@SubModuleName+'%') and   
  (ISNULL(@SubRefferenceNumber, '') = '' OR SubRefferenceNumber LIKE '%'+@SubRefferenceNumber+'%'))
  )),
  ResultCount AS (Select COUNT(StklineHistoryId) AS NumberOfItems FROM FinalResult)
  SELECT ModuleName, StockLineNumber, RefferenceId, StklineHistoryId, ModuleId, StocklineId, QuantityAvailable, QuantityOnHand, QuantityReserved, QuantityIssued, QtyOnAction,
  TextMessage, UpdatedBy, UpdatedDate, Action, SubModuleName, SubRefferenceNumber, NumberOfItems FROM FinalResult, ResultCount
  
  ORDER BY
   CASE WHEN (@SortOrder=1 and @SortColumn='StklineHistoryId')  THEN StklineHistoryId END DESC,
   CASE WHEN (@SortOrder=1 and @SortColumn='ModuleName')  THEN ModuleName END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='StockLineNumber')  THEN StockLineNumber END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='RefferenceId')  THEN RefferenceId END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='QuantityAvailable')  THEN QuantityAvailable END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='QuantityOnHand')  THEN QuantityOnHand END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='QuantityReserved')  THEN QuantityReserved END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='QuantityIssued')  THEN QuantityIssued END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='QtyOnAction')  THEN QtyOnAction END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='TextMessage')  THEN TextMessage END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='Action')  THEN Action END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='SubModuleName')  THEN SubModuleName END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='SubRefferenceNumber')  THEN SubRefferenceNumber END ASC,
    
   CASE WHEN (@SortOrder=-1 and @SortColumn='StklineHistoryId')  THEN StklineHistoryId END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='ModuleName')  THEN ModuleName END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='StockLineNumber')  THEN StockLineNumber END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='RefferenceId')  THEN RefferenceId END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityAvailable')  THEN QuantityAvailable END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityOnHand')  THEN QuantityOnHand END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityReserved')  THEN QuantityReserved END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityIssued')  THEN QuantityIssued END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='QtyOnAction')  THEN QtyOnAction END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='TextMessage')  THEN TextMessage END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='Action')  THEN Action END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='SubModuleName')  THEN SubModuleName END DESC,
   CASE WHEN (@SortOrder=-1 and @SortColumn='SubRefferenceNumber')  THEN SubRefferenceNumber END DESC
  
   OFFSET @RecordFrom ROWS
   FETCH NEXT @PageSize ROWS ONLY
 END TRY
 BEGIN CATCH
   DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileStocklineHistoryList'
            , @ProcedureParameters VARCHAR(3000)  = ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  
                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName   =  @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
    END CATCH   
END