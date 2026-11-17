-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <10-JAN-2024>
-- Description:	<This SP to get all the Asset Register Reports>
-- =============================================
/*************************************************************           
 ** File:   [usprpt_GetStockReportAsOfNow]           
 ** Author:   Ayesha Sultana
 ** Description: This SP to get all the Asset Register Reports 
 ** Purpose:         
 ** Date:   10-JAN-2024    
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	 10-01-2024		Ayesha Sultana		Created
	2    11-04-2024     ABHISHEK JIRAWLA    Modified it according to the parameters passed and added some more return values. Also added some modification to Depreciation calculations.
	3	 12/12/2024		Abhishek Jirawla	Change made for Asset Inventory Status and Asset Available Status
	4    12-Aug-2026    Abhishek Jirawla	Remove AssetAttributeTypeId
	5    13-Nov-2026    Kishor Makwana		[PN-18535] UNION ALL the Lease Assets (Stockline IsAsset = 1, IsLease = 1) with their usage based depreciation (StocklineAssetDepreciationHistory); added DepreciationPerHour and UsageHours columns
     
**************************************************************/
CREATE   PROCEDURE [dbo].[GetAssetRegisterReport]
@mastercompanyid INT,
@id INT = NULL,
@id2 INT= NULL,
@id3 INT= NULL,
@strFilter VARCHAR(MAX) = NULL
AS
BEGIN
	BEGIN TRY
	BEGIN
	
		SET NOCOUNT ON;      
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED     	
		
		IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
			BEGIN    
				DROP TABLE #TEMPMSFilter
			END

			CREATE TABLE #TEMPMSFilter(        
					ID BIGINT  IDENTITY(1,1),        
					LevelIds VARCHAR(MAX)			 
				) 

			INSERT INTO #TEMPMSFilter(LevelIds)
			SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!')

			DECLARE   
			@level1 VARCHAR(MAX) = NULL,  
			@level2 VARCHAR(MAX) = NULL,  
			@level3 VARCHAR(MAX) = NULL,  
			@level4 VARCHAR(MAX) = NULL,  
			@Level5 VARCHAR(MAX) = NULL,  
			@Level6 VARCHAR(MAX) = NULL,  
			@Level7 VARCHAR(MAX) = NULL,  
			@Level8 VARCHAR(MAX) = NULL,  
			@Level9 VARCHAR(MAX) = NULL,  
			@Level10 VARCHAR(MAX) = NULL 

			SELECT @level1 = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
			SELECT @level2 = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
			SELECT @level3 = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
			SELECT @level4 = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
			SELECT @level5 = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
			SELECT @level6 = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
			SELECT @level7 = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
			SELECT @level8 = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
			SELECT @level9 = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
			SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10

			DECLARE @AssetStatusID varchar(500);
			SELECT @AssetStatusID = AssetStatusID FROM AssetStatus WHERE Name ='DEPRECIATING' and MasterCompanyId = @mastercompanyid;

			DECLARE @AssetModuleID varchar(500);
			--DECLARE @xmlFilter XML;
			SELECT @AssetModuleID = ManagementStructureModuleId FROM ManagementStructureModule WHERE ModuleName ='AssetInventoryTangible'

			DECLARE @StocklineMSModuleID INT = 2; -- [PN-18535] Management Structure module of a Stockline (Lease Assets are Stocklines)
			SELECT @StocklineMSModuleID = ISNULL((SELECT TOP 1 ManagementStructureModuleId FROM ManagementStructureModule WHERE ModuleName = 'Stockline'), 2);

		SELECT DISTINCT AI.AssetInventoryId,
				'TANGIBLE' AS AssetCategory,
				AI.AssetId AS InternalPN,
				UPPER(ASTS.[Name]) AS AssetStatus,
				UPPER(COALESCE(ASTIS.[Status], ASTAS.[Status], '')) AS InventoryStatus,
				UPPER(TC.TangibleClassName) AS AssetClass,
				AI.InventoryNumber,
				UPPER(AI.PartNumber) AS PartNumber,
				AI.AlternateAssetRecordId,
				--AAR.AssetId AS AlternateAssetRecordName,
				UPPER(AST.MANUFACTURERPN) AS ManufacturerPN,
				-- AST.[Name] AS AssetName,
				UPPER(AI.[Name]) AS AssetName,
				UPPER(AI.ManufactureName) AS ManufactureName,
				AI.ManufacturerId,
				UPPER(AI.Model) AS Model,
				-- ASTIS.[Status], 
				AI.AssetLife,
				UPPER(AI.DepreciationMethodName) AS DepreciationMethodName,
				UPPER(AAT.[Name]) AS AcquisitionType,
				AI.ReceivedDate,
				AI.DepreciationStartDate, -- CHANGE IT TO DEPR START DATE
				UPPER(AI.DepreciationFrequencyName) AS DepreciationFrequencyName,
				AI.TotalCost,
				CASE 
					WHEN ASTS.AssetStatusId = @AssetStatusID THEN ISNULL(ADH.AccumlatedDepr, 0)
					ELSE NULL
				END AS AccumlatedDepr,
				CASE 
					WHEN ASTS.AssetStatusId = @AssetStatusID THEN ISNULL(ADH.NetBookValue, AI.TotalCost)
					ELSE NULL
				END AS NetBookValue,
				CASE 
					WHEN ASTS.AssetStatusId = @AssetStatusID THEN ISNULL(ADH.DepreciationAmount, (AI.TotalCost - (AI.TotalCost * AI.ResidualPercentage)/100)/NULLIF(AI.AssetLife, 0))
					ELSE NULL
				END AS DepreciationAmount,
				ADH.LastDeprRunPeriod AS LastDeprDate,
				(SELECT COUNT(*) FROM AssetDepreciationHistory AS ADRH WHERE ADRH.AssetInventoryId = AI.AssetInventoryId and ADRH.IsDelete = 0) AS NumOfDeprPeriod,
				AI.AssetLife - (SELECT COUNT(*) FROM AssetDepreciationHistory AS ADRH WHERE ADRH.AssetInventoryId = AI.AssetInventoryId and ADRH.IsDelete = 0)  AS DeprPeriodRemaining,
				UPPER(AI.SerialNo) AS SerialNo,
				UPPER(AI.StklineNumber) AS StklineNumber,
				UPPER(MSD.Level1Name) AS level1,        
				UPPER(MSD.Level2Name) AS level2,       
				UPPER(MSD.Level3Name) AS level3,       
				UPPER(MSD.Level4Name) AS level4,       
				UPPER(MSD.Level5Name) AS level5,       
				UPPER(MSD.Level6Name) AS level6,       
				UPPER(MSD.Level7Name) AS level7,       
				UPPER(MSD.Level8Name) AS level8,       
				UPPER(MSD.Level9Name) AS level9,       
				UPPER(MSD.Level10Name) AS level10,
				CAST(NULL AS DECIMAL(18, 6)) AS DepreciationPerHour, -- [PN-18535] lease assets only
				CAST(NULL AS DECIMAL(18, 6)) AS UsageHours -- [PN-18535] lease assets only
		FROM DBO.AssetInventory AI WITH (NOLOCK)
				INNER JOIN DBO.Asset AST WITH (NOLOCK) ON AST.AssetRecordId = AI.AssetRecordId
				LEFT JOIN DBO.Asset AAR WITH (NOLOCK) ON AAR.AssetRecordId = AI.AlternateAssetRecordId
				LEFT JOIN DBO.AssetDepreciationHistory ADH WITH (NOLOCK) ON ADH.AssetInventoryId = AI.AssetInventoryId AND ADH.ID = (SELECT MAX(ID) FROM AssetDepreciationHistory WHERE AssetInventoryId = AI.AssetInventoryId AND IsDelete = 0)
				LEFT JOIN DBO.Currency CR WITH(NOLOCK) ON CR.CurrencyId = AI.CurrencyId 
				LEFT JOIN DBO.AssetStatus ASTS WITH(NOLOCK) ON ASTS.AssetStatusId = AI.AssetStatusId
				LEFT JOIN DBO.AssetAcquisitionType AAT WITH(NOLOCK) ON AAT.AssetAcquisitionTypeId = AI.AssetAcquisitionTypeId
				LEFT JOIN DBO.AssetInventoryStatus ASTIS WITH(NOLOCK) ON ASTIS.AssetInventoryStatusId = AI.InventoryStatusId
				LEFT JOIN DBO.AssetAvailableStatus ASTAS WITH(NOLOCK) ON ASTAS.AssetAvailableStatusId = AI.InventoryStatusId
				--LEFT JOIN DBO.AssetAttributeType ASAT WITH(NOLOCK) ON ASAT.AssetAttributeTypeId=AI.AssetAttributeTypeId
				LEFT JOIN DBO.TangibleClass TC WITH(NOLOCK) ON TC.TangibleClassId = AI.TangibleClassId
				LEFT JOIN DBO.AssetManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = AI.AssetInventoryId AND MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AssetModuleID,','))
				LEFT JOIN DBO.EntityStructureSetup ES WITH(NOLOCK) ON ES.EntityStructureId=MSD.EntityMSID 		

		WHERE ((ISNULL(@id,0) = 0 OR AI.TangibleClassId IN (@id,0)))			
			  AND ((ISNULL(@id2,0) = 0 OR AI.AssetStatusId IN (@id2,0)))		 
			  AND ((ISNULL(@id3,0) = 0 OR AI.InventoryStatusId IN (@id3,0)))	 
			  AND AI.MasterCompanyId = @mastercompanyid
			  AND AI.IsActive = 1
			  AND AI.IsDeleted = 0
			  AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))      
			  AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))      
			  AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))      
			  AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))      
			  AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))      
			  AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))      
			  AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))      
			  AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))      
			  AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))      
			  AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  

		UNION ALL

		-- [PN-18535] Lease Assets (Stockline IsAsset = 1, IsLease = 1) : usage based depreciation from StocklineAssetDepreciationHistory
		SELECT DISTINCT SL.StockLineId AS AssetInventoryId,
				'LEASE' AS AssetCategory,
				UPPER(ISNULL(AST.AssetId, SL.PartNumber)) AS InternalPN,
				UPPER(ASTS.[Name]) AS AssetStatus,
				UPPER(COALESCE(ASTIS.[Status], ASTAS.[Status], SL.AssetAvailStatus, '')) AS InventoryStatus,
				UPPER(TC.TangibleClassName) AS AssetClass,
				ISNULL(NULLIF(SL.AssetInventoryNumber, ''), SL.StockLineNumber) AS InventoryNumber,
				UPPER(SL.PartNumber) AS PartNumber,
				CAST(NULL AS BIGINT) AS AlternateAssetRecordId,
				UPPER(SL.AssetManufacturerPN) AS ManufacturerPN,
				UPPER(ISNULL(SL.AssetName, SL.PNDescription)) AS AssetName,
				UPPER(SL.Manufacturer) AS ManufactureName,
				SL.ManufacturerId,
				UPPER(SL.Model) AS Model,
				SL.AssetLife,
				UPPER(SL.DepreciationMethodName) AS DepreciationMethodName,
				UPPER(AAT.[Name]) AS AcquisitionType,
				SL.ReceivedDate,
				ISNULL(SL.AssetDepreciationStartDate, SL.ReceivedDate) AS DepreciationStartDate,
				UPPER(SL.DepreciationFrequencyName) AS DepreciationFrequencyName,
				SL.AssetTotalCost AS TotalCost,
				-- Accumulated Depr / NBV / last Depreciation of the last depreciation run (StocklineAssetDepreciationHistory)
				CASE WHEN LDH.StocklineAssetDepreciationHistoryId IS NOT NULL OR UPPER(ASTS.[Name]) = 'DEPRECIATING' THEN ISNULL(LDH.AccumulatedDepr, 0) ELSE NULL END AS AccumlatedDepr,
				CASE WHEN LDH.StocklineAssetDepreciationHistoryId IS NOT NULL OR UPPER(ASTS.[Name]) = 'DEPRECIATING' THEN ISNULL(LDH.NetBookValue, SL.AssetTotalCost) ELSE NULL END AS NetBookValue,
				CASE WHEN LDH.StocklineAssetDepreciationHistoryId IS NOT NULL OR UPPER(ASTS.[Name]) = 'DEPRECIATING' THEN ISNULL(LDH.DepreciationAmount, 0) ELSE NULL END AS DepreciationAmount,
				LDH.LastDeprRunPeriod AS LastDeprDate,
				ISNULL(LDS.NumOfDeprPeriod, 0) AS NumOfDeprPeriod,
				CAST(NULL AS INT) AS DeprPeriodRemaining, -- usage based : there is no fixed number of periods
				UPPER(SL.SerialNumber) AS SerialNo,
				UPPER(SL.StockLineNumber) AS StklineNumber,
				UPPER(SMSD.Level1Name) AS level1,
				UPPER(SMSD.Level2Name) AS level2,
				UPPER(SMSD.Level3Name) AS level3,
				UPPER(SMSD.Level4Name) AS level4,
				UPPER(SMSD.Level5Name) AS level5,
				UPPER(SMSD.Level6Name) AS level6,
				UPPER(SMSD.Level7Name) AS level7,
				UPPER(SMSD.Level8Name) AS level8,
				UPPER(SMSD.Level9Name) AS level9,
				UPPER(SMSD.Level10Name) AS level10,
				-- usage based depreciation : Depreciation per Hr = Cost / Asset Life, UsageHours = hours depreciated up to the last run
				CAST(ISNULL(LDH.DepreciationPerHour, SL.AssetTotalCost / NULLIF(SL.AssetLife, 0)) AS DECIMAL(18, 6)) AS DepreciationPerHour,
				CAST(ISNULL(LDS.TotalUsageHours, 0) AS DECIMAL(18, 6)) AS UsageHours
		FROM DBO.Stockline SL WITH (NOLOCK)
				LEFT JOIN DBO.Asset AST WITH (NOLOCK) ON AST.AssetRecordId = SL.AssetId
				LEFT JOIN DBO.AssetStatus ASTS WITH(NOLOCK) ON ASTS.AssetStatusId = SL.AssetStatusId
				LEFT JOIN DBO.AssetAcquisitionType AAT WITH(NOLOCK) ON AAT.AssetAcquisitionTypeId = SL.AcquistionTypeId
				LEFT JOIN DBO.AssetInventoryStatus ASTIS WITH(NOLOCK) ON ASTIS.AssetInventoryStatusId = SL.AssetInventoryStatusId
				LEFT JOIN DBO.AssetAvailableStatus ASTAS WITH(NOLOCK) ON ASTAS.AssetAvailableStatusId = SL.AssetAvailableStatusId
				LEFT JOIN DBO.TangibleClass TC WITH(NOLOCK) ON TC.TangibleClassId = SL.AssetTangibleClassId
				OUTER APPLY (
					SELECT TOP 1 H.StocklineAssetDepreciationHistoryId, H.AccumulatedDepr, H.NetBookValue, H.DepreciationAmount, H.LastDeprRunPeriod, H.DepreciationPerHour
					FROM DBO.StocklineAssetDepreciationHistory H WITH (NOLOCK)
					WHERE H.StockLineId = SL.StockLineId AND H.IsDeleted = 0
					ORDER BY H.StocklineAssetDepreciationHistoryId DESC
				) LDH
				OUTER APPLY (
					SELECT COUNT(*) AS NumOfDeprPeriod, SUM(ISNULL(H2.UsageHours, 0)) AS TotalUsageHours
					FROM DBO.StocklineAssetDepreciationHistory H2 WITH (NOLOCK)
					WHERE H2.StockLineId = SL.StockLineId AND H2.IsDeleted = 0
				) LDS
				LEFT JOIN DBO.StocklineManagementStructureDetails SMSD WITH (NOLOCK) ON SMSD.ReferenceID = SL.StockLineId AND SMSD.ModuleID = @StocklineMSModuleID

		WHERE ISNULL(SL.IsAsset, 0) = 1
			  AND ISNULL(SL.IsLease, 0) = 1
			  AND ((ISNULL(@id,0) = 0 OR SL.AssetTangibleClassId IN (@id,0)))
			  AND ((ISNULL(@id2,0) = 0 OR SL.AssetStatusId IN (@id2,0)))
			  AND ((ISNULL(@id3,0) = 0 OR SL.AssetInventoryStatusId IN (@id3,0)))
			  AND SL.MasterCompanyId = @mastercompanyid
			  AND ISNULL(SL.isActive, 1) = 1
			  AND ISNULL(SL.isDeleted, 0) = 0
			  AND (ISNULL(@Level1,'') ='' OR SMSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
			  AND (ISNULL(@Level2,'') ='' OR SMSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
			  AND (ISNULL(@Level3,'') ='' OR SMSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
			  AND (ISNULL(@Level4,'') ='' OR SMSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
			  AND (ISNULL(@Level5,'') ='' OR SMSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
			  AND (ISNULL(@Level6,'') ='' OR SMSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
			  AND (ISNULL(@Level7,'') ='' OR SMSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
			  AND (ISNULL(@Level8,'') ='' OR SMSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
			  AND (ISNULL(@Level9,'') ='' OR SMSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
			  AND (ISNULL(@Level10,'') =''  OR SMSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')));
			  
		--GROUP BY AI.AssetInventoryId,
		--		AI.AssetId,
		--		ASTS.[Name],
		--		UPPER(ASTIS.[Status]),
		--		UPPER(ASAT.AssetAttributeTypeName),
		--		AI.InventoryNumber,
		--		UPPER(AI.PartNumber),
		--		AI.AlternateAssetRecordId,
		--		AAR.AssetId,
		--		UPPER(AST.MANUFACTURERPN),
		--		-- AST.[Name] AS AssetName,
		--		UPPER(AI.[Name]),
		--		UPPER(AI.ManufactureName),
		--		AI.ManufacturerId,
		--		UPPER(AI.Model),
		--		-- ASTIS.[Status], 
		--		AI.AssetLife,
		--		UPPER(AI.DepreciationMethodName),
		--		UPPER(AAT.[Name]),
		--		AI.ReceivedDate,
		--		AI.DepreciationStartDate, -- CHANGE IT TO DEPR START DATE
		--		UPPER(AI.DepreciationFrequencyName),
		--		-- ASTS.[Name],
		--		AI.TotalCost,
		--		ADH.AccumlatedDepr,
		--		ADH.NetBookValue,
		--		ADH.DepreciationAmount,
		--		ADH.LastDeprRunPeriod,
		--		UPPER(AI.SerialNo),
		--		UPPER(AI.StklineNumber),
		--		UPPER(MSD.Level1Name),        
		--		UPPER(MSD.Level2Name),       
		--		UPPER(MSD.Level3Name),       
		--		UPPER(MSD.Level4Name),       
		--		UPPER(MSD.Level5Name),       
		--		UPPER(MSD.Level6Name),       
		--		UPPER(MSD.Level7Name),       
		--		UPPER(MSD.Level8Name),       
		--		UPPER(MSD.Level9Name),       
		--		UPPER(MSD.Level10Name)
	END	
	END TRY  
	BEGIN CATCH  
	    IF @@trancount > 0
	    ROLLBACK TRAN;
		DECLARE @ErrorLogID INT ,@DatabaseName VARCHAR(100) = db_name()      
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
		,@AdhocComments VARCHAR(150) = 'GetAssetRegisterReport'      
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@id, '') AS varchar(100))      
											+ '@Parameter2 = ''' + CAST(ISNULL(@id2, '') AS varchar(100))       
											+ '@Parameter3 = ''' + CAST(ISNULL(@id3, '') AS varchar(100))      
		,@ApplicationName VARCHAR(100) = 'PAS'      
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
		EXEC spLogException @DatabaseName = @DatabaseName      
								,@AdhocComments = @AdhocComments      
								,@ProcedureParameters = @ProcedureParameters      
								,@ApplicationName = @ApplicationName      
								,@ErrorLogID = @ErrorLogID OUTPUT;          
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)      
      
		RETURN (1);    
	END CATCH 
END