/*************************************************************               
 ** File:   [ProcStockListFromItemMasterId]               
 ** Author:  Amit Ghediya    
 ** Description:     
 ** Purpose:             
 ** Date:   04/09/2023          
              
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author  Change Description                
 ** --   --------     -------  --------------------------------              
    1    06/08/2023  Amit Ghediya    Select conditionid    
    2    07/26/2023  Vishal Suthar   Added query block for alternative part stockline  
    3    07/28/2023  Vishal Suthar   Added warehouse and location columns  
    4    09/07/2023  Vishal Suthar   Modified to show only available quantity  
	5    o9/12/2023  Bhargav Saliya  Add two column [QuantityIssued] and [QuantityReserved]
    5    09 NOV 2023  Rajesh Gami    Add flag : @IsFromSOSOQ in the parameter and add code for the same for getting all the itemmaster from the dashboard (trading page SO SOQ)     
-- exec ProcStockListFromItemMasterId @PageNumber=1,@PageSize=5,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@PartNumber=NULL,@PartDescription=NULL,@ManufacturerName=NULL,@SerialNumber=NULL,@Condition=NULL,@StocklineNumber=NULL,@QuantityAvai
lable=NULL,@QuantityOnHand=NULL,@UnitCost=NULL,@PurchaseOrderNumber=NULL,@RepairOrderNumber=NULL,@Vendor=NULL,@EmployeeId=2,@MasterCompanyId=1,@ItemMasterId=514,@ConditionId=N'9,1,111,10,7,8,2,11,101,3,12,14,13,15',@TaggedByName=NULL,@TraceableToName=NULL
,@TraceableToName=NULL,@TagDate=NULL,@IsALTStock=0,@Warehouse=NULL,@Location=NULL  
************************************************************************/    
CREATE   PROCEDURE [dbo].[ProcStockListFromItemMasterId]  
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
@IsFromSOSOQ bit = NULL
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
   BEGIN TRANSACTION
   BEGIN  
		IF(@IsFromSOSOQ = 1)
		BEGIN
					
			;WITH Result AS(      
				SELECT DISTINCT stl.StockLineId,          
					 (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',      
					 (ISNULL(im.PartNumber,'')) 'MainPartNumber',  
			   (ISNULL(im.PartNumber,'')) 'PartNumber',      
					 (ISNULL(im.PartDescription,'')) 'PartDescription',      
					 (ISNULL(im.ManufacturerName,'')) 'ManufacturerName',      
					 CASE WHEN stl.isSerialized = 1 THEN (CASE WHEN ISNULL(stl.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(stl.SerialNumber,'') END) ELSE ISNULL(stl.SerialNumber,'') END AS 'SerialNumber',      
			   (ISNULL(c.ConditionId,'')) 'ConditionId',  
					 (ISNULL(c.Description,'')) 'Condition',  
					 (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',  
					 CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',  
					 CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',  
					 CAST(stl.UnitCost AS varchar) 'UnitCost',  
					 (ISNULL(po.PurchaseOrderNumber,'')) 'PurchaseOrderNumber',  
					 (ISNULL(ro.RepairOrderNumber,'')) 'RepairOrderNumber',  
					 vp.VendorName AS Vendor,  
					 im.MasterCompanyId,  
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
			   ,stl.UnitSalesPrice
			   ,ISNULL((SELECT TOP 1 ISNULL(SP_CalSPByPP_UnitSalePrice,0) FROM dbo.ItemMasterPurchaseSale imp WITH(NOLOCK) WHERE im.ItemMasterId =imp.ItemmasterId AND imp.ConditionId = c.ConditionId),0) AS BaseSalePrice
				FROM  [dbo].[ItemMaster] im WITH (NOLOCK) 					
					LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId in (SELECT Item FROM DBO.SPLITSTRING(@ConditionId,','))
					LEFT JOIN [dbo].[StockLine] stl WITH (NOLOCK) ON im.ItemMasterId = stl.ItemMasterId  AND stl.ConditionId = c.ConditionId AND stl.IsParent = 1  AND stl.IsCustomerStock = 0 AND stl.QuantityOnHand > 0 AND stl.QuantityAvailable > 0     
				    LEFT JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId      
					LEFT JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId      
					LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK) ON stl.RepairOrderId = ro.RepairOrderId      
					LEFT JOIN [dbo].[Vendor] vp WITH (NOLOCK) ON stl.VendorId = vp.VendorId                    
				   WHERE (im.IsDeleted = 0)       
					 AND im.MasterCompanyId = @MasterCompanyId        
				  AND im.ItemMasterId = @ItemMasterId       
				  --AND (@ConditionId IS NULL OR stl.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))      
				  AND im.ItemTypeId  = 1      

				), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)      
				SELECT * INTO #TempResultsSOQ FROM  Result      
				  SELECT @Count = COUNT(StockLineId) FROM #TempResultsSOQ         
      
				  SELECT *, @Count AS NumberOfItems FROM #TempResultsSOQ ORDER BY       
				 
				  CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,      
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC		
            
				 OFFSET @RecordFrom ROWS       
				 FETCH NEXT @PageSize ROWS ONLY      
		
		END  /**END IF @IsFromSOSOQ = 1 **/
		ELSE
		BEGIN
			IF(@IsALTStock IS NULL OR @IsALTStock = 0)  
			BEGIN  
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
					 (ISNULL(po.PurchaseOrderNumber,'')) 'PurchaseOrderNumber',  
					 (ISNULL(ro.RepairOrderNumber,'')) 'RepairOrderNumber',  
					 vp.VendorName AS Vendor,  
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
			   ,stl.UnitSalesPrice
				FROM  [dbo].[StockLine] stl WITH (NOLOCK)      
				   INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId       
				   INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId      
					LEFT JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId      
					LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK) ON stl.RepairOrderId = ro.RepairOrderId      
					LEFT JOIN [dbo].[Vendor] vp WITH (NOLOCK) ON stl.VendorId = vp.VendorId                    
				   WHERE (stl.IsDeleted = 0)       
			   AND stl.QuantityOnHand > 0  
					 AND stl.MasterCompanyId = @MasterCompanyId        
				  AND stl.ItemMasterId = @ItemMasterId       
				  AND (@ConditionId IS NULL OR stl.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))      
				  AND stl.IsParent = 1       
				  AND stl.IsCustomerStock = 0       
				  AND im.ItemTypeId  = 1      
				), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)      
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
				  (PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR       
				  (RepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR       
				  (Vendor LIKE '%' +@GlobalFilter+'%') OR  
			   (TaggedByName LIKE '%' +@GlobalFilter+'%') OR            
				  (TraceableToName LIKE '%' +@GlobalFilter+'%') OR  
			   (TagType LIKE '%' +@GlobalFilter+'%') OR  
			   (Warehouse LIKE '%' +@GlobalFilter+'%') OR  
			   ([Location] LIKE '%' +@GlobalFilter+'%') OR
			   (QuantityIssued LIKE '%' +@GlobalFilter+'%') OR
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
				  (ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber + '%') AND      
				  (ISNULL(@RepairOrderNumber,'') ='' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber + '%') AND      
				  (ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND  
			   (ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND         
			   (ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND          
				  (ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND  
				  (ISNULL(@Warehouse,'') ='' OR Warehouse LIKE '%' + @Warehouse + '%') AND  
				  (ISNULL(@Location,'') ='' OR [Location] LIKE '%' + @Location + '%') AND  
				  (ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND
				  (ISNULL(@QuantityIssued,'') ='' OR QuantityIssued LIKE '%' + @QuantityIssued + '%') AND
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
				  CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,      
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,       
				  CASE WHEN (@SortOrder=1  AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END ASC,      
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END DESC,             
				  CASE WHEN (@SortOrder=1  AND @SortColumn='Vendor')  THEN Vendor END ASC,      
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='Vendor')  THEN Vendor END DESC,     
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
				  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReserved END ASC,      
				  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReserved END DESC
            
				 OFFSET @RecordFrom ROWS       
				 FETCH NEXT @PageSize ROWS ONLY      
				END  
			 ELSE  
			 BEGIN  
			  ;WITH Result AS (  
			   SELECT DISTINCT stl.StockLineId,  
				(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',  
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
				(ISNULL(po.PurchaseOrderNumber,'')) 'PurchaseOrderNumber',  
				(ISNULL(ro.RepairOrderNumber,'')) 'RepairOrderNumber',  
				vp.VendorName AS Vendor,  
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
				,stl.UnitSalesPrice
				FROM Nha_Tla_Alt_Equ_ItemMapping ALT  
				 --[dbo].[StockLine] stl WITH (NOLOCK)      
				 INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON ALT.MappingItemMasterId = im.ItemMasterId --ALTPART      
				 INNER JOIN DBO.ItemMaster IMAl WITH (NOLOCK) ON ALT.ItemMasterId = IMAl.ItemMasterId --MAINPART    
				 INNER JOIN DBO.StockLine stl WITH (NOLOCK) ON im.ItemMasterId = stl.ItemMasterId      
				 INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId      
			   LEFT JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId      
			   LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK) ON stl.RepairOrderId = ro.RepairOrderId      
			   LEFT JOIN [dbo].[Vendor] vp WITH (NOLOCK) ON stl.VendorId = vp.VendorId                    
				 WHERE ALT.MappingType = 1 AND ALT.IsDeleted = 0 AND ALT.IsActive = 1  
				AND stl.IsDeleted = 0  
				AND stl.MasterCompanyId = @MasterCompanyId        
				AND IMAl.ItemMasterId = @ItemMasterId       
				AND (@ConditionId IS NULL OR stl.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))      
				AND stl.IsParent = 1       
				AND stl.QuantityOnHand > 0  
				AND stl.IsCustomerStock = 0       
				AND im.ItemTypeId  = 1      
			  ), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)      
			  SELECT * INTO #TempResults_ALT FROM  Result      
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
				(PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR       
				(RepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR       
				(Vendor LIKE '%' +@GlobalFilter+'%') OR  
				(TaggedByName LIKE '%' +@GlobalFilter+'%') OR            
				(TraceableToName LIKE '%' +@GlobalFilter+'%') OR  
				(TagType LIKE '%' +@GlobalFilter+'%') OR  
				(Warehouse LIKE '%' +@GlobalFilter+'%') OR  
				([Location] LIKE '%' +@GlobalFilter+'%') OR
				(QuantityIssued LIKE '%' +@GlobalFilter+'%') OR
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
				(ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber + '%') AND      
				(ISNULL(@RepairOrderNumber,'') ='' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber + '%') AND      
				(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%') AND  
				(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND            
				(ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND          
				(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND  
				(ISNULL(@Warehouse,'') ='' OR Warehouse LIKE '%' + @Warehouse + '%') AND  
				(ISNULL(@Location,'') ='' OR [Location] LIKE '%' + @Location + '%') AND  
				(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date) AND
				(ISNULL(@QuantityIssued,'') ='' OR QuantityIssued LIKE '%' + @QuantityIssued + '%') AND
				  (ISNULL(@QuantityReserved,'') ='' OR QuantityReserved LIKE '%' + @QuantityReserved + '%'))             
				)      
				)      
				 SELECT @Count = COUNT(StockLineId) FROM #TempResults_ALT         
      
			  SELECT *, @Count AS NumberOfItems FROM #TempResults_ALT ORDER BY        
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
				CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,      
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,       
				CASE WHEN (@SortOrder=1  AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END ASC,      
				CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='Vendor')  THEN Vendor END ASC,      
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Vendor')  THEN Vendor END DESC,     
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
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReserved END ASC,      
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReserved END DESC
            
			   OFFSET @RecordFrom ROWS       
			   FETCH NEXT @PageSize ROWS ONLY    
			 END  
		END
   END      
   	COMMIT  TRANSACTION
END TRY          
  BEGIN CATCH            
   IF @@trancount > 0      
    PRINT 'ROLLBACK'      
    ROLLBACK TRAN;      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
      
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
              , @AdhocComments     VARCHAR(150)    = 'ProcStockListFromItemMasterId'       
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