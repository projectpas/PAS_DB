
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <06/02/2023>  
** Description: <Get Work Order MPN details for INternal Customer>  
  
EXEC [GetWorkOrderMPNInternalStocklineList] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    06/02/2023  HEMANT SALIYA    Get Work Order MPN details for INternal Customer

exec GetWorkOrderMPNInternalStocklineList @PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@PartNumber=NULL,@PartDescription=NULL,
@ManufacturerName=NULL,@SerialNumber=NULL,@Condition=NULL,@StocklineNumber=NULL,@QuantityAvailable=NULL,@QuantityOnHand=NULL,@UnitCost=NULL,@EmployeeId=2,@MasterCompanyId=1,
@ItemMasterId=0,@ConditionId=NULL,@workOrderTypeId=3,@CustomerId=2178

**************************************************************/ 

CREATE   PROCEDURE [dbo].[GetWorkOrderMPNInternalStocklineList]  
@PageNumber INT = NULL,  
@PageSize INT = NULL,  
@SortColumn VARCHAR(50)=NULL,  
@SortOrder INT = NULL,  
@GlobalFilter VARCHAR(50) = NULL,  
@PartNumber VARCHAR(50) = NULL,  
@PartDescription VARCHAR(50) = NULL,  
@ManufacturerName VARCHAR(50) = NULL,  
@SerialNumber  VARCHAR(50) = NULL,  
@Condition VARCHAR(50) = NULL,  
@StocklineNumber VARCHAR(50) = NULL,  
@ControlNumber VARCHAR(50) = NULL,  
@UnitOfMeasure VARCHAR(50) = NULL,  
@QuantityAvailable VARCHAR(50) = NULL,  
@QuantityOnHand VARCHAR(50) = NULL,  
@UnitCost VARCHAR(50) = NULL,  
@EmployeeId BIGINT=NULL,  
@MasterCompanyId BIGINT = NULL,  
@ItemMasterId BIGINT = NULL,  
@ConditionId BIGINT = NULL,  
@WorkOrderTypeId INT = NULL,
@CustomerId BIGINT = NULL
AS  
BEGIN   
     SET NOCOUNT ON;  
		  DECLARE @RecordFrom INT;  
		  DECLARE @MSModuelId INT;  
		  DECLARE @Count INT;  
		  DECLARE @IsActive bit;  
		  DECLARE @TeardownWorkOrderTypeId INT;

		  SET @RecordFrom = (@PageNumber-1)*@PageSize;   
		  SET @MSModuelId = 2;   -- For Stockline  
		  SELECT @TeardownWorkOrderTypeId = Id FROM dbo.WorkOrderType WITH(NOLOCK) where UPPER([Description]) = 'TEARDOWN';
  
		  IF @SortColumn IS NULL  
		  BEGIN  
		   SET @SortColumn=Upper('CreatedDate')  
		  END   
		  ELSE  
		  BEGIN   
		   Set @SortColumn=Upper(@SortColumn)  
		  END   
     
		  IF @ItemMasterId = 0  
		  BEGIN  
		   SET @ItemMasterId = NULL  
		  END   
		  BEGIN TRY    
		   BEGIN      
			;WITH Result AS(  
			 SELECT DISTINCT stl.StockLineId,      
					 (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',  
					 (ISNULL(im.PartNumber,'')) 'PartNumber',  
					 (ISNULL(im.PartDescription,'')) 'PartDescription',  
					 (ISNULL(im.ManufacturerName,'')) 'ManufacturerName',  
					 CASE WHEN stl.isSerialized = 1 THEN (CASE WHEN ISNULL(stl.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(stl.SerialNumber,'') END) ELSE ISNULL(stl.SerialNumber,'') END AS 'SerialNumber',  
					 (ISNULL(stl.Condition,'')) 'Condition',    
					 (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',   
					 (ISNULL(stl.ControlNumber,'')) 'ControlNumber',   
					 (ISNULL(um.ShortName,'')) 'UnitOfMeasure',
					 CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',  
					 CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',  
					 CAST(stl.UnitCost AS varchar) 'UnitCost',           
					 stl.MasterCompanyId,   
					 stl.CreatedDate,  
					 0 AS Isselected,  
					 ISNULL(stl.IsCustomerStock, 0) AS IsCustomerStock  
			  FROM  [dbo].[StockLine] stl WITH (NOLOCK)  
					INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId 
					INNER JOIN [dbo].[UnitOfMeasure] um WITH (NOLOCK) ON im.PurchaseUnitOfMeasureId = um.UnitOfMeasureId 
					INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId  
			  WHERE (stl.IsDeleted = 0) AND stl.MasterCompanyId = @MasterCompanyId AND ISNULL(stl.QuantityOnHand, 0) > 0 AND ISNULL(stl.QuantityAvailable, 0) > 0     
			  AND stl.IsParent = 1 AND (stl.IsCustomerStock = 0 OR (stl.IsCustomerStock = 1 AND stl.CustomerId = @CustomerId AND @WorkOrderTypeId = @TeardownWorkOrderTypeId))
			), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)  
			SELECT * INTO #TempResults FROM  Result  
			 WHERE ((@GlobalFilter <>'' AND   
				   ((PartNumber LIKE '%' +@GlobalFilter+'%') OR  
				    (PartDescription LIKE '%' +@GlobalFilter+'%') OR   
				    (ManufacturerName LIKE '%' +@GlobalFilter+'%') OR   
				    (SerialNumber LIKE '%' +@GlobalFilter+'%') OR  
				    (Condition LIKE '%' +@GlobalFilter+'%') OR  
				    (StocklineNumber LIKE '%' +@GlobalFilter+'%') OR   
					(ControlNumber LIKE '%' +@GlobalFilter+'%') OR   
					(UnitOfMeasure LIKE '%' +@GlobalFilter+'%') OR   
				    (QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR  
				    (QuantityAvailable LIKE '%' +@GlobalFilter+'%') OR  
				    (UnitCost LIKE '%' +@GlobalFilter+'%')))
					OR     
				    (@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND  
				    (ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND  
				    (ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND  
				    (ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND  
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND  
					(ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%') AND  
				    (ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND  
				    (ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND   
				    (ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND  
				    (ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND  
				    (ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%')))  
			   
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
			  CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,  
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
			  CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,  
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,
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
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderMPNInternalStocklineList'   
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
                @Parameter13 = ' + ISNULL(@QuantityOnHand,'') + ',                                  
                @Parameter16 = ' + ISNULL(@EmployeeId,'') + ',   
                @Parameter17 = ' + ISNULL(@ManufacturerName,'') + ',   
                @Parameter18 = ' + ISNULL(@MasterCompanyId,'') + ''                   
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