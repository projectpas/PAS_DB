/*************************************************************           
 ** File:   [USP_GetWOTearDownStockLineList]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used retrieve stockline list for teardown work order
 ** Purpose:         
 ** Date:   12/25/2021      
          
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    12/28/2021   Devendra Shekh			Created
     
exec USP_GetWOTearDownStockLineList 
@PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@StatusId=1,@PartNumber=NULL,@PartDescription=NULL,@Manufacturer=NULL,
@StockLineNumber=NULL,@SerialNumber=NULL,@ControlNumber=NULL,@IdNumber=NULL,@UnitCost=0,@QtyOnHand=0,@QtyAvailable=0,@ExtendedCost=0,@CreatedBy=NULL,
@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@WorkOrderId=3845,@WorkOrderPartNumberId=3329,@MasterCompanyId=1

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetWOTearDownStockLineList]
@PageNumber INT = NULL,
@PageSize INT = NULL,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@GlobalFilter VARCHAR(50) = NULL,
@StatusId INT = NULL,

@PartNumber VARCHAR(100) = NULL,
@PartDescription VARCHAR(100) = NULL,
@Manufacturer VARCHAR(100) = NULL,
@StockLineNumber VARCHAR(100) = NULL,
@SerialNumber VARCHAR(100) = NULL,
@ControlNumber VARCHAR(100) = NULL,
@IdNumber VARCHAR(100) = NULL,
@UnitCost DECIMAL(18,2) = NULL,
@QtyOnHand BIGINT = NULL,
@QtyAvailable BIGINT = NULL,
@ExtendedCost DECIMAL(18,2) = NULL,
@CreatedBy  VARCHAR(100) = NULL,
@CreatedDate DATETIME = NULL,
@UpdatedBy  VARCHAR(100) = NULL,
@OpenDate DATETIME = NULL,
@UpdatedDate  DATETIME = NULL,
@IsDeleted BIT = NULL,
@WorkOrderId BIGINT = NULL,
@WorkOrderPartNumberId BIGINT = NULL,
@MasterCompanyId BIGINT = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom INT;		
		DECLARE @Count INT;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END

		;WITH Result AS(
				SELECT DISTINCT
						SL.StockLineId,
						SL.WorkOrderId,
						WOP.ID AS 'WorkOrderPartNumberId',
						IM.PartNumber,
						IM.PartDescription,
						IM.ManufacturerName AS 'Manufacturer',
						SL.StockLineNumber,
						ISNULL(SL.SerialNumber, '') AS 'SerialNumber',
						ISNULL(SL.ControlNumber, '') AS 'ControlNumber',
						ISNULL(SL.IdNumber, '') AS 'IdNumber',
						ISNULL(SL.UnitCost, 0) AS 'UnitCost',
						ISNULL(SL.QuantityOnHand, 0) AS 'QtyOnHand',
						ISNULL(SL.QuantityAvailable, 0) AS 'QtyAvailable',
						ISNULL(SL.WorkOrderExtendedCost, 0) AS 'ExtendedCost',
						SL.IsActive,
						SL.IsDeleted,
						SL.CreatedDate,
						SL.UpdatedDate,
						Upper(SL.CreatedBy) CreatedBy,
						Upper(SL.UpdatedBy) UpdatedBy
			   FROM [dbo].[Stockline] SL WITH (NOLOCK)
				INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = SL.WorkOrderId
				INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId AND WOP.ID = @WorkOrderPartNumberId
				LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.ItemMasterId = IM.ItemMasterId

		 	  WHERE ((SL.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR SL.IsActive=@IsActive))			     
					AND SL.MasterCompanyId=@MasterCompanyId AND SL.WorkOrderId = @WorkOrderId	
			), ResultCount AS(SELECT COUNT(StockLineId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
			        (PartDescription LIKE '%' + @GlobalFilter+'%') OR	
					(Manufacturer LIKE '%' + @GlobalFilter+'%') OR
					(StockLineNumber LIKE '%' + @GlobalFilter+'%') OR
					(SerialNumber LIKE '%' + @GlobalFilter+'%') OR
					(ControlNumber LIKE '%' + @GlobalFilter+'%') OR
					(IdNumber LIKE '%' + @GlobalFilter+'%') OR
					(CAST(UnitCost AS VARCHAR) LIKE '%' + @GlobalFilter+'%') OR
					(CAST(QtyOnHand AS VARCHAR) LIKE '%' + @GlobalFilter+'%') OR
					(CAST(QtyAvailable AS VARCHAR) LIKE '%' + @GlobalFilter+'%') OR
					(CAST(ExtendedCost AS VARCHAR) LIKE '%' + @GlobalFilter+'%') OR
					(CreatedBy LIKE '%' + @GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' + @GlobalFilter+'%'))) OR   
					(@GlobalFilter ='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND	
					(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND	
					(ISNULL(@StockLineNumber,'') ='' OR StockLineNumber LIKE '%' + @StockLineNumber + '%') AND	
					(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND	
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND	
					(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND	
					--(ISNULL(CAST(@UnitCost AS VARCHAR),'') ='' OR CAST(UnitCost AS VARCHAR) LIKE '%' + CAST(@UnitCost AS VARCHAR)+ '%') AND	
					--(ISNULL(CAST(@QtyOnHand AS VARCHAR),'') ='' OR CAST(QtyOnHand AS VARCHAR) LIKE '%' + CAST(@SerialNumber AS VARCHAR) + '%') AND	
					--(ISNULL(CAST(@QtyAvailable AS VARCHAR),'') ='' OR CAST(QtyAvailable AS VARCHAR) LIKE '%' + CAST(@SerialNumber AS VARCHAR) + '%') AND	
					--(ISNULL(CAST(@ExtendedCost AS VARCHAR),'') ='' OR CAST(ExtendedCost AS VARCHAR) LIKE '%' + CAST(@SerialNumber AS VARCHAR) + '%') AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(StockLineId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='StockLineNumber')  THEN StockLineNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StockLineNumber')  THEN StockLineNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QtyOnHand')  THEN QtyOnHand END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyOnHand')  THEN QtyOnHand END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QtyAvailable')  THEN QtyAvailable END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyAvailable')  THEN QtyAvailable END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ExtendedCost')  THEN ExtendedCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ExtendedCost')  THEN ExtendedCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetWOTearDownStockLineList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS VARCHAR(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@PartNumber, '') AS VARCHAR(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@PartDescription, '') AS VARCHAR(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@Manufacturer , '') AS VARCHAR(100))		  
			   + '@Parameter10 = ''' + CAST(ISNULL(@StockLineNumber , '') AS VARCHAR(100))		  
			   + '@Parameter11 = ''' + CAST(ISNULL(@SerialNumber , '') AS VARCHAR(100))		  
			   + '@Parameter12 = ''' + CAST(ISNULL(@ControlNumber , '') AS VARCHAR(100))		  
			   + '@Parameter13 = ''' + CAST(ISNULL(@IdNumber , '') AS VARCHAR(100))		  
			   + '@Parameter14 = ''' + CAST(ISNULL(@UnitCost , '') AS VARCHAR(100))		  
			   + '@Parameter15 = ''' + CAST(ISNULL(@QtyOnHand , '') AS VARCHAR(100))		  
			   + '@Parameter16 = ''' + CAST(ISNULL(@QtyAvailable , '') AS VARCHAR(100))		  
			   + '@Parameter17 = ''' + CAST(ISNULL(@ExtendedCost , '') AS VARCHAR(100))		  
			   + '@Parameter18 = ''' + CAST(ISNULL(@CreatedBy , '') AS VARCHAR(100))
			   + '@Parameter19 = ''' + CAST(ISNULL(@CreatedDate , '') AS VARCHAR(100))
			   + '@Parameter20 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS VARCHAR(100))
			   + '@Parameter21 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS VARCHAR(100))
			   + '@Parameter22 = ''' + CAST(ISNULL(@OpenDate  , '') AS VARCHAR(100))
			   + '@Parameter23 = ''' + CAST(ISNULL(@IsDeleted , '') AS VARCHAR(100))
			   + '@Parameter24 = ''' + CAST(ISNULL(@WorkOrderId , '') AS VARCHAR(100))
			   + '@Parameter25 = ''' + CAST(ISNULL(@WorkOrderPartNumberId , '') AS VARCHAR(100))
			   + '@Parameter26 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END