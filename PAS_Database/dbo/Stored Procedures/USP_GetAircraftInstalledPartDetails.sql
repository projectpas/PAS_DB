/*************************************************************           
 ** File:   [USP_GetAircraftInstalledPartDetails]           
 ** Author:  
 ** Description: 
 ** Purpose:         
 ** Date:    
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------    ---------			--------------------------------          
    1	03-27-2026		Amit Ghediya		    Created
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_GetAircraftInstalledPartDetails]
	@PageNumber int,  
	@PageSize int,  
	@SortColumn varchar(50)=null,  
	@SortOrder int,  
	@AircraftRegistryId BIGINT = NULL,
	@MasterCompanyId INT
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	

		;WITH Result AS
		(
			SELECT
				AIPD.AircraftInstalledPartDetailsId,
				AIPD.ATAChapterId,
				ATAC.ATAChapterName AS AtaChapter,
				AIPD.PartNumber,
				AIPD.PartDescription,
				AIPD.IsLLP,
				CASE WHEN AIPD.IsLLP > 0 THEN 'YES' ELSE 'NO' END AS 'llp',
				AIPD.IsSerialized,
				AIPD.DateInstalled,
				AIPD.PositionCode,
				AIPD.[Hours],
				AIPD.[Minutes],
				AIPD.FlightHours,
				AIPD.Cycles,
				AIPD.Landings,
				AIPD.EngineStarts,
				AIPD.Memo,
				AIPD.CreatedDate,
				AIPD.UpdatedDate,
				UPPER(AIPD.CreatedBy) AS CreatedBy,
				UPPER(AIPD.UpdatedBy) AS UpdatedBy
			FROM dbo.AircraftInstalledPartDetails AIPD WITH (NOLOCK)
			INNER JOIN dbo.ATAChapter ATAC WITH (NOLOCK) ON AIPD.ATAChapterId = ATAC.ATAChapterId
			WHERE 
				AIPD.AircraftRegistryId = @AircraftRegistryId
				AND AIPD.MasterCompanyId = @MasterCompanyId
		   
		)
		SELECT * INTO #TempResult
		FROM Result  ORDER BY CreatedDate DESC

		SELECT @Count = COUNT(*) FROM #TempResult;

		SELECT *, @Count AS NumberOfItems
		FROM #TempResult
		ORDER BY

			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'AtaChapter') THEN AtaChapter END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'AtaChapter') THEN AtaChapter END DESC,

			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'llp') THEN llp END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'llp') THEN llp END DESC,

			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartNumber') THEN PartNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartNumber') THEN PartNumber END DESC,

			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartDescription') THEN PartDescription END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartDescription') THEN PartDescription END DESC,

			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PositionCode') THEN PositionCode END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PositionCode') THEN PositionCode END DESC,

			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CreatedDate') THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CreatedDate') THEN CreatedDate END DESC,

			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UpdatedDate') THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UpdatedDate') THEN UpdatedDate END DESC

		OFFSET @RecordFrom ROWS
		FETCH NEXT @PageSize ROWS ONLY;

		DROP TABLE #TempResult;

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetAircraftInstalledPartDetails'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)

		RETURN (1);           
	END CATCH
END