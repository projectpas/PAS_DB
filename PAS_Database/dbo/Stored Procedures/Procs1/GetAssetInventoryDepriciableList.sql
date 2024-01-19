
/*************************************************************           
 ** File:   [GetAssetInventoryDepriciableList]           
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used GetAssetInventoryDepriciableList
 ** Purpose:         
 ** Date:   01/23/2023      
 ** PARAMETERS: @JournalBatchHeaderId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/23/2023  Subhash Saliya     Created
	2    08/10/2023  Moin Bloch         Format SP And Added WITH (NOLOCK)
	
   EXEC [dbo].[GetAssetInventoryDepriciableList] 10406,1,'150.00','AssetInventory','admin',1,'AssetWriteOff',0
************************************************************************/
CREATE   PROCEDURE [dbo].[GetAssetInventoryDepriciableList]
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
@EmployeeId bigint=1,
@InstalledCost decimal,
@InServiceDate decimal,
@DepreciableStatus varchar(50) = null,
@DepreciationAmount decimal,
@AccumlatedDepr decimal,
@NetBookValue decimal,
@NBVAfterDepreciation decimal,
@DepreciableLife bigint,
@DepreciationFrequencyName varchar(50) = null,
@Currency varchar(50) = null,
@DepreciationMethod varchar(50) = null
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @RecordFrom INT;
		DECLARE @ModuleID VARCHAR(500) ='42,43'
		DECLARE @IsActive BIT = 1
		DECLARE @Count INT;
		DECLARE @AssetStatusid INT;
		DECLARE @QtrDays INT =90;
		DECLARE @YearDays INT =365;
		DECLARE @DeprFrequencyMonthly VARCHAR(50) ='MTHLY,MONTHLY'
		DECLARE @DeprFrequencyQUATERLY VARCHAR(50) ='QUATERLY,QTLY'
		DECLARE @DeprFrequencyYEARLY VARCHAR(50) ='YEARLY,YRLY'
		SELECT TOP 1  @AssetStatusid = [AssetStatusid] FROM [dbo].[AssetStatus] WITH (NOLOCK)  WHERE UPPER([name]) ='DEPRECIATING' AND [MasterCompanyId] = @MasterCompanyId
		
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted = 0
		END
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			SET @SortColumn = UPPER(@SortColumn)
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
				BEGIN
						;With Result AS(
						SELECT	asm.AssetRecordId AS AssetRecordId,
								AssetInventoryId = asm.AssetInventoryId,
								asm.[Name], 
								asm.AssetId,
								(SELECT TOP 1 [AssetId] FROM [dbo].[Asset] WITH (NOLOCK) WHERE AssetRecordId = asm.AlternateAssetRecordId) AS AlternateAssetId,
								maf.[Name] AS ManufacturerName,
								SerialNumber = asm.SerialNo,
								CASE WHEN asm.IsSerialized = 1 THEN 'Yes'ELSE 'No' END AS IsSerializedNew,
								CASE WHEN asm.CalibrationRequired = 1 THEN 'Yes'ELSE 'No' END AS CalibrationRequiredNew,
								CASE WHEN asm.IsTangible = 1 THEN 'Tangible'ELSE 'Intangible' END AS AssetClass,
								ISNULL((CASE WHEN ISNULL(asm.IsTangible,0) = 1 AND ISNULL(asm.IsDepreciable, 0) = 1 THEN 'Yes' WHEN  ISNULL(asm.IsTangible,0) = 0 AND ISNULL(asm.IsAmortizable,0)=1  THEN  'Yes'  ELSE 'No'  END),'No') AS deprAmort,
								AssetType = CASE WHEN ISNULL(asty.AssetAttributeTypeName,'') != '' THEN asty.AssetAttributeTypeName ELSE ISNULL(asti.AssetIntangibleName,'') END, --case  when (SELECT top 1 AssetIntangibleName from AssetIntangibleType asp WHERE asp.AssetIntangibleTypeId = asm.AssetIntangibleTypeId),
								InventoryNumber = asm.InventoryNumber,
								EntryDate = asm.EntryDate,
								AssetStatus = (SELECT TOP 1 [Name] FROM [dbo].[AssetStatus] WITH(NOLOCK) WHERE AssetStatusId = asm.AssetStatusId),
								InventoryStatus = (SELECT TOP 1 [Status] FROM [dbo].[AssetInventoryStatus] WITH(NOLOCK) WHERE [AssetInventoryStatusId] = asm.[InventoryStatusId]),
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
								ISNULL(cal.CalibrationDefaultVendorId,0) AS VendorId,	
								V.VendorName AS VendorName,	
								MSD.LastMSLevel,	
								MSD.AllMSlevels,
								MSD.EntityMSID,
								asm.statusNote,

								ASM.TotalCost as InstalledCost,
								ASM.ReceivedDate as InServiceDate,
								'Depreciating' as DepreciableStatus,
								
								ASM.AssetLife as DepreciableLife,
								ASM.DepreciationFrequencyName,
								CURR.Code as Currency,
								ASM.DepreciationMethodName as DepreciationMethod,
								asm.ResidualPercentage,

								A.AccountingCalenderId

							FROM [dbo].[AssetInventory] asm WITH(NOLOCK)
								INNER JOIN [dbo].[Asset] AS ast WITH(NOLOCK) ON ast.AssetRecordId=asm.AssetRecordId								
								 LEFT JOIN [dbo].[AssetAttributeType] asty WITH(NOLOCK) ON ast.AssetAttributeTypeId = asty.AssetAttributeTypeId
								 LEFT JOIN [dbo].[AssetIntangibleType]  astI WITH(NOLOCK) ON ast.AssetIntangibleTypeId = astI.AssetIntangibleTypeId
								 LEFT JOIN [dbo].[Manufacturer]  maf WITH(NOLOCK) ON asm.ManufacturerId = maf.ManufacturerId
								 LEFT JOIN [dbo].[AssetCalibration] cal WITH(NOLOCK) ON asm.AssetRecordId=cal.AssetRecordId AND asm.CalibrationRequired = 1	
								 LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON cal.CalibrationDefaultVendorId=V.VendorId	
								 LEFT JOIN [dbo].[AssetManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleID,',')) AND MSD.ReferenceID = asm.AssetInventoryId	
								 LEFT JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON asm.ManagementStructureId = RMS.EntityStructureId	
								 LEFT JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId
								 LEFT JOIN [dbo].Currency CURR WITH (NOLOCK) ON CURR.CurrencyId = ASM.CurrencyId
								 -- INNER JOIN [dbo].AssetDepreciationHistory ADH WITH (NOLOCK) ON ADH.AssetInventoryId = ASM.AssetInventoryId

								 OUTER APPLY      
									 (      
										SELECT TOP 1 ADH.AccountingCalenderId AS 'AccountingCalenderId'			           
										 FROM [dbo].AssetDepreciationHistory ADH WITH (NOLOCK)      			
										 WHERE ADH.AssetInventoryId = ASM.AssetInventoryId 
										 ORDER BY ADH.ID DESC
									 ) A


							WHERE (((asm.DepreciationFrequencyName IN (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyMonthly,',')) AND (CONVERT(VARCHAR(6), GETUTCDATE(), 112) != CONVERT(VARCHAR(6), asm.EntryDate, 112)) ) OR
							        (asm.DepreciationFrequencyName IN (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyQUATERLY,',')) AND (ABS(CAST((DATEDIFF(MONTH, CAST(asm.EntryDate AS DATE),CAST(GETUTCDATE() AS DATE)))  AS INT)) % 3 =0))  OR
									(asm.DepreciationFrequencyName IN (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyYEARLY,',')) AND  (ABS(CAST((DATEDIFF(MONTH, CAST(asm.EntryDate AS DATE),CAST(GETUTCDATE() AS DATE)))  AS INT)) % 12 =0))) 
							                                    AND ((DATEDIFF(MONTH, CAST(asm.EntryDate AS DATE),CAST(GETUTCDATE() AS DATE))) <= asm.AssetLife)
																AND (asm.IsDeleted = @IsDeleted) 
																AND (asm.InventoryStatusId = 1) 
																AND (asm.IsTangible = 1) 
																AND (asm.IsDepreciable = 1) 
																AND (asm.AssetStatusId = @AssetStatusid) 			     
							                                    AND (asm.MasterCompanyId = @MasterCompanyId) 
																AND (@IsActive IS NULL OR ISNULL(asm.IsActive,1) = @IsActive))
																AND (EUR.EmployeeId IS NOT NULL AND EUR.EmployeeId = @EmployeeId)
					), ResultCount AS(SELECT COUNT(AssetInventoryId) AS totalItems FROM Result)
					SELECT * INTO #TempResult FROM  Result
					WHERE (
						(@GlobalFilter <> '' AND (
								(AssetId LIKE '%' +@GlobalFilter+'%') OR
								([Name] LIKE '%' +@GlobalFilter+'%') OR
								(AlternateAssetId LIKE '%' +@GlobalFilter+'%') OR
								(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR		
								(SerialNumber LIKE '%' +@GlobalFilter+'%') OR
								(AssetClass LIKE '%' +@GlobalFilter+'%') OR
								(CalibrationRequiredNew LIKE '%'+@GlobalFilter+'%') OR
								(AssetType LIKE '%' +@GlobalFilter+'%') OR
								(AssetClass LIKE '%' +@GlobalFilter+'%') OR
								(InventoryNumber LIKE '%' +@GlobalFilter+'%') OR
								(AssetStatus LIKE '%' +@GlobalFilter+'%') OR
								(InventoryStatus LIKE '%' +@GlobalFilter+'%') OR
								(CompanyName LIKE '%' +@GlobalFilter+'%') OR
								(BuName LIKE '%'+@GlobalFilter+'%') OR
								(DivName LIKE '%' +@GlobalFilter+'%') OR
								(DeptName LIKE '%' +@GlobalFilter+'%') OR
								(UpdatedBy LIKE '%' +@GlobalFilter+'%') 
								))
							OR   
							(@GlobalFilter='' AND (ISNULL(@AssetId,'') ='' OR AssetId LIKE '%' + @AssetId+'%') AND
								(ISNULL(@Name,'') ='' OR [Name] LIKE '%' + @Name+'%') AND
								(ISNULL(@AlternateAssetId,'') ='' OR AlternateAssetId LIKE '%' + @AlternateAssetId+'%') AND
								(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName+'%') AND
								(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber+'%') AND
								(ISNULL(@CalibrationRequiredNew,'') ='' OR CalibrationRequiredNew LIKE '%' + @CalibrationRequiredNew+'%') AND
								(ISNULL(@AssetStatus,'') ='' OR AssetStatus LIKE '%' + @AssetStatus+'%') AND
								(ISNULL(@AssetType,'') ='' OR AssetType LIKE '%' + @AssetType+'%') AND
								(ISNULL(@AssetClass,'') ='' OR AssetClass LIKE '%' + @AssetClass+'%') AND
								(ISNULL(@InventoryNumber,'') ='' OR InventoryNumber LIKE '%' + @InventoryNumber+'%') AND
								(ISNULL(@InventoryStatus,'') ='' OR InventoryStatus LIKE '%' + @InventoryStatus+'%') AND
								(ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName+'%') AND
								(ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName+'%') AND
								(ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName+'%') AND
								(ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName+'%') AND
								(ISNULL(@ManufacturerPN,'') ='' OR ManufacturerPN LIKE '%' + @ManufacturerPN+'%') AND
								(ISNULL(@Model,'') ='' OR Model LIKE '%' + @Model+'%') AND
								(ISNULL(@StklineNumber,'') ='' OR StklineNumber LIKE '%' + @StklineNumber+'%') AND
								(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber+'%') AND
								(ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND
								(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND
								(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) and
								(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND
								(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') 
								))
						
					SELECT @Count = COUNT(AssetInventoryId) FROM #TempResult			

					SELECT *, @Count AS NumberOfItems FROM #TempResult
					ORDER BY  			
					CASE WHEN (@SortOrder=1 AND @SortColumn='ASSETID')  THEN AssetId END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='ASSETNAME')  THEN Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='ALTERNATEASSETID')  THEN AlternateAssetId END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='MANUFACTURENAME')  THEN ManufacturerName END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='CALIBRATIONREQUIREDNEW')  THEN CalibrationRequiredNew END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='ASSETCLASS')  THEN AssetClass END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='ASSETTYPE')  THEN AssetType END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='ManufacturerPN')  THEN ManufacturerPN END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='Model')  THEN Model END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='StklineNumber')  THEN StklineNumber END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='AssetStatus')  THEN AssetStatus END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='InventoryNumber')  THEN InventoryNumber END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='InventoryStatus')  THEN InventoryStatus END ASC,

					CASE WHEN (@SortOrder=-1 AND @SortColumn='ASSETID')  THEN AssetId END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='ASSETNAME')  THEN Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='ALTERNATEASSETID')  THEN AlternateAssetId END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='MANUFACTURENAME')  THEN ManufacturerName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='CALIBRATIONREQUIREDNEW')  THEN CalibrationRequiredNew END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='ASSETCLASS')  THEN AssetClass END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='ASSETTYPE')  THEN AssetType END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerPN')  THEN ManufacturerPN END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='Model')  THEN Model END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='StklineNumber')  THEN StklineNumber END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='AssetStatus')  THEN AssetStatus END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='InventoryNumber')  THEN InventoryNumber END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='InventoryStatus')  THEN InventoryStatus END DESC
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
				END
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