CREATE PROCEDURE [dbo].[GetCalibarationMgmtList]
	-- Add the parameters for the stored procedure here	
	@PageSize int,
    @PageNumber int,
	@SortColumn VARCHAR(50)=null,
	@SortOrder int,
	@GlobalFilter VARCHAR(50) = '',
	@AssetId VARCHAR(50) = null,
	@AssetName VARCHAR(50)=null,
	@AltAssetId VARCHAR(50)=null,
	@AltAssetName VARCHAR(50)=null,
	@SerialNum VARCHAR(50)=null,
    @Location VARCHAR(50)=null,
    @ControlName VARCHAR(50)=null,
    @LastCalibrationDate datetime=null,
    @NextCalibrationDate datetime=null,    
	@LastCalibrationBy VARCHAR(50)=null,
	@AssetType VARCHAR(50)=null,
	@CurrencyName VARCHAR(50)=null,
	@Certifytype VARCHAR(50)=null,
	@UOM VARCHAR(50)=null,
	@Qty int=null,
	@UpdatedCost decimal(18,2)=null,
	@Inservicedate datetime=null,
	@AssetStatus VARCHAR(50)=null,
	@Itemtype VARCHAR(50)=null,
	@CompanyName VARCHAR(50)=null,
	@BuName VARCHAR(50)=null,
	@DivName VARCHAR(50)=null,
	@DeptName VARCHAR(50)=null,
	@lastcalibrationmemo VARCHAR(50)=null,
	@lastcheckedinby VARCHAR(50)=null,
	@lastcheckedindate datetime=null,
	@lastcheckedinmemo VARCHAR(50)=null,
	@lastcheckedoutby VARCHAR(50)=null,
	@lastcheckedoutdate datetime=null,
	@lastcheckedoutmemo VARCHAR(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  VARCHAR(50)=null,
	@UpdatedBy  VARCHAR(50)=null,
    @IsDeleted bit= null,
	@Status VARCHAR(50)= null,
	@MasterCompanyId VARCHAR(200)=null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @RecordFROM int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;
		SET @RecordFROM = (@PageNumber-1)*@PageSize;
		IF @IsDeleted is null
		BEGIN
			Set @IsDeleted=0
		END
		
		IF @SortColumn is null
		BEGIN
			Set @SortColumn=Upper('CreatedDate')
		END 
		Else
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END

		set @IsActive = 1

		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN
				DECLARE @isStatusActive bit = 1;
				set @isStatusActive = (CASE WHEN @Status ='InActive' then 0 else 1 END)
					IF((@Certifytype is null or lower(@Certifytype) ='') and @Status is not null)
					BEGIN	
						print 'Status 1'
							DECLARE @isActiveFilter bit = (CASE when @Status = 'InActive' then 0 else 1 END)
									;With Result AS(
								SELECT	
											CalibrationId  = (SELECT top 1 ISNULL(CalibrationId, 0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											(SELECT top 1 AssetId FROM Asset WHERE AssetRecordId = asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											AsI.AssetInventoryId,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' END  as AssetType,
											AssetClass= asty.AssetAttributeTypeName, 
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetRecordId ORDER BY  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate())),				
											LastCalibrationBy = (SELECT top  1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetRecordId ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetRecordId ORDER BY  CalibrationId desc),
											curr.Code AS CurrencyName,
											curr.CurrencyId,
											ast.Name as AssetStatus,
											--ISNULL(asm.UnitCost,0) as UnitCost,
											ISNULL(Assc.CalibrationDefaultCost,0) as UnitCost,
											Memo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetRecordId ORDER BY  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetRecordId ORDER BY  CalibrationId desc),
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
												  WHEN Assc.VerificationRequired =1  THEN  'Verification' ELSE 'Calibration' END)as CertifyType,
											--'Calibration' as CertifyType,
											asm.level1 AS CompanyName,
											asm.level2 AS BuName,
											asm.level3 AS DivName,
											asm.level4 AS DeptName,											
											AsI.StklineNumber AS StocklineNumber,
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											ISNULL(Assc.CalibrationProvider,'') AS IsVENDororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId										
										LEFT JOIN dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.CertificationDefaultVendorId
										LEFT JOIN dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										LEFT JOIN dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										LEFT JOIN dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										LEFT JOIN dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										LEFT JOIN dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										INNER JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId										
										WHERE ((asm.IsDeleted = @IsDeleted)  AND (ISNULL(clm.IsActive,1) = @isStatusActive )  and  asm.MasterCompanyId=@MasterCompanyId )
								), ResultCount AS(SELECT COUNT(AssetId) AS totalItems FROM Result)
								SELECT * INTO #TempResult5 FROM  Result
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
										(@GlobalFilter='' AND (ISNULL(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(ISNULL(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(ISNULL(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(ISNULL(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(ISNULL(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(ISNULL(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(ISNULL(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(ISNULL(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(ISNULL(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(ISNULL(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(ISNULL(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(ISNULL(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(ISNULL(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(ISNULL(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(ISNULL(@Qty,'') = '' OR  cast(Qty as VARCHAR(10))  like '%' + cast(@Qty as VARCHAR(10))+'%') AND
											(ISNULL(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(ISNULL(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(ISNULL(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(ISNULL(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(ISNULL(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(ISNULL(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(ISNULL(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(ISNULL(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(ISNULL(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(ISNULL(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(ISNULL(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								SELECT @Count = COUNT(AssetId) FROM #TempResult5			

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
								OFFSET @RecordFROM ROWS 
								FETCH NEXT @PageSize ROWS ONLY
					END
					ELSE
					BEGIN
						if(lower(@Certifytype) =lower('calibration'))			
							BEGIN
								print 'Calibration'
								;With Result AS(
								SELECT	
											CalibrationId  =clm.CalibrationId,-- (SELECT top 1 ISNULL(CalibrationId, 0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											(SELECT top 1 AssetId FROM Asset WHERE AssetRecordId = asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' END  as AssetType,
											AssetClass= asty.AssetAttributeTypeName, 
											ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' ORDER BY  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, ISNULL(Assc.CalibrationFrequencyDays, 0), DATEADD(MONTH, ISNULL(Assc.CalibrationFrequencyMonths,0),getdate())),				
											LastCalibrationBy = (SELECT top  1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' ORDER BY  CalibrationId desc),
											curr.Code AS CurrencyName,
											curr.CurrencyId,
											ast.Name as AssetStatus,
											ISNULL(Assc.CalibrationDefaultCost,0) as UnitCost,
											Memo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' ORDER BY  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Calibration' ORDER BY  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,	
											'Calibration' as CertifyType,
											asm.level1 AS CompanyName,
											asm.level2 AS BuName,
											asm.level3 AS DivName,
											asm.level4 AS DeptName,
											AsI.StklineNumber AS StocklineNumber,
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											AsI.AssetInventoryId,
											ISNULL(Assc.CalibrationProvider,'') AS IsVENDororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId and CertifyType='Calibration'									
										--LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										--LEFT JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.CalibrationDefaultVendorId
										LEFT JOIN dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										LEFT JOIN dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										LEFT JOIN dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										LEFT JOIN dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										LEFT JOIN dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										WHERE ((asm.IsDeleted = @IsDeleted) AND (ISNULL(clm.IsActive,1) = @isStatusActive ) AND (@IsActive is null or ISNULL(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.CalibrationRequired =1))
								), ResultCount AS(SELECT COUNT(AssetId) AS totalItems FROM Result)
								SELECT * INTO #TempResult FROM  Result
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
										(@GlobalFilter='' AND (ISNULL(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(ISNULL(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(ISNULL(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(ISNULL(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(ISNULL(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(ISNULL(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(ISNULL(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(ISNULL(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(ISNULL(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(ISNULL(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(ISNULL(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(ISNULL(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(ISNULL(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(ISNULL(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(ISNULL(@Qty,'') = '' OR  cast(Qty as VARCHAR(10))  like '%' + cast(@Qty as VARCHAR(10))+'%') AND
											(ISNULL(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(ISNULL(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(ISNULL(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(ISNULL(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(ISNULL(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(ISNULL(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(ISNULL(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(ISNULL(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(ISNULL(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(ISNULL(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(ISNULL(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								SELECT @Count = COUNT(AssetId) FROM #TempResult			

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
								OFFSET @RecordFROM ROWS 
								FETCH NEXT @PageSize ROWS ONLY

							END

							else if(lower(@Certifytype) =lower('certification'))
							BEGIN

								;With Result AS(
								SELECT	
											CalibrationId  = (SELECT top 1 ISNULL(CalibrationId,0) FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId ORDER BY  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											(SELECT top 1 AssetId FROM Asset WHERE AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' END  as AssetType,
											AssetClass= asty.AssetAttributeTypeName,
												ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' ORDER BY  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, ISNULL(Assc.CertificationFrequencyDays, 0), DATEADD(MONTH,ISNULL(Assc.CertificationFrequencyMonths,0),getdate())),
											LastCalibrationBy = (SELECT top 1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' ORDER BY  CalibrationId desc),
											curr.Code AS CurrencyName,
											curr.CurrencyId,
											ast.Name as AssetStatus,
											--ISNULL(asm.UnitCost,0) as UnitCost,
											ISNULL(Assc.CertificationDefaultCost,0) as UnitCost,
											Memo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' ORDER BY  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Certification' ORDER BY  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,
											'Certification' as CertifyType,
											asm.level1 AS CompanyName,
											asm.level2 AS BuName,
											asm.level3 AS DivName,
											asm.level4 AS DeptName,
											AsI.StklineNumber AS StocklineNumber,
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											AsI.AssetInventoryId,
											ISNULL(Assc.CertificationProvider,'') AS IsVENDororEmployee
											--Assc.
											--CASE WHEN (ISNULL(Assc.CertificationRequired, 0) > 0 AND ISNULL(Assc.CertificationDefaultVendorId, 0) > 0) THEN Assc.CertificationProvider ELSE '' END AS IsVENDororEmployee
					    					--ISNULL((SELECT top 1 IsVENDororEmployee FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),'vENDor') as IsVENDororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId and CertifyType='Certification'										
										--LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										--LEFT JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.CertificationDefaultVendorId
										LEFT JOIN dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										LEFT JOIN dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										LEFT JOIN dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										LEFT JOIN dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										LEFT JOIN dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										INNER JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId										
										WHERE ((asm.IsDeleted = @IsDeleted) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND  (@IsActive is null or ISNULL(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.CertificationRequired =1))
								), ResultCount AS(SELECT COUNT(AssetId) AS totalItems FROM Result)
							SELECT * INTO #TempResult1 FROM  Result
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
										(@GlobalFilter='' AND (ISNULL(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(ISNULL(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(ISNULL(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(ISNULL(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(ISNULL(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(ISNULL(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(ISNULL(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(ISNULL(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(ISNULL(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(ISNULL(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(ISNULL(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(ISNULL(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(ISNULL(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(ISNULL(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(ISNULL(@Qty,'') = '' OR  cast(Qty as VARCHAR(10))  like '%' + cast(@Qty as VARCHAR(10))+'%') AND
											(ISNULL(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(ISNULL(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(ISNULL(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(ISNULL(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(ISNULL(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(ISNULL(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(ISNULL(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(ISNULL(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(ISNULL(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(ISNULL(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(ISNULL(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								SELECT @Count = COUNT(AssetId) FROM #TempResult1			

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
								OFFSET @RecordFROM ROWS 
								FETCH NEXT @PageSize ROWS ONLY
							END

							else if(lower(@Certifytype) = lower('inspection'))
							BEGIN
								;With Result AS(
								SELECT	
											CalibrationId  = (SELECT top 1 ISNULL(CalibrationId,0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
																	(SELECT top 1 AssetId FROM Asset WHERE AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' END  as AssetType,
											AssetClass= asty.AssetAttributeTypeName, 
												ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' ORDER BY  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, ISNULL(Assc.InspectionFrequencyDays,0), DATEADD(MONTH,ISNULL(Assc.InspectionFrequencyMonths,0),getdate())),
											LastCalibrationBy = (SELECT top 1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' ORDER BY  CalibrationId desc),
											curr.Code AS CurrencyName,
											curr.CurrencyId,
											ast.Name as AssetStatus,
											--ISNULL(asm.UnitCost,0) as UnitCost,
											ISNULL(Assc.InspectionDefaultCost,0) as UnitCost,
											Memo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' ORDER BY  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Inspection' ORDER BY  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,		
											'Inspection' as CertifyType,
											asm.level1 AS CompanyName,
											asm.level2 AS BuName,
											asm.level3 AS DivName,
											asm.level4 AS DeptName,
											AsI.StklineNumber AS StocklineNumber,
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											AsI.AssetInventoryId,
											ISNULL(Assc.InspectionProvider,'') AS IsVENDororEmployee
		   							FROM dbo.Asset asm WITH(NOLOCK)
									INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId and CertifyType='Inspection'										
										--LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										--LEFT JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.InspectionDefaultVendorId
										LEFT JOIN dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										LEFT JOIN dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										LEFT JOIN dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										LEFT JOIN dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										LEFT JOIN dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										INNER JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId										
										WHERE ((asm.IsDeleted = @IsDeleted) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND (@IsActive is null or ISNULL(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.InspectionRequired =1))
								), ResultCount AS(SELECT COUNT(AssetId) AS totalItems FROM Result)
								SELECT * INTO #TempResult2 FROM  Result
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
										(@GlobalFilter='' AND (ISNULL(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(ISNULL(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(ISNULL(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(ISNULL(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(ISNULL(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(ISNULL(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(ISNULL(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(ISNULL(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(ISNULL(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(ISNULL(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(ISNULL(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(ISNULL(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(ISNULL(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(ISNULL(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(ISNULL(@Qty,'') = '' OR  cast(Qty as VARCHAR(10))  like '%' + cast(@Qty as VARCHAR(10))+'%') AND
											(ISNULL(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(ISNULL(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(ISNULL(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(ISNULL(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(ISNULL(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(ISNULL(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(ISNULL(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(ISNULL(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(ISNULL(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(ISNULL(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(ISNULL(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								SELECT @Count = COUNT(AssetId) FROM #TempResult2			

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
								OFFSET @RecordFROM ROWS 
								FETCH NEXT @PageSize ROWS ONLY

							END

							else if(lower(@Certifytype) =lower('verification'))
							BEGIN

								;With Result AS(
								SELECT	
											  CalibrationId  = (SELECT top 1 ISNULL(CalibrationId,0) FROM CalibrationManagment WHERE AssetRecordId = asm.AssetRecordId ORDER BY  CalibrationId desc),							
											asm.Assetid AS AssetId,
											asm.Name AS AssetName,
											(SELECT top 1 AssetId FROM Asset WHERE AssetRecordId=asm.AlternateAssetRecordId) AS AltAssetId,
											asm.AssetRecordId AS AssetRecordId,
											AsI.SerialNo AS SerialNum,
											'Asset' AS Itemtype,
											case when asm.IsTangible = 1 then 'Tangible'else 'Intangible' END  as AssetType,
											AssetClass= asty.AssetAttributeTypeName, --case  when (SELECT top 1 AssetIntangibleName FROM AssetIntangibleType asp WHERE asp.AssetIntangibleTypeId = asm.AssetIntangibleTypeId),
												ISNULL(asm.AssetAcquisitionTypeId,0) AS AcquisitionTypeId,
											astaq.Name AS AcquisitionType,
											Asl.Name AS Locations,
											asm.ControlNumber As ControlName,
											UM.Description as UOM,
											LastCalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' ORDER BY  CalibrationId desc),							
											NextCalibrationDate =  DATEADD(DAY, ISNULL(Assc.VerificationFrequencyDays,0), DATEADD(MONTH,ISNULL(Assc.VerificationFrequencyMonths,0),getdate())),
											LastCalibrationBy = (SELECT top 1 LastCalibrationBy FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' ORDER BY  CalibrationId desc),					
											CalibrationDate  = (SELECT top 1 CalibrationDate FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' ORDER BY  CalibrationId desc),
											curr.Code AS CurrencyName,
											curr.CurrencyId,
											ast.Name as AssetStatus,
											--ISNULL(asm.UnitCost,0) as UnitCost,
											ISNULL(Assc.VerificationDefaultCost,0) as UnitCost,
											Memo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' ORDER BY  CalibrationId desc),
											'1' as Qty,
											'' as Inservicesdate,
											lastcalibrationmemo = (SELECT top 1 memo FROM CalibrationManagment WHERE AssetInventoryId = AsI.AssetInventoryId and CertifyType='Verification' ORDER BY  CalibrationId desc),
											'' AS lastcheckedinby,
											'' AS lastcheckedindate,
											'' AS lastcheckedinmemo,
											'' AS lastcheckedoutby,
											'' AS lastcheckedoutdate,	
											'' AS lastcheckedoutmemo,	
											'Verification' as CertifyType,
											asm.level1 AS CompanyName,
											asm.level2 AS BuName,
											asm.level3 AS DivName,
											asm.level4 AS DeptName,
											AsI.StklineNumber AS StocklineNumber,
											asm.MasterCompanyId AS MasterCompanyId,
											asm.CreatedDate AS CreatedDate,
											asm.UpdatedDate AS UpdatedDate,
											asm.CreatedBy AS CreatedBy,
											asm.UpdatedBy AS UpdatedBy ,
											ISNULL(clm.IsActive,1) AS IsActive,
											asm.IsDeleted AS IsDeleted,
											V.vendorName AS VendorName,
											V.vendorId AS VendorId,
											AsI.AssetInventoryId,
											ISNULL(Assc.VerificationProvider,'') AS IsVENDororEmployee
										FROM dbo.Asset asm WITH(NOLOCK)
										INNER JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on AsI.AssetInventoryId= clm.AssetInventoryId and asm.AssetRecordId=clm.AssetRecordId and CertifyType='Verification'										
										--LEFT JOIN dbo.CalibrationManagment  As clm WITH(NOLOCK) on asm.AssetRecordId=clm.AssetRecordId
										--LEFT JOIN dbo.CalibrationManagment   As CM  WITH(NOLOCK) on asm.AssetRecordId=cm.AssetRecordId
										--LEFT JOIN dbo.AssetInventory   As AsI WITH(NOLOCK) on asm.AssetRecordId=AsI.AssetRecordId
										LEFT JOIN dbo.AssetLocation  As Asl WITH(NOLOCK) on asm.AssetLocationId=Asl.AssetLocationId
										LEFT JOIN dbo.AssetCalibration  As Assc WITH(NOLOCK) on Assc.AssetRecordId=asm.AssetRecordId
										LEFT JOIN dbo.Vendor  V WITH(NOLOCK) ON V.vendorId = Assc.VerificationDefaultVendorId
										LEFT JOIN dbo.UnitOfMeasure  As UM  WITH(NOLOCK)on UM.UnitOfMeasureId=AsI.UnitOfMeasureId
										LEFT JOIN dbo.Currency  As curr WITH(NOLOCK) on curr.CurrencyId=AsI.CurrencyId
										LEFT JOIN dbo.AssetStatus  As ast WITH(NOLOCK) on ast.AssetStatusId=AsI.AssetStatusId
										LEFT JOIN dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
										LEFT JOIN dbo.AssetAcquisitionType  As astaq WITH(NOLOCK) on astaq.AssetAcquisitionTypeId=asm.AssetAcquisitionTypeId
										INNER JOIN dbo. ManagementStructure  level4 WITH(NOLOCK) ON asm.ManagementStructureId = level4.ManagementStructureId										
										WHERE ((asm.IsDeleted = @IsDeleted) AND (ISNULL(clm.IsActive,1) = @isStatusActive )  AND (@IsActive is null or ISNULL(asm.IsActive,1) = @IsActive) and  asm.MasterCompanyId=@MasterCompanyId and (Assc.VerificationRequired =1))
								), ResultCount AS(SELECT COUNT(AssetId) AS totalItems FROM Result)
								SELECT * INTO #TempResult3 FROM  Result
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
										(@GlobalFilter='' AND (ISNULL(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
											(ISNULL(@AssetName,'') ='' OR AssetName like '%' + @AssetName+'%') AND
											(ISNULL(@AltAssetId,'') ='' OR AltAssetId like '%' + @AltAssetId+'%') AND
											(ISNULL(@SerialNum,'') ='' OR SerialNum like '%' + @SerialNum+'%') AND
											(ISNULL(@Itemtype,'') ='' OR Itemtype like '%' + @Itemtype+'%') AND
											(ISNULL(@AssetType,'') ='' OR AssetClass like '%' + @AssetType+'%') AND
											(ISNULL(@LastCalibrationDate,'') ='' OR Cast(LastCalibrationDate as Date)=Cast(@LastCalibrationDate as date)) AND
											(ISNULL(@NextCalibrationDate,'') ='' OR Cast(NextCalibrationDate as Date)=Cast(@NextCalibrationDate as date)) AND
											(ISNULL(@Inservicedate,'') ='' OR Cast(Inservicesdate as Date)=Cast(@Inservicedate as date)) AND
											(ISNULL(@lastcheckedindate,'') ='' OR Cast(lastcheckedindate as Date)=Cast(@lastcheckedindate as date)) AND
											(ISNULL(@lastcheckedoutdate,'') ='' OR Cast(lastcheckedoutdate as Date)=Cast(@lastcheckedoutdate as date)) AND
											(ISNULL(@Location,'') ='' OR Locations like '%' + @Location+'%') AND
											(ISNULL(@ControlName,'') ='' OR ControlName like '%' + @ControlName+'%') AND
											(ISNULL(@UOM,'') ='' OR UOM like '%' + @UOM+'%') AND
											(ISNULL(@Qty,'') = '' OR  cast(Qty as VARCHAR(10))  like '%' + cast(@Qty as VARCHAR(10))+'%') AND
											(ISNULL(@lastcalibrationmemo,'') ='' OR lastcalibrationmemo like '%' + @lastcalibrationmemo+'%') AND
											(ISNULL(@lastcheckedinby,'') ='' OR lastcheckedinby like '%' + @lastcheckedinby+'%') AND
											(ISNULL(@lastcheckedinmemo,'') ='' OR lastcheckedinmemo like '%' + @lastcheckedinmemo+'%') AND
											(ISNULL(@lastcheckedoutby,'') ='' OR lastcheckedoutby like '%' + @lastcheckedoutby+'%') AND
											(ISNULL(@lastcheckedoutmemo,'') ='' OR lastcheckedoutmemo like '%' + @lastcheckedoutmemo+'%') AND
											(ISNULL(@CertifyType,'') ='' OR CertifyType like '%' + @CertifyType+'%') AND
											(ISNULL(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
											(ISNULL(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
											(ISNULL(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
											(ISNULL(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
											(ISNULL(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
											(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
											))
						
								SELECT @Count = COUNT(AssetId) FROM #TempResult3			

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
								OFFSET @RecordFROM ROWS 
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