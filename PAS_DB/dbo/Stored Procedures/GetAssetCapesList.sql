  
  
/*************************************************************             
 ** File:   [GetAssetCapesList]             
 ** Author:   Subhash Saliya  
 ** Description: Get Search Data for GetAssetCapesList      
 ** Purpose:           
 ** Date:   05/04/2020        
            
 ** PARAMETERS:             
 @POId varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    05/04/2020   Subhash Saliya Created  
  
       
 EXECUTE [GetAssetCapesList] 10, 1, null, -1, '',null, '','','',null,null,null,null,null,null,0,1  
**************************************************************/   
  
CREATE PROCEDURE [dbo].[GetAssetCapesList]  
 -- Add the parameters for the stored procedure here   
 @PageSize int,  
 @PageNumber int,  
 @SortColumn varchar(50) = null,  
 @SortOrder int,  
 @StatusID int = 0,  
 @GlobalFilter varchar(50) = '',  
 @partNumber varchar(50) = null,  
 @partDescription varchar(50) = null,  
 @captypedescription varchar(50) = null,  
 @modelname varchar(50) = null,  
 @dashnumber varchar(50) = null,  
 @manufacturer varchar(50) = null,  
 @manufacturerName	varchar(50) =null,
 @itemClassification	varchar(50)=null,
 @itemGroup	varchar(50)=null,
 @id bigint = 0,  
 @CreatedDate datetime = null,  
 @UpdatedDate  datetime = null,  
 @CreatedBy  varchar(50) = null,  
 @UpdatedBy  varchar(50) = null,  
    @IsDeleted bit = null,  
 @MasterCompanyId int = 0  
