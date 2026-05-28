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
	04	14-Nov-2024		Vishal Suthar		Fixed the Quantity Received Issue
 	05	15-Jan-2025		RAJESH GAMI		    Fixed to multiple records display while select on POVIEW     
	06	15-Jan-2025		Hemant Saliya		Resolved Duplicate issue
	07	16-Jan-2025		Bhargav Saliya		Resolved Purchase Order count issue
	08	21-Jan-2025		Bhargav Saliya		When we attached WO with PO Part That time select Multiple/WO Number
	09  23-Jan-2025		Bhargav Saliya		Resolved Shorting issue
	10	31-Jan-2025		Hemant Saliya		Resolved WO number Display issue
	11  26-02-2025      Shrey Chandegara    Modified due to datetime issue.
	12  06-03-2025      Shrey Chandegara     Modified due to add view in Accouting Integration List's PendingSync(Add @IsUpdated parameter)
	13  18-03-2025      Ekta Chandegara     Add @PartDescription parameter and retrieve PartDescription column value
	14   07-04-2025     Shrey Chandegara    Modified due to PN-12013
	15  10-04-2025      Moin Bloch          Modified change logic for QuantityReceived
	16  02-12-2025      Sahdev Saliya       Added New Field :- Priority
	17  04/12/2025		RAJESH GAMI			ADDED: @CustomerRFQNo and functionality while getting the list
	18  08-12-2025      Sahdev Saliya       Added New Field :- VendorRFQPurchaseOrderNumber
	19  01-20-2026      Vishal Suthar       Added filter to skip migrated PO from the listing for PAR
	20  05-14-2026      Bhargav Saliya      Remove The [VendoreId] Condition [PN-16416]
	21  28-05-2026      Ayushi Patel        [PN-16427]Fixed bigint casting issue for quantity sorting columns
**************************************************************/      
CREATE    PROCEDURE [dbo].[GetPurchaseOrderList]
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
	@PartDescription nvarchar(MAX),
	@EstDeliveryType varchar(50)=null,
	@ManufacturerType varchar(50)=null,
	@SalesOrderNumberType varchar(50)=null,
	@WorkOrderNumType varchar(50)=null,
	@RepairOrderNumberType varchar(50)=null,
	@QuantityOrdered varchar(50)= null,
	@QuantityBackOrdered varchar(50)= null,
	@QuantityReceived varchar(50)= null,
	@IsUpdated BIT = NULL,  
    @Priority varchar(100) = NULL,
	@CustomerRFQNo varchar(400)=NULL,
    @VendorRFQPurchaseOrderNumber varchar(50) = NULL     
