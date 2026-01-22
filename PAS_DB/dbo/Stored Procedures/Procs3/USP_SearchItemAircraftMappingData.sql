/*************************************************************           
 ** File:		 [USP_SearchItemAircraftMappingData]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Aircraft Data.
 ** Purpose:         
 ** Date:   29-August-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    29-August-2025		Divyesh Kathiriya	Created

 -- EXEC [USP_SearchItemAircraftMappingData] @ItemmasterId=96940, @AircraftTypeIds='57,51', @AircraftModelIds='213,217,249,250', @DashNumberIds='10,11,17,20,12,16,18,19,23,27'
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_SearchItemAircraftMappingData]
@ItemmasterId     BIGINT,
@AircraftTypeIds  NVARCHAR(MAX) = NULL, 
@AircraftModelIds NVARCHAR(MAX) = NULL,
@DashNumberIds    NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY    
    ;WITH Base AS (
        SELECT
            it.[ItemMasterId],
            it.[PartNumber],
            it.[AircraftTypeId],
            it.[AircraftModelId],
            it.[DashNumberId],
            it.[DashNumber],
            it.[AircraftType],
            it.[AircraftModel],
            it.[Memo],
            it.[ATAReferenceId],
            it.[ATAReference],
            it.[ATAChapterId],            
            ATAChapter = it.[Level1]
                         + CASE WHEN ISNULL(it.[Level2], '') <> '' THEN '-' + it.[Level2] ELSE '' END
                         + CASE WHEN ISNULL(it.[Level3], '') <> '' THEN '-' + it.[Level3] ELSE '' END,
            it.[MasterCompanyId],
            ISNULL(it.[IsActive], 0) AS IsActive,
			ISNULL(it.[IsDeleted], 0) AS IsDeleted,
            it.[CreatedDate],
            it.[CreatedBy],
            it.[UpdatedBy],
            it.[UpdatedDate]
        FROM [DBO].[ItemMasterAircraftMapping] AS it WITH (NOLOCK)
        WHERE it.[IsActive] = 1
            AND it.[IsDeleted] = 0
            AND it.[ItemMasterId] = @ItemmasterId
            AND (@AircraftTypeIds IS NULL OR @AircraftTypeIds = '' 
                OR it.[AircraftTypeId] IN (SELECT Item FROM dbo.SplitString(@AircraftTypeIds , ',')))
            AND (@AircraftModelIds IS NULL OR @AircraftModelIds = '' 
                OR it.[AircraftModelId] IN (SELECT Item FROM dbo.SplitString(@AircraftModelIds , ',')))
            AND (@DashNumberIds IS NULL OR @DashNumberIds = '' 
                OR it.[DashNumberId] IN (SELECT Item FROM dbo.SplitString(@DashNumberIds , ',')))
            ),
   
    Result AS (
        SELECT B.*, ROW_NUMBER() OVER (
                PARTITION BY B.AircraftTypeId, B.AircraftModelId, B.DashNumberId
                ORDER BY B.CreatedDate DESC, B.ItemMasterId) AS RN
        FROM Base AS B
            )
            SELECT
                ItemMasterId,
                PartNumber,
                AircraftTypeId,
                AircraftModelId,
                DashNumberId,
                DashNumber,
                AircraftType,
                AircraftModel,
                Memo,
                ATAReferenceId,
                ATAReference,
                ATAChapterId,
                ATAChapter,
                MasterCompanyId,
                IsActive,
                IsDeleted,
                CreatedDate,
                CreatedBy,
                UpdatedBy,
                UpdatedDate
            FROM Result
            WHERE RN = 1; 
		
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SearchItemAircraftMappingData'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END