AS  
BEGIN  
  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 DECLARE @RecordFrom int;  
 Declare @IsActive bit=1  
 Declare @Count Int;  
 SET @RecordFrom = (@PageNumber - 1) * @PageSize;  
 IF @IsDeleted is null  
 Begin  
  Set @IsDeleted = 0  
 End  
 print @IsDeleted   
    
 IF @SortColumn is null  
 Begin  
  Set @SortColumn = Upper('CreatedDate')  
 End   
 Else  
 Begin   
  Set @SortColumn = Upper(@SortColumn)  
 End  
  
 If @StatusID = 0  
 Begin   
  Set @IsActive = 0  
 End   
 else IF @StatusID = 1  
 Begin   
  Set @IsActive = 1  
 End   
 else IF @StatusID = 2  
 Begin   
  Set @IsActive = null  
 End   
  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
    ;With Result AS(  
     SELECT   
      assetCapesId = capability.AssetCapesId,  
      aircraftTypeId = capability.AircraftTypeId,  
      aircraftModelId = capability.AircraftModelId,  
      partNumber = im.PartNumber,  
      partDescription = im.PartDescription,  
      --captypedescription = captype.CapabilityTypeDesc,  
      --manufacturer = act.Description,  
     -- modelname = acm.ModelName,  
     -- dashnumber = dn.DashNumber,  
      CreatedBy = capability.CreatedBy,  
      UpdatedDate = capability.UpdatedDate,  
      UpdatedBy = capability.UpdatedBy,  
      createdDate = capability.CreatedDate,  
      isActive = capability.IsActive,  
      isDeleted = capability.IsDeleted  ,
	  ItemClassification=  ic.ItemClassificationCode ,
	  im.ManufacturerId,
	  ManufacturerName=ma.Name,
	  im.ItemClassificationId,
      im.ItemGroupId,
	  ItemGroup=ig.ItemGroupCode
    FROM dbo.AssetCapes capability WITH(NOLOCK)  
     INNER JOIN dbo.ItemMaster im WITH(NOLOCK) on capability.ItemMasterId = im.ItemMasterId 
	 left JOIN dbo.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
	 left join dbo.Itemgroup ig with(NOLOCK) on im.ItemGroupId = ig.ItemGroupId
     --left JOIN dbo.capabilityType captype WITH(NOLOCK) on capability.CapabilityId = captype.CapabilityTypeId  
     --LEFT JOIN dbo.AircraftType act WITH(NOLOCK) on capability.AircraftTypeId = act.AircraftTypeId  
     --LEFT JOIN dbo.AircraftModel acm WITH(NOLOCK) on capability.AircraftModelId = acm.AircraftModelId  
     --LEFT JOIN dbo. AircraftDashNumber dn WITH(NOLOCK) ON capability.AircraftDashNumberId = dn.DashNumberId  
	 left join dbo.Manufacturer ma with(nolock)on im.ManufacturerId =ma.ManufacturerId
    WHERE ((capability.AssetRecordId = @id) and (capability.IsDeleted = @IsDeleted)    AND (@IsActive is null or isnull(capability.IsActive,1) = @IsActive))  
   ), ResultCount AS(SELECT COUNT(assetCapesId) AS totalItems FROM Result)  
   SELECT * INTO #TempResult from  Result  
   WHERE (  
    (@GlobalFilter <>'' AND (  
      (partNumber like '%' +@GlobalFilter+'%') OR  
      (partDescription like '%' +@GlobalFilter+'%') OR  
      --(captypedescription like '%' +@GlobalFilter+'%') OR  
     -- (manufacturer like '%' +@GlobalFilter+'%') OR    
      --(modelname like '%' +@GlobalFilter+'%') OR  
     -- (dashnumber like '%' +@GlobalFilter+'%') OR 
	 (ManufacturerName like'%' +@GlobalFilter+'%') OR
	 (ItemClassification like'%' +@GlobalFilter+'%') OR
	 (ItemGroup like'%' +@GlobalFilter+'%') OR
      (CreatedBy like '%'+@GlobalFilter+'%') OR  
      (UpdatedBy like '%' +@GlobalFilter+'%')   
      ))  
     OR     
     (@GlobalFilter='' AND (IsNull(@partNumber,'') ='' OR partNumber like '%' + @partNumber+'%') AND  
      (IsNull(@partDescription,'') ='' OR partDescription like '%' + @partDescription+'%') AND  
     -- (IsNull(@captypedescription,'') ='' OR captypedescription like '%' + @captypedescription+'%') AND  
     -- (IsNull(@manufacturer,'') ='' OR manufacturer like '%' + @manufacturer+'%') AND  
     -- (IsNull(@modelname,'') ='' OR modelname like '%' + @modelname+'%') AND  
     -- (IsNull(@dashnumber,'') ='' OR dashnumber like '%' + @dashnumber+'%') AND  
	 (IsNull(@manufacturerName,'') ='' OR manufacturerName like '%' + @manufacturerName+'%') AND
	 (IsNull(@itemClassification,'') ='' OR itemClassification like '%' + @itemClassification+'%') AND
	 (IsNull(@itemGroup,'') ='' OR itemGroup like '%' + @itemGroup+'%') AND
      (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
      (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and  
      (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
      (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%')   
      ))  
   SELECT @Count = COUNT(assetCapesId) from #TempResult     
  
   SELECT *, @Count As NumberOfItems FROM #TempResult  
   ORDER BY       
   CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN partNumber END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN partDescription END ASC,
   CASE WHEN (@SortOrder=1 and @SortColumn='MANUFACTURERNAME')  THEN manufacturerName END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='ITEMCLASSIFICATION')  THEN itemClassification END ASC, 
   CASE WHEN (@SortOrder=1 and @SortColumn='ITEMGROUP')  THEN itemGroup END ASC,
   --CASE WHEN (@SortOrder=1 and @SortColumn='CAPTYPEDESCRIPTION')  THEN captypedescription END ASC,  
   --CASE WHEN (@SortOrder=1 and @SortColumn='MANUFACTURER')  THEN manufacturer END ASC,  
   --CASE WHEN (@SortOrder=1 and @SortColumn='MODELNAME')  THEN modelname END ASC,  
   --CASE WHEN (@SortOrder=1 and @SortColumn='DASHNUMBER')  THEN dashnumber END ASC,  
  
   CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN partNumber END dESC,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN partDescription END dESC,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='MANUFACTURERNAME')  THEN manufacturerName END DESC,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMCLASSIFICATION')  THEN itemClassification END DESC, 
   CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMGROUP')  THEN itemGroup END DESC 
   --CASE WHEN (@SortOrder=-1 and @SortColumn='CAPTYPEDESCRIPTION')  THEN captypedescription END dESC,  
   --CASE WHEN (@SortOrder=-1 and @SortColumn='MANUFACTURER')  THEN manufacturer END dESC,  
   --CASE WHEN (@SortOrder=-1 and @SortColumn='MODELNAME')  THEN modelname END dESC,  
   --CASE WHEN (@SortOrder=-1 and @SortColumn='DASHNUMBER')  THEN dashnumber END dESC  
  
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
            , @AdhocComments     VARCHAR(150)    = 'GetRecevingCustomerList'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''',   
             @Parameter2 = ' + ISNULL(@PageSize,'') + ',   
             @Parameter3 = ' + ISNULL(@SortColumn,'') + ',   
             @Parameter4 = ' + ISNULL(@SortOrder,'') + ',   
             @Parameter5 = ' + ISNULL(@StatusID,'') + ',   
             @Parameter6 = ' + ISNULL(@GlobalFilter,'') + ',   
             @Parameter7 = ' + ISNULL(@partNumber,'') + ',   
             @Parameter8 = ' + ISNULL(@partDescription,'') + ',   
             @Parameter9 = ' + ISNULL(@captypedescription,'') + ',   
             @Parameter10 = ' + ISNULL(@modelname,'') + ',   
             @Parameter11 = ' + ISNULL(@dashnumber,'') + ',   
             @Parameter12 = ' + ISNULL(@manufacturer,'') + ',  
			 @Parameter13 = ' + ISNULL(@manufacturerName,'') + ',  
			 @Parameter14 = ' + ISNULL(@itemClassification,'') + ',  
			 @Parameter15 = ' + ISNULL(@itemGroup,'') + ',  
             @Parameter16 = ' + ISNULL(@id,'') + ',   
             @Parameter17 = ' + ISNULL(@CreatedDate,'') + ',  
             @Parameter18 = ' + ISNULL(@UpdatedDate,'') + ',   
             @Parameter19 = ' + ISNULL(@CreatedBy,'') + ',   
             @Parameter20 = ' + ISNULL(@UpdatedBy,'') + ',   
             @Parameter21 = ' + ISNULL(@IsDeleted,'') + ',   
             @Parameter22 = ' + ISNULL(@MasterCompanyId ,'') +''  
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