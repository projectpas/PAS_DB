﻿/*************************************************************               
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
	14   25/07/2024   Rajesh Gami       Remove inner query for the get WorkOrderStage due to performance issue
	
-- exec ProcStockList @PageNumber=1,@PageSize=20,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@stockTypeId=1,@StocklineNumber=NULL,@MainPartNumber=NULL,
@PartNumber=NULL,@PartDescription=NULL,@ItemGroup=NULL,@UnitOfMeasure=NULL,@SerialNumber=NULL,@GlAccountName=NULL,@ItemCategory=NULL,@Condition=NULL,@QuantityAvailable=NULL,
@QuantityOnHand=NULL,@CompanyName=NULL,@BuName=NULL,@DeptName=NULL,@DivName=NULL,@RevisedPN=NULL,@AWB=NULL,@ReceivedDate=NULL,@TraceableToName=NULL,@TaggedByName=NULL,
@TagType=NULL,@TagDate=NULL,@ExpirationDate=NULL,@ControlNumber=NULL,@IdNumber=NULL,@Manufacturer=NULL,@PartCertificationNumber=NULL,@CertifiedBy=NULL,@CertifiedDate=NULL,
@UpdatedBy=NULL,@UpdatedDate=NULL,@EmployeeId=98,@MasterCompanyId=11,@IsCustomerStock=NULL,@ItemMasterId=0,@StockLineIds=NULL,@obtainFrom=NULL,@ownerName=NULL,
@LastMSLevel=NULL,@QuantityReserved=NULL,@WorkOrderStage=NULL,@IsECStock=1,@IsCStock=0,@Site=NULL,@Location=NULL,@IsALTStock=0,@WorkOrderNumber=NULL,@IsTimeLife=NULL,
@CustomerName=NULL,@IsTurnIn=NULL
**************************************************************/   
CREATE   PROCEDURE [dbo].[ProcStockList]
	@PageNumber int = NULL,        
	@PageSize int = NULL,        
	@SortColumn varchar(50)=NULL,        
	@SortOrder int = NULL,        
	@GlobalFilter varchar(50) = NULL,        
	@stockTypeId int = NULL,        
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
	@IsTurnIn varchar(50) = NULL
