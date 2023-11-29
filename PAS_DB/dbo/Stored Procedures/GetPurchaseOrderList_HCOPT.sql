/*
exec GetPurchaseOrderList @PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,@StatusID=1,@Status=N'Open',@GlobalFilter=N'',@PurchaseOrderNumber=NULL,@OpenDate=NULL,@VendorName=NULL,@RequestedBy=NULL,@ApprovedBy=NULL,@CreatedBy=NULL,@CreatedDate=NULL,@UpdatedBy=NULL,@UpdatedDate=NULL,@IsDeleted=0,@EmployeeId=98,@MasterCompanyId=11,@VendorId=NULL,@ViewType=N'poview',@PartNumberType=NULL,@EstDeliveryType=NULL,@ManufacturerType=NULL,@SalesOrderNumberType=NULL,@WorkOrderNumType=NULL,@RepairOrderNumberType=NULL,@QuantityOrdered=NULL,@QuantityBackOrdered=NULL,@QuantityReceived=NULL
*/
CREATE   PROCEDURE [dbo].GetPurchaseOrderList_HCOPT
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
		BEGIN TRANSACTION
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
					ISNULL(A.QuantityOrdered,0) AS QuantityOrdered,
					ISNULL(A.QuantityBackOrdered,0) AS QuantityBackOrdered,
					ISNULL(A.QuantityReceived,0) AS QuantityReceived
					--POP.EstDeliveryDate
			  FROM [dbo].[PurchaseOrder] PO WITH (NOLOCK)
			  INNER JOIN [dbo].[PurchaseOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			  INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			  INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
			  LEFT JOIN  [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1
			  OUTER APPLY(
				SELECT SUM(popt.QuantityOrdered) AS QuantityOrdered,
					SUM(popt.QuantityBackOrdered) AS QuantityBackOrdered,
					SUM(popt.QuantityOrdered) - SUM(popt.QuantityBackOrdered) AS QuantityReceived 
					FROM dbo.PurchaseOrderPart popt WITH (NOLOCK) WHERE popt.PurchaseOrderId = PO.PurchaseOrderId and popt.isParent=1 AND popt.MasterCompanyId = @MasterCompanyId
			  ) AS A
		 	  WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID))
				  AND PO.MasterCompanyId = @MasterCompanyId	
				  AND  (@VendorId  IS NULL OR PO.VendorId = @VendorId)
			)
			,
