-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <10-JAN-2024>
-- Description:	<This SP to get all the Asset Register Reports>
-- =============================================
CREATE     PROCEDURE [dbo].[GetAssetRegisterReport]
@AssetClass VARCHAR(30),
@AssetStatus VARCHAR(30),
@AssetInventoryStatus VARCHAR(30),
@MasterCompanyId INT,
@PageNumber INT = 1,      
@PageSize INT = NULL
AS
BEGIN
	SET NOCOUNT ON;      
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED     
	
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
		@Level10 VARCHAR(MAX) = NULL,      
		@IsDownload BIT = NULL  
		
	DECLARE @AssetModuleID varchar(500);
	SELECT @AssetModuleID = ModuleId FROM Module WHERE ModuleName='AssetInventory' AND ModuleName='Asset'     

	BEGIN TRY 
	BEGIN TRANSACTION
	BEGIN

	    SELECT  AI.AssetInventoryId,
				'Tangible' AS AssetCategory,
				AI.InventoryNumber,
				AI.PartNumber,
				AI.AlternateAssetRecordId,
				AST.MANUFACTURERPN,
				AI.[Name],
				AI.ManufactureName,
				AI.ManufacturerId,
				AI.Model,
				ASTIS.[Status], 
				AI.AssetLife,
				AI.DepreciationMethodName,
				AI.AssetAcquisitionTypeId,
				AI.ReceivedDate,
				AI.CreatedDate, -- CHANGE IT TO DEPR START DATE
				AI.DepreciationFrequencyName,
				ASTS.[Name],
				AI.TotalCost,
				ADH.AccumlatedDepr,
				ADH.NetBookValue,
				ADH.DepreciationAmount,
				'' AS LastDeprDate,
				'' AS NumOfDeprPeriod,
				'' AS DeprPeriodRemaining,
				AI.SerialNo,
				AI.StklineNumber,
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
				INNER JOIN Currency CR WITH(NOLOCK) ON CR.CurrencyId = AI.CurrencyId 
				INNER JOIN AssetStatus ASTS WITH(NOLOCK) ON ASTS.AssetStatusId = AI.AssetStatusId
				INNER JOIN AssetInventoryStatus ASTIS WITH(NOLOCK) ON ASTIS.AssetInventoryStatusId = AI.InventoryStatusId
				LEFT JOIN TangibleClass TC WITH(NOLOCK) ON TC.TangibleClassId=AI.TangibleClassId
				INNER JOIN AssetManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = AI.AssetInventoryId AND MSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AssetModuleID,','))
				LEFT JOIN EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID 

		WHERE AI.AssetStatusId=@AssetStatus AND AI.InventoryStatusId=@AssetInventoryStatus AND AI.TangibleClassId = @AssetClass  
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

		SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END      
		SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END 
			
	END
	COMMIT  TRANSACTION		
	END TRY  
	BEGIN CATCH  
	    IF @@trancount > 0
	    ROLLBACK TRAN;
		DECLARE @ErrorLogID INT ,@DatabaseName VARCHAR(100) = db_name()      
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
		,@AdhocComments VARCHAR(150) = 'CopyReportingStructure'      
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