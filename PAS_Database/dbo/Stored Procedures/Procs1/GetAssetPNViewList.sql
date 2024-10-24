﻿

/*************************************************************           
 ** File:   [GetAssetPNViewList]
 ** Author:   
 ** Description: This stored procedure is used to Get Asset List PN View
 ** Purpose:         
 ** Date:    
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    									Created
    2	 06/10/2024  Abhishek Jirawla		Returning upper case data
	

************************************************************************/

CREATE PROCEDURE [dbo].[GetAssetPNViewList]  
 -- Add the parameters for the stored procedure here   
@PageSize int,  
@PageNumber int,  
@SortColumn varchar(50),  
@SortOrder int,  
@StatusID int,  
@GlobalFilter varchar(50),  
@AssetId varchar(50),  
@Name varchar(50),  
@AlternateAssetId varchar(50),  
@ManufacturerName varchar(50),  
@IsSerializedNew varchar(50),  
@CalibrationRequiredNew varchar(50),  
@AssetStatus varchar(50),  
@AssetType varchar(50),  
@CompanyName varchar(50),  
@BuName varchar(50),  
@DivName varchar(50),  
@DeptName varchar(50),  
@deprAmort varchar(50),  
@CreatedDate datetime,  
@UpdatedDate  datetime,  
@CreatedBy  varchar(50),  
@UpdatedBy  varchar(50),  
@IsDeleted bit,  
@MasterCompanyId int,  
@PartNumber varchar(50)=null,  
@PartDescription varchar(50)=null ,
@ManufacturerPN		varchar(50)=null,
@EmployeeId bigint=1
AS  
BEGIN  
  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  DECLARE @RecordFrom int;  
  Declare @IsActive bit = 1 
  DECLARE @ModuleID varchar(500) ='40,41'
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
   Set @IsActive=null  
  End   
  
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
      
    ;With Result AS(  
              Select   
    UPPER(asm.AssetRecordId) as AssetRecordId,         
    asm.IsDepreciable AS IsDepreciable,  
    asm.IsAmortizable AS IsAmortizable,  

    UPPER(asm.Name) AS Name,  
    UPPER(asm.AssetId) AS AssetId,  
    UPPER((SELECT TOP 1 AssetId FROM dbo.Asset WITH(NOLOCK) where AssetRecordId=asm.AlternateAssetRecordId)) AS AlternateAssetId,  
    UPPER(maf.Name) AS ManufacturerName,  
    UPPER(CASE WHEN asm.IsSerialized = 1 THEN 'Yes'else 'No' END) AS IsSerializedNew,  
    UPPER(CASE WHEN ascal.CalibrationRequired = 1 THEN 'Yes'else 'No' END) AS CalibrationRequiredNew,  
    UPPER(CASE WHEN asm.IsTangible = 1 THEN 'Tangible'else 'Intangible' END) AS AssetClass,
	UPPER((SELECT TOP 1 AssetDepreciationMethodName FROM dbo.AssetDepreciationMethod AS adm WITH(NOLOCK) WHERE adm.AssetDepreciationMethodId = asty.DepreciationMethod)) AS DepreciationMethod,
    UPPER(ISNULL((case when ISNULL(asm.IsTangible, 0) = 1 and ISNULL(asm.IsDepreciable,0)=1 THEN 'Yes' when  ISNULL(asm.IsTangible,0) = 0 and ISNULL(asm.IsAmortizable,0)=1  THEN  'Yes'  else 'No'  end),'No')) as deprAmort,  
    UPPER(asty.AssetAttributeTypeName) AS AssetType,   
    UPPER(asm.MasterCompanyId) AS MasterCompanyId,  
    asm.CreatedDate AS CreatedDate,  
    asm.UpdatedDate AS UpdatedDate,  
    UPPER(asm.CreatedBy) AS CreatedBy,  
    UPPER(asm.UpdatedBy) AS UpdatedBy ,  
    asm.IsActive AS IsActive,  
    asm.IsDeleted AS IsDeleted  ,
	UPPER(asm.ManufacturerPN) AS ManufacturerPN
	  ,(SELECT CAST(ai.AssetInventoryId as NVARCHAR(100)) + ',' 
	  FROM dbo.AssetInventory ai  WITH(NOLOCK) WHERE ai.AssetRecordId=asm.AssetRecordId FOR XML PATH('')) AS AssetInventoryIds
     FROM dbo.Asset asm WITH(NOLOCK)  
      LEFT JOIN dbo.AssetCalibration ascal WITH(NOLOCK) on asm.AssetRecordId = ascal.AssetRecordId  
      --LEFT JOIN dbo.AssetAttributeType asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId  
	  LEFT JOIN dbo.AssetAttributeType asty WITH(NOLOCK) on asm.AssetAttributeTypeId = asty.AssetAttributeTypeId
      LEFT JOIN dbo.Manufacturer maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId 
	  --INNER JOIN dbo.AssetManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID  IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleID,',')) AND MSD.ReferenceID = asm.AssetRecordId
	  --INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON asm.ManagementStructureId = RMS.EntityStructureId
	  --INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
     WHERE ((asm.IsDeleted = @IsDeleted) and (asm.MasterCompanyId = @MasterCompanyId) AND (@IsActive is null or ISNULL(asm.IsActive,1) = @IsActive))  
   ),  
   PartCTE AS(  
    Select PC.AssetRecordId,(Case When Count(PCI.AssetRecordId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',  
    A.PartNumber from Asset PC WITH (NOLOCK)  
    Left Join AssetCapes PCI WITH (NOLOCK) On PC.AssetRecordId = PCI.AssetRecordId  
    Outer Apply(  
     SELECT   
        STUFF((SELECT ',' + I.partnumber  
         FROM AssetCapes S WITH (NOLOCK)  
         Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
         Where S.AssetRecordId = PC.AssetRecordId  
         AND S.IsActive = 1 AND S.IsDeleted = 0  
         FOR XML PATH('')), 1, 1, '') PartNumber  
    ) A  
    Where ((PC.IsDeleted = @IsDeleted))  
    AND PCI.IsActive = 1 AND PCI.IsDeleted = 0  
    Group By PC.AssetRecordId, A.PartNumber  
    ),  
     
   PartDescCTE AS(  
    Select PC.AssetRecordId, (Case When Count(PCI.AssetRecordId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescriptionType',  
    A.PartDescription from Asset PC WITH (NOLOCK)  
    Left Join AssetCapes PCI WITH (NOLOCK) On PC.AssetRecordId = PCI.AssetRecordId  
    Outer Apply(  
     SELECT   
        STUFF((SELECT ', ' + I.PartDescription  
         FROM AssetCapes S WITH (NOLOCK)  
         Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
         Where S.AssetRecordId = PC.AssetRecordId  
         AND S.IsActive = 1 AND S.IsDeleted = 0  
         FOR XML PATH('')), 1, 1, '') PartDescription  
    ) A  
    Where ((PC.IsDeleted = @IsDeleted))  
    AND PCI.IsActive = 1 AND PCI.IsDeleted = 0  
    Group By PC.AssetRecordId,A.PartDescription  
    ),Results AS(  
    Select M.AssetRecordId, M.IsDepreciable,M.IsAmortizable,  
        M.[Name] as 'Name',M.AssetId,M.AlternateAssetId, M.ManufacturerName,M.IsSerializedNew,M.CalibrationRequiredNew,M.AssetClass,M.DepreciationMethod,M.deprAmort,M.AssetType,M.MasterCompanyId,ISNULL(M.CreatedDate,'')AS CreatedDate,ISNULL(M.UpdatedDate,'')AS UpdatedDate,  
        M.CreatedBy,M.UpdatedBy,M.IsActive as 'IsActive',M.IsDeleted as 'IsDeleted',  
       PT.PartNumber AS 'PN', UPPER(PT.PartNumberType) as 'PartNumber',  
       PD.PartDescription AS 'PNDesc',UPPER(PD.PartDescriptionType)  as 'PartDescription'  ,M.ManufacturerPN,M.AssetInventoryIds
       from Result M   
    Left Join PartCTE PT On M.AssetRecordId = PT.AssetRecordId  
    Left Join PartDescCTE PD on PD.AssetRecordId = M.AssetRecordId),  
   ResultCount AS(SELECT COUNT(AssetRecordId) AS totalItems FROM Results)  
   SELECT * INTO #TempResult from  Results  
   WHERE (  
    (@GlobalFilter <> '' AND (  
      (AssetId like '%' +@GlobalFilter+'%') OR  
	  (ManufacturerPN like '%' +@GlobalFilter+'%') OR  
      (Name like '%' +@GlobalFilter+'%') OR  
      (AlternateAssetId like '%' +@GlobalFilter+'%') OR  
      (ManufacturerName like '%' +@GlobalFilter+'%') OR    
      (IsSerializedNew like '%' +@GlobalFilter+'%') OR  
      (AssetClass like '%' +@GlobalFilter+'%') OR  
      (CalibrationRequiredNew like '%'+@GlobalFilter+'%') OR  
      (AssetType like '%' +@GlobalFilter+'%') OR  
      (AssetClass like '%' +@GlobalFilter+'%') OR  
      (deprAmort like '%' +@GlobalFilter+'%') OR  
      (UpdatedBy like '%' +@GlobalFilter+'%') OR  
      (PartNumber like '%' +@GlobalFilter+'%') OR  
      (PartDescription like '%' +@GlobalFilter+'%')  
      ))  
     OR     
     (@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND  
      (IsNull(@Name,'') ='' OR Name like '%' + @Name+'%') AND  
	  (IsNull(@ManufacturerPN,'') ='' OR ManufacturerPN like '%' + @ManufacturerPN+'%') AND 
      (IsNull(@AlternateAssetId,'') ='' OR AlternateAssetId like '%' + @AlternateAssetId+'%') AND  
      (IsNull(@ManufacturerName,'') ='' OR ManufacturerName like '%' + @ManufacturerName+'%') AND  
      (IsNull(@IsSerializedNew,'') ='' OR IsSerializedNew like '%' + @IsSerializedNew+'%') AND  
      (IsNull(@CalibrationRequiredNew,'') ='' OR CalibrationRequiredNew like '%' + @CalibrationRequiredNew+'%') AND  
      (IsNull(@AssetStatus,'') ='' OR AssetClass like '%' + @AssetStatus+'%') AND  
      (IsNull(@AssetType,'') ='' OR AssetType like '%' + @AssetType+'%') AND  
      (IsNull(@deprAmort,'') ='' OR deprAmort like '%' + @deprAmort+'%') AND  
                        (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
      (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and  
      (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
      (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND  
      (IsNull(@Partnumber,'') ='' OR PartNumber like '%' + @Partnumber+'%') AND  
      (IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%')   
      ))  
        
   Select @Count = COUNT(AssetRecordId) from #TempResult     
  
   SELECT *, @Count As NumberOfItems FROM #TempResult  
   ORDER BY       
   CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='NAME')  THEN Name END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='ALTERNATEASSETID')  THEN AlternateAssetId END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='manufacturerName')  THEN ManufacturerName END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='ISSERIALZEDNEW')  THEN IsSerializedNew END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='CALIBRATIONREQUIREDNEW')  THEN CalibrationRequiredNew END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='ASSETCLASS')  THEN AssetClass END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='deprAmort')  THEN deprAmort END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,  
   CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC, 
   CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerPN')  THEN ManufacturerPN END ASC, 
  
   CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='NAME')  THEN Name END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='ALTERNATEASSETID')  THEN AlternateAssetId END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturerName')  THEN ManufacturerName END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='ISSERIALZEDNEW')  THEN IsSerializedNew END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='deprAmort')  THEN deprAmort END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='CALIBRATIONREQUIREDNEW')  THEN CalibrationRequiredNew END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETCLASS')  THEN AssetClass END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END Desc,  
   CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END Desc ,
   CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerPN')  THEN ManufacturerPN END Desc 
  
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
              , @AdhocComments     VARCHAR(150)    = 'GetAssetPNViewList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''',   
                @Parameter2 = ' + ISNULL(@PageSize,'') + ',   
                @Parameter3 = ' + ISNULL(@SortColumn,'') + ',   
                @Parameter4 = ' + ISNULL(@SortOrder,'') + ',   
                @Parameter5 = ' + ISNULL(@StatusID,'') + ',   
                @Parameter6 = ' + ISNULL(@GlobalFilter,'') + ',   
                @Parameter7 = ' + ISNULL(@AssetId,'') + ',   
                @Parameter8 = ' + ISNULL(@Name,'') + ',   
                @Parameter9 = ' + ISNULL(@AlternateAssetId,'') + ',   
                @Parameter10 = ' + ISNULL(@ManufacturerName,'') + ',   
                @Parameter11 = ' + ISNULL(@IsSerializedNew,'') + ',   
                @Parameter12 = ' + ISNULL(@CalibrationRequiredNew,'') + ',   
                @Parameter13 = ' + ISNULL(@AssetStatus,'') + ',   
                @Parameter14 = ' + ISNULL(@AssetType,'') + ',  
                @Parameter15 = ' + ISNULL(@CompanyName,'') + ',   
                @Parameter16 = ' + ISNULL(@BuName,'') + ',   
                @Parameter17 = ' + ISNULL(@DivName,'') + ',   
                @Parameter18 = ' + ISNULL(@DeptName,'') + ',   
                @Parameter19 = ' + ISNULL(@deprAmort,'') + ',  
                @Parameter20 = ' + ISNULL(@CreatedDate,'') + ',   
                @Parameter21 = ' + ISNULL(@UpdatedDate,'') + ',   
                @Parameter22 = ' + ISNULL(@CreatedBy,'') + ',   
                @Parameter23 = ' + ISNULL(@UpdatedBy,'') + ',   
                @Parameter24 = ' + ISNULL(@IsDeleted,'') + ',   
                @Parameter25 = ' + ISNULL(@MasterCompanyId ,'') +''  
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