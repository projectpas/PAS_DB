CREATE PROCEDURE [dbo].[ProcGetVendorRFQRoList]
	-- Add the parameters for the stored procedure here
	@PageNumber int=null,
	@PageSize int=null,
	@SortColumn varchar(50)=null,
	@SortOrder int=null,
	@StatusID int=null,
	@GlobalFilter varchar(50) = null,
	@VendorRFQRepairOrderNumber  varchar(50)=null,	
	@OpenDate datetime=null,
	@ClosedDate datetime=null,
	@VendorName varchar(50)=null,
	@VendorCode varchar(50)=null,
	@Status varchar(50)=null,	
	@RequestedBy varchar(50)=null,	
	@CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit = null,
	@EmployeeId bigint=null,
    @MasterCompanyId bigint=null,
	@VendorId bigint= null,
	@ViewType	varchar(10)=null,
	@PartNumber varchar(50)=null,
	@PartDescription	varchar(100) null,
	@AltEquiPartNumber	varchar(50)=null,
	@RevisedPartNumber	varchar(50)=null,
	@StockType			varchar(50)=null,
	@Manufacturer		varchar(100)=null,
	@Priority			varchar(50)=null,
	@NeedByDate			varchar(50)=null,
	@PromisedDate		varchar(50)=null,
	@Condition			varchar(50)=null,
	@WorkPerformed		varchar(50)=null,
	@QuantityOrdered	varchar(50)=null,
	@UnitCost			varchar(50)=null,
	@WorkOrderNo		varchar(50)=null,
	@SubWorkOrderNo		varchar(50)=null,
	@SalesOrderNo		varchar(50)=null,
	@Level1Type			varchar(200)=null,
	@Level2Type			varchar(200)=null,
	@Level3Type			varchar(200)=null,
	@Level4Type			varchar(200)=null,
	@Memo			varchar(200)=null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @RecordFrom int;
		Declare @IsActive bit=1
		DECLARE @Count Int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted is null
		Begin
			Set @IsDeleted=0
		End
		IF @SortColumn is null
		Begin
			Set @SortColumn=Upper('CreatedDate')
		End 
		Else
		Begin 
			Set @SortColumn=Upper(@SortColumn)
		End
		IF (@StatusID=6 AND @Status='All')
		BEGIN			
			SET @Status = ''
		END
		IF (@StatusID=6 OR @StatusID=0)
		BEGIN
			SET @StatusID = null			
		END	
	if @ViewType='pnview'
	BEGIN
	;With Result AS(
			SELECT DISTINCT 
			       RO.VendorRFQRepairOrderId,
			       RO.VendorRFQRepairOrderNumber,				  				   
			       RO.OpenDate,
				   RO.ClosedDate,
				   RO.CreatedDate,
				   RO.CreatedBy,
				   RO.UpdatedDate,
				   RO.UpdatedBy,
				   RO.IsActive,
				   RO.IsDeleted,
				   RO.VendorId,
				   RO.VendorName,
				   RO.VendorCode,
				   RO.StatusId,
				   RO.[Status],
				   RO.Requisitioner AS RequestedBy,
				   RP.PartNumber as 'PartNumberType',
				   RP.AltEquiPartNumber as 'AltEquiPartNumberType',
				   RP.PartDescription as 'PartDescriptionType',
				   RP.RevisedPartNumber as 'RevisedPartNumberType',
				   RP.Manufacturer as 'ManufacturerType',
				   RP.StockType as 'StockTypeType',
				   RP.Priority as 'PriorityType',
				   RP.Condition as 'ConditionType',
				   RP.WorkPerformed as 'WorkPerformedType',
				   RP.QuantityOrdered,
				   RP.UnitCost,
				   RP.NeedByDate as 'NeedByDateType',
				   RP.PromisedDate as 'PromisedDateType',
				   RP.WorkOrderNo as 'WorkOrderNoType',
				   RP.SubWorkOrderNo as 'SubWorkOrderNoType',
				   RP.SalesOrderNo as 'SalesOrderNoType',
				   RP.Level1 as 'Level1Type',
				   RP.Level2 as 'Level2Type',
				   RP.Level3 as 'Level3Type',
				   RP.Level4 as 'Level4Type',
				   RP.Memo as 'MemoType'
			FROM  dbo.VendorRFQRepairOrder RO WITH (NOLOCK)
			 INNER JOIN  dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = RO.ManagementStructureId	
			 LEFT JOIN dbo.VendorRFQRepairOrderPart RP WITH (NOLOCK) ON RP.VendorRFQRepairOrderId=RO.VendorRFQRepairOrderId
			WHERE ((RO.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR RO.StatusId=@StatusID)) AND
			        EMS.EmployeeId = @EmployeeId AND RO.MasterCompanyId=@MasterCompanyId 
					 AND 
					 (@VendorId  IS NULL OR RO.VendorId=@VendorId)
					), ResultCount AS(Select COUNT(VendorRFQRepairOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE ((@GlobalFilter <>'' AND ((VendorRFQRepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
			        (CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR	
					(VendorCode LIKE '%' +@GlobalFilter+'%') OR					
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR					
					([Status] LIKE '%' +@GlobalFilter+'%') ))
					OR 
					(@GlobalFilter='' AND IsDeleted=@IsDeleted AND
					(ISNULL(@VendorRFQRepairOrderNumber,'') ='' OR VendorRFQRepairOrderNumber LIKE '%' + @VendorRFQRepairOrderNumber +'%') AND 
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND					
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND
					(ISNULL(@RequestedBy,'') ='' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND
					(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND		
					(ISNULL(@PartNumber,'') ='' OR PartNumberType LIKE '%' +@PartNumber + '%') AND
					(ISNULL(@PartDescription   ,'') ='' OR	PartDescriptionType LIKE '%' +   @PartDescription    + '%') AND
					(ISNULL(@AltEquiPartNumber   ,'') ='' OR	AltEquiPartNumberType LIKE '%' +   @AltEquiPartNumber    + '%') AND
					(ISNULL(@RevisedPartNumber   ,'') ='' OR	RevisedPartNumberType LIKE '%' +   @RevisedPartNumber    + '%') AND
					(ISNULL(@StockType   ,'') ='' OR	StockTypeType LIKE '%' +   @StockType    + '%') AND
					(ISNULL(@Manufacturer   ,'') ='' OR	ManufacturerType LIKE '%' +   @Manufacturer    + '%') AND
					(ISNULL(@Priority   ,'') ='' OR	PriorityType LIKE '%' +   @Priority    + '%') AND
					(ISNULL(@NeedByDate   ,'') ='' OR	CAST(NeedByDateType AS Date)=CAST(@NeedByDate AS date)) AND
					(ISNULL(@PromisedDate   ,'') ='' OR	CAST(PromisedDateType AS Date)=CAST(@PromisedDate AS date)) AND
					(ISNULL(@Condition   ,'') ='' OR	ConditionType LIKE '%' +   @Condition    + '%') AND
					(ISNULL(@WorkPerformed   ,'') ='' OR	WorkPerformedType LIKE '%' +   @WorkPerformed    + '%') AND
					(ISNULL(@QuantityOrdered   ,'') ='' OR	QuantityOrdered LIKE '%' +   @QuantityOrdered    + '%') AND
					(ISNULL(@UnitCost   ,'') ='' OR	UnitCost LIKE '%' +   @UnitCost    + '%') AND
					(ISNULL(@WorkOrderNo   ,'') ='' OR	WorkOrderNoType LIKE '%' +   @WorkOrderNo    + '%') AND
					(ISNULL(@SubWorkOrderNo   ,'') ='' OR	SubWorkOrderNoType LIKE '%' +   @SubWorkOrderNo    + '%') AND
					(ISNULL(@SalesOrderNo   ,'') ='' OR	SalesOrderNoType LIKE '%' +   @SalesOrderNo    + '%') AND
					(ISNULL(@Level1Type   ,'') ='' OR	Level1Type LIKE '%' +   @Level1Type    + '%') AND
					(ISNULL(@Level2Type   ,'') ='' OR	Level2Type LIKE '%' +   @Level2Type    + '%') AND
					(ISNULL(@Level3Type   ,'') ='' OR	Level3Type LIKE '%' +   @Level3Type    + '%') AND
					(ISNULL(@Level4Type   ,'') ='' OR	Level4Type LIKE '%' +   @Level4Type    + '%') AND
					(ISNULL(@Memo   ,'') ='' OR MemoType LIKE '%' +   @Memo    + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND									
					(ISNULL(@ClosedDate,'') ='' OR CAST(ClosedDate AS Date) = CAST(@ClosedDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )
				   SELECT @Count = COUNT(VendorRFQRepairOrderId) FROM #TempResult
				   SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
            CASE WHEN (@SortOrder=1 AND @SortColumn='VendorRFQRepairOrderNumber')  THEN VendorRFQRepairOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQRepairOrderNumber')  THEN VendorRFQRepairOrderNumber END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='ClosedDate')  THEN ClosedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ClosedDate')  THEN ClosedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='RequestedBy')  THEN RequestedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RequestedBy')  THEN RequestedBy END DESC,			          
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='partNumberType')  THEN PartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='partNumberType')  THEN PartNumberType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='altEquiPartNumberType')  THEN AltEquiPartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='altEquiPartNumberType')  THEN AltEquiPartNumberType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='partDescriptionType')  THEN PartDescriptionType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='partDescriptionType')  THEN PartDescriptionType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='revisedPartNumberType')  THEN RevisedPartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='revisedPartNumberType')  THEN RevisedPartNumberType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='manufacturerType')  THEN ManufacturerType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='manufacturerType')  THEN ManufacturerType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='stockTypeType')  THEN StockTypeType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='stockTypeType')  THEN StockTypeType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='priorityType')  THEN PriorityType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='priorityType')  THEN PriorityType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='conditionType')  THEN ConditionType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='conditionType')  THEN ConditionType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='workPerformedType')  THEN WorkPerformedType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='workPerformedType')  THEN WorkPerformedType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='quantityOrdered')  THEN QuantityOrdered END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityOrdered')  THEN QuantityOrdered END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='needByDateType')  THEN NeedByDateType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='needByDateType')  THEN NeedByDateType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='unitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='unitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='promisedDateType')  THEN PromisedDateType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='promisedDateType')  THEN PromisedDateType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='workOrderNoType')  THEN WorkOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='workOrderNoType')  THEN WorkOrderNoType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='subWorkOrderNoType')  THEN SubWorkOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='subWorkOrderNoType')  THEN SubWorkOrderNoType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='salesOrderNoType')  THEN SalesOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='salesOrderNoType')  THEN SalesOrderNoType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='memoType')  THEN MemoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='memoType')  THEN MemoType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='level1Type')  THEN Level1Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='level1Type')  THEN Level1Type END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='level2Type')  THEN Level2Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='level2Type')  THEN Level2Type END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='level3Type')  THEN Level3Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='level3Type')  THEN Level3Type END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='level4Type')  THEN Level4Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='level4Type')  THEN Level4Type END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END

	ELSE 
	BEGIN
			;With Main AS(
			SELECT DISTINCT 
			       RO.VendorRFQRepairOrderId,
			       RO.VendorRFQRepairOrderNumber,				  				   
			       RO.OpenDate,
				   RO.ClosedDate,
				   RO.CreatedDate,
				   RO.CreatedBy,
				   RO.UpdatedDate,
				   RO.UpdatedBy,
				   RO.IsActive,
				   RO.IsDeleted,
				   RO.VendorId,
				   RO.VendorName,
				   RO.VendorCode,
				   RO.StatusId,
				   RO.[Status],
				   RO.Requisitioner AS RequestedBy
				   --,
				   --RP.PartNumber as 'PartNumberType',
				   --RP.AltEquiPartNumber as 'AltEquiPartNumberType',
				   --RP.PartDescription as 'PartDescriptionType',
				   --RP.RevisedPartNumber as 'RevisedPartNumberType',
				   --RP.Manufacturer as 'ManufacturerType',
				   --RP.StockType as 'StockTypeType',
				   --RP.Priority as 'PriorityType',
				   --RP.Condition as 'ConditionType',
				   --RP.WorkPerformed as 'WorkPerformedType',
				   --RP.QuantityOrdered,
				   --RP.UnitCost,
				   --RP.NeedByDate as 'NeedByDateType',
				   --RP.PromisedDate as 'PromisedDateType',
				   --RP.WorkOrderNo as 'WorkOrderNoType',
				   --RP.SubWorkOrderNo as 'SubWorkOrderNoType',
				   --RP.SalesOrderNo as 'SalesOrderNoType',
				   --RP.Level1 as 'Level1Type',
				   --RP.Level2 as 'Level2Type',
				   --RP.Level3 as 'Level3Type',
				   --RP.Level4 as 'Level4Type',
				   --RP.Memo as 'MemoType'
			FROM  dbo.VendorRFQRepairOrder RO WITH (NOLOCK)
			 INNER JOIN  dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = RO.ManagementStructureId	
			-- LEFT JOIN dbo.VendorRFQRepairOrderPart RP WITH (NOLOCK) ON RP.VendorRFQRepairOrderId=RO.VendorRFQRepairOrderId
			WHERE ((RO.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR RO.StatusId=@StatusID)) AND
			        EMS.EmployeeId = @EmployeeId AND RO.MasterCompanyId=@MasterCompanyId 
					 AND 
					 (@VendorId  IS NULL OR RO.VendorId=@VendorId)
					),
			DatesCTE AS(
							Select RO.VendorRFQRepairOrderId, 
							A.NeedByDate,
							(Case When Count(SP.VendorRFQRepairOrderId) > 1 Then 'Multiple' ELse A.NeedByDate End)  as 'NeedByDateType',
							A.PromisedDate,
							(Case When Count(SP.VendorRFQRepairOrderId) > 1 Then 'Multiple' ELse A.PromisedDate End)  as 'PromisedDateType'
							from VendorRFQRepairOrder RO WITH (NOLOCK)
							Left Join VendorRFQRepairOrderPart SP WITH (NOLOCK) On RO.VendorRFQRepairOrderId = SP.VendorRFQRepairOrderId
							Outer Apply(
								SELECT 
								   STUFF((SELECT ',' + CONVERT(VARCHAR, NeedByDate, 101)--CAST(CustomerRequestDate as varchar)
										  FROM VendorRFQRepairOrderPart S WITH (NOLOCK) Where S.VendorRFQRepairOrderId = RO.VendorRFQRepairOrderId
										  AND RO.IsActive = 1 AND RO.IsDeleted = 0
										  FOR XML PATH('')), 1, 1, '') NeedByDate,
								   STUFF((SELECT ',' + CONVERT(VARCHAR, PromisedDate, 101)--CAST(PromisedDate as varchar)
										  FROM VendorRFQRepairOrderPart S WITH (NOLOCK) Where S.VendorRFQRepairOrderId = RO.VendorRFQRepairOrderId
										  AND RO.IsActive = 1 AND RO.IsDeleted = 0
										  FOR XML PATH('')), 1, 1, '') PromisedDate								   
							) A
							Where ((RO.IsDeleted = @IsDeleted) and (@StatusID is null or RO.StatusId = @StatusID))
							
							Group By RO.VendorRFQRepairOrderId, A.NeedByDate, A.PromisedDate
			),		
			PartCTE AS(
									Select SO.VendorRFQRepairOrderId,(Case When Count(SP.VendorRFQRepairOrderId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber 
									from VendorRFQRepairOrder SO WITH (NOLOCK)
									Left Join VendorRFQRepairOrderPart SP WITH (NOLOCK) On SO.VendorRFQRepairOrderId = SP.VendorRFQRepairOrderId
									Outer Apply(
										SELECT 
										   STUFF((SELECT ',' + I.partnumber
												  FROM VendorRFQRepairOrderPart S WITH (NOLOCK)
												  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
												  Where S.VendorRFQRepairOrderId = SO.VendorRFQRepairOrderId
												  AND S.IsActive = 1 AND S.IsDeleted = 0
												  FOR XML PATH('')), 1, 1, '') PartNumber
									) A
									Where ((SO.IsDeleted = @IsDeleted) and (@StatusID is null or so.StatusId = @StatusID))
									AND SP.IsActive = 1 AND SP.IsDeleted = 0
									Group By SO.VendorRFQRepairOrderId, A.PartNumber
									),
						PartDescCTE AS(
						Select SO.VendorRFQRepairOrderId, (Case When Count(SP.VendorRFQRepairOrderId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescriptionType', A.PartDescription 
						from VendorRFQRepairOrder SO WITH (NOLOCK)
						Left Join VendorRFQRepairOrderPart SP WITH (NOLOCK) On SO.VendorRFQRepairOrderId = SP.VendorRFQRepairOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ', ' + I.PartDescription
									  FROM VendorRFQRepairOrderPart S WITH (NOLOCK)
									  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.VendorRFQRepairOrderId = SO.VendorRFQRepairOrderId
									  AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PartDescription
						) A	
						Where ((SO.IsDeleted = @IsDeleted) and (@StatusID is null or SO.StatusId = @StatusID))
						AND SP.IsActive = 1 AND SP.IsDeleted = 0
						Group By SO.VendorRFQRepairOrderId,A.PartDescription
			),		
			result as(
			SELECT DISTINCT M.VendorRFQRepairOrderId,M.VendorRFQRepairOrderNumber,M.OpenDate,M.ClosedDate,M.CreatedDate,M.CreatedBy,M.UpdatedDate,
					M.UpdatedBy,M.IsActive,M.IsDeleted,M.StatusId,M.VendorId,M.VendorName,M.VendorCode,M.[Status],
					M.RequestedBy AS RequestedBy,
					--M.UnitCost,
					--M.QuantityOrdered,
					(Select SUM(QuantityOrdered) as QuantityOrdered from VendorRFQRepairOrderPart WITH (NOLOCK) 
					Where VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) as QuantityOrdered,
					(Select SUM(UnitCost) as UnitCost from VendorRFQRepairOrderPart WITH (NOLOCK) 
					Where VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) as UnitCost,
					PC.PartNumber,PDC.PartDescription,PC.PartNumberType,PDC.PartDescriptionType,
					(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.StockType,'')) >0) Then 'Multiple' ELse  isnull(SP.StockType,'')   End)
						as 'StockTypeType',
						(Case When (SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 Then 'Multiple' ELse  isnull(SP.Manufacturer,'')   End)
						as 'ManufacturerType',
						(Case When (SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 Then 'Multiple' ELse  isnull(SP.Priority,'')   End)
						as 'PriorityType',
						(Case When (SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 Then 'Multiple' ELse  isnull(SP.Condition,'')   End)
						as 'ConditionType',
						
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId AND LEN(isnull(SP.WorkOrderNo,'')) >0) > 1 ) Then 'Multiple' ELse  isnull(SP.WorkOrderNo,'')   End)
						as 'WorkOrderNoType',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId AND LEN(isnull(SP.SubWorkOrderNo,'')) >0) > 1 ) Then 'Multiple' ELse  isnull(SP.SubWorkOrderNo,'')   End)
						as 'SubWorkOrderNoType',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId AND LEN(isnull(SP.SalesOrderNo,'')) >0) > 1 ) Then 'Multiple' ELse  isnull(SP.SalesOrderNo,'')   End)
						as 'SalesOrderNoType',
						--(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						--FROM  dbo.VendorRFQRepairOrderPart VRPP 
						--WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId AND LEN(isnull(SP.PurchaseOrderNumber,'')) >0) > 1 ) Then 'Multiple' ELse  isnull(SP.PurchaseOrderNumber,'')   End)
						--as 'PurchaseOrderNumberType',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.Memo,'')) >0) Then 'Multiple' ELse  isnull(SP.Memo,'')   End)
						as 'MemoType',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.Level1,'')) >0 ) Then 'Multiple' ELse  isnull(SP.Level1,'')   End)
						as 'Level1Type',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.Level2,'')) >0 
						 ) Then 'Multiple' ELse  isnull(SP.Level2,'')   End)
						as 'Level2Type',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.Level3,'')) >0 
						) Then 'Multiple' ELse  isnull(SP.Level3,'')   End)
						as 'Level3Type',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.Level4,'')) >0 
						 ) Then 'Multiple' ELse  isnull(SP.Level4,'')   End)
						as 'Level4Type',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.AltEquiPartNumber,'')) >0 
						 ) Then 'Multiple' ELse  isnull(SP.AltEquiPartNumber,'')   End)
						as 'AltEquiPartNumberType',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.RevisedPartNumber,'')) >0 
						 ) Then 'Multiple' ELse  isnull(SP.RevisedPartNumber,'')   End)
						as 'RevisedPartNumberType',
						(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 AND LEN(isnull(SP.WorkPerformed,'')) >0 
						 ) Then 'Multiple' ELse  isnull(SP.WorkPerformed,'')   End)
						as 'WorkPerformedType',
						D.NeedByDate,D.PromisedDate,D.NeedByDateType,D.PromisedDateType
					
					
					from Main M
					LEFT JOIN PartCTE PC ON PC.VendorRFQRepairOrderId=M.VendorRFQRepairOrderId
					LEFT JOIN PartDescCTE PDC ON PDC.VendorRFQRepairOrderId=M.VendorRFQRepairOrderId
					LEFT JOIN VendorRFQRepairOrderPart SP ON SP.VendorRFQRepairOrderId=M.VendorRFQRepairOrderId
					
					LEFT JOIN DatesCTE D ON D.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId			
			
			WHERE ((@GlobalFilter <>'' AND ((VendorRFQRepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
			        (M.CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(M.UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR	
					(VendorCode LIKE '%' +@GlobalFilter+'%') OR					
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR					
					([Status] LIKE '%' +@GlobalFilter+'%') ))
					OR 
					(@GlobalFilter='' AND M.IsDeleted=@IsDeleted AND
					(ISNULL(@VendorRFQRepairOrderNumber,'') ='' OR VendorRFQRepairOrderNumber LIKE '%' + @VendorRFQRepairOrderNumber +'%') AND 
					(ISNULL(@CreatedBy,'') ='' OR M.CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR M.UpdatedBy LIKE '%' + @UpdatedBy + '%') AND					
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND
					(ISNULL(@RequestedBy,'') ='' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND
					(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND		
					(ISNULL(@PartNumber,'') ='' OR PartNumberType LIKE '%' +@PartNumber + '%') AND
					(ISNULL(@PartDescription   ,'') ='' OR	PartDescriptionType LIKE '%' +   @PartDescription    + '%') AND
					(ISNULL(@AltEquiPartNumber   ,'') ='' OR	AltEquiPartNumber LIKE '%' +   @AltEquiPartNumber    + '%') AND
					(ISNULL(@RevisedPartNumber   ,'') ='' OR	RevisedPartNumber LIKE '%' +   @RevisedPartNumber    + '%') AND
					(ISNULL(@StockType   ,'') ='' OR	StockType LIKE '%' +   @StockType    + '%') AND
					(ISNULL(@Manufacturer   ,'') ='' OR	Manufacturer LIKE '%' +   @Manufacturer    + '%') AND
					(ISNULL(@Priority   ,'') ='' OR	Priority LIKE '%' +   @Priority    + '%') AND
					(ISNULL(@NeedByDate   ,'') ='' OR	CAST(NeedByDateType AS Date)=CAST(@NeedByDate AS date)) AND
					(ISNULL(@PromisedDate   ,'') ='' OR	CAST(PromisedDateType AS Date)=CAST(@PromisedDate AS date)) AND
					(ISNULL(@Condition   ,'') ='' OR	Condition LIKE '%' +   @Condition    + '%') AND
					(ISNULL(@WorkPerformed   ,'') ='' OR	WorkPerformed LIKE '%' +   @WorkPerformed    + '%') AND
					(ISNULL(@QuantityOrdered   ,'') ='' OR	QuantityOrdered LIKE '%' +   @QuantityOrdered    + '%') AND
					(ISNULL(@UnitCost   ,'') ='' OR	UnitCost LIKE '%' +   @UnitCost    + '%') AND
					(ISNULL(@WorkOrderNo   ,'') ='' OR	WorkOrderNo LIKE '%' +   @WorkOrderNo    + '%') AND
					(ISNULL(@SubWorkOrderNo   ,'') ='' OR	SubWorkOrderNo LIKE '%' +   @SubWorkOrderNo    + '%') AND
					(ISNULL(@SalesOrderNo   ,'') ='' OR	SalesOrderNo LIKE '%' +   @SalesOrderNo    + '%') AND
					(ISNULL(@Level1Type   ,'') ='' OR	Level1 LIKE '%' +   @Level1Type    + '%') AND
					(ISNULL(@Level2Type   ,'') ='' OR	Level2 LIKE '%' +   @Level2Type    + '%') AND
					(ISNULL(@Level3Type   ,'') ='' OR	Level3 LIKE '%' +   @Level3Type    + '%') AND
					(ISNULL(@Level4Type   ,'') ='' OR	Level4 LIKE '%' +   @Level4Type    + '%') AND
					(ISNULL(@Memo   ,'') ='' OR Memo LIKE '%' +   @Memo    + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND									
					(ISNULL(@ClosedDate,'') ='' OR CAST(ClosedDate AS Date) = CAST(@ClosedDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(M.CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(M.UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )
				   GROUP BY M.VendorRFQRepairOrderId,VendorRFQRepairOrderNumber,OpenDate,ClosedDate,M.CreatedDate,M.CreatedBy,M.UpdatedDate,
					M.UpdatedBy,M.IsActive,M.IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered,
					RequestedBy,PC.PartNumber,PDC.PartDescription,pc.PartNumberType,pdc.PartDescriptionType,
					SP.StockType
					,SP.Manufacturer,SP.Priority,D.NeedByDate,D.PromisedDate,D.NeedByDateType,D.PromisedDateType,sp.Memo,sp.Level1,sp.Level2,sp.Level3,sp.Level4
					,SP.Condition,SP.WorkOrderNo,SP.SubWorkOrderNo,SP.SalesOrderNo,SP.AltEquiPartNumber,SP.RevisedPartNumber,SP.WorkPerformed--,Level1,Level2,Level3,Level4,Memo--,PurchaseOrderId
			), 
			CTE_Count AS (Select COUNT(VendorRFQRepairOrderId) AS NumberOfItems FROM result)
			SELECT VendorRFQRepairOrderId,VendorRFQRepairOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,
					UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered
					,RequestedBy,PartNumber,PartDescription,PartNumberType,PartDescriptionType,StockTypeType,
					ManufacturerType,PriorityType,NeedByDate,PromisedDate,NeedByDateType,PromisedDateType,ConditionType,WorkOrderNoType,SubWorkOrderNoType,SalesOrderNoType--,PurchaseOrderNumberType
					
					,NumberOfItems,Level1Type,Level2Type,Level3Type,Level4Type,MemoType,AltEquiPartNumberType,RevisedPartNumberType,WorkPerformedType
					FROM result,CTE_Count
			ORDER BY  
            CASE WHEN (@SortOrder=1 AND @SortColumn='VendorRFQRepairOrderNumber')  THEN VendorRFQRepairOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQRepairOrderNumber')  THEN VendorRFQRepairOrderNumber END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='ClosedDate')  THEN ClosedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ClosedDate')  THEN ClosedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='RequestedBy')  THEN RequestedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RequestedBy')  THEN RequestedBy END DESC,			          
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='partNumberType')  THEN PartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='partNumberType')  THEN PartNumberType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='altEquiPartNumberType')  THEN AltEquiPartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='altEquiPartNumberType')  THEN AltEquiPartNumberType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='partDescriptionType')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='partDescriptionType')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='revisedPartNumberType')  THEN RevisedPartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='revisedPartNumberType')  THEN RevisedPartNumberType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='manufacturerType')  THEN ManufacturerType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='manufacturerType')  THEN ManufacturerType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='stockTypeType')  THEN StockTypeType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='stockTypeType')  THEN StockTypeType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='priorityType')  THEN PriorityType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='priorityType')  THEN PriorityType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='conditionType')  THEN ConditionType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='conditionType')  THEN ConditionType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='workPerformedType')  THEN WorkPerformedType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='workPerformedType')  THEN WorkPerformedType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='quantityOrdered')  THEN QuantityOrdered END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityOrdered')  THEN QuantityOrdered END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='needByDateType')  THEN NeedByDateType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='needByDateType')  THEN NeedByDateType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='unitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='unitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='promisedDateType')  THEN PromisedDateType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='promisedDateType')  THEN PromisedDateType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='workOrderNoType')  THEN WorkOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='workOrderNoType')  THEN WorkOrderNoType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='subWorkOrderNoType')  THEN SubWorkOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='subWorkOrderNoType')  THEN SubWorkOrderNoType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='salesOrderNoType')  THEN SalesOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='salesOrderNoType')  THEN SalesOrderNoType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='memoType')  THEN MemoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='memoType')  THEN MemoType END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='level1Type')  THEN Level1Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='level1Type')  THEN Level1Type END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='level2Type')  THEN Level2Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='level2Type')  THEN Level2Type END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='level3Type')  THEN Level3Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='level3Type')  THEN Level3Type END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='level4Type')  THEN Level4Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='level4Type')  THEN Level4Type END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END
	END TRY    
	BEGIN CATCH      
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'ProcGetVendorRFQRoList'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			+ '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			+ '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			+ '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			+ '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			+ '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			+ '@Parameter7 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			+ '@Parameter8 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			+ '@Parameter9 = ''' + CAST(ISNULL(@UpdatedBy , '') AS varchar(100))
			+ '@Parameter10 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))			
			+ '@Parameter11 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			+ '@Parameter12 = ''' + CAST(ISNULL(@EmployeeId , '') AS varchar(100))
			+ '@Parameter13 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
		,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END