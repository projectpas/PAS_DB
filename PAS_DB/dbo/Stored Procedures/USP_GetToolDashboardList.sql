CREATE PROCEDURE [dbo].[USP_GetToolDashboardList]
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
    @ToolId varchar(50)=null,
    @PartNumber varchar(50)=null,
	@Name		varchar(50)=null,
	@Manufacturer		varchar(50)=null,
	@AltIdNum		varchar(50)=null,
    @LastCalibrationDate datetime=null,
    @NextCalibrationDate datetime=null,    
	@LastCalibrationBy varchar(50)=null,
	@StklineNum varchar(50)=null,
	@Calibrated varchar(50)=null,
	@Certifytype varchar(50)=null,
	@CalCertNum varchar(50)=null,	
	@DayTillNextCal varchar(50)=null,
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
				set @isStatusActive = 1;
					IF((@Certifytype is null or lower(@Certifytype) ='') and @Status is not null)
					BEGIN	
						print 'Status 1'
							declare @isActiveFilter bit = 1;
									;With Result AS(
								Select 
											CalibrationId  = (select top 1 isnull(CalibrationId, 0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											--Asi.CalibrationRequired = 1 and
											CASE WHEN ( ((select top 1 isnull(CalibrationId, 0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc)>0) ) THEN 'Yes'ELSE 'No' END AS Calibrated,
											(select top 1 AssetId from Asset where AssetRecordId = asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName,
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											UM.Description as UOM,
											LastCalDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 CreatedBy FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),
											DATEDIFF(day, isnull((SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),getDate()), DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											asm.ControlNumber As ControlName,
											--clm.LastCalibrationDate as LastCalDate,							
											--clm.NextCalibrationDate as NextCalDate,
											--LastCalibrationBy as LastCalBy,											
											--DATEDIFF(day, isnull(clm.LastCalibrationDate,getDate()), clm.NextCalibrationDate) AS DayTillNextCal,
											--clm.CalibrationDate,
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
										left join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId	
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = 0)  AND (ISNULL(clm.IsActive,1) = @isStatusActive )  and  asm.MasterCompanyId=@MasterCompanyId )
								), ResultCount AS(Select COUNT(AssetId) AS totalItems FROM Result)
								Select * INTO #TempResult5 from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(LastCalDate like '%'+@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(NextCalDate like '%' +@GlobalFilter+'%') OR
											(LastCalBy like '%' +@GlobalFilter+'%') OR												
											(CertifyType like '%' +@GlobalFilter+'%') 
											
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
											(IsNull(@Manufacturer,'') ='' OR Manufacturer like '%' + @Manufacturer+'%') AND
											(IsNull(@StklineNum,'') ='' OR StklineNum like '%' + @StklineNum+'%') AND
											(IsNull(@Calibrated,'') ='' OR Calibrated like '%' + @Calibrated+'%') AND
											(IsNull(@ToolId,'') ='' OR ToolId like '%' + @ToolId+'%') AND
											(IsNull(@DayTillNextCal,'') ='' OR DayTillNextCal like '%' + @DayTillNextCal+'%') AND
											(IsNull(@LastCalibrationBy,'') ='' OR LastCalBy like '%' + @LastCalibrationBy+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalDate as Date)=Cast(@NextCalibrationDate as date))
											
											))
						
								Select @Count = COUNT(AssetId) from #TempResult5			

								SELECT *, @Count As NumberOfItems FROM #TempResult5
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalDate')  THEN LastCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='nextCalDate')  THEN NextCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='toolId')  THEN toolId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='partNumber')  THEN partNumber END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturer')  THEN manufacturer END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='stklineNum')  THEN stklineNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='calibrated')  THEN calibrated END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalBy')  THEN lastCalBy END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END ASC,

								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalDate')  THEN LastCalDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='nextCalDate')  THEN NextCalDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='toolId')  THEN toolId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='partNumber')  THEN partNumber END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturer')  THEN manufacturer END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='stklineNum')  THEN stklineNum END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='calibrated')  THEN calibrated END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalBy')  THEN lastCalBy END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END Desc
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
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											--Asi.CalibrationRequired = 1 and
											CASE WHEN ( ((select top 1 isnull(CalibrationId, 0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc)>0) ) THEN 'Yes'ELSE 'No' END AS Calibrated,
											(select top 1 AssetId from Asset where AssetRecordId = asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 CreatedBy FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),
											DATEDIFF(day, isnull((SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),getDate()), DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											--clm.LastCalibrationDate as LastCalDate,							
											--clm.NextCalibrationDate as NextCalDate,
											--LastCalibrationBy as LastCalBy,	
											--clm.CalibrationDate,
											--DATEDIFF(day, isnull(clm.LastCalibrationDate,getDate()), clm.NextCalibrationDate) AS DayTillNextCal,
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
											asm.IsDeleted AS IsDeleted,
											isnull((select top 1 IsVendororEmployee from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),'vendor') as IsVendororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										left join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										Left join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId	
										Left join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId 
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = 0)  AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.CalibrationRequired =1))
								), ResultCount AS(Select COUNT(AssetId) AS totalItems FROM Result)
								Select * INTO #TempResult from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(LastCalDate like '%'+@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(NextCalDate like '%' +@GlobalFilter+'%') OR
											(LastCalBy like '%' +@GlobalFilter+'%') OR										
											(CertifyType like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@ToolId,'') ='' OR ToolId like '%' + @ToolId+'%') AND
											(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
											(IsNull(@Manufacturer,'') ='' OR Manufacturer like '%' + @Manufacturer+'%') AND
											(IsNull(@StklineNum,'') ='' OR StklineNum like '%' + @StklineNum+'%') AND
											(IsNull(@Calibrated,'') ='' OR Calibrated like '%' + @Calibrated+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@DayTillNextCal,'') ='' OR DayTillNextCal like '%' + @DayTillNextCal+'%') AND
											(IsNull(@LastCalibrationBy,'') ='' OR LastCalBy like '%' + @LastCalibrationBy+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalDate as Date)=Cast(@NextCalibrationDate as date)) 
											))
						
								Select @Count = COUNT(AssetId) from #TempResult			

								SELECT *, @Count As NumberOfItems FROM #TempResult
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalDate')  THEN LastCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='nextCalDate')  THEN NextCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='toolId')  THEN toolId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='partNumber')  THEN partNumber END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturer')  THEN manufacturer END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='stklineNum')  THEN stklineNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='calibrated')  THEN calibrated END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalBy')  THEN lastCalBy END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END ASC,

								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalDate')  THEN LastCalDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='NEXTCALIBRATIONDATE')  THEN NextCalDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='toolId')  THEN toolId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='partNumber')  THEN partNumber END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturer')  THEN manufacturer END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='stklineNum')  THEN stklineNum END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='calibrated')  THEN calibrated END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalBy')  THEN lastCalBy END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END desc
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY

							end

							else if(lower(@Certifytype) =lower('certification'))
							begin

								;With Result AS(
								Select	
											CalibrationId  = (select top 1 isnull(CalibrationId,0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											--CASE WHEN Asi.CalibrationRequired = 1 THEN 'Yes'ELSE 'No' END AS Calibrated,
											--Asi.CertificationRequired = 1 and
											CASE WHEN ( ((select top 1 isnull(CalibrationId, 0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc)>0) ) THEN 'Yes'ELSE 'No' END AS Calibrated,
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
											LastCalDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.CertificationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CertificationFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 CreatedBy FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),
											DATEDIFF(day, isnull((SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),getDate()), DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											--clm.LastCalibrationDate as LastCalDate,							
											--clm.NextCalibrationDate as NextCalDate,
											--LastCalibrationBy as LastCalBy,
											--clm.CalibrationDate,
											--DATEDIFF(day, isnull(clm.LastCalibrationDate,getDate()), clm.NextCalibrationDate) AS DayTillNextCal,
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
										LEFT join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId 
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = 0) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND  (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.CertificationRequired =1))
								), ResultCount AS(Select COUNT(AssetId) AS totalItems FROM Result)
							Select * INTO #TempResult1 from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(LastCalDate like '%'+@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(NextCalDate like '%' +@GlobalFilter+'%') OR
											(LastCalBy like '%' +@GlobalFilter+'%') OR
											(CertifyType like '%' +@GlobalFilter+'%') OR
											(UpdatedBy like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@ToolId,'') ='' OR ToolId like '%' + @ToolId+'%') AND
											(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
											(IsNull(@Manufacturer,'') ='' OR Manufacturer like '%' + @Manufacturer+'%') AND
											(IsNull(@StklineNum,'') ='' OR StklineNum like '%' + @StklineNum+'%') AND
											(IsNull(@Calibrated,'') ='' OR Calibrated like '%' + @Calibrated+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@DayTillNextCal,'') ='' OR DayTillNextCal like '%' + @DayTillNextCal+'%') AND
											(IsNull(@LastCalibrationBy,'') ='' OR LastCalBy like '%' + @LastCalibrationBy+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalDate as Date)=Cast(@NextCalibrationDate as date)) 
											))
						
								Select @Count = COUNT(AssetId) from #TempResult1			

								SELECT *, @Count As NumberOfItems FROM #TempResult1
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalDate')  THEN LastCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='nextCalDate')  THEN NextCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='toolId')  THEN toolId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='partNumber')  THEN partNumber END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturer')  THEN manufacturer END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='stklineNum')  THEN stklineNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='calibrated')  THEN calibrated END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalBy')  THEN lastCalBy END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END ASC,

								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalDate')  THEN LastCalDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='nextCalDate')  THEN NextCalDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='toolId')  THEN toolId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='partNumber')  THEN partNumber END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturer')  THEN manufacturer END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='stklineNum')  THEN stklineNum END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='calibrated')  THEN calibrated END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalBy')  THEN lastCalBy END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END desc
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY
							end

							else if(lower(@Certifytype) = lower('inspection'))
							begin
								;With Result AS(
								Select	
											CalibrationId  = (select top 1 isnull(CalibrationId,0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											--CASE WHEN Asi.CalibrationRequired = 1 THEN 'Yes'ELSE 'No' END AS Calibrated,
											--Asi.InspectionRequired = 1 and
											CASE WHEN ( ((select top 1 isnull(CalibrationId, 0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc)>0) ) THEN 'Yes'ELSE 'No' END AS Calibrated,
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
											LastCalDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.InspectionFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.InspectionFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 CreatedBy FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),
											DATEDIFF(day, isnull((SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),getDate()), DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											--clm.LastCalibrationDate as LastCalDate,							
											--clm.NextCalibrationDate as NextCalDate,
											--LastCalibrationBy as LastCalBy,	
											--clm.CalibrationDate,
											--DATEDIFF(day, isnull(clm.LastCalibrationDate,getDate()), clm.NextCalibrationDate) AS DayTillNextCal,
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
										LEFT join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = 0) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.InspectionRequired =1))
								), ResultCount AS(Select COUNT(AssetId) AS totalItems FROM Result)
								Select * INTO #TempResult2 from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(LastCalDate like '%'+@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(NextCalDate like '%' +@GlobalFilter+'%') OR
											(LastCalBy like '%' +@GlobalFilter+'%') OR
											(CertifyType like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@ToolId,'') ='' OR ToolId like '%' + @ToolId+'%') AND
											(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
											(IsNull(@Manufacturer,'') ='' OR Manufacturer like '%' + @Manufacturer+'%') AND
											(IsNull(@StklineNum,'') ='' OR StklineNum like '%' + @StklineNum+'%') AND
											(IsNull(@Calibrated,'') ='' OR Calibrated like '%' + @Calibrated+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@DayTillNextCal,'') ='' OR DayTillNextCal like '%' + @DayTillNextCal+'%') AND
											(IsNull(@LastCalibrationBy,'') ='' OR LastCalBy like '%' + @LastCalibrationBy+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalDate as Date)=Cast(@NextCalibrationDate as date)) 
											))
						
								Select @Count = COUNT(AssetId) from #TempResult2			

								SELECT *, @Count As NumberOfItems FROM #TempResult2
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalDate')  THEN LastCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='nextCalDate')  THEN NextCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='toolId')  THEN toolId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='partNumber')  THEN partNumber END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturer')  THEN manufacturer END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='stklineNum')  THEN stklineNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='calibrated')  THEN calibrated END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalBy')  THEN lastCalBy END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END ASC,

								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalDate')  THEN LastCalDate END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='nextCalDate')  THEN NextCalDate END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='toolId')  THEN toolId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='partNumber')  THEN partNumber END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturer')  THEN manufacturer END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='stklineNum')  THEN stklineNum END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='calibrated')  THEN calibrated END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalBy')  THEN lastCalBy END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END desc
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY

							end

							else if(lower(@Certifytype) =lower('verification'))
							begin

								;With Result AS(
								Select	
											  CalibrationId  = (select top 1 isnull(CalibrationId,0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											--CASE WHEN Asi.CalibrationRequired = 1 THEN 'Yes'ELSE 'No' END AS Calibrated,
											--Asi.VerificationRequired = 1 and
											CASE WHEN ( ((select top 1 isnull(CalibrationId, 0) from CalibrationManagment where AssetRecordId = asm.AssetRecordId order by  CalibrationId desc)>0) ) THEN 'Yes'ELSE 'No' END AS Calibrated,
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
											LastCalDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.VerificationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.VerificationFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 CreatedBy FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),
											DATEDIFF(day, isnull((SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),getDate()), DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											--clm.LastCalibrationDate as LastCalDate,							
											--clm.NextCalibrationDate as NextCalDate,
											--LastCalibrationBy as LastCalBy,	
											--clm.CalibrationDate,
											--DATEDIFF(day, isnull(clm.LastCalibrationDate,getDate()), clm.NextCalibrationDate) AS DayTillNextCal,
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
										LEFT join dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT join dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId										
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										left join dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId 
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										inner JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level3 WITH(NOLOCK) ON level4.ParentId = level3.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level2 WITH(NOLOCK) ON level3.ParentId = level2.ManagementStructureId
										LEFT JOIN dbo.ManagementStructure  level1 WITH(NOLOCK) ON level2.ParentId = level1.ManagementStructureId
										where ((asm.IsDeleted = 0) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.VerificationRequired =1))
								), ResultCount AS(Select COUNT(AssetId) AS totalItems FROM Result)
								Select * INTO #TempResult3 from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(LastCalDate like '%'+@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(NextCalDate like '%' +@GlobalFilter+'%') OR
											(LastCalBy like '%' +@GlobalFilter+'%') OR
											(CertifyType like '%' +@GlobalFilter+'%') 
											
											))
										OR   
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(IsNull(@ToolId,'') ='' OR ToolId like '%' + @ToolId+'%') AND
											(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND
											(IsNull(@Manufacturer,'') ='' OR Manufacturer like '%' + @Manufacturer+'%') AND
											(IsNull(@StklineNum,'') ='' OR StklineNum like '%' + @StklineNum+'%') AND
											(IsNull(@Calibrated,'') ='' OR Calibrated like '%' + @Calibrated+'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(IsNull(@DayTillNextCal,'') ='' OR DayTillNextCal like '%' + @DayTillNextCal+'%') AND
											(IsNull(@LastCalibrationBy,'') ='' OR LastCalBy like '%' + @LastCalibrationBy+'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalDate as Date)=Cast(@NextCalibrationDate as date))  
											
											))
						
								Select @Count = COUNT(AssetId) from #TempResult3			

								SELECT *, @Count As NumberOfItems FROM #TempResult3
								ORDER BY  			
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN AssetName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ALTASSETID')  THEN AltAssetId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUM')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CONTROLNAME')  THEN ControlName END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ITEMTYPE')  THEN Itemtype END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalDate')  THEN LastCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='nextCalDate')  THEN NextCalDate END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='toolId')  THEN toolId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='partNumber')  THEN partNumber END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturer')  THEN manufacturer END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='stklineNum')  THEN stklineNum END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='calibrated')  THEN calibrated END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='lastCalBy')  THEN lastCalBy END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END ASC,

								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN AssetName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ALTASSETID')  THEN AltAssetId END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUM')  THEN SerialNum END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CONTROLNAME')  THEN ControlName END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ITEMTYPE')  THEN Itemtype END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalDate')  THEN LastCalDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='nextCalDate')  THEN NextCalDate END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='CERTIFYTYPE')  THEN CertifyType END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='toolId')  THEN toolId END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='partNumber')  THEN partNumber END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturer')  THEN manufacturer END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='stklineNum')  THEN stklineNum END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='calibrated')  THEN calibrated END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='lastCalBy')  THEN lastCalBy END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END desc
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
              , @AdhocComments     VARCHAR(150)    = 'USP_GetToolDashboardList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ', 
													   @Parameter6 = ' + ISNULL(@AssetId,'') + ', 
													   @Parameter7 = ' + ISNULL(@AssetName,'') + ', 
													   @Parameter8 = ' + ISNULL(@AltAssetId,'') + ', 
													   @Parameter9 = ' + ISNULL(@AltAssetName,'') + ', 
													   @Parameter10 = ' + ISNULL(@SerialNum,'') + ', 													  													   @Parameter13 = ' + ISNULL(@LastCalibrationDate,'') + ', 
													   @Parameter11 = ' + ISNULL(@NextCalibrationDate,'') + ',
													   @Parameter12 = ' + ISNULL(@LastCalibrationBy,'') + ', 
													   @Parameter13 = ' + ISNULL(@Certifytype,'') + ', 
													   @Parameter14 = ' + ISNULL(@MasterCompanyId ,'') +''
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