AS        
BEGIN         
     SET NOCOUNT ON;        
	  DECLARE @RecordFROM INT;        
	  DECLARE @MSModuelId int;        
	  DECLARE @Count Int;        
	  DECLARE @IsActive bit;        
	  DECLARE @ISCS bit;        
	  DECLARE @ISECS bit, @isElse bit =0, @IsCustomerStockInline bit = NULL;        
	  SET @RecordFROM = (@PageNumber-1)*@PageSize;         
	  SET @MSModuelId = 2;   -- For Stockline        
        
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
  BEGIN TRY        
  --BEGIN TRANSACTION        
  -- BEGIN       
	 IF(@IsALTStock  IS NULL OR @IsALTStock = 0)    
	 BEGIN     
	  IF @stockTypeId = 1 -- Qty OH > 0        
	  BEGIN        
	   ;WITH Result AS(        
	   SELECT DISTINCT stl.StockLineId,            
		(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',        
		(ISNULL(im.PartNumber,'')) 'MainPartNumber',        
		(ISNULL(im.PartDescription,'')) 'PartDescription',        
		(ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
		(ISNULL(rPart.PartNumber,'')) 'RevisedPN',                  
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
		im.ItemTypeId,        
		stl.IsActive,                             
		stl.CreatedDate,        
		stl.CreatedBy,        
		stl.PartCertificationNumber,        
		stl.CertifiedBy,        
		stl.CertifiedDate,        
		stl.UpdatedDate,                
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
	   lot.LotNumber,
	   (ISNULL(ct.Name,'')) 'CustomerName',
	   ISNULL(stl.CustomerId,0) as CustomerId, 
	   '' AS WorkOrderStage --Remove Workorderstage due to performance issue  
		FROM  dbo.StockLine stl WITH (NOLOCK)        
		  INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId         
		  INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId     
		  INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
		  INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		  LEFT JOIN dbo.ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId                  
		  LEFT JOIN dbo.TimeLife tf WITH (NOLOCK) ON stl.StockLineId = tf.StockLineId                  
		  LEFT JOIN dbo.Lot lot WITH (NOLOCK) ON lot.LotId = stl.LotId 
		  LEFT JOIN dbo.Customer ct WITH (NOLOCK) ON ct.CustomerId = stl.CustomerId
		WHERE stl.MasterCompanyId=@MasterCompanyId  AND ((stl.IsDeleted=0 ) AND (stl.QuantityOnHand > 0)) AND (@StockLineIds IS NULL OR stl.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,',')))                
		 AND (@ItemMasterId = 0 OR stl.ItemMasterId = @ItemMasterId)       
		 AND stl.IsParent = 1 
		 --AND stl.IsCustomerStock = CASE WHEN @ISCS = 1 AND @ISECS = 0 THEN 1 WHEN @ISCS = 0 AND @ISECS = 1 THEN 0 else stl.IsCustomerStock END          
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
		  (CustomerName LIKE '%' +@GlobalFilter+'%')))         
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
		  --(ISNULL(@ReceivedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(ReceivedDate, @CurrntEmpTimeZoneDesc )AS date)=CAST(@ReceivedDate AS date)) AND        
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
		  (ISNULL(@IsTurnIn,'') ='' OR IsTurnIn LIKE '%' + @IsTurnIn + '%') AND    
		  (ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND        
		  (ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND        
		  (ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage LIKE '%' + @WorkOrderStage + '%') AND        
		  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND   
		  (ISNULL(@WorkOrderNumber,'') ='' OR WorkOrderNumber LIKE '%' + @WorkOrderNumber + '%') AND
		  (ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%') AND
		  (ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%'))        
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
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC
            
		OFFSET @RecordFROM ROWS         
		FETCH NEXT @PageSize ROWS ONLY        
	  END        
	  ELSE -- ALL        
	  BEGIN        
	   ;WITH Result AS(        
	   SELECT DISTINCT stl.StockLineId,            
		(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',        
		(ISNULL(im.PartNumber,'')) 'MainPartNumber',        
		(ISNULL(im.PartDescription,'')) 'PartDescription',        
		(ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
		(ISNULL(rPart.PartNumber,'')) 'RevisedPN',                  
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
		im.ItemTypeId,        
		stl.IsActive,                             
		stl.CreatedDate,        
		stl.CreatedBy,        
		stl.PartCertificationNumber,        
		stl.CertifiedBy,        
		stl.CertifiedDate,        
		stl.UpdatedDate,                
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
		lot.LotNumber,
		Stl.Site,
		Stl.SiteId,
		(ISNULL(ct.Name,'')) 'CustomerName',
		ISNULL(stl.CustomerId,0) as CustomerId,
		'' as WorkOrderStage        
      
		FROM  DBO.StockLine stl WITH (NOLOCK)        
		 INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId         
		 INNER JOIN  dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId        
		 INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
		 INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
		 LEFT JOIN dbo.ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId                  
		 LEFT JOIN dbo.TimeLife tf WITH (NOLOCK) ON stl.StockLineId = tf.StockLineId                  
		 LEFT JOIN dbo.Lot lot WITH (NOLOCK) ON lot.LotId = stl.LotId
		 LEFT JOIN dbo.Customer ct WITH (NOLOCK) ON ct.CustomerId = stl.CustomerId
		 WHERE stl.MasterCompanyId = @MasterCompanyId AND stl.IsParent = 1 AND ((stl.IsDeleted = 0) AND (@stockTypeId IS NULL OR im.ItemTypeId = @stockTypeId)) AND (@StockLineIds IS NULL OR stl.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,  
  
	   ',')))                
		AND (@ItemMasterId = 0 OR stl.ItemMasterId = @ItemMasterId)        
		--AND stl.IsCustomerStock = CASE WHEN @ISCS = 1 AND @ISECS = 0 THEN 1 WHEN @ISCS = 0 AND @ISECS = 1 THEN 0 else stl.IsCustomerStock END
		AND stl.IsCustomerStock = CASE WHEN @isElse = 0 THEN @IsCustomerStockInline else stl.IsCustomerStock END  
	  ), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)        
	  SELECT *,
	  	(SELECT TOP 1 wos.Status  FROM DBO.WorkOrder wo WITH (NOLOCK) inner join DBO.WorkOrderStatus wos WITH (NOLOCK) on wo.WorkOrderStatusId=wos.Id where wo.WorkOrderId=WorkOrderId) as WorkOrderStatus,        
		(SELECT TOP 1 isnull(RS.WorkOrderId,0)  FROM DBO.ReceivingCustomerWork RS WITH (NOLOCK)  where RS.StockLineId=r.StockLineId) as rsworkOrderId INTO #TempResult FROM  Result r         
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
		(CustomerName LIKE '%' +@GlobalFilter+'%')))         
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
		--(ISNULL(@ReceivedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(ReceivedDate, @CurrntEmpTimeZoneDesc )AS date)=CAST(@ReceivedDate AS date)) AND        
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
		(ISNULL(@IsTurnIn,'') ='' OR IsTurnIn LIKE '%' + @IsTurnIn + '%') AND    
		(ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND        
		(ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND        
		(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and        
		(ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage like '%' + @WorkOrderStage+'%') and        
		(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND  
		(ISNULL(@WorkOrderNumber,'') ='' OR WorkOrderNumber LIKE '%' + @WorkOrderNumber + '%') AND
		(ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%') AND
		(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%'))        
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
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC
            
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
		(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',        
		(ISNULL(IMAl.PartNumber,'')) 'MainPartNumber',       
		(ISNULL(im.partnumber,'')) 'PartNumber',    
		(ISNULL(im.PartDescription,'')) 'PartDescription',        
		(ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
		(ISNULL(rPart.PartNumber,'')) 'RevisedPN',                  
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
		im.ItemTypeId,        
		stl.IsActive,                             
		stl.CreatedDate,        
		stl.CreatedBy,        
		stl.PartCertificationNumber,        
		stl.CertifiedBy,          stl.CertifiedDate,        
		stl.UpdatedDate,                
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
	   lot.LotNumber,
	    Stl.Site,
	   Stl.SiteId,
	   ISNULL(stl.CustomerId,0) as CustomerId,
	   '' AS WorkOrderStage        
		     
	  FROM Nha_Tla_Alt_Equ_ItemMapping ALT    
	   INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON ALT.MappingItemMasterId = im.ItemMasterId --ALTPART    
	   INNER JOIN DBO.ItemMaster IMAl WITH (NOLOCK) ON ALT.ItemMasterId = IMAl.ItemMasterId --MAINPART    
	   INNER JOIN DBO.StockLine stl WITH (NOLOCK) ON im.ItemMasterId = stl.ItemMasterId    
	   INNER JOIN DBO.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId        
	   INNER JOIN DBO.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
	   INNER JOIN DBO.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
	   LEFT JOIN DBO.ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId     
	   LEFT JOIN DBO.TimeLife tf WITH (NOLOCK) ON stl.StockLineId = tf.StockLineId     
	   LEFT JOIN dbo.Lot lot WITH (NOLOCK) ON lot.LotId = stl.LotId 
		WHERE ALT.MappingType = 1 AND ALT.IsDeleted = 0 AND ALT.IsActive = 1 AND stl.MasterCompanyId=@MasterCompanyId  AND ((stl.IsDeleted=0 ) AND (stl.QuantityOnHand > 0)) AND (@StockLineIds IS NULL OR stl.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StockLineIds,',')))                
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
		  (UpdatedBy LIKE '%' +@GlobalFilter+'%')))         
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
		  --(ISNULL(@ReceivedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(ReceivedDate, @CurrntEmpTimeZoneDesc )AS date)=CAST(@ReceivedDate AS date)) AND        
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
		  (ISNULL(@IsTurnIn,'') ='' OR IsTurnIn LIKE '%' + @IsTurnIn + '%') AND    
		  (ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND        
		  (ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND        
		  (ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage LIKE '%' + @WorkOrderStage + '%') AND        
		  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND  
		  (ISNULL(@WorkOrderNumber,'') ='' OR WorkOrderNumber LIKE '%' + @WorkOrderNumber + '%') AND
		  (ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%'))        
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
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC     
            
		OFFSET @RecordFROM ROWS         
		FETCH NEXT @PageSize ROWS ONLY        
	  END        
	  ELSE -- ALL        
	  BEGIN        
	   ;WITH Result AS(        
	   SELECT DISTINCT stl.StockLineId,            
		(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',        
		(ISNULL(IMAl.PartNumber,'')) 'MainPartNumber',        
		(ISNULL(im.partnumber,'')) 'PartNumber',    
		(ISNULL(im.PartDescription,'')) 'PartDescription',        
		(ISNULL(stl.Manufacturer,'')) 'Manufacturer',          
		(ISNULL(rPart.PartNumber,'')) 'RevisedPN',                  
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
		im.ItemTypeId,        
		stl.IsActive,                             
		stl.CreatedDate,        
		stl.CreatedBy,        
		stl.PartCertificationNumber,        
		stl.CertifiedBy,        
		stl.CertifiedDate,        
		stl.UpdatedDate,                
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
		lot.LotNumber,
		Stl.Site,
		Stl.SiteId,
		ISNULL(stl.CustomerId,0) as CustomerId,
		'' as WorkOrderStage        
		    
		FROM Nha_Tla_Alt_Equ_ItemMapping ALT    
	   INNER JOIN DBO.ItemMaster im WITH (NOLOCK) ON ALT.MappingItemMasterId = im.ItemMasterId --ALTPART    
	   INNER JOIN DBO.ItemMaster IMAl WITH (NOLOCK) ON ALT.ItemMasterId = IMAl.ItemMasterId --MAINPART    
	   INNER JOIN DBO.StockLine stl WITH (NOLOCK) ON im.ItemMasterId = stl.ItemMasterId    
	   INNER JOIN DBO.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId        
	   INNER JOIN DBO.RoleManagementStructure RMS WITH (NOLOCK) ON stl.ManagementStructureId = RMS.EntityStructureId
	   INNER JOIN DBO.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
	   LEFT JOIN DBO.ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId     
	   LEFT JOIN DBO.TimeLife tf WITH (NOLOCK) ON stl.StockLineId = tf.StockLineId     
	   LEFT JOIN DBO.Lot lot WITH (NOLOCK) ON lot.LotId = stl.LotId 
		 WHERE ALT.MappingType =1 AND ALT.IsDeleted = 0 AND ALT.IsActive = 1 AND stl.MasterCompanyId = @MasterCompanyId AND stl.IsParent = 1 AND ((stl.IsDeleted = 0) AND (@stockTypeId IS NULL OR im.ItemTypeId = @stockTypeId)) AND (@StockLineIds IS NULL OR stl
  
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
		(UpdatedBy LIKE '%' +@GlobalFilter+'%')))         
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
		--(ISNULL(@ReceivedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(ReceivedDate, @CurrntEmpTimeZoneDesc )AS date)=CAST(@ReceivedDate AS date)) AND        
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
		(ISNULL(@IsTurnIn,'') ='' OR IsTurnIn LIKE '%' + @IsTurnIn + '%') AND    
		(ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND        
		(ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND        
		(ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and        
		(ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage like '%' + @WorkOrderStage+'%') and        
		(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND  
		(ISNULL(@WorkOrderNumber,'') ='' OR WorkOrderNumber LIKE '%' + @WorkOrderNumber + '%') AND
		(ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%'))        
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
	   CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC 
            
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''',         
                @Parameter2 = ' + ISNULL(@PageSize,'') + ',         
                @Parameter3 = ' + ISNULL(@SortColumn,'') + ',         
                @Parameter4 = ' + ISNULL(@SortOrder,'') + ',         
                @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ',         
                @Parameter6 = ' + ISNULL(@stockTypeId,'') + ',         
                @Parameter7 = ' + ISNULL(@StocklineNumber,'') + ',         
                @Parameter8 = ' + ISNULL(@PartNumber,'') + ',         
                @Parameter9 = ' + ISNULL(@PartDescription,'') + ',         
                @Parameter10 = ' + ISNULL(@ItemGroup,'') + ',         
                @Parameter11 = ' + ISNULL(@UnitOfMeasure,'') + ',         
                @Parameter12 = ' + ISNULL(@SerialNumber,'') + ',         
                @Parameter13 = ' + ISNULL(@GlAccountName,'') + ',         
                @Parameter14 = ' + ISNULL(@ItemCategory,'') + ',        
                @Parameter15 = ' + ISNULL(@Condition,'') + ',         
                @Parameter16 = ' + ISNULL(@QuantityAvailable,'') + ',         
                @Parameter17 = ' + ISNULL(@QuantityOnHand,'') + ',         
                @Parameter18 = ' + ISNULL(@CompanyName,'') + ',         
                @Parameter19 = ' + ISNULL(@BuName,'') + ',        
                @Parameter20 = ' + ISNULL(@DeptName,'') + ',         
                @Parameter21 = ' + ISNULL(@DivName,'') + ',         
                @Parameter22 = ' + ISNULL(@RevisedPN,'') + ',         
                @Parameter23 = ' + ISNULL(@AWB,'') + ',         
                @Parameter24 = ' + ISNULL(CAST(@ReceivedDate AS varchar(20)) ,'') +''',          
                @Parameter25 = ' + ISNULL(@TraceableToName,'') + ',         
                @Parameter26 = ' + ISNULL(@TaggedByName,'') + ',         
                @Parameter27 = ' + ISNULL(@TagType,'') + ',         
                @Parameter28 = ' + ISNULL(CAST(@TagDate AS varchar(20)) ,'') +''',          
                @Parameter30 = ' + ISNULL(CAST(@ExpirationDate AS varchar(20)) ,'') +''',         
                @Parameter31 = ' + ISNULL(@IdNumber,'') + ',         
                @Parameter32 = ' + ISNULL(@Manufacturer,'') + ',         
                @Parameter33 = ' + ISNULL(@PartCertificationNumber,'') + ',        
                @Parameter34 = ' + ISNULL(@CertifiedBy,'') + ',         
                @Parameter35 = ' + ISNULL(@CertifiedDate,'') + ',         
                @Parameter36 = ' + ISNULL(@UpdatedBy,'') + ',         
                @Parameter37 = ' + ISNULL(CAST(@UpdatedDate AS varchar(20)) ,'') +''',        
                @Parameter38 = ' + ISNULL(@EmployeeId,'') + ',         
                @Parameter39 = ' + ISNULL(@MasterCompanyId,'') + ',         
                @Parameter40 = ' + ISNULL(@IsCustomerStock ,'') +',  
                @Parameter41 = ' + ISNULL(@WorkOrderNumber,'') + ',
                @Parameter42 = ' + ISNULL(@IsTimeLife ,'') +',
				@Parameter43 = ' + ISNULL(@CustomerName,'') + ',
				'        
              , @ApplicationName VARCHAR(100) = 'PAS'        
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
              exec spLogException         
                       @DatabaseName           = @DatabaseName        
                     , @AdhocComments          = @AdhocComments        
                     , @ProcedureParameters = @ProcedureParameters        
                     , @ApplicationName        =  @ApplicationName        
                     , @ErrorLogID   = @ErrorLogID OUTPUT ;        
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)        
              RETURN(1);        
  END CATCH              
END