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
    01	 03-July-2023	Vishal Suthar		Removed script of "MULTIPLE" hover over
	02	 30-Dec-2024	Abhishek Jirawla	MULTIPLE checking was improper so corrected it and Performance changes implemented
	03	 03-Mar-2025	Bhargav Saliya		Get New isStkLable value
	04   10-March-2025  Sahdev Saliya		Added a case to get timeZone
	05   12-03-2025     Shrey Chandegara    Modified due to add view in Accouting Integration List's PendingSync(Add @IsUpdated parameter)
	06   18-03-2025     Ekta Chandegara     Add @PartDescription parameter and retrieve PartDescription column value
	07	 30-Dec-2024	Vishal Suthar		Removed subqueries and used CTE for Performance imporvement
	08   07-04-2025     Shrey Chandegara    Modified due to PN-12013
	09   14-04-2025     Moin Bloch          Modified Fix Order Isuee in RO List
	10   25-04-2025     HEMANT SALIYA       Modified Fix Default Order Isuee in RO List Created By
	11   13-05-2025     Bhargav Saliya      MULTIPLE checking for  WO and SO Number was improper so corrected it
	12   04-12-2025     Amit Ghediya        Added qtyShipped,qtyRemaining for shipping details
	13   14-05-2026     Bhargav Saliya      Remove The VendoreId Condition [PN-16416]
	14	 22/06/2026		Abhishek Jirawla	Adding IsPiecePart condition in RepairOrderPart table
	16	 07/07/2026		Abhishek Jirawla	Added @StatusIds parameter to filter RO list by multiple ROStatusEnum values (PN-16786)
	17	 16/07/2026		Abhishek Jirawla	Added @StrictVendorId parameter to filter RO list strictly by a single VendorId, independent of the existing @VendorId condition disabled per PN-16416 (PN-16786)
	18	 22/07/2026		Bhargav Saliya		Changed qtyShipped/qtyRemaining temp columns to DECIMAL(18,6) so they match the decimal type expected by the API (PN-17353)

