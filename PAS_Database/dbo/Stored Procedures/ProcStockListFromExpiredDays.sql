/*************************************************************               
 ** File:   [ProcStockListFromExpiredDays]               
 ** Author:  RAJESH GAMI 
 ** Description: Getting the stockline detail by expired days     
 ** Purpose:             
 ** Date:   19/AUG/2025          
              
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date			  Author				Change Description                
 ** --   --------		  -------				--------------------------------              
    1    19/AUG/2025	  RAJESH GAMI			Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
************************************************************************/    
CREATE PROCEDURE [dbo].[ProcStockListFromExpiredDays]  
@PageNumber int = NULL,      
@PageSize int = NULL,      
@SortColumn varchar(50)=NULL,      
@SortOrder int = NULL,      
@GlobalFilter varchar(50) = NULL,      
@PartNumber varchar(50) = NULL,      
@PartDescription varchar(50) = NULL,      
@ManufacturerName varchar(50) = NULL,      
@SerialNumber  varchar(50) = NULL,      
@Condition varchar(50) = NULL,      
@StocklineNumber varchar(50) = NULL,      
@QuantityAvailable varchar(50) = NULL,      
@QuantityOnHand varchar(50) = NULL,      
@UnitCost varchar(50) = NULL,      
@PurchaseOrderNumber varchar(50) = NULL,      
@RepairOrderNumber varchar(50) = NULL,      
@Vendor varchar(50) = NULL,      
@EmployeeId BIGINT=NULL,      
@MasterCompanyId BIGINT = NULL,      
@ItemMasterId BIGINT = NULL,      
@ConditionId VARCHAR(250) = NULL,  
@TraceableToName varchar(50) = NULL,            
@TaggedByName varchar(50) = NULL,  
@TagDate datetime = NULL,  
@TagType varchar(50) = NULL,  
@IsALTStock bit NULL,  
@Warehouse varchar(50) = NULL,  
@Location varchar(50) = NULL,
@QuantityIssued varchar(50) = NULL,
@QuantityReserved varchar(50) = NULL ,
@ExpiredInDays INT = 0,
@ExpirationDate datetime = NULL,  
@ReceivedDate datetime = NULL,
@DaysOfExpired varchar(50) = NULL ,
@Site varchar(100) = NULL ,
@Shelf varchar(100) = NULL ,
@Bin varchar(100) = NULL ,
@ReorderPoint varchar(50) = NULL ,
@ReorderQuantiy varchar(50) = NULL ,
@MinimumOrderQuantity varchar(50) = NULL ,
@StockLevel varchar(50) = NULL ,
@OrderQty varchar(50) = NULL,
@ControlNumber varchar(50) = NULL,
@IdNumber varchar(50) = NULL
AS      
BEGIN       
     SET NOCOUNT ON;      
	   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  DECLARE @RecordFrom INT;      
  DECLARE @MSModuelId int;      
  DECLARE @Count Int;      
  DECLARE @IsActive bit;      
  SET @RecordFrom = (@PageNumber-1)*@PageSize;       
  SET @MSModuelId = 2;   -- For Stockline      
      
  IF @SortColumn IS NULL      
  BEGIN      
   SET @SortColumn=Upper('ExpirationDate')   
   SET @SortOrder=-1
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
   BEGIN TRANSACTION
   BEGIN  

				DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '',@BaseUtcOffsetSec INT    ;
				
				SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
	
					SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec  
					FROM dbo.TimeZone WITH(NOLOCK)  
					WHERE [Description] = @CurrntEmpTimeZoneDesc    


				;WITH Result AS(      
				 SELECT DISTINCT stl.StockLineId,          
					   (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',      
					   (ISNULL(im.PartNumber,'')) 'MainPartNumber',  
					   (ISNULL(im.PartNumber,'')) 'PartNumber',      
					   (ISNULL(im.PartDescription,'')) 'PartDescription',      
					   (ISNULL(im.ManufacturerName,'')) 'ManufacturerName',      
					   CASE WHEN stl.isSerialized = 1 THEN (CASE WHEN ISNULL(stl.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(stl.SerialNumber,'') END) ELSE ISNULL(stl.SerialNumber,'') END AS 'SerialNumber',      
					   (ISNULL(stl.ConditionId,'')) 'ConditionId',  
					   (ISNULL(stl.Condition,'')) 'Condition',  
					   (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',  
					   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',  
					   CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',  
					   CAST(stl.UnitCost AS varchar) 'UnitCost',  
					   stl.MasterCompanyId,  
					   stl.CreatedDate,  
					   0 AS Isselected,  
					   0 AS IsCustomerStock,  
					   stl.TagDate 'TagDate',  
					   (ISNULL(stl.TaggedByName,'')) 'TaggedByName',  
					   (ISNULL(stl.TraceableToName,'')) 'TraceableToName',  
					   (ISNULL(stl.TagType,'')) 'TagType',  
					   (ISNULL(stl.Warehouse,'')) 'Warehouse',  
					   (ISNULL(stl.[Location],'')) 'Location',
					   CAST(stl.QuantityIssued AS varchar) 'QuantityIssued',
					   CAST(stl.QuantityReserved AS varchar) 'QuantityReserved'
					   ,stl.SalesPriceExpiryDate
					   ,stl.UnitSalesPrice,
					   stl.ExpirationDate,
					   stl.ReceivedDate,
					   DaysOfExpired = 
							CASE 
								WHEN stl.ExpirationDate IS NULL 
									THEN NULL  
								ELSE DATEDIFF(DAY, CAST(GETDATE() AS DATE), CAST(DATEADD(SECOND, @BaseUtcOffsetSec, stl.ExpirationDate) AS DATE))
							END,
					   ISNULL(stl.[Site],'') as [Site],
					   ISNULL(stl.Shelf,'') as Shelf,
					   ISNULL(stl.Bin,'') as  Bin,
					   ISNULL(im.ReorderPoint,0)ReorderPoint,
					   ISNULL(im.ReorderQuantiy,0)ReorderQuantiy,
					   ISNULL(im.MinimumOrderQuantity,0)MinimumOrderQuantity,
					   ISNULL(im.StockLevel,0)StockLevel,
					   stl.Quantity as OrderQty,
					   stl.ControlNumber,
					   stl.IdNumber
				FROM  [dbo].[StockLine] stl WITH (NOLOCK)      
				   INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId       
				   INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId      
				   WHERE (stl.IsDeleted = 0)       
					  AND stl.MasterCompanyId = @MasterCompanyId        
			
					  AND (@ConditionId IS NULL OR stl.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))      
					  AND stl.IsParent = 1       
					  AND stl.IsCustomerStock = 0       
					  AND im.ItemTypeId  = 1
					AND (
						   stl.ExpirationDate IS NOT NULL
						   AND CAST(DATEADD(SECOND, @BaseUtcOffsetSec, stl.ExpirationDate) AS DATE)
								BETWEEN CAST(GETDATE() AS DATE) 
									AND CAST(DATEADD(DAY, @ExpiredInDays, GETDATE()) AS DATE)
						)
				 AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(stl.IsNonStock,0) = 0), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)      
				SELECT * INTO #TempResults FROM  Result      
				 WHERE ((@GlobalFilter <>'' AND       
					   ((PartNumber LIKE '%' +@GlobalFilter+'%') OR      
						(PartDescription LIKE '%' +@GlobalFilter+'%') OR       
						  (ManufacturerName LIKE '%' +@GlobalFilter+'%') OR       
						  (SerialNumber LIKE '%' +@GlobalFilter+'%') OR      
						  (Condition LIKE '%' +@GlobalFilter+'%') OR      
						  (StocklineNumber LIKE '%' +@GlobalFilter+'%') OR       
						  (QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR      
						  (QuantityAvailable LIKE '%' +@GlobalFilter+'%') OR      
						  (UnitCost LIKE '%' +@GlobalFilter+'%') OR      
						(TaggedByName LIKE '%' +@GlobalFilter+'%') OR            
						  (TraceableToName LIKE '%' +@GlobalFilter+'%') OR  
					   (TagType LIKE '%' +@GlobalFilter+'%') OR  
					   (Warehouse LIKE '%' +@GlobalFilter+'%') OR  
					   ([Location] LIKE '%' +@GlobalFilter+'%') OR
					   (QuantityIssued LIKE '%' +@GlobalFilter+'%') OR
					   (DaysOfExpired LIKE '%' +@DaysOfExpired+'%') OR
					   ([Site] LIKE '%' +@Site+'%') OR
					   (Shelf LIKE '%' +@Shelf+'%') OR
					   (Bin LIKE '%' +@Bin+'%') OR
					   (ControlNumber LIKE '%' +@ControlNumber+'%') OR
					   (IdNumber LIKE '%' +@IdNumber+'%') OR
					   (QuantityReserved LIKE '%' +@GlobalFilter+'%')))       
				  OR         
				  (@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND      
				  (ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND      
				  (ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND      
				  (ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND      
				  (ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND      
				  (ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND       
				  (ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND      
				  (ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND      
				  (ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%') AND      
			   (ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND         
			   (ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND          
				  (ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND  
				  (ISNULL(@Warehouse,'') ='' OR Warehouse LIKE '%' + @Warehouse + '%') AND  
				  (ISNULL(@Location,'') ='' OR [Location] LIKE '%' + @Location + '%') AND  
				  (ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND  (ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND   
				  (ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS Date)=CAST(@ReceivedDate AS date)) AND
				  (ISNULL(@DaysOfExpired,'') ='' OR DaysOfExpired LIKE '%' + @DaysOfExpired + '%') AND
				  (ISNULL(@Site,'') ='' OR [Site] LIKE '%' + @Site + '%') AND
				  (ISNULL(@Bin,'') ='' OR Bin LIKE '%' + @Bin + '%') AND
				  (ISNULL(@ReorderPoint,'') ='' OR ReorderPoint LIKE '%' + @ReorderPoint + '%') AND
				  (ISNULL(@ReorderQuantiy,'') ='' OR ReorderQuantiy LIKE '%' + @ReorderQuantiy + '%') AND
				  (ISNULL(@MinimumOrderQuantity,'') ='' OR MinimumOrderQuantity LIKE '%' + @MinimumOrderQuantity + '%') AND
				  (ISNULL(@StockLevel,'') ='' OR StockLevel LIKE '%' + @StockLevel + '%') AND
				  (ISNULL(@OrderQty,'') ='' OR OrderQty LIKE '%' + @OrderQty + '%') AND
				  (ISNULL(@QuantityIssued,'') ='' OR QuantityIssued LIKE '%' + @QuantityIssued + '%') AND
				  		  (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND  
						  		  (ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND  
				  (ISNULL(@QuantityReserved,'') ='' OR QuantityReserved LIKE '%' + @QuantityReserved + '%')
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
			   CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,            
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,             
				  CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,            
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,  
			   CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,          
			   CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,           
			   CASE WHEN (@SortOrder=1  AND @SortColumn='Warehouse')  THEN Warehouse END ASC,            
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='Warehouse')  THEN Warehouse END DESC,  
			   CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN [Location] END ASC,     
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN [Location] END DESC,  
			   CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,            
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,      
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityIssued')  THEN QuantityIssued END ASC,      
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityIssued')  THEN QuantityIssued END DESC,
				  
				  CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='DaysOfExpired')  THEN DaysOfExpired END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='DaysOfExpired')  THEN DaysOfExpired END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='Site')  THEN Site END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='Site')  THEN Site END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='Shelf')  THEN Shelf END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='Shelf')  THEN Shelf END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='Bin')  THEN Bin END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='Bin')  THEN Bin END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='ReorderPoint')  THEN ReorderPoint END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReorderPoint')  THEN ReorderPoint END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='ReorderQuantiy')  THEN ReorderQuantiy END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReorderQuantiy')  THEN ReorderQuantiy END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='MinimumOrderQuantity')  THEN MinimumOrderQuantity END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='MinimumOrderQuantity')  THEN MinimumOrderQuantity END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='StockLevel')  THEN StockLevel END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='StockLevel')  THEN StockLevel END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='OrderQty')  THEN OrderQty END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='OrderQty')  THEN OrderQty END DESC,

				  CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC, 
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,
				  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReserved END ASC,      
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReserved END DESC
            
				 OFFSET @RecordFrom ROWS       
				 FETCH NEXT @PageSize ROWS ONLY      
   END      
   	COMMIT  TRANSACTION
END TRY          
  BEGIN CATCH            
   IF @@trancount > 0      
    PRINT 'ROLLBACK'      
    ROLLBACK TRAN;      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
      
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
              , @AdhocComments     VARCHAR(150)    = 'ProcStockListFromExpiredDays'       
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