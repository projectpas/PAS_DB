



CREATE PROCEDURE [dbo].[ProcStockList_123]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@stockTypeId int = NULL,
@StocklineNumber varchar(50) = NULL,
@PartNumber varchar(50) = NULL,
@PartDescription varchar(50) = NULL,
@ItemGroup varchar(50) = NULL,
@UnitOfMeasure varchar(50) = NULL,
@SerialNumber  varchar(50) = NULL,
@GlAccountName varchar(50) = NULL,
@ItemCategory varchar(50) = NULL,
@Condition varchar(50) = NULL,
@QuantityAvailable varchar(50) = NULL,
@QuantityOnHand varchar(50) = NULL,
@CompanyName varchar(50) = NULL,
@BuName varchar(50) = NULL,
@DeptName varchar(50) = NULL,
@DivName varchar(50) = NULL,
@RevisedPN varchar(50) = NULL,
@AWB varchar(50) = NULL,
@ReceivedDate datetime = NULL,
@TagDate datetime = NULL,
@ExpirationDate datetime = NULL,
@ControlNumber varchar(50) = NULL,
@IdNumber varchar(50) = NULL,
@Manufacturer varchar(50) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@EmployeeId bigint=NULL,
@MasterCompanyId bigint = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END	
		IF(@stockTypeId<>1 AND @stockTypeId<>2 )
		BEGIN
			 SET @stockTypeId=NULL;
		END
				
		;WITH Result AS(
				SELECT DISTINCT stl.StockLineId,				
					   (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',
					   (ISNULL(im.PartNumber,'')) 'PartNumber',
					   (ISNULL(im.PartDescription,'')) 'PartDescription',
					   (ISNULL(man.[Name],'')) 'Manufacturer',  
					   (ISNULL(rPart.PartNumber,'')) 'RevisedPN', 					    
					   (ISNULL(ig.[Description],'')) 'ItemGroup', 
					   (ISNULL(um.ShortName,'')) 'UnitOfMeasure',
					   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',					  
					   CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',
					   (ISNULL(stl.SerialNumber,'')) 'SerialNumber',
					   (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber', 
					   stl.ControlNumber,
					   stl.IdNumber,
					   (ISNULL(co.[Description],'')) 'Condition', 					   
					   (ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',
					   (ISNULL(stl.ShippingReference,'')) 'AWB',					  
					   (ISNULL(stl.ExpirationDate,'')) 'ExpirationDate',
					   (ISNULL(stl.TagDate,'')) 'TagDate', 
					   (ISNULL(it.[Description],'')) 'ItemCategory', 
					   (ISNULL(gl.AccountName,'')) 'GlAccountName', 
					   im.ItemTypeId,
					   stl.IsActive,                     
                       stl.CreatedDate,
                       stl.CreatedBy,
					   stl.UpdatedDate,					   
                       stl.UpdatedBy,
					   CASE WHEN level4.Code + level4.Name IS NOT NULL AND 
                         level3.Code + level3.Name IS NOT NULL AND level2.Code IS NOT NULL AND level1.Code + level1.Name IS NOT NULL THEN level1.Code + level1.Name WHEN level4.Code + level4.Name IS NOT NULL AND 
                         level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.Name IS NOT NULL THEN level2.Code + level2.Name WHEN level4.Code + level4.Name IS NOT NULL AND 
                         level3.Code + level3.Name IS NOT NULL THEN level3.Code + level3.Name WHEN level4.Code + level4.Name IS NOT NULL THEN level4.Code + level4.Name ELSE '' END AS CompanyName, 
                         
						 CASE WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.name IS NOT NULL AND level1.Code IS NOT NULL 
                         THEN level2.Code + level2.Name WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.Name IS NOT NULL 
                         THEN level3.Code + level3.Name WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.name IS NOT NULL THEN level4.Code + level4.Name ELSE '' END AS BuName, 

                         CASE WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code IS NOT NULL AND level2.Code + level2.Name IS NOT NULL AND level1.Code + level1.Name IS NOT NULL 
                         THEN level3.Code + level3.Name WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.Name IS NOT NULL 
                         THEN level4.Code + level4.Name ELSE '' END AS DivName, 
						 
						 CASE WHEN level4.Code + level4.Name IS NOT NULL AND level3.Code + level3.Name IS NOT NULL AND level2.Code + level2.Name IS NOT NULL AND 
                         level1.Code + level1.Name IS NOT NULL THEN level4.Code + level4.Name ELSE '' END AS DeptName,
						 EMS.EmployeeId,
						  stl.ManagementStructureId

						  
					   
				 FROM  StockLine stl INNER JOIN ItemMaster im ON stl.ItemMasterId = im.ItemMasterId                     			
									 INNER JOIN GLAccount gl ON im.GLAccountId = gl.GLAccountId 	
									 LEFT JOIN Condition co ON stl.ConditionId = co.ConditionId
									 LEFT JOIN Itemgroup ig ON im.ItemGroupId = ig.ItemGroupId
									 LEFT JOIN ItemType it ON im.ItemTypeId = it.ItemTypeId
									 INNER JOIN  dbo.EmployeeManagementStructure EMS ON EMS.ManagementStructureId = stl.ManagementStructureId
									 INNER JOIN ManagementStructure level4 ON stl.ManagementStructureId = level4.ManagementStructureId
									 LEFT JOIN ManagementStructure level3 ON level4.ParentId = level3.ManagementStructureId
									 LEFT JOIN ManagementStructure level2 ON level3.ParentId = level2.ManagementStructureId
									 LEFT JOIN ManagementStructure level1 ON level2.ParentId = level1.ManagementStructureId
									 LEFT JOIN ItemMaster rPart ON im.RevisedPartId = rPart.ItemMasterId
									 LEFT JOIN Manufacturer man ON stl.ManufacturerId = man.ManufacturerId
									 LEFT JOIN UnitOfMeasure um ON stl.PurchaseUnitOfMeasureId = um.UnitOfMeasureId 								 
																				 
		 	  WHERE ((stl.IsDeleted=0 ) AND (@stockTypeId IS NULL OR im.ItemTypeId=@stockTypeId) 
				    -- AND (stl.IsSameDetailsForAllParts = 1 OR stl.IsSameDetailsForAllParts = 0)
					)			     
					AND stl.MasterCompanyId=@MasterCompanyId 
					--AND EMS.EmployeeId = @EmployeeId					
				    --AND stl.IsParent = 1
			), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
			        (PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(Manufacturer LIKE '%' +@GlobalFilter+'%') OR					
					(RevisedPN LIKE '%' +@GlobalFilter+'%') OR						
					(ItemGroup LIKE '%' +@GlobalFilter+'%') OR						
					(UnitOfMeasure LIKE '%' +@GlobalFilter+'%') OR										
					(QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR
					(QuantityAvailable LIKE '%' +@GlobalFilter+'%') OR
					(SerialNumber LIKE '%' +@GlobalFilter+'%') OR
					(StocklineNumber LIKE '%' +@GlobalFilter+'%') OR					
					(ControlNumber LIKE '%' +@GlobalFilter+'%') OR
					(IdNumber LIKE '%' +@GlobalFilter+'%') OR
					(Condition LIKE '%' +@GlobalFilter+'%') OR
					(AWB LIKE '%' +@GlobalFilter+'%') OR
					(ItemCategory LIKE '%' +@GlobalFilter+'%') OR
					(GlAccountName LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(CompanyName LIKE '%' +@GlobalFilter+'%') OR
					(BuName LIKE '%' +@GlobalFilter+'%') OR
					(DivName LIKE '%' +@GlobalFilter+'%') OR
					(DeptName LIKE '%' +@GlobalFilter+'%') OR					
					(UpdatedBy LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
					(ISNULL(@RevisedPN,'') ='' OR RevisedPN LIKE '%' + @RevisedPN + '%') AND
					(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND
					(ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%') AND				
					(ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND
					(ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND
					(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND
					(ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND					
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
					(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS Date)=CAST(@ReceivedDate AS date)) AND
					(ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND					
					(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND
					(ISNULL(@ItemCategory,'') ='' OR ItemCategory LIKE '%' + @ItemCategory + '%') AND
					(ISNULL(@GlAccountName,'') ='' OR GlAccountName LIKE '%' + @GlAccountName + '%') AND					
					(ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName + '%') AND
					(ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName + '%') AND
					(ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName + '%') AND
					(ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName + '%') AND
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHand END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHand END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailable END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailable END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='GlAccountName')  THEN GlAccountName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='GlAccountName')  THEN GlAccountName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
END