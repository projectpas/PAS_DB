/*************************************************************                 
 ** File:   [GetPurchaseOrderList]                 
 ** Author:   Vishal Suthar        
 ** Description: Get Data for Purchase Order listing      
 ** Purpose:               
 ** Date:         
                
 ** PARAMETERS:                 
               
 ** RETURN VALUE:                 
        
 **************************************************************                 
 ** Change History                 
 **************************************************************                 
 ** SN   Date           Author			Change Description                  
 ** --   --------		-------------		--------------------------------                
    01  03-July-2023	Vishal Suthar		Removed script of "MULTIPLE" hover over      
    02  23-July-2024	Vishal Suthar		Removed Transaction from the SP
	03	29-Oct-2024		Abhishek Jirawla	Adding extra data so that we can remove unnecessary data
           
-- EXEC GetPurchaseOrderList @PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,@StatusID=1,@Status=N'Open',@GlobalFilter=N'',@PurchaseOrderNumber=NULL,@OpenDate=NULL,@VendorName=NULL,@RequestedBy=NULL,@ApprovedBy=NULL,@CreatedBy=NULL,@CreatedDate=
  
    
NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@EmployeeId=98,@MasterCompanyId=11,@VendorId=NULL,@ViewType=N'poview',@PartNumberType=NULL,@EstDeliveryType=NULL,@ManufacturerType=NULL,@SalesOrderNumberType=NULL,@WorkOrderNumType=NULL,@RepairOrderNumbe
  
rType=NULL,@QuantityOrdered=NULL,@QuantityBackOrdered=NULL,@QuantityReceived=NULL      
**************************************************************/      
CREATE PROCEDURE [dbo].[GetPurchaseOrderList]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@StatusID int = 1,
	@Status varchar(50) = 'Open',
	@GlobalFilter varchar(50) = '',
	@PurchaseOrderNumber varchar(50) = NULL, 
	@OpenDate  datetime = NULL,
	@VendorName varchar(50) = NULL,
	@RequestedBy varchar(50) = NULL,
	@ApprovedBy varchar(50) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy  varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@IsDeleted bit = 0,
	@EmployeeId bigint=61,
	@MasterCompanyId bigint=1,
	@VendorId bigint =null,
	@ViewType varchar(50) =null,
	@PartNumberType varchar(50)=null,
	@EstDeliveryType varchar(50)=null,
	@ManufacturerType varchar(50)=null,
	@SalesOrderNumberType varchar(50)=null,
	@WorkOrderNumType varchar(50)=null,
	@RepairOrderNumberType varchar(50)=null,
	@QuantityOrdered varchar(50)= null,
	@QuantityBackOrdered varchar(50)= null,
	@QuantityReceived varchar(50)= null      
