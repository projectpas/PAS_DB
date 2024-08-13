
/*************************************************************               
 ** File:   [ProcGetVendorRFQRoList]               
 ** Author:   -    
 ** Description: This stored procedure is used to ProcGetVendorRFQRoList      
 ** Purpose:             
 ** Date: -            
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------			--------------------------------              
	1    	-	         -              Created    
	2    25/07/2024   Rajesh Gami		Optimize the SP due to performance issue
	3    08/08/2024   Rajesh Gami		Return vendor Reference number for the make duplicate functionality.

**************************************************************/  

----------------------------------------------------------------------------------------------------------------------
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
	@Memo			varchar(200)=null,
	@IsNoQuote [BIT] = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @RecordFrom int;
		Declare @IsActive bit=1
		DECLARE @Count Int,@TotalCount int = 0;
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
		DECLARE @MSModuleID INT = 22; -- Vendor RFQ PO Management Structure Module ID
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
				   RP.IsNoQuote,
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
				   RP.Memo as 'MemoType',
				   RP.RepairOrderNumber as 'RepairOrderNumberType',
				   RP.RepairOrderId,
				   RP.VendorRFQROPartRecordId,
				   MSD.LastMSLevel,
				   MSD.AllMSlevels
				   ,RO.VendorReference VendorReference
			FROM  dbo.VendorRFQRepairOrder RO WITH (NOLOCK)
			 --INNER JOIN  dbo.EmployeeManagementStructure EMS WITH (NOLOCK) ON EMS.ManagementStructureId = RO.ManagementStructureId	
			 INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = RO.VendorRFQRepairOrderId
			  INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			  INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			 LEFT JOIN dbo.VendorRFQRepairOrderPart RP WITH (NOLOCK) ON RP.VendorRFQRepairOrderId=RO.VendorRFQRepairOrderId
			WHERE ((RO.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR RO.StatusId=@StatusID)) AND
			        --EMS.EmployeeId = @EmployeeId AND
					RO.MasterCompanyId=@MasterCompanyId 
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
					--(ISNULL(@Level4Type   ,'') ='' OR	Level4Type LIKE '%' +   @Level4Type    + '%') AND
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
				   RO.Requisitioner AS RequestedBy,RO.VendorReference VendorReference				   
			FROM  dbo.VendorRFQRepairOrder RO WITH (NOLOCK)
			INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = RO.VendorRFQRepairOrderId
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			WHERE ((RO.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR RO.StatusId=@StatusID)) AND
			        --EMS.EmployeeId = @EmployeeId AND
					RO.MasterCompanyId=@MasterCompanyId 
					 AND 
					 (@VendorId  IS NULL OR RO.VendorId=@VendorId)
					 )
			SELECT DISTINCT M.VendorRFQRepairOrderId,M.VendorRFQRepairOrderNumber,M.OpenDate,M.ClosedDate,M.CreatedDate,M.CreatedBy,M.UpdatedDate,
					M.UpdatedBy,M.IsActive,M.IsDeleted,M.StatusId,M.VendorId,M.VendorName,M.VendorCode,M.[Status],
					M.RequestedBy AS RequestedBy,
					(Select SUM(QuantityOrdered) as QuantityOrdered from VendorRFQRepairOrderPart WITH (NOLOCK) 
					Where VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) as QuantityOrdered,
					 0 as IsNoQuote,
					(Select SUM(UnitCost) as UnitCost from VendorRFQRepairOrderPart WITH (NOLOCK) 
					Where VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) as UnitCost,
					
						'' AS Level1Type,
						'' AS Level2Type,
						'' AS Level3Type,
						'' AS Level4Type,

						--(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						--FROM  dbo.VendorRFQRepairOrderPart VRPP 
						--WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId ) > 1  --AND LEN(isnull(SP.Level1,'')) >0
						--) Then 'Multiple' ELse  MAX(isnull(MSD.LastMSLevel,''))   End)
						--as 'LastMSLevel',
						--(Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						--FROM  dbo.VendorRFQRepairOrderPart VRPP 
						--WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId ) > 1  --AND LEN(isnull(SP.Level1,'')) >0
						--) Then 'Multiple' ELse  MAX(isnull(MSD.AllMSlevels,''))   End)
						--as 'AllMSlevels',
						MAX(isnull(MSD.LastMSLevel,'')) as LastMSLevelMax,
						MAX(isnull(MSD.AllMSlevels,'')) as AllMSlevelsMax,
						MAX(isnull(SP.StockType,'')) as StockTypeMax,
						MAX(isnull(SP.Manufacturer,'')) as ManufacturerMax,
						MAX(isnull(SP.[Priority],'')) as PriorityMax,
						MAX(isnull(SP.Condition,'')) as ConditionMax,
						MAX(isnull(SP.WorkOrderNo,'')) as WorkOrderNoMax,
						MAX(isnull(SP.SubWorkOrderNo,'')) as SubWorkOrderNoMax,
						MAX(isnull(SP.SalesOrderNo,'')) as SalesOrderNoMax,
						MAX(isnull(SP.RepairOrderNumber,'')) as RepairOrderNumberMax,
						MAX(isnull(SP.Memo,'')) as MemoMax,
					  MAX(isnull(SP.AltEquiPartNumber,'')) as AltEquiPartNumberMax,
					  MAX(isnull(SP.RevisedPartNumber,'')) as RevisedPartNumberMax,
  					  MAX(isnull(SP.WorkPerformed,'')) as WorkPerformedMax,
					  MAX(SP.PartNumber) as 'PartNumberMax', 
					  MAX(SP.PartDescription)as 'PartDescriptionMax',
					  MAX(CONVERT(varchar, SP.PromisedDate, 101)) as 'PromisedDateMax',
					  MAX(CONVERT(varchar, SP.NeedByDate, 101)) as NeedByDateMax,
					  
					  (Case When ((SELECT Count(VRPP.VendorRFQRepairOrderId) 
						FROM  dbo.VendorRFQRepairOrderPart VRPP 
						WHERE VRPP.VendorRFQRepairOrderId = M.VendorRFQRepairOrderId) > 1 
						 ) Then 'Multiple' ELse  'Single'   End)
						as 'RowStatus'
						,VendorReference
					 INTO #TEMPRes
					from 
					Main M
					LEFT JOIN VendorRFQRepairOrderPart SP ON M.VendorRFQRepairOrderId=SP.VendorRFQRepairOrderId 
					LEFT JOIN dbo.RepairOrderManagementStructureDetails MSD ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SP.VendorRFQRepairOrderId
			
				   GROUP BY M.VendorRFQRepairOrderId,VendorRFQRepairOrderNumber,OpenDate,ClosedDate,M.CreatedDate,M.CreatedBy,M.UpdatedDate,
					M.UpdatedBy,M.IsActive,M.IsDeleted,M.StatusId,VendorId,VendorName,VendorCode,M.[Status],SP.UnitCost,QuantityOrdered,IsNoQuote,
					RequestedBy,VendorReference
	
			SELECT VendorRFQRepairOrderId,VendorRFQRepairOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,
					UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered,IsNoQuote,
					RequestedBy,Level1Type, Level2Type,Level3Type,Level4Type,RowStatus,VendorReference,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(LastMSLevelMax) END) as LastMSLevel,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(AllMSlevelsMax) END) as AllMSlevels,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(StockTypeMax) END) as StockTypeType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(ManufacturerMax) END) as ManufacturerType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(PriorityMax) END) as PriorityType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(ConditionMax) END) as ConditionType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(WorkOrderNoMax) END) as WorkOrderNoType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(SubWorkOrderNoMax) END) as SubWorkOrderNoType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(SalesOrderNoMax) END) as SalesOrderNoType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(RepairOrderNumberMax) END) as RepairOrderNumberType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(MemoMax) END) as MemoType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(AltEquiPartNumberMax) END) as AltEquiPartNumberType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(RevisedPartNumberMax) END) as RevisedPartNumberType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(WorkPerformedMax) END) as WorkPerformedType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(PartNumberMax) END) as PartNumber,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(PartNumberMax) END) as PartNumberType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(NeedByDateMax) END) as NeedByDate,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(NeedByDateMax) END) as NeedByDateType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(PromisedDateMax) END) as PromisedDate,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(PromisedDateMax) END) as PromisedDateType,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(PartDescriptionMax) END) as PartDescription,
					(CASE WHEN RowStatus = 'Multiple' THEN 'Multiple' ELSE MAX(PartDescriptionMax) END) as PartDescriptionType
			INTO #finalTemp FROM #TEMPRes 
			GROUP BY VendorRFQRepairOrderId,VendorRFQRepairOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,
					UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered,IsNoQuote,
					RequestedBy,Level1Type, Level2Type,Level3Type,Level4Type,RowStatus,VendorReference
																		  
			  SELECT DISTINCT * INTO #TEMPData FROM #finalTemp													   
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
					(ISNULL(@NeedByDate,'') ='' OR NeedByDateType LIKE '%' + @NeedByDate + '%') AND  
					(ISNULL(@PromisedDate,'') ='' OR PromisedDateType LIKE '%' + @PromisedDate + '%') AND  
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

				  SET @TotalCount = (SELECT COUNT(VendorRFQRepairOrderId) FROM #TEMPData)
			SELECT VendorRFQRepairOrderId,VendorRFQRepairOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,
					UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered
					,RequestedBy
					,PartNumber
					,PartDescription,PartNumberType,PartDescriptionType
					,StockTypeType,RepairOrderNumberType,
					ManufacturerType,PriorityType,NeedByDate,PromisedDate,NeedByDateType,PromisedDateType,ConditionType,WorkOrderNoType,SubWorkOrderNoType,SalesOrderNoType--,PurchaseOrderNumberType
					,LastMSLevel,AllMSlevels,VendorReference,
					@TotalCount as NumberOfItems
					FROM #TEMPData
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
	SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
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