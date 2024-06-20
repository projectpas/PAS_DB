/*************************************************************             
 ** File:   [GetSubWOAssetList]             
 ** Author:   Subhash Saliya  
 ** Description: Get Search Data for GetSubWOAsset List      
 ** Purpose:           
 ** Date:   23-march-2020          
            
 ** PARAMETERS:             
 @POId varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    03/23/2020   Subhash Saliya	Created  
	2    06/25/2020   Hemant  Saliya	Added Transation & Content Management 
	3    04/24/2023   Shrey Chandegara	Join Change with table AssetAttributeType
	4    06/20/2023   Devendra Shekh	Join Change with table TangibleClass
       
exec GetSubWOAssetList 
@PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@SubWorkOrderAssetId=0,@SubWOPartNoId=231,
@TaskName=NULL,@Name=NULL,@AssetId=NULL,@Description=NULL,@TangibleClassName=NULL,@Quantity=0,
@CheckInDate=NULL,@CheckOutDate=NULL,@CheckInBy=NULL,@CheckOutBy=NULL,@IsDeleted=0,@MasterCompanyId=1,@AssetClass=NULL,@Status=NULL 
**************************************************************/   
  
CREATE   PROCEDURE [dbo].[GetSubWOAssetList]  
 -- Add the parameters for the stored procedure here   
 @PageSize int,  
 @PageNumber int,  
 @SortColumn varchar(50) = null,  
 @SortOrder int,   
 @GlobalFilter varchar(50) = null,  
 @SubWorkOrderAssetId Bigint = null,  
 @SubWOPartNoId Bigint = null,  
 @TaskName varchar(50) = null,  
 @Name varchar(50) = null,   
 @AssetId varchar(50) = null,  
 @Description varchar(50) = null,  
 @TangibleClassName varchar(50) = null,  
    @Quantity int = null,      
    @CheckInDate datetime = null,  
    @CheckOutDate  datetime = null,  
 @CheckInBy  varchar(50) = null,  
 @CheckOutBy  varchar(50) = null,  
    @IsDeleted bit= null,  
 @MasterCompanyId bigint = NULL,  
 @AssetClass  varchar(50) = null,  
 @Status  varchar(50) = null  
  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
 BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
     DECLARE @RecordFrom int;  
     DECLARE @IsActive bit=1  
     DECLARE @Count Int;  
     SET @RecordFrom = (@PageNumber-1)*@PageSize;  
     IF @IsDeleted is null  
     Begin  
      Set @IsDeleted=0  
     End  
     print @IsDeleted   
    
     IF @SortColumn is null  
     Begin  
      Set @SortColumn=Upper('CreatedDate')  
     End   
     Else  
     Begin   
      Set @SortColumn=Upper(@SortColumn)  
     End  
    
     ;With Result AS(  
      Select   
       WOA.AssetRecordId,  
       WOA.WorkOrderId,  
       WOA.SubWorkOrderAssetId,  
       A.AssetId,  
       A.Description,  
       A.Name,  
       T.[Description] AS TaskName,  
       T.TaskId,  
       at.TangibleClassId,  
       at.TangibleClassName,  
       WOA.Quantity,  
       WOA.IsActive,  
       WOA.IsDeleted,  
       WOA.CreatedDate,  
       WOA.CreatedBy,  
       WOA.UpdatedDate,  
       WOA.UpdatedBy,  
       WOA.MasterCompanyId,  
       WOA.SubWOPartNoId,  
       WOA.SubWorkOrderId,  
       AssetClass= AAT.AssetAttributeTypeName,  
       (CIE.FirstName + ' ' + CIE.LastName) AS CheckInEmp,  
       (CIB.FirstName + ' ' + CIB.LastName) AS CheckInBy,  
       (COE.FirstName + ' ' + COE.LastName) AS CheckOutEmp,  
       (COB.FirstName + ' ' + COB.LastName) AS CheckOutBy,  
       COCI.CheckInDate,  
       COCI.CheckOutDate,  
       case when isnull(WOA.IsFromWorkFlow,0) =0 then 'No' else 'Yes' end IsFromWorkFlowNew,    
                            CASE WHEN  ISNULL(COCI.CheckOutDate,'') !='' THEN 'Checked Out of WO' WHEN isnull(COCI.CheckInDate,'') !='' THEN 'Checked In To WO'  ELSE ''  END  AS Status    
       FROM dbo.SubWorkOrderAsset WOA WITH (NOLOCK)  
       join dbo.Asset A WITH (NOLOCK) on WOA.AssetRecordId = A.AssetRecordId  
       LEFT JOIN dbo.Task T WITH(NOLOCK) on T.TaskId = WOA.TaskId  
       LEFT JOIN dbo.AssetAttributeType AAT WITH (NOLOCK) on A.AssetAttributeTypeId = AAT.AssetAttributeTypeId  
       JOIN dbo.TangibleClass at WITH (NOLOCK) ON AAT.TangibleClassId = at.TangibleClassId  
       LEFT JOIN dbo.SubWOCheckInCheckOutWorkOrderAsset COCI WITH (NOLOCK) ON WOA.SubWorkOrderAssetId = COCI.SubWorkOrderAssetId AND COCI.IsQtyCheckOut = 1  
       LEFT JOIN dbo.AssetInventory AI WITH (NOLOCK) ON COCI.AssetInventoryId =  AI.AssetInventoryId  
       LEFT JOIN dbo.AssetInventoryStatus AIS WITH (NOLOCK) ON AIS.AssetInventoryStatusId =  AI.InventoryStatusId  
       LEFT JOIN dbo.Employee CIE WITH (NOLOCK) ON COCI.CheckInEmpId = CIE.EmployeeId  
       LEFT JOIN dbo.Employee CIB WITH (NOLOCK) ON COCI.CheckInById = CIB.EmployeeId  
       LEFT JOIN dbo.Employee COE WITH (NOLOCK) ON COCI.CheckOutEmpId = COE.EmployeeId  
       LEFT JOIN dbo.Employee COB WITH (NOLOCK) ON COCI.CheckOutById = COB.EmployeeId  
       WHERE WOA.IsDeleted = @IsDeleted AND WOA.MasterCompanyId = @MasterCompanyId AND WOA.SubWOPartNoId = @SubWOPartNoId  
     ), ResultCount AS(Select COUNT(SubWorkOrderAssetId) AS totalItems FROM Result)  
     Select * INTO #TempResult from  Result  
     WHERE (  
     (@GlobalFilter <>'' AND ((Name like '%' +@GlobalFilter+'%' ) OR  
       (Description like '%' +@GlobalFilter+'%') OR  
       (TaskName like '%' +@GlobalFilter+'%') OR         
       (TangibleClassName like '%' +@GlobalFilter+'%') OR  
       (AssetId like '%' +@GlobalFilter+'%') OR  
       (AssetClass like '%' +@GlobalFilter+'%') OR  
       (CAST(Quantity AS NVARCHAR(10)) like '%' +@GlobalFilter+'%') OR       
       (CreatedBy like '%' +@GlobalFilter+'%') OR  
       (UpdatedBy like '%' +@GlobalFilter+'%')   
       ))  
       OR     
       (@GlobalFilter='' AND (IsNull(@Name,'') ='' OR Name like '%' + @Name+'%') and   
       (IsNull(@Description,'') ='' OR Description like '%' + @Description+'%') and  
       (IsNull(@TaskName,'') ='' OR TaskName like '%' + @TaskName +'%') and  
       (IsNull(@TangibleClassName,'') ='' OR TangibleClassName like '%' + @TangibleClassName+'%') and  
       (IsNull(@Quantity,'') ='' OR Quantity = @Quantity) and   
       (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') and  
       (IsNull(@AssetClass,'') ='' OR AssetClass like '%' + @AssetClass+'%') and  
       (IsNull(@CheckInBy,'') ='' OR CheckInBy like '%' + @CheckInBy+'%') and  
       (IsNull(@Status,'') ='' OR Status like '%' + @Status+'%') and  
       (IsNull(@CheckOutBy,'') ='' OR CheckOutBy like '%' + @CheckOutBy+'%') and  
       (IsNull(@CheckInDate,'') ='' OR Cast(CheckInDate as Date)=Cast(@CheckInDate as date)) and  
       (IsNull(@CheckOutDate,'') ='' OR Cast(CheckOutDate as date)=Cast(@CheckOutDate as date)))  
       )  
  
       Select @Count = COUNT(SubWorkOrderAssetId) from #TempResult     
  
       SELECT *, @Count As NumberOfItems FROM #TempResult  
        ORDER BY       
        CASE WHEN (@SortOrder=1 and @SortColumn='NAME')  THEN Name END ASC,  
          CASE WHEN (@SortOrder=1 and @SortColumn='Status')  THEN Status END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='DESCRIPTION')  THEN Description END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TaskName')  THEN TaskName END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TANGIBLECLASSNAME')  THEN TangibleClassName END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='QUANTITY')  THEN Quantity END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CheckInDate')  THEN CheckInDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CheckOutDate')  THEN CheckOutDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CheckInBy')  THEN CheckInBy END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CheckOutBy')  THEN CheckOutBy END ASC,  
  
        CASE WHEN (@SortOrder=-1 and @SortColumn='NAME')  THEN Name END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Status')  THEN Status END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='DESCRIPTION')  THEN Description END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='TaskName')  THEN TaskName END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='TANGIBLECLASSNAME')  THEN TangibleClassName END ASC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='QUANTITY')  THEN Quantity END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CheckInBy')  THEN CheckInBy END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CheckOutBy')  THEN CheckOutBy END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CheckInDate')  THEN CheckInDate END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CheckOutDate')  THEN CheckOutDate END Desc  
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
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderFreightAuditList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageSize, '') + ''',  
                @Parameter2 = ' + ISNULL(@PageNumber ,'') +'''  
                @Parameter3 = ' + ISNULL(@SortColumn ,'') +'''  
                @Parameter4 = ' + ISNULL(@GlobalFilter ,'') +'''  
                @Parameter5 = ' + ISNULL(@SubWorkOrderAssetId ,'') +'''  
                @Parameter6 = ' + ISNULL(@SubWOPartNoId ,'') +'''  
                @Parameter7 = ' + ISNULL(@Name ,'') +'''  
                @Parameter8 = ' + ISNULL(@AssetId ,'') +'''  
                @Parameter9 = ' + ISNULL(@Description ,'') +'''  
                @Parameter10 = ' + ISNULL(@TangibleClassName ,'') +'''  
                @Parameter11 = ' + ISNULL(@Quantity ,'') +'''  
                @Parameter12 = ' + ISNULL(CAST(@CheckInDate AS varchar(20)) ,'') +'''  
                @Parameter13 = ' + ISNULL(CAST(@CheckOutDate AS varchar(20)) ,'') +'''  
                @Parameter14 = ' + ISNULL(@CheckInBy ,'') +'''  
                @Parameter15 = ' + ISNULL(@CheckOutBy ,'') +'''  
                @Parameter16 = ' + ISNULL(CAST(@IsDeleted AS varchar(10)) ,'') +'''  
                @Parameter17 = ' + ISNULL(@MasterCompanyId ,'') +'''  
                @Parameter18 = ' + ISNULL(CAST(@Status AS varchar(20)) ,'') +''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName   = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN  
  END CATCH  
END