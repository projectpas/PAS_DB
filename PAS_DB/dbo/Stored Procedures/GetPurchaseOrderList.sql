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
@SalesOrderNumberType varchar(50)=null,
@WorkOrderNumType varchar(50)=null,
@RepairOrderNumberType varchar(50)=null
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
					PO.ApprovedBy				
			  FROM PurchaseOrder PO WITH (NOLOCK)
			  INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			  INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			  INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
			  LEFT JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1
		 	  WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID))
			      --AND EMS.EmployeeId = 	@EmployeeId 
				  AND PO.MasterCompanyId = @MasterCompanyId	
				  AND  (@VendorId  IS NULL OR PO.VendorId = @VendorId)
			)
			,PartCTE AS(
						Select PO.PurchaseOrderId,(Case When Count(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber from PurchaseOrder PO WITH (NOLOCK)
						Left Join PurchaseOrderPart POP WITH (NOLOCK) On PO.PurchaseOrderId=POP.PurchaseOrderId AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + PO.partnumber
									  FROM PurchaseOrderPart PO WITH (NOLOCK)
									  --Left Join ItemMaster I WITH (NOLOCK) On PO.ItemMasterId=I.ItemMasterId
									  Where PO.PurchaseOrderId=POP.PurchaseOrderId AND PO.IsActive = 1 AND PO.IsDeleted = 0 AND PO.isParent=1
									  FOR XML PATH('')), 1, 1, '') PartNumber
								--CASE WHEN POP.ItemTypeId=1 THEN  STUFF((SELECT ',' + I.partnumber
								--	  FROM PurchaseOrderPart PO WITH (NOLOCK)
								--	   Left Join ItemMaster I WITH (NOLOCK) On PO.ItemMasterId=I.ItemMasterId
								--	  Where PO.PurchaseOrderId=POP.PurchaseOrderId AND PO.IsActive = 1 AND PO.IsDeleted = 0 AND PO.isParent=1
								--	  FOR XML PATH('')), 1, 1, '')
								--WHEN POP.ItemTypeId=2 THEN STUFF((SELECT ',' + I.partnumber
								--	  FROM PurchaseOrderPart PO WITH (NOLOCK)
								--	   Left Join ItemMasterNonStock I WITH (NOLOCK) On PO.ItemMasterId=I.MasterPartId
								--	  Where PO.PurchaseOrderId=POP.PurchaseOrderId AND PO.IsActive = 1 AND PO.IsDeleted = 0 AND PO.isParent=1
								--	  FOR XML PATH('')), 1, 1, '')
								--WHEN POP.ItemTypeId=11 THEN STUFF((SELECT ',' + I.AssetId
								--	  FROM PurchaseOrderPart PO WITH (NOLOCK)
								--	   Left Join Asset I WITH (NOLOCK) On PO.ItemMasterId=I.AssetRecordId
								--	  Where PO.PurchaseOrderId=POP.PurchaseOrderId AND PO.IsActive = 1 AND PO.IsDeleted = 0 AND PO.isParent=1
								--	  FOR XML PATH('')), 1, 1, '')
								--ELSE '' END AS PartNumber
						) A
						Where ((PO.IsDeleted=@IsDeleted) and (@StatusID is null or PO.StatusId=@StatusID))Group By PO.PurchaseOrderId,A.PartNumber)
			,WOCTE AS(
						Select PO.PurchaseOrderId,(Case When Count(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse B.WorkOrderNum End)  as 'WorkOrderNumType',B.WorkOrderNum from PurchaseOrder PO WITH (NOLOCK)
						Left Join PurchaseOrderPart POP WITH (NOLOCK) On PO.PurchaseOrderId=POP.PurchaseOrderId AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1
						INNER Join WorkOrder I WITH (NOLOCK) On POP.WorkOrderId=I.WorkOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.WorkOrderNum
									  FROM PurchaseOrderPart PO WITH (NOLOCK)
									  Left Join WorkOrder I WITH (NOLOCK) On PO.WorkOrderId=I.WorkOrderId
									  Where PO.PurchaseOrderId=POP.PurchaseOrderId AND PO.IsActive = 1 AND PO.IsDeleted = 0 AND PO.isParent=1
									  FOR XML PATH('')), 1, 1, '') WorkOrderNum
						) B
			Where ((PO.IsDeleted=@IsDeleted) and (@StatusID is null or PO.StatusId=@StatusID))Group By PO.PurchaseOrderId,B.WorkOrderNum)
			,SOCTE AS(
						Select PO.PurchaseOrderId,(Case When Count(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse C.SalesOrderNumber End)  as 'SalesOrderNumberType', C.SalesOrderNumber from PurchaseOrder PO WITH (NOLOCK)
						Left Join PurchaseOrderPart POP WITH (NOLOCK) On PO.PurchaseOrderId=POP.PurchaseOrderId AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1
						INNER Join SalesOrder I WITH (NOLOCK) On POP.SalesOrderId=I.SalesOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.SalesOrderNumber
									  FROM PurchaseOrderPart PO WITH (NOLOCK)
									  Left Join SalesOrder I WITH (NOLOCK) On PO.SalesOrderId=I.SalesOrderId
									  Where PO.PurchaseOrderId=POP.PurchaseOrderId AND PO.IsActive = 1 AND PO.IsDeleted = 0 AND PO.isParent=1
									  FOR XML PATH('')), 1, 1, '') SalesOrderNumber
						) C
			Where ((PO.IsDeleted=@IsDeleted) and (@StatusID is null or PO.StatusId=@StatusID))Group By PO.PurchaseOrderId,C.SalesOrderNumber)
			,ROCTE AS(
						Select PO.PurchaseOrderId,(Case When Count(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse D.RepairOrderNumber End)  as 'RepairOrderNumberType', D.RepairOrderNumber from PurchaseOrder PO WITH (NOLOCK)
						Left Join PurchaseOrderPart POP WITH (NOLOCK) On PO.PurchaseOrderId=POP.PurchaseOrderId AND POP.IsActive = 1 AND POP.IsDeleted = 0 AND POP.isParent=1
						INNER Join RepairOrder I WITH (NOLOCK) On POP.RepairOrderId=I.RepairOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.RepairOrderNumber
									  FROM PurchaseOrderPart PO WITH (NOLOCK)
									  Left Join RepairOrder I WITH (NOLOCK) On PO.RepairOrderId=I.RepairOrderId
									  Where PO.PurchaseOrderId=POP.PurchaseOrderId AND PO.IsActive = 1 AND PO.IsDeleted = 0 AND PO.isParent=1
									  FOR XML PATH('')), 1, 1, '') RepairOrderNumber
						) D
			Where ((PO.IsDeleted=@IsDeleted) and (@StatusID is null or PO.StatusId=@StatusID))Group By PO.PurchaseOrderId,D.RepairOrderNumber)
			,ResultData AS(
						Select M.PurchaseOrderId,M.PurchaseOrderNumber,M.PurchaseOrderNo,M.OpenDate as 'OpenDate',M.ClosedDate as 'ClosedDate',M.CreatedDate,
									M.CreatedBy,M.UpdatedDate,M.UpdatedBy,M.IsActive,M.IsDeleted,
									M.StatusId,M.VendorId,M.VendorName,M.VendorCode,M.[Status],M.RequestedBy,M.ApprovedBy,
									PR.SalesOrderNumberType,PR.SalesOrderNumber,PT.PartNumber,PT.PartNumberType,PD.WorkOrderNum,
									PD.WorkOrderNumType,RP.RepairOrderNumberType,RP.RepairOrderNumber,NULL as 'EstDeliveryDate',0 as PurchaseOrderPartRecordId
									from Result M 
						Left Join PartCTE PT On M.PurchaseOrderId=PT.PurchaseOrderId
						Left Join WOCTE PD on PD.PurchaseOrderId=M.PurchaseOrderId
						Left Join SOCTE PR on PR.PurchaseOrderId=M.PurchaseOrderId
						Left Join ROCTE RP on RP.PurchaseOrderId=M.PurchaseOrderId
			--, ResultCount AS(Select COUNT(PurchaseOrderId) AS totalItems FROM Result)
			--SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR		
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR
					(ApprovedBy LIKE '%' +@GlobalFilter+'%') OR					
					([Status]  LIKE '%' +@GlobalFilter+'%') OR
					(PT.PartNumberType like '%' +@GlobalFilter+'%') OR
					(PR.SalesOrderNumberType like '%' +@GlobalFilter+'%') OR
					(PD.WorkOrderNumType like '%' +@GlobalFilter+'%') OR
					(RP.RepairOrderNumberType like '%' +@GlobalFilter+'%')))
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
					(IsNull(@PartNumberType,'') ='' OR PT.PartNumberType like '%'+ @PartNumberType+'%') and
					(IsNull(@SalesOrderNumberType,'') ='' OR PR.SalesOrderNumberType like '%'+@SalesOrderNumberType+'%') and
					(IsNull(@WorkOrderNumType,'') ='' OR PD.WorkOrderNumType like '%'+@WorkOrderNumType+'%') and
					(IsNull(@RepairOrderNumberType,'') ='' OR RP.RepairOrderNumberType like '%'+@RepairOrderNumberType+'%'))
				   )

			--SELECT @Count = COUNT(PurchaseOrderId) FROM #TempResult			

			--SELECT *, @Count AS NumberOfItems FROM #TempResult
			), CTE_Count AS (Select COUNT(PurchaseOrderId) AS NumberOfItems FROM ResultData)
						SELECT PurchaseOrderId,PurchaseOrderNumber,PurchaseOrderNo,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,UpdatedBy,IsActive,IsDeleted
						,StatusId,VendorId,VendorName,VendorCode,[Status],RequestedBy,ApprovedBy,PartNumber,PartNumberType,WorkOrderNum,WorkOrderNumType,SalesOrderNumber,SalesOrderNumberType,RepairOrderNumberType,RepairOrderNumber,
						CreatedDate,UpdatedDate,NumberOfItems,CreatedBy,UpdatedBy,EstDeliveryDate,PurchaseOrderPartRecordId FROM ResultData,CTE_Count
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
					SO.SalesOrderNumber,
					SO.SalesOrderNumber as SalesOrderNumberType,
					WO.WorkOrderNum,
					WO.WorkOrderNum as WorkOrderNumType,
					RO.RepairOrderNumber,
					RO.RepairOrderNumber as RepairOrderNumberType,
					POP.EstDeliveryDate,
					POP.PurchaseOrderPartRecordId
			  FROM PurchaseOrder PO WITH (NOLOCK)
			  INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			  INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			  INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			  LEFT JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1
			  LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON POP.SalesOrderId = SO.SalesOrderId
			  LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON POP.WorkOrderId = WO.WorkOrderId
			  LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON POP.RepairOrderId = RO.RepairOrderId
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
					(PartNumberType like '%' +@GlobalFilter+'%') OR
					(SalesOrderNumberType like '%' +@GlobalFilter+'%') OR
					(WorkOrderNumType like '%' +@GlobalFilter+'%') OR
					(RepairOrderNumberType like '%' +@GlobalFilter+'%')))
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
					(IsNull(@PartNumberType,'') ='' OR PartNumberType like '%'+ @PartNumberType+'%') and
					(IsNull(@SalesOrderNumberType,'') ='' OR SalesOrderNumberType like '%'+@SalesOrderNumberType+'%') and
					(IsNull(@WorkOrderNumType,'') ='' OR WorkOrderNumType like '%'+@WorkOrderNumType+'%') and
					(IsNull(@RepairOrderNumberType,'') ='' OR RepairOrderNumberType like '%'+@RepairOrderNumberType+'%'))
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