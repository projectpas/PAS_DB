-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <10-JAN-2024>
-- Description:	<This SP to get all the Asset Register Reports>
-- =============================================
CREATE     PROCEDURE [dbo].[GetAssetRegisterReport]
@AssetClass VARCHAR(30) = NULL,
@AssetStatus VARCHAR(30) = NULL,
@AssetInventoryStatus VARCHAR(30) = NULL,
@MasterCompanyId INT,
@ManagementStructureId INT,
@xmlFilter XML 
AS
BEGIN
	BEGIN TRY
	BEGIN
	
		SET NOCOUNT ON;      
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED     
	
		DECLARE @AssetModuleID varchar(500);
		--DECLARE @xmlFilter XML;
		SELECT @AssetModuleID = ManagementStructureModuleId FROM ManagementStructureModule WHERE ModuleName ='AssetInventoryTangible'

		print @AssetModuleID

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

		SELECT 		@level1=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level1 END,    
					   @level2=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level2 END,    
					   @level3=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level3 END,    
					   @level4=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level4 END,    
					   @level5=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level5 END,    
					   @level6=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level6 END,    
					   @level7=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level7 END,    
					   @level8=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level8 END,    
					   @level9=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level9 END,    
					   @level10=CASE WHEN filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10'   
					   THEN filterby.value('(FieldValue/text())[1]','VARCHAR(100)') ELSE @level10 end    
		FROM @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby) 

		print @level1

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

		WHERE ((ISNULL(@AssetClass,0) = 0 OR AI.AssetAttributeTypeId IN (@AssetClass,0)))			
			  AND ((ISNULL(@AssetStatus,0) = 0 OR AI.AssetStatusId IN (@AssetStatus,0)))		 
			  AND ((ISNULL(@AssetInventoryStatus,0) = 0 OR AI.InventoryStatusId IN (@AssetInventoryStatus,0)))	 
			  AND AI.MasterCompanyId = @MasterCompanyId
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
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@AssetClass, '') AS varchar(100))      
											+ '@Parameter2 = ''' + CAST(ISNULL(@AssetStatus, '') AS varchar(100))       
											+ '@Parameter3 = ''' + CAST(ISNULL(@AssetInventoryStatus, '') AS varchar(100))      
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