PartCTE AS(
						Select PO.PurchaseOrderId,(Case When Count(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',
						A.PartNumber 
						FROM DBO.PurchaseOrder PO WITH (NOLOCK)
						Left Join [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) On PO.PurchaseOrderId=POP.PurchaseOrderId --AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1 AND POP.MasterCompanyId = @MasterCompanyId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + P.partnumber
									  FROM DBO.PurchaseOrderPart P WITH (NOLOCK)
									  Where P.PurchaseOrderId = PO.PurchaseOrderId AND P.IsActive = 1 AND P.IsDeleted = 0 AND P.isParent = 1
									  AND P.MasterCompanyId = @MasterCompanyId
									  FOR XML PATH('')), 1, 1, '') PartNumber
						) A
						WHERE (PO.IsDeleted = @IsDeleted) Group By PO.PurchaseOrderId, A.PartNumber)
			,ManufacturerCTE AS(
						Select PO.PurchaseOrderId,(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 THEN 'Multiple' ELSE M.Manufacturer END) AS 'ManufacturerType',M.Manufacturer 
						FROM [dbo].[PurchaseOrder] PO WITH (NOLOCK)
						LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON PO.PurchaseOrderId=POP.PurchaseOrderId AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1 AND POP.MasterCompanyId = @MasterCompanyId
						OUTER APPLY(
							SELECT 
							   STUFF((SELECT ',' + M.[Name]
									  FROM [dbo].[PurchaseOrderPart] P WITH (NOLOCK)									  
									  LEFT JOIN [dbo].[Manufacturer] M WITH (NOLOCK) ON P.ManufacturerId = M.ManufacturerId AND M.MasterCompanyId = @MasterCompanyId
									  WHERE PO.PurchaseOrderId = P.PurchaseOrderId AND P.IsActive = 1 AND P.IsDeleted = 0 AND P.isParent = 1
									  AND P.MasterCompanyId = @MasterCompanyId
									  FOR XML PATH('')), 1, 1, '') Manufacturer								
						) M
						WHERE (PO.IsDeleted=@IsDeleted) GROUP BY PO.PurchaseOrderId,M.Manufacturer)
			,WOCTE AS(
						Select PO.PurchaseOrderId,(Case When Count(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse B.WorkOrderNum End)  as 'WorkOrderNumType',B.WorkOrderNum 
						from DBO.PurchaseOrder PO WITH (NOLOCK)
						Left Join DBO.PurchaseOrderPart POP WITH (NOLOCK) On PO.PurchaseOrderId=POP.PurchaseOrderId AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1 AND POP.MasterCompanyId = @MasterCompanyId
						INNER Join DBO.WorkOrder I WITH (NOLOCK) On POP.WorkOrderId=I.WorkOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.WorkOrderNum
									  FROM DBO.PurchaseOrderPart P WITH (NOLOCK)
									  Left Join DBO.WorkOrder I WITH (NOLOCK) On P.WorkOrderId = I.WorkOrderId AND I.MasterCompanyId = @MasterCompanyId
									  Where PO.PurchaseOrderId = P.PurchaseOrderId AND P.IsActive = 1 AND P.IsDeleted = 0 AND P.isParent=1
									  AND P.MasterCompanyId = @MasterCompanyId
									  FOR XML PATH('')), 1, 1, '') WorkOrderNum
						) B
			Where (PO.IsDeleted=@IsDeleted) Group By PO.PurchaseOrderId,B.WorkOrderNum)
			,SOCTE AS(
						Select PO.PurchaseOrderId,(Case When Count(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse C.SalesOrderNumber End)  as 'SalesOrderNumberType', C.SalesOrderNumber from PurchaseOrder PO WITH (NOLOCK)
						Left Join PurchaseOrderPart POP WITH (NOLOCK) On PO.PurchaseOrderId=POP.PurchaseOrderId AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1 AND POP.MasterCompanyId = @MasterCompanyId
						INNER Join SalesOrder I WITH (NOLOCK) On POP.SalesOrderId=I.SalesOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.SalesOrderNumber
									  FROM PurchaseOrderPart P WITH (NOLOCK)
									  Left Join SalesOrder I WITH (NOLOCK) On P.SalesOrderId = I.SalesOrderId AND I.MasterCompanyId = @MasterCompanyId
									  Where PO.PurchaseOrderId = P.PurchaseOrderId AND P.IsActive = 1 AND P.IsDeleted = 0 AND P.isParent = 1
									  AND P.MasterCompanyId = @MasterCompanyId
									  FOR XML PATH('')), 1, 1, '') SalesOrderNumber
						) C
			Where (PO.IsDeleted=@IsDeleted) Group By PO.PurchaseOrderId,C.SalesOrderNumber)
			,ROCTE AS(
						Select PO.PurchaseOrderId,(Case When Count(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse D.RepairOrderNumber End)  as 'RepairOrderNumberType', D.RepairOrderNumber from PurchaseOrder PO WITH (NOLOCK)
						Left Join PurchaseOrderPart POP WITH (NOLOCK) On PO.PurchaseOrderId=POP.PurchaseOrderId AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1 AND POP.MasterCompanyId = @MasterCompanyId
						INNER Join RepairOrder I WITH (NOLOCK) On POP.RepairOrderId=I.RepairOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.RepairOrderNumber
									  FROM PurchaseOrderPart P WITH (NOLOCK)
									  Left Join RepairOrder I WITH (NOLOCK) On P.RepairOrderId = I.RepairOrderId AND I.MasterCompanyId = @MasterCompanyId
									  Where PO.PurchaseOrderId = P.PurchaseOrderId AND P.IsActive = 1 AND P.IsDeleted = 0 AND P.isParent = 1
									  AND P.MasterCompanyId = @MasterCompanyId
									  FOR XML PATH('')), 1, 1, '') RepairOrderNumber
						) D
			Where (PO.IsDeleted=@IsDeleted) Group By PO.PurchaseOrderId,D.RepairOrderNumber)
			,PartDateCTE AS(
						Select RO.PurchaseOrderId,(Case When Count(ROP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse A.EstDeliveryDateMulti End)  as 'EstDeliveryType',A.EstDeliveryDateMulti 
						from PurchaseOrder RO WITH (NOLOCK)
						Left Join dbo.PurchaseOrderPart ROP WITH (NOLOCK) On RO.PurchaseOrderId = ROP.PurchaseOrderId AND ROP.IsActive = 1 AND ROP.IsDeleted = 0 AND ROP.isParent=1 AND ROP.MasterCompanyId = @MasterCompanyId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + CAST(convert(varchar, R.EstDeliveryDate, 101) as VARCHAR(MAX))											
									  FROM PurchaseOrderPart R WITH (NOLOCK)
									  Where RO.PurchaseOrderId = R.PurchaseOrderId AND R.IsActive = 1 AND R.IsDeleted = 0 AND R.isParent = 1
									  AND R.MasterCompanyId = @MasterCompanyId
									  FOR XML PATH('')), 1, 1, '') EstDeliveryDateMulti
						) A
						Where (RO.IsDeleted=@IsDeleted)
						Group By RO.PurchaseOrderId,A.EstDeliveryDateMulti)
			,ResultData AS(
						Select M.PurchaseOrderId,M.PurchaseOrderNumber,M.PurchaseOrderNo,M.OpenDate as 'OpenDate',M.ClosedDate as 'ClosedDate',M.CreatedDate,
									M.CreatedBy,M.UpdatedDate,M.UpdatedBy,M.IsActive,M.IsDeleted,
									M.StatusId,M.VendorId,M.VendorName,M.VendorCode,M.[Status],M.RequestedBy,M.ApprovedBy,
									PR.SalesOrderNumberType,PR.SalesOrderNumber,PT.PartNumber,PT.PartNumberType,MF.Manufacturer,MF.ManufacturerType,PD.WorkOrderNum,
									PD.WorkOrderNumType,RP.RepairOrderNumberType,RP.RepairOrderNumber,
									PDT.EstDeliveryDateMulti,
									CAST(PDT.EstDeliveryType AS VARCHAR(MAX)) as 'EstDeliveryType',
									0 as PurchaseOrderPartRecordId
									,M.QuantityOrdered,M.QuantityBackOrdered,M.QuantityReceived
									from Result M 
						LEFT JOIN PartCTE PT ON M.PurchaseOrderId=PT.PurchaseOrderId
						LEFT JOIN ManufacturerCTE MF ON MF.PurchaseOrderId=M.PurchaseOrderId						
						LEFT JOIN WOCTE PD ON PD.PurchaseOrderId=M.PurchaseOrderId
						LEFT JOIN SOCTE PR ON PR.PurchaseOrderId=M.PurchaseOrderId
						LEFT JOIN ROCTE RP ON RP.PurchaseOrderId=M.PurchaseOrderId
						Left Join PartDateCTE PDT On M.PurchaseOrderId=PDT.PurchaseOrderId
			 WHERE ((@GlobalFilter <>'' AND ((PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR		
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR
					(ApprovedBy LIKE '%' +@GlobalFilter+'%') OR					
					([Status]  LIKE '%' +@GlobalFilter+'%') OR
					--(PT.PartNumber like '%' +@GlobalFilter+'%') OR
					--(MF.Manufacturer like '%' +@GlobalFilter+'%') OR
					--(PR.SalesOrderNumberType like '%' +@GlobalFilter+'%') OR
					--(PD.WorkOrderNumType like '%' +@GlobalFilter+'%') OR
					--(RP.RepairOrderNumberType like '%' +@GlobalFilter+'%') OR
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
					--(IsNull(@PartNumberType,'') ='' OR PT.PartNumber like '%'+ @PartNumberType+'%') and
					--(ISNULL(@EstDeliveryType,'') ='' OR PDT.EstDeliveryDateMulti like '%'+ @EstDeliveryType+'%') AND
					--(IsNull(@ManufacturerType,'') ='' OR MF.Manufacturer like '%'+ @ManufacturerType+'%') and
					--(IsNull(@SalesOrderNumberType,'') ='' OR PR.SalesOrderNumberType like '%'+@SalesOrderNumberType+'%') and
					--(IsNull(@WorkOrderNumType,'') ='' OR PD.WorkOrderNumType like '%'+@WorkOrderNumType+'%') and
					--(IsNull(@RepairOrderNumberType,'') ='' OR RP.RepairOrderNumberType like '%'+@RepairOrderNumberType+'%') and
					(IsNull(@QuantityOrdered,'') ='' OR CAST(QuantityOrdered as NVARCHAR(10)) like '%'+ @QuantityOrdered+'%') AND 
					(IsNull(@QuantityBackOrdered,'') ='' OR CAST(QuantityBackOrdered as NVARCHAR(10)) like '%'+@QuantityBackOrdered+'%') AND 
					(IsNull(@QuantityReceived,'') ='' OR CAST(QuantityReceived as NVARCHAR(10)) like '%'+@QuantityReceived+'%'))
				   )
			), CTE_Count AS (Select COUNT(PurchaseOrderId) AS NumberOfItems FROM ResultData)

			SELECT PurchaseOrderId,PurchaseOrderNumber,PurchaseOrderNo,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,UpdatedBy,IsActive,IsDeleted
			,StatusId,VendorId,VendorName,VendorCode,[Status],RequestedBy,ApprovedBy,
			PartNumber,PartNumberType,Manufacturer,ManufacturerType,WorkOrderNum,WorkOrderNumType,SalesOrderNumber,SalesOrderNumberType,RepairOrderNumberType,RepairOrderNumber,
			CreatedDate,UpdatedDate,NumberOfItems,CreatedBy,UpdatedBy,
			EstDeliveryDateMulti,EstDeliveryType,
			PurchaseOrderPartRecordId,QuantityOrdered,QuantityBackOrdered,QuantityReceived 
			FROM ResultData,CTE_Count
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
				    M.[Name] AS Manufacturer,
					M.[Name] AS ManufacturerType,
					SO.SalesOrderNumber,
					SO.SalesOrderNumber as SalesOrderNumberType,
					WO.WorkOrderNum,
					WO.WorkOrderNum as WorkOrderNumType,
					RO.RepairOrderNumber,
					RO.RepairOrderNumber as RepairOrderNumberType,
					--POP.EstDeliveryDate,
					CAST(POP.EstDeliveryDate AS VARCHAR(MAX)) as EstDeliveryDateMulti,
				    CAST(POP.EstDeliveryDate AS VARCHAR(MAX)) as EstDeliveryType,
					POP.PurchaseOrderPartRecordId,
					ISNULL(POP.QuantityOrdered,0) AS QuantityOrdered,
					ISNULL(POP.QuantityBackOrdered,0) AS QuantityBackOrdered,
					ISNULL(POP.QuantityOrdered,0) - ISNULL(POP.QuantityBackOrdered,0) AS QuantityReceived
			  FROM  [dbo].[PurchaseOrder] PO WITH (NOLOCK)
			  INNER JOIN [dbo].[PurchaseOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			  INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			  INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			  LEFT JOIN [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1
			  LEFT JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON POP.SalesOrderId = SO.SalesOrderId
			  LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON POP.WorkOrderId = WO.WorkOrderId
			  LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON POP.RepairOrderId = RO.RepairOrderId
			  LEFT JOIN [dbo].[Manufacturer] M WITH (NOLOCK) ON POP.ManufacturerId = M.ManufacturerId
		 	  WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID)) 
			      --AND EMS.EmployeeId = 	@EmployeeId 
				  AND PO.MasterCompanyId = @MasterCompanyId	
				  AND  (@VendorId  IS NULL OR PO.VendorId = @VendorId)
			), ResultCount AS(Select COUNT(PurchaseOrderId) AS totalItems FROM Result)
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
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
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