/*************************************************************           
 ** File:   [USP_GetStockBulkUpdateDatalist]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to get bulk uploaded file data list.
 ** Purpose:         
 ** Date:   07/14/2023      
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/14/2023  Amit Ghediya     Created
     
-- EXEC USP_GetStockBulkUpdateDatalist
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetStockBulkUpdateDatalist]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@GlobalFilter varchar(50) = null,
	@FileName varchar(100)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,	
	@MasterCompanyId bigint=NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		Else
		BEGIN 
			SET @SortColumn=UPPER(@SortColumn)
		END

		;WITH Result AS(
			SELECT	DISTINCT
					StkF.StockLineBulkUploadFileId AS 'StockLineBulkUploadFileId',
					StkF.FileName AS 'FileName',
					StkF.CreatedDate,
					StkF.CreatedBy,
					StkF.UpdatedDate,
					StkF.UpdatedBy
				FROM dbo.StockLineBulkUploadFile StkF  WITH (NOLOCK)
					WHERE StkF.MasterCompanyId = @MasterCompanyId
			), ResultCount AS(SELECT COUNT(StockLineBulkUploadFileId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE (
			(@GlobalFilter <>'' AND ((FileName LIKE '%' +@GlobalFilter+'%' ) OR 
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') 
					))
					OR   
					(@GlobalFilter='' AND (ISNULL(@FileName,'') ='' OR FileName LIKE '%' + @FileName+'%') AND 
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND 
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))
					)

		SELECT @Count = COUNT(StockLineBulkUploadFileId) from #TempResult			

		SELECT *, @Count AS NumberOfItems FROM #TempResult
		ORDER BY  
		CASE WHEN (@SortOrder=1 AND @SortColumn='FILENAME')  THEN FileName END ASC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
        CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
		CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC
		OFFSET @RecordFrom ROWS 
		FETCH NEXT @PageSize ROWS ONLY		

		END TRY    
		BEGIN CATCH      
             DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetStockBulkUpdateDatalist'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))			  
			   + '@Parameter7 = ''' + CAST(ISNULL(@FileName, '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter23 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))  
			  
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