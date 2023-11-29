/*************************************************************             
 ** File:   [USP_GetVendorRMA_History]             
 ** Author:  Devendra Shekh  
 ** Description: This stored procedure is used History data  of VendorRMA
 ** Purpose:           
 ** Date:   03/07/2023        
            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author					Change Description              
 ** --   --------     -------				--------------------------------            
    1    03/07/2023   Devendra Shekh			Created  
       
--exec USP_GetVendorRMA_History
@PageSize=50,@PageNumber=1,@SortColumn=N'HistoryId',@SortOrder=1,@GlobalFilter=N'',@HistoryId=0,@ReferenceId=54,@RMANum=NULL,@RMANumber=NULL,@OldValue=NULL,@NewValue=NULL,
@HistoryText=NULL,@MasterCompanyId=1,@CreatedDate=NULL,@UpdatedDate=NULL,@CreatedBy=NULL,@UpdatedBy=NULL,@ModuleId=45
************************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetVendorRMA_History]  
 @PageNumber INT,  
 @PageSize INT,  
 @SortColumn VARCHAR(50)=null,  
 @SortOrder INT,  
 @GlobalFilter VARCHAR(50) = null,   
 @HistoryId VARCHAR(20),  
 @ReferenceId BIGINT,  
 @RMANumber VARCHAR(MAX) = null,  
 @RMANum VARCHAR(MAX) = null,  
 @OldValue VARCHAR(MAX) = null,  
 @NewValue VARCHAR(MAX) = null,  
 @HistoryText VARCHAR(MAX) = null,  
 @MasterCompanyId INT,  
 @CreatedDate DATETIME=null,  
 @UpdatedDate  DATETIME=null,  
 @CreatedBy VARCHAR(50)=null,  
 @UpdatedBy VARCHAR(50)=null,
 @ModuleId BIGINT = null
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
   DECLARE @RecordFrom INT;  
    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
      
    IF @SortColumn is null  
    BEGIN  
     SET @SortColumn=Upper('CreatedDate')  
    END   
    Else  
    BEGIN   
     SET @SortColumn=Upper(@SortColumn)  
    END  
  
    ;With Result AS(  
    SELECT HS.[HistoryId],  
     HS.[ModuleId],  
     --HS.[RefferenceId],  
     vrm.[RMANumber],  
	 vrmd.[RMANum],  
     HS.[OldValue],  
     HS.[NewValue],  
     HS.[HistoryText],  
     HS.[FieldsName],  
     HS.[CreatedBy],  
     HS.[CreatedDate],  
     HS.[UpdatedBy],  
     HS.[UpdatedDate]   
    FROM History HS WITH (NOLOCK)  
    INNER JOIN [dbo].[VendorRMA] vrm WITH (NOLOCK) ON HS.RefferenceId = vrm.VendorRMAId  
    LEFT JOIN [dbo].[VendorRMADetail] vrmd WITH (NOLOCK) ON hs.SubRefferenceId = vrmd.VendorRMADetailId  
    WHERE HS.RefferenceId = @ReferenceId AND HS.ModuleId = @ModuleId --AND HS.MasterCompanyId = @MasterCompanyId    
    ),  
    FinalResult AS (  
    SELECT HistoryId, ModuleId, RMANumber, RMANum, OldValue, NewValue, HistoryText, FieldsName  
      ,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result  
    WHERE (  
     (@GlobalFilter <>'' AND ((HistoryId like '%' +@GlobalFilter+'%') OR   
       (OldValue like '%' +@GlobalFilter+'%') OR  
       (NewValue like '%' +@GlobalFilter+'%') OR  
       (HistoryText like '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND   
       (IsNull(@OldValue,'') ='' OR OldValue like  '%'+@OldValue+'%') and  
       (IsNull(@NewValue,'') ='' OR NewValue like  '%'+@NewValue+'%') and  
       (IsNull(@RMANum,'') ='' OR RMANum like  '%'+@RMANum+'%') and  
       (IsNull(@RMANumber,'') ='' OR RMANumber like  '%'+@RMANumber+'%') and  
       (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like  '%'+@UpdatedBy+'%') and  
       (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and  
       (IsNull(@HistoryText,'') ='' OR HistoryText like '%'+@HistoryText+'%'))  
       )),  
      ResultCount AS (Select COUNT(HistoryId) AS NumberOfItems FROM FinalResult)  
      SELECT HistoryId, ModuleId, RMANumber, RMANum, OldValue, NewValue, HistoryText, FieldsName,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,  
      NumberOfItems FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='HistoryId')  THEN HistoryId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='OldValue')  THEN OldValue END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='NewValue')  THEN NewValue END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='RMANumber')  THEN RMANumber END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='RMANum')  THEN RMANum END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='HistoryText')  THEN HistoryText END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='HistoryId')  THEN HistoryId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='OldValue')  THEN OldValue END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='NewValue')  THEN NewValue END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RMANumber')  THEN RMANumber END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='RMANum')  THEN RMANum END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='HistoryText')  THEN HistoryText END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC  
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    COMMIT  TRANSACTION  
    END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRMA_History'   
            , @ProcedureParameters VARCHAR(3000) = '@HistoryId = ''' + CAST(ISNULL(@HistoryId, '') as varchar(100))  
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