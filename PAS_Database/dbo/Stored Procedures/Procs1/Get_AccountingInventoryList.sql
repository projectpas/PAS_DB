/*************************************************************             
 ** File:   [Get_AccountingInventoryList]             
 ** Author:   
 ** Description: This stored procedure is used to display all stockline between period 
 ** Purpose:           
 ** Date:  Created 
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    30/05/2023   Satish Gohil  Created
	2    02/06/2023   Satish Gohil  Modify(Added IsSerialized Column)
**************************************************************/  

CREATE   PROCEDURE [dbo].[Get_AccountingInventoryList]
(
	@PageNumber int = NULL,      
	@PageSize int = NULL,      
	@SortColumn varchar(50)=NULL,      
	@SortOrder int = NULL,      
	@GlobalFilter varchar(50) = NULL,     
	@StocklineNumber varchar(50) = NULL,      
	@PartNumber varchar(50) = NULL,      
	@PartDescription varchar(50) = NULL,     
	@Manufacturer varchar(50) = NULL,   
	@RevisedPN varchar(50) = NULL,      
	@ItemGroup varchar(50) = NULL,      
	@UnitOfMeasure varchar(50) = NULL,
	@Condition varchar(50) = NULL,      
	@Location varchar(100) = NULL,
	@QuantityAvailable varchar(50) = NULL,      
	@QuantityOnHand varchar(50) = NULL,      
	@UnitPrice varchar(100) = NULL,
	@QuantityReserved varchar(50)=null,      
	@SerialNumber  varchar(50) = NULL,      
	@IsCustomerStock varchar(50) = NULL,      
	@ItemMasterId BIGINT = 0,      
	@StockLineIds varchar(1000) = NULL,      
	@LastMSLevel varchar(50)=null,      
	@GlAccountName varchar(50) = NULL,      
	@ItemCategory varchar(50) = NULL,      
	@CompanyName varchar(50) = NULL,      
	@BuName varchar(50) = NULL,      
	@DeptName varchar(50) = NULL,      
	@DivName varchar(50) = NULL,      
	@AWB varchar(50) = NULL,      
	@ReceivedDate datetime = NULL,      
	@TraceableToName varchar(50) = NULL,      
	@TaggedByName varchar(50) = NULL,      
	@TagType varchar(50) = NULL,      
	@TagDate datetime = NULL,      
	@ExpirationDate datetime = NULL,      	
	@PartCertificationNumber varchar(50) = NULL,      
	@CertifiedBy  varchar(50) = NULL,      
	@CertifiedDate datetime = NULL,      
	@UpdatedBy  varchar(50) = NULL,      
	@UpdatedDate  datetime = NULL,      
	@EmployeeId BIGINT=NULL,      
	@MasterCompanyId BIGINT = NULL,      
	@obtainFrom varchar(50) = NULL,      
	@ownerName varchar(50) = NULL,      
	@WorkOrderStage varchar(50)=null,
	@AccountingCalendarId bigint=null,
	@InventoryType int = NULL,
	@ControlNumber varchar(50) = NULL,      
	@IdNumber varchar(50) = NULL 
)
AS
BEGIN
	SET NOCOUNT ON;      
	DECLARE @RecordFrom INT = (@PageNumber-1)*@PageSize;
	DECLARE @MSModuelId int = 2;      
	DECLARE @Count Int;      
	DECLARE @IsActive bit;
	DECLARE @FromDate DATE = null;
	DECLARE @ToDate DATE = null;

	SELECT @FromDate = FromDate,@ToDate = ToDate FROM dbo.AccountingCalendar WITH(NOLOCK) WHERE AccountingCalendarId = @AccountingCalendarId

	IF @SortColumn IS NULL      
	BEGIN      
		SET @SortColumn=Upper('CreatedDate')      
	END       
	ELSE      
	BEGIN       
		Set @SortColumn=Upper(@SortColumn)      
	END       

	BEGIN TRY
		IF(@InventoryType = 1)
		BEGIN 
			;WITH RESULT AS(
				SELECT DISTINCT
					stl.StockLineId,
					(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',      
					 (ISNULL(im.PartNumber,'')) 'PartNumber',      
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
					 stl.ObtainFromName AS obtainFrom,      
					 stl.OwnerName AS ownerName,      
					 MSD.LastMSLevel,      
					 MSD.AllMSlevels,      
					 stl.WorkOrderId,      
					 stl.WorkOrderNumber,    
					 stl.Location,  
					 stl.LocationId,
					 stl.ControlNumber,      
					 stl.IdNumber,   
					 CAST(stl.UnitCost AS varchar(50)) 'UnitPrice',	
					 stl.IsSerialized,
					 (select top 1 wos.CodeDescription  from DBO.WorkOrder wo WITH (NOLOCK) inner join WorkOrderPartNumber wop WITH (NOLOCK) on wop.WorkOrderId=wo.WorkOrderId inner join DBO.WorkOrderStage wos WITH (NOLOCK) on wop.WorkOrderStageId=wos.WorkOrderStageId  where wo.WorkOrderId=stl.WorkOrderId and wop.StockLineId=stl.StockLineId) as WorkOrderStage,      
					 (select top 1 wos.Status  from DBO.WorkOrder wo WITH (NOLOCK) inner join DBO.WorkOrderStatus wos WITH (NOLOCK) on wo.WorkOrderStatusId=wos.Id where wo.WorkOrderId=stl.WorkOrderId) as WorkOrderStatus,      
					 (select top 1 isnull(RS.WorkOrderId,0)  from DBO.ReceivingCustomerWork RS WITH (NOLOCK)  where RS.StockLineId=stl.StockLineId) as rsworkOrderId
				FROM dbo.Stockline stl WITH(NOLOCK)
				INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
				LEFT JOIN dbo.ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId  
				INNER JOIN  dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId     
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.EntityMSID = RMS.EntityStructureId  
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
				WHERE stl.MasterCompanyId = @MasterCompanyId AND stl.IsParent = 1 AND (stl.IsDeleted = 0)
				AND (@ItemMasterId = 0 OR stl.ItemMasterId = @ItemMasterId)      
				AND stl.QuantityAvailable < 0 AND CAST(stl.EntryDate AS date) >= CAST(@FromDate AS DATE)  AND CAST(stl.EntryDate AS date) <= CAST(@ToDate AS DATE)
			), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)      


			--SELECT * FROM  Result  
			SELECT * INTO #TempResult1 FROM  Result  
			WHERE (
			(@GlobalFilter <>'' AND
			((PartNumber LIKE '%' +@GlobalFilter+'%') OR      
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
		  (TaggedByName LIKE '%' +@GlobalFilter+'%') OR      
		  (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR            
		  (TagType LIKE '%' +@GlobalFilter+'%') OR      
		  (TraceableToName LIKE '%' +@GlobalFilter+'%') OR           
		  (UnitPrice  LIKE '%' +@GlobalFilter+'%') OR      
		  (Condition LIKE '%' +@GlobalFilter+'%') OR      
		  (Location LIKE '%' +@GlobalFilter+'%') OR      
		  (AWB LIKE '%' +@GlobalFilter+'%') OR      
		  (ItemCategory LIKE '%' +@GlobalFilter+'%') OR      
		  (IsCustomerStock LIKE '%' +@GlobalFilter+'%') OR      
		  (PartCertificationNumber LIKE '%' +@GlobalFilter+'%') OR      
		  (CertifiedBy LIKE '%' +@GlobalFilter+'%') OR      
		  (CompanyName LIKE '%' +@GlobalFilter+'%') OR      
		  (BuName LIKE '%' +@GlobalFilter+'%') OR      
		  (DivName LIKE '%' +@GlobalFilter+'%') OR      
		  (DeptName LIKE '%' +@GlobalFilter+'%') OR           
		  (obtainFrom LIKE '%' +@GlobalFilter+'%') OR      
		  (ownerName LIKE '%' +@GlobalFilter+'%') OR      
		  (WorkOrderStage LIKE '%' +@GlobalFilter+'%') OR      
		  (IdNumber LIKE '%' +@GlobalFilter+'%') OR      
		  (ControlNumber LIKE '%' +@GlobalFilter+'%') OR      
		  (UpdatedBy LIKE '%' +@GlobalFilter+'%')
		  ))       
		  OR         
		  (@GlobalFilter='' AND 
			(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND      
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
			  (ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND      
			  (ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND      
			  (ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND           
			  (ISNULL(@UnitPrice,'') ='' OR UnitPrice LIKE '%' + @UnitPrice + '%') AND      
			  (ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND      
			  (ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND      
			  (ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS Date)=CAST(@ReceivedDate AS date)) AND      
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
			  (ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND      
			  (ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND      
			  (ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and      
			  (ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage like '%' + @WorkOrderStage+'%') and  
			   (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND      
			   (ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND      
			  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date))
			 )      
		  )      
			SELECT @Count = COUNT(StockLineId) FROM #TempResult1  


			SELECT *, @Count AS NumberOfItems FROM #TempResult1 ORDER BY        
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,       
			CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,       
			CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,      
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitPrice')  THEN UnitPrice END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitPrice')  THEN UnitPrice END DESC,       
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
            CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,  
			CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC

		   OFFSET @RecordFrom ROWS       
		   FETCH NEXT @PageSize ROWS ONLY      

		END
		IF(@InventoryType = 2)
		BEGIN
				;WITH RESULT AS(
				SELECT DISTINCT
					stl.StockLineId,
					(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',      
					 (ISNULL(im.PartNumber,'')) 'PartNumber',      
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
					 stl.ObtainFromName AS obtainFrom,      
					 stl.OwnerName AS ownerName,      
					 MSD.LastMSLevel,      
					 MSD.AllMSlevels,      
					 stl.WorkOrderId,      
					 stl.WorkOrderNumber,    
					 stl.Location,  
					 stl.LocationId,
					  stl.ControlNumber,      
					 stl.IdNumber,   
					 CAST(stl.UnitCost AS varchar(50)) 'UnitPrice',	
					 stl.IsSerialized,
					 (select top 1 wos.CodeDescription  from DBO.WorkOrder wo WITH (NOLOCK) inner join WorkOrderPartNumber wop WITH (NOLOCK) on wop.WorkOrderId=wo.WorkOrderId inner join DBO.WorkOrderStage wos WITH (NOLOCK) on wop.WorkOrderStageId=wos.WorkOrderStageId  where wo.WorkOrderId=stl.WorkOrderId and wop.StockLineId=stl.StockLineId) as WorkOrderStage,      
					 (select top 1 wos.Status  from DBO.WorkOrder wo WITH (NOLOCK) inner join DBO.WorkOrderStatus wos WITH (NOLOCK) on wo.WorkOrderStatusId=wos.Id where wo.WorkOrderId=stl.WorkOrderId) as WorkOrderStatus,      
					 (select top 1 isnull(RS.WorkOrderId,0)  from DBO.ReceivingCustomerWork RS WITH (NOLOCK)  where RS.StockLineId=stl.StockLineId) as rsworkOrderId
				FROM dbo.Stockline stl WITH(NOLOCK)
				INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
				LEFT JOIN dbo.ItemMaster rPart WITH (NOLOCK) ON im.RevisedPartId = rPart.ItemMasterId  
				INNER JOIN  dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = stl.StockLineId     
				INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MSD.EntityMSID = RMS.EntityStructureId  
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
				WHERE stl.MasterCompanyId = @MasterCompanyId AND stl.IsParent = 1 AND (stl.IsDeleted = 0)
				AND (@ItemMasterId = 0 OR stl.ItemMasterId = @ItemMasterId)      
				AND ISNULL(stl.QuantityAvailable,0) > 0 AND CAST(stl.EntryDate AS date) >= CAST(@FromDate AS DATE)  AND CAST(stl.EntryDate AS date) <= CAST(@ToDate AS DATE)
			), ResultCount AS(Select COUNT(StockLineId) AS totalItems FROM Result)      


			--SELECT * FROM  Result  
			SELECT * INTO #TempResult3 FROM  Result  
			WHERE (
			(@GlobalFilter <>'' AND
			((PartNumber LIKE '%' +@GlobalFilter+'%') OR      
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
		  (TaggedByName LIKE '%' +@GlobalFilter+'%') OR      
		  (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR            
		  (TagType LIKE '%' +@GlobalFilter+'%') OR      
		  (TraceableToName LIKE '%' +@GlobalFilter+'%') OR           
		  (UnitPrice  LIKE '%' +@GlobalFilter+'%') OR      
		  (Condition LIKE '%' +@GlobalFilter+'%') OR      
		  (Location LIKE '%' +@GlobalFilter+'%') OR      
		  (AWB LIKE '%' +@GlobalFilter+'%') OR      
		  (ItemCategory LIKE '%' +@GlobalFilter+'%') OR      
		  (IsCustomerStock LIKE '%' +@GlobalFilter+'%') OR      
		  (PartCertificationNumber LIKE '%' +@GlobalFilter+'%') OR      
		  (CertifiedBy LIKE '%' +@GlobalFilter+'%') OR      
		  (CompanyName LIKE '%' +@GlobalFilter+'%') OR      
		  (BuName LIKE '%' +@GlobalFilter+'%') OR      
		  (DivName LIKE '%' +@GlobalFilter+'%') OR      
		  (DeptName LIKE '%' +@GlobalFilter+'%') OR           
		  (obtainFrom LIKE '%' +@GlobalFilter+'%') OR      
		  (ownerName LIKE '%' +@GlobalFilter+'%') OR      
		  (WorkOrderStage LIKE '%' +@GlobalFilter+'%') OR  
		   (IdNumber LIKE '%' +@GlobalFilter+'%') OR      
		  (ControlNumber LIKE '%' +@GlobalFilter+'%') OR      
		  (UpdatedBy LIKE '%' +@GlobalFilter+'%')
		  ))       
		  OR         
		  (@GlobalFilter='' AND 
			(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND      
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
			  (ISNULL(@TaggedByName,'') ='' OR TaggedByName LIKE '%' + @TaggedByName + '%') AND      
			  (ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND      
			  (ISNULL(@TraceableToName,'') ='' OR TraceableToName LIKE '%' + @TraceableToName + '%') AND           
			  (ISNULL(@UnitPrice,'') ='' OR UnitPrice LIKE '%' + @UnitPrice + '%') AND      
			  (ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND      
			  (ISNULL(@Location,'') ='' OR Location LIKE '%' + @Location + '%') AND      
			  (ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS Date)=CAST(@ReceivedDate AS date)) AND      
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
			  (ISNULL(@obtainFrom,'') ='' OR obtainFrom LIKE '%' + @obtainFrom + '%') AND      
			  (ISNULL(@ownerName,'') ='' OR ownerName LIKE '%' + @ownerName + '%') AND      
			  (ISNULL(@LastMSLevel,'') ='' OR LastMSLevel like '%' + @LastMSLevel+'%') and      
			  (ISNULL(@WorkOrderStage,'') ='' OR WorkOrderStage like '%' + @WorkOrderStage+'%') and    
			   (ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND      
			   (ISNULL(@IdNumber,'') ='' OR IdNumber LIKE '%' + @IdNumber + '%') AND      
			  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date))
			 )      
		  )      
			SELECT @Count = COUNT(StockLineId) FROM #TempResult3   


			SELECT *, @Count AS NumberOfItems FROM #TempResult3 ORDER BY        
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,       
			CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,       
			CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,      
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitPrice')  THEN UnitPrice END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitPrice')  THEN UnitPrice END DESC,       
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
            CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,  
			CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,      
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC

		   OFFSET @RecordFrom ROWS       
		   FETCH NEXT @PageSize ROWS ONLY      

		END
		
	END TRY
	BEGIN CATCH
	END CATCH

END