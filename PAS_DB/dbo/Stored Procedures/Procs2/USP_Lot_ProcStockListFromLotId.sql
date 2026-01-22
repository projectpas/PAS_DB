
/*************************************************************           
 ** File:   [USP_Lot_ProcStockListFromLotId]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to get stockl list from itemMaster.
 ** Purpose:         
 ** Date:   04/12/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/12/2023  Amit Ghediya    Created
     
-- EXEC USP_Lot_ProcStockListFromLotId
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_ProcStockListFromLotId]
	@PageNumber INT = NULL,
	@PageSize INT = NULL,
	@SortColumn varchar(50)=NULL,
	@SortOrder INT = NULL,
	@GlobalFilter VARCHAR(50) = NULL,
	@PartNumber VARCHAR(50) = NULL,
	@PartDescription VARCHAR(50) = NULL,
	@ManufacturerName VARCHAR(50) = NULL,
	@UOM VARCHAR(50) = NULL,
	@SerialNumber  VARCHAR(50) = NULL,
	@Condition VARCHAR(50) = NULL,
	@QuantityAvailable VARCHAR(50) = NULL,
	@ItemClassification VARCHAR(50) = NULL,
	@ItemGroup VARCHAR(50) = NULL,
	@StocklineNumber VARCHAR(50) = NULL,
	@UnitCost DECIMAL(18,2) = NULL,
	@ExtCost DECIMAL(18,2) = NULL,
	@CO VARCHAR(50) = NULL,
	@BU VARCHAR(50) = NULL,
	@Div VARCHAR(50) = NULL,
	@Dept VARCHAR(50) = NULL,	
	@LotId BIGINT =NULL,
	@ItemMasterId BIGINT = NULL,
	@TraceableToName varchar(200) = NULL,
	@TaggedByName varchar(200) = NULL,
	@TagDate datetime = NULL,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
		DECLARE @RecordFrom INT;
		DECLARE @MSModuelId int;
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;	
		SET @MSModuelId = 2;

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END	
		
		BEGIN TRY		
			BEGIN				
				;WITH Result AS(
					SELECT DISTINCT stl.StockLineId,				
						   (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',
						   UPPER((ISNULL(im.PartNumber,''))) 'PartNumber',
						   UPPER((ISNULL(im.PartDescription,''))) 'PartDescription',
						   UPPER((ISNULL(im.ManufacturerName,''))) 'ManufacturerName',
						   CASE WHEN stl.isSerialized = 1 THEN UPPER(ISNULL(stl.SerialNumber,'')) ELSE UPPER(ISNULL(stl.SerialNumber,'')) END AS 'SerialNumber',
						   (ISNULL(stl.Condition,'')) 'Condition', 	
						   UPPER((ISNULL(stl.StockLineNumber,''))) 'StocklineNumber', 
						   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',
						   CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',
						   CAST((CASE WHEN ISNULL(stl.QuantityAvailable,0) >0 THEN ISNULL(stl.UnitCost,0) ELSE 0 END) AS varchar) 'UnitCost',
						   CAST((ISNULL(stl.UnitCost,0) * ISNULL(stl.QuantityAvailable,0)) AS varchar) 'ExtCost',
						   UPPER(stl.unitofmeasure) 'uom',
						   UPPER(stl.itemgroup) 'itemgroup', 
						   stl.MasterCompanyId,	
						   stl.CreatedDate,
						   0 AS Isselected,
						   UPPER(MSD.Level1Name) AS cO,
						   UPPER(MSD.Level2Name) AS bU,
						   UPPER(MSD.Level3Name) AS div,
						   UPPER(MSD.Level4Name) AS dept,
						   lin.LotTransInOutId,
						   stl.ControlNumber,
						   stl.IdNumber,
						   po.PurchaseOrderNumber
						  ,UPPER(MSD.LastMSLevel) LastMSLevel
						  ,UPPER(MSD.AllMSlevels) AllMSlevels
						  ,im.ItemClassificationName AS ItemClassification
						  ,lt.LotId
						  ,stl.TraceableToName
						  ,stl.TaggedByName
						  ,stl.TagDate
					FROM LotTransInOutDetails lin WITH (NOLOCK)
					INNER JOIN DBO.LotCalculationDetails Cal WITH (NOLOCK) ON lin.LotTransInOutId = Cal.LotTransInOutId
					INNER JOIN DBO.Lot lt WITH(NOLOCK) on lin.LotId = lt.LotId
					LEFT JOIN [dbo].[StockLine] stl WITH (NOLOCK) ON lin.StockLineId = stl.StockLineId
					LEFT JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId 
					LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId
					LEFT JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
					WHERE lin.LotId = @LotId AND im.ItemMasterId = @ItemMasterId 
					AND ISNULL(lin.QtyToTransIn,0) >0 AND ISNULL(stl.QuantityAvailable,0) >0 AND ( (REPLACE(cal.Type,' ','')  ='Trans In(RO)' AND ISNULL(lin.QtyToTransIn,0) >ISNULL(lin.QtyToTransOut,0)) OR (REPLACE(cal.Type,' ','') = REPLACE('Trans Out(SO)',' ','') AND ISNULL(lin.QtyToTransIn,0) >ISNULL(lin.QtyToTransOut,0))
					OR (REPLACE(cal.Type,' ','') = REPLACE('Trans Out(Lot)',' ','') AND ISNULL(lin.QtyToTransOut,0)=0 ) OR (REPLACE(cal.Type,' ','') = REPLACE('Trans In(Lot)',' ','')) )
					--AND ISNULL(lin.StockLineId,1) != ISNULL(stl.StockLineId,0)
					--AND ISNULL(stl.StockLineId,1) NOT IN (ISNULL(lin.StockLineId,0))
					AND ISNULL(po.PurchaseOrderId,1) != ISNULL(lt.InitialPOId,0)
				), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)
				SELECT * INTO #TempResults FROM  Result
				 WHERE ((@GlobalFilter <>''
						OR   
						(@GlobalFilter='')
					   ))
					  SELECT @Count = COUNT(StockLineId) FROM #TempResults			

				SELECT *, @Count AS NumberOfItems FROM #TempResults ORDER BY  
						CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHand END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHand END DESC, 
						CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailable END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailable END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC	
						
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
								
			END	
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Lot_ProcStockListFromLotId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ', 													   
													   @Parameter7 = ' + ISNULL(@StocklineNumber,'') + ', 
													   @Parameter8 = ' + ISNULL(@PartNumber,'') + ', 
													   @Parameter9 = ' + ISNULL(@PartDescription,'') + ', 
													   @Parameter10 = ' + ISNULL(@SerialNumber,'') + ',
													   @Parameter11 = ' + ISNULL(@Condition,'') + ', 
													   @Parameter12 = ' + ISNULL(@QuantityAvailable,'') + ', 
													   @Parameter13 = ' + ISNULL(@ManufacturerName,'') + ', 
													   @Parameter14 = ' + ISNULL(@MasterCompanyId,'') + '' 													   
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH   			
END