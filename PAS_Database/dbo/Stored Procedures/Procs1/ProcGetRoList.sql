/*************************************************************           
 ** File:   [ProcGetRoList]           
 ** Author:   Moin Bloch  
 ** Description: Get Data for Repair Order listing
 ** Purpose:         
 ** Date:   17-Dec-2020
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** SN   Date           Author  		Change Description            
 ** --   --------		-------------	--------------------------------          
    01	 03-July-2023	Vishal Suthar	Removed script of "MULTIPLE" hover over
     
-- EXEC GetPurchaseOrderList @PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,@StatusID=1,@Status=N'Open',@GlobalFilter=N'',@PurchaseOrderNumber=NULL,@OpenDate=NULL,@VendorName=NULL,@RequestedBy=NULL,@ApprovedBy=NULL,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@EmployeeId=98,@MasterCompanyId=11,@VendorId=NULL,@ViewType=N'poview',@PartNumberType=NULL,@EstDeliveryType=NULL,@ManufacturerType=NULL,@SalesOrderNumberType=NULL,@WorkOrderNumType=NULL,@RepairOrderNumberType=NULL,@QuantityOrdered=NULL,@QuantityBackOrdered=NULL,@QuantityReceived=NULL
**************************************************************/
CREATE   PROCEDURE [dbo].[ProcGetRoList]
	@PageNumber int = null,
	@PageSize int = null,
	@SortColumn varchar(50) = null,
	@SortOrder int = null,
	@StatusID int = null,
	@GlobalFilter varchar(50) = null,
	@RepairOrderNumber varchar(50) = null,	
	@OpenDate datetime = null,
	@ClosedDate datetime = null,
	@VendorName varchar(50) = null,
	@VendorCode varchar(50) = null,
	@Status varchar(50) = null,
	@ApprovedBy varchar(50) = null,
	@RequestedBy varchar(50) = null,	
	@CreatedDate datetime = null,
	@UpdatedDate  datetime = null,
	@CreatedBy  varchar(50) = null,
	@UpdatedBy  varchar(50) = null,
	@IsDeleted bit = null,
	@EmployeeId bigint = 1,
	@MasterCompanyId bigint = 1,
	@VendorId bigint = null,
	@ViewType varchar(50) = null,
	@PartNumberType varchar(50) = null,
	@EstDeliveryType varchar(50) = null,
	@ManufacturerType varchar(50) = null,
	@SalesOrderNumberType varchar(50) = null,
	@WorkOrderNumType varchar(50) = null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @RecordFrom int;
		Declare @IsActive bit=1
		DECLARE @Count Int;
		DECLARE @ItemTypeAsset Int;
		DECLARE @ItemTypeStock Int;
		DECLARE @ItemTypeNonStock Int;

		SELECT @ItemTypeStock = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [name] = 'Stock'
		SELECT @ItemTypeNonStock = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [name] = 'Non-Stock'
		SELECT @ItemTypeAsset = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [name] = 'Asset'

		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		IF @IsDeleted IS NULL
		Begin
			Set @IsDeleted = 0
		End
		print @IsDeleted	
		
		IF @SortColumn IS NULL
		Begin
			Set @SortColumn = Upper('CreatedDate')
		End 
		Else
		Begin 
			Set @SortColumn = Upper(@SortColumn)
		End
		IF (@StatusID = 6 AND @Status = 'All')
		BEGIN			
			SET @Status = ''
		END
		IF (@StatusID = 6 OR @StatusID = 0)
		BEGIN
			SET @StatusID = null			
		END
		DECLARE @MSModuleID INT = 24; -- Repair Order Management Structure Module ID
		IF (@ViewType = 'roview')
		BEGIN
		;With Result AS(
			SELECT DISTINCT 
			       RO.RepairOrderId,
			       RO.RepairOrderNumber,
				   RO.RepairOrderNumber AS RepairOrderNo,				   
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
				   RO.ApprovedBy,
				   (CASE WHEN COUNT(ROP.RepairOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(ROP.PartNumber) END) AS 'PartNumberType',
				   (CASE WHEN Count(ROP.RepairOrderPartRecordId) > 1 THEN 'Multiple' ELSE CAST(CONVERT(VARCHAR, MAX(ROP.EstRecordDate), 101) AS VARCHAR(MAX)) END) AS 'EstDeliveryType',
				   (CASE WHEN COUNT(ROP.RepairOrderPartRecordId) > 1 THEN 'Multiple' ELSE MAX(ROP.Manufacturer) END) AS 'ManufacturerType',
				   (Case When Count(ROP.RepairOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(WO.WorkOrderNum) End)  as 'WorkOrderNumType',
				   (Case When Count(ROP.RepairOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(SO.SalesOrderNumber) End)  as 'SalesOrderNumberType'
			FROM DBO.RepairOrder RO WITH (NOLOCK)
			 --INNER JOIN  dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = RO.ManagementStructureId		              			  
			 INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = RO.RepairOrderId
			 INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			 INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			 LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId AND ROP.isParent=1
			 LEFT Join dbo.WorkOrder WO WITH (NOLOCK) On ROP.WorkOrderId = WO.WorkOrderId
			 LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) On ROP.SalesOrderId = SO.SalesOrderId
			WHERE ((RO.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR RO.StatusId=@StatusID)) AND
					RO.MasterCompanyId=@MasterCompanyId 
			GROUP BY RO.RepairOrderId,
			       RO.RepairOrderNumber,
				   RO.RepairOrderNumber,				   
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
				   RO.Requisitioner,
				   RO.ApprovedBy
				)
			--,PartCTE AS(
			--			Select RO.RepairOrderId,(Case When Count(ROP.RepairOrderPartRecordId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber 
			--			FROM RepairOrder RO WITH (NOLOCK)
			--			LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) On RO.RepairOrderId = ROP.RepairOrderId --AND ROP.IsActive = 1 AND ROP.IsDeleted = 0 AND ROP.isParent=1
			--			Outer Apply(
			--				SELECT 
			--				   STUFF((SELECT ',' + CASE WHEN R.ItemTypeId = @ItemTypeStock THEN I.partnumber 
			--											WHEN R.ItemTypeId = @ItemTypeAsset THEN AI.AssetId
			--											WHEN R.ItemTypeId = @ItemTypeNonStock THEN NI.PartNumber
			--											ELSE I.partnumber END  														
			--						  FROM dbo.RepairOrderPart R WITH (NOLOCK)
			--						  LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On R.ItemMasterId = I.ItemMasterId
			--						  LEFT JOIN dbo.Assetinventory AI WITH (NOLOCK) On R.ItemMasterId = AI.AssetinventoryId
			--						  LEFT JOIN dbo.NonStockinventory NI WITH (NOLOCK) On R.ItemMasterId = NI.NonStockInventoryId
			--						  Where R.RepairOrderId = ROP.RepairOrderId AND RO.IsActive = 1 AND RO.IsDeleted = 0 AND R.isParent = 1
			--						  FOR XML PATH('')), 1, 1, '') PartNumber
			--			) A
			--			Where (RO.IsDeleted = @IsDeleted) 
			--			Group By RO.RepairOrderId,A.PartNumber,ROP.EstRecordDate)
			--,PartDateCTE AS(
			--			Select RO.RepairOrderId, (CASE WHEN Count(ROP.RepairOrderPartRecordId) > 1 THEN 'Multiple' ELSE A.EstDeliveryDateMulti END) AS 'EstDeliveryType', A.EstDeliveryDateMulti 
			--			from RepairOrder RO WITH (NOLOCK)
			--			LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) On RO.RepairOrderId = ROP.RepairOrderId AND ROP.IsActive = 1 AND ROP.IsDeleted = 0 AND ROP.isParent = 1
			--			Outer Apply(
			--				SELECT 
			--				   STUFF((SELECT ',' + CAST(R.EstRecordDate as VARCHAR(MAX))											
			--						  FROM dbo.RepairOrderPart R WITH (NOLOCK)
			--						  Left Join dbo.ItemMaster I WITH (NOLOCK) On R.ItemMasterId = I.ItemMasterId
			--						  Left Join dbo.Assetinventory AI WITH (NOLOCK) On R.ItemMasterId = AI.AssetinventoryId
			--						  Left Join dbo.NonStockinventory NI WITH (NOLOCK) On R.ItemMasterId = NI.NonStockInventoryId
			--						  Where R.RepairOrderId = ROP.RepairOrderId AND RO.IsActive = 1 AND RO.IsDeleted = 0 AND R.isParent = 1
			--						  FOR XML PATH('')), 1, 1, '') EstDeliveryDateMulti
			--			) A
			--			Where (RO.IsDeleted = @IsDeleted)
			--			Group By RO.RepairOrderId,A.EstDeliveryDateMulti)
			--,ManufacturerCTE AS(
			--			Select RO.RepairOrderId,(CASE WHEN COUNT(ROP.RepairOrderPartRecordId) > 1 THEN 'Multiple' ELSE M.Manufacturer END) AS 'ManufacturerType',M.Manufacturer 
			--			FROM [dbo].[RepairOrder] RO WITH (NOLOCK)
			--			LEFT JOIN [dbo].[RepairOrderPart] ROP WITH (NOLOCK) ON RO.RepairOrderId=ROP.RepairOrderId AND ROP.IsActive = 1 AND ROP.IsDeleted = 0 AND ROP.isParent=1
			--			OUTER APPLY(
			--				SELECT 
			--				   STUFF((SELECT ',' + M.[Name]
			--						  FROM [dbo].[RepairOrderPart] P WITH (NOLOCK)
			--						  LEFT JOIN [dbo].[Manufacturer] M WITH (NOLOCK) ON P.ManufacturerId = M.ManufacturerId
			--						  WHERE P.RepairOrderId = ROP.RepairOrderId AND P.IsActive = 1 AND P.IsDeleted = 0 AND P.isParent = 1
			--						  FOR XML PATH('')), 1, 1, '') Manufacturer								
			--			) M
			--			WHERE (RO.IsDeleted = @IsDeleted) GROUP BY RO.RepairOrderId,M.Manufacturer)
			--,WOCTE AS(
			--			Select RO.RepairOrderId,(Case When Count(ROP.RepairOrderPartRecordId) > 1 Then 'Multiple' ELse B.WorkOrderNum End)  as 'WorkOrderNumType',B.WorkOrderNum from RepairOrder RO WITH (NOLOCK)
			--			Left Join RepairOrderPart ROP WITH (NOLOCK) On RO.RepairOrderId=ROP.RepairOrderId AND ROP.IsActive = 1 AND ROP.IsDeleted = 0 AND ROP.isParent=1
			--			INNER Join WorkOrder I WITH (NOLOCK) On ROP.WorkOrderId=I.WorkOrderId
			--			Outer Apply(
			--				SELECT 
			--				   STUFF((SELECT ',' + I.WorkOrderNum
			--						  FROM RepairOrderPart R WITH (NOLOCK)
			--						  Left Join WorkOrder I WITH (NOLOCK) On R.WorkOrderId = I.WorkOrderId
			--						  Where R.RepairOrderId = ROP.RepairOrderId AND R.IsActive = 1 AND R.IsDeleted = 0 AND R.isParent = 1
			--						  FOR XML PATH('')), 1, 1, '') WorkOrderNum
			--			) B
			--Where (RO.IsDeleted=@IsDeleted)
			--Group By RO.RepairOrderId,B.WorkOrderNum)
			--,SOCTE AS(
			--			Select RO.RepairOrderId,(Case When Count(ROP.RepairOrderPartRecordId) > 1 Then 'Multiple' ELse C.SalesOrderNumber End)  as 'SalesOrderNumberType', C.SalesOrderNumber 
			--			FROM RepairOrder RO WITH (NOLOCK)
			--			LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) On RO.RepairOrderId = ROP.RepairOrderId AND ROP.IsActive = 1 AND ROP.IsDeleted = 0 AND ROP.isParent = 1
			--			INNER JOIN dbo.SalesOrder I WITH (NOLOCK) On ROP.SalesOrderId = I.SalesOrderId
			--			Outer Apply(
			--				SELECT 
			--				   STUFF((SELECT ',' + I.SalesOrderNumber
			--						  FROM dbo.RepairOrderPart R WITH (NOLOCK)
			--						  Left Join dbo.SalesOrder I WITH (NOLOCK) ON R.SalesOrderId = I.SalesOrderId
			--						  Where R.RepairOrderId = ROP.RepairOrderId AND R.IsActive = 1 AND R.IsDeleted = 0 AND R.isParent = 1
			--						  FOR XML PATH('')), 1, 1, '') SalesOrderNumber
			--			) C
			--Where (RO.IsDeleted = @IsDeleted) 
			--Group By RO.RepairOrderId,C.SalesOrderNumber)
			,ResultData AS(
						Select M.RepairOrderId,M.RepairOrderNumber,M.RepairOrderNo,M.OpenDate as 'OpenDate',M.ClosedDate as 'ClosedDate',M.CreatedDate,
									M.CreatedBy,M.UpdatedDate,M.UpdatedBy,M.IsActive,M.IsDeleted,
									M.VendorId,M.VendorName,M.VendorCode,M.StatusId,M.[Status],M.RequestedBy,M.ApprovedBy,
									M.SalesOrderNumberType,
									--PR.SalesOrderNumber,
									--M.PartNumber,
									M.PartNumberType,
									--MF.Manufacturer,
									M.ManufacturerType,
									--M.WorkOrderNum,
									M.WorkOrderNumType,
									--M.EstDeliveryDateMulti,
									CAST(M.EstDeliveryType AS VARCHAR(MAX)) as 'EstDeliveryType',
									0 as RepairOrderPartRecordId
									from Result M 
						--Left Join PartCTE PT On M.RepairOrderId=PT.RepairOrderId
						--Left Join PartDateCTE PDT On M.RepairOrderId=PDT.RepairOrderId
						--LEFT JOIN ManufacturerCTE MF ON MF.RepairOrderId=M.RepairOrderId	
						--Left Join WOCTE PD on PD.RepairOrderId=M.RepairOrderId
						--Left Join SOCTE PR on PR.RepairOrderId=M.RepairOrderId
			WHERE ((@GlobalFilter <>'' AND ((RepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
			        (CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR	
					(VendorCode LIKE '%' +@GlobalFilter+'%') OR					
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR
					(ApprovedBy LIKE '%' +@GlobalFilter+'%') OR
					([Status] LIKE '%' +@GlobalFilter+'%') OR
					(M.PartNumberType like '%' +@GlobalFilter+'%') OR
					(M.ManufacturerType like '%' +@GlobalFilter+'%') OR
					(M.SalesOrderNumberType like '%' +@GlobalFilter+'%') OR
					(M.WorkOrderNumType like '%' +@GlobalFilter+'%')))
					OR 
					(@GlobalFilter='' AND IsDeleted=@IsDeleted AND
					(ISNULL(@RepairOrderNumber,'') ='' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber+'%') AND 
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND
					(ISNULL(@ApprovedBy,'') ='' OR ApprovedBy LIKE '%' + @ApprovedBy + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND
					(ISNULL(@RequestedBy,'') ='' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND
					(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND									
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND									
					(ISNULL(@ClosedDate,'') ='' OR CAST(ClosedDate AS Date) = CAST(@ClosedDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND
					(ISNULL(@PartNumberType,'') ='' OR M.PartNumberType like '%'+ @PartNumberType+'%') AND
					(ISNULL(@EstDeliveryType,'') ='' OR M.EstDeliveryType like '%'+ @EstDeliveryType+'%') AND					
					(ISNULL(@ManufacturerType,'') ='' OR M.ManufacturerType like '%'+ @ManufacturerType+'%') AND
					(ISNULL(@SalesOrderNumberType,'') ='' OR M.SalesOrderNumberType like '%'+@SalesOrderNumberType+'%') AND
					(ISNULL(@WorkOrderNumType,'') ='' OR M.WorkOrderNumType like '%'+@WorkOrderNumType+'%'))
				   )
				   --SELECT @Count = COUNT(RepairOrderId) FROM #TempResult
				   --SELECT *, @Count AS NumberOfItems FROM #TempResult
				   ), CTE_Count AS (Select COUNT(RepairOrderId) AS NumberOfItems FROM ResultData)
						SELECT RepairOrderId,RepairOrderNumber,RepairOrderNo,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,UpdatedBy,IsActive,IsDeleted
						,VendorId,VendorName,VendorCode,StatusId,[Status],RequestedBy,ApprovedBy,
						'' PartNumber, PartNumberType, '' Manufacturer, ManufacturerType, '' WorkOrderNum, WorkOrderNumType, '' SalesOrderNumber, SalesOrderNumberType,
						CreatedDate, UpdatedDate, NumberOfItems, CreatedBy, UpdatedBy, '' EstDeliveryDateMulti, EstDeliveryType, RepairOrderPartRecordId 
						FROM ResultData, CTE_Count
			ORDER BY  
            CASE WHEN (@SortOrder=1 AND @SortColumn='repairOrderNumber')  THEN repairOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='repairOrderNumber')  THEN repairOrderNumber END DESC,
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
			CASE WHEN (@SortOrder=1 AND @SortColumn='ApprovedBy')  THEN ApprovedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ApprovedBy')  THEN ApprovedBy END DESC,           
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
			;With Result AS(
			SELECT DISTINCT 
			       RO.RepairOrderId,
			       RO.RepairOrderNumber,
				   RO.RepairOrderNumber AS RepairOrderNo,				   
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
				   RO.ApprovedBy,
				   ROP.PartNumber,
				   ROP.PartNumber as PartNumberType,
				   M.[Name] AS Manufacturer,
				   M.[Name] AS ManufacturerType,
				   SO.SalesOrderNumber,
				   SO.SalesOrderNumber as SalesOrderNumberType,
				   WO.WorkOrderNum,
				   WO.WorkOrderNum as WorkOrderNumType,
				   CAST(ROP.EstRecordDate AS VARCHAR(MAX)) as EstDeliveryDateMulti,
				   CAST(ROP.EstRecordDate AS VARCHAR(MAX)) as EstDeliveryType,
				   ROP.RepairOrderPartRecordId
			FROM  dbo.RepairOrder RO WITH (NOLOCK)
			 --INNER JOIN  dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = RO.ManagementStructureId		              			  
			 INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = RO.RepairOrderId
			 INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			 INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			 LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId AND ROP.isParent=1
			 LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON ROP.SalesOrderId = SO.SalesOrderId
			 LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON ROP.WorkOrderId = WO.WorkOrderId
			 LEFT JOIN [dbo].[Manufacturer] M WITH (NOLOCK) ON ROP.ManufacturerId = M.ManufacturerId

			WHERE ((RO.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR RO.StatusId=@StatusID)) AND
			        --EMS.EmployeeId = @EmployeeId AND 
					RO.MasterCompanyId=@MasterCompanyId 
					), ResultCount AS(Select COUNT(RepairOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE ((@GlobalFilter <>'' AND ((RepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
			        (CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR	
					(VendorCode LIKE '%' +@GlobalFilter+'%') OR					
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR
					(ApprovedBy LIKE '%' +@GlobalFilter+'%') OR
					([Status] LIKE '%' +@GlobalFilter+'%') OR
					(PartNumber like '%' +@GlobalFilter+'%') OR
					(Manufacturer LIKE '%' +@GlobalFilter+'%') OR
					(SalesOrderNumberType like '%' +@GlobalFilter+'%') OR
					(WorkOrderNumType like '%' +@GlobalFilter+'%')))
					OR 
					(@GlobalFilter='' AND IsDeleted=@IsDeleted AND
					(ISNULL(@RepairOrderNumber,'') ='' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber+'%') AND 
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND
					(ISNULL(@ApprovedBy,'') ='' OR ApprovedBy LIKE '%' + @ApprovedBy + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND
					(ISNULL(@RequestedBy,'') ='' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND
					(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND									
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND									
					(ISNULL(@ClosedDate,'') ='' OR CAST(ClosedDate AS Date) = CAST(@ClosedDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date))  AND
					(IsNull(@PartNumberType,'') ='' OR PartNumber like '%'+ @PartNumberType+'%') and
					(ISNULL(@EstDeliveryType,'') ='' OR EstDeliveryDateMulti like '%'+ @EstDeliveryType+'%') and
					(ISNULL(@ManufacturerType,'') ='' OR Manufacturer like '%'+ @ManufacturerType +'%') AND
					(IsNull(@SalesOrderNumberType,'') ='' OR SalesOrderNumberType like '%'+@SalesOrderNumberType+'%') and
					(IsNull(@WorkOrderNumType,'') ='' OR WorkOrderNumType like '%'+@WorkOrderNumType+'%'))
				   )
				   SELECT @Count = COUNT(RepairOrderId) FROM #TempResult
				   SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
            CASE WHEN (@SortOrder=1 AND @SortColumn='repairOrderNumber')  THEN repairOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='repairOrderNumber')  THEN repairOrderNumber END DESC,
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
			CASE WHEN (@SortOrder=1 AND @SortColumn='ApprovedBy')  THEN ApprovedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ApprovedBy')  THEN ApprovedBy END DESC,           
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END DESC,	
			CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END
	END TRY    
	BEGIN CATCH      
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'ProcGetRoList'
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