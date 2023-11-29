/*************************************************************           
 ** File:   [USP_VendorRMA_CreditMeMo_GetVendorRMAList]          
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to get vendorrma for credit memo create
 ** Purpose:         
 ** Date:   07/05/2023        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    07/05/2023   Devendra Shekh			Created
     
 exec USP_VendorRMA_CreditMeMo_GetVendorRMAList 
@PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',
@RMANumber=NULL,@Partnumber=NULL,@StockLineNumber=NULL,@PartDescription=NULL,
@MasterCompanyId=1,@ViewType=N'detailview',@vendorRMADetailStatusId=3,
@VendorRMAId=0,@VendorName=NULL,@QtyShipped=NULL

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_CreditMeMo_GetVendorRMAList]  
 @PageNumber INT,  
 @PageSize INT,  
 @SortColumn VARCHAR(50)=null,  
 @SortOrder INT,  
 @GlobalFilter VARCHAR(50) = null,  
 @RMANumber VARCHAR(100) = NULL,
 @Partnumber VARCHAR(100) NULL,
 @StockLineNumber VARCHAR(100) NULL,
 @PartDescription VARCHAR(100) NULL,
 @CreatedDate DATETIME=NULL,  
 @UpdatedDate  datetime=NULL,  
 @MasterCompanyId INT=NULL,
 @ViewType VARCHAR(50)=NULL,
 @VendorRMADetailStatusId  INT=NULL,
 @VendorRMAId BIGINT=NULL,
 @VendorName VARCHAR(100) NULL,
 @QtyShipped varchar(50)=NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
    DECLARE @RecordFrom int;  
    DECLARE  @VendorRMADetailStatus VARCHAR(100)= NULL;  
    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
    IF @SortColumn is null  
    Begin  
     Set @SortColumn=Upper('CreatedDate')  
    End   
    Else  
    Begin   
     Set @SortColumn=Upper(@SortColumn)  
    End  

	IF @ViewType = 'detailview'
	BEGIN	
		;With Result AS(  
		SELECT 
			RMA.[VendorRMAId] AS 'VendorRMAId',
			V.[VendorId] AS 'VendorId',
			ISNULL(V.[VendorName],'') AS 'VendorName',
			ISNULL(V.[VendorCode],'') AS 'VendorCode',
			RMAD.[RMANum] AS 'RMANumber',
			IM.[ItemMasterId] AS 'ItemMasterId',
			IM.[partnumber] AS 'PartNumberType',	
			SL.[StockLineId] AS 'StockLineIdType',
			SL.[StockLineNumber] AS 'StockLineNumberType',
			IM.[PartDescription] AS 'PartDescriptionType',
			RMAD.[CreatedDate], 
			RMAD.[UpdatedDate], 
			RMAD.[UpdatedBy], 
			RMAD.[CreatedBy],
			RMAD.[ReferenceId],
			VCM.VendorCreditMemoId as 'VendorCreditMemoId',
			VS.VendorRMAStatus as 'VendorRMADetailStatus',
			RMA.RMANumber as 'VendorRMANumber',
			RMAD.ModuleId,
			RMS.QtyShipped,
			RMAD.VendorRMADetailId
		FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
		INNER JOIN [DBO].[Vendor] V WITH (NOLOCK) ON RMA.VendorId = V.VendorId
		INNER JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.[VendorRMAId] = RMAD.[VendorRMAId]
		INNER JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON RMAD.[StockLineId] = SL.[StockLineId]
		INNER JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON RMAD.[ItemMasterId] = IM.[ItemMasterId]
		LEFT JOIN [DBO].[VendorCreditMemo] VCM WITH (NOLOCK) ON VCM.VendorRMAId = RMA.VendorRMAId
		LEFT JOIN [DBO].[VendorRMAStatus] VS WITH (NOLOCK) ON RMAD.VendorRMAStatusId = VS.VendorRMAStatusId
		LEFT JOIN [DBO].[RMAShippingItem] RMS WITH (NOLOCK) ON RMAD.VendorRMADetailId = RMS.VendorRMADetailId
		WHERE RMA.[VendorRMAId] = CASE WHEN @VendorRMAId != 0 and @VendorRMAId is not null THEN @VendorRMAId ELSE RMAD.[VendorRMAId] END
		AND VS.VendorRMAStatusId = @VendorRMADetailStatusId AND RMA.VendorRMAId NOT IN (SELECT ISNULL(VendorRMAId,0) VendorRMAId FROM VendorCreditMemo WHERE MasterCompanyId = @MasterCompanyId)
		),
    FinalResult AS (  
    SELECT VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, ItemMasterId, PartNumberType, StockLineIdType, StockLineNumberType, PartDescriptionType, 
      CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, ReferenceId, VendorCreditMemoId, VendorRMADetailStatus, VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId FROM Result  
    where  (  
     (@GlobalFilter <>'' AND ((RMANumber like '%' +@GlobalFilter+'%' ) OR   
       (PartNumberType like '%' +@GlobalFilter+'%') OR  
       (StockLineNumberType like '%' +@GlobalFilter+'%') OR  
       (PartDescriptionType like '%' +@GlobalFilter+'%') OR  
	   (VendorName like '%' +@GlobalFilter+'%') OR  
       (CreatedDate like '%' +@GlobalFilter+'%') OR  
       (UpdatedDate like '%' +@GlobalFilter+'%') 
       ))  
       OR     
       (@GlobalFilter='' AND (IsNull(@RMANumber,'') ='' OR RMANumber like  '%'+ @RMANumber+'%') and   
       (IsNull(@Partnumber,'') ='' OR PartNumberType like '%'+ @Partnumber+'%') and  
       (IsNull(@StockLineNumber,'') ='' OR StockLineNumberType like '%'+ @StockLineNumber +'%') and  
       (IsNull(@PartDescription,'') ='' OR PartDescriptionType like '%'+ @PartDescription +'%') and  
	   (IsNull(@VendorName,'') ='' OR VendorName like '%'+@VendorName+'%') and  
	   (ISNULL(@QtyShipped,'') ='' OR CAST(QtyShipped AS varchar(10)) LIKE '%' + CAST(@QtyShipped AS VARCHAR(10))+ '%') AND
       (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and  
       (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date))
	   )  
       )),  
      ResultCount AS (Select COUNT(VendorRMAId) AS NumberOfItems FROM FinalResult)  
      SELECT VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, ItemMasterId, PartNumberType, StockLineIdType, StockLineNumberType, PartDescriptionType, 
      CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, ReferenceId, VendorCreditMemoId, VendorRMADetailStatus, VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId, NumberOfItems FROM FinalResult, ResultCount  
  
      ORDER BY    
      CASE WHEN (@SortOrder=1 and @SortColumn='VENDORRMAID')  THEN VendorRMAId END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='RMANUMBER')  THEN RMANumber END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='ITEMMASTERID')  THEN ItemMasterId END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='STOCKLINENUMBERTYPE')  THEN StockLineNumberType END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC, 
      CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC, 
  	  
      CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORRMAID')  THEN VendorRMAId END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='RMANUMBER')  THEN RMANumber END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMMASTERID')  THEN ItemMasterId END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='STOCKLINENUMBERTYPE')  THEN StockLineNumberType END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END DESC, 
      CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
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
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_CreditMeMo_GetVendorRMAList'   
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