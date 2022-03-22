CREATE PROCEDURE [dbo].[GetVendorRFQPurchaseOrderList]
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
@mgmtStructure	VARCHAR(200)=null,
@Level2Type varchar(200)=null,
@Level3Type varchar(200)=null,
@Level4Type varchar(200)=null,
@Memo	varchar(200)=NULL
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
		DECLARE @MSModuleID INT = 20; -- Vendor RFQ PO Management Structure Module ID
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN	

		;WITH Result AS(									
		   	 SELECT PO.VendorRFQPurchaseOrderId,
		            PO.VendorRFQPurchaseOrderNumber,					
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
					VPOP.VendorRFQPOPartRecordId,  
					VPOP.PartNumber as 'PartNumberType',
					VPOP.PartDescription as 'PartDescriptionType',
					VPOP.StockType as 'StockTypeType',
					VPOP.Manufacturer as 'ManufacturerType',
					VPOP.Priority as 'PriorityType',
					VPOP.NeedByDate as 'NeedByDateType',
					VPOP.PromisedDate as 'PromisedDateType',
					VPOP.Condition as 'ConditionType',
					VPOP.UnitCost,
					VPOP.QuantityOrdered,
					VPOP.WorkOrderNo as 'WorkOrderNoType',
					VPOP.SubWorkOrderNo as 'SubWorkOrderNoType',
					VPOP.SalesOrderNo as 'SalesOrderNoType',
					ISNULL(VPOP.Level1,'') as 'Level1Type',
					ISNULL(VPOP.Level2,'') as 'Level2Type',
					ISNULL(VPOP.Level3,'') as 'Level3Type',
					ISNULL(VPOP.Level4,'') as 'Level4Type',
					ISNULL(VPOP.Memo,'') as 'MemoType',
					VPOP.PurchaseOrderId,
					VPOP.PurchaseOrderNumber as 'PurchaseOrderNumberType',
					MSD.LastMSLevel,
					MSD.AllMSlevels
			  FROM VendorRFQPurchaseOrder PO WITH (NOLOCK)
			  --INNER JOIN dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = PO.ManagementStructureId
			  INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.VendorRFQPurchaseOrderId
			  INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			  INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			  left outer JOIN DBO.VendorRFQPurchaseOrderPart VPOP WITH (NOLOCK) ON VPOP.VendorRFQPurchaseOrderId=PO.VendorRFQPurchaseOrderId			  		              			  
		 	  WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID)) 
			      --AND EMS.EmployeeId = 	@EmployeeId 
				  AND PO.MasterCompanyId = @MasterCompanyId	
				  --AND  (@VendorId  IS NULL OR PO.VendorId = @VendorId)
			), ResultCount AS(Select COUNT(VendorRFQPurchaseOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((VendorRFQPurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR		
					(RequestedBy LIKE '%' +@GlobalFilter+'%') OR
					(PartNumberType LIKE '%' +@GlobalFilter+'%') OR
					(PartDescriptionType LIKE '%' +@GlobalFilter+'%') OR
					(StockTypeType LIKE '%' +@GlobalFilter+'%') OR
					(ManufacturerType LIKE '%' +@GlobalFilter+'%') OR
					(PriorityType LIKE '%' +@GlobalFilter+'%') OR
					(ConditionType LIKE '%' +@GlobalFilter+'%') OR
					(UnitCost LIKE '%' +@GlobalFilter+'%') OR
					(QuantityOrdered LIKE '%' +@GlobalFilter+'%') OR
					(WorkOrderNoType LIKE '%' +@GlobalFilter+'%') OR
					(SubWorkOrderNoType LIKE '%' +@GlobalFilter+'%') OR
					(SalesOrderNoType LIKE '%' +@GlobalFilter+'%') OR
					--(Level1Type LIKE '%' +@mgmtStructure+'%') OR
					--(Level2Type LIKE '%' +@mgmtStructure+'%') OR
					--(Level3Type LIKE '%' +@mgmtStructure+'%') OR
					--(Level4Type LIKE '%' +@mgmtStructure+'%') OR
					(PurchaseOrderNumberType LIKE '%' +@GlobalFilter+'%') OR
					([Status]  LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@VendorRFQPurchaseOrderNumber,'') ='' OR VendorRFQPurchaseOrderNumber LIKE '%' + @VendorRFQPurchaseOrderNumber+'%') AND 
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND					
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@RequestedBy,'') ='' OR RequestedBy LIKE '%' + @RequestedBy + '%') AND
					(ISNULL(@Status,'') ='' OR Status LIKE '%' + @Status + '%') AND									
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND									
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@NeedByDate,'') ='' OR CAST(NeedByDateType AS Date)=CAST(@NeedByDate AS date)) AND
					(ISNULL(@PromisedDate,'') ='' OR CAST(PromisedDateType AS Date)=CAST(@PromisedDate AS date)) AND
					(ISNULL(@PartNumber,'') ='' OR PartNumberType LIKE '%' + @PartNumber + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescriptionType LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@StockType,'') ='' OR StockTypeType LIKE '%' + @StockType + '%') AND
					(ISNULL(@Manufacturer,'') ='' OR ManufacturerType LIKE '%' + @Manufacturer + '%') AND
					(ISNULL(@Priority,'') ='' OR PriorityType LIKE '%' + @Priority + '%') AND
					(ISNULL(@Condition,'') ='' OR ConditionType LIKE '%' + @Condition + '%') AND
					(ISNULL(@UnitCost,'') ='' OR CAST(UnitCost AS varchar(10)) LIKE '%' + CAST(@UnitCost AS VARCHAR(10))+ '%') AND
					(ISNULL(@QuantityOrdered,'') ='' OR QuantityOrdered LIKE '%' + @QuantityOrdered + '%') AND
					(ISNULL(@WorkOrderNo,'') ='' OR WorkOrderNoType LIKE '%' + @WorkOrderNo + '%') AND
					(ISNULL(@SubWorkOrderNo,'') ='' OR SubWorkOrderNoType LIKE '%' + @SubWorkOrderNo + '%') AND
					(ISNULL(@SalesOrderNo,'') ='' OR SalesOrderNoType LIKE '%' + @SalesOrderNo + '%') AND
					(ISNULL(@mgmtStructure,'') ='' OR Level1Type LIKE '%' + @mgmtStructure + '%') AND
					(ISNULL(@Level2Type,'') ='' OR Level2Type LIKE '%' + @Level2Type + '%') AND
					(ISNULL(@Level3Type,'') ='' OR Level3Type LIKE '%' + @Level3Type + '%') AND
					(ISNULL(@Level4Type,'') ='' OR Level4Type LIKE '%' + @Level4Type + '%') AND
					(ISNULL(@Memo,'') ='' OR MemoType LIKE '%' + @Memo + '%') AND
					(ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumberType LIKE '%' + @PurchaseOrderNumber + '%') AND					
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(VendorRFQPurchaseOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='vendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='vendorName')  THEN VendorName END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Status')  THEN Status END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Status')  THEN Status END DESC,	
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

			CASE WHEN (@SortOrder=1  AND @SortColumn='partNumberType')  THEN PartNumberType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='partNumberType')  THEN PartNumberType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescriptionType')  THEN PartDescriptionType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescriptionType')  THEN PartDescriptionType END DESC,
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='workOrderNoType')  THEN WorkOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='workOrderNoType')  THEN WorkOrderNoType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SubWorkOrderNoType')  THEN SubWorkOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SubWorkOrderNoType')  THEN SubWorkOrderNoType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SalesOrderNoType')  THEN SalesOrderNoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesOrderNoType')  THEN SalesOrderNoType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='MemoType')  THEN MemoType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MemoType')  THEN MemoType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='mgmtStructure')  THEN Level1Type END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='mgmtStructure')  THEN Level1Type END DESC,
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