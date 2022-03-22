
CREATE PROCEDURE [dbo].[ProcStockList]
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
@TraceableToName varchar(50) = NULL,
@TaggedByName varchar(50) = NULL,
@TagType varchar(50) = NULL,
@TagDate datetime = NULL,
@ExpirationDate datetime = NULL,
@ControlNumber varchar(50) = NULL,
@IdNumber varchar(50) = NULL,
@Manufacturer varchar(50) = NULL,
@PartCertificationNumber varchar(50) = NULL,
@CertifiedBy  varchar(50) = NULL,
@CertifiedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@EmployeeId BIGINT=NULL,
@MasterCompanyId BIGINT = NULL,
@IsCustomerStock varchar(50) = NULL,
@ItemMasterId BIGINT = NULL,
@StockLineIds varchar(1000) = NULL,
@obtainFrom varchar(50) = NULL,
@ownerName varchar(50) = NULL
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

		--IF(@stockTypeId<>1 AND @stockTypeId<>2 )
		--BEGIN
		--	 SET @stockTypeId=NULL;
		--END

		IF(@stockTypeId = 0)
		BEGIN
			 SET @stockTypeId = NULL;
		END

		IF @ItemMasterId = 0
		BEGIN
			SET @ItemMasterId = NULL
		END 

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF @stockTypeId = 1 -- Qty OH > 0
				BEGIN
					;WITH Result AS(
					SELECT DISTINCT stl.StockLineId,				
						   (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',
						   (ISNULL(im.PartNumber,'')) 'PartNumber',
						   (ISNULL(im.PartDescription,'')) 'PartDescription',
						   (ISNULL(stl.Manufacturer,'')) 'Manufacturer',  
						   (ISNULL(rPart.PartNumber,'')) 'RevisedPN', 					    
						   (ISNULL(stl.ItemGroup,'')) 'ItemGroup', 
						   (ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',
						   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',
						   stl.QuantityOnHand  as QuantityOnHandnew,
						   CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',
						   stl.QuantityAvailable  as QuantityAvailablenew,
						   (ISNULL(stl.SerialNumber,'')) 'SerialNumber',
						   (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber', 
						   stl.ControlNumber,
						   stl.IdNumber,
						   (ISNULL(stl.Condition,'')) 'Condition', 					   
						   (ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',
						   (ISNULL(stl.ShippingReference,'')) 'AWB',					  
						   (ISNULL(stl.ExpirationDate,'')) 'ExpirationDate',
						   (ISNULL(stl.TagDate,'')) 'TagDate',
						   (ISNULL(stl.TaggedByName,'')) 'TaggedByName',
						   (ISNULL(stl.TagType,'')) 'TagType',	
						   (ISNULL(stl.TraceableToName,'')) 'TraceableToName',					   
						   (ISNULL(stl.itemType,'')) 'ItemCategory', 
						   --(ISNULL(stl.GlAccountName,'')) 'GlAccountName', 
						   im.ItemTypeId,
						   stl.IsActive,                     
						   stl.CreatedDate,
						   stl.CreatedBy,
						   stl.PartCertificationNumber,
						   stl.CertifiedBy,
						   stl.CertifiedDate,
						   stl.UpdatedDate,					   
						   stl.UpdatedBy,
						   stl.level1 AS CompanyName,
						   stl.level2 AS BuName,
						   stl.level3 AS DivName,
						   stl.level4 AS DeptName,	
						   CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,
						   stl.ObtainFromName AS obtainFrom,
						   stl.OwnerName AS ownerName
					 FROM  StockLine stl WITH (NOLOCK)
							INNER JOIN ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId 
							INNER JOIN  dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = stl.ManagementStructureId
							LEFT JOIN ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId									 
		 		  WHERE ((stl.IsDeleted=0 ) AND (stl.QuantityOnHand > 0)) AND (@StockLineIds IS NULL OR stl.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,',')))			     
						AND stl.MasterCompanyId=@MasterCompanyId AND EMS.EmployeeId = @EmployeeId AND (@ItemMasterId IS NULL OR stl.ItemMasterId = @ItemMasterId)					
						AND stl.IsParent = 1
				), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)
				SELECT * INTO #TempResults FROM  Result
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
						(TaggedByName LIKE '%' +@GlobalFilter+'%') OR
						(TagType LIKE '%' +@GlobalFilter+'%') OR
						(TraceableToName LIKE '%' +@GlobalFilter+'%') OR					
						(IdNumber LIKE '%' +@GlobalFilter+'%') OR
						(Condition LIKE '%' +@GlobalFilter+'%') OR
						(AWB LIKE '%' +@GlobalFilter+'%') OR
						(ItemCategory LIKE '%' +@GlobalFilter+'%') OR
						(IsCustomerStock LIKE '%' +@GlobalFilter+'%') OR
						(PartCertificationNumber LIKE '%' +@GlobalFilter+'%') OR
						(CertifiedBy LIKE '%' +@GlobalFilter+'%') OR
						(CompanyName LIKE '%' +@GlobalFilter+'%') OR
						(BuName LIKE '%' +@GlobalFilter+'%') OR
						(DivName LIKE '%' +@GlobalFilter+'%') OR
						(DeptName LIKE '%' +@GlobalFilter+'%') OR					
						(obtainFrom LIKE '%' +@GlobalFilter+'%') OR
						(ownerName LIKE '%' +@GlobalFilter+'%') OR
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
						(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND
						(ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND
						(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND					
						(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND
						(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
						(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS Date)=CAST(@ReceivedDate AS date)) AND
						(ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND					
						(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND
						(ISNULL(@ItemCategory,'') ='' OR ItemCategory LIKE '%' + @ItemCategory + '%') AND
						(ISNULL(@AWB,'') ='' OR AWB LIKE '%' + @AWB + '%') AND					
						(ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName + '%') AND
						(ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName + '%') AND
						(ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName + '%') AND
						(ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName + '%') AND
						(ISNULL(@PartCertificationNumber,'') ='' OR PartCertificationNumber LIKE '%' + @PartCertificationNumber + '%') AND
						(ISNULL(@CertifiedBy,'') ='' OR CertifiedBy LIKE '%' + @CertifiedBy + '%') AND
						(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
						(ISNULL(@CertifiedDate,'') ='' OR CAST(CertifiedDate AS Date)=CAST(@CertifiedDate AS date)) AND
						(ISNULL(@IsCustomerStock,'') ='' OR IsCustomerStock LIKE '%' + @IsCustomerStock + '%') AND						
						(ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND
						(ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND
						(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
					   )
					   SELECT @Count = COUNT(StockLineId) FROM #TempResults			

					SELECT *, @Count AS NumberOfItems FROM #TempResults ORDER BY  
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
						CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC, 
						CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,			
						CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
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
						CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,					
						CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,	
						CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,
						CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC
				
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
				END
				ELSE -- ALL
				BEGIN
					;WITH Result AS(
					SELECT DISTINCT stl.StockLineId,				
						   (ISNULL(im.ItemMasterId,0)) 'ItemMasterId',
						   (ISNULL(im.PartNumber,'')) 'PartNumber',
						   (ISNULL(im.PartDescription,'')) 'PartDescription',
						   (ISNULL(stl.Manufacturer,'')) 'Manufacturer',  
						   (ISNULL(rPart.PartNumber,'')) 'RevisedPN', 					    
						   (ISNULL(stl.ItemGroup,'')) 'ItemGroup', 
						   (ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',
						   CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',
						   stl.QuantityOnHand  as QuantityOnHandnew,
						   CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',
						   stl.QuantityAvailable  as QuantityAvailablenew,
						   (ISNULL(stl.SerialNumber,'')) 'SerialNumber',
						   (ISNULL(stl.StockLineNumber,'')) 'StocklineNumber', 
						   stl.ControlNumber,
						   stl.IdNumber,
						   (ISNULL(stl.Condition,'')) 'Condition', 					   
						   (ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',
						   (ISNULL(stl.ShippingReference,'')) 'AWB',					  
						   (ISNULL(stl.ExpirationDate,'')) 'ExpirationDate',
						   (ISNULL(stl.TagDate,'')) 'TagDate',
						   (ISNULL(stl.TaggedByName,'')) 'TaggedByName',
						   (ISNULL(stl.TagType,'')) 'TagType',	
						   (ISNULL(stl.TraceableToName,'')) 'TraceableToName',					   
						   (ISNULL(stl.itemType,'')) 'ItemCategory', 
						   --(ISNULL(stl.GlAccountName,'')) 'GlAccountName', 
						   im.ItemTypeId,
						   stl.IsActive,                     
						   stl.CreatedDate,
						   stl.CreatedBy,
						   stl.PartCertificationNumber,
						   stl.CertifiedBy,
						   stl.CertifiedDate,
						   stl.UpdatedDate,					   
						   stl.UpdatedBy,
						   stl.level1 AS CompanyName,
						   stl.level2 AS BuName,
						   stl.level3 AS DivName,
						   stl.level4 AS DeptName,	
						   CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,
						   stl.ObtainFromName AS obtainFrom,
						   stl.OwnerName AS ownerName
					 FROM  StockLine stl WITH (NOLOCK)
							INNER JOIN ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId 
							INNER JOIN  dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = stl.ManagementStructureId
							LEFT JOIN ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId									 
		 		  WHERE ((stl.IsDeleted=0 ) AND (@stockTypeId IS NULL OR im.ItemTypeId=@stockTypeId)) AND (@StockLineIds IS NULL OR stl.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,',')))			     
						AND stl.MasterCompanyId=@MasterCompanyId AND EMS.EmployeeId = @EmployeeId AND (@ItemMasterId IS NULL OR stl.ItemMasterId = @ItemMasterId)					
						AND stl.IsParent = 1
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
						(TaggedByName LIKE '%' +@GlobalFilter+'%') OR
						(TagType LIKE '%' +@GlobalFilter+'%') OR
						(TraceableToName LIKE '%' +@GlobalFilter+'%') OR					
						(IdNumber LIKE '%' +@GlobalFilter+'%') OR
						(Condition LIKE '%' +@GlobalFilter+'%') OR
						(AWB LIKE '%' +@GlobalFilter+'%') OR
						(ItemCategory LIKE '%' +@GlobalFilter+'%') OR
						(IsCustomerStock LIKE '%' +@GlobalFilter+'%') OR
						(PartCertificationNumber LIKE '%' +@GlobalFilter+'%') OR
						(CertifiedBy LIKE '%' +@GlobalFilter+'%') OR
						(CompanyName LIKE '%' +@GlobalFilter+'%') OR
						(BuName LIKE '%' +@GlobalFilter+'%') OR
						(DivName LIKE '%' +@GlobalFilter+'%') OR
						(DeptName LIKE '%' +@GlobalFilter+'%') OR					
						(obtainFrom LIKE '%' +@GlobalFilter+'%') OR
						(ownerName LIKE '%' +@GlobalFilter+'%') OR
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
						(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND
						(ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND
						(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND					
						(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND
						(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
						(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS Date)=CAST(@ReceivedDate AS date)) AND
						(ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND					
						(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND
						(ISNULL(@ItemCategory,'') ='' OR ItemCategory LIKE '%' + @ItemCategory + '%') AND
						(ISNULL(@AWB,'') ='' OR AWB LIKE '%' + @AWB + '%') AND					
						(ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName + '%') AND
						(ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName + '%') AND
						(ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName + '%') AND
						(ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName + '%') AND
						(ISNULL(@PartCertificationNumber,'') ='' OR PartCertificationNumber LIKE '%' + @PartCertificationNumber + '%') AND
						(ISNULL(@CertifiedBy,'') ='' OR CertifiedBy LIKE '%' + @CertifiedBy + '%') AND
						(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
						(ISNULL(@CertifiedDate,'') ='' OR CAST(CertifiedDate AS Date)=CAST(@CertifiedDate AS date)) AND
						(ISNULL(@IsCustomerStock,'') ='' OR IsCustomerStock LIKE '%' + @IsCustomerStock + '%') AND						
						(ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND
						(ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND
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
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC, 
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,
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
				CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,					
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC
				
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
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
              , @AdhocComments     VARCHAR(150)    = 'ProcStockList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize,'') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn,'') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder,'') + ', 
													   @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ', 
													   @Parameter6 = ' + ISNULL(@stockTypeId,'') + ', 
													   @Parameter7 = ' + ISNULL(@StocklineNumber,'') + ', 
													   @Parameter8 = ' + ISNULL(@PartNumber,'') + ', 
													   @Parameter9 = ' + ISNULL(@PartDescription,'') + ', 
													   @Parameter10 = ' + ISNULL(@ItemGroup,'') + ', 
													   @Parameter11 = ' + ISNULL(@UnitOfMeasure,'') + ', 
													   @Parameter12 = ' + ISNULL(@SerialNumber,'') + ', 
													   @Parameter13 = ' + ISNULL(@GlAccountName,'') + ', 
													   @Parameter14 = ' + ISNULL(@ItemCategory,'') + ',
													   @Parameter15 = ' + ISNULL(@Condition,'') + ', 
													   @Parameter16 = ' + ISNULL(@QuantityAvailable,'') + ', 
													   @Parameter17 = ' + ISNULL(@QuantityOnHand,'') + ', 
													   @Parameter18 = ' + ISNULL(@CompanyName,'') + ', 
													   @Parameter19 = ' + ISNULL(@BuName,'') + ',
													   @Parameter20 = ' + ISNULL(@DeptName,'') + ', 
													   @Parameter21 = ' + ISNULL(@DivName,'') + ', 
													   @Parameter22 = ' + ISNULL(@RevisedPN,'') + ', 
													   @Parameter23 = ' + ISNULL(@AWB,'') + ', 
													   @Parameter24 = ' + ISNULL(CAST(@ReceivedDate AS varchar(20)) ,'') +''',  
													   @Parameter25 = ' + ISNULL(@TraceableToName,'') + ', 
													   @Parameter26 = ' + ISNULL(@TaggedByName,'') + ', 
													   @Parameter27 = ' + ISNULL(@TagType,'') + ', 
													   @Parameter28 = ' + ISNULL(CAST(@TagDate AS varchar(20)) ,'') +''',  
													   @Parameter30 = ' + ISNULL(CAST(@ExpirationDate AS varchar(20)) ,'') +''', 
													   @Parameter31 = ' + ISNULL(@IdNumber,'') + ', 
													   @Parameter32 = ' + ISNULL(@Manufacturer,'') + ', 
													   @Parameter33 = ' + ISNULL(@PartCertificationNumber,'') + ',
													   @Parameter34 = ' + ISNULL(@CertifiedBy,'') + ', 
													   @Parameter35 = ' + ISNULL(@CertifiedDate,'') + ', 
													   @Parameter36 = ' + ISNULL(@UpdatedBy,'') + ', 
													   @Parameter37 = ' + ISNULL(CAST(@UpdatedDate AS varchar(20)) ,'') +''',
													   @Parameter38 = ' + ISNULL(@EmployeeId,'') + ', 
													   @Parameter39 = ' + ISNULL(@MasterCompanyId,'') + ', 
													   @Parameter40 = ' + ISNULL(@IsCustomerStock ,'') +''
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