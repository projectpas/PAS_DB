
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
	3    03/26/2024  Abhishek Jirawla   Added distinct in the SP
	4    04/08/2024  Abhishek Jirawla   Added Selected Accounting Period Id to the sp
	5    06/27/2024  Abhishek Jirawla   Returning Capital for export
	6    07/16/2024  Devendra Shekh		Added lastDeprRunPeriod to List
	
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
@InstalledCost varchar(30) = null,
@InServiceDate datetime = null,
@DepreciableStatus varchar(50) = null,
@DepreciationAmount varchar(30) = null,
@AccumlatedDepr varchar(30) = null,
@NetBookValue varchar(30) = null,
@NBVAfterDepreciation varchar(30),
@DepreciableLife varchar(30) = null,
@DepreciationFrequencyName varchar(50) = null,
@Currency varchar(50) = null,
@DepreciationMethod varchar(50) = null,
@LegalentityId varchar(500) = null,
@LastMSLevel varchar(50) = null,
@SelectedAccountingPeriodId int = null,
@LastDeprRunPeriod varchar(30) = null
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
		DECLARE @ReduceResidualPerc DECIMAL(18,2);
		DECLARE @ResidualPercentage DECIMAL(18,2);
		DECLARE @LastDateOfSelectedAccountingPeriod Date = NULL;
		DECLARE @CurrentDateAccountingPeriod VARCHAR(200) = NULL;

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

		IF @SelectedAccountingPeriodId IS NOT NULL OR @SelectedAccountingPeriodId <> 0
		BEGIN
			SELECT @LastDateOfSelectedAccountingPeriod = ToDate FROM AccountingCalendar WHERE AccountingCalendarId = @SelectedAccountingPeriodId;
		END
		ELSE
		BEGIN
			SELECT @CurrentDateAccountingPeriod = STRING_AGG(AccountingCalendarId, ',') FROM AccountingCalendar WHERE (IsDeleted = 0) AND (GETUTCDATE() BETWEEN FromDate AND ToDate);
		END

		BEGIN TRY
			--BEGIN TRANSACTION
				BEGIN
				
					;With Result AS(
						SELECT DISTINCT	asm.AssetRecordId AS AssetRecordId,
								AssetInventoryId = asm.AssetInventoryId,
								UPPER(asm.[Name]) as Name, 
								UPPER(asm.AssetId) as AssetId,
								(SELECT TOP 1 UPPER([AssetId]) AS AssetId FROM [dbo].[Asset] WITH (NOLOCK) WHERE AssetRecordId = asm.AlternateAssetRecordId) AS AlternateAssetId,
								UPPER(maf.[Name]) AS ManufacturerName,
								SerialNumber = UPPER(asm.SerialNo),
								UPPER(CASE WHEN asm.IsSerialized = 1 THEN 'Yes'ELSE 'No' END) AS IsSerializedNew,
								UPPER(CASE WHEN asm.CalibrationRequired = 1 THEN 'Yes'ELSE 'No' END) AS CalibrationRequiredNew,
								UPPER(CASE WHEN asm.IsTangible = 1 THEN 'Tangible'ELSE 'Intangible' END) AS AssetClass,
								UPPER(ISNULL((CASE WHEN ISNULL(asm.IsTangible,0) = 1 AND ISNULL(asm.IsDepreciable, 0) = 1 THEN 'Yes' WHEN  ISNULL(asm.IsTangible,0) = 0 AND ISNULL(asm.IsAmortizable,0)=1  THEN  'Yes'  ELSE 'No'  END),'No')) AS deprAmort,
								AssetType = UPPER(CASE WHEN ISNULL(asty.AssetAttributeTypeName,'') != '' THEN asty.AssetAttributeTypeName ELSE ISNULL(asti.AssetIntangibleName,'') END), --case  when (SELECT top 1 AssetIntangibleName from AssetIntangibleType asp WHERE asp.AssetIntangibleTypeId = asm.AssetIntangibleTypeId),
								InventoryNumber = UPPER(asm.InventoryNumber),
								EntryDate = UPPER(asm.EntryDate),
								AssetStatus = (SELECT TOP 1 UPPER([Name]) AS Name FROM [dbo].[AssetStatus] WITH(NOLOCK) WHERE AssetStatusId = asm.AssetStatusId),
								InventoryStatus = (SELECT TOP 1 UPPER([Status]) AS Status FROM [dbo].[AssetInventoryStatus] WITH(NOLOCK) WHERE [AssetInventoryStatusId] = asm.[InventoryStatusId]),
								UPPER(asm.InventoryStatusId) AS InventoryStatusId,
								UPPER(asm.level1) AS CompanyName,
								UPPER(asm.level2) AS BuName,
								UPPER(asm.level3) AS DivName,
								UPPER(asm.level4) AS DeptName,
								asm.MasterCompanyId AS MasterCompanyId,
								asm.CreatedDate AS CreatedDate,
								asm.UpdatedDate AS UpdatedDate,
								UPPER(asm.CreatedBy) AS CreatedBy,
								UPPER(asm.UpdatedBy) AS UpdatedBy,
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
								UPPER(MSD.EntityMSID) AS EntityMSID,
								UPPER(asm.statusNote) AS statusNote,

								ASM.TotalCost as InstalledCost,
								ASM.DepreciationStartDate as InServiceDate,
								'DEPRECIATING' as DepreciableStatus,
								
								ASM.AssetLife as DepreciableLife,
								UPPER(ASM.DepreciationFrequencyName) AS DepreciationFrequencyName,
								UPPER(CURR.Code) as Currency,
								UPPER(ASM.DepreciationMethodName) as DepreciationMethod,
								asm.ResidualPercentage,

								A.AccountingCalenderId,
								B.DepreciationAmount,
								B.AccumlatedDepr,
								B.NetBookValue,
								B.NBVAfterDepreciation,
								B.LastDeprRunPeriod

							FROM [dbo].[AssetInventory] asm WITH(NOLOCK)
								INNER JOIN [dbo].[Asset] AS ast WITH(NOLOCK) ON ast.AssetRecordId=asm.AssetRecordId								
								 LEFT JOIN [dbo].[AssetAttributeType] asty WITH(NOLOCK) ON ast.AssetAttributeTypeId = asty.AssetAttributeTypeId
								 LEFT JOIN [dbo].[AssetIntangibleType]  astI WITH(NOLOCK) ON ast.AssetIntangibleTypeId = astI.AssetIntangibleTypeId
								 LEFT JOIN [dbo].[Manufacturer]  maf WITH(NOLOCK) ON asm.ManufacturerId = maf.ManufacturerId
								 LEFT JOIN [dbo].[AssetCalibration] cal WITH(NOLOCK) ON asm.AssetRecordId=cal.AssetRecordId AND asm.CalibrationRequired = 1	
								 LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON cal.CalibrationDefaultVendorId=V.VendorId
								 LEFT JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON asm.ManagementStructureId = RMS.EntityStructureId	
								 LEFT JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId
								 LEFT JOIN [dbo].Currency CURR WITH (NOLOCK) ON CURR.CurrencyId = ASM.CurrencyId
								 --INNER JOIN [dbo].LegalEntity LE WITH (NOLOCK) ON LE.LegalEntityId IN (SELECT Item FROM DBO.SPLITSTRING(@LegalentityId,','))
								 --INNER JOIN ManagementStructureLevel MSL on LE.LegalEntityId = MSL.LegalEntityId
								 --INNER JOIN [dbo].[AssetManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleID,',')) AND MSD.Level1Id = MSL.ID AND MSD.ReferenceID = asm.AssetInventoryId	
								LEFT JOIN [dbo].[AssetManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@ModuleID,',')) AND MSD.ReferenceID = asm.AssetInventoryId	
								LEFT JOIN [dbo].EntityStructureSetup ES ON ES.EntityStructureId = MSD.EntityMSID  
								LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
								LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
								LEFT JOIN [dbo].AssetDepreciationMonthRemoval admr WITH(NOLOCK) ON admr.AssetInventoryId = asm.AssetInventoryId AND (AccountingCalenderId IN (@SelectedAccountingPeriodId) OR AccountingCalenderId IN (SELECT Item FROM DBO.SPLITSTRING(@CurrentDateAccountingPeriod,',')))
									OUTER APPLY      
									 (      
										SELECT DISTINCT STRING_AGG(ISNULL(ADH.AccountingCalenderId,0), ',')  AS 'AccountingCalenderId'
										 FROM [dbo].AssetDepreciationHistory ADH WITH (NOLOCK)      			
										 WHERE ADH.AssetInventoryId = ASM.AssetInventoryId 
									 ) A

									 OUTER APPLY      
									 (      
										SELECT TOP 1 ADH.DepreciationAmount,
														ADH.AccumlatedDepr,
														ADH.NetBookValue,
														ADH.NBVAfterDepreciation,
														ADH.LastDeprRunPeriod
										 FROM [dbo].AssetDepreciationHistory ADH WITH (NOLOCK)      			
										 WHERE ADH.AssetInventoryId = ASM.AssetInventoryId 
										 ORDER BY ADH.ID DESC
									 ) B


							WHERE (((asm.DepreciationFrequencyName IN (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyMonthly,',')) AND (CONVERT(VARCHAR(6), ISNULL(@LastDateOfSelectedAccountingPeriod, GETUTCDATE()), 112) != CONVERT(VARCHAR(6), asm.EntryDate, 112)) ) OR
							        (asm.DepreciationFrequencyName IN (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyQUATERLY,',')) AND (ABS(CAST((DATEDIFF(MONTH, CAST(asm.EntryDate AS DATE),CAST(ISNULL(@LastDateOfSelectedAccountingPeriod, GETUTCDATE()) AS DATE)))  AS INT)) % 3 =0))  OR
									(asm.DepreciationFrequencyName IN (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyYEARLY,',')) AND  (ABS(CAST((DATEDIFF(MONTH, CAST(asm.EntryDate AS DATE),CAST(ISNULL(@LastDateOfSelectedAccountingPeriod, GETUTCDATE()) AS DATE)))  AS INT)) % 12 =0))) 
							                                    AND ((DATEDIFF(MONTH, CAST(asm.EntryDate AS DATE),CAST(ISNULL(@LastDateOfSelectedAccountingPeriod, GETUTCDATE()) AS DATE))) <= asm.AssetLife)
																-- AND (B.NetBookValue IS NOT NULL AND B.NetBookValue > ASM.ResidualPercentage)
																-- AND (B.NetBookValue IS NULL OR ISNULL(B.NetBookValue,0) > ASM.ResidualPercentage)
																AND (asm.IsDeleted = @IsDeleted) 
																AND (asm.InventoryStatusId = 1) 
																AND (asm.IsTangible = 1) 
																AND (asm.IsDepreciable = 1) 
																AND (asm.AssetStatusId = @AssetStatusid) 			     
							                                    AND (asm.MasterCompanyId = @MasterCompanyId) 
																AND (@IsActive IS NULL OR ISNULL(asm.IsActive,1) = @IsActive))
																AND (admr.AssetInventoryId IS NULL)
																AND (EUR.EmployeeId IS NOT NULL AND EUR.EmployeeId = @EmployeeId)
																AND (LE.LegalEntityId IN (SELECT Item FROM DBO.SPLITSTRING(@LegalentityId,',')))
																AND ( ASM.DepreciationStartDate <= CAST(ISNULL(@LastDateOfSelectedAccountingPeriod, GETUTCDATE()) AS DATE) )
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

								 (cast(InstalledCost as varchar(10)) LIKE '%' +@GlobalFilter+'%')  OR 
								-- (cast(InServiceDate as nvarchar(10)) LIKE '%' +@GlobalFilter+'%') OR
								(CAST(DepreciationAmount as varchar(10)) LIKE '%' +@GlobalFilter+'%') OR 
								(CAST(AccumlatedDepr as varchar(10)) LIKE '%' +@GlobalFilter+'%') OR 
								(cast(NetBookValue as varchar(10)) LIKE '%' +@GlobalFilter+'%') OR 
								(cast(NBVAfterDepreciation as varchar(10)) LIKE '%' +@GlobalFilter+'%') OR
								(DepreciableStatus LIKE '%' +@GlobalFilter+'%') OR 
								(cast(DepreciableLife as varchar(10)) LIKE '%' +@GlobalFilter+'%') OR 
								(Currency LIKE '%' +@GlobalFilter+'%') OR 
								(DepreciationFrequencyName LIKE '%' +@GlobalFilter+'%') OR 
								(DepreciationMethod LIKE '%' +@GlobalFilter+'%') OR
								(LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
								(LastDeprRunPeriod LIKE '%' +@GlobalFilter+'%')
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
								(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%')  AND
								
								 (ISNULL(@DepreciationAmount,'') ='' OR cast(DepreciationAmount as varchar(10)) LIKE '%' + @DepreciationAmount+'%') AND
								 (ISNULL(@AccumlatedDepr,'') ='' OR cast(AccumlatedDepr as varchar(10)) LIKE '%' + @AccumlatedDepr+'%') AND
								(ISNULL(@NetBookValue,'') ='' OR cast(NetBookValue as varchar(10)) LIKE '%' + @NetBookValue+'%') AND
								(ISNULL(@NBVAfterDepreciation,'') ='' OR cast(NBVAfterDepreciation as varchar(10)) LIKE '%' + @NBVAfterDepreciation+'%') AND
								(ISNULL(@InServiceDate,'') ='' OR CAST(InServiceDate AS DATE) = CAST(@InServiceDate AS DATE)) AND --  
								(ISNULL(@DepreciableStatus,'') ='' OR DepreciableStatus LIKE '%' + @DepreciableStatus+'%') AND
								(ISNULL(@DepreciableLife,'') ='' OR cast(DepreciableLife as varchar(10)) LIKE '%' + @DepreciableLife+'%') AND
								(ISNULL(@Currency,'') ='' OR Currency LIKE '%' + @Currency+'%') AND
								(ISNULL(@DepreciationFrequencyName,'') ='' OR DepreciationFrequencyName LIKE '%' + @DepreciationFrequencyName+'%') AND
								(ISNULL(@DepreciationMethod,'') ='' OR DepreciationMethod LIKE '%' + @DepreciationMethod+'%') AND
								(ISNULL(@InstalledCost,'') ='' OR cast(InstalledCost as varchar(10)) LIKE '%' + @InstalledCost+'%') AND
								(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel LIKE '%' + @LastMSLevel+'%') AND
								(ISNULL(@LastDeprRunPeriod,'') ='' OR LastDeprRunPeriod LIKE '%' + @LastDeprRunPeriod+'%') 
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
					
					CASE WHEN (@SortOrder=1 AND @SortColumn='DepreciationAmount')  THEN DepreciationAmount END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='AccumlatedDepr')  THEN AccumlatedDepr END ASC,					
					CASE WHEN (@SortOrder=1 AND @SortColumn='NetBookValue')  THEN NetBookValue END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='NBVAfterDepreciation')  THEN NBVAfterDepreciation END ASC,					
					CASE WHEN (@SortOrder=1 AND @SortColumn='DepreciableStatus')  THEN DepreciableStatus END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='DepreciableLife')  THEN DepreciableLife END ASC,					
					CASE WHEN (@SortOrder=1 AND @SortColumn='Currency')  THEN Currency END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='DepreciationFrequencyName')  THEN DepreciationFrequencyName END ASC,					
					CASE WHEN (@SortOrder=1 AND @SortColumn='DepreciationMethod')  THEN DepreciationMethod END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='InstalledCost')  THEN InstalledCost END ASC,	
					CASE WHEN (@SortOrder=1 AND @SortColumn='InServiceDate')  THEN InServiceDate END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END ASC,
					CASE WHEN (@SortOrder=1 and @SortColumn='LastDeprRunPeriod')  THEN LastDeprRunPeriod END ASC,

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
					CASE WHEN (@SortOrder=-1 AND @SortColumn='InventoryStatus')  THEN InventoryStatus END DESC ,	
					
					CASE WHEN (@SortOrder=-1 AND @SortColumn='DepreciationAmount')  THEN DepreciationAmount END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='AccumlatedDepr')  THEN AccumlatedDepr END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='NetBookValue')  THEN NetBookValue END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='NBVAfterDepreciation')  THEN NBVAfterDepreciation END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='DepreciableStatus')  THEN DepreciableStatus END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='DepreciableLife')  THEN DepreciableLife END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='Currency')  THEN Currency END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='DepreciationFrequencyName')  THEN DepreciationFrequencyName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='DepreciationMethod')  THEN DepreciationMethod END DESC,					
					CASE WHEN (@SortOrder=-1 AND @SortColumn='InstalledCost')  THEN InstalledCost END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='InServiceDate')  THEN InServiceDate END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LastMSLevel')  THEN LastMSLevel END DESC,
					CASE WHEN (@SortOrder=-1 and @SortColumn='LastDeprRunPeriod')  THEN LastDeprRunPeriod END DESC

					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
				END
			--COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;

					SELECT
						ERROR_NUMBER() AS ErrorNumber,
						ERROR_STATE() AS ErrorState,
						ERROR_SEVERITY() AS ErrorSeverity,
						ERROR_PROCEDURE() AS ErrorProcedure,
						ERROR_LINE() AS ErrorLine,
						ERROR_MESSAGE() AS ErrorMessage;

					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetAssetInventoryDepriciableList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageSize  , '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageNumber,'') + ', 
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