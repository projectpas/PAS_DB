CREATE PROCEDURE [dbo].[GetCalibarationMgmtList]
	-- Add the parameters for the stored procedure here	
	@PageSize int,
    @PageNumber int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@GlobalFilter varchar(50) = '',
	@AssetId varchar(50) = null,
	@AssetName varchar(50)=null,
	@AltAssetId varchar(50)=null,
	@AltAssetName varchar(50)=null,
	@SerialNum varchar(50)=null,
    @Location varchar(50)=null,
    @ControlName varchar(50)=null,
    @LastCalibrationDate datetime=null,
    @NextCalibrationDate datetime=null,    
	@LastCalibrationBy varchar(50)=null,
	@AssetType varchar(50)=null,
	@CurrencyName varchar(50)=null,
	@Certifytype varchar(50)=null,
	@UOM varchar(50)=null,
	@Qty int=null,
	@UpdatedCost decimal(18,2)=null,
	@Inservicedate datetime=null,
	@AssetStatus varchar(50)=null,
	@Itemtype varchar(50)=null,
	@CompanyName varchar(50)=null,
	@BuName varchar(50)=null,
	@DivName varchar(50)=null,
	@DeptName varchar(50)=null,
	@lastcalibrationmemo varchar(50)=null,
	@lastcheckedinby varchar(50)=null,
	@lastcheckedindate datetime=null,
	@lastcheckedinmemo varchar(50)=null,
	@lastcheckedoutby varchar(50)=null,
	@lastcheckedoutdate datetime=null,
	@lastcheckedoutmemo varchar(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,
	@Status varchar(50)= null,
	@MasterCompanyId varchar(200)=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @RecordFrom int;
		Declare @IsActive bit=1
		Declare @Count Int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted is null
		Begin
			Set @IsDeleted=0
		End
		
		IF @SortColumn is null
		Begin
			Set @SortColumn=Upper('CreatedDate')
		End 
		Else
		Begin 
			Set @SortColumn=Upper(@SortColumn)
		End

		set @IsActive = 1

		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN
				declare @isStatusActive bit = 1;
				set @isStatusActive = (CASE WHEN @Status ='InActive' then 0 else 1 end)
					IF((@Certifytype is null or lower(@Certifytype) ='') and @Status is not null)
					BEGIN	
						print 'Status 1'
							declare @isActiveFilter bit = (CASE when @Status = 'InActive' then 0 else 1 end)
									;With Result AS(
								Select	
											CalibrationId  = (select top 1 isnull(CalibrationId, 0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											(select top 1 AssetId from Asset where AssetRecordId = asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName, 
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, isnull(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, isnull(Assc.CalibrationFrequencyMonths,0),getdate())),				
											LastCalibrationBy = (select top  1 CreatedBy from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),					
											CalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											isnull(asm.UnitCost,0) as UnitCost,
											Memo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,	
											(CASE 
												  WHEN Assc.CalibrationRequired = 1 THEN 'Calibration'
												  WHEN Assc.CertificationRequired =1  THEN  'Certification'
												  WHEN Assc.InspectionRequired =1  THEN  'Inspection'
												  WHEN Assc.VerificationRequired =1  THEN  'Verification' ELSE 'Calibration' end)as CertifyType,
											--'Calibration' as CertifyType,

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
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											isnull((select top 1 IsVendororEmployee from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),'vendor') as IsVendororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										left join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										left join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										left join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = @IsDeleted)  AND (ISNULL(clm.IsActive,1) = @isStatusActive )  and  asm.MasterCompanyId=@MasterCompanyId )
								), ResultCount AS(Select COUNT(CalibrationId) AS totalItems FROM Result)
								Select * INTO #TempResult5 from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(AssetClass like '%' +@GlobalFilter+'%') OR
											(LastCalibrationDate like '%'+@GlobalFilter+'%') OR
											(AcquisitionType like '%' +@GlobalFilter+'%') OR
											(Locations like '%' +@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(UOM like '%' +@GlobalFilter+'%') OR
											(NextCalibrationDate like '%' +@GlobalFilter+'%') OR
											(LastCalibrationBy like '%' +@GlobalFilter+'%') OR
											(CalibrationDate like '%'+@GlobalFilter+'%') OR
											(CurrencyName like '%' +@GlobalFilter+'%') OR
											(AssetStatus like '%' +@GlobalFilter+'%') OR
											(UnitCost like '%' +@GlobalFilter+'%') OR
											(Memo like '%' +@GlobalFilter+'%') OR
											(Qty like '%' +@GlobalFilter+'%') OR		
											(Inservicesdate like '%' +@GlobalFilter+'%') OR
											(lastcalibrationmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedinby like '%'+@GlobalFilter+'%') OR
											(lastcheckedindate like '%' +@GlobalFilter+'%') OR
											(lastcheckedinmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutby like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutdate like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutmemo like '%' +@GlobalFilter+'%') OR		
											(CertifyType like '%' +@GlobalFilter+'%') OR
											(CompanyName like '%' +@GlobalFilter+'%') OR
											(BuName like '%'+@GlobalFilter+'%') OR
											(DivName like '%' +@GlobalFilter+'%') OR
											(DeptName like '%' +@GlobalFilter+'%') OR
											(UpdatedBy like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(IsNull(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(IsNull(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(IsNull(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(IsNull(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(IsNull(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(IsNull(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(IsNull(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(IsNull(@Qty,'') = '' OR  cast(Qty as varchar(10))  like '%' + cast(@Qty as varchar(10))+'%') AND
											(IsNull(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(IsNull(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(IsNull(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(IsNull(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(IsNull(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(IsNull(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(IsNull(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(IsNull(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(IsNull(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(IsNull(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								Select @Count = COUNT(CalibrationId) from #TempResult5			

								SELECT *, @Count As NumberOfItems FROM #TempResult5
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LOCATION')  THEN Locations END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UOM')  THEN UOM END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='QTY')  THEN Qty END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,

								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LOCATION')  THEN Locations END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UOM')  THEN UOM END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='QTY')  THEN Qty END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY
					END
					ELSE
					BEGIN
						if(lower(@Certifytype) =lower('calibration'))			
							begin
										print 'Calibration'
								;With Result AS(
								Select	
											CalibrationId  = (select top 1 isnull(CalibrationId, 0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											(select top 1 AssetId from Asset where AssetRecordId = asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName, 
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, isnull(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, isnull(Assc.CalibrationFrequencyMonths,0),getdate())),				
											LastCalibrationBy = (select top  1 CreatedBy from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),					
											CalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											isnull(asm.UnitCost,0) as UnitCost,
											Memo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,	
											'Calibration' as CertifyType,

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
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											isnull((select top 1 IsVendororEmployee from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),'vendor') as IsVendororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										left join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										left join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										left join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = @IsDeleted) AND (ISNULL(clm.IsActive,1) = @isStatusActive ) AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.CalibrationRequired =1))
								), ResultCount AS(Select COUNT(CalibrationId) AS totalItems FROM Result)
								Select * INTO #TempResult from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(AssetClass like '%' +@GlobalFilter+'%') OR
											(LastCalibrationDate like '%'+@GlobalFilter+'%') OR
											(AcquisitionType like '%' +@GlobalFilter+'%') OR
											(Locations like '%' +@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(UOM like '%' +@GlobalFilter+'%') OR
											(NextCalibrationDate like '%' +@GlobalFilter+'%') OR
											(LastCalibrationBy like '%' +@GlobalFilter+'%') OR
											(CalibrationDate like '%'+@GlobalFilter+'%') OR
											(CurrencyName like '%' +@GlobalFilter+'%') OR
											(AssetStatus like '%' +@GlobalFilter+'%') OR
											(UnitCost like '%' +@GlobalFilter+'%') OR
											(Memo like '%' +@GlobalFilter+'%') OR
											(Qty like '%' +@GlobalFilter+'%') OR		
											(Inservicesdate like '%' +@GlobalFilter+'%') OR
											(lastcalibrationmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedinby like '%'+@GlobalFilter+'%') OR
											(lastcheckedindate like '%' +@GlobalFilter+'%') OR
											(lastcheckedinmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutby like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutdate like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutmemo like '%' +@GlobalFilter+'%') OR		
											(CertifyType like '%' +@GlobalFilter+'%') OR
											(CompanyName like '%' +@GlobalFilter+'%') OR
											(BuName like '%'+@GlobalFilter+'%') OR
											(DivName like '%' +@GlobalFilter+'%') OR
											(DeptName like '%' +@GlobalFilter+'%') OR
											(UpdatedBy like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(IsNull(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(IsNull(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(IsNull(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(IsNull(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(IsNull(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(IsNull(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(IsNull(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(IsNull(@Qty,'') = '' OR  cast(Qty as varchar(10))  like '%' + cast(@Qty as varchar(10))+'%') AND
											(IsNull(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(IsNull(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(IsNull(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(IsNull(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(IsNull(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(IsNull(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(IsNull(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(IsNull(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(IsNull(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(IsNull(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								Select @Count = COUNT(CalibrationId) from #TempResult			

								SELECT *, @Count As NumberOfItems FROM #TempResult
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LOCATION')  THEN Locations END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UOM')  THEN UOM END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='QTY')  THEN Qty END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,

								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LOCATION')  THEN Locations END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UOM')  THEN UOM END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='QTY')  THEN Qty END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY

							end

							else if(lower(@Certifytype) =lower('certification'))
							begin

								;With Result AS(
								Select	
											CalibrationId  = (select top 1 isnull(CalibrationId,0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											(select top 1 AssetId from Asset where AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName,
												ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, isnull(Assc.CertificationFrequencyDays, 0), DATEADD(MONTH,isnull(Assc.CertificationFrequencyMonths,0),getdate())),
											LastCalibrationBy = (select top 1 CreatedBy from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),					
											CalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											isnull(asm.UnitCost,0) as UnitCost,
											Memo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,
											'Certification' as CertifyType,
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
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
					    						isnull((select top 1 IsVendororEmployee from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),'vendor') as IsVendororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										left join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										left join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										left join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = @IsDeleted) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND  (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.CertificationRequired =1))
								), ResultCount AS(Select COUNT(CalibrationId) AS totalItems FROM Result)
							Select * INTO #TempResult1 from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(AssetClass like '%' +@GlobalFilter+'%') OR
											(LastCalibrationDate like '%'+@GlobalFilter+'%') OR
											(AcquisitionType like '%' +@GlobalFilter+'%') OR
											(Locations like '%' +@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(UOM like '%' +@GlobalFilter+'%') OR
											(NextCalibrationDate like '%' +@GlobalFilter+'%') OR
											(LastCalibrationBy like '%' +@GlobalFilter+'%') OR
											(CalibrationDate like '%'+@GlobalFilter+'%') OR
											(CurrencyName like '%' +@GlobalFilter+'%') OR
											(AssetStatus like '%' +@GlobalFilter+'%') OR
											(UnitCost like '%' +@GlobalFilter+'%') OR
											(Memo like '%' +@GlobalFilter+'%') OR
											(Qty like '%' +@GlobalFilter+'%') OR		
											(Inservicesdate like '%' +@GlobalFilter+'%') OR
											(lastcalibrationmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedinby like '%'+@GlobalFilter+'%') OR
											(lastcheckedindate like '%' +@GlobalFilter+'%') OR
											(lastcheckedinmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutby like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutdate like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutmemo like '%' +@GlobalFilter+'%') OR		
											(CertifyType like '%' +@GlobalFilter+'%') OR
											(CompanyName like '%' +@GlobalFilter+'%') OR
											(BuName like '%'+@GlobalFilter+'%') OR
											(DivName like '%' +@GlobalFilter+'%') OR
											(DeptName like '%' +@GlobalFilter+'%') OR
											(UpdatedBy like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(IsNull(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(IsNull(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(IsNull(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(IsNull(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(IsNull(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(IsNull(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(IsNull(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(IsNull(@Qty,'') = '' OR  cast(Qty as varchar(10))  like '%' + cast(@Qty as varchar(10))+'%') AND
											(IsNull(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(IsNull(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(IsNull(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(IsNull(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(IsNull(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(IsNull(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(IsNull(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(IsNull(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(IsNull(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(IsNull(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								Select @Count = COUNT(CalibrationId) from #TempResult1			

								SELECT *, @Count As NumberOfItems FROM #TempResult1
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LOCATION')  THEN Locations END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UOM')  THEN UOM END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='QTY')  THEN Qty END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LOCATION')  THEN Locations END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UOM')  THEN UOM END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='QTY')  THEN Qty END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY
							end

							else if(lower(@Certifytype) = lower('inspection'))
							begin
								;With Result AS(
								Select	
											CalibrationId  = (select top 1 isnull(CalibrationId,0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
																	(select top 1 AssetId from Asset where AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName, 
												ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, isnull(Assc.InspectionFrequencyDays,0), DATEADD(MONTH,isnull(Assc.InspectionFrequencyMonths,0),getdate())),
											LastCalibrationBy = (select top 1 CreatedBy from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),					
											CalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											isnull(asm.UnitCost,0) as UnitCost,
											Memo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,		
											'Inspection' as CertifyType,

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
										ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											isnull((select top 1 IsVendororEmployee from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),'vendor') as IsVendororEmployee
		   							FROM dbo.Asset asm WITH(NOLOCK)
										left join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										left join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										left join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = @IsDeleted) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.InspectionRequired =1))
								), ResultCount AS(Select COUNT(CalibrationId) AS totalItems FROM Result)
								Select * INTO #TempResult2 from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(AssetClass like '%' +@GlobalFilter+'%') OR
											(LastCalibrationDate like '%'+@GlobalFilter+'%') OR
											(AcquisitionType like '%' +@GlobalFilter+'%') OR
											(Locations like '%' +@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(UOM like '%' +@GlobalFilter+'%') OR
											(NextCalibrationDate like '%' +@GlobalFilter+'%') OR
											(LastCalibrationBy like '%' +@GlobalFilter+'%') OR
											(CalibrationDate like '%'+@GlobalFilter+'%') OR
											(CurrencyName like '%' +@GlobalFilter+'%') OR
											(AssetStatus like '%' +@GlobalFilter+'%') OR
											(UnitCost like '%' +@GlobalFilter+'%') OR
											(Memo like '%' +@GlobalFilter+'%') OR
											(Qty like '%' +@GlobalFilter+'%') OR		
											(Inservicesdate like '%' +@GlobalFilter+'%') OR
											(lastcalibrationmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedinby like '%'+@GlobalFilter+'%') OR
											(lastcheckedindate like '%' +@GlobalFilter+'%') OR
											(lastcheckedinmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutby like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutdate like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutmemo like '%' +@GlobalFilter+'%') OR		
											(CertifyType like '%' +@GlobalFilter+'%') OR
											(CompanyName like '%' +@GlobalFilter+'%') OR
											(BuName like '%'+@GlobalFilter+'%') OR
											(DivName like '%' +@GlobalFilter+'%') OR
											(DeptName like '%' +@GlobalFilter+'%') OR
											(UpdatedBy like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(IsNull(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(IsNull(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(IsNull(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(IsNull(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(IsNull(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(IsNull(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(IsNull(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(IsNull(@Qty,'') = '' OR  cast(Qty as varchar(10))  like '%' + cast(@Qty as varchar(10))+'%') AND
											(IsNull(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(IsNull(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(IsNull(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(IsNull(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(IsNull(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(IsNull(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(IsNull(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(IsNull(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(IsNull(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(IsNull(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								Select @Count = COUNT(CalibrationId) from #TempResult2			

								SELECT *, @Count As NumberOfItems FROM #TempResult2
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LOCATION')  THEN Locations END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UOM')  THEN UOM END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='QTY')  THEN Qty END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LOCATION')  THEN Locations END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UOM')  THEN UOM END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='QTY')  THEN Qty END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY

							end

							else if(lower(@Certifytype) =lower('verification'))
							begin

								;With Result AS(
								Select	
											  CalibrationId  = (select top 1 isnull(CalibrationId,0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											(select top 1 AssetId from Asset where AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName, --case  when (select top 1 AssetIntangibleName from AssetIntangibleType asp where asp.AssetIntangibleTypeId = asm.AssetIntangibleTypeId),
												ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, isnull(Assc.VerificationFrequencyDays,0), DATEADD(MONTH,isnull(Assc.VerificationFrequencyMonths,0),getdate())),
											LastCalibrationBy = (select top 1 CreatedBy from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),					
											CalibrationDate  = (select top 1 CalibrationDate from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											isnull(asm.UnitCost,0) as UnitCost,
											Memo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,	
											'Verification' as CertifyType,

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
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											isnull((select top 1 IsVendororEmployee from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),'vendor') as IsVendororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										left join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										left join dbo.CalibrationManagment   As CM  WITH(NOLOCK) on asm.AssetRecordId=cm.AssetRecordId
										left join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										left join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = @IsDeleted) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.VerificationRequired =1))
								), ResultCount AS(Select COUNT(CalibrationId) AS totalItems FROM Result)
								Select * INTO #TempResult3 from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(AssetClass like '%' +@GlobalFilter+'%') OR
											(LastCalibrationDate like '%'+@GlobalFilter+'%') OR
											(AcquisitionType like '%' +@GlobalFilter+'%') OR
											(Locations like '%' +@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(UOM like '%' +@GlobalFilter+'%') OR
											(NextCalibrationDate like '%' +@GlobalFilter+'%') OR
											(LastCalibrationBy like '%' +@GlobalFilter+'%') OR
											(CalibrationDate like '%'+@GlobalFilter+'%') OR
											(CurrencyName like '%' +@GlobalFilter+'%') OR
											(AssetStatus like '%' +@GlobalFilter+'%') OR
											(UnitCost like '%' +@GlobalFilter+'%') OR
											(Memo like '%' +@GlobalFilter+'%') OR
											(Qty like '%' +@GlobalFilter+'%') OR		
											(Inservicesdate like '%' +@GlobalFilter+'%') OR
											(lastcalibrationmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedinby like '%'+@GlobalFilter+'%') OR
											(lastcheckedindate like '%' +@GlobalFilter+'%') OR
											(lastcheckedinmemo like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutby like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutdate like '%' +@GlobalFilter+'%') OR
											(lastcheckedoutmemo like '%' +@GlobalFilter+'%') OR		
											(CertifyType like '%' +@GlobalFilter+'%') OR
											(CompanyName like '%' +@GlobalFilter+'%') OR
											(BuName like '%'+@GlobalFilter+'%') OR
											(DivName like '%' +@GlobalFilter+'%') OR
											(DeptName like '%' +@GlobalFilter+'%') OR
											(UpdatedBy like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(IsNull(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(IsNull(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(IsNull(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(IsNull(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(IsNull(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(IsNull(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(IsNull(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(IsNull(@Qty,'') = '' OR  cast(Qty as varchar(10))  like '%' + cast(@Qty as varchar(10))+'%') AND
											(IsNull(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(IsNull(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(IsNull(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(IsNull(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(IsNull(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(IsNull(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(IsNull(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(IsNull(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(IsNull(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(IsNull(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								Select @Count = COUNT(CalibrationId) from #TempResult3			

								SELECT *, @Count As NumberOfItems FROM #TempResult3
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LOCATION')  THEN Locations END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UOM')  THEN UOM END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='QTY')  THEN Qty END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LOCATION')  THEN Locations END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONDATE')  THEN LastCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalibrationDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='INSERVICEDATE')  THEN Inservicesdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINDATE')  THEN lastcheckedindate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTDATE')  THEN lastcheckedoutdate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UOM')  THEN UOM END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='QTY')  THEN Qty END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDCOST')  THEN UnitCost END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCALIBRATIONMEMO')  THEN lastcalibrationmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINBY')  THEN lastcheckedinby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDINMEMO')  THEN lastcheckedinmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTBY')  THEN lastcheckedoutby END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='LASTCHECKEDOUTMEMO')  THEN lastcheckedoutmemo END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY
							END
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
              , @AdhocComments     VARCHAR(150)    = 'GetRecevingCustomerList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ', 
													   @Parameter6 = ' + ISNULL(@AssetId,'') + ', 
													   @Parameter7 = ' + ISNULL(@AssetName,'') + ', 
													   @Parameter8 = ' + ISNULL(@AltAssetId,'') + ', 
													   @Parameter9 = ' + ISNULL(@AltAssetName,'') + ', 
													   @Parameter10 = ' + ISNULL(@SerialNum,'') + ', 
													   @Parameter11 = ' + ISNULL(@Location,'') + ', 
													   @Parameter12 = ' + ISNULL(@ControlName,'') + ', 
													   @Parameter13 = ' + ISNULL(@LastCalibrationDate,'') + ', 
													   @Parameter14 = ' + ISNULL(@NextCalibrationDate,'') + ',
													   @Parameter15 = ' + ISNULL(@LastCalibrationBy,'') + ', 
													   @Parameter16 = ' + ISNULL(@AssetType,'') + ', 
													   @Parameter17 = ' + ISNULL(@CurrencyName,'') + ', 
													   @Parameter18 = ' + ISNULL(@Certifytype,'') + ', 
													   @Parameter19 = ' + ISNULL(@UOM,'') + ',
													   @Parameter20 = ' + ISNULL(@Qty,'') + ', 
													   @Parameter21 = ' + ISNULL(@UpdatedCost,'') + ', 
													   @Parameter22 = ' + ISNULL(@Inservicedate,'') + ', 
													   @Parameter23 = ' + ISNULL(@AssetStatus,'') + ', 
													   @Parameter24 = ' + ISNULL(@Itemtype,'') + ', 
													   @Parameter25 = ' + ISNULL(@CompanyName,'') + ', 
													   @Parameter26 = ' + ISNULL(@BuName,'') + ', 
													   @Parameter27 = ' + ISNULL(@DivName,'') + ', 
													   @Parameter28 = ' + ISNULL(@DeptName,'') + ', 
													   @Parameter30 = ' + ISNULL(@lastcalibrationmemo,'') + ', 
													   @Parameter31 = ' + ISNULL(@lastcheckedinby,'') + ', 
													   @Parameter32 = ' + ISNULL(@lastcheckedindate,'') + ', 
													   @Parameter33 = ' + ISNULL(@lastcheckedinmemo,'') + ',
													   @Parameter34 = ' + ISNULL(@lastcheckedoutby,'') + ', 
													   @Parameter35 = ' + ISNULL(@lastcheckedoutdate,'') + ', 
													   @Parameter36 = ' + ISNULL(@lastcheckedoutmemo,'') + ', 
													   @Parameter37 = ' + ISNULL(@CreatedDate,'') + ', 
													   @Parameter38 = ' + ISNULL(@UpdatedDate,'') + ',
													   @Parameter39 = ' + ISNULL(@CreatedBy,'') + ', 
													   @Parameter40 = ' + ISNULL(@UpdatedBy,'') + ', 
													   @Parameter41 = ' + ISNULL(@IsDeleted,'') + ', 
													   @Parameter42 = ' + ISNULL(@MasterCompanyId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);

        END CATCH  
END