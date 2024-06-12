
/*************************************************************           
 ** File:   [GetAssetInventoryList]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get list of Asset Inventory List   
 ** Purpose:         
 ** Date:    19/05/2023 
          
 ** PARAMETERS:    

 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    19/05/2023   Moin Bloch    Added WorkOrderNum Parameter To get WorkOrderNum  for check in status
	2    11/06/2024   Abhishek Jirawla Returning data in upper case
     
--  EXEC [GetAssetInventoryList] 
**************************************************************/

CREATE   PROCEDURE [dbo].[GetAssetInventoryList]
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
@WorkOrderNum varchar(50) = null,
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
@EmployeeId bigint=1,
@LastMSLevel varchar(50) = null 
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @RecordFrom INT;
		DECLARE @ModuleID VARCHAR(500) ='42,43'
		DECLARE @IsActive BIT = 1
		DECLARE @Count INT;
		DECLARE @AssetInventoryCheckInStatus INT = 4; 
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
			--BEGIN TRANSACTION
			--	BEGIN
						;With Result AS(
							SELECT	DISTINCT
								asm.AssetRecordId as AssetRecordId,
								AssetInventoryId = asm.AssetInventoryId,
								UPPER(asm.Name) AS Name,
								UPPER(asm.AssetId) AS AssetId,
								UPPER((SELECT TOP 1 AssetId FROM [dbo].[Asset] WITH (NOLOCK) WHERE AssetRecordId=asm.AlternateAssetRecordId)) AS AlternateAssetId,
								UPPER(maf.Name) AS ManufacturerName,
								UPPER(asm.SerialNo) AS SerialNumber,
								UPPER(CASE WHEN asm.IsSerialized = 1 THEN 'Yes'ELSE 'No' END) AS IsSerializedNew,
								UPPER(CASE WHEN asm.CalibrationRequired = 1 THEN 'Yes'ELSE 'No' END) AS CalibrationRequiredNew,
								UPPER(CASE WHEN asm.IsTangible = 1 THEN 'Tangible'ELSE 'Intangible' END) AS AssetClass,
								UPPER(ISNULL((CASE WHEN ISNULL(asm.IsTangible,0) = 1 and ISNULL(asm.IsDepreciable, 0) = 1 THEN 'Yes' when  ISNULL(asm.IsTangible,0) = 0 and ISNULL(asm.IsAmortizable,0)=1  THEN  'Yes'  ELSE 'No'  END),'No')) as deprAmort,
								UPPER(CASE WHEN ISNULL(asty.AssetAttributeTypeName,'') != '' THEN asty.AssetAttributeTypeName ELSE ISNULL(asti.AssetIntangibleName,'') END) AS AssetType, --case  when (SELECT top 1 AssetIntangibleName from AssetIntangibleType asp WHERE asp.AssetIntangibleTypeId = asm.AssetIntangibleTypeId),
								UPPER(asm.InventoryNumber) AS InventoryNumber,
								UPPER(asm.EntryDate) AS EntryDate,
								UPPER((SELECT TOP 1 [Name] FROM [dbo].[AssetStatus] WITH(NOLOCK) WHERE AssetStatusId = asm.AssetStatusId)) AS AssetStatus,
								UPPER((SELECT TOP 1 [Status] FROM [dbo].[AssetInventoryStatus]  WITH(NOLOCK) WHERE AssetInventoryStatusId = asm.InventoryStatusId)) AS InventoryStatus,
								UPPER(asm.InventoryStatusId) AS InventoryStatusId,
								UPPER(asm.level1) AS CompanyName,
								UPPER(asm.level2) AS BuName,
								UPPER(asm.level3) AS DivName,
								UPPER(asm.level4) AS DeptName,
								UPPER(asm.MasterCompanyId) AS MasterCompanyId,
								asm.CreatedDate AS CreatedDate,
								asm.UpdatedDate AS UpdatedDate,
								UPPER(asm.CreatedBy) AS CreatedBy,
								UPPER(asm.UpdatedBy) AS UpdatedBy ,
								asm.IsActive AS IsActive,
								asm.IsDeleted AS IsDeleted,
								UPPER(ast.ManufacturerPN) AS ManufacturerPN,
								UPPER(ast.Model) AS Model,
								UPPER(asm.StklineNumber) AS StklineNumber,
								UPPER(asm.ControlNumber) AS ControlNumber,
								ISNULL(cal.CalibrationDefaultVendorId,0) AS VendorId,	
								UPPER(V.VendorName) AS VendorName,	
								UPPER(MSD.LastMSLevel) AS LastMSLevel,	
								UPPER(MSD.AllMSlevels) AS AllMSlevels,
								UPPER(asm.statusNote) AS statusNote, 
								UPPER(awo.WorkOrderNum) AS WorkOrderNum
							FROM [dbo].[AssetInventory] asm WITH(NOLOCK)
								INNER JOIN [dbo].[Asset] AS ast WITH(NOLOCK) ON ast.AssetRecordId=asm.AssetRecordId
								LEFT JOIN  [dbo].[CheckInCheckOutWorkOrderAsset] aci WITH(NOLOCK) ON aci.AssetInventoryId = asm.AssetInventoryId AND aci.InventoryStatusId = @AssetInventoryCheckInStatus
								LEFT JOIN  [dbo].[WorkOrder] awo WITH(NOLOCK) ON awo.WorkOrderId = aci.WorkOrderId
								LEFT JOIN  [dbo].[AssetAttributeType] asty WITH(NOLOCK) ON ast.AssetAttributeTypeId = asty.AssetAttributeTypeId
								LEFT JOIN  [dbo].[AssetIntangibleType]  AS astI WITH(NOLOCK) ON ast.AssetIntangibleTypeId = astI.AssetIntangibleTypeId
								LEFT JOIN  [dbo].[Manufacturer]  AS maf WITH(NOLOCK) ON asm.ManufacturerId = maf.ManufacturerId
								LEFT JOIN  [dbo].[AssetCalibration] as cal WITH(NOLOCK) ON asm.AssetRecordId=cal.AssetRecordId and asm.CalibrationRequired=1	
								LEFT JOIN  [dbo].[Vendor] AS V WITH(NOLOCK) ON cal.CalibrationDefaultVendorId=V.VendorId	
								LEFT JOIN  [dbo].[AssetManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleID,',')) AND MSD.ReferenceID = asm.AssetInventoryId	
								LEFT JOIN  [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON asm.ManagementStructureId = RMS.EntityStructureId	
								LEFT JOIN  [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId
							WHERE ((asm.IsDeleted = @IsDeleted) AND (@AssetInventoryIds IS NULL OR asm.AssetInventoryId IN (SELECT Item FROM DBO.SPLITSTRING(@AssetInventoryIds,',')))			     
							                                    AND (asm.MasterCompanyId = @MasterCompanyId) AND (@IsActive IS NULL OR ISNULL(asm.IsActive,1) = @IsActive))
																AND (EUR.EmployeeId IS NOT NULL AND EUR.EmployeeId = @EmployeeId)
					), ResultCount AS(SELECT COUNT(AssetInventoryId) AS totalItems FROM Result)
					SELECT * INTO #TempResult from  Result
					WHERE (
						(@GlobalFilter <> '' AND (
								(AssetId LIKE '%' +@GlobalFilter+'%') OR
								(Name LIKE '%' +@GlobalFilter+'%') OR
								(AlternateAssetId LIKE '%' +@GlobalFilter+'%') OR
								(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR		
								(SerialNumber LIKE '%' +@GlobalFilter+'%') OR
								(AssetClass LIKE '%' +@GlobalFilter+'%') OR
								(CalibrationRequiredNew LIKE '%'+@GlobalFilter+'%') OR
								(AssetType LIKE '%' +@GlobalFilter+'%') OR
								(AssetClass LIKE '%' +@GlobalFilter+'%') OR
								(InventoryNumber LIKE '%' +@GlobalFilter+'%') OR
								(WorkOrderNum LIKE '%' +@GlobalFilter+'%') OR								
								(AssetStatus LIKE '%' +@GlobalFilter+'%') OR
								(InventoryStatus LIKE '%' +@GlobalFilter+'%') OR
								(CompanyName LIKE '%' +@GlobalFilter+'%') OR
								(BuName LIKE '%'+@GlobalFilter+'%') OR
								(DivName LIKE '%' +@GlobalFilter+'%') OR
								(DeptName LIKE '%' +@GlobalFilter+'%') OR
								(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
								(LastMSLevel LIKE '%' +@GlobalFilter+'%')
								))
							OR   
							(@GlobalFilter='' AND (ISNULL(@AssetId,'') ='' OR AssetId LIKE '%' + @AssetId+'%') AND
								(ISNULL(@Name,'') ='' OR Name LIKE '%' + @Name+'%') AND
								(ISNULL(@AlternateAssetId,'') ='' OR AlternateAssetId LIKE '%' + @AlternateAssetId+'%') AND
								(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName+'%') AND
								(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber+'%') AND
								(ISNULL(@CalibrationRequiredNew,'') ='' OR CalibrationRequiredNew LIKE '%' + @CalibrationRequiredNew+'%') AND
								(ISNULL(@AssetStatus,'') ='' OR AssetStatus LIKE '%' + @AssetStatus+'%') AND
								(ISNULL(@AssetType,'') ='' OR AssetType LIKE '%' + @AssetType+'%') AND
								(ISNULL(@AssetClass,'') ='' OR AssetClass LIKE '%' + @AssetClass+'%') AND
								(ISNULL(@InventoryNumber,'') ='' OR InventoryNumber LIKE '%' + @InventoryNumber+'%') AND
								(ISNULL(@WorkOrderNum,'') ='' OR WorkOrderNum LIKE '%' + @WorkOrderNum+'%') AND			
								(ISNULL(@InventoryStatus,'') ='' OR InventoryStatus LIKE '%' + @InventoryStatus+'%') AND													
								(ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName+'%') AND
								(ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName+'%') AND
								(ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName+'%') AND
								(ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName+'%') AND
								(ISNULL(@ManufacturerPN,'') ='' OR ManufacturerPN LIKE '%' + @ManufacturerPN+'%') AND
								(ISNULL(@Model,'') ='' OR Model like '%' + @Model+'%') AND
								(ISNULL(@StklineNumber,'') ='' OR StklineNumber LIKE '%' + @StklineNumber+'%') AND
								(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber+'%') AND
								(ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE)=CAST(@EntryDate AS DATE)) AND
								(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND
								(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)) AND
								(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND
								(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND
								(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel+'%') 
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
					CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,					
					CASE WHEN (@SortOrder=1 and @SortColumn='InventoryStatus')  THEN InventoryStatus END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,

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
					CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,		
					CASE WHEN (@SortOrder=-1 and @SortColumn='InventoryStatus')  THEN InventoryStatus END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
				--END
			--COMMIT  TRANSACTION

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