AS      
BEGIN      
	SET NOCOUNT ON;       
	DECLARE @RecordFrom int;      
	DECLARE @IsActive bit=1      
	DECLARE @Count Int;      
	DECLARE @MSModuleID INT = 4; -- Employee Management Structure Module ID     
	DECLARE @poModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) Where ModuleName = 'PurchaseOrder' AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0 )
	
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
	
	DECLARE @POMSModuleID INT = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WHERE ModuleName = 'POHeader');  
	IF OBJECT_ID(N'tempdb..#tmpPurchaseOrderUserRole') IS NOT NULL    
	BEGIN    
		DROP TABLE #tmpPurchaseOrderUserRole
	END

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
		
	SELECT * INTO #tmpPurchaseOrderUserRole FROM (SELECT DISTINCT MSD.[ReferenceID],RMS.[EntityStructureId] 
	FROM [dbo].PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK)
		INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.[EntityMsId] = RMS.[EntityStructureId]
		INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.[RoleId] = RMS.[RoleId]
	WHERE MSD.[ModuleID] = @POMSModuleID AND EUR.[EmployeeId] = @EmployeeId) AS PurchaseOrderUserRole


	IF OBJECT_ID('tempdb..#TempPurchaseOrders') IS NOT NULL
    DROP TABLE #TempPurchaseOrders;

	CREATE TABLE #TempPurchaseOrders (
		[PurchaseOrderId] INT,
		[PurchaseOrderNumber] NVARCHAR(50),
		[PurchaseOrderNo] NVARCHAR(50),
		[OpenDate] DATETIME,
		[ClosedDate] DATETIME,
		[CreatedDate] DATETIME,
		[CreatedBy] NVARCHAR(256),
		[UpdatedDate] DATETIME,
		[UpdatedBy] NVARCHAR(256),
		[IsActive] BIT,
		[IsDeleted] BIT,
		[StatusId] INT,
		[VendorId] INT,
		[VendorName] NVARCHAR(100),
		[VendorCode] NVARCHAR(100),
		[Status] NVARCHAR(100),
		[RequestedBy] NVARCHAR(100),
		[ApprovedBy] NVARCHAR(100),
		[QuantityOrdered] DECIMAL(18,6),
		[QuantityBackOrdered] DECIMAL(18,6),
		[QuantityReceived] DECIMAL(18,6),
		[PartNumberType] NVARCHAR(250),
		[PartDescription] NVARCHAR(MAX),
		[ManufacturerType] NVARCHAR(250),
		[WorkOrderNumType] NVARCHAR(250),
		[SalesOrderNumberType] NVARCHAR(250),
		[RepairOrderNumberType] NVARCHAR(250),
		[WorkOrderNum] NVARCHAR(250),
		[SalesOrderNumber] NVARCHAR(250),
		[RepairOrderNumber] NVARCHAR(250),
		[EstDeliveryType] NVARCHAR(MAX),
		[Priority] varchar(100),
		[CustomerRFQNo] varchar(400),
	    [VendorRFQPurchaseOrderNumber] varchar(50)      
	);
        
	BEGIN TRY      
		BEGIN       
			IF(@ViewType = 'poview')      
			BEGIN     
			

			INSERT INTO #TempPurchaseOrders ([PurchaseOrderId],[PurchaseOrderNumber],[PurchaseOrderNo],[OpenDate],[ClosedDate],[CreatedDate],[CreatedBy],[UpdatedDate],[UpdatedBy],
								[IsActive],[IsDeleted],[StatusId],[VendorId],[VendorName],[VendorCode],[Status],[RequestedBy],[ApprovedBy],[QuantityOrdered],[QuantityBackOrdered],
								[QuantityReceived],[PartNumberType],[PartDescription],[ManufacturerType],[WorkOrderNumType],[SalesOrderNumberType],[RepairOrderNumberType],[WorkOrderNum],
								[SalesOrderNumber],[RepairOrderNumber],[EstDeliveryType],[Priority],[CustomerRFQNo],[VendorRFQPurchaseOrderNumber])				              
				SELECT DISTINCT PO.PurchaseOrderId,
					PO.PurchaseOrderNumber,
					PO.PurchaseOrderNumber AS PurchaseOrderNo,
					PO.OpenDate,
					PO.ClosedDate,
					(Cast(DBO.ConvertUTCtoLocal(PO.CreatedDate, @CurrntEmpTimeZoneDesc) as Date)) CreatedDate,
					PO.CreatedBy,
					(Cast(DBO.ConvertUTCtoLocal(PO.UpdatedDate, @CurrntEmpTimeZoneDesc) as Date)) UpdatedDate,
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
					CAST(SUM(ISNULL(POP.QuantityOrdered,0)) AS VARCHAR(100)) AS [QuantityOrdered],
					--CAST(SUM(ISNULL(POP.QuantityBackOrdered,0)) AS varchar(100)) AS [QuantityBackOrdered],
					SUM(POP.[QuantityOrdered]) - ISNULL(SUM(POP.[QuantityReceived]),0) [QuantityBackOrdered],					
					--SUM(ISNULL(POP.QuantityOrdered,0)) - SUM(ISNULL(POP.QuantityBackOrdered,0)) AS [QuantityReceived],					
					ISNULL(SUM(POP.[QuantityReceived]),0) [QuantityReceived],					
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(POP.PartNumber) End) as 'PartNumberType',
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(POP.PartDescription) End) as 'PartDescription',
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 THEN 'Multiple' ELSE MAX(POP.Manufacturer) END) AS 'ManufacturerType',  
					'' WorkOrderNumType,
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 AND COUNT(POP.SalesOrderId) > 1 THEN 'Multiple' ELse MAX(POP.SalesOrderNo) End)  as 'SalesOrderNumberType', 
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 AND COUNT(POP.RepairOrderId) > 1 THEN 'Multiple' ELse MAX(POP.ReapairOrderNo) End)  as 'RepairOrderNumberType', 
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 AND COUNT(ISNULL(POP.WorkOrderId, 0)) > 1 THEN 'Multiple' ELse MAX(POP.WorkOrderNo) End)  as 'WorkOrderNum', 
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 AND COUNT(ISNULL(POP.SalesOrderId, 0)) > 1 THEN 'Multiple' ELse MAX(POP.SalesOrderNo) End)  as 'SalesOrderNumber', 
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 AND COUNT(POP.RepairOrderId) > 1 THEN 'Multiple' ELse MAX(POP.ReapairOrderNo) End)  as 'RepairOrderNumber', 
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(CAST(CONVERT(VARCHAR, POP.EstDeliveryDate, 101) AS VARCHAR(MAX))) END) AS 'EstDeliveryType',
					(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 THEN 'Multiple' ELSE MAX(POP.[Priority]) END) AS 'Priority', 
					ISNULL(rfqData.CustomerRFQNo,'-') AS CustomerRFQNo,
			        VRPO.VendorRFQPurchaseOrderNumber
				FROM [dbo].[PurchaseOrder] PO WITH (NOLOCK)    
				LEFT JOIN  [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1  
				OUTER APPLY (SELECT TOP 1 rfq.RfqId CustomerRFQNo FROM DBO.VendorRFQPart rfqPart WITH(NOLOCK) 
					INNER JOIN DBO.ILSRFQPart ilsPart WITH(NOLOCK) ON rfqPart.ILSRFQDetailId = ilsPart.ILSRFQDetailId 
					INNER JOIN DBO.CustomerRfq rfq WITH(NOLOCK) ON ilsPart.CustomerRfqId = rfq.CustomerRfqId
					WHERE rfqPart.ModuleId = @poModuleId AND rfqPart.ReferenceId = PO.PurchaseOrderId) rfqData
				LEFT JOIN  [dbo].[VendorRFQPurchaseOrder] VRPO WITH (NOLOCK) ON VRPO.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId
				WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID))      
				AND PO.MasterCompanyId = @MasterCompanyId AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(PO.IsUpdated,0) = ISNULL(@IsUpdated,0))   
				--AND (@VendorId IS NULL OR PO.VendorId = @VendorId)
				AND (PO.Notes <> 'PARMigrate' AND PO.CreatedBy <> 'TBD')
				GROUP BY PO.PurchaseOrderId, 				   
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
					PO.ApprovedBy,rfqData.CustomerRFQNo,
					VRPO.VendorRFQPurchaseOrderNumber
	
	UPDATE TMP
	SET TMP.WorkOrderNumType = WODATA.WorkOrderNumType
	FROM #TempPurchaseOrders TMP
	OUTER APPLY (
		SELECT  
			CASE WHEN COUNT(DISTINCT PORW.ReferenceId) > 1 AND PORW.ModuleId = 1 THEN 'Multiple' ELSE MAX(WON.WorkOrderNum) end  AS 'WorkOrderNumType'
		FROM 
		[dbo].[PurchaseOrderPart] POPW WITH (NOLOCK) 
		LEFT JOIN [dbo].[PurchaseOrderPartReference] PORW  WITH (NOLOCK) ON POPW.PurchaseOrderPartRecordId = PORW.PurchaseOrderPartId AND POPW.PurchaseOrderId = PORW.PurchaseOrderId
		LEFT JOIN [dbo].WorkOrder WON WITH (NOLOCK) ON PORW.ReferenceId = WON.WorkOrderId
		WHERE	POPW.PurchaseOrderPartRecordId = PORW.PurchaseOrderPartId AND POPW.PurchaseOrderId = PORW.PurchaseOrderId
				AND POPW.isParent=1  AND TMP.PurchaseOrderId = POPW.PurchaseOrderId AND PORW.ModuleId = 1 -- FOR WO Module
				GROUP BY PORW.ModuleId
		) AS WODATA
	
	;WITH ResultData AS(      
		SELECT M.PurchaseOrderId,M.PurchaseOrderNumber,M.PurchaseOrderNo,M.OpenDate as 'OpenDate',M.ClosedDate as 'ClosedDate',M.CreatedDate,
			M.CreatedBy, M.UpdatedDate, M.UpdatedBy, M.IsActive, M.IsDeleted,
			M.StatusId, M.VendorId, M.VendorName, M.VendorCode, M.[Status], M.RequestedBy, M.ApprovedBy,
			M.SalesOrderNumberType,
			M.PartNumberType,
			M.PartDescription,
			M.ManufacturerType, 
			M.WorkOrderNumType,
			M.RepairOrderNumberType, 
			M.RepairOrderNumber,
			M.WorkOrderNum,
			M.SalesOrderNumber,
			CAST(M.EstDeliveryType AS VARCHAR(MAX)) as 'EstDeliveryType',
			0 as PurchaseOrderPartRecordId      
			,M.QuantityOrdered,M.QuantityBackOrdered,M.QuantityReceived ,
			M.[Priority],M.CustomerRFQNo,
			M.VendorRFQPurchaseOrderNumber
		FROM #TempPurchaseOrders M    
		WHERE ((@GlobalFilter <>'' AND ((PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR      
			(CreatedBy LIKE '%' +@GlobalFilter+'%') OR      
			(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR       
			(VendorName LIKE '%' +@GlobalFilter+'%') OR        
			(RequestedBy LIKE '%' +@GlobalFilter+'%') OR      
			(ApprovedBy LIKE '%' +@GlobalFilter+'%') OR           
			([Status]  LIKE '%' +@GlobalFilter+'%') OR
			(M.CustomerRFQNo like '%' +@GlobalFilter+'%') OR    
			(M.PartNumberType like '%' +@GlobalFilter+'%') OR      
			(M.PartDescription like '%' +@GlobalFilter+'%') OR      
			(M.ManufacturerType like '%' +@GlobalFilter+'%') OR      
			(M.SalesOrderNumberType like '%' +@GlobalFilter+'%') OR      
			(M.WorkOrderNumType like '%' +@GlobalFilter+'%') OR      
			(M.RepairOrderNumberType like '%' +@GlobalFilter+'%') OR      
			(CAST(QuantityOrdered AS NVARCHAR(100)) LIKE '%' +@GlobalFilter+'%') OR      
			(CAST(QuantityBackOrdered AS NVARCHAR(100)) LIKE '%' +@GlobalFilter+'%') OR       
			(CAST(QuantityReceived AS NVARCHAR(100)) LIKE '%' +@GlobalFilter+'%') OR 
			([Priority]  LIKE '%' +@GlobalFilter+'%') OR
			(VendorRFQPurchaseOrderNumber  LIKE '%' +@GlobalFilter+'%')))    
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
			(IsNull(@PartDescription, '') = '' OR M.PartDescription like '%'+ @PartDescription +'%') and   
			(IsNull(@CustomerRFQNo, '') = '' OR M.CustomerRFQNo like '%'+ @CustomerRFQNo +'%') and   		
			(ISNULL(@EstDeliveryType, '') = '' OR M.EstDeliveryType like '%'+ @EstDeliveryType +'%') AND      
			(IsNull(@ManufacturerType, '') = '' OR M.ManufacturerType like '%'+ @ManufacturerType +'%') and      
			(IsNull(@SalesOrderNumberType, '') = '' OR M.SalesOrderNumberType like '%'+ @SalesOrderNumberType +'%') and      
			(IsNull(@WorkOrderNumType, '') = '' OR M.WorkOrderNumType like '%'+ @WorkOrderNumType +'%') and      
			(IsNull(@RepairOrderNumberType, '') = '' OR M.RepairOrderNumberType like '%'+ @RepairOrderNumberType +'%') and      
			(IsNull(@QuantityOrdered, '') = '' OR CAST(QuantityOrdered as NVARCHAR(100)) like '%'+ @QuantityOrdered +'%') AND       
			(IsNull(@QuantityBackOrdered, '') = '' OR CAST(QuantityBackOrdered as NVARCHAR(100)) like '%'+ @QuantityBackOrdered +'%') AND       
			(IsNull(@QuantityReceived, '') = '' OR CAST(QuantityReceived as NVARCHAR(100)) like '%'+ @QuantityReceived +'%') AND
			(ISNULL(@Priority,'') ='' OR Priority LIKE '%' + @Priority + '%') AND
		    (ISNULL(@VendorRFQPurchaseOrderNumber,'') ='' OR VendorRFQPurchaseOrderNumber LIKE '%' + @VendorRFQPurchaseOrderNumber + '%')))      
			), CTE_Count AS (Select COUNT(PurchaseOrderId) AS NumberOfItems FROM ResultData)      
      
			SELECT PurchaseOrderId,PurchaseOrderNumber,PurchaseOrderNo,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,UpdatedBy,IsActive,IsDeleted      
			,StatusId,VendorId,VendorName,VendorCode,[Status],RequestedBy,ApprovedBy,'' PartNumber,PartNumberType,PartDescription,'' Manufacturer,ManufacturerType,WorkOrderNumType,SalesOrderNumberType,RepairOrderNumberType, RepairOrderNumber , SalesOrderNumber,WorkOrderNum,
      
			CreatedDate,UpdatedDate,NumberOfItems,CreatedBy,UpdatedBy, '' EstDeliveryDate,EstDeliveryType,PurchaseOrderPartRecordId,QuantityOrdered,QuantityBackOrdered,QuantityReceived,[Priority],CustomerRFQNo,VendorRFQPurchaseOrderNumber FROM ResultData,CTE_Count      
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
			CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='quantityOrdered')  THEN cast(quantityOrdered as bigint) END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityOrdered')  THEN cast(quantityOrdered as bigint) END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='quantityReceived')  THEN cast(quantityReceived as bigint) END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityReceived')  THEN cast(quantityReceived as bigint) END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='quantityBackOrdered')  THEN cast(quantityBackOrdered as bigint) END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityBackOrdered')  THEN cast(quantityBackOrdered as bigint) END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='workOrderNumType')  THEN workOrderNumType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='workOrderNumType')  THEN workOrderNumType END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='repairOrderNumberType')  THEN repairOrderNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='repairOrderNumberType')  THEN repairOrderNumberType END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='approvedBy')  THEN approvedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='approvedBy')  THEN approvedBy END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='estDeliveryType')  THEN estDeliveryType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='estDeliveryType')  THEN estDeliveryType END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN [Priority] END ASC,
	        CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN [Priority] END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CustomerRFQNo')  THEN CustomerRFQNo END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerRFQNo')  THEN CustomerRFQNo END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END ASC,
	        CASE WHEN (@SortOrder=-1 and @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END DESC

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
			(Cast(DBO.ConvertUTCtoLocal(PO.CreatedDate, @CurrntEmpTimeZoneDesc) as Date)) CreatedDate,
			PO.CreatedBy,
			(Cast(DBO.ConvertUTCtoLocal(PO.UpdatedDate, @CurrntEmpTimeZoneDesc) as Date)) UpdatedDate,
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
			POP.PartDescription,
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
			--ISNULL(POP.QuantityBackOrdered,0) AS QuantityBackOrdered,
			POP.[QuantityOrdered] - ISNULL(POP.[QuantityReceived],0) [QuantityBackOrdered],	
			--ISNULL(POP.QuantityOrdered,0) - ISNULL(POP.QuantityBackOrdered,0) AS QuantityReceived,  
			ISNULL(POP.[QuantityReceived],0) [QuantityReceived],
			POP.[Priority],
			ISNULL(rfqData.CustomerRFQNo,'-') as CustomerRFQNo,
		    VRPO.VendorRFQPurchaseOrderNumber 
		FROM  [dbo].[PurchaseOrder] PO WITH (NOLOCK)  
			INNER JOIN #tmpPurchaseOrderUserRole MSD WITH (NOLOCK) ON MSD.ReferenceID = PO.PurchaseOrderId
			LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1			
			OUTER APPLY ( SELECT TOP 1 rfq.RfqId CustomerRFQNo FROM dbo.PurchaseOrderPart part WITH(NOLOCK) 
					INNER JOIN DBO.VendorRFQPart rfqPart WITH(NOLOCK) ON part.PurchaseOrderId = rfqPart.ReferenceId AND rfqPart.ModuleId = @poModuleId 
					INNER JOIN DBO.ILSRFQPart ilsPart WITH(NOLOCK) ON rfqPart.ILSRFQDetailId = ilsPart.ILSRFQDetailId 
					INNER JOIN DBO.CustomerRfq rfq WITH(NOLOCK) ON ilsPart.CustomerRfqId = rfq.CustomerRfqId
					WHERE part.PurchaseOrderId =PO.PurchaseOrderId) rfqData
			LEFT JOIN  [dbo].[VendorRFQPurchaseOrder] VRPO WITH (NOLOCK) ON VRPO.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId

		WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID)) AND PO.MasterCompanyId = @MasterCompanyId    
				--AND (@VendorId IS NULL OR PO.VendorId = @VendorId)
		
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
				(PartDescription LIKE '%' +@GlobalFilter+'%') OR
				(CustomerRFQNo LIKE '%' +@GlobalFilter+'%') OR  
				(Manufacturer LIKE '%' +@GlobalFilter+'%') OR      
				(SalesOrderNumberType LIKE '%' +@GlobalFilter+'%') OR      
				(WorkOrderNumType LIKE '%' +@GlobalFilter+'%') OR      
				(RepairOrderNumberType LIKE '%' +@GlobalFilter+'%') OR      
				(CAST(QuantityOrdered AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR      
				(CAST(QuantityBackOrdered AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR       
				(CAST(QuantityReceived AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
				([Priority]  LIKE '%' +@GlobalFilter+'%') OR
				(VendorRFQPurchaseOrderNumber  LIKE '%' +@GlobalFilter+'%')))      
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
				(ISNULL(@PartDescription,'') ='' OR PartDescription like '%'+ @PartDescription+'%') AND 
				(ISNULL(@CustomerRFQNo,'') ='' OR CustomerRFQNo like '%'+ @CustomerRFQNo+'%') AND 
				(ISNULL(@EstDeliveryType,'') ='' OR EstDeliveryDateMulti like '%'+ @EstDeliveryType+'%') and      
				(ISNULL(@ManufacturerType,'') ='' OR Manufacturer like '%'+ @ManufacturerType +'%') AND      
				(ISNULL(@SalesOrderNumberType,'') ='' OR SalesOrderNumberType like '%'+@SalesOrderNumberType+'%') AND      
				(ISNULL(@WorkOrderNumType,'') ='' OR WorkOrderNumType like '%'+@WorkOrderNumType+'%') AND      
				(ISNULL(@RepairOrderNumberType,'') ='' OR RepairOrderNumberType like '%'+@RepairOrderNumberType+'%') AND      
				(ISNULL(@QuantityOrdered,'') ='' OR CAST(QuantityOrdered as NVARCHAR(10)) like '%'+ @QuantityOrdered+'%') AND       
				(ISNULL(@QuantityBackOrdered,'') ='' OR CAST(QuantityBackOrdered as NVARCHAR(10)) like '%'+@QuantityBackOrdered+'%') AND       
				(ISNULL(@QuantityReceived,'') ='' OR CAST(QuantityReceived as NVARCHAR(10)) like '%'+@QuantityReceived+'%') AND
				(ISNULL(@Priority,'') ='' OR Priority LIKE '%' + @Priority + '%') AND				
				(ISNULL(@VendorRFQPurchaseOrderNumber,'') ='' OR VendorRFQPurchaseOrderNumber LIKE '%' + @VendorRFQPurchaseOrderNumber + '%')))  
      
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
	   CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END DESC,  
	  CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBERTYPE')  THEN SalesOrderNumberType END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUMBERTYPE')  THEN WorkOrderNumType END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='REPAIRORDERNUMBERTYPE')  THEN RepairOrderNumberType END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='REPAIRORDERNUMBERTYPE')  THEN RepairOrderNumberType END DESC,
	  CASE WHEN (@SortOrder=1  AND @SortColumn='quantityOrdered')  THEN TRY_CAST(quantityOrdered as decimal(18,6)) END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityOrdered')  THEN TRY_CAST(quantityOrdered as decimal(18,6)) END DESC, 
	  CASE WHEN (@SortOrder=1  AND @SortColumn='quantityReceived')  THEN TRY_CAST(quantityReceived as decimal(18,6)) END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityReceived')  THEN TRY_CAST(quantityReceived as decimal(18,6)) END DESC, 
	  CASE WHEN (@SortOrder=1  AND @SortColumn='quantityBackOrdered')  THEN TRY_CAST(quantityBackOrdered as decimal(18,6)) END ASC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='quantityBackOrdered')  THEN TRY_CAST(quantityBackOrdered as decimal(18,6)) END DESC ,
	  CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITY')  THEN [Priority] END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITY')  THEN [Priority] END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='CustomerRFQNo')  THEN CustomerRFQNo END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerRFQNo')  THEN CustomerRFQNo END DESC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END DESC

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