-- exec ProcGetRoList @PageNumber=1,@PageSize=20,@SortColumn=N'CreatedDate',@SortOrder=-1,@StatusID=6,@GlobalFilter=N'',@RepairOrderNumber=NULL,@OpenDate=NULL,@ClosedDate=NULL,@VendorName=NULL,@VendorCode=NULL,@Status=N'open',@ApprovedBy=NULL,@RequestedBy=NULL,@CreatedDate=NULL,@UpdatedDate=NULL,@CreatedBy=NULL,@UpdatedBy=NULL,@IsDeleted=0,@EmployeeId=223,@MasterCompanyId=1,@VendorId=NULL,@ViewType=N'roview',@PartNumberType=NULL,@PartDescription=NULL,@EstDeliveryType=NULL,@ManufacturerType=NULL,@SalesOrderNumberType=NULL,@WorkOrderNumType=NULL,@IsUpdated=0
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
	@PartDescription nvarchar(MAX),
	@EstDeliveryType varchar(50) = null,
	@ManufacturerType varchar(50) = null,
	@SalesOrderNumberType varchar(50) = null,
	@WorkOrderNumType varchar(50) = null,
	@IsUpdated BIT = NULL,
	@qtyShipped varchar(50) = NULL,
	@qtyRemaining varchar(50) = NULL,
	@StatusIds nvarchar(max) = NULL,
	@StrictVendorId bigint = NULL
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
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
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

		SELECT @ItemTypeStock = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [name] = 'Stock'
		SELECT @ItemTypeNonStock = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [name] = 'Non-Stock'
		SELECT @ItemTypeAsset = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [name] = 'Asset'

		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		IF @IsDeleted IS NULL
		Begin
			Set @IsDeleted = 0
		End

		IF @SortColumn IS NULL OR @SortColumn = Upper('CreatedDate')
		Begin
			Set @SortColumn = Upper('RepairOrderId')
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

		IF OBJECT_ID('tempdb..#tmpReceivingRoviewList') IS NOT NULL DROP TABLE #TempResult;
		IF OBJECT_ID('tempdb..#tmpReceivingPnviewList') IS NOT NULL DROP TABLE #TempResult;

		IF (@ViewType = 'roview')
		BEGIN
			;WITH RepairOrderPartAggregated AS (
				SELECT
					ROP.RepairOrderId,
					COUNT(ROP.RepairOrderPartRecordId) AS PartCount,
					COUNT(ROP.WorkOrderId) AS WorkOrderCount,
					COUNT(ROP.SalesOrderId) AS SalesOrderCount,
					MAX(ROP.PartNumber) AS MaxPartNumber,
					MAX(ROP.PartDescription) AS MaxPartDescription,
					MAX(ROP.EstRecordDate) AS MaxEstRecordDate,
					MAX(ROP.Manufacturer) AS MaxManufacturer,
					MAX(ROP.WorkOrderNo) AS MaxWorkOrderNo,
					MAX(ROP.SalesOrderNo) AS MaxSalesOrderNo,
					SUM(ROP.QuantityOrdered) AS QuantityOrdered
				FROM dbo.RepairOrderPart ROP WITH (NOLOCK)
				WHERE ROP.IsParent = 1 AND ISNULL(ROP.[IsPiecePart], 0) = 0
				GROUP BY ROP.RepairOrderId
			)

			SELECT DISTINCT
			       RO.RepairOrderId,
			       RO.RepairOrderNumber,
				   RO.RepairOrderNumber AS RepairOrderNo,
			       RO.OpenDate,
				   RO.ClosedDate,
				   case when CAST(RO.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(RO.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate,
				   RO.CreatedBy,
				   case when CAST(RO.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(RO.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate,
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
					CASE WHEN ROPA.PartCount > 1 THEN 'Multiple' ELSE ROPA.MaxPartNumber END AS PartNumberType,
					CASE WHEN ROPA.PartCount > 1 THEN 'Multiple' ELSE ROPA.MaxPartDescription END AS PartDescription,
					CASE WHEN ROPA.PartCount > 1 THEN 'Multiple' ELSE CAST(CONVERT(VARCHAR, ROPA.MaxEstRecordDate, 101) AS VARCHAR(MAX)) END AS EstDeliveryType,
					CASE WHEN ROPA.PartCount > 1 THEN 'Multiple' ELSE ROPA.MaxManufacturer END AS ManufacturerType,
					CASE WHEN ROPA.WorkOrderCount > 1 THEN 'Multiple' ELSE ROPA.MaxWorkOrderNo END AS WorkOrderNumType,
					CASE WHEN ROPA.SalesOrderCount > 1 THEN 'Multiple' ELSE ROPA.MaxSalesOrderNo END AS SalesOrderNumberType,
					0 AS isStkLable,
					CAST(0 AS DECIMAL(18, 6)) AS qtyShipped,
					CAST(0 AS DECIMAL(18, 6)) AS qtyRemaining,
					ROPA.QuantityOrdered
			INTO #tmpReceivingRoviewList
			FROM DBO.RepairOrder RO WITH (NOLOCK)
			 INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = RO.RepairOrderId
			 INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			 INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			 LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId AND ROP.isParent=1
			 LEFT JOIN RepairOrderPartAggregated ROPA ON ROPA.RepairOrderId = RO.RepairOrderId
			WHERE ((RO.IsDeleted=@IsDeleted) AND
					(
						(@StatusIds IS NOT NULL AND LTRIM(RTRIM(@StatusIds)) <> '' AND RO.StatusId IN (SELECT CAST(value AS INT) FROM STRING_SPLIT(@StatusIds, ',')))
						OR
						((@StatusIds IS NULL OR LTRIM(RTRIM(@StatusIds)) = '') AND (@StatusID IS NULL OR RO.StatusId=@StatusID))
					)) AND
					RO.MasterCompanyId=@MasterCompanyId
					AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(RO.isUpdated,0) = ISNULL(@IsUpdated,0))AND (@StrictVendorId IS NULL OR RO.VendorId = @StrictVendorId) --AND (@VendorId IS NULL OR RO.VendorId = @VendorId)
			GROUP BY RO.RepairOrderId,RO.RepairOrderNumber,RO.RepairOrderNumber,RO.OpenDate,RO.ClosedDate,RO.CreatedDate,RO.CreatedBy,
				   RO.UpdatedDate,RO.UpdatedBy,RO.IsActive,RO.IsDeleted,RO.VendorId,RO.VendorName,RO.VendorCode,RO.StatusId,RO.[Status],
				   RO.Requisitioner,RO.ApprovedBy,ROPA.PartCount,
				   ROPA.MaxPartNumber, ROPA.MaxPartDescription,
				   ROPA.MaxEstRecordDate,
				   ROPA.MaxManufacturer,
				   ROPA.MaxWorkOrderNo,
				   ROPA.MaxSalesOrderNo,ROPA.WorkOrderCount,ROPA.SalesOrderCount,ROPA.QuantityOrdered

		    UPDATE TMP
				SET TMP.isStkLable = case when result.StkCount > 0 then 1 else 0 end
				FROM #tmpReceivingRoviewList TMP
				OUTER APPLY (
					SELECT COUNT(stk.StockLineId) AS StkCount FROM DBO.Stockline stk WITH (NOLOCK)
					WHERE stk.RepairOrderId = TMP.RepairOrderId)
				AS result

			UPDATE TMP1
				SET TMP1.qtyShipped = ISNULL(result.QtyShipped, 0),
					TMP1.qtyRemaining = ISNULL(result.QuantityOrdered, 0)
				FROM #tmpReceivingRoviewList TMP1
				OUTER APPLY (
					SELECT
						ISNULL(TMP1.QuantityOrdered,0) - ISNULL(SUM(ROSI.QtyShipped),0)AS QuantityOrdered,
						ISNULL(SUM(ROSI.QtyShipped),0) AS QtyShipped
					FROM DBO.RepairOrderPart rop WITH (NOLOCK)
					LEFT JOIN DBO.RepairOrderShippingItem ROSI WITH (NOLOCK) ON ROSI.RepairOrderPartId = rop.RepairOrderPartRecordId
					WHERE rop.RepairOrderId = TMP1.RepairOrderId AND ISNULL(ROP.[IsPiecePart], 0) = 0)
				AS result

			;WITH ResultData AS(
				Select M.RepairOrderId,M.RepairOrderNumber,M.RepairOrderNo,M.OpenDate as 'OpenDate',M.ClosedDate as 'ClosedDate',M.CreatedDate,
					M.CreatedBy,M.UpdatedDate,M.UpdatedBy,M.IsActive,M.IsDeleted,
					M.VendorId,M.VendorName,M.VendorCode,M.StatusId,M.[Status],M.RequestedBy,M.ApprovedBy,
					M.SalesOrderNumberType,
					M.PartNumberType,
					M.PartDescription,
					M.ManufacturerType,
					M.WorkOrderNumType,
					CAST(M.EstDeliveryType AS VARCHAR(MAX)) as 'EstDeliveryType',
					0 as RepairOrderPartRecordId,isStkLable,qtyShipped,qtyRemaining
				FROM #tmpReceivingRoviewList M

			WHERE ((@GlobalFilter <>'' AND ((RepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR
			        (CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(VendorCode LIKE '%' +@GlobalFilter+'%') OR
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR
					(ApprovedBy LIKE '%' +@GlobalFilter+'%') OR
					([Status] LIKE '%' +@GlobalFilter+'%') OR
					(M.PartNumberType like '%' +@GlobalFilter+'%') OR
					(M.PartDescription like '%' +@GlobalFilter+'%') OR
					(M.ManufacturerType like '%' +@GlobalFilter+'%') OR
					(M.SalesOrderNumberType like '%' +@GlobalFilter+'%') OR
					(M.WorkOrderNumType like '%' +@GlobalFilter+'%') OR
					(M.qtyShipped like '%' +@GlobalFilter+'%') OR
					(M.qtyRemaining like '%' +@GlobalFilter+'%')))
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
					(ISNULL(@PartDescription,'') ='' OR M.PartDescription like '%'+ @PartDescription+'%') AND
					(ISNULL(@EstDeliveryType,'') ='' OR M.EstDeliveryType like '%'+ @EstDeliveryType+'%') AND
					(ISNULL(@ManufacturerType,'') ='' OR M.ManufacturerType like '%'+ @ManufacturerType+'%') AND
					(ISNULL(@SalesOrderNumberType,'') ='' OR M.SalesOrderNumberType like '%'+@SalesOrderNumberType+'%') AND
					(ISNULL(@WorkOrderNumType,'') ='' OR M.WorkOrderNumType like '%'+@WorkOrderNumType+'%') AND
					(ISNULL(@qtyShipped,'') ='' OR M.qtyShipped like '%'+@qtyShipped+'%') AND
					(ISNULL(@qtyRemaining,'') ='' OR M.qtyRemaining like '%'+@qtyRemaining+'%'))
				   )),
					CTE_Count AS (Select COUNT(RepairOrderId) AS NumberOfItems FROM ResultData)
					SELECT RepairOrderId,RepairOrderNumber,RepairOrderNo,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,UpdatedBy,IsActive,IsDeleted
						,VendorId,VendorName,VendorCode,StatusId,[Status],RequestedBy,ApprovedBy,
						'' PartNumber, PartNumberType, PartDescription , '' Manufacturer, ManufacturerType, '' WorkOrderNum, WorkOrderNumType, '' SalesOrderNumber, SalesOrderNumberType,
						CreatedDate, UpdatedDate, NumberOfItems, CreatedBy, UpdatedBy, '' EstDeliveryDateMulti, EstDeliveryType, RepairOrderPartRecordId ,isStkLable,qtyShipped,qtyRemaining
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
			CASE WHEN (@SortOrder=1 and @SortColumn='PartNumberType')  THEN PartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumberType')  THEN PartNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='SalesOrderNumberType')  THEN SalesOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='SalesOrderNumberType')  THEN SalesOrderNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNumType')  THEN WorkOrderNumType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNumType')  THEN WorkOrderNumType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='EstDeliveryType')  THEN EstDeliveryType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='EstDeliveryType')  THEN EstDeliveryType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='RepairOrderId')  THEN RepairOrderId END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='RepairOrderId')  THEN RepairOrderId END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='qtyShipped')  THEN qtyShipped END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='qtyShipped')  THEN qtyShipped END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='qtyRemaining')  THEN qtyRemaining END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='qtyRemaining')  THEN qtyRemaining END DESC
			OFFSET @RecordFrom ROWS
			FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
			SELECT DISTINCT
			       RO.RepairOrderId,
			       RO.RepairOrderNumber,
				   RO.RepairOrderNumber AS RepairOrderNo,
			       RO.OpenDate,
				   RO.ClosedDate,
				   case when CAST(RO.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(RO.CreatedDate, @CurrntEmpTimeZoneDesc) as Date))end CreatedDate,
				   RO.CreatedBy,
				   case when CAST(RO.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(RO.UpdatedDate, @CurrntEmpTimeZoneDesc) as Date))end UpdatedDate,
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
				   ROP.PartDescription,
				   ROP.Manufacturer AS Manufacturer,
				   ROP.Manufacturer AS ManufacturerType,
				   ROP.SalesOrderNo,
				   ROP.SalesOrderNo as SalesOrderNumberType,
				   ROP.WorkOrderNo,
				   ROP.WorkOrderNo as WorkOrderNumType,
				   CAST(ROP.EstRecordDate AS VARCHAR(MAX)) as EstDeliveryDateMulti,
				   CAST(ROP.EstRecordDate AS VARCHAR(MAX)) as EstDeliveryType,
				   ROP.RepairOrderPartRecordId,
				   0 AS isStkLable,
				   CAST(0 AS DECIMAL(18, 6)) AS qtyShipped,
				   CAST(0 AS DECIMAL(18, 6)) AS qtyRemaining,
				   ROP.QuantityOrdered AS QuantityOrdered
			INTO #tmpReceivingPnviewList
			FROM  dbo.RepairOrder RO WITH (NOLOCK)
			 INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = RO.RepairOrderId
			 INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			 INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			 LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId AND ROP.isParent=1

			WHERE ((RO.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR RO.StatusId=@StatusID)) AND
			        RO.MasterCompanyId=@MasterCompanyId AND (@StrictVendorId IS NULL OR RO.VendorId = @StrictVendorId) --AND (@VendorId IS NULL OR RO.VendorId = @VendorId)

			UPDATE TMP
				SET TMP.isStkLable = case when result.StkCount > 0 then 1 else 0 end
				FROM #tmpReceivingPnviewList TMP
				OUTER APPLY (
					SELECT COUNT(stk.StockLineId) AS StkCount FROM DBO.Stockline stk WITH (NOLOCK)
					WHERE stk.RepairOrderId = TMP.RepairOrderId
					) AS result

			UPDATE TMP1
				SET TMP1.qtyShipped = ISNULL(result.QtyShipped, 0),
					TMP1.qtyRemaining = ISNULL(result.QuantityOrdered, 0)
				FROM #tmpReceivingPnviewList TMP1
				OUTER APPLY (
					SELECT
						ISNULL(TMP1.QuantityOrdered,0) - ISNULL(SUM(ROSI.QtyShipped),0) AS QuantityOrdered,
						ISNULL(SUM(ROSI.QtyShipped),0) AS QtyShipped
					FROM DBO.RepairOrderShippingItem ROSI WITH (NOLOCK)
					WHERE ROSI.RepairOrderPartId = TMP1.RepairOrderPartRecordId)
				AS result

					;with ResultCount AS(Select COUNT(RepairOrderId) AS totalItems FROM #tmpReceivingPnviewList)
			SELECT * INTO #TempResult FROM  #tmpReceivingPnviewList
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
					(IsNull(@PartDescription,'') ='' OR PartDescription like '%'+ @PartDescription+'%') and
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
			CASE WHEN (@SortOrder=1 and @SortColumn='PartNumberType')  THEN PartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumberType')  THEN PartNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='SalesOrderNumberType')  THEN SalesOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='SalesOrderNumberType')  THEN SalesOrderNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNumType')  THEN WorkOrderNumType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNumType')  THEN WorkOrderNumType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='EstDeliveryType')  THEN EstDeliveryType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='EstDeliveryType')  THEN EstDeliveryType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='RepairOrderId')  THEN RepairOrderId END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='RepairOrderId')  THEN RepairOrderId END DESC
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