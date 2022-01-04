CREATE PROCEDURE SP_GetVendorRFQPNViewList
@PageNumber int = 1,
@PageSize int = 10,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@StatusID int = 1,
@Status varchar(50) = 'Open',
@GlobalFilter varchar(50) = '',	
@VendorRFQPurchaseOrderNumber varchar(50) = NULL,	
@OpenDate  datetime = NULL,
@VendorName varchar(50) = NULL,
@RequestedBy varchar(50) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = 0,
@EmployeeId bigint=1,
@MasterCompanyId bigint=1,
@VendorId bigint =null,
@PartNumber varchar(50)=NULL,
@PartDescription VARCHAR(100)=NULL,
@StockType VARCHAR(50)=NULL,
@Manufacturer VARCHAR(50)=NULL,
@Priority VARCHAR(50)=NULL,
@NeedByDate	VARCHAR(50)=NULL,
@PromisedDate VARCHAR(50)=NULL,
@Condition	VARCHAR(50)=NULL,
@UnitCost varchar(50)=NULL,
@QuantityOrdered varchar(50) =NULL,
@WorkOrderNo VARCHAR(50)=NULL,
@SubWorkOrderNo VARCHAR(50)=NULL,
@SalesOrderNo	VARCHAR(50)=NULL,
@PurchaseOrderNumber VARCHAR(50)=NULL,
@mgmtStructure varchar(200)=null
AS
BEGIN
SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
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
			SET @SortColumn=Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END
		IF (@StatusID=6 AND @Status='All')
		BEGIN			
			SET @Status = ''
		END
		IF (@StatusID=6 OR @StatusID=0)
		BEGIN
			SET @StatusID = NULL			
		END		
		
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN	

		;WITH Main AS(									
		   	 SELECT PO.VendorRFQPurchaseOrderId,PO.VendorRFQPurchaseOrderNumber,PO.OpenDate,PO.ClosedDate,PO.CreatedDate,PO.CreatedBy,PO.UpdatedDate,
					PO.UpdatedBy,PO.IsActive,PO.IsDeleted,PO.StatusId,PO.VendorId,PO.VendorName,PO.VendorCode,PO.[Status],
					PO.Requisitioner AS RequestedBy--,	
					--B.UnitCost,
					--A.QuantityOrdered
			  FROM VendorRFQPurchaseOrder PO WITH (NOLOCK)
			  INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = PO.ManagementStructureId			  
		 	  WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID)) 
			     AND EMS.EmployeeId = 	@EmployeeId 
				  AND PO.MasterCompanyId = @MasterCompanyId	
				  --AND  (@VendorId  IS NULL OR PO.VendorId = @VendorId)
			),	
			
			DatesCTE AS(
							Select PO.VendorRFQPurchaseOrderId, 
							A.NeedByDate,
							(Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse A.NeedByDate End)  as 'NeedByDateType',
							A.PromisedDate,
							(Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse A.PromisedDate End)  as 'PromisedDateType'
							from VendorRFQPurchaseOrder PO WITH (NOLOCK)
							Left Join VendorRFQPurchaseOrderPart SP WITH (NOLOCK) On PO.VendorRFQPurchaseOrderId = SP.VendorRFQPurchaseOrderId
							Outer Apply(
								SELECT 
								   STUFF((SELECT ',' + CONVERT(VARCHAR, NeedByDate, 101)--CAST(CustomerRequestDate as varchar)
										  FROM VendorRFQPurchaseOrderPart S WITH (NOLOCK) Where S.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId
										  AND PO.IsActive = 1 AND PO.IsDeleted = 0
										  FOR XML PATH('')), 1, 1, '') NeedByDate,
								   STUFF((SELECT ',' + CONVERT(VARCHAR, PromisedDate, 101)--CAST(PromisedDate as varchar)
										  FROM VendorRFQPurchaseOrderPart S WITH (NOLOCK) Where S.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId
										  AND PO.IsActive = 1 AND PO.IsDeleted = 0
										  FOR XML PATH('')), 1, 1, '') PromisedDate								   
							) A
							Where ((PO.IsDeleted = @IsDeleted) and (@StatusID is null or PO.StatusId = @StatusID))
							
							Group By PO.VendorRFQPurchaseOrderId, A.NeedByDate, A.PromisedDate
			),PartCTE AS(
									Select SO.VendorRFQPurchaseOrderId,(Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber 
									from VendorRFQPurchaseOrder SO WITH (NOLOCK)
									Left Join VendorRFQPurchaseOrderPart SP WITH (NOLOCK) On SO.VendorRFQPurchaseOrderId = SP.VendorRFQPurchaseOrderId
									Outer Apply(
										SELECT 
										   STUFF((SELECT ',' + I.partnumber
												  FROM VendorRFQPurchaseOrderPart S WITH (NOLOCK)
												  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
												  Where S.VendorRFQPurchaseOrderId = SO.VendorRFQPurchaseOrderId
												  AND S.IsActive = 1 AND S.IsDeleted = 0
												  FOR XML PATH('')), 1, 1, '') PartNumber
									) A
									Where ((SO.IsDeleted = @IsDeleted) and (@StatusID is null or so.StatusId = @StatusID))
									AND SP.IsActive = 1 AND SP.IsDeleted = 0
									Group By SO.VendorRFQPurchaseOrderId, A.PartNumber
									),
						PartDescCTE AS(
						Select SO.VendorRFQPurchaseOrderId, (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescriptionType', A.PartDescription 
						from VendorRFQPurchaseOrder SO WITH (NOLOCK)
						Left Join VendorRFQPurchaseOrderPart SP WITH (NOLOCK) On SO.VendorRFQPurchaseOrderId = SP.VendorRFQPurchaseOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ', ' + I.PartDescription
									  FROM VendorRFQPurchaseOrderPart S WITH (NOLOCK)
									  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.VendorRFQPurchaseOrderId = SO.VendorRFQPurchaseOrderId
									  AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PartDescription
						) A	
						Where ((SO.IsDeleted = @IsDeleted) and (@StatusID is null or SO.StatusId = @StatusID))
						AND SP.IsActive = 1 AND SP.IsDeleted = 0
						Group By SO.VendorRFQPurchaseOrderId,A.PartDescription

						
			
			),result as(
			SELECT DISTINCT M.VendorRFQPurchaseOrderId,M.VendorRFQPurchaseOrderNumber,M.OpenDate,M.ClosedDate,M.CreatedDate,M.CreatedBy,M.UpdatedDate,
					M.UpdatedBy,M.IsActive,M.IsDeleted,M.StatusId,M.VendorId,M.VendorName,M.VendorCode,M.[Status],
					M.RequestedBy AS RequestedBy,
					--M.UnitCost,
					--M.QuantityOrdered,
					(Select SUM(QuantityOrdered) as QuantityOrdered from VendorRFQPurchaseOrderPart WITH (NOLOCK) 
					Where VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) as QuantityOrdered,
					(Select SUM(UnitCost) as UnitCost from VendorRFQPurchaseOrderPart WITH (NOLOCK) 
					Where VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) as UnitCost,
					PC.PartNumber,PDC.PartDescription,PC.PartNumberType,PDC.PartDescriptionType,
					(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 AND LEN(isnull(SP.StockType,'')) >0) Then 'Multiple' ELse  isnull(SP.StockType,'')   End)
						as 'StockTypeType',
						(Case When (SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse  isnull(SP.Manufacturer,'')   End)
						as 'ManufacturerType',
						(Case When (SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse  isnull(SP.Priority,'')   End)
						as 'PriorityType',
						(Case When (SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse  isnull(SP.Condition,'')   End)
						as 'ConditionType',
						
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND LEN(isnull(SP.WorkOrderNo,'')) >0) > 1 ) Then 'Multiple' ELse  isnull(SP.WorkOrderNo,'')   End)
						as 'WorkOrderNoType',
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND LEN(isnull(SP.SubWorkOrderNo,'')) >0) > 1 ) Then 'Multiple' ELse  isnull(SP.SubWorkOrderNo,'')   End)
						as 'SubWorkOrderNoType',
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND LEN(isnull(SP.SalesOrderNo,'')) >0) > 1 ) Then 'Multiple' ELse  isnull(SP.SalesOrderNo,'')   End)
						as 'SalesOrderNoType',
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND LEN(isnull(SP.PurchaseOrderNumber,'')) >0) > 1 ) Then 'Multiple' ELse  isnull(SP.PurchaseOrderNumber,'')   End)
						as 'PurchaseOrderNumberType',
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 AND LEN(isnull(SP.Memo,'')) >0) Then 'Multiple' ELse  isnull(SP.Memo,'')   End)
						as 'MemoType',
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 AND LEN(isnull(SP.Level1,'')) >0 ) Then 'Multiple' ELse  isnull(SP.Level1,'')   End)
						as 'Level1Type',
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 AND LEN(isnull(SP.Level2,'')) >0 
						 ) Then 'Multiple' ELse  isnull(SP.Level2,'')   End)
						as 'Level2Type',
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 AND LEN(isnull(SP.Level3,'')) >0 
						) Then 'Multiple' ELse  isnull(SP.Level3,'')   End)
						as 'Level3Type',
						(Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId) 
						FROM  dbo.VendorRFQPurchaseOrderPart VRPP 
						WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId) > 1 AND LEN(isnull(SP.Level4,'')) >0 
						 ) Then 'Multiple' ELse  isnull(SP.Level4,'')   End)
						as 'Level4Type',
						D.NeedByDate,D.PromisedDate,D.NeedByDateType,D.PromisedDateType

					--,MFC.Manufacturer,MFC.ManufacturerType,PRC.Priority,PRC.PriorityType,D.NeedByDate,D.PromisedDate,D.NeedByDateType,D.PromisedDateType
					--,conC.Condition,conC.ConditionType,woc.WorkOrderNo,woc.WorkOrderNoType,SubWorkOrderNo,SubWorkOrderNoType,SalesOrderNo,SalesOrderNoType,
					--PurchaseOrderNumber,PurchaseOrderNumberType
					
					from Main M
					LEFT JOIN PartCTE PC ON PC.VendorRFQPurchaseOrderId=M.VendorRFQPurchaseOrderId
					LEFT JOIN PartDescCTE PDC ON PDC.VendorRFQPurchaseOrderId=M.VendorRFQPurchaseOrderId
					LEFT JOIN VendorRFQPurchaseOrderPart SP ON SP.VendorRFQPurchaseOrderId=M.VendorRFQPurchaseOrderId
					
					LEFT JOIN DatesCTE D ON D.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId					
			
			 WHERE ((@GlobalFilter <>'' AND ((VendorRFQPurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(M.CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(M.UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR		
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR
					(PartNumberType LIKE '%' +@GlobalFilter+'%') OR
					(PartDescriptionType LIKE '%' +@GlobalFilter+'%') OR
					(SP.StockType LIKE '%' +@GlobalFilter+'%') OR
					(Manufacturer LIKE '%' +@GlobalFilter+'%') OR
					(Priority LIKE '%' +@GlobalFilter+'%') OR
					(Condition LIKE '%' +@GlobalFilter+'%') OR
					(UnitCost LIKE '%' +@GlobalFilter+'%') OR
					(QuantityOrdered LIKE '%' +@GlobalFilter+'%') OR
					(WorkOrderNo LIKE '%' +@GlobalFilter+'%') OR
					(SubWorkOrderNo LIKE '%' +@GlobalFilter+'%') OR
					(SalesOrderNo LIKE '%' +@GlobalFilter+'%') OR
					(PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(NeedByDateType LIKE '%' +@GlobalFilter+'%') OR
					(PromisedDateType LIKE '%' +@GlobalFilter+'%') OR
					([Status]  LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@VendorRFQPurchaseOrderNumber,'') ='' OR VendorRFQPurchaseOrderNumber LIKE '%' + @VendorRFQPurchaseOrderNumber+'%') AND 
					(ISNULL(@CreatedBy,'') ='' OR M.CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR M.UpdatedBy LIKE '%' + @UpdatedBy + '%') AND					
					--(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@RequestedBy,'') ='' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND
					(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND									
					(ISNULL(@OpenDate,'') ='' OR CAST(M.OpenDate AS Date) = CAST(@OpenDate AS date)) AND									
					(ISNULL(@CreatedDate,'') ='' OR CAST(M.CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@NeedByDate,'') ='' OR NeedByDateType LIKE '%' + @NeedByDate + '%') AND
					(ISNULL(@PromisedDate,'') ='' OR PromisedDateType LIKE '%' + @PromisedDate + '%') AND
					(ISNULL(@PartNumber,'') ='' OR PC.PartNumber LIKE '%' + @PartNumber + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PDC.PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@StockType,'') ='' OR StockType LIKE '%' + @StockType + '%') AND
					(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
					(ISNULL(@Priority,'') ='' OR Priority LIKE '%' + @Priority + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
					--(ISNULL(@UnitCost,'') ='' OR CAST(UnitCost AS varchar(10)) LIKE '%' + CAST(@UnitCost AS VARCHAR(10))+ '%') AND
					--(ISNULL(@QuantityOrdered,'') ='' OR QuantityOrdered LIKE '%' + @QuantityOrdered + '%') AND
					(ISNULL(@WorkOrderNo,'') ='' OR WorkOrderNo LIKE '%' + @WorkOrderNo + '%') AND
					(ISNULL(@SubWorkOrderNo,'') ='' OR SubWorkOrderNo LIKE '%' + @SubWorkOrderNo + '%') AND
					(ISNULL(@SalesOrderNo,'') ='' OR SalesOrderNo LIKE '%' + @SalesOrderNo + '%') AND
					(ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber + '%') AND
					--(ISNULL(@mgmtStructure,'') ='' OR Level1 LIKE '%' + @PartNumber + '%') AND
					--(ISNULL(@mgmtStructure,'') ='' OR Level2 LIKE '%' + @PartNumber + '%') AND
					--(ISNULL(@mgmtStructure,'') ='' OR Level3 LIKE '%' + @PartNumber + '%') AND
					--(ISNULL(@mgmtStructure,'') ='' OR Level4 LIKE '%' + @PartNumber + '%') AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(M.UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )
				   GROUP BY M.VendorRFQPurchaseOrderId,VendorRFQPurchaseOrderNumber,OpenDate,ClosedDate,M.CreatedDate,M.CreatedBy,M.UpdatedDate,
					M.UpdatedBy,M.IsActive,M.IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered,
					RequestedBy,PC.PartNumber,PDC.PartDescription,pc.PartNumberType,pdc.PartDescriptionType,
					SP.StockType
					,SP.Manufacturer,SP.Priority,D.NeedByDate,D.PromisedDate,D.NeedByDateType,D.PromisedDateType,sp.Memo,sp.Level1,sp.Level2,sp.Level3,sp.Level4
					,SP.Condition,SP.WorkOrderNo,SP.SubWorkOrderNo,SP.SalesOrderNo,SP.PurchaseOrderNumber--,Level1,Level2,Level3,Level4,Memo--,PurchaseOrderId
			), 
			CTE_Count AS (Select COUNT(VendorRFQPurchaseOrderId) AS NumberOfItems FROM result)
			--SELECT @Count = COUNT(VendorRFQPurchaseOrderId) FROM #TempResult			

			SELECT VendorRFQPurchaseOrderId,VendorRFQPurchaseOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,
					UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered
					,RequestedBy,PartNumber,PartDescription,PartNumberType,PartDescriptionType,StockTypeType,
					ManufacturerType,PriorityType,NeedByDate,PromisedDate,NeedByDateType,PromisedDateType,ConditionType,WorkOrderNoType,SubWorkOrderNoType,SalesOrderNoType,PurchaseOrderNumberType
					
					,NumberOfItems,Level1Type,Level2Type,Level3Type,Level4Type,MemoType
					FROM result,CTE_Count
				
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='vendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='vendorName')  THEN VendorName END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='RequestedBy')  THEN RequestedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RequestedBy')  THEN RequestedBy END DESC,			         
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='partNumberType')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='partNumberType')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StockTypeType')  THEN StockTypeType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StockTypeType')  THEN StockTypeType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConditionType')  THEN ConditionType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConditionType')  THEN ConditionType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerType')  THEN ManufacturerType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PriorityType')  THEN PriorityType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PriorityType')  THEN PriorityType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NeedByDateType')  THEN NeedByDateType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NeedByDateType')  THEN NeedByDateType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PromisedDateType')  THEN PromisedDateType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PromisedDateType')  THEN PromisedDateType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOrdered')  THEN QuantityOrdered END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOrdered')  THEN QuantityOrdered END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkOrderNoType')  THEN WorkOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderNoType')  THEN WorkOrderNoType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SubWorkOrderNoType')  THEN SubWorkOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SubWorkOrderNoType')  THEN SubWorkOrderNoType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SalesOrderNoType')  THEN SalesOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesOrderNoType')  THEN SalesOrderNoType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='MemoType')  THEN MemoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MemoType')  THEN MemoType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='mgmtStructure')  THEN Level1Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='mgmtStructure')  THEN Level1Type END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Status')  THEN Status END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Status')  THEN Status END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumberType')  THEN PurchaseOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumberType')  THEN PurchaseOrderNumberType END DESC

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
            , @AdhocComments     VARCHAR(150)    = 'GetVendorRFQPurchaseOrderList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRFQPurchaseOrderNumber, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END