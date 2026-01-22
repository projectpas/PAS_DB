CREATE PROCEDURE [dbo].[GetCalibarationMgmtAuditList]
	@CalibrationId bigint = 0
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN  
			Select	
				isnull(CM.CalibrationId, 0) AS CalibrationId, 
				asm.Assetid AS AssetId,
				asm.Name AS AssetName,
				AltAssetId=(SELECT AssetId FROM dbo.Asset WITH(NOLOCK) WHERE AssetRecordId=asm.AlternateAssetRecordId) ,
				--asm.AlternateAssetRecordId AS AltAssetId,
				asm.AssetRecordId AS AssetRecordId,
				AsI.SerialNo AS SerialNum,
				'Asset' AS Itemtype,
				case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
				AssetClass = asty.AssetAttributeTypeName,
				asm.AssetAcquisitionTypeId AS AcquisitionTypeId,
				astaq.Name AS AcquisitionType,
				--Asl.Name AS Locations,
				Locations=st.Name,
				asm.ControlNumber As ControlName,
				UM.Description as UOM,
				CM.CalibrationDate As LastCalibrationDate,		
				CM.NextCalibrationDate AS NextCalibrationDate,
				CM.CreatedBy AS LastCalibrationBy,					
				CM.CalibrationDate AS  CalibrationDate,
				curr.Code AS CurrencyName,
				ast.Name as AssetStatus,
				isnull(asm.UnitCost, 0) as UnitCost,
				CM.Memo,
				'1' as Qty,
				cm.CalibrationDate as Inservicesdate,
				CM.Memo AS lastcalibrationmemo,
				CM.CreatedBy AS lastcheckedinby,
				Null AS lastcheckedindate,
				CM.Memo AS lastcheckedinmemo,
				CM.CreatedBy AS lastcheckedoutby,
				Null  AS lastcheckedoutdate,	
				CM.Memo AS lastcheckedoutmemo,	
				--'Calibration' as CertifyType,
				cm.CertifyType,
				asm.MasterCompanyId AS MasterCompanyId,
				asm.CreatedDate AS CreatedDate,
				asm.UpdatedDate AS UpdatedDate,
				asm.CreatedBy AS CreatedBy,
				asm.UpdatedBy AS UpdatedBy ,
				asm.IsActive AS IsActive,
				asm.IsDeleted AS IsDeleted
			FROM dbo.CalibrationManagmentAudit CM WITH(NOLOCK)
			left join dbo.Asset As asm WITH(NOLOCK) on asm.AssetRecordId=cm.AssetRecordId
			left join dbo.AssetInventory As AsI  WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId and asi.AssetInventoryId=cm.AssetInventoryId
			LEFT JOIN dbo.Site as st WITH(NOLOCK) on st.SiteId=asm.SiteId
			--left join dbo.AssetLocation As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
			left join dbo.AssetCalibration As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
			left join dbo.UnitOfMeasure As UM WITH(NOLOCK) on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
			left join dbo.Currency As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
			left join dbo.AssetStatus As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
			left join dbo.AssetAttributeType As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
			left join dbo.AssetAcquisitionType As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
			--INNER JOIN dbo.ManagementStructure level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
			--LEFT JOIN dbo.ManagementStructure level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
			--LEFT JOIN dbo.ManagementStructure level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
			--LEFT JOIN dbo.ManagementStructure level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
			where  cm.AssetInventoryId = @CalibrationId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetCalibarationMgmtAuditList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CalibrationId, '') + ''
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