/*************************************************************           
 ** File:   [USP_GetToolDashboardList]           
 ** Author: 
 ** Description: This stored procedure is used to populate Tools Listing.    
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/03/2022   Vishal Suthar Added Inventory Status
     
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetToolDashboardList]
	@PageSize int,
    @PageNumber int,
	@SortColumn varchar(50) = null,
	@SortOrder int,
	@GlobalFilter varchar(50) = '',
	@AssetId varchar(50) = null,
	@AssetName varchar(50) = null,
	@AltAssetId varchar(50) = null,
	@AltAssetName varchar(50) = null,
	@SerialNum varchar(50) = null,
    @ToolId varchar(50) = null,
    @PartNumber varchar(50) = null,
	@Name varchar(50) = null,
	@Manufacturer varchar(50) = null,
	@AltIdNum varchar(50) = null,
    @LastCalibrationDate datetime = null,
    @NextCalibrationDate datetime = null,    
	@LastCalibrationBy varchar(50) = null,
	@StklineNum varchar(50) = null,
	@Calibrated varchar(50) = null,
	@Certifytype varchar(50) = null,
	@CalCertNum varchar(50) = null,	
	@DayTillNextCal varchar(50) = null,
	@Status varchar(50) = null,
	@ManufacturerPN	VARCHAR(50) = NULL,
	@Model	VARCHAR(50) = NULL,
	@ControlNumber	VARCHAR(50) = NULL,
	@AssetAttributeTypeName	VARCHAR(50) = NULL,
	@MasterCompanyId varchar(200) = null,
	@InventoryStatus varchar(200) = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @RecordFrom int;
		Declare @IsActive bit=1
		Declare @Count Int;
		DECLARE @ModuleID varchar(500) ='40,41'
		SET @RecordFrom = (@PageNumber-1)*@PageSize;		
		
		IF @SortColumn is null
		Begin
			Set @SortColumn=Upper('lastCalDate')
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
											CalibrationId  = (SELECT top 1 ISNULL(CalibrationId, 0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											'Yes' as Calibrated,
											(select top 1 AssetId from Asset where AssetRecordId = asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											AsI.AssetInventoryId,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName,
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											UM.Description as UOM,
											ISNULL(T.CalibrationDate,GETDATE()) as LastCalDate,
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 ISNULL(CalibrationDate,GETDATE()) FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId ORDER BY  CalibrationId desc),
											DATEDIFF(day, getDate(), DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0),DATEADD(MONTH,ISNULL(Assc.CalibrationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											asm.ControlNumber As ControlName,
											curr.Code AS CurrencyName,
											CurrencyId=isnull(curr.CurrencyId,0),
											ast.Name as AssetStatus,
											ISNULL(Assc.CalibrationDefaultCost,0) as UnitCost,
											Memo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId order by  CalibrationId desc),
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
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											ISNULL(Assc.CalibrationProvider,'') AS IsVENDororEmployee,
										asm.ManufacturerPN [ManufacturerPN],
										asm.Model [AssetModel],
										AsI.ControlNumber [ControlId],
										Asl.Name AS Locations,
										sit.Name as [Site],
										wh.Name as [Warehouse],
										slf.Name as [Self],
										bn.Name as [Bin],
										InventoryStatus = (SELECT top 1 Status from AssetInventoryStatus WHERE AssetInventoryStatusId = AsI.InventoryStatusId)
										FROM dbo.Asset asm WITH(NOLOCK)
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId										
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.CalibrationDefaultVendorId
										LEFT JOIN dbo.Site sit WITH(NOLOCK) ON sit.SiteId=asm.SiteId
										LEFT JOIN dbo.Warehouse wh WITH(NOLOCK) ON wh.WarehouseId=asm.WarehouseId
										left join dbo.Location  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.LocationId
										left join dbo.Shelf as slf WITH(NOLOCK) on slf.ShelfId=asm.ShelfId
										left join dbo.Bin as bn WITH(NOLOCK) on bn.BinId=asm.BinId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
									    OUTER APPLY (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId ORDER BY  CalibrationId desc) T
										where ((asm.IsDeleted = 0)  AND (ISNULL(clm.IsActive,1) = @isStatusActive )  
										and  asm.MasterCompanyId = @MasterCompanyId 
										AND (@IsActive is null or isnull(AsI.IsActive, 1) = @IsActive))										
										and AsI.InventoryStatusId in (1, 3)
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
										(@GlobalFilter='' AND (IsNull(@AssetId,'') ='' OR AssetId like '%' + @AssetId +'%') AND
											(IsNull(@AssetName,'') ='' OR AssetName like '%' + @AssetName +'%') AND
											(IsNull(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId +'%') AND
											(IsNull(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum +'%') AND
											(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber +'%') AND
											(IsNull(@Manufacturer,'') ='' OR Manufacturer like '%' + @Manufacturer +'%') AND
											(IsNull(@StklineNum,'') ='' OR StklineNum like '%' + @StklineNum +'%') AND
											(IsNull(@Calibrated,'') ='' OR Calibrated like '%' + @Calibrated +'%') AND
											(IsNull(@ToolId,'') ='' OR ToolId like '%' + @ToolId +'%') AND
											(IsNull(@DayTillNextCal,'') ='' OR DayTillNextCal like '%' + @DayTillNextCal +'%') AND
											(IsNull(@LastCalibrationBy,'') ='' OR LastCalBy like '%' + @LastCalibrationBy +'%') AND
											(IsNull(@ManufacturerPN,'') ='' OR ManufacturerPN like '%' + @ManufacturerPN +'%') AND
											(IsNull(@Model,'') ='' OR AssetModel like '%' + @Model +'%') AND
											(IsNull(@ControlNumber,'') ='' OR ControlId like '%' + @ControlNumber +'%') AND
											(IsNull(@AssetAttributeTypeName,'') ='' OR AssetClass like '%' + @AssetAttributeTypeName +'%') AND
											(IsNull(@InventoryStatus,'') ='' OR InventoryStatus like '%' + @InventoryStatus +'%') AND
											(IsNull(@LastCalibrationDate,'') ='' OR Cast(LastCalDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate,'') ='' OR Cast(NextCalDate as Date)=Cast(@NextCalibrationDate as date))
											))
						
								Select @Count = COUNT(AssetId) from #TempResult5			
								update #TempResult5 set LastCalDate=GETDATE() where LastCalDate is null
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
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetClass')  THEN assetClass END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetModel')  THEN assetModel END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='controlId')  THEN controlId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END ASC,

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
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END Desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END ASC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetClass')  THEN assetClass END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetModel')  THEN assetModel END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='controlId')  THEN controlId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END DESC
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
											CalibrationId  = (SELECT top 1 ISNULL(CalibrationId, 0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											'Yes' as Calibrated,
											(select top 1 AssetId from Asset where AssetRecordId = asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											AssetClass= asty.AssetAttributeTypeName,
											astaq.Name AS AcquisitionType,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											ISNULL(T.CalibrationDate,GETDATE()) as LastCalDate,
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' ORDER BY  CalibrationId desc),
											DATEDIFF(day, getDate(), DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0),DATEADD(MONTH,ISNULL(Assc.CalibrationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											Memo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,
											'Calibration' as CertifyType,
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											ISNULL(Assc.CalibrationDefaultCost,0) as UnitCost,
											CurrencyId=isnull(curr.CurrencyId,0),
											ISNULL(Assc.CalibrationProvider,'') AS IsVENDororEmployee
										,AsI.AssetInventoryId
										,asm.ManufacturerPN [ManufacturerPN],
										asm.Model [AssetModel],
										AsI.ControlNumber [ControlId],
										Asl.Name AS Locations,
										sit.Name as [Site],
										wh.Name as [Warehouse],
										slf.Name as [Self],
										bn.Name as [Bin],
										InventoryStatus = (SELECT top 1 Status from AssetInventoryStatus WHERE AssetInventoryStatusId = AsI.InventoryStatusId)
										FROM dbo.Asset asm WITH(NOLOCK)
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId and CertifyType='Calibration'										
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.CalibrationDefaultVendorId
										LEFT JOIN dbo.Site sit WITH(NOLOCK) ON sit.SiteId=asm.SiteId
										LEFT JOIN dbo.Warehouse wh WITH(NOLOCK) ON wh.WarehouseId=asm.WarehouseId
										left join dbo.Location  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.LocationId
										left join dbo.Shelf as slf WITH(NOLOCK) on slf.ShelfId=asm.ShelfId
										left join dbo.Bin as bn WITH(NOLOCK) on bn.BinId=asm.BinId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId 
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										OUTER APPLY (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' ORDER BY  CalibrationId desc) T
										where ((asm.IsDeleted = 0) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive)
										AND  asm.MasterCompanyId=@MasterCompanyId and (Assc.CalibrationRequired =1)
										AND (@IsActive is null or isnull(AsI.IsActive,1) = @IsActive))										
										and AsI.InventoryStatusId in (1,3)
								), ResultCount AS(Select COUNT(AssetId) AS totalItems FROM Result)
								Select * INTO #TempResult from  Result
								WHERE (
									(@GlobalFilter <>'' AND (
											(AssetId like '%' +@GlobalFilter+'%') OR
											(AssetName like '%' +@GlobalFilter+'%') OR
											(AltAssetId like '%' +@GlobalFilter+'%') OR
											(SerialNum like '%' +@GlobalFilter+'%') OR		
											(Itemtype like '%' +@GlobalFilter+'%') OR
											(ISNULL(LastCalDate,GETDATE()) like '%'+@GlobalFilter+'%') OR
											(ControlName like '%' +@GlobalFilter+'%') OR
											(NextCalDate like '%' +@GlobalFilter+'%') OR
											(LastCalBy like '%' +@GlobalFilter+'%') OR										
											(CertifyType like '%' +@GlobalFilter+'%') 
											))
										OR   
										(@GlobalFilter = '' AND (IsNull(@AssetId, '') = '' OR AssetId like '%' + @AssetId +'%') AND
											(IsNull(@AssetName, '') = '' OR AssetName like '%' + @AssetName +'%') AND
											(IsNull(@AltAssetId, '') = '' OR AltAssetId like '%' + @AltAssetId +'%') AND
											(IsNull(@ToolId, '') = '' OR ToolId like '%' + @ToolId +'%') AND
											(IsNull(@PartNumber, '') = '' OR PartNumber like '%' + @PartNumber +'%') AND
											(IsNull(@Manufacturer, '') = '' OR Manufacturer like '%' + @Manufacturer +'%') AND
											(IsNull(@StklineNum, '') = '' OR StklineNum like '%' + @StklineNum +'%') AND
											(IsNull(@Calibrated, '') = '' OR Calibrated like '%' + @Calibrated +'%') AND
											(IsNull(@SerialNum, '') = '' OR SerialNum like '%' + @SerialNum +'%') AND
											(IsNull(@DayTillNextCal, '') = '' OR DayTillNextCal like '%' + @DayTillNextCal +'%') AND
											(IsNull(@LastCalibrationBy, '') = '' OR LastCalBy like '%' + @LastCalibrationBy +'%') AND
											(IsNull(@ManufacturerPN, '') = '' OR ManufacturerPN like '%' + @ManufacturerPN +'%') AND
											(IsNull(@Model, '') = '' OR AssetModel like '%' + @Model +'%') AND
											(IsNull(@ControlNumber,'') = '' OR ControlId like '%' + @ControlNumber +'%') AND
											(IsNull(@AssetAttributeTypeName, '') = '' OR AssetClass like '%' + @AssetAttributeTypeName +'%') AND
											(IsNull(@InventoryStatus, '') = '' OR InventoryStatus like '%' + @InventoryStatus +'%') AND
											(IsNull(@LastCalibrationDate, '') = '' OR Cast(ISNULL(LastCalDate, GETDATE()) as Date) = Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate, '') = '' OR Cast(NextCalDate as Date) = Cast(@NextCalibrationDate as date)) 
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
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetClass')  THEN assetClass END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetModel')  THEN assetModel END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='controlId')  THEN controlId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END ASC,

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
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END desc,								
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetClass')  THEN assetClass END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetModel')  THEN assetModel END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='controlId')  THEN controlId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END DESC
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY
							end

							else if(lower(@Certifytype) =lower('certification'))
							begin

								;With Result AS(
								Select	
											CalibrationId  = (SELECT top 1 ISNULL(CalibrationId, 0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											'Yes' as Calibrated,
											(select top 1 AssetId from Asset where AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName,
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											ISNULL(T.CalibrationDate,GETDATE()) as LastCalDate,
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.CertificationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CertificationFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 ISNULL(CalibrationDate,GETDATE()) FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' ORDER BY  CalibrationId desc),
											DATEDIFF(day, getDate(), DATEADD(DAY, ISNULL(Assc.CertificationFrequencyDays, 0),DATEADD(MONTH,ISNULL(Assc.CertificationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											Memo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,
											'Certification' as CertifyType,	
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											ISNULL(Assc.CertificationDefaultCost,0) as UnitCost,
											CurrencyId=isnull(curr.CurrencyId,0),
					    					ISNULL(Assc.CertificationProvider,'') AS IsVENDororEmployee
										,AsI.AssetInventoryId
										,asm.ManufacturerPN [ManufacturerPN],
										asm.Model [AssetModel],
										AsI.ControlNumber [ControlId],
										Asl.Name AS Locations,
										sit.Name as [Site],
										wh.Name as [Warehouse],
										slf.Name as [Self],
										bn.Name as [Bin],
										InventoryStatus = (SELECT top 1 Status from AssetInventoryStatus WHERE AssetInventoryStatusId = AsI.InventoryStatusId)
										FROM dbo.Asset asm WITH(NOLOCK)
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId	 and CertifyType='Certification'									
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.CertificationDefaultVendorId
										LEFT JOIN dbo.Site sit WITH(NOLOCK) ON sit.SiteId=asm.SiteId
										LEFT JOIN dbo.Warehouse wh WITH(NOLOCK) ON wh.WarehouseId=asm.WarehouseId
										left join dbo.Location  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.LocationId
										left join dbo.Shelf as slf WITH(NOLOCK) on slf.ShelfId=asm.ShelfId
										left join dbo.Bin as bn WITH(NOLOCK) on bn.BinId=asm.BinId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId 
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										OUTER APPLY (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' ORDER BY  CalibrationId desc) T
										where ((asm.IsDeleted = 0) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND  
										(@IsActive is null or isnull(asm.IsActive,1) = @IsActive) 
										and  asm.MasterCompanyId=@MasterCompanyId and (Assc.CertificationRequired =1)
										AND (@IsActive is null or isnull(AsI.IsActive,1) = @IsActive))										
										and AsI.InventoryStatusId in (1,3)
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
										(@GlobalFilter = '' AND (IsNull(@AssetId, '') = '' OR AssetId like '%' + @AssetId +'%') AND
											(IsNull(@AssetName, '') ='' OR AssetName like '%' + @AssetName +'%') AND
											(IsNull(@AltAssetId, '') ='' OR AltAssetId like '%' + @AltAssetId +'%') AND
											(IsNull(@ToolId, '') ='' OR ToolId like '%' + @ToolId +'%') AND
											(IsNull(@PartNumber, '') ='' OR PartNumber like '%' + @PartNumber +'%') AND
											(IsNull(@Manufacturer, '') ='' OR Manufacturer like '%' + @Manufacturer +'%') AND
											(IsNull(@StklineNum, '') ='' OR StklineNum like '%' + @StklineNum +'%') AND
											(IsNull(@Calibrated, '') ='' OR Calibrated like '%' + @Calibrated +'%') AND
											(IsNull(@SerialNum, '') ='' OR SerialNum like '%' + @SerialNum +'%') AND
											(IsNull(@DayTillNextCal, '') ='' OR DayTillNextCal like '%' + @DayTillNextCal +'%') AND
											(IsNull(@LastCalibrationBy, '') = '' OR LastCalBy like '%' + @LastCalibrationBy +'%') AND
											(IsNull(@ManufacturerPN, '') = '' OR ManufacturerPN like '%' + @ManufacturerPN +'%') AND
											(IsNull(@Model, '') = '' OR AssetModel like '%' + @Model +'%') AND
											(IsNull(@ControlNumber, '') = '' OR ControlId like '%' + @ControlNumber +'%') AND
											(IsNull(@AssetAttributeTypeName, '') = '' OR AssetClass like '%' + @AssetAttributeTypeName +'%') AND
											(IsNull(@InventoryStatus, '') = '' OR InventoryStatus like '%' + @InventoryStatus +'%') AND
											(IsNull(@LastCalibrationDate, '') = '' OR Cast(LastCalDate as Date) = Cast(@LastCalibrationDate as date)) AND
											(IsNull(@NextCalibrationDate, '') = '' OR Cast(NextCalDate as Date) = Cast(@NextCalibrationDate as date)) 
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
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetClass')  THEN assetClass END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetModel')  THEN assetModel END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='controlId')  THEN controlId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END ASC,

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
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetClass')  THEN assetClass END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetModel')  THEN assetModel END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='controlId')  THEN controlId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END DESC
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY
							end

							else if(lower(@Certifytype) = lower('inspection'))
							begin
								;With Result AS(
								Select	
											CalibrationId  = (SELECT top 1 ISNULL(CalibrationId, 0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											'Yes' as Calibrated,
											(select top 1 AssetId from Asset where AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName,
												ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
												astaq.Name AS AcquisitionType,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											ISNULL(T.CalibrationDate,GETDATE()) as LastCalDate,
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.InspectionFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.InspectionFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 ISNULL(CalibrationDate,GETDATE()) FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' ORDER BY  CalibrationId desc),
											DATEDIFF(day, getDate(), DATEADD(DAY, ISNULL(Assc.InspectionFrequencyDays, 0),DATEADD(MONTH,ISNULL(Assc.InspectionFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											Memo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,
											'Inspection' as CertifyType,
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
										ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											ISNULL(Assc.InspectionDefaultCost,0) as UnitCost,
											CurrencyId=isnull(curr.CurrencyId,0),
											ISNULL(Assc.InspectionProvider,'') AS IsVENDororEmployee
		   							,AsI.AssetInventoryId
									,asm.ManufacturerPN [ManufacturerPN],
										asm.Model [AssetModel],
										AsI.ControlNumber [ControlId],
										Asl.Name AS Locations,
										sit.Name as [Site],
										wh.Name as [Warehouse],
										slf.Name as [Self],
										bn.Name as [Bin],
										InventoryStatus = (SELECT top 1 Status from AssetInventoryStatus WHERE AssetInventoryStatusId = AsI.InventoryStatusId)
									FROM dbo.Asset asm WITH(NOLOCK)									
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId and CertifyType='Inspection'										
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.InspectionDefaultVendorId
										LEFT JOIN dbo.Site sit WITH(NOLOCK) ON sit.SiteId=asm.SiteId
										LEFT JOIN dbo.Warehouse wh WITH(NOLOCK) ON wh.WarehouseId=asm.WarehouseId
										left join dbo.Location  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.LocationId
										left join dbo.Shelf as slf WITH(NOLOCK) on slf.ShelfId=asm.ShelfId
										left join dbo.Bin as bn WITH(NOLOCK) on bn.BinId=asm.BinId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										OUTER APPLY (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' ORDER BY  CalibrationId desc) T
										where ((asm.IsDeleted = 0) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  
										AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) 
										and  asm.MasterCompanyId=@MasterCompanyId and (Assc.InspectionRequired =1)
										AND (@IsActive is null or isnull(AsI.IsActive,1) = @IsActive))										
										and AsI.InventoryStatusId in (1,3)
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
											(IsNull(@ManufacturerPN,'') ='' OR ManufacturerPN like '%' + @ManufacturerPN+'%') AND
											(IsNull(@Model,'') ='' OR AssetModel like '%' + @Model+'%') AND
											(IsNull(@ControlNumber,'') ='' OR ControlId like '%' + @ControlNumber+'%') AND
											(IsNull(@AssetAttributeTypeName,'') ='' OR AssetClass like '%' + @AssetAttributeTypeName+'%') AND
											(IsNull(@InventoryStatus, '') = '' OR InventoryStatus like '%' + @InventoryStatus +'%') AND
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
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetClass')  THEN assetClass END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetModel')  THEN assetModel END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='controlId')  THEN controlId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END ASC,

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
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetClass')  THEN assetClass END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetModel')  THEN assetModel END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='controlId')  THEN controlId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END ASC
								OFFSET @RecordFrom ROWS 
								FETCH NEXT @PageSize ROWS ONLY

							end

							else if(lower(@Certifytype) =lower('verification'))
							begin

								;With Result AS(
								Select	
											  CalibrationId  = (SELECT top 1 ISNULL(CalibrationId, 0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS ToolId,
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											Asi.PartNumber AS PartNumber,
											Asi.StklineNumber AS StklineNum,
											maf.Name AS Manufacturer,
											'Yes' as Calibrated,
											(select top 1 AssetId from Asset where AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' end  as AssetType,
											AssetClass= asty.AssetAttributeTypeName,
												ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
												astaq.Name AS AcquisitionType,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											ISNULL(T.CalibrationDate,GETDATE()) as LastCalDate,
											NextCalDate =  DATEADD(DAY, ISNULL(Assc.VerificationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.VerificationFrequencyMonths,0),getdate())),				
											LastCalBy = (SELECT top  1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 ISNULL(CalibrationDate,GETDATE()) FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' ORDER BY  CalibrationId desc),
											DATEDIFF(day, getDate(), DATEADD(DAY, ISNULL(Assc.VerificationFrequencyDays, 0),DATEADD(MONTH,ISNULL(Assc.VerificationFrequencyMonths,0),getdate()))) AS DayTillNextCal,
											curr.Code AS CurrencyName,
											ast.Name as AssetStatus,
											Memo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' order by  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (select top 1 memo from CalibrationManagment where AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' order by  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,
											'Verification' as CertifyType,	
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											ISNULL(Assc.VerificationDefaultCost,0) as UnitCost,
											CurrencyId=isnull(curr.CurrencyId,0),
											ISNULL(Assc.VerificationProvider,'') AS IsVENDororEmployee
										,AsI.AssetInventoryId
										,asm.ManufacturerPN [ManufacturerPN],
										asm.Model [AssetModel],
										AsI.ControlNumber [ControlId],
										Asl.Name AS Locations,
										sit.Name as [Site],
										wh.Name as [Warehouse],
										slf.Name as [Self],
										bn.Name as [Bin],
										InventoryStatus = (SELECT top 1 Status from AssetInventoryStatus WHERE AssetInventoryStatusId = AsI.InventoryStatusId)
										FROM dbo.Asset asm WITH(NOLOCK)
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId and CertifyType='Verification'										
										LEFT join dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.VerificationDefaultVendorId
										LEFT JOIN dbo.Site sit WITH(NOLOCK) ON sit.SiteId=asm.SiteId
										LEFT JOIN dbo.Warehouse wh WITH(NOLOCK) ON wh.WarehouseId=asm.WarehouseId
										left join dbo.Location  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.LocationId
										left join dbo.Shelf as slf WITH(NOLOCK) on slf.ShelfId=asm.ShelfId
										left join dbo.Bin as bn WITH(NOLOCK) on bn.BinId=asm.BinId
										LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId 
										left join dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										left join dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										left join dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										left join dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										left join dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										OUTER APPLY (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' ORDER BY  CalibrationId desc) T
										where ((asm.IsDeleted = 0) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  
										AND (@IsActive is null or isnull(asm.IsActive,1) = @IsActive) 
										and  asm.MasterCompanyId=@MasterCompanyId and (Assc.VerificationRequired =1)
										AND (@IsActive is null or isnull(AsI.IsActive,1) = @IsActive))										
										and AsI.InventoryStatusId in (1,3)
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
											(IsNull(@ManufacturerPN,'') ='' OR ManufacturerPN like '%' + @ManufacturerPN+'%') AND
											(IsNull(@Model,'') ='' OR AssetModel like '%' + @Model+'%') AND
											(IsNull(@ControlNumber,'') ='' OR ControlId like '%' + @ControlNumber+'%') AND
											(IsNull(@AssetAttributeTypeName,'') ='' OR AssetClass like '%' + @AssetAttributeTypeName+'%') AND
											(IsNull(@InventoryStatus, '') = '' OR InventoryStatus like '%' + @InventoryStatus +'%') AND
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
								CASE WHEN (@SortOrder=1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetClass')  THEN assetClass END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='assetModel')  THEN assetModel END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='controlId')  THEN controlId END ASC,
								CASE WHEN (@SortOrder=1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END ASC,

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
								CASE WHEN (@SortOrder=-1 and @SortColumn='dayTillNextCal')  THEN dayTillNextCal END desc,
								CASE WHEN (@SortOrder=-1 and @SortColumn='manufacturerPN')  THEN manufacturerPN END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetClass')  THEN assetClass END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='assetModel')  THEN assetModel END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='controlId')  THEN controlId END DESC,
								CASE WHEN (@SortOrder=-1 and @SortColumn='inventoryStatus')  THEN InventoryStatus END ASC
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