AS      
BEGIN      
	SET NOCOUNT ON;      
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED       
	DECLARE @RecordFrom int;      
	DECLARE @IsActive bit=1      
	DECLARE @Count Int;      
	DECLARE @MSModuleID INT = 4; -- Employee Management Structure Module ID      
	SET @RecordFrom = (@PageNumber-1)*@PageSize;      
      
	IF @IsDeleted IS NULL      
	BEGIN      
	SET @IsDeleted=0      
	END      
	IF @SortColumn IS NULL      
	BEGIN      
	SET @SortColumn=Upper('PurchaseOrderId')      
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
		BEGIN       
			IF(@ViewType = 'poview')      
			BEGIN      
				;WITH Result AS(               
				SELECT DISTINCT PO.PurchaseOrderId,
					PO.PurchaseOrderNumber,
					PO.PurchaseOrderNumber AS PurchaseOrderNo,
					PO.OpenDate,
					PO.ClosedDate,
					PO.CreatedDate,
					PO.CreatedBy,
					PO.UpdatedDate,
					PO.UpdatedBy,
					PO.IsActive,
					PO.IsDeleted,
					PO.StatusId,
					PO.VendorId,
					PO.VendorName,
					PO.VendorCode,  
					PO.[Status],
					PO.Requisitioner AS RequestedBy,
					PO.ApprovedBy,
					SUM(ISNULL(POP.QuantityOrdered,0)) AS QuantityOrdered,
					SUM(ISNULL(POP.QuantityBackOrdered,0)) AS QuantityBackOrdered,
					SUM(ISNULL(POP.QuantityBackOrdered,0)) - SUM(ISNULL(POP.QuantityOrdered,0)) AS QuantityReceived,
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(POP.PartNumber) End) as 'PartNumberType',
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 THEN 'Multiple' ELSE MAX(POP.Manufacturer) END) AS 'ManufacturerType',  					
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 AND COUNT(POP.WorkOrderId) > 1 THEN 'Multiple' ELse MAX(POP.WorkOrderNo) End)  as 'WorkOrderNumType', 
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 AND COUNT(POP.SalesOrderId) > 1 THEN 'Multiple' ELse MAX(POP.SalesOrderNo) End)  as 'SalesOrderNumberType', 
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 AND COUNT(POP.RepairOrderId) > 1 THEN 'Multiple' ELse MAX(POP.ReapairOrderNo) End)  as 'RepairOrderNumberType', 
					POP.ReapairOrderNo AS 'RepairOrderNumber',
					POP.WorkOrderNo AS 'WorkOrderNum',
					POP.SalesOrderNo AS 'SalesOrderNumber',
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(CAST(CONVERT(VARCHAR, POP.EstDeliveryDate, 101) AS VARCHAR(MAX))) END) AS 'EstDeliveryType'--,
				FROM [dbo].[PurchaseOrder] PO WITH (NOLOCK)    
					LEFT JOIN  [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1   
				WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID))      
				AND PO.MasterCompanyId = @MasterCompanyId      
				GROUP BY PO.PurchaseOrderId, PO.PurchaseOrderNumber,
					PO.PurchaseOrderNumber,
					PO.OpenDate,
					PO.ClosedDate,
					PO.CreatedDate,
					PO.CreatedBy,
					PO.UpdatedDate,
					PO.UpdatedBy,
					PO.IsActive,
					PO.IsDeleted,
					PO.StatusId,
					PO.VendorId,
					PO.VendorName,
					PO.VendorCode,  
					PO.[Status],
					PO.Requisitioner,
					PO.ApprovedBy,
					POP.ReapairOrderNo,
					POP.WorkOrderNo,
					POP.SalesOrderNo
				)   
	,ResultData AS(      
		SELECT M.PurchaseOrderId,M.PurchaseOrderNumber,M.PurchaseOrderNo,M.OpenDate as 'OpenDate',M.ClosedDate as 'ClosedDate',M.CreatedDate,
			M.CreatedBy, M.UpdatedDate, M.UpdatedBy, M.IsActive, M.IsDeleted,
			M.StatusId, M.VendorId, M.VendorName, M.VendorCode, M.[Status], M.RequestedBy, M.ApprovedBy,
			M.SalesOrderNumberType,
			M.PartNumberType,
			M.ManufacturerType, 
			M.WorkOrderNumType,
			M.RepairOrderNumberType, 
			M.RepairOrderNumber,
			M.WorkOrderNum,
			M.SalesOrderNumber,
			CAST(M.EstDeliveryType AS VARCHAR(MAX)) as 'EstDeliveryType',
			0 as PurchaseOrderPartRecordId      
			,M.QuantityOrdered,M.QuantityBackOrdered,M.QuantityReceived      
		FROM Result M    
		WHERE ((@GlobalFilter <>'' AND ((PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR      
			(CreatedBy LIKE '%' +@GlobalFilter+'%') OR      
			(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR       
			(VendorName LIKE '%' +@GlobalFilter+'%') OR        
			(RequestedBy LIKE '%' +@GlobalFilter+'%') OR      
			(ApprovedBy LIKE '%' +@GlobalFilter+'%') OR           
			([Status]  LIKE '%' +@GlobalFilter+'%') OR      
			(M.PartNumberType like '%' +@GlobalFilter+'%') OR      
			(M.ManufacturerType like '%' +@GlobalFilter+'%') OR      
			(M.SalesOrderNumberType like '%' +@GlobalFilter+'%') OR      
			(M.WorkOrderNumType like '%' +@GlobalFilter+'%') OR      
			(M.RepairOrderNumberType like '%' +@GlobalFilter+'%') OR      
			(CAST(QuantityOrdered AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR      
			(CAST(QuantityBackOrdered AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR       
			(CAST(QuantityReceived AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%')))      
		OR         
			(@GlobalFilter = '' AND (ISNULL(@PurchaseOrderNumber,'') = '' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber +'%') AND       
			(ISNULL(@CreatedBy, '') = '' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND      
			(ISNULL(@UpdatedBy, '') = '' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND      
			(ISNULL(@ApprovedBy, '') = '' OR ApprovedBy LIKE '%' + @ApprovedBy + '%') AND      
			(ISNULL(@VendorName, '') = '' OR VendorName LIKE '%' + @VendorName + '%') AND      
			(ISNULL(@RequestedBy, '') = '' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND      
			(ISNULL(@Status, '') = '' OR Status LIKE '%' + @Status + '%') AND               
			(ISNULL(@OpenDate, '') = '' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND               
			(ISNULL(@CreatedDate, '') = '' OR CAST(CreatedDate AS Date) = CAST(@CreatedDate AS date)) AND      
			(ISNULL(@UpdatedDate, '') = '' OR CAST(UpdatedDate AS date) = CAST(@UpdatedDate AS date)) AND      
			(IsNull(@PartNumberType, '') = '' OR M.PartNumberType like '%'+ @PartNumberType +'%') and      
			(ISNULL(@EstDeliveryType, '') = '' OR M.EstDeliveryType like '%'+ @EstDeliveryType +'%') AND      
			(IsNull(@ManufacturerType, '') = '' OR M.ManufacturerType like '%'+ @ManufacturerType +'%') and      
			(IsNull(@SalesOrderNumberType, '') = '' OR M.SalesOrderNumberType like '%'+ @SalesOrderNumberType +'%') and      
			(IsNull(@WorkOrderNumType, '') = '' OR M.WorkOrderNumType like '%'+ @WorkOrderNumType +'%') and      
			(IsNull(@RepairOrderNumberType, '') = '' OR M.RepairOrderNumberType like '%'+ @RepairOrderNumberType +'%') and      
			(IsNull(@QuantityOrdered, '') = '' OR CAST(QuantityOrdered as NVARCHAR(10)) like '%'+ @QuantityOrdered +'%') AND       
			(IsNull(@QuantityBackOrdered, '') = '' OR CAST(QuantityBackOrdered as NVARCHAR(10)) like '%'+ @QuantityBackOrdered +'%') AND       
			(IsNull(@QuantityReceived, '') = '' OR CAST(QuantityReceived as NVARCHAR(10)) like '%'+ @QuantityReceived +'%'))      
			)      
			), CTE_Count AS (Select COUNT(PurchaseOrderId) AS NumberOfItems FROM ResultData)      
      
			SELECT PurchaseOrderId,PurchaseOrderNumber,PurchaseOrderNo,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,UpdatedBy,IsActive,IsDeleted      
			,StatusId,VendorId,VendorName,VendorCode,[Status],RequestedBy,ApprovedBy,'' PartNumber,PartNumberType,'' Manufacturer,ManufacturerType,WorkOrderNumType,SalesOrderNumberType,RepairOrderNumberType, RepairOrderNumber , SalesOrderNumber,WorkOrderNum,
      
			CreatedDate,UpdatedDate,NumberOfItems,CreatedBy,UpdatedBy, '' EstDeliveryDate,EstDeliveryType,PurchaseOrderPartRecordId,QuantityOrdered,QuantityBackOrdered,QuantityReceived FROM ResultData,CTE_Count      
		ORDER BY      
         
			CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderId')  THEN PurchaseOrderId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderId')  THEN PurchaseOrderId END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RequestedBy')  THEN RequestedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RequestedBy')  THEN RequestedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ApprovedBy')  THEN ApprovedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ApprovedBy')  THEN ApprovedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='REPAIRORDERNUMBERTYPE')  THEN RepairOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='REPAIRORDERNUMBERTYPE')  THEN RepairOrderNumberType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='status')  THEN status END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='status')  THEN status END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='quantityOrdered')  THEN quantityOrdered END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityOrdered')  THEN quantityOrdered END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='quantityReceived')  THEN quantityReceived END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityReceived')  THEN quantityReceived END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='quantityBackOrdered')  THEN quantityBackOrdered END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityBackOrdered')  THEN quantityBackOrdered END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='workOrderNumType')  THEN workOrderNumType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='workOrderNumType')  THEN workOrderNumType END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='repairOrderNumberType')  THEN repairOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='repairOrderNumberType')  THEN repairOrderNumberType END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='approvedBy')  THEN approvedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='approvedBy')  THEN approvedBy END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='estDeliveryType')  THEN estDeliveryType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='estDeliveryType')  THEN estDeliveryType END DESC 

		OFFSET @RecordFrom ROWS       
		FETCH NEXT @PageSize ROWS ONLY      
	END      
	ELSE      
	BEGIN      
	  ;WITH Result AS(               
		SELECT DISTINCT PO.PurchaseOrderId,
			PO.PurchaseOrderNumber,
			PO.PurchaseOrderNumber AS PurchaseOrderNo,
			PO.OpenDate,
			PO.ClosedDate,
			PO.CreatedDate,
			PO.CreatedBy,
			PO.UpdatedDate,
			PO.UpdatedBy,
			PO.IsActive,
			PO.IsDeleted,
			PO.StatusId,
			PO.VendorId,
			PO.VendorName,
			PO.VendorCode,  
			PO.[Status],
			PO.Requisitioner AS RequestedBy,
			PO.ApprovedBy,
			POP.PartNumber,
			POP.PartNumber as PartNumberType,
			--M.[Name] AS Manufacturer,
			--M.[Name] AS ManufacturerType, 
			POP.Manufacturer AS Manufacturer,
			POP.Manufacturer AS ManufacturerType,
			POP.SalesOrderNo AS SalesOrderNumber,
			POP.SalesOrderNo as SalesOrderNumberType,
			POP.WorkOrderNo AS WorkOrderNum,
			POP.WorkOrderNo as WorkOrderNumType,
			POP.ReapairOrderNo AS RepairOrderNumber,
			POP.ReapairOrderNo as RepairOrderNumberType,
			CAST(POP.EstDeliveryDate AS VARCHAR(MAX)) as EstDeliveryDateMulti,
			CAST(POP.EstDeliveryDate AS VARCHAR(MAX)) as EstDeliveryType,
			POP.PurchaseOrderPartRecordId,
			ISNULL(POP.QuantityOrdered,0) AS QuantityOrdered,
			ISNULL(POP.QuantityBackOrdered,0) AS QuantityBackOrdered,
			ISNULL(POP.QuantityOrdered,0) - ISNULL(POP.QuantityBackOrdered,0) AS QuantityReceived      
		FROM  [dbo].[PurchaseOrder] PO WITH (NOLOCK)      
			LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1      
		WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID)) AND PO.MasterCompanyId = @MasterCompanyId           
		
		), ResultCount AS(
	  
		Select COUNT(PurchaseOrderId) AS totalItems FROM Result)      
			SELECT * INTO #TempResult FROM  Result      
			WHERE ((@GlobalFilter <>'' AND ((PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR      
				(CreatedBy LIKE '%' +@GlobalFilter+'%') OR      
				(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR       
				(VendorName LIKE '%' +@GlobalFilter+'%') OR        
				(RequestedBy LIKE '%' +@GlobalFilter+'%') OR      
				(ApprovedBy LIKE '%' +@GlobalFilter+'%') OR           
				([Status]  LIKE '%' +@GlobalFilter+'%') OR      
				(PartNumber LIKE '%' +@GlobalFilter+'%') OR      
				(Manufacturer LIKE '%' +@GlobalFilter+'%') OR      
				(SalesOrderNumberType LIKE '%' +@GlobalFilter+'%') OR      
				(WorkOrderNumType LIKE '%' +@GlobalFilter+'%') OR      
				(RepairOrderNumberType LIKE '%' +@GlobalFilter+'%') OR      
				(CAST(QuantityOrdered AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR      
				(CAST(QuantityBackOrdered AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR       
				(CAST(QuantityReceived AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%')))      
			OR         
				(@GlobalFilter='' AND (ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber+'%') AND       
				(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND      
				(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND      
				(ISNULL(@ApprovedBy,'') ='' OR ApprovedBy LIKE '%' + @ApprovedBy + '%') AND      
				(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND      
				(ISNULL(@RequestedBy,'') ='' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND      
				(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND               
				(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND               
				(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND      
				(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND      
				(ISNULL(@PartNumberType,'') ='' OR PartNumber like '%'+ @PartNumberType+'%') AND      
				(ISNULL(@EstDeliveryType,'') ='' OR EstDeliveryDateMulti like '%'+ @EstDeliveryType+'%') and      
				(ISNULL(@ManufacturerType,'') ='' OR Manufacturer like '%'+ @ManufacturerType +'%') AND      
				(ISNULL(@SalesOrderNumberType,'') ='' OR SalesOrderNumberType like '%'+@SalesOrderNumberType+'%') AND      
				(ISNULL(@WorkOrderNumType,'') ='' OR WorkOrderNumType like '%'+@WorkOrderNumType+'%') AND      
				(ISNULL(@RepairOrderNumberType,'') ='' OR RepairOrderNumberType like '%'+@RepairOrderNumberType+'%') AND      
				(ISNULL(@QuantityOrdered,'') ='' OR CAST(QuantityOrdered as NVARCHAR(10)) like '%'+ @QuantityOrdered+'%') AND       
				(ISNULL(@QuantityBackOrdered,'') ='' OR CAST(QuantityBackOrdered as NVARCHAR(10)) like '%'+@QuantityBackOrdered+'%') AND       
				(ISNULL(@QuantityReceived,'') ='' OR CAST(QuantityReceived as NVARCHAR(10)) like '%'+@QuantityReceived+'%'))      
			)      
      
	  SELECT @Count = COUNT(PurchaseOrderId) FROM #TempResult      
      
	  SELECT *, @Count AS NumberOfItems FROM #TempResult      
	  ORDER BY        
	  CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderId')  THEN PurchaseOrderId END ASC,
      CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderId')  THEN PurchaseOrderId END DESC, 
	  CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='RequestedBy')  THEN RequestedBy END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='RequestedBy')  THEN RequestedBy END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='ApprovedBy')  THEN ApprovedBy END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='ApprovedBy')  THEN ApprovedBy END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END DESC,  
	  CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='REPAIRORDERNUMBERTYPE')  THEN RepairOrderNumberType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='REPAIRORDERNUMBERTYPE')  THEN RepairOrderNumberType END DESC      
	  OFFSET @RecordFrom ROWS       
	  FETCH NEXT @PageSize ROWS ONLY      
 END      
 END           
 END TRY          
 BEGIN CATCH         
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
            , @AdhocComments     VARCHAR(150)    = 'GetPublicationViewList'       
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderNumber, '') + ''      
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