
/*************************************************************               
 ** File:   [USP_GetStocklineHistoryDetailById]              
 ** Author:   Devendra      
 ** Description: Get stockline history detail by stocklineid  
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
CREATE    PROCEDURE [dbo].[USP_GetStocklineHistoryDetailById]  
 @PageNumber INT,    
 @PageSize INT,    
 @SortColumn VARCHAR(50)=null,    
 @SortOrder INT,    
 @GlobalFilter VARCHAR(50) = null,     
 @StockLineId INT = NULL,  
 @QuantityAvailable INT=null,   
 @QuantityIssued INT=null,  
 @QuantityOnHand INT=null,   
 @QuantityReserved INT=null,    
 @TextMessage VARCHAR(MAX) = null,    
 @RefferenceId varchar(50)=null,    
 @ModuleName varchar(50)=null,    
 @UpdatedDate  DATETIME=null,    
 @UpdatedBy VARCHAR(50)=null,  
 @Action VARCHAR(50)=null,  
 @SubModuleName varchar(50)=null,    
 @SubRefferenceNumber varchar(50)=null,
 @QtyOnAction INT = null
   
AS  
BEGIN  
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 BEGIN TRY   
  
 DECLARE @RecordFrom INT;    
 SET @RecordFrom = (@PageNumber-1) * @PageSize;    
        
 IF @SortColumn is null    
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
 LEFT JOIN DBO.Module SM WITH (NOLOCK) ON StlHist.SubModuleId = SM.ModuleId  
 WHERE StlHist.StocklineId = @StockLineId),  
   FinalResult AS (    
 SELECT  rs.ModuleName,  rs.StockLineNumber,  
 rs.RefferenceId RefferenceId,
 --(CASE WHEN LOWER(ISNULL([Action],'')) = 'adjustment' THEN 
	--		(SELECT TOP 1 BulkStkLineAdjNumber FROM DBO.BulkStockLineAdjustment BS WITH (NOLOCK) 
	--		  INNER JOIN DBO.BulkStockLineAdjustmentDetails BSD WITH (NOLOCK) ON BS.BulkStkLineAdjId = BSD.BulkStkLineAdjId 
	--		  WHERE BSD.StockLineId = rs.StocklineId ORDER BY BS.BulkStkLineAdjId DESC) ELSE rs.RefferenceId END) RefferenceId,  
 rs.StklineHistoryId,  rs.ModuleId, rs.StocklineId,  rs.QuantityAvailable, rs.QuantityOnHand,  rs.QuantityReserved,  rs.QuantityIssued    
  ,  rs.QtyOnAction,  rs.TextMessage, rs.UpdatedBy, rs.UpdatedDate,  rs.[Action],  rs.SubModuleName,  rs.SubRefferenceNumber  FROM Result  rs
 WHERE (    
  (@GlobalFilter <>'' AND ((ModuleName like '%' +@GlobalFilter+'%') OR     
  (RefferenceId like '%' +@GlobalFilter+'%') OR    
  (CAST(rs.QuantityOnHand AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR  
  (CAST(rs.QtyOnAction AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR
  (CAST(QuantityReserved AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR    
  (CAST(QuantityIssued AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR    
  (CAST(QuantityAvailable AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR    
  (CAST(QtyOnAction AS VARCHAR(100)) like '%' +@GlobalFilter+'%') OR    
  (rs.UpdatedBy like '%' +@GlobalFilter+'%') OR    
  (rs.UpdatedDate like '%' +@GlobalFilter+'%') OR    
  (TextMessage like '%' +@GlobalFilter+'%') OR   
  (Action like '%' +@GlobalFilter+'%')  OR  
  (SubModuleName like '%' +@GlobalFilter+'%')  OR  
  (SubRefferenceNumber like '%' +@GlobalFilter+'%')    
  ))    
  OR       
  (@GlobalFilter='' AND     
  (IsNull(@ModuleName,'') ='' OR ModuleName like  '%'+@ModuleName+'%') and    
  (IsNull(@RefferenceId,'') ='' OR RefferenceId like  '%'+@RefferenceId+'%') and    
  (IsNull(@QuantityOnHand,'') ='' OR rs.QuantityOnHand like '%'+ CAST(@QuantityOnHand AS VARCHAR(100)) +'%') and 
  (IsNull(@QtyOnAction,'') ='' OR QtyOnAction like '%'+ CAST(@QtyOnAction AS VARCHAR(100)) +'%') and
  (IsNull(@QuantityReserved,'') ='' OR QuantityReserved like  '%'+ CAST(@QuantityReserved AS VARCHAR(100)) +'%') and    
  (IsNull(@QuantityIssued,'') ='' OR QuantityIssued like  '%'+  CAST(@QuantityIssued AS VARCHAR(100)) +'%') and    
  (IsNull(@QuantityAvailable,'') ='' OR QuantityAvailable like '%'+ CAST(@QuantityAvailable AS VARCHAR(100)) +'%') and    
  (IsNull(@UpdatedBy,'') ='' OR rs.UpdatedBy like  '%'+@UpdatedBy+'%') and    
  (IsNull(@Action,'') ='' OR Action like  '%'+@Action+'%') and    
  (IsNull(@UpdatedDate,'') ='' OR Cast(rs.UpdatedDate as date)=Cast(@UpdatedDate as date)) and    
  (IsNull(@TextMessage,'') ='' OR TextMessage like '%'+@TextMessage+'%') and   
  (IsNull(@SubModuleName,'') ='' OR SubModuleName like '%'+@SubModuleName+'%') and   
  (IsNull(@SubRefferenceNumber,'') ='' OR SubRefferenceNumber like '%'+@SubRefferenceNumber+'%'))    
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
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetStocklineHistoryDetailById'   
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