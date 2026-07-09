/*************************************************************               
 ** File:   [ProcStockList]               
 ** Author:   Hemant Saliya    
 ** Description: This stored procedure is used to get stockline list      
 ** Purpose:             
 ** Date:   23/05/2023            
              
 ** PARAMETERS:               
 @UserType varchar(60)       
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------			--------------------------------              
	1    23/05/2023   Hemant Saliya		Created    
	2    30/05/2023   Amit Ghediya		Alternate part selected with main part.    
	3    31/05/2023   Amit Ghediya		Filter with ALT part.    
	4    02/06/2023   Amit Ghediya		Resolved ALT part stk mismatch.    
	5    12/06/2023   Devendra Shekh	Added work order num filter  
	6    13/06/2023   Devendra Shekh	Added new field 'isTimeLife' for list
	7    06/07/2023   Vishal Suthar		Added new field 'lotNumber' for list
	8    23/08/2023   Amit Ghediya		Updated filter list as per ManagementStructureId
	9    16/10/2023   Devendra Shekh	timelife issue resolved
	10   02/02/2024	  Bhargav Saliya    Filter with 'CustomerName'.
	11   18/04/2024	  Moin Bloch        Added new field 'IsTurnIn' for list
	12   17/07/2024   Shrey Chandegara  Modified( use this function @CurrntEmpTimeZoneDesc for date issue.)
	13   22/07/2024   Vishal Suthar     Commented above change as for the performance issue
	14   22/07/2024   Rajesh Gami       Optimized for Performance Issue
	15   25/07/2024   Rajesh Gami       Remove inner query for the get WorkOrderStage due to performance issue
	16   21/01/2025   Abhishek Jirawala Stockline listing SP optimisation
	17   12/02/2025   Ayushi Patel      converted the date into utc (updated) , Added a case to get timeZone
	18   08/04/2025   Amit Ghediya		Added new field 'PoNumber,RoNumber & ReceiverNumber' for list
	19   09/04/2025   Devendra Shekh	Added new field 'QuantityAdjustment, IsDocument' for list
	20   13/05/2025   Hemant Saliya		Remove 'PoNumber, RoNumber, IsDocument join to Improve Performance.
	21   16/05/2025   Devendra Shekh    reading RepairOrderNumber, PurchaseOrderNumber, IsDocument from StockLine Table
	22   22/05/2025   Abhishek Jirawala Added new field Repair Management for list
	23   16/07/2025   Moin Bloch	    Added IsBatchStock And Batch Number
	24   02/12/2025   Bhargav Saliya	Added Unit Cost
	25   01/20/2026   Amit Ghediya		Update for filter allow unitcost to decimal like (18.25)
	26   26/01/2026   Divyesh Kathiriya	Added new field 'GLAccount' for list
	27   21/04/2026   Divyesh Kathiriya	Added new field 'PN Source' for list [PN-16132]
	28    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	29    07/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory into Stockline : Added @IsNonStock filter (NULL=All, 0=Stock, 1=Non-Stock) and IsNonStock column, no new joins added
	30    08/July/2026			 RAJESH GAMI						[PN-17009] - Added computed 'Type' column (Stock/Non-Stock text) for the FieldMaster-driven grid column
	31    08/July/2026			 RAJESH GAMI						[PN-17009] - Renamed computed column 'Type' to 'ItemType'; Added @ItemType filter param + GlobalFilter/specific-filter support so searching 'Stock'/'Non-Stock' matches by IsNonStock flag

	(Do Not add any new join or In Query in Stockline list SP)
	
-- exec ProcStockList @PageNumber=1,@PageSize=20,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@stockTypeId=1,@StocklineNumber=NULL,@MainPartNumber=NULL,
@PartNumber=NULL,@PartDescription=NULL,@ItemGroup=NULL,@UnitOfMeasure=NULL,@SerialNumber=NULL,@GlAccountName=NULL,@ItemCategory=NULL,@Condition=NULL,@QuantityAvailable=NULL,
@QuantityOnHand=NULL,@CompanyName=NULL,@BuName=NULL,@DeptName=NULL,@DivName=NULL,@RevisedPN=NULL,@AWB=NULL,@ReceivedDate=NULL,@TraceableToName=NULL,@TaggedByName=NULL,
@TagType=NULL,@TagDate=NULL,@ExpirationDate=NULL,@ControlNumber=NULL,@IdNumber=NULL,@Manufacturer=NULL,@PartCertificationNumber=NULL,@CertifiedBy=NULL,@CertifiedDate=NULL,
@UpdatedBy=NULL,@UpdatedDate=NULL,@EmployeeId=98,@MasterCompanyId=11,@IsCustomerStock=NULL,@ItemMasterId=0,@StockLineIds=NULL,@obtainFrom=NULL,@ownerName=NULL,
@LastMSLevel=NULL,@QuantityReserved=NULL,@WorkOrderStage=NULL,@IsECStock=1,@IsCStock=0,@Site=NULL,@Location=NULL,@IsALTStock=0,@WorkOrderNumber=NULL,@IsTimeLife=NULL,
@CustomerName=NULL,@IsTurnIn=NULL,@GLAccount=NULL,@PNSource=NULL
**************************************************************/   
CREATE       PROCEDURE [dbo].[ProcStockList]	
	@PageNumber int = NULL,
	@PageSize int = NULL,        
	@SortColumn varchar(50)=NULL,        
	@SortOrder int = NULL,        
	@GlobalFilter varchar(50) = NULL,        
	@stockTypeId int = NULL,
	@IsNonStock bit = NULL,
	@ItemType varchar(50) = NULL,
	@StocklineNumber varchar(50) = NULL,
	@MainPartNumber varchar(50) = NULL,       
	@PartNumber varchar(50) = NULL,        
	@PartDescription varchar(50) = NULL,        
	@ItemGroup varchar(50) = NULL,        
	@UnitOfMeasure varchar(50) = NULL,        
	@SerialNumber  varchar(50) = NULL,        
	@GlAccountName varchar(50) = NULL,        
	@ItemCategory varchar(50) = NULL,        
	@Condition varchar(50) = NULL,        
	@QuantityAvailable varchar(50) = NULL,        
	@QuantityOnHand varchar(50) = NULL,        
	@CompanyName varchar(50) = NULL,        
	@BuName varchar(50) = NULL,        
	@DeptName varchar(50) = NULL,        
	@DivName varchar(50) = NULL,        
	@RevisedPN varchar(50) = NULL,        
	@AWB varchar(50) = NULL,        
	@ReceivedDate datetime = NULL,        
	@TraceableToName varchar(50) = NULL,        
	@TaggedByName varchar(50) = NULL,        
	@TagType varchar(50) = NULL,        
	@TagDate datetime = NULL,        
	@ExpirationDate datetime = NULL,        
	@ControlNumber varchar(50) = NULL,        
	@IdNumber varchar(50) = NULL,        
	@Manufacturer varchar(50) = NULL,        
	@PartCertificationNumber varchar(50) = NULL,        
	@CertifiedBy  varchar(50) = NULL,        
	@CertifiedDate datetime = NULL,        
	@UpdatedBy  varchar(50) = NULL,        
	@UpdatedDate  datetime = NULL,        
	@EmployeeId BIGINT=NULL,     
	@MasterCompanyId BIGINT = NULL,        
	@IsCustomerStock varchar(50) = NULL,        
	@ItemMasterId BIGINT = 0,        
	@StockLineIds varchar(1000) = NULL,        
	@obtainFROM varchar(50) = NULL,        
	@ownerName varchar(50) = NULL,        
	@LastMSLevel varchar(50)=null,        
	@QuantityReserved varchar(50)=null,        
	@WorkOrderStage varchar(50)=null,        
	@IsECStock bit,        
	@IsCStock bit,  
	@Site varchar(100) = NULL,    
	@Location varchar(100) = NULL,    
	@IsALTStock bit NULL,  
	@WorkOrderNumber  varchar(50) = NULL,
	@IsTimeLife varchar(50) = NULL,
	@CustomerName varchar(50) = NULL,
	@IsTurnIn varchar(50) = NULL,
	@PONumber varchar(50) = NULL,
	@RONumber varchar(50) = NULL,
	@ReceiverNumber varchar(50) = NULL,
	@QuantityAdjustment varchar(50) = NULL,
	@IsDocument varchar(50) = NULL,
	@IsRepairManagement varchar(50) = NULL,
	@BatchNumber varchar(50)=NULL,
	@UnitCost varchar(50)=NULL,
	@GLAccount varchar(255) = NULL,
	@PNSource varchar(20) = NULL
AS        
BEGIN         
     SET NOCOUNT ON;        
	  DECLARE @RecordFROM INT;        
	  DECLARE @MSModuelId int;        
	  DECLARE @Count Int;        
	  DECLARE @IsActive bit;        
	  DECLARE @ISCS bit;        
	  DECLARE @ISECS bit, @isElse bit =0, @IsCustomerStockInline bit = NULL; 
	  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	  DECLARE @AttachmentModuleId INT = 0;
	  DECLARE @BaseUtcOffsetSec INT;
		
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
	   	WHERE E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
	  
	  SET @RecordFROM = (@PageNumber-1)*@PageSize;         
	  SET @MSModuelId = 2;   -- For Stockline  
	  
	  -- Fetch the UTC offset in seconds
	  SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec  
	  FROM dbo.TimeZone WITH(NOLOCK)  
	  WHERE [Description] = @CurrntEmpTimeZoneDesc 
        
	  IF @SortColumn IS NULL        
	  BEGIN        
	   SET @SortColumn=Upper('CreatedDate')        
	  END         
	  ELSE        
	  BEGIN         
	   Set @SortColumn=Upper(@SortColumn)        
	  END         
        
	  IF(@stockTypeId = 0)        
	  BEGIN        
		SET @stockTypeId = NULL;        
	  END        
        
	  IF @IsCStock = 0        
	  BEGIN         
	   SET @ISCS = 0        
	  END        
	  ELSE        
	  BEGIN        
	   SET @ISCS = 1        
	  END        
        
	  IF @IsECStock = 0        
	  BEGIN         
	   SET @ISECS = 0        
	  END        
	  ELSE        
	  BEGIN        
	   SET @ISECS = 1        
	  END        
       SET @IsCustomerStockInline = (CASE WHEN @ISCS = 1 AND @ISECS = 0 THEN 1 WHEN @ISCS = 0 AND @ISECS = 1 THEN 0 else NULL END) 
	   SET @isElse = (CASE WHEN @IsCustomerStockInline IS NULL THEN 1 ELSE 0  END)
	   SELECT @AttachmentModuleId = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'StockLine';
  BEGIN TRY        
  --BEGIN TRANSACTION        
  -- BEGIN       
	 IF(@IsALTStock  IS NULL OR @IsALTStock = 0)    
	 BEGIN     
	  IF @stockTypeId = 1 -- Qty OH > 0        
	  BEGIN        
	   ;WITH Result AS(        
	   SELECT DISTINCT stl.StockLineId,            
		(ISNULL(stl.ItemMasterId,0)) 'ItemMasterId',        
		(ISNULL(stl.PartNumber,'')) 'MainPartNumber',        
		(ISNULL(stl.PNDescription,'')) 'PartDescription',        
		(ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
		--(ISNULL(rPart.PartNumber,'')) 'RevisedPN',    
		stl.RevicedPNNumber 'RevisedPN',
		(ISNULL(stl.ItemGroup,'')) 'ItemGroup',         
		(ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',        
		CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',        
		stl.QuantityOnHand  as QuantityOnHandnew,        
		CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',        
		stl.QuantityAvailable  as QuantityAvailablenew,        
		CAST(stl.QuantityReserved AS varchar) 'QuantityReserved',        
		stl.QuantityReserved  as QuantityReservednew,        
		CASE WHEN stl.isSerialized = 1 THEN (CASE WHEN ISNULL(stl.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(stl.SerialNumber,'') END) ELSE ISNULL(stl.SerialNumber,'') END AS 'SerialNumber',        
		CASE WHEN ISNULL(stl.IsCustomerStock, 0) = 1 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(stl.customerId,0) > 0 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
		(ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',         
		stl.ControlNumber,        
		stl.IdNumber,        
		(ISNULL(stl.Condition,'')) 'Condition',                 
		(ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',        
		(ISNULL(stl.ShippingReference,'')) 'AWB',               
		stl.ExpirationDate 'ExpirationDate',        
		stl.TagDate 'TagDate',        
		(ISNULL(stl.TaggedByName,'')) 'TaggedByName',        
		(ISNULL(stl.TagType,'')) 'TagType',         
		(ISNULL(stl.TraceableToName,'')) 'TraceableToName',                
		(ISNULL(stl.itemType,'')) 'ItemCategory',         
		stl.ItemTypeId,
		ISNULL(stl.IsNonStock,0) AS IsNonStock,
		CASE WHEN ISNULL(stl.IsNonStock,0) = 1 THEN 'Non-Stock' ELSE 'Stock' END AS ItemType,
		stl.IsActive,                             
		stl.CreatedDate,        
		stl.CreatedBy,        
		stl.PartCertificationNumber,        
		stl.CertifiedBy,        
		stl.CertifiedDate,        
		--stl.UpdatedDate,
		CASE WHEN CAST(stl.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE Cast(stl.UpdatedDate AS DATE) END UpdatedDate,
		--case when CAST(stl.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date) then null else (Cast(DATEADD(SECOND, @BaseUtcOffsetSec, stl.UpdatedDate) as Date))end UpdatedDate,
		stl.UpdatedBy,        
		stl.level1 AS CompanyName,        
		stl.level2 AS BuName,        
		stl.level3 AS DivName,        
		stl.level4 AS DeptName,         
		CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock, 
		CASE WHEN stl.[IsTurnIn] = 1 THEN 'Yes' ELSE 'No' END AS IsTurnIn,
		CASE WHEN ISNULL(stl.IsStkTimeLife,0) =  0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,        
		stl.ObtainFromName AS obtainFrom,        
		stl.OwnerName AS ownerName,        
		MSD.LastMSLevel,        
		MSD.AllMSlevels,        
		stl.WorkOrderId,        
		stl.SubWorkOrderId,        
		stl.WorkOrderNumber,        
	    stl.Location,      
	    stl.LocationId,
	    Stl.Site,
	    Stl.SiteId,
	    Stl.LotNumber,
	    Stl.CustomerName 'CustomerName',
	   ISNULL(stl.CustomerId,0) as CustomerId, 
	   '' AS WorkOrderStage, --Remove Workorderstage due to performance issue  
	   ISNULL(stl.PurchaseOrderNumber,'') AS 'PONumber',
	   ISNULL(stl.RepairOrderNumber,'') AS 'RONumber',
	   --ISNULL(PO.PurchaseOrderNumber,'') 'PONumber',
	   --ISNULL(RO.RepairOrderNumber,'') 'RONumber',
	   ISNULL(stl.ReceiverNumber,'') as 'ReceiverNumber',
	   CAST(stl.QuantityAdjustment AS varchar) 'QuantityAdjustment',
	   CASE WHEN ISNULL(STL.IsDocument, 0) = 0 THEN 'No' ELSE 'Yes' END AS 'IsDocument',
		CASE WHEN ISNULL(stl.IsRepairManagement, 0) = 0 THEN 'No' ELSE 'Yes' END AS IsRepairManagement,
		ISNULL(stl.[IsBatchStock],0) [IsBatchStock],
		stl.[BatchNumber],
		stl.[UnitCost],
		stl.[InventoryGLAccName] AS 'GLAccount',
		CASE 
			WHEN stl.[IsPMA] = 1 THEN 'PMA'
			WHEN stl.[IsDER] = 1 THEN 'DER'
			WHEN stl.[OEM] = 1 THEN 'OEM'
			ELSE ''
		END AS 'PNSource'
	   --CASE WHEN ISNULL((SELECT COUNT(CommonDocumentDetailId) FROM [DBO].[CommonDocumentDetails] CDD WITH(NOLOCK) WHERE stl.StockLineId = CDD.ReferenceId AND CDD.ModuleId = @AttachmentModuleId AND ISNULL(CDD.IsDeleted, 0) = 0), 0) > 0 THEN 'Yes' ELSE 'No' END AS 'IsDocument'
		FROM  dbo.StockLine stl WITH (NOLOCK)        
		  INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId     
		  INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
		  INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		  --LEFT JOIN dbo.PurchaseOrder PO WITH(NOLOCK) ON stl.PurchaseOrderId = PO.PurchaseOrderId
		  --LEFT JOIN dbo.RepairOrder RO WITH(NOLOCK) ON stl.RepairOrderId = RO.RepairOrderId
		WHERE stl.MasterCompanyId=@MasterCompanyId  AND ISNULL(stl.IsDeleted, 0) = 0  AND ISNULL(stl.QuantityOnHand, 0) > 0 AND (@IsNonStock IS NULL OR ISNULL(stl.IsNonStock,0) = @IsNonStock) AND (@StockLineIds IS NULL OR stl.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,',')))
		 AND (@ItemMasterId = 0 OR stl.ItemMasterId = @ItemMasterId)       
		 AND ISNULL(stl.IsParent, 0) = 1 
		 AND stl.IsCustomerStock = CASE WHEN @isElse = 0 THEN @IsCustomerStockInline else stl.IsCustomerStock END          
	   ), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)        
	   SELECT *,
	   (SELECT TOP 1 WOS.Status FROM DBO.WORKORDER WO WITH (NOLOCK) INNER JOIN dbo.WorkOrderStatus wos WITH (NOLOCK) on wo.WorkOrderStatusId = WOS.Id WHERE WO.WorkOrderId = WorkOrderId) as WorkOrderStatus, 
	   (SELECT TOP 1 ISNULL(RS.WorkOrderId, 0) FROM dbo.ReceivingCustomerWork RS WITH (NOLOCK) WHERE RS.StockLineId = r.StockLineId) as rsworkOrderId 
	   INTO #TempResults FROM  Result r       
		 WHERE ((@GlobalFilter <>'' AND ((MainPartNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (PartDescription LIKE '%' +@GlobalFilter+'%') OR         
		  (Manufacturer LIKE '%' +@GlobalFilter+'%') OR             
		  (RevisedPN LIKE '%' +@GlobalFilter+'%') OR              
		  (ItemGroup LIKE '%' +@GlobalFilter+'%') OR              
		  (UnitOfMeasure LIKE '%' +@GlobalFilter+'%') OR                  
		  (QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR        
		  (QuantityAvailable LIKE '%' +@GlobalFilter+'%') OR              
		  (QuantityReserved LIKE '%' +@GlobalFilter+'%') OR        
		  (SerialNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (StocklineNumber LIKE '%' +@GlobalFilter+'%') OR             
		  (ControlNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (TaggedByName LIKE '%' +@GlobalFilter+'%') OR        
		  (TagType LIKE '%' +@GlobalFilter+'%') OR        
		  (TraceableToName LIKE '%' +@GlobalFilter+'%') OR             
		  (IdNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (Condition LIKE '%' +@GlobalFilter+'%') OR        
		  (Location LIKE '%' +@GlobalFilter+'%') OR  
		  (Site LIKE '%' +@GlobalFilter+'%') OR   
		  (AWB LIKE '%' +@GlobalFilter+'%') OR        
		  (ItemCategory LIKE '%' +@GlobalFilter+'%') OR        
		  (IsCustomerStock LIKE '%' +@GlobalFilter+'%') OR     
		  (IsRepairManagement LIKE '%' +@GlobalFilter+'%') OR 
		  (IsTurnIn LIKE '%' +@GlobalFilter+'%') OR 
		  (PartCertificationNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (CertifiedBy LIKE '%' +@GlobalFilter+'%') OR        
		  (CompanyName LIKE '%' +@GlobalFilter+'%') OR        
		  (BuName LIKE '%' +@GlobalFilter+'%') OR        
		  (DivName LIKE '%' +@GlobalFilter+'%') OR        
		  (DeptName LIKE '%' +@GlobalFilter+'%') OR             
		  (obtainFrom LIKE '%' +@GlobalFilter+'%') OR        
		  (ownerName LIKE '%' +@GlobalFilter+'%') OR        
		  (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR        
		  (WorkOrderStage LIKE '%' +@GlobalFilter+'%') OR        
		  (UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
		  (CustomerName LIKE '%' +@GlobalFilter+'%') OR
		  (PONumber LIKE '%' +@GlobalFilter+'%') OR
		  (RONumber LIKE '%' +@GlobalFilter+'%') OR
		  (ReceiverNumber LIKE '%' +@GlobalFilter+'%') OR
		  (QuantityAdjustment LIKE '%' +@GlobalFilter+'%') OR 
		  ([BatchNumber] LIKE '%' +@GlobalFilter+'%') OR	
		  (IsDocument LIKE '%' +@GlobalFilter+'%') OR 
		  ((CAST(UnitCost AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR
		  (GLAccount LIKE '%' +@GlobalFilter+'%') OR
		  (PNSource LIKE '%' +@GlobalFilter+'%') OR
		  (ItemType LIKE '%' +@GlobalFilter+'%')
		  ))
		  OR
		  (@GlobalFilter='' AND (ISNULL(@MainPartNumber,'') ='' OR MainPartNumber LIKE '%' + @MainPartNumber+'%') AND
		  (ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
		  (ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND        
		  (ISNULL(@RevisedPN,'') ='' OR RevisedPN LIKE '%' + @RevisedPN + '%') AND        
		  (ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND        
		  (ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%') AND            
		  (ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND        
		  (ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND        
		  (ISNULL(@QuantityReserved,'') ='' OR QuantityReserved LIKE '%' + @QuantityReserved + '%') AND        
		  (ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND        
		  (ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND             
		  (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND        
		  (ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND        
		  (ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND        
		  (ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND             
		  (ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND        
		  (ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND        
		  (ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND    
		  (ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND    
		  (ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and   
		  (ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS date)=CAST(@ReceivedDate AS date)) AND        
		  (ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND             
		  (ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND        
		  (ISNULL(@ItemCategory,'') ='' OR ItemCategory LIKE '%' + @ItemCategory + '%') AND        
		  (ISNULL(@AWB,'') ='' OR AWB LIKE '%' + @AWB + '%') AND             
		  (ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName + '%') AND        
		  (ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName + '%') AND        
		  (ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName + '%') AND        
		  (ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName + '%') AND        
		  (ISNULL(@PartCertificationNumber,'') ='' OR PartCertificationNumber LIKE '%' + @PartCertificationNumber + '%') AND        
		  (ISNULL(@CertifiedBy,'') ='' OR CertifiedBy LIKE '%' + @CertifiedBy + '%') AND        
		  (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND              
		  (ISNULL(@CertifiedDate,'') ='' OR CAST(CertifiedDate AS Date)=CAST(@CertifiedDate AS date)) AND        
		  (ISNULL(@IsCustomerStock,'') ='' OR IsCustomerStock LIKE '%' + @IsCustomerStock + '%') AND        
		  (ISNULL(@IsRepairManagement,'') ='' OR IsRepairManagement LIKE '%' + @IsRepairManagement + '%') AND  
		  (ISNULL(@IsTurnIn,'') ='' OR IsTurnIn LIKE '%' + @IsTurnIn + '%') AND    
		  (ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND        
		  (ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND        
		  (ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage LIKE '%' + @WorkOrderStage + '%') AND        
		  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND   
		  (ISNULL(@WorkOrderNumber,'') ='' OR WorkOrderNumber LIKE '%' + @WorkOrderNumber + '%') AND
		  (ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%') AND
		  (ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND
		  (ISNULL(@PONumber,'') ='' OR PONumber LIKE '%' + @PONumber + '%') AND
		  (ISNULL(@RONumber,'') ='' OR RONumber LIKE '%' + @RONumber + '%') AND
		  (ISNULL(@ReceiverNumber,'') ='' OR ReceiverNumber LIKE '%' + @ReceiverNumber + '%') AND
		  (ISNULL(@QuantityAdjustment,'') ='' OR QuantityAdjustment LIKE '%' + @QuantityAdjustment + '%') AND
		  (ISNULL(@BatchNumber,'') ='' OR [BatchNumber] LIKE '%' + @BatchNumber+'%') AND			
		  (ISNULL(@IsDocument,'') ='' OR IsDocument LIKE '%' + @IsDocument + '%') and 
		  (IsNull(@UnitCost,'') ='' OR CAST(UnitCost AS varchar(20)) like '%' + @UnitCost+'%' ) AND
		  (ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
		  (ISNULL(@PNSource,'') ='' OR PNSource LIKE '%' + @PNSource + '%') AND
		  (ISNULL(@ItemType,'') ='' OR ItemType LIKE '%' + @ItemType + '%'))
		 )
		SELECT @Count = COUNT(StockLineId) FROM #TempResults
		
		 SELECT *, @Count AS NumberOfItems FROM #TempResults ORDER BY          
		  CASE WHEN (@SortOrder=1  AND @SortColumn='MainPartNumber')  THEN MainPartNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='MainPartNumber')  THEN MainPartNumber END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,           
		  CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,            
		  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,           
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,           
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='IsTurnIn')  THEN IsTurnIn END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTurnIn')  THEN IsTurnIn END DESC,      
		  CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,              
		  CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,        
		  CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,        
		  CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END ASC,        
		  CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC,    
		  CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='Site')  THEN Site END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Site')  THEN Site END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PONumber')  THEN PONumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PONumber')  THEN PONumber END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='RONumber')  THEN RONumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RONumber')  THEN RONumber END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAdjustment')  THEN QuantityAdjustment END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAdjustment')  THEN QuantityAdjustment END DESC,
	      CASE WHEN (@SortOrder=1  AND @SortColumn='IsDocument')  THEN IsDocument END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsDocument')  THEN IsDocument END DESC,
	      CASE WHEN (@SortOrder=1  AND @SortColumn='IsRepairManagement')  THEN IsDocument END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsRepairManagement')  THEN IsDocument END DESC,
		  CASE WHEN (@SortOrder=1 AND @SortColumn='BATCHNUMBER')  THEN BatchNumber END ASC,
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='BATCHNUMBER')  THEN BatchNumber END DESC,
		  CASE WHEN (@SortOrder=1 AND @SortColumn='UnitCost')  THEN CAST(UnitCost AS varchar(20)) END ASC,
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN CAST(UnitCost AS varchar(20)) END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PNSource')  THEN PNSource END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PNSource')  THEN PNSource END DESC
		OFFSET @RecordFROM ROWS         
		FETCH NEXT @PageSize ROWS ONLY        
	  END        
	  ELSE -- ALL        
	  BEGIN        
	  PRINT 'wer'
	   ;WITH Result AS(        
	   SELECT DISTINCT stl.StockLineId,            
		(ISNULL(stl.ItemMasterId,0)) 'ItemMasterId',        
		(ISNULL(stl.PartNumber,'')) 'MainPartNumber',        
		(ISNULL(stl.PNDescription,'')) 'PartDescription',        
		(ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
		(ISNULL(RevicedPNNumber,'')) 'RevisedPN',                  
		(ISNULL(stl.ItemGroup,'')) 'ItemGroup',         
		(ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',        
		CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',        
		stl.QuantityOnHand  as QuantityOnHandnew,        
		CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',        
		stl.QuantityAvailable  as QuantityAvailablenew,        
		CAST(stl.QuantityReserved AS varchar) 'QuantityReserved',        
		stl.QuantityReserved  as QuantityReservednew,        
		(ISNULL(stl.SerialNumber,'')) 'SerialNumber',        
		(ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',         
		stl.ControlNumber,        
		stl.IdNumber,        
		(ISNULL(stl.Condition,'')) 'Condition',                 
		(ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',        
		(ISNULL(stl.ShippingReference,'')) 'AWB',               
		(ISNULL(stl.ExpirationDate,'')) 'ExpirationDate',        
		(ISNULL(stl.TagDate,'')) 'TagDate',        
		(ISNULL(stl.TaggedByName,'')) 'TaggedByName',        
		(ISNULL(stl.TagType,'')) 'TagType',         
		(ISNULL(stl.TraceableToName,'')) 'TraceableToName',                
		(ISNULL(stl.itemType,'')) 'ItemCategory',         
		--(ISNULL(stl.GlAccountName,'')) 'GlAccountName',         
		stl.ItemTypeId,       
		ISNULL(stl.IsNonStock,0) AS IsNonStock,
		CASE WHEN ISNULL(stl.IsNonStock,0) = 1 THEN 'Non-Stock' ELSE 'Stock' END AS ItemType,
		stl.IsActive,                             
		stl.CreatedDate,        
		stl.CreatedBy,        
		stl.PartCertificationNumber,        
		stl.CertifiedBy,        
		stl.CertifiedDate,        
		--stl.UpdatedDate, 
		CASE WHEN CAST(stl.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE Cast(stl.UpdatedDate AS DATE) END UpdatedDate,
		--case when CAST(stl.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DATEADD(SECOND, @BaseUtcOffsetSec, stl.UpdatedDate) as Date))end UpdatedDate,
		stl.UpdatedBy,        
		stl.level1 AS CompanyName,        
		stl.level2 AS BuName,        
		stl.level3 AS DivName,        
		stl.level4 AS DeptName,         
		CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,
		CASE WHEN stl.[IsTurnIn] = 1 THEN 'Yes' ELSE 'No' END AS IsTurnIn,
		CASE WHEN ISNULL(stl.IsStkTimeLife,0) =  0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,
		CASE WHEN ISNULL(stl.IsCustomerStock, 0) = 1 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(stl.customerId,0) > 0 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
		stl.ObtainFromName AS obtainFrom,        
		stl.OwnerName AS ownerName,        
		MSD.LastMSLevel,        
		MSD.AllMSlevels,        
		stl.WorkOrderId,        
		stl.WorkOrderNumber,      
		stl.Location,    
		stl.LocationId,   
		stl.LotNumber,
		Stl.Site,
		Stl.SiteId,
		stl.CustomerName 'CustomerName',
		ISNULL(stl.CustomerId,0) as CustomerId,
		'' as WorkOrderStage,
		ISNULL(stl.PurchaseOrderNumber,'') AS 'PONumber',
	    ISNULL(stl.RepairOrderNumber,'') AS 'RONumber',
		--ISNULL(PO.PurchaseOrderNumber,'') 'PONumber',
		--ISNULL(RO.RepairOrderNumber,'') 'RONumber',
		ISNULL(stl.ReceiverNumber,'') as 'ReceiverNumber',
		CAST(stl.QuantityAdjustment AS varchar) 'QuantityAdjustment',
		CASE WHEN ISNULL(STL.IsDocument, 0) = 0 THEN 'No' ELSE 'Yes' END AS 'IsDocument',
		CASE WHEN stl.IsRepairManagement = 1 THEN 'Yes' ELSE 'No' END AS IsRepairManagement,
		ISNULL(stl.[IsBatchStock],0) [IsBatchStock],
		stl.[BatchNumber],
		stl.[UnitCost],
		stl.[InventoryGLAccName] AS 'GLAccount',
		CASE 
			WHEN stl.[IsPMA] = 1 THEN 'PMA'
			WHEN stl.[IsDER] = 1 THEN 'DER'
			WHEN stl.[OEM] = 1 THEN 'OEM'
			ELSE ''
		END AS 'PNSource'
	    --CASE WHEN ISNULL((SELECT COUNT(CommonDocumentDetailId) FROM [DBO].[CommonDocumentDetails] CDD WITH(NOLOCK) WHERE stl.StockLineId = CDD.ReferenceId AND CDD.ModuleId = @AttachmentModuleId AND ISNULL(CDD.IsDeleted, 0) = 0), 0) > 0 THEN 'Yes' ELSE 'No' END AS 'IsDocument'
		FROM  DBO.StockLine stl WITH (NOLOCK)    
		 INNER JOIN  dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId        
		 INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
		 INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		 --LEFT JOIN dbo.PurchaseOrder PO WITH(NOLOCK) ON stl.PurchaseOrderId = PO.PurchaseOrderId
		 --LEFT JOIN dbo.RepairOrder RO WITH(NOLOCK) ON stl.RepairOrderId = RO.RepairOrderId
		WHERE stl.MasterCompanyId = @MasterCompanyId AND ISNULL(stl.IsParent, 0) = 1 AND ISNULL(stl.IsDeleted, 0) = 0 AND (@stockTypeId IS NULL OR stl.ItemTypeId = @stockTypeId) AND (@IsNonStock IS NULL OR ISNULL(stl.IsNonStock,0) = @IsNonStock) AND (@StockLineIds IS NULL OR stl.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,
  
	   ',')))                
		AND (@ItemMasterId = 0 OR stl.ItemMasterId = @ItemMasterId)        
		--AND stl.IsCustomerStock = CASE WHEN @ISCS = 1 AND @ISECS = 0 THEN 1 WHEN @ISCS = 0 AND @ISECS = 1 THEN 0 else stl.IsCustomerStock END
		AND stl.IsCustomerStock = CASE WHEN @isElse = 0 THEN @IsCustomerStockInline else stl.IsCustomerStock END  
	  ), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)        
	  SELECT *,
	  	(SELECT TOP 1 wos.Status  FROM DBO.WorkOrder wo WITH (NOLOCK) inner join DBO.WorkOrderStatus wos WITH (NOLOCK) on wo.WorkOrderStatusId=wos.Id where wo.WorkOrderId=WorkOrderId) as WorkOrderStatus,        
		(SELECT TOP 1 isnull(RS.WorkOrderId,0)  FROM DBO.ReceivingCustomerWork RS WITH (NOLOCK)  where RS.StockLineId=r.StockLineId) as rsworkOrderId INTO #TempResult FROM  Result r         
	   
	   WHERE (
			(@GlobalFilter <>'' 
		AND (
		(MainPartNumber LIKE '%' +@GlobalFilter+'%') OR        
		(PartDescription LIKE '%' +@GlobalFilter+'%') OR         
		(Manufacturer LIKE '%' +@GlobalFilter+'%') OR             
		(RevisedPN LIKE '%' +@GlobalFilter+'%') OR              
		(ItemGroup LIKE '%' +@GlobalFilter+'%') OR              
		(UnitOfMeasure LIKE '%' +@GlobalFilter+'%') OR                  
		(QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR        
		(QuantityAvailable LIKE '%' +@GlobalFilter+'%') OR        
		(QuantityReserved LIKE '%' +@GlobalFilter+'%') OR        
		(SerialNumber LIKE '%' +@GlobalFilter+'%') OR        
		(StocklineNumber LIKE '%' +@GlobalFilter+'%') OR             
		(ControlNumber LIKE '%' +@GlobalFilter+'%') OR        
		(TaggedByName LIKE '%' +@GlobalFilter+'%') OR        
		(LastMSLevel LIKE '%' +@GlobalFilter+'%') OR              
		(TagType LIKE '%' +@GlobalFilter+'%') OR        
		(TraceableToName LIKE '%' +@GlobalFilter+'%') OR             
		(IdNumber LIKE '%' +@GlobalFilter+'%') OR        
		(Condition LIKE '%' +@GlobalFilter+'%') OR        
		(Location LIKE '%' +@GlobalFilter+'%') OR 
		(Site LIKE '%' +@GlobalFilter+'%') OR   
		(AWB LIKE '%' +@GlobalFilter+'%') OR        
		(ItemCategory LIKE '%' +@GlobalFilter+'%') OR        
		(IsCustomerStock LIKE '%' +@GlobalFilter+'%') OR  
		(IsRepairManagement LIKE '%' +@GlobalFilter+'%') OR   
		(IsTurnIn LIKE '%' +@GlobalFilter+'%') OR 
		(PartCertificationNumber LIKE '%' +@GlobalFilter+'%') OR        
		(CertifiedBy LIKE '%' +@GlobalFilter+'%') OR        
		(CompanyName LIKE '%' +@GlobalFilter+'%') OR        
		(BuName LIKE '%' +@GlobalFilter+'%') OR        
		(DivName LIKE '%' +@GlobalFilter+'%') OR        
		(DeptName LIKE '%' +@GlobalFilter+'%') OR             
		(obtainFrom LIKE '%' +@GlobalFilter+'%') OR        
		(ownerName LIKE '%' +@GlobalFilter+'%') OR        
		(WorkOrderStage LIKE '%' +@GlobalFilter+'%') OR        
		(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
		(CustomerName LIKE '%' +@GlobalFilter+'%') OR
		(PONumber LIKE '%' +@GlobalFilter+'%') OR
		(RONumber LIKE '%' +@GlobalFilter+'%') OR
		(ReceiverNumber LIKE '%' +@GlobalFilter+'%') OR
		(QuantityAdjustment LIKE '%' +@GlobalFilter+'%') OR 
		([BatchNumber] LIKE '%' +@GlobalFilter+'%') OR
		(IsDocument LIKE '%' +@GlobalFilter+'%') OR
		((CAST(UnitCost AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR
		(GLAccount LIKE '%' +@GlobalFilter+'%') OR
		(PNSource LIKE '%' +@GlobalFilter+'%') OR
		(ItemType LIKE '%' +@GlobalFilter+'%')
		))
		OR
		(@GlobalFilter='' AND (ISNULL(@MainPartNumber,'') ='' OR MainPartNumber LIKE '%' + @MainPartNumber+'%') AND
		(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
		(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND        
		(ISNULL(@RevisedPN,'') ='' OR RevisedPN LIKE '%' + @RevisedPN + '%') AND        
		(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND        
		(ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%') AND            
		(ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND        
		(ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND        
		(ISNULL(@QuantityReserved,'') ='' OR QuantityReserved LIKE '%' + @QuantityReserved + '%') AND        
		(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND        
		(ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND             
		(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND        
		(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND        
		(ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND        
		(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND             
		(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND        
		(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND        
		(ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND        
		(ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND    
		(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS date)=CAST(@ReceivedDate AS date)) AND        
		(ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND             
		(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND        
		(ISNULL(@ItemCategory,'') ='' OR ItemCategory LIKE '%' + @ItemCategory + '%') AND        
		(ISNULL(@AWB,'') ='' OR AWB LIKE '%' + @AWB + '%') AND             
		(ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName + '%') AND        
		(ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName + '%') AND        
		(ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName + '%') AND        
		(ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName + '%') AND        
		(ISNULL(@PartCertificationNumber,'') ='' OR PartCertificationNumber LIKE '%' + @PartCertificationNumber + '%') AND        
		(ISNULL(@CertifiedBy,'') ='' OR CertifiedBy LIKE '%' + @CertifiedBy + '%') AND        
		(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND              
		(ISNULL(@CertifiedDate,'') ='' OR CAST(CertifiedDate AS Date)=CAST(@CertifiedDate AS date)) AND        
		(ISNULL(@IsCustomerStock,'') ='' OR IsCustomerStock LIKE '%' + @IsCustomerStock + '%') AND           
		(ISNULL(@IsRepairManagement,'') ='' OR IsRepairManagement LIKE '%' + @IsRepairManagement + '%') AND
		(ISNULL(@IsTurnIn,'') ='' OR IsTurnIn LIKE '%' + @IsTurnIn + '%') AND    
		(ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND        
		(ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND        
		(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and        
		(ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage like '%' + @WorkOrderStage+'%') and        
		(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND  
		(ISNULL(@WorkOrderNumber,'') ='' OR WorkOrderNumber LIKE '%' + @WorkOrderNumber + '%') AND
		(ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%') AND
		(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%') AND
		(ISNULL(@PONumber,'') ='' OR PONumber LIKE '%' + @PONumber + '%') AND
		(ISNULL(@RONumber,'') ='' OR RONumber LIKE '%' + @RONumber + '%') AND
		(ISNULL(@ReceiverNumber,'') ='' OR ReceiverNumber LIKE '%' + @ReceiverNumber + '%') AND
		(ISNULL(@QuantityAdjustment,'') ='' OR QuantityAdjustment LIKE '%' + @QuantityAdjustment + '%') AND
		(ISNULL(@BatchNumber,'') ='' OR [BatchNumber] LIKE '%' + @BatchNumber+'%') 	
		AND (ISNULL(@IsDocument,'') ='' OR IsDocument LIKE '%' + @IsDocument + '%') 
		AND (IsNull(@UnitCost,'') ='' OR CAST(UnitCost AS varchar(20)) like '%' + @UnitCost+'%' )AND
		(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
		(ISNULL(@PNSource,'') ='' OR PNSource LIKE '%' + @PNSource + '%') AND
		(ISNULL(@ItemType,'') ='' OR ItemType LIKE '%' + @ItemType + '%'))
	   )
	   SELECT @Count = COUNT(StockLineId) FROM #TempResult
        
	   SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY          
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN MainPartNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN MainPartNumber END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,           
	   CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,            
	   CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END DESC,         
             
	   CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,           
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,           
	   CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,   
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsTurnIn')  THEN IsTurnIn END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTurnIn')  THEN IsTurnIn END DESC,      
	   CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC,        
	   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,        
	   CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END ASC,        
	   CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END DESC,        
	   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,    
	   CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='Site')  THEN Site END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='Site')  THEN Site END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PONumber')  THEN PONumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PONumber')  THEN PONumber END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='RONumber')  THEN RONumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='RONumber')  THEN RONumber END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAdjustment')  THEN QuantityAdjustment END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAdjustment')  THEN QuantityAdjustment END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsDocument')  THEN IsDocument END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsDocument')  THEN IsDocument END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsRepairManagement')  THEN IsDocument END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsRepairManagement')  THEN IsDocument END DESC,
	   CASE WHEN (@SortOrder=1 AND @SortColumn='BATCHNUMBER')  THEN BatchNumber END ASC,
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='BATCHNUMBER')  THEN BatchNumber END DESC,
	   CASE WHEN (@SortOrder=1 AND @SortColumn='UnitCost')  THEN CAST(UnitCost AS varchar(20)) END ASC,
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN CAST(UnitCost AS varchar(20)) END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PNSource')  THEN PNSource END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PNSource')  THEN PNSource END DESC   
            
		OFFSET @RecordFROM ROWS         
		FETCH NEXT @PageSize ROWS ONLY        
	  END        
	 END    
	 ELSE    
	 BEGIN    
	  IF @stockTypeId = 1 -- Qty OH > 0        
	  BEGIN        
		  ;WITH Result AS(        
		 SELECT DISTINCT stl.StockLineId,            
		(ISNULL(stl.ItemMasterId,0)) 'ItemMasterId',        
		(ISNULL(IMAl.PartNumber,'')) 'MainPartNumber',       
		(ISNULL(stl.partnumber,'')) 'PartNumber',    
		(ISNULL(stl.PNDescription,'')) 'PartDescription',        
		(ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
		(ISNULL(RevicedPNNumber,'')) 'RevisedPN',                  
		(ISNULL(stl.ItemGroup,'')) 'ItemGroup',         
		(ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',        
		CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',        
		stl.QuantityOnHand  as QuantityOnHandnew,   
		CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',        
		stl.QuantityAvailable  as QuantityAvailablenew,        
		CAST(stl.QuantityReserved AS varchar) 'QuantityReserved',        
		stl.QuantityReserved  as QuantityReservednew,        
		CASE WHEN stl.isSerialized = 1 THEN (CASE WHEN ISNULL(stl.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(stl.SerialNumber,'') END) ELSE ISNULL(stl.SerialNumber,'') END AS 'SerialNumber',        
		CASE WHEN ISNULL(stl.IsCustomerStock, 0) = 1 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(stl.customerId,0) > 0 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
		(ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',         
		stl.ControlNumber,        
		stl.IdNumber,        
		(ISNULL(stl.Condition,'')) 'Condition',                 
		(ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',        
		(ISNULL(stl.ShippingReference,'')) 'AWB',               
		stl.ExpirationDate 'ExpirationDate',        
		stl.TagDate 'TagDate',        
		(ISNULL(stl.TaggedByName,'')) 'TaggedByName',        
		(ISNULL(stl.TagType,'')) 'TagType',         
		(ISNULL(stl.TraceableToName,'')) 'TraceableToName',                
		(ISNULL(stl.itemType,'')) 'ItemCategory',         
		stl.ItemTypeId,        
		ISNULL(stl.IsNonStock,0) AS IsNonStock,
		CASE WHEN ISNULL(stl.IsNonStock,0) = 1 THEN 'Non-Stock' ELSE 'Stock' END AS ItemType,
		stl.IsActive,                             
		stl.CreatedDate,        
		stl.CreatedBy,        
		stl.PartCertificationNumber,        
		stl.CertifiedBy,          stl.CertifiedDate,        
		--stl.UpdatedDate,  
		CASE WHEN CAST(stl.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE Cast(stl.UpdatedDate AS DATE) END UpdatedDate,
		--case when CAST(stl.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DATEADD(SECOND, @BaseUtcOffsetSec, stl.UpdatedDate)  as Date))end UpdatedDate,
		stl.UpdatedBy,        
		stl.level1 AS CompanyName,        
		stl.level2 AS BuName,        
		stl.level3 AS DivName,        
		stl.level4 AS DeptName,         
		CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,
		CASE WHEN stl.[IsTurnIn] = 1 THEN 'Yes' ELSE 'No' END AS IsTurnIn,
		CASE WHEN ISNULL(stl.IsStkTimeLife,0) =  0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,
		stl.ObtainFromName AS obtainFrom,        
		stl.OwnerName AS ownerName,        
		MSD.LastMSLevel,        
		MSD.AllMSlevels,        
		stl.WorkOrderId,        
		stl.SubWorkOrderId,        
		stl.WorkOrderNumber,        
	   stl.Location,      
	   stl.LocationId,
	   stl.LotNumber,
	    Stl.Site,
	   Stl.SiteId,
	   ISNULL(stl.CustomerId,0) as CustomerId,
	   '' AS WorkOrderStage,
	   ISNULL(stl.PurchaseOrderNumber,'') AS 'PONumber',
	   ISNULL(stl.RepairOrderNumber,'') AS 'RONumber',
	   --ISNULL(PO.PurchaseOrderNumber,'') 'PONumber',
	   --ISNULL(RO.RepairOrderNumber,'') 'RONumber',
	   ISNULL(stl.ReceiverNumber,'') as 'ReceiverNumber',
	   CAST(stl.QuantityAdjustment AS varchar) 'QuantityAdjustment',
	   CASE WHEN ISNULL(STL.IsDocument, 0) = 0 THEN 'No' ELSE 'Yes' END AS 'IsDocument',
	   CASE WHEN stl.IsRepairManagement = 1 THEN 'Yes' ELSE 'No' END AS IsRepairManagement,
	   ISNULL(stl.[IsBatchStock],0) [IsBatchStock],
	   stl.[BatchNumber],
	   stl.[UnitCost],
	   stl.[InventoryGLAccName] AS 'GLAccount',
	   CASE 
			WHEN stl.[IsPMA] = 1 THEN 'PMA'
			WHEN stl.[IsDER] = 1 THEN 'DER'
			WHEN stl.[OEM] = 1 THEN 'OEM'
			ELSE ''
		END AS 'PNSource'
	   --CASE WHEN ISNULL((SELECT COUNT(CommonDocumentDetailId) FROM [DBO].[CommonDocumentDetails] CDD WITH(NOLOCK) WHERE stl.StockLineId = CDD.ReferenceId AND CDD.ModuleId = @AttachmentModuleId AND ISNULL(CDD.IsDeleted, 0) = 0), 0) > 0 THEN 'Yes' ELSE 'No' END AS 'IsDocument'
	  FROM Nha_Tla_Alt_Equ_ItemMapping ALT    
	   INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON ALT.MappingItemMasterId = im.ItemMasterId --ALTPART    
	   INNER JOIN DBO.ItemMaster IMAl WITH (NOLOCK) ON ALT.ItemMasterId = IMAl.ItemMasterId --MAINPART    
	   INNER JOIN DBO.StockLine stl WITH (NOLOCK) ON im.ItemMasterId = stl.ItemMasterId    
	   INNER JOIN DBO.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId        
	   INNER JOIN DBO.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
	   INNER JOIN DBO.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
	   --LEFT JOIN dbo.PurchaseOrder PO WITH(NOLOCK) ON stl.PurchaseOrderId = PO.PurchaseOrderId
	   --LEFT JOIN dbo.RepairOrder RO WITH(NOLOCK) ON stl.RepairOrderId = RO.RepairOrderId
		WHERE ALT.MappingType = 1 AND ALT.IsDeleted = 0 AND ALT.IsActive = 1 AND stl.MasterCompanyId=@MasterCompanyId  AND ((stl.IsDeleted=0 ) AND (stl.QuantityOnHand > 0)) AND (@IsNonStock IS NULL OR ISNULL(stl.IsNonStock,0) = @IsNonStock) AND (@StockLineIds IS NULL OR stl.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,',')))
		 AND (@ItemMasterId = 0 OR stl.ItemMasterId = @ItemMasterId)       
		 AND stl.IsParent = 1 
		 --AND stl.IsCustomerStock = CASE WHEN @ISCS = 1 AND @ISECS = 0 THEN 1 WHEN @ISCS = 0 AND @ISECS = 1 THEN 0 else stl.IsCustomerStock END          
		 AND stl.IsCustomerStock = CASE WHEN @isElse = 0 THEN @IsCustomerStockInline else stl.IsCustomerStock END  
	   ), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)        
	   SELECT *,
	   (SELECT TOP 1 WOS.Status FROM DBO.WORKORDER WO WITH (NOLOCK) INNER JOIN dbo.WorkOrderStatus wos WITH (NOLOCK) on wo.WorkOrderStatusId = WOS.Id WHERE WO.WorkOrderId = WorkOrderId) as WorkOrderStatus,        
		(SELECT TOP 1 ISNULL(RS.WorkOrderId, 0) FROM dbo.ReceivingCustomerWork RS WITH (NOLOCK) WHERE RS.StockLineId = r.StockLineId) as rsworkOrderId INTO #TempALTResults FROM  Result r       
		 WHERE ((@GlobalFilter <>'' AND ((MainPartNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (PartNumber LIKE '%' +@GlobalFilter+'%') OR         
		  (PartDescription LIKE '%' +@GlobalFilter+'%') OR         
		  (Manufacturer LIKE '%' +@GlobalFilter+'%') OR             
		  (RevisedPN LIKE '%' +@GlobalFilter+'%') OR              
		  (ItemGroup LIKE '%' +@GlobalFilter+'%') OR              
		  (UnitOfMeasure LIKE '%' +@GlobalFilter+'%') OR                  
		  (QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR        
		  (QuantityAvailable LIKE '%' +@GlobalFilter+'%') OR              
		  (QuantityReserved LIKE '%' +@GlobalFilter+'%') OR        
		  (SerialNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (StocklineNumber LIKE '%' +@GlobalFilter+'%') OR             
		  (ControlNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (TaggedByName LIKE '%' +@GlobalFilter+'%') OR        
		  (TagType LIKE '%' +@GlobalFilter+'%') OR        
		  (TraceableToName LIKE '%' +@GlobalFilter+'%') OR             
		  (IdNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (Condition LIKE '%' +@GlobalFilter+'%') OR        
		  (Location LIKE '%' +@GlobalFilter+'%') OR
		  (Site LIKE '%' +@GlobalFilter+'%') OR   
		  (AWB LIKE '%' +@GlobalFilter+'%') OR        
		  (ItemCategory LIKE '%' +@GlobalFilter+'%') OR        
		  (IsCustomerStock LIKE '%' +@GlobalFilter+'%') OR  
		  (IsRepairManagement LIKE '%' +@GlobalFilter+'%') OR 
		  (IsTurnIn LIKE '%' +@GlobalFilter+'%') OR 
		  (PartCertificationNumber LIKE '%' +@GlobalFilter+'%') OR        
		  (CertifiedBy LIKE '%' +@GlobalFilter+'%') OR        
		  (CompanyName LIKE '%' +@GlobalFilter+'%') OR        
		  (BuName LIKE '%' +@GlobalFilter+'%') OR        
		  (DivName LIKE '%' +@GlobalFilter+'%') OR        
		  (DeptName LIKE '%' +@GlobalFilter+'%') OR             
		  (obtainFrom LIKE '%' +@GlobalFilter+'%') OR        
		  (ownerName LIKE '%' +@GlobalFilter+'%') OR        
		  (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR        
		  (WorkOrderStage LIKE '%' +@GlobalFilter+'%') OR        
		  (UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
		  (PONumber LIKE '%' +@GlobalFilter+'%') OR
		  (RONumber LIKE '%' +@GlobalFilter+'%') OR
		  (ReceiverNumber LIKE '%' +@GlobalFilter+'%') OR
		  (QuantityAdjustment LIKE '%' +@GlobalFilter+'%') OR 
		  ([BatchNumber] LIKE '%' +@GlobalFilter+'%') OR
		  (IsDocument LIKE '%' +@GlobalFilter+'%') OR
		  ((CAST(UnitCost AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR
		  (GLAccount LIKE '%' +@GlobalFilter+'%') OR
		  (PNSource LIKE '%' +@GlobalFilter+'%') OR
		  (ItemType LIKE '%' +@GlobalFilter+'%')))
		  OR
		  (@GlobalFilter='' AND (ISNULL(@MainPartNumber,'') ='' OR MainPartNumber LIKE '%' + @MainPartNumber+'%') AND
		  (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber + '%') AND
		  (ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND        
		  (ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND        
		  (ISNULL(@RevisedPN,'') ='' OR RevisedPN LIKE '%' + @RevisedPN + '%') AND        
		  (ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND        
		  (ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%') AND            
		  (ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND        
		  (ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND        
		  (ISNULL(@QuantityReserved,'') ='' OR QuantityReserved LIKE '%' + @QuantityReserved + '%') AND        
		  (ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND        
		  (ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND             
		  (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND        
		  (ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND        
		  (ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND        
		  (ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND             
		  (ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND        
		  (ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND        
		  (ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND   
		  (ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND    
		  (ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and        
		  (ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS date)=CAST(@ReceivedDate AS date)) AND        
		  (ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND             
		  (ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND        
		  (ISNULL(@ItemCategory,'') ='' OR ItemCategory LIKE '%' + @ItemCategory + '%') AND        
		  (ISNULL(@AWB,'') ='' OR AWB LIKE '%' + @AWB + '%') AND             
		  (ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName + '%') AND        
		  (ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName + '%') AND        
		  (ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName + '%') AND        
		  (ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName + '%') AND        
		  (ISNULL(@PartCertificationNumber,'') ='' OR PartCertificationNumber LIKE '%' + @PartCertificationNumber + '%') AND        
		  (ISNULL(@CertifiedBy,'') ='' OR CertifiedBy LIKE '%' + @CertifiedBy + '%') AND        
		  (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND              
		  (ISNULL(@CertifiedDate,'') ='' OR CAST(CertifiedDate AS Date)=CAST(@CertifiedDate AS date)) AND        
		  (ISNULL(@IsCustomerStock,'') ='' OR IsCustomerStock LIKE '%' + @IsCustomerStock + '%') AND          
		  (ISNULL(@IsRepairManagement,'') ='' OR IsRepairManagement LIKE '%' + @IsRepairManagement + '%') AND
		  (ISNULL(@IsTurnIn,'') ='' OR IsTurnIn LIKE '%' + @IsTurnIn + '%') AND    
		  (ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND        
		  (ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND        
		  (ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage LIKE '%' + @WorkOrderStage + '%') AND        
		  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND  
		  (ISNULL(@WorkOrderNumber,'') ='' OR WorkOrderNumber LIKE '%' + @WorkOrderNumber + '%') AND
		  (ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%') AND
		  (ISNULL(@PONumber,'') ='' OR PONumber LIKE '%' + @PONumber + '%') AND
		  (ISNULL(@RONumber,'') ='' OR RONumber LIKE '%' + @RONumber + '%') AND
		  (ISNULL(@ReceiverNumber,'') ='' OR ReceiverNumber LIKE '%' + @ReceiverNumber + '%') AND
		  (ISNULL(@QuantityAdjustment,'') ='' OR QuantityAdjustment LIKE '%' + @QuantityAdjustment + '%') AND
		  (ISNULL(@BatchNumber,'') ='' OR [BatchNumber] LIKE '%' + @BatchNumber+'%') AND		
		  (ISNULL(@IsDocument,'') ='' OR IsDocument LIKE '%' + @IsDocument + '%') AND
		  (IsNull(@UnitCost,'') ='' OR CAST(UnitCost AS varchar(20)) like '%' + @UnitCost+'%' ) AND
		  (ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
		  (ISNULL(@PNSource,'') ='' OR PNSource LIKE '%' + @PNSource + '%') AND
		  (ISNULL(@ItemType,'') ='' OR ItemType LIKE '%' + @ItemType + '%'))
		 )
	   SELECT @Count = COUNT(StockLineId) FROM #TempALTResults
        
	   SELECT *, @Count AS NumberOfItems FROM #TempALTResults ORDER BY        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='MainPartNumber')  THEN MainPartNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='MainPartNumber')  THEN MainPartNumber END DESC,      
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,           
		  CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,            
		  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,           
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,           
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,      
		  CASE WHEN (@SortOrder=1  AND @SortColumn='IsTurnIn')  THEN IsTurnIn END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTurnIn')  THEN IsTurnIn END DESC,      
		  CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,              
		  CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,        
		  CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,        
		  CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END ASC,        
		  CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END DESC,        
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC,    
		  CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='Site')  THEN Site END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Site')  THEN Site END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PONumber')  THEN PONumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PONumber')  THEN PONumber END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='RONumber')  THEN RONumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RONumber')  THEN RONumber END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAdjustment')  THEN QuantityAdjustment END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAdjustment')  THEN QuantityAdjustment END DESC,
	      CASE WHEN (@SortOrder=1  AND @SortColumn='IsDocument')  THEN IsDocument END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsDocument')  THEN IsDocument END DESC,
	      CASE WHEN (@SortOrder=1  AND @SortColumn='IsRepairManagement')  THEN IsDocument END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsRepairManagement')  THEN IsDocument END DESC,
		  CASE WHEN (@SortOrder=1 AND @SortColumn='BATCHNUMBER')  THEN BatchNumber END ASC,
	      CASE WHEN (@SortOrder=-1 AND @SortColumn='BATCHNUMBER')  THEN BatchNumber END DESC,
		  CASE WHEN (@SortOrder=1 AND @SortColumn='UnitCost')  THEN CAST(UnitCost AS varchar(20)) END ASC,
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN CAST(UnitCost AS varchar(20)) END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
		  CASE WHEN (@SortOrder=1  AND @SortColumn='PNSource')  THEN PNSource END ASC,        
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PNSource')  THEN PNSource END DESC		  
            
		OFFSET @RecordFROM ROWS         
		FETCH NEXT @PageSize ROWS ONLY        
	  END        
	  ELSE -- ALL        
	  BEGIN        
	   ;WITH Result AS(        
	   SELECT DISTINCT stl.StockLineId,            
		(ISNULL(stl.ItemMasterId,0)) 'ItemMasterId',        
		(ISNULL(IMAl.PartNumber,'')) 'MainPartNumber',        
		(ISNULL(stl.partnumber,'')) 'PartNumber',    
		(ISNULL(stl.PNDescription,'')) 'PartDescription',        
		(ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
		(ISNULL(stl.RevicedPNNumber,'')) 'RevisedPN',                  
		(ISNULL(stl.ItemGroup,'')) 'ItemGroup',         
		(ISNULL(stl.UnitOfMeasure,'')) 'UnitOfMeasure',        
		CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',        
		stl.QuantityOnHand  as QuantityOnHandnew,        
		CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',        
		stl.QuantityAvailable  as QuantityAvailablenew,        
		CAST(stl.QuantityReserved AS varchar) 'QuantityReserved',        
		stl.QuantityReserved  as QuantityReservednew,        
		(ISNULL(stl.SerialNumber,'')) 'SerialNumber',        
		(ISNULL(stl.StockLineNumber,'')) 'StocklineNumber',         
		stl.ControlNumber,        
		stl.IdNumber,        
		(ISNULL(stl.Condition,'')) 'Condition',                 
		(ISNULL(stl.ReceivedDate,'')) 'ReceivedDate',        
		(ISNULL(stl.ShippingReference,'')) 'AWB',               
		(ISNULL(stl.ExpirationDate,'')) 'ExpirationDate',        
		(ISNULL(stl.TagDate,'')) 'TagDate',        
		(ISNULL(stl.TaggedByName,'')) 'TaggedByName',        
		(ISNULL(stl.TagType,'')) 'TagType',         
		(ISNULL(stl.TraceableToName,'')) 'TraceableToName',                
		(ISNULL(stl.itemType,'')) 'ItemCategory',         
		stl.ItemTypeId,        
		ISNULL(stl.IsNonStock,0) AS IsNonStock,
		CASE WHEN ISNULL(stl.IsNonStock,0) = 1 THEN 'Non-Stock' ELSE 'Stock' END AS ItemType,
		stl.IsActive,                             
		stl.CreatedDate,        
		stl.CreatedBy,        
		stl.PartCertificationNumber,        
		stl.CertifiedBy,        
		stl.CertifiedDate,        
		--stl.UpdatedDate, 
		CASE WHEN CAST(stl.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE Cast(stl.UpdatedDate AS DATE) END UpdatedDate,
		--case when CAST(stl.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DATEADD(SECOND, @BaseUtcOffsetSec, stl.UpdatedDate)  as Date))end UpdatedDate,
		stl.UpdatedBy,        
		stl.level1 AS CompanyName,        
		stl.level2 AS BuName,        
		stl.level3 AS DivName,        
		stl.level4 AS DeptName,         
		CASE WHEN stl.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,        
		CASE WHEN stl.[IsTurnIn] = 1 THEN 'Yes' ELSE 'No' END AS IsTurnIn,
		CASE WHEN ISNULL(stl.IsStkTimeLife,0) =  0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,
		CASE WHEN ISNULL(stl.IsCustomerStock, 0) = 1 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(stl.customerId,0) > 0 AND ISNULL(stl.QuantityAvailable, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
		stl.ObtainFromName AS obtainFrom,        
		stl.OwnerName AS ownerName,        
		MSD.LastMSLevel,        
		MSD.AllMSlevels,        
		stl.WorkOrderId,        
		stl.WorkOrderNumber,      
		stl.Location,    
		stl.LocationId,    
		stl.LotNumber,
		Stl.Site,
		Stl.SiteId,
		ISNULL(stl.CustomerId,0) as CustomerId,
		'' as WorkOrderStage,
		ISNULL(stl.PurchaseOrderNumber,'') AS 'PONumber',
	    ISNULL(stl.RepairOrderNumber,'') AS 'RONumber',
		--ISNULL(PO.PurchaseOrderNumber,'') 'PONumber',
	    --ISNULL(RO.RepairOrderNumber,'') 'RONumber',
	    ISNULL(stl.ReceiverNumber,'') as 'ReceiverNumber',
		CAST(stl.QuantityAdjustment AS varchar) 'QuantityAdjustment',
		CASE WHEN ISNULL(STL.IsDocument, 0) = 0 THEN 'No' ELSE 'Yes' END AS 'IsDocument',
		CASE WHEN stl.IsRepairManagement = 1 THEN 'Yes' ELSE 'No' END AS IsRepairManagement,
		ISNULL(stl.[IsBatchStock],0) [IsBatchStock],
		stl.[BatchNumber],
		stl.[UnitCost],
		stl.[InventoryGLAccName] AS 'GLAccount',
		CASE 
			WHEN stl.[IsPMA] = 1 THEN 'PMA'
			WHEN stl.[IsDER] = 1 THEN 'DER'
			WHEN stl.[OEM] = 1 THEN 'OEM'
			ELSE ''
		END AS 'PNSource'
	    --CASE WHEN ISNULL((SELECT COUNT(CommonDocumentDetailId) FROM [DBO].[CommonDocumentDetails] CDD WITH(NOLOCK) WHERE stl.StockLineId = CDD.ReferenceId AND CDD.ModuleId = @AttachmentModuleId AND ISNULL(CDD.IsDeleted, 0) = 0), 0) > 0 THEN 'Yes' ELSE 'No' END AS 'IsDocument'
		FROM Nha_Tla_Alt_Equ_ItemMapping ALT    
	   INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON ALT.MappingItemMasterId = im.ItemMasterId --ALTPART    
	   INNER JOIN DBO.ItemMaster IMAl WITH (NOLOCK) ON ALT.ItemMasterId = IMAl.ItemMasterId --MAINPART    
	   INNER JOIN DBO.StockLine stl WITH (NOLOCK) ON im.ItemMasterId = stl.ItemMasterId    
	   INNER JOIN DBO.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId        
	   INNER JOIN DBO.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
	   INNER JOIN DBO.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
	   --LEFT JOIN dbo.PurchaseOrder PO WITH(NOLOCK) ON stl.PurchaseOrderId = PO.PurchaseOrderId
	   --LEFT JOIN dbo.RepairOrder RO WITH(NOLOCK) ON stl.RepairOrderId = RO.RepairOrderId
	 WHERE ALT.MappingType =1 AND ALT.IsDeleted = 0 AND ALT.IsActive = 1 AND stl.MasterCompanyId = @MasterCompanyId AND stl.IsParent = 1 AND ((stl.IsDeleted = 0) AND (@stockTypeId IS NULL OR im.ItemTypeId = @stockTypeId)) AND (@IsNonStock IS NULL OR ISNULL(stl.IsNonStock,0) = @IsNonStock) AND (@StockLineIds IS NULL OR stl
  
	.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,    
	   ',')))                
		AND (@ItemMasterId = 0 OR stl.ItemMasterId = @ItemMasterId)        
		--AND stl.IsCustomerStock = CASE WHEN @ISCS = 1 AND @ISECS = 0 THEN 1 WHEN @ISCS = 0 AND @ISECS = 1 THEN 0 else stl.IsCustomerStock END
		AND stl.IsCustomerStock = CASE WHEN @isElse = 0 THEN @IsCustomerStockInline else stl.IsCustomerStock END  
	  ), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)        
	  SELECT *,
	   (SELECT TOP 1 wos.Status  FROM DBO.WorkOrder wo WITH (NOLOCK) inner join DBO.WorkOrderStatus wos WITH (NOLOCK) on wo.WorkOrderStatusId=wos.Id where wo.WorkOrderId = WorkOrderId) as WorkOrderStatus,        
	   (SELECT TOP 1 isnull(RS.WorkOrderId,0)  FROM DBO.ReceivingCustomerWork RS WITH (NOLOCK)  where RS.StockLineId=r.StockLineId) as rsworkOrderId
		INTO #TempALTResult FROM  Result r       
	   WHERE ((@GlobalFilter <>'' AND ((MainPartNumber LIKE '%' +@GlobalFilter+'%') OR        
		(PartNumber LIKE '%' +@GlobalFilter+'%') OR    
		(PartDescription LIKE '%' +@GlobalFilter+'%') OR         
		(Manufacturer LIKE '%' +@GlobalFilter+'%') OR             
		(RevisedPN LIKE '%' +@GlobalFilter+'%') OR              
		(ItemGroup LIKE '%' +@GlobalFilter+'%') OR              
		(UnitOfMeasure LIKE '%' +@GlobalFilter+'%') OR                  
		(QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR        
		(QuantityAvailable LIKE '%' +@GlobalFilter+'%') OR        
		(QuantityReserved LIKE '%' +@GlobalFilter+'%') OR        
		(SerialNumber LIKE '%' +@GlobalFilter+'%') OR        
		(StocklineNumber LIKE '%' +@GlobalFilter+'%') OR             
		(ControlNumber LIKE '%' +@GlobalFilter+'%') OR        
		(TaggedByName LIKE '%' +@GlobalFilter+'%') OR        
		(LastMSLevel LIKE '%' +@GlobalFilter+'%') OR              
		(TagType LIKE '%' +@GlobalFilter+'%') OR        
		(TraceableToName LIKE '%' +@GlobalFilter+'%') OR             
		(IdNumber LIKE '%' +@GlobalFilter+'%') OR        
		(Condition LIKE '%' +@GlobalFilter+'%') OR        
		(Location LIKE '%' +@GlobalFilter+'%') OR  
		(Site LIKE '%' +@GlobalFilter+'%') OR   
		(AWB LIKE '%' +@GlobalFilter+'%') OR        
		(ItemCategory LIKE '%' +@GlobalFilter+'%') OR        
		(IsCustomerStock LIKE '%' +@GlobalFilter+'%') OR    
		  (IsRepairManagement LIKE '%' +@GlobalFilter+'%') OR 
		(IsTurnIn LIKE '%' +@GlobalFilter+'%') OR 
		(PartCertificationNumber LIKE '%' +@GlobalFilter+'%') OR        
		(CertifiedBy LIKE '%' +@GlobalFilter+'%') OR        
		(CompanyName LIKE '%' +@GlobalFilter+'%') OR        
		(BuName LIKE '%' +@GlobalFilter+'%') OR        
		(DivName LIKE '%' +@GlobalFilter+'%') OR        
		(DeptName LIKE '%' +@GlobalFilter+'%') OR             
		(obtainFrom LIKE '%' +@GlobalFilter+'%') OR        
		(ownerName LIKE '%' +@GlobalFilter+'%') OR        
		(WorkOrderStage LIKE '%' +@GlobalFilter+'%') OR        
		(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
		(PONumber LIKE '%' +@GlobalFilter+'%') OR
		(RONumber LIKE '%' +@GlobalFilter+'%') OR
		(ReceiverNumber LIKE '%' +@GlobalFilter+'%') OR
		(QuantityAdjustment LIKE '%' +@GlobalFilter+'%') OR 
		([BatchNumber] LIKE '%' +@GlobalFilter+'%')	OR		
		(IsDocument LIKE '%' +@GlobalFilter+'%') or
		((CAST(UnitCost AS NVARCHAR(20))) LIKE '%' +@GlobalFilter+'%') OR
		(GLAccount LIKE '%' +@GlobalFilter+'%') OR
		(PNSource LIKE '%' +@GlobalFilter+'%') OR
		(ItemType LIKE '%' +@GlobalFilter+'%')))
		OR
		(@GlobalFilter='' AND (ISNULL(@MainPartNumber,'') ='' OR MainPartNumber LIKE '%' + @MainPartNumber+'%') AND
		(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber + '%') AND      
		(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND        
		(ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND        
		(ISNULL(@RevisedPN,'') ='' OR RevisedPN LIKE '%' + @RevisedPN + '%') AND        
		(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND        
		(ISNULL(@UnitOfMeasure,'') ='' OR UnitOfMeasure LIKE '%' + @UnitOfMeasure + '%') AND            
		(ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND        
		(ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND        
		(ISNULL(@QuantityReserved,'') ='' OR QuantityReserved LIKE '%' + @QuantityReserved + '%') AND        
		(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND        
		(ISNULL(@StocklineNumber,'') ='' OR StocklineNumber LIKE '%' + @StocklineNumber + '%') AND             
		(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND        
		(ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND        
		(ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND        
		(ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND             
		(ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND        
		(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND        
		(ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND  
		(ISNULL(@Site,'') ='' OR Site LIKE '%' + @Site + '%') AND    
		(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS date)=CAST(@ReceivedDate AS date)) AND        
		(ISNULL(@ExpirationDate,'') ='' OR CAST(ExpirationDate AS Date)=CAST(@ExpirationDate AS date)) AND             
		(ISNULL(@TagDate,'') ='' OR CAST(TagDate AS Date)=CAST(@TagDate AS date)) AND        
		(ISNULL(@ItemCategory,'') ='' OR ItemCategory LIKE '%' + @ItemCategory + '%') AND        
		(ISNULL(@AWB,'') ='' OR AWB LIKE '%' + @AWB + '%') AND             
		(ISNULL(@CompanyName,'') ='' OR CompanyName LIKE '%' + @CompanyName + '%') AND        
		(ISNULL(@BuName,'') ='' OR BuName LIKE '%' + @BuName + '%') AND        
		(ISNULL(@DivName,'') ='' OR DivName LIKE '%' + @DivName + '%') AND        
		(ISNULL(@DeptName,'') ='' OR DeptName LIKE '%' + @DeptName + '%') AND        
		(ISNULL(@PartCertificationNumber,'') ='' OR PartCertificationNumber LIKE '%' + @PartCertificationNumber + '%') AND        
		(ISNULL(@CertifiedBy,'') ='' OR CertifiedBy LIKE '%' + @CertifiedBy + '%') AND        
		(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND              
		(ISNULL(@CertifiedDate,'') ='' OR CAST(CertifiedDate AS Date)=CAST(@CertifiedDate AS date)) AND        
		(ISNULL(@IsCustomerStock,'') ='' OR IsCustomerStock LIKE '%' + @IsCustomerStock + '%') AND           
		(ISNULL(@IsRepairManagement,'') ='' OR IsRepairManagement LIKE '%' + @IsRepairManagement + '%') AND  
		(ISNULL(@IsTurnIn,'') ='' OR IsTurnIn LIKE '%' + @IsTurnIn + '%') AND    
		(ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND        
		(ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND        
		(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and        
		(ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage like '%' + @WorkOrderStage+'%') and        
		(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND  
		(ISNULL(@WorkOrderNumber,'') ='' OR WorkOrderNumber LIKE '%' + @WorkOrderNumber + '%') AND
		(ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%') AND
		(ISNULL(@PONumber,'') ='' OR PONumber LIKE '%' + @PONumber + '%') AND
		(ISNULL(@RONumber,'') ='' OR RONumber LIKE '%' + @RONumber + '%') AND
		(ISNULL(@ReceiverNumber,'') ='' OR ReceiverNumber LIKE '%' + @ReceiverNumber + '%') AND
		(ISNULL(@QuantityAdjustment,'') ='' OR QuantityAdjustment LIKE '%' + @QuantityAdjustment + '%') AND
		(ISNULL(@BatchNumber,'') ='' OR [BatchNumber] LIKE '%' + @BatchNumber+'%') AND	
		(ISNULL(@IsDocument,'') ='' OR IsDocument LIKE '%' + @IsDocument + '%') and 
		(IsNull(@UnitCost,'') =''  OR CAST(UnitCost AS varchar(20)) like '%' + @UnitCost+'%' ) AND
		(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
		(ISNULL(@PNSource,'') ='' OR PNSource LIKE '%' + @PNSource + '%') AND
		(ISNULL(@ItemType,'') ='' OR ItemType LIKE '%' + @ItemType + '%'))
	   )
	   SELECT @Count = COUNT(StockLineId) FROM #TempALTResult           
        
		  SELECT *, @Count AS NumberOfItems FROM #TempALTResult ORDER BY      
	   CASE WHEN (@SortOrder=1  AND @SortColumn='MainPartNumber')  THEN MainPartNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='MainPartNumber')  THEN MainPartNumber END DESC,    
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,           
	   CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,            
	   CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END DESC,         
             
	   CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,           
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,         
		  CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,           
	   CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,  
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsTurnIn')  THEN IsTurnIn END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTurnIn')  THEN IsTurnIn END DESC,      
	   CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,         
	   CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,        
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC,        
	   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,        
	   CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END ASC,        
	   CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END DESC,        
	   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,    
	   CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='Site')  THEN Site END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='Site')  THEN Site END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PONumber')  THEN PONumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PONumber')  THEN PONumber END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='RONumber')  THEN RONumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='RONumber')  THEN RONumber END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAdjustment')  THEN QuantityAdjustment END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAdjustment')  THEN QuantityAdjustment END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsDocument')  THEN IsDocument END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsDocument')  THEN IsDocument END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='IsRepairManagement')  THEN IsDocument END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsRepairManagement')  THEN IsDocument END DESC,
	   CASE WHEN (@SortOrder=1 AND @SortColumn='BATCHNUMBER')  THEN BatchNumber END ASC,
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='BATCHNUMBER')  THEN BatchNumber END DESC,
	   CASE WHEN (@SortOrder=1 AND @SortColumn='UnitCost')  THEN CAST(UnitCost AS varchar(20)) END ASC,
       CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN CAST(UnitCost AS varchar(20)) END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
	   CASE WHEN (@SortOrder=1  AND @SortColumn='PNSource')  THEN PNSource END ASC,        
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='PNSource')  THEN PNSource END DESC
            
		OFFSET @RecordFROM ROWS         
		FETCH NEXT @PageSize ROWS ONLY        
	  END        
	 END       
  -- END        
  --COMMIT  TRANSACTION        
        
  END TRY            
  BEGIN CATCH              
   IF @@trancount > 0        
    PRINT 'ROLLBACK'        
    --ROLLBACK TRAN;        
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()         
        
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
              , @AdhocComments     VARCHAR(150)    = 'ProcStockList'         
              , @ProcedureParameters VARCHAR(3000)  = CONCAT(
				''
				,'@Parameter1 = ', ISNULL(CAST(@PageNumber AS VARCHAR(200)), '')
				,'@Parameter2 = ', ISNULL(CAST(@PageSize AS VARCHAR(200)), '')
				,'@Parameter3 = ', ISNULL(CAST(@SortColumn AS VARCHAR(200)), '')
				,'@Parameter4 = ', ISNULL(CAST(@SortOrder AS VARCHAR(200)), '')
				,'@Parameter5 = ', ISNULL(CAST(@GlobalFilter AS VARCHAR(200)), '')
				,'@Parameter6 = ', ISNULL(CAST(@stockTypeId AS VARCHAR(200)), '')
				,'@Parameter7 = ', ISNULL(CAST(@IsNonStock AS VARCHAR(200)), '')
				,'@Parameter8 = ', ISNULL(CAST(@StocklineNumber AS VARCHAR(200)), '')
				,'@Parameter9 = ', ISNULL(CAST(@MainPartNumber AS VARCHAR(200)), '')
				,'@Parameter10 = ', ISNULL(CAST(@PartNumber AS VARCHAR(200)), '')
				,'@Parameter11 = ', ISNULL(CAST(@PartDescription AS VARCHAR(200)), '')
				,'@Parameter12 = ', ISNULL(CAST(@ItemGroup AS VARCHAR(200)), '')
				,'@Parameter13 = ', ISNULL(CAST(@UnitOfMeasure AS VARCHAR(200)), '')
				,'@Parameter14 = ', ISNULL(CAST(@SerialNumber AS VARCHAR(200)), '')
				,'@Parameter15 = ', ISNULL(CAST(@GlAccountName AS VARCHAR(200)), '')
				,'@Parameter16 = ', ISNULL(CAST(@ItemCategory AS VARCHAR(200)), '')
				,'@Parameter17 = ', ISNULL(CAST(@Condition AS VARCHAR(200)), '')
				,'@Parameter18 = ', ISNULL(CAST(@QuantityAvailable AS VARCHAR(200)), '')
				,'@Parameter19 = ', ISNULL(CAST(@QuantityOnHand AS VARCHAR(200)), '')
				,'@Parameter20 = ', ISNULL(CAST(@CompanyName AS VARCHAR(200)), '')
				,'@Parameter21 = ', ISNULL(CAST(@BuName AS VARCHAR(200)), '')
				,'@Parameter22 = ', ISNULL(CAST(@DeptName AS VARCHAR(200)), '')
				,'@Parameter23 = ', ISNULL(CAST(@DivName AS VARCHAR(200)), '')
				,'@Parameter24 = ', ISNULL(CAST(@RevisedPN AS VARCHAR(200)), '')
				,'@Parameter25 = ', ISNULL(CAST(@AWB AS VARCHAR(200)), '')
				,'@Parameter26 = ', ISNULL(CAST(@ReceivedDate AS VARCHAR(200)), '')
				,'@Parameter27 = ', ISNULL(CAST(@TraceableToName AS VARCHAR(200)), '')
				,'@Parameter28 = ', ISNULL(CAST(@TaggedByName AS VARCHAR(200)), '')
				,'@Parameter29 = ', ISNULL(CAST(@TagType AS VARCHAR(200)), '')
				,'@Parameter30 = ', ISNULL(CAST(@TagDate AS VARCHAR(200)), '')
				,'@Parameter31 = ', ISNULL(CAST(@ExpirationDate AS VARCHAR(200)), '')
				,'@Parameter32 = ', ISNULL(CAST(@ControlNumber AS VARCHAR(200)), '')
				,'@Parameter33 = ', ISNULL(CAST(@IdNumber AS VARCHAR(200)), '')
				,'@Parameter34 = ', ISNULL(CAST(@Manufacturer AS VARCHAR(200)), '')
				,'@Parameter35 = ', ISNULL(CAST(@PartCertificationNumber AS VARCHAR(200)), '')
				,'@Parameter36 = ', ISNULL(CAST(@CertifiedBy AS VARCHAR(200)), '')
				,'@Parameter37 = ', ISNULL(CAST(@CertifiedDate AS VARCHAR(200)), '')
				,'@Parameter38 = ', ISNULL(CAST(@UpdatedBy AS VARCHAR(200)), '')
				,'@Parameter39 = ', ISNULL(CAST(@UpdatedDate AS VARCHAR(200)), '')
				,'@Parameter40 = ', ISNULL(CAST(@EmployeeId AS VARCHAR(200)), '')
				,'@Parameter41 = ', ISNULL(CAST(@MasterCompanyId AS VARCHAR(200)), '')
				,'@Parameter42 = ', ISNULL(CAST(@IsCustomerStock AS VARCHAR(200)), '')
				,'@Parameter43 = ', ISNULL(CAST(@ItemMasterId AS VARCHAR(200)), '')
				,'@Parameter44 = ', ISNULL(CAST(@StockLineIds AS VARCHAR(200)), '')
				,'@Parameter45 = ', ISNULL(CAST(@obtainFROM AS VARCHAR(200)), '')
				,'@Parameter46 = ', ISNULL(CAST(@ownerName AS VARCHAR(200)), '')
				,'@Parameter47 = ', ISNULL(CAST(@LastMSLevel AS VARCHAR(200)), '')
				,'@Parameter48 = ', ISNULL(CAST(@QuantityReserved AS VARCHAR(200)), '')
				,'@Parameter49 = ', ISNULL(CAST(@WorkOrderStage AS VARCHAR(200)), '')
				,'@Parameter50 = ', ISNULL(CAST(@IsECStock AS VARCHAR(200)), '')
				,'@Parameter51 = ', ISNULL(CAST(@IsCStock AS VARCHAR(200)), '')
				,'@Parameter52 = ', ISNULL(CAST(@Site AS VARCHAR(200)), '')
				,'@Parameter53 = ', ISNULL(CAST(@Location AS VARCHAR(200)), '')
				,'@Parameter54 = ', ISNULL(CAST(@IsALTStock AS VARCHAR(200)), '')
				,'@Parameter55 = ', ISNULL(CAST(@WorkOrderNumber AS VARCHAR(200)), '')
				,'@Parameter56 = ', ISNULL(CAST(@IsTimeLife AS VARCHAR(200)), '')
				,'@Parameter57 = ', ISNULL(CAST(@CustomerName AS VARCHAR(200)), '')
				,'@Parameter58 = ', ISNULL(CAST(@IsTurnIn AS VARCHAR(200)), '')
				,'@Parameter59 = ', ISNULL(CAST(@PONumber AS VARCHAR(200)), '')
				,'@Parameter60 = ', ISNULL(CAST(@RONumber AS VARCHAR(200)), '')
				,'@Parameter61 = ', ISNULL(CAST(@ReceiverNumber AS VARCHAR(200)), '')
				,'@Parameter62 = ', ISNULL(CAST(@QuantityAdjustment AS VARCHAR(200)), '')
				,'@Parameter63 = ', ISNULL(CAST(@IsDocument AS VARCHAR(200)), '')
				,'@Parameter64 = ', ISNULL(CAST(@IsRepairManagement AS VARCHAR(200)), '')
				,'@Parameter65 = ', ISNULL(CAST(@BatchNumber AS VARCHAR(200)), '')
				,'@Parameter66 = ', ISNULL(CAST(@UnitCost AS VARCHAR(200)), '')
				,'@Parameter67 = ', ISNULL(CAST(@GLAccount AS VARCHAR(200)), '')
				,'@Parameter68 = ', ISNULL(CAST(@PNSource AS VARCHAR(200)), '')
				,'@Parameter69 = ', ISNULL(CAST(@ItemType AS VARCHAR(200)), '')
			)
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
  END CATCH
END
