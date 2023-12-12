/*************************************************************             
 ** File:   [USP_SearchBulkStockData]             
 ** Author:  AMIT GHEDIYA  
 ** Description: This stored procedure is used to Get Bulk Stockline Adjustment listing  
 ** Purpose:           
 ** Date:   12/10/2023        
            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date            Author                 Change Description              
 ** --   --------       -----------				--------------------------------            
    1    12/10/2023     AMIT GHEDIYA			Created
	2    06/12/2023     AMIT GHEDIYA			Modify(Added Adjustment Type column)
       
-- EXEC USP_SearchBulkStockData
  
************************************************************************/  
CREATE  PROCEDURE [dbo].[USP_SearchBulkStockData]
	@PageNumber int = NULL,
	@PageSize int = NULL,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = '',
	@StatusId int = NULL,
	@BulkStkLineAdjNumber  varchar(50) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy  varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@IsDeleted bit = NULL,
	@MasterCompanyId bigint = NULL,
	@AdjustmentType varchar(150) = NULL
AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
   BEGIN  
    DECLARE @RecordFrom int;  
    DECLARE  @VendorRMADetailStatus VARCHAR(100)= NULL;  
    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
    IF @IsDeleted IS NULL  
    BEGIN  
     SET @IsDeleted=0  
    END  
    IF @SortColumn IS NULL  
    BEGIN  
     SET @SortColumn = UPPER('CreatedDate')  
    END   
    ELSE  
    BEGIN   
     SET @SortColumn = UPPER(@SortColumn)  
    END  

	IF @StatusId=0  
    BEGIN   
     SET @StatusId = NULL  
    END   

		;WITH Result AS(  
		SELECT stadt.[Name] AS 'AdjustmentType',
					   bsadj.BulkStkLineAdjId,
					   bsadj.BulkStkLineAdjNumber,                    
					   bsadj.CreatedDate,
                       bsadj.UpdatedDate,
					   bsadj.CreatedBy,
                       bsadj.UpdatedBy,	
					   bsadj.IsDeleted,
					   bsadj.StatusId
			   FROM dbo.BulkStockLineAdjustment bsadj WITH (NOLOCK)	
			   INNER JOIN dbo.StockLineAdjustmentType stadt ON bsadj.StockLineAdjustmentTypeId = stadt.StockLineAdjustmentTypeId
		 	  WHERE (bsadj.IsActive = 1)			     
					AND bsadj.MasterCompanyId=@MasterCompanyId AND (@StatusId IS NULL OR bsadj.StatusId = @StatusId )
		),
		FinalResult AS (  
		SELECT AdjustmentType,BulkStkLineAdjId, BulkStkLineAdjNumber, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsDeleted, StatusId FROM Result  
		WHERE  (  
		 (@GlobalFilter <>'' AND ((BulkStkLineAdjNumber LIKE '%' +@GlobalFilter+'%' ) OR   
		   (CreatedBy LIKE '%' +@GlobalFilter+'%') OR 
		   (UpdatedBy LIKE '%' +@GlobalFilter+'%') OR 
		   (CreatedDate LIKE '%' +@GlobalFilter+'%') OR  
		   (UpdatedDate LIKE '%' +@GlobalFilter+'%') OR
		   (AdjustmentType LIKE '%' +@GlobalFilter+'%') 
		   ))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@BulkStkLineAdjNumber,'') ='' OR BulkStkLineAdjNumber LIKE  '%'+ @BulkStkLineAdjNumber+'%') AND   
		   (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND  
		   (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND  
		   (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND  
		   (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) AND
		   (ISNULL(@AdjustmentType,'') ='' OR AdjustmentType LIKE '%'+ @AdjustmentType +'%')
		   )  
		   )),  
      ResultCount AS (Select COUNT(BulkStkLineAdjId) AS NumberOfItems FROM FinalResult)  
      SELECT AdjustmentType,BulkStkLineAdjId, BulkStkLineAdjNumber, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsDeleted, StatusId, NumberOfItems FROM FinalResult, ResultCount  
  
      ORDER BY    
	  CASE WHEN (@SortOrder=1 AND @SortColumn='AdjustmentType')  THEN AdjustmentType END ASC,
      CASE WHEN (@SortOrder=1 AND @SortColumn='BulkStkLineAdjId')  THEN BulkStkLineAdjId END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='BulkStkLineAdjNumber')  THEN BulkStkLineAdjNumber END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,   
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='AdjustmentType')  THEN AdjustmentType END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='BulkStkLineAdjId')  THEN BulkStkLineAdjId END DESC,  
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='BulkStkLineAdjNumber')  THEN BulkStkLineAdjNumber END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
   END  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_GetVendorRMAList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END