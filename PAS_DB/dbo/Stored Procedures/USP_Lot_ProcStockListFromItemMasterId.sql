/*************************************************************           
 ** File:   [USP_Lot_ProcStockListFromItemMasterId]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to get available qty >0 stocklines from the Item Master.
 ** Purpose:         
 ** Date:  04/09/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/09/2023  Rajesh Gami    Created
     
-- EXEC USP_Lot_ProcStockListFromItemMasterId
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_ProcStockListFromItemMasterId]
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
@TraceableToName varchar(200) = NULL,
@TaggedByName varchar(200) = NULL,
@TagDate datetime = NULL,
@ItemMasterId BIGINT = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
		DECLARE @RecordFrom INT;
		DECLARE @MSModuelId int;
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;	
		SET @MSModuelId = 2;   -- For Stockline
		--Select  @MSModuelId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'StockLine';

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
						   UPPER((ISNULL(im.PartNumber,''))) 'PartNumber',
						   UPPER((ISNULL(im.PartDescription,''))) 'PartDescription',
						   UPPER((ISNULL(im.ManufacturerName,''))) 'ManufacturerName',
						   CASE WHEN stl.isSerialized = 1 THEN UPPER(ISNULL(stl.SerialNumber,'')) ELSE UPPER(ISNULL(stl.SerialNumber,'')) END AS 'SerialNumber',
						   UPPER(ISNULL(con.Description,'')) 'Condition', 	
						   UPPER((ISNULL(stl.StockLineNumber,''))) 'StocklineNumber', 
						   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',
						   CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',
						   CAST(stl.UnitCost AS varchar) 'UnitCost',						   
						   UPPER((ISNULL(po.PurchaseOrderNumber,''))) 'PurchaseOrderNumber',
						   UPPER((ISNULL(ro.RepairOrderNumber,''))) 'RepairOrderNumber',		
						   vp.VendorName AS Vendor,						  
						   stl.MasterCompanyId,	
						   stl.CreatedDate,
						   0 AS Isselected,
						   0 AS IsCustomerStock,
						   UPPER(MSD.Level1Name) AS cO,
						   UPPER(MSD.Level2Name) AS bU,
						   UPPER(MSD.Level3Name) AS div,
						   UPPER(MSD.Level4Name) AS dept
						  ,UPPER(MSD.LastMSLevel) LastMSLevel
					      ,UPPER(MSD.AllMSlevels) AllMSlevels
						  ,UPPER(stl.UnitOfMeasure) AS Uom
						  ,UPPER(stl.ControlNumber) AS CntrlNumber
						  	,stl.TraceableToName
							,stl.TaggedByName
							,stl.TagDate
					 FROM  [dbo].[StockLine] stl WITH (NOLOCK)
							INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId 
							INNER JOIN [dbo].[StocklineManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ReferenceID = stl.StockLineId AND MSD.ModuleID = @MSModuelId
							INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId    
							INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
							LEFT JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
							LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK) ON stl.RepairOrderId = ro.RepairOrderId
							LEFT JOIN [dbo].[Vendor] vp WITH (NOLOCK) ON stl.VendorId = vp.VendorId
							LEFT JOIN [dbo].[Condition] con WITH(NOLOCK) ON stl.ConditionId = con.ConditionId
		 		  WHERE (stl.IsDeleted = 0) 
				     AND stl.MasterCompanyId = @MasterCompanyId  
					 AND stl.ItemMasterId = @ItemMasterId					
					 AND stl.IsParent = 1 
					 AND ISNULL(stl.IsCustomerStock,0) = 0 
					 AND im.ItemTypeId  = 1
					 AND ISNULL(stl.QuantityAvailable,0) >0
					 AND ISNULL(stl.LotId,0) = 0
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
						(TraceableToName like '%' +@GlobalFilter+'%') OR
						(TaggedByName like '%' +@GlobalFilter+'%') OR
						(TagDate like '%' +@GlobalFilter+'%') OR
						(Vendor LIKE '%' +@GlobalFilter+'%')))	
						OR   
						(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
						(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
						(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @GlobalFilter + '%') AND
						(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND
						(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
						(ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND	
						(ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND
						(ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND
						(ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%') AND
						(ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber + '%') AND
						(ISNULL(@RepairOrderNumber,'') ='' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber + '%') AND
							(IsNull(@TraceableToName,'') ='' OR TraceableToName like '%'+ @TraceableToName+'%') and
							(IsNull(@TaggedByName,'') ='' OR TaggedByName like '%'+ @TaggedByName+'%') and
							(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date) = CAST(@TagDate AS date)) AND
						(ISNULL(@Vendor,'') ='' OR Vendor LIKE '%' + @Vendor + '%'))
					   )
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
              , @AdhocComments     VARCHAR(150)    = 'USP_Lot_ProcStockListFromItemMasterId' 
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