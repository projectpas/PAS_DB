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
	2    02-04-2024     ABHISHEK JIRAWLA    Modified it according to the parameters passed
     
**************************************************************/
CREATE     PROCEDURE [dbo].[GetAssetRegisterReport]
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

		DECLARE @AssetModuleID varchar(500);
		--DECLARE @xmlFilter XML;
		SELECT @AssetModuleID = ManagementStructureModuleId FROM ManagementStructureModule WHERE ModuleName ='AssetInventoryTangible'

		SELECT  AI.AssetInventoryId,
				'TANGIBLE' AS AssetCategory,
				UPPER(ASTS.[Name]) AS AssetStatus,
				UPPER(ASTIS.[Status]) AS InventoryStatus,
				UPPER(ASAT.AssetAttributeTypeName) AS AssetClass,
				AI.InventoryNumber,
				UPPER(AI.PartNumber) AS PartNumber,
				AI.AlternateAssetRecordId,
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
				-- ASTS.[Name],
				AI.TotalCost,
				ADH.AccumlatedDepr,
				ADH.NetBookValue,
				ADH.DepreciationAmount,
				ADH.LastDeprRunPeriod AS LastDeprDate,
				'' AS NumOfDeprPeriod,
				'' AS DeprPeriodRemaining,
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
				UPPER(MSD.Level10Name) AS level10

		FROM AssetInventory AI WITH (NOLOCK)
				LEFT JOIN Asset AST WITH (NOLOCK) ON AST.AssetId = AI.AssetId
				LEFT JOIN AssetDepreciationHistory ADH WITH (NOLOCK) ON ADH.AssetInventoryId = AI.AssetInventoryId
				LEFT JOIN Currency CR WITH(NOLOCK) ON CR.CurrencyId = AI.CurrencyId 
				LEFT JOIN AssetStatus ASTS WITH(NOLOCK) ON ASTS.AssetStatusId = AI.AssetStatusId
				LEFT JOIN AssetAcquisitionType AAT WITH(NOLOCK) ON AAT.AssetAcquisitionTypeId = AI.AssetAcquisitionTypeId
				LEFT JOIN AssetInventoryStatus ASTIS WITH(NOLOCK) ON ASTIS.AssetInventoryStatusId = AI.InventoryStatusId
				-- LEFT JOIN TangibleClass TC WITH(NOLOCK) ON TC.TangibleClassId=AI.TangibleClassId
				LEFT JOIN AssetAttributeType ASAT WITH(NOLOCK) ON ASAT.AssetAttributeTypeId=AI.AssetAttributeTypeId
				LEFT JOIN AssetManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = AI.AssetInventoryId AND MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AssetModuleID,','))
				LEFT JOIN EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID 		

		WHERE ((ISNULL(@id,0) = 0 OR AI.AssetAttributeTypeId IN (@id,0)))			
			  AND ((ISNULL(@id2,0) = 0 OR AI.AssetStatusId IN (@id2,0)))		 
			  AND ((ISNULL(@id3,0) = 0 OR AI.InventoryStatusId IN (@id3,0)))	 
			  AND AI.MasterCompanyId = @mastercompanyid
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