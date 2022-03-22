
/*************************************************************           
 ** File:   [GetAuditDataByAssetList]           
 ** Author:   Subhash Saliya
 ** Description: Get Data for Get Audit DataBy AssetList 
 ** Purpose:         
 ** Date:   16-March-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/16/2021   Subhash Saliya Created
	     
 EXECUTE [GetAuditDataByAssetList] 11
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetAuditDataByAssetList]
	@Id bigint = null
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN  
			Select	
				asm.AssetRecordId as AssetRecordId,							
				asm.IsDepreciable AS IsDepreciable,
				asm.IsAmortizable AS IsAmortizable,
				asm.Name AS Name,
				asm.AssetId AS AssetId,
				(select top 1 AssetId from Asset where AssetRecordId=asm.AlternateAssetRecordId) AS AlternateAssetId,
				maf.Name AS ManufacturerName,
				case when asm.IsSerialized = 1 then 'Yes'else 'No' end  as IsSerializedNew,
				case when ascal.CalibrationRequired = 1 then 'Yes'else 'No' end  as CalibrationRequiredNew,
				case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetClass,
				isnull((case when isnull(asm.IsTangible,0) = 1 and isnull(asm.IsDepreciable,0)=1 then 'Yes' when  isnull(asm.IsTangible,0) = 0 and isnull(asm.IsAmortizable,0)=1  then  'Yes'  else 'No'  end),'No') as deprAmort,
					AssetType= case when isnull(asty.AssetAttributeTypeName,'') !='' then asty.AssetAttributeTypeName else isnull(asti.AssetIntangibleName,'') end, --case  when (select top 1 AssetIntangibleName from AssetIntangibleType asp where asp.AssetIntangibleTypeId = asm.AssetIntangibleTypeId),
				CASE WHEN level4.Code + level4.Name IS NOT NULL AND 
                    level3.Code + level3.Name IS NOT NULL AND level2.Code IS NOT NULL AND level1.Code + level1.Name IS NOT NULL THEN level1.Code + level1.Name WHEN level4.Code + level4.Name IS NOT NULL AND 
                    level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.Name IS NOT NULL THEN level2.Code + level2.Name WHEN level4.Code + level4.Name IS NOT NULL AND 
                    level3.Code + level3.Name IS NOT NULL THEN level3.Code + level3.Name WHEN level4.Code + level4.Name IS NOT NULL THEN level4.Code + level4.Name ELSE '' END AS CompanyName, 
                         
					CASE WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.name IS NOT NULL AND level1.Code IS NOT NULL 
                    THEN level2.Code + level2.Name WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.Name IS NOT NULL 
                    THEN level3.Code + level3.Name WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.name IS NOT NULL THEN level4.Code + level4.Name ELSE '' END AS BuName, 

                    CASE WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code IS NOT NULL AND level2.Code + level2.Name IS NOT NULL AND level1.Code + level1.Name IS NOT NULL 
                    THEN level3.Code + level3.Name WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.Name IS NOT NULL 
                    THEN level4.Code + level4.Name ELSE '' END AS DivName, 
						 
					CASE WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.Name IS NOT NULL AND 
                    level1.Code + level1.Name IS NOT NULL THEN level4.Code + level4.Name ELSE '' END AS DeptName,
				asm.MasterCompanyId AS MasterCompanyId,
				asm.CreatedDate AS CreatedDate,
				asm.UpdatedDate AS UpdatedDate,
				asm.CreatedBy AS CreatedBy,
				asm.UpdatedBy AS UpdatedBy ,
				asm.IsActive AS IsActive,
				asm.IsDeleted AS IsDeleted
			FROM dbo.AssetAudit asm WITH(NOLOCK)
			left join dbo.AssetCalibration   As ascal  WITH(NOLOCK) on asm.AssetRecordId = ascal.AssetRecordId
			left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
			left join dbo.AssetIntangibleType  As astI WITH(NOLOCK) on asm.AssetIntangibleTypeId = astI.AssetIntangibleTypeId
			left join dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId
			inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
			LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
			LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
			LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId

			where asm.AssetRecordId = @Id
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetAuditDataByAssetList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@Id, '') + ''
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