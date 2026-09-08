/*************************************************************   
** Author:  <Moin Bloch>  
** Create date: <19/08/2026>  
** Description: <Get Work Order MPN details for INternal Customer>  
  
EXEC [GetWorkOrderMPNInternalStocklineList] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
    1   19/08/2026  Moin Bloch      Created [PN-17372]
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWorkOrderMPNInternalItemMasterList]  
@PageNumber INT = NULL,  
@PageSize INT = NULL,  
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,  
@GlobalFilter VARCHAR(50) = NULL,  
@PartNumber VARCHAR(50) = NULL,  
@PartDescription VARCHAR(50) = NULL,  
@ManufacturerName VARCHAR(50) = NULL,  
@IsSerialized VARCHAR(50) = NULL,
@UnitOfMeasure VARCHAR(50) = NULL,  
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
		  SELECT @TeardownWorkOrderTypeId = Id FROM dbo.WorkOrderType WITH(NOLOCK) WHERE UPPER([Description]) = 'INTERNAL TEARDOWN';
  
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
			 SELECT  (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',  
					 (ISNULL(im.PartNumber,'')) 'PartNumber',  
					 (ISNULL(im.PartDescription,'')) 'PartDescription',  
					 (ISNULL(im.ManufacturerName,'')) 'ManufacturerName', 					  
					  CASE WHEN im.IsSerialized = 1 THEN 'Yes' ELSE 'No' END AS IsSerialized,
					 (ISNULL(um.ShortName,'')) 'UnitOfMeasure',					
					 CAST(0 AS varchar) 'UnitCost',           
					 im.MasterCompanyId,   
					 im.CreatedDate,  
					 0 AS Quantity,
					 0 AS Isselected 				 
			  FROM  [dbo].[ItemMaster] im WITH (NOLOCK)  					 
					INNER JOIN [dbo].[UnitOfMeasure] um WITH (NOLOCK) ON im.PurchaseUnitOfMeasureId = um.UnitOfMeasureId 
			  WHERE (@ItemMasterId IS NULL OR im.[ItemMasterId] = @ItemMasterId) 
			  AND (im.IsDeleted = 0) AND im.MasterCompanyId = @MasterCompanyId AND im.[IsKitAssy] = 1 --AND @WorkOrderTypeId = @TeardownWorkOrderTypeId
			  ), 
			  ResultCount AS(SELECT COUNT(ItemMasterId) AS totalItems FROM Result)  
			SELECT * INTO #TempResults FROM  Result  
			 WHERE ((@GlobalFilter <>'' AND   
				   ((PartNumber LIKE '%' +@GlobalFilter+'%') OR  
				    (PartDescription LIKE '%' +@GlobalFilter+'%') OR   
				    (ManufacturerName LIKE '%' +@GlobalFilter+'%') OR   	
					(IsSerialized LIKE '%' +@GlobalFilter+'%') OR
					(UnitOfMeasure LIKE '%' +@GlobalFilter+'%')   				 				    
					))
					OR     
				    (@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND  
				    (ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND  
				    (ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND  
					(ISNULL(@IsSerialized,'') ='' OR IsSerialized LIKE '%' + @IsSerialized + '%') AND
					(ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%')   				   
					))  
			   
			SELECT @Count = COUNT(ItemMasterId) FROM #TempResults     
  
			SELECT *, @Count AS NumberOfItems FROM #TempResults ORDER BY    
			  CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,  
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,  
			  CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,  
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,  
			  CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,  
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,  			
			  CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,  
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,			 
			  CASE WHEN (@SortOrder=1  AND @SortColumn='IsSerialized')  THEN IsSerialized END ASC,
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsSerialized')  THEN IsSerialized END DESC, 
			  CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,  
			  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC  
			          
			 OFFSET @RecordFrom ROWS   
			 FETCH NEXT @PageSize ROWS ONLY            
   END   
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderMPNInternalItemMasterList'   				
				,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100)) 
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100)) 
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100)) 
			   + '@Parameter6 = ''' + CAST(ISNULL(@PartNumber, '') AS VARCHAR(100)) 
			   + '@Parameter7 = ''' + CAST(ISNULL(@PartDescription, '') AS VARCHAR(100)) 
			   + '@Parameter8 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) 
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