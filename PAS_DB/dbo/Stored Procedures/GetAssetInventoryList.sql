CREATE PROCEDURE [dbo].[GetAssetInventoryList]
	-- Add the parameters for the stored procedure here	
	@PageSize int,
    @PageNumber int,
	@SortColumn varchar(50) = null,
	@SortOrder int,
	@StatusID int = 0,
	@GlobalFilter varchar(50) = '',
	@AssetId varchar(50) = null,
	@Name varchar(50) = null,
	@AlternateAssetId varchar(50) = null,
	@ManufacturerName varchar(50) = null,
	@SerialNumber varchar(50) = null,
    @CalibrationRequiredNew varchar(50) = null,
	@AssetStatus varchar(50) = null,
	@AssetType varchar(50) = null,
	@InventoryNumber varchar(50) = null,
	@InventoryStatus varchar(50) = null,
	@AssetClass varchar(50) = null,
	@EntryDate  datetime = null,
	@CompanyName varchar(50) = null,
	@BuName varchar(50) = null,
	@DivName varchar(50) = null,
	@DeptName varchar(50) = null,
	@deprAmort varchar(50) = null,
	@AssetInventoryIds varchar(1000) = NULL,
    @CreatedDate datetime = null,
    @UpdatedDate  datetime = null,
	@CreatedBy  varchar(50) = null,
	@UpdatedBy  varchar(50) = null,
    @IsDeleted bit = null,
	@MasterCompanyId int = 0,
	@ManufacturerPN varchar(50) = null,
	@Model varchar(50) = null,
	@StklineNumber varchar(50) = null,
	@ControlNumber varchar(50) = null,
	@EmployeeId bigint=1
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @RecordFrom int;
		DECLARE @ModuleID varchar(500) ='42,43'
		Declare @IsActive bit = 1
		Declare @Count Int;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted = 0
		END
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			SET @SortColumn = Upper(@SortColumn)
		END

		If @StatusID = 0
		BEGIN 
			SET @IsActive = 0
		END 
		ELSE IF @StatusID = 1
		BEGIN 
			SET @IsActive = 1
		END 
		ELSE IF @StatusID = 2
		BEGIN 
			SET @IsActive = NULL
		END 

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
						;With Result AS(
							SELECT	
								asm.AssetRecordId as AssetRecordId,
								AssetInventoryId = asm.AssetInventoryId,
								asm.Name AS Name,
								asm.AssetId AS AssetId,
								(SELECT top 1 AssetId FROM dbo.Asset WITH (NOLOCK) WHERE AssetRecordId=asm.AlternateAssetRecordId) AS AlternateAssetId,
								maf.Name AS ManufacturerName,
								SerialNumber =asm.SerialNo,
								CASE WHEN asm.IsSerialized = 1 THEN 'Yes'ELSE 'No' END AS IsSerializedNew,
								CASE WHEN asm.CalibrationRequired = 1 THEN 'Yes'ELSE 'No' END AS CalibrationRequiredNew,
								CASE WHEN asm.IsTangible = 1 THEN 'Tangible'ELSE 'Intangible' END AS AssetClass,
								ISNULL((CASE WHEN ISNULL(asm.IsTangible,0) = 1 and ISNULL(asm.IsDepreciable, 0) = 1 THEN 'Yes' when  ISNULL(asm.IsTangible,0) = 0 and ISNULL(asm.IsAmortizable,0)=1  THEN  'Yes'  ELSE 'No'  END),'No') as deprAmort,
								AssetType = CASE WHEN ISNULL(asty.AssetAttributeTypeName,'') != '' THEN asty.AssetAttributeTypeName ELSE ISNULL(asti.AssetIntangibleName,'') END, --case  when (SELECT top 1 AssetIntangibleName from AssetIntangibleType asp WHERE asp.AssetIntangibleTypeId = asm.AssetIntangibleTypeId),
								InventoryNumber = asm.InventoryNumber,
								EntryDate = asm.EntryDate,
								AssetStatus = (SELECT top 1 Name from AssetStatus WHERE AssetStatusId = asm.AssetStatusId),
								InventoryStatus = (SELECT top 1 Status from AssetInventoryStatus WHERE AssetInventoryStatusId = asm.InventoryStatusId),
								asm.InventoryStatusId AS InventoryStatusId,
								asm.level1 AS CompanyName,
								asm.level2 AS BuName,
								asm.level3 AS DivName,
								asm.level4 AS DeptName,
								asm.MasterCompanyId AS MasterCompanyId,
								asm.CreatedDate AS CreatedDate,
								asm.UpdatedDate AS UpdatedDate,
								asm.CreatedBy AS CreatedBy,
								asm.UpdatedBy AS UpdatedBy ,
								asm.IsActive AS IsActive,
								asm.IsDeleted AS IsDeleted,
								ast.ManufacturerPN,
								ast.Model,
								asm.StklineNumber,
								asm.ControlNumber,
								ISNULL(cal.CalibrationDefaultVendorId,0) as VendorId,	
								V.VendorName as VendorName,	
								MSD.LastMSLevel,	
								MSD.AllMSlevels,asm.statusNote
							FROM dbo.AssetInventory asm WITH(NOLOCK)
								INNER JOIN Asset AS ast WITH(NOLOCK) ON ast.AssetRecordId=asm.AssetRecordId
								LEFT JOIN dbo.AssetAttributeType  As asty WITH(NOLOCK) on asm.TangibleClassId = asty.TangibleClassId
								LEFT JOIN dbo.AssetIntangibleType  As astI WITH(NOLOCK) on asm.AssetIntangibleTypeId = astI.AssetIntangibleTypeId
								LEFT JOIN dbo.Manufacturer  As maf WITH(NOLOCK) on asm.ManufacturerId = maf.ManufacturerId
								LEFT JOIN dbo.AssetCalibration as cal WITH(NOLOCK) on asm.AssetRecordId=cal.AssetRecordId and asm.CalibrationRequired=1	
								LEFT JOIN dbo.Vendor as V WITH(NOLOCK) on cal.CalibrationDefaultVendorId=V.VendorId	
								LEFT JOIN dbo.AssetManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleID,',')) AND MSD.ReferenceID = asm.AssetInventoryId	
								LEFT JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON asm.ManagementStructureId = RMS.EntityStructureId	
								LEFT JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId
							WHERE ((asm.IsDeleted = @IsDeleted) AND (@AssetInventoryIds IS NULL OR asm.AssetInventoryId IN (SELECT Item FROM DBO.SPLITSTRING(@AssetInventoryIds,',')))			     
							                                    AND (asm.MasterCompanyId = @MasterCompanyId) AND (@IsActive is null or ISNULL(asm.IsActive,1) = @IsActive))
																AND (EUR.EmployeeId IS NOT NULL AND EUR.EmployeeId = @EmployeeId)
					), ResultCount AS(SELECT COUNT(AssetInventoryId) AS totalItems FROM Result)
					SELECT * INTO #TempResult from  Result
					WHERE (
						(@GlobalFilter <> '' AND (
								(AssetId like '%' +@GlobalFilter+'%') OR
								(Name like '%' +@GlobalFilter+'%') OR
								(AlternateAssetId like '%' +@GlobalFilter+'%') OR
								(ManufacturerName like '%' +@GlobalFilter+'%') OR		
								(SerialNumber like '%' +@GlobalFilter+'%') OR
								(AssetClass like '%' +@GlobalFilter+'%') OR
								(CalibrationRequiredNew like '%'+@GlobalFilter+'%') OR
								(AssetType like '%' +@GlobalFilter+'%') OR
								(AssetClass like '%' +@GlobalFilter+'%') OR
								(InventoryNumber like '%' +@GlobalFilter+'%') OR
								(AssetStatus like '%' +@GlobalFilter+'%') OR
								(InventoryStatus like '%' +@GlobalFilter+'%') OR
								(CompanyName like '%' +@GlobalFilter+'%') OR
								(BuName like '%'+@GlobalFilter+'%') OR
								(DivName like '%' +@GlobalFilter+'%') OR
								(DeptName like '%' +@GlobalFilter+'%') OR
								(UpdatedBy like '%' +@GlobalFilter+'%') 
								))
							OR   
							(@GlobalFilter='' AND (ISNULL(@AssetId,'') ='' OR AssetId like '%' + @AssetId+'%') AND
								(ISNULL(@Name,'') ='' OR Name like '%' + @Name+'%') AND
								(ISNULL(@AlternateAssetId,'') ='' OR AlternateAssetId like '%' + @AlternateAssetId+'%') AND
								(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName like '%' + @ManufacturerName+'%') AND
								(ISNULL(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND
								(ISNULL(@CalibrationRequiredNew,'') ='' OR CalibrationRequiredNew like '%' + @CalibrationRequiredNew+'%') AND
								(ISNULL(@AssetStatus,'') ='' OR AssetStatus like '%' + @AssetStatus+'%') AND
								(ISNULL(@AssetType,'') ='' OR AssetType like '%' + @AssetType+'%') AND
								(ISNULL(@AssetClass,'') ='' OR AssetClass like '%' + @AssetClass+'%') AND
								(ISNULL(@InventoryNumber,'') ='' OR InventoryNumber like '%' + @InventoryNumber+'%') AND
								(ISNULL(@InventoryStatus,'') ='' OR InventoryStatus like '%' + @InventoryStatus+'%') AND
								(ISNULL(@CompanyName,'') ='' OR CompanyName like '%' + @CompanyName+'%') AND
								(ISNULL(@BuName,'') ='' OR BuName like '%' + @BuName+'%') AND
								(ISNULL(@DivName,'') ='' OR DivName like '%' + @DivName+'%') AND
								(ISNULL(@DeptName,'') ='' OR DeptName like '%' + @DeptName+'%') AND
								(ISNULL(@ManufacturerPN,'') ='' OR ManufacturerPN like '%' + @ManufacturerPN+'%') AND
								(ISNULL(@Model,'') ='' OR Model like '%' + @Model+'%') AND
								(ISNULL(@StklineNumber,'') ='' OR StklineNumber like '%' + @StklineNumber+'%') AND
								(ISNULL(@ControlNumber,'') ='' OR ControlNumber like '%' + @ControlNumber+'%') AND
								(ISNULL(@EntryDate,'') ='' OR Cast(EntryDate as Date)=Cast(@EntryDate as date)) AND
								(ISNULL(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND
								(ISNULL(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and
								(ISNULL(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND
								(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') 
								))
						
					SELECT @Count = COUNT(AssetInventoryId) from #TempResult			

					SELECT *, @Count As NumberOfItems FROM #TempResult
					ORDER BY  			
					CASE WHEN (@SortOrder=1 and @SortColumn='ASSETID')  THEN AssetId END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ASSETNAME')  THEN Name END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ALTERNATEASSETID')  THEN AlternateAssetId END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='MANUFACTURENAME')  THEN ManufacturerName END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='CALIBRATIONREQUIREDNEW')  THEN CalibrationRequiredNew END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ASSETCLASS')  THEN AssetClass END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerPN')  THEN ManufacturerPN END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='Model')  THEN Model END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='StklineNumber')  THEN StklineNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='AssetStatus')  THEN AssetStatus END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='InventoryNumber')  THEN InventoryNumber END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='InventoryStatus')  THEN InventoryStatus END ASC,

					CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETID')  THEN AssetId END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETNAME')  THEN Name END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ALTERNATEASSETID')  THEN AlternateAssetId END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='MANUFACTURENAME')  THEN ManufacturerName END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CALIBRATIONREQUIREDNEW')  THEN CalibrationRequiredNew END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETCLASS')  THEN AssetClass END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ASSETTYPE')  THEN AssetType END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END Desc,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerPN')  THEN ManufacturerPN END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='Model')  THEN Model END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='StklineNumber')  THEN StklineNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='AssetStatus')  THEN AssetStatus END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='InventoryNumber')  THEN InventoryNumber END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='InventoryStatus')  THEN InventoryStatus END DESC
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
													   @Parameter7 = ' + ISNULL(@AssetId,'') + ', 
													   @Parameter8 = ' + ISNULL(@Name,'') + ', 
													   @Parameter9 = ' + ISNULL(@AlternateAssetId,'') + ', 
													   @Parameter10 = ' + ISNULL(@ManufacturerName,'') + ', 
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
													   @Parameter25 = ' + ISNULL(@MasterCompanyId ,'') +',
													   @Parameter26 = ' + ISNULL(@ManufacturerPN ,'') +',
													   @Parameter27 = ' + ISNULL(@Model ,'') +',
													   @Parameter28 = ' + ISNULL(@StklineNumber  ,'') +',
													   @Parameter29 = ' + ISNULL(@ControlNumber  ,'') +',
													   '
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