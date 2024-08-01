/*************************************************************               
 ** File:   [SP_GetVendorRFQPNViewList]               
 ** Author:   -    
 ** Description: This stored procedure is used to GetVendorRFQPNViewList      
 ** Purpose:             
 ** Date: -            
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------			--------------------------------              
	1    	-	         -              Created    
	2    25/07/2024   Rajesh Gami		Optimize the SP due to performance issue    
	3    29/07/2024   Rajesh Gami		Duplicate record    

**************************************************************/  

CREATE PROCEDURE [dbo].[SP_GetVendorRFQPNViewList]  
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
@NeedByDate VARCHAR(50)=NULL,  
@PromisedDate VARCHAR(50)=NULL,  
@Condition VARCHAR(50)=NULL,  
@UnitCost varchar(50)=NULL,  
@QuantityOrdered varchar(50) =NULL,  
@WorkOrderNo VARCHAR(50)=NULL,  
@SubWorkOrderNo VARCHAR(50)=NULL,  
@SalesOrderNo VARCHAR(50)=NULL,  
@PurchaseOrderNumber VARCHAR(50)=NULL,  
@mgmtStructure varchar(200)=null,  
@Level2Type varchar(200)=null,  
@Level3Type varchar(200)=null,  
@Level4Type varchar(200)=null,  
@Memo VARCHAR(200) =NULL  
AS  
BEGIN  
SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
  DECLARE @RecordFrom int;  
  DECLARE @IsActive bit=1  
  DECLARE @Count Int,@TotalCount int = 0;  
  SET @RecordFrom = (@PageNumber-1)*@PageSize;  
  
  IF @IsDeleted IS NULL  
  BEGIN  
   SET @IsDeleted=0  
  END  
  IF @SortColumn IS NULL  
  BEGIN  
   SET @SortColumn=Upper('VendorRFQPurchaseOrderId')  
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
	DECLARE @OpenDateConverted datetime = NULL;
	DECLARE @CreatedDateConverted datetime = NULL;
	DECLARE @NeedByDateConverted datetime = NULL;
	DECLARE @PromisedDateConverted datetime = NULL;

	IF (@OpenDate IS NOT NULL AND ISDATE(@OpenDate) = 1)
		SET @OpenDateConverted = CAST(@OpenDate AS datetime);

	IF (@CreatedDate IS NOT NULL AND ISDATE(@CreatedDate) = 1)
		SET @CreatedDateConverted = CAST(@CreatedDate AS datetime);

	IF (@NeedByDate IS NOT NULL AND ISDATE(@NeedByDate) = 1)
		SET @NeedByDateConverted = CAST(@NeedByDate AS datetime);

	IF (@PromisedDate IS NOT NULL AND ISDATE(@PromisedDate) = 1)
		SET @PromisedDateConverted = CAST(@PromisedDate AS datetime);
		
  --BEGIN TRANSACTION  
  --BEGIN   
  
  ;WITH Main AS(           
       SELECT PO.VendorRFQPurchaseOrderId,PO.VendorRFQPurchaseOrderNumber,PO.OpenDate,PO.ClosedDate,PO.CreatedDate,PO.CreatedBy,PO.UpdatedDate,  
     PO.UpdatedBy,PO.IsActive,PO.IsDeleted,PO.StatusId,PO.VendorId,PO.VendorName,PO.VendorCode,PO.[Status],  
     PO.Requisitioner AS RequestedBy
     FROM VendorRFQPurchaseOrder PO WITH (NOLOCK)  
     INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.VendorRFQPurchaseOrderId  
     INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId  
     INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
      WHERE ((PO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR PO.StatusId = @StatusID))   
      AND PO.MasterCompanyId = @MasterCompanyId )   
   
   SELECT 
	DISTINCT M.VendorRFQPurchaseOrderId,M.VendorRFQPurchaseOrderNumber,M.OpenDate,M.ClosedDate,M.CreatedDate,M.CreatedBy,M.UpdatedDate,  
     M.UpdatedBy,M.IsActive,M.IsDeleted,M.StatusId,M.VendorId,M.VendorName,M.VendorCode,M.[Status],  
     M.RequestedBy AS RequestedBy,  
     (Select SUM(QuantityOrdered) as QuantityOrdered from VendorRFQPurchaseOrderPart WITH (NOLOCK)   
     Where VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND IsDeleted=0 AND IsActive=1) as QuantityOrdered,  
     (Select SUM(UnitCost) as UnitCost from VendorRFQPurchaseOrderPart WITH (NOLOCK)   
     Where VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND IsDeleted=0 AND IsActive=1) as UnitCost,  
	 (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse SP.PartDescription End)  as 'PartDescription',
	 (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse SP.PartDescription End)  as 'PartDescriptionType',
     (Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId)   
      FROM  dbo.VendorRFQPurchaseOrderPart VRPP   
      WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND VRPP.IsDeleted=0 AND VRPP.IsActive=1 ) > 1 --AND LEN(isnull(SP.StockType,'')) >0  
      ) Then 'Multiple' ELse  isnull(SP.StockType,'')   End)  
      as 'StockTypeType',  
      (Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId)   
      FROM  dbo.VendorRFQPurchaseOrderPart VRPP   
      WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND VRPP.IsDeleted=0 AND VRPP.IsActive=1 ) > 1 --AND LEN(isnull(SP.Manufacturer,'')) >0  
      ) Then 'Multiple' ELse  isnull(SP.Manufacturer,'')   End)  
      as 'ManufacturerType',  
      (Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId)   
      FROM  dbo.VendorRFQPurchaseOrderPart VRPP   
      WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND VRPP.IsDeleted=0 AND VRPP.IsActive=1 ) > 1 --AND LEN(isnull(SP.Priority,'')) >0  
      )Then 'Multiple' ELse  isnull(SP.Priority,'')   End)  
      as 'PriorityType',  
      (Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId)   
      FROM  dbo.VendorRFQPurchaseOrderPart VRPP   
      WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND VRPP.IsDeleted=0 AND VRPP.IsActive=1 ) > 1 --AND LEN(isnull(SP.Condition,'')) >0  
      )Then 'Multiple' ELse  isnull(SP.Condition,'')   End)  
      as 'ConditionType',  

      (Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId)   
      FROM  dbo.VendorRFQPurchaseOrderPart VRPP   
      WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND VRPP.IsDeleted=0 AND VRPP.IsActive=1) > 1 --AND LEN(isnull(SP.PurchaseOrderNumber,'')) >0  
      ) Then 'Multiple' ELse  isnull(SP.PurchaseOrderNumber,'')   End)  
      as 'PurchaseOrderNumberType',  
      (Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId)   
      FROM  dbo.VendorRFQPurchaseOrderPart VRPP   
      WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND VRPP.IsDeleted=0 AND VRPP.IsActive=1) > 1  --AND LEN(isnull(SP.Memo,'')) >0  
      ) Then 'Multiple' ELse  isnull(SP.Memo,'')   End)  
      as 'MemoType',  
      '' AS Level1Type,  
      '' AS Level2Type,  
      '' AS Level3Type,  
      '' AS Level4Type,
      (Case When ((SELECT Count(VRPP.VendorRFQPurchaseOrderId)   
      FROM  dbo.VendorRFQPurchaseOrderPart VRPP   
      WHERE VRPP.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId AND VRPP.IsDeleted=0 AND VRPP.IsActive=1) > 1  --AND LEN(isnull(SP.Level1,'')) >0  
      ) Then 'Multiple' ELse  isnull(MSD.AllMSlevels,'')   End)  
      as 'AllMSlevels',
	  --SP.NeedByDate as 'NeedByDateType',
	  (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse CONVERT(varchar, SP.NeedByDate, 101)  End)  as 'NeedByDate',
	  (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse CONVERT(varchar, SP.NeedByDate, 101) End)  as 'NeedByDateType',
	  (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse CONVERT(varchar, SP.PromisedDate, 101) End)  as 'PromisedDate',
	  (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse CONVERT(varchar, SP.PromisedDate, 101) End)  as 'PromisedDateType',
	  (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse SP.PartNumber End)  as 'PartNumberType',
	  (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse SP.PartNumber End)  as 'PartNumber',   
	  (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MSD.LastMSLevel End)  as 'LastMSLevel',
	  (Case When Count(SP.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MSD.LastMSLevel End)  as 'LastMSLevelType',
      (CASE WHEN COUNT(SP.VendorRFQPOPartRecordId) > 1 AND MAX(WorkOrderRefNumber.RefNumber) = 'Multiple' Then 'Multiple' ELse MAX(WorkOrderRefNumber.RefNumber) End)  as 'WorkOrderNoType',    
	  (CASE WHEN COUNT(SP.VendorRFQPOPartRecordId) > 1 AND MAX(SalesOrderRefNumber.RefNumber) = 'Multiple' Then 'Multiple' ELse MAX(SalesOrderRefNumber.RefNumber) End)  as 'SalesOrderNoType',    
	  (CASE WHEN COUNT(SP.VendorRFQPOPartRecordId) > 1 AND MAX(SubWorkOrderRefNumber.RefNumber) = 'Multiple' Then 'Multiple' ELse  MAX(SubWorkOrderRefNumber.RefNumber) End)  as 'SubWorkOrderNoType'  
     INTO #TEMPRes
	 from Main M  
     LEFT JOIN VendorRFQPurchaseOrderPart SP ON SP.VendorRFQPurchaseOrderId=M.VendorRFQPurchaseOrderId AND SP.IsDeleted=0 AND SP.IsActive=1  
     LEFT JOIN dbo.PurchaseOrderManagementStructureDetails MSD ON MSD.ModuleID = 21 AND MSD.ReferenceID = SP.VendorRFQPOPartRecordId 
	   OUTER APPLY(    
         SELECT case when COUNT(1) > 1 then 'Multiple' else MAX(I.WorkOrderNum) end 'RefNumber'  
          FROM dbo.VendorRFQPurchaseOrderPartReference popr WITH (NOLOCK) 
          LEFT JOIN  [DBO].[WorkOrder] I WITH (NOLOCK) On POPR.ReferenceId = I.WorkOrderId  
          WHERE POPR.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId -- and pop.PurchaseOrderPartRecordId = POPR.PurchaseOrderPartId 
          and POPR.ModuleId = 1
         ) AS WorkOrderRefNumber 
           OUTER APPLY(    
         SELECT  case when COUNT(1) > 1 then 'Multiple' else MAX(S.SalesOrderNumber) end 'RefNumber'
          FROM dbo.VendorRFQPurchaseOrderPartReference popr WITH (NOLOCK) 
          LEFT JOIN  [DBO].[SalesOrder] S WITH (NOLOCK) On POPR.ReferenceId = S.SalesOrderId 
          WHERE POPR.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId -- and pop.PurchaseOrderPartRecordId = POPR.PurchaseOrderPartId 
          and POPR.ModuleId = 3
         ) AS SalesOrderRefNumber 
           OUTER APPLY(    
         SELECT  case when COUNT(1) > 1 then 'Multiple' else MAX(SWO.SubWorkOrderNo) end 'RefNumber'
          FROM dbo.VendorRFQPurchaseOrderPartReference popr WITH (NOLOCK) 
          LEFT JOIN  [DBO].[SubWorkOrder] SWO WITH (NOLOCK) On POPR.ReferenceId = SWO.SubWorkOrderId  
          WHERE POPR.VendorRFQPurchaseOrderId = M.VendorRFQPurchaseOrderId -- and pop.PurchaseOrderPartRecordId = POPR.PurchaseOrderPartId 
          and POPR.ModuleId = 5
		) AS SubWorkOrderRefNumber   
    
     GROUP BY M.VendorRFQPurchaseOrderId,VendorRFQPurchaseOrderNumber,OpenDate,ClosedDate,M.CreatedDate,M.CreatedBy,M.UpdatedDate,  
     M.UpdatedBy,M.IsActive,M.IsDeleted,M.StatusId,VendorId,VendorName,VendorCode,M.[Status],UnitCost,QuantityOrdered,  
     RequestedBy,SP.PartNumber,SP.PartDescription, 
     SP.StockType ,
	 SP.VendorRFQPurchaseOrderId
     ,SP.Manufacturer,SP.Priority,SP.NeedByDate,SP.PromisedDate,sp.Memo,sp.Level1,sp.Level2,sp.Level3,sp.Level4  
     ,SP.Condition,SP.WorkOrderNo,SP.SubWorkOrderNo,SP.SalesOrderNo,SP.PurchaseOrderNumber,MSD.LastMSLevel,MSD.AllMSlevels--,Level1,Level2,Level3,Level4,Memo--,PurchaseOrderId  

   --CTE_Count AS (Select COUNT(VendorRFQPurchaseOrderId) AS NumberOfItems FROM result)  
   --SELECT @Count = COUNT(VendorRFQPurchaseOrderId) FROM #TempResult 
   --select * from #TEMPRes
  SELECT * INTO #TEMPData FROM #TEMPRes
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
     (PurchaseOrderNumberType LIKE '%' +@GlobalFilter+'%') OR  
     (NeedByDateType LIKE '%' +@GlobalFilter+'%') OR  
     (PromisedDateType LIKE '%' +@GlobalFilter+'%') OR  
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
     (ISNULL(@NeedByDate,'') ='' OR NeedByDateType LIKE '%' + @NeedByDate + '%') AND  
     (ISNULL(@PromisedDate,'') ='' OR PromisedDateType LIKE '%' + @PromisedDate + '%') AND  
     (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber + '%') AND  
     (ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND  
     (ISNULL(@StockType,'') ='' OR StockTypeType LIKE '%' + @StockType + '%') AND  
     (ISNULL(@Manufacturer,'') ='' OR ManufacturerType LIKE '%' + @Manufacturer + '%') AND  
     (ISNULL(@Priority,'') ='' OR PriorityType LIKE '%' + @Priority + '%') AND  
     (ISNULL(@Condition,'') ='' OR ConditionType LIKE '%' + @Condition + '%') AND  
     (ISNULL(@UnitCost,'') ='' OR CAST(UnitCost AS varchar(10)) LIKE '%' + CAST(@UnitCost AS VARCHAR(10))+ '%') AND  
     (ISNULL(@QuantityOrdered,'') ='' OR QuantityOrdered LIKE '%' + @QuantityOrdered + '%') AND  
     (ISNULL(@WorkOrderNo,'') ='' OR WorkOrderNoType LIKE '%' + @WorkOrderNo + '%') AND  
     (ISNULL(@SubWorkOrderNo,'') ='' OR SubWorkOrderNoType LIKE '%' + @SubWorkOrderNo + '%') AND  
     (ISNULL(@SalesOrderNo,'') ='' OR SalesOrderNoType LIKE '%' + @SalesOrderNo + '%') AND  
     (ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumberType LIKE '%' + @PurchaseOrderNumber + '%') AND  
     (ISNULL(@Memo,'') ='' OR MemoType LIKE '%' + @Memo + '%') AND  
     --(ISNULL(@mgmtStructure,'') ='' OR Level1 LIKE '%' + @mgmtStructure + '%') AND  
     --(ISNULL(@Level2Type,'') ='' OR Level2 LIKE '%' + @Level2Type + '%') AND  
     --(ISNULL(@Level3Type,'') ='' OR Level3 LIKE '%' + @Level3Type + '%') AND  
     --(ISNULL(@Level4Type,'') ='' OR Level4 LIKE '%' + @Level4Type + '%') AND       
     (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date))) )


	 SELECT VendorRFQPurchaseOrderId,VendorRFQPurchaseOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,  
     UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered  
     ,RequestedBy,
	 (Case When (SELECT Count(tc.VendorRFQPurchaseOrderId) FROM #TEMPData tc WHERE td.VendorRFQPurchaseOrderId = tc.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MAX(td.PartNumber) End)  as 'PartNumber',
	 (Case When (SELECT Count(tc.VendorRFQPurchaseOrderId) FROM #TEMPData tc WHERE td.VendorRFQPurchaseOrderId = tc.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MAX(td.PartDescription) End)  as 'PartDescription',
	 (Case When (SELECT Count(tc.VendorRFQPurchaseOrderId) FROM #TEMPData tc WHERE td.VendorRFQPurchaseOrderId = tc.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MAX(td.PartNumberType) End)  as 'PartNumberType',
	 (Case When (SELECT Count(tc.VendorRFQPurchaseOrderId) FROM #TEMPData tc WHERE td.VendorRFQPurchaseOrderId = tc.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MAX(td.PartDescriptionType) End)  as 'PartDescriptionType',

	 StockTypeType,  
     ManufacturerType,PriorityType,
	 NeedByDate,
	 PromisedDate,
	 NeedByDateType,
	 PromisedDateType,
	 ConditionType,WorkOrderNoType,SubWorkOrderNoType,SalesOrderNoType,PurchaseOrderNumberType  
       
     ,@TotalCount as NumberOfItems,Level1Type,Level2Type,Level3Type,Level4Type,MemoType,LastMSLevel,AllMSlevels,LastMSLevelType  
   INTO #finalTemp FROM #TEMPData td
   group by  
   VendorRFQPurchaseOrderId,VendorRFQPurchaseOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,  
     UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered  
     ,RequestedBy,
	 --PartNumber,PartDescription,PartNumberType,PartDescriptionType,
	 StockTypeType,  
     ManufacturerType,PriorityType,
	 NeedByDate,
	 PromisedDate,
	 NeedByDateType,
	 PromisedDateType,
	 ConditionType,WorkOrderNoType,SubWorkOrderNoType,SalesOrderNoType,PurchaseOrderNumberType 
       
     ,Level1Type,Level2Type,Level3Type,Level4Type,MemoType,LastMSLevel,AllMSlevels,LastMSLevelType 

	 	 SET @TotalCount = (SELECT COUNT(VendorRFQPurchaseOrderId) FROM #finalTemp)
   SELECT VendorRFQPurchaseOrderId,VendorRFQPurchaseOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,  
     UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered  
     ,RequestedBy,
	 --(Case When (SELECT Count(tc.VendorRFQPurchaseOrderId) FROM #TEMPData tc WHERE td.VendorRFQPurchaseOrderId = tc.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MAX(td.PartNumber) End)  as 'PartNumber',
	 --(Case When (SELECT Count(tc.VendorRFQPurchaseOrderId) FROM #TEMPData tc WHERE td.VendorRFQPurchaseOrderId = tc.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MAX(td.PartDescription) End)  as 'PartDescription',
	 --(Case When (SELECT Count(tc.VendorRFQPurchaseOrderId) FROM #TEMPData tc WHERE td.VendorRFQPurchaseOrderId = tc.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MAX(td.PartNumberType) End)  as 'PartNumberType',
	 --(Case When (SELECT Count(tc.VendorRFQPurchaseOrderId) FROM #TEMPData tc WHERE td.VendorRFQPurchaseOrderId = tc.VendorRFQPurchaseOrderId) > 1 Then 'Multiple' ELse MAX(td.PartDescriptionType) End)  as 'PartDescriptionType',
	PartNumber,
	PartDescription,
	PartNumberType,
	PartDescriptionType,
	 StockTypeType,  
     ManufacturerType,PriorityType,
	 NeedByDate,
	 PromisedDate,
	 NeedByDateType,
	 PromisedDateType,
	 ConditionType,WorkOrderNoType,SubWorkOrderNoType,SalesOrderNoType,PurchaseOrderNumberType  
       
     ,@TotalCount as NumberOfItems,Level1Type,Level2Type,Level3Type,Level4Type,MemoType,LastMSLevel,AllMSlevels,LastMSLevelType 
     FROM #finalTemp td  
   group by  
   VendorRFQPurchaseOrderId,VendorRFQPurchaseOrderNumber,OpenDate,ClosedDate,CreatedDate,CreatedBy,UpdatedDate,  
     UpdatedBy,IsActive,IsDeleted,StatusId,VendorId,VendorName,VendorCode,[Status],UnitCost,QuantityOrdered  
     ,RequestedBy,
	 PartNumber,PartDescription,PartNumberType,PartDescriptionType,
	 StockTypeType,  
     ManufacturerType,PriorityType,
	 NeedByDate,
	 PromisedDate,
	 NeedByDateType,
	 PromisedDateType,
	 ConditionType,WorkOrderNoType,SubWorkOrderNoType,SalesOrderNoType,PurchaseOrderNumberType 
       
     ,Level1Type,Level2Type,Level3Type,Level4Type,MemoType,LastMSLevel,AllMSlevels,LastMSLevelType  
   ORDER BY    
   
   CASE WHEN (@SortOrder=1  AND @SortColumn='VendorRFQPurchaseOrderId')  THEN VendorRFQPurchaseOrderId END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQPurchaseOrderId')  THEN VendorRFQPurchaseOrderId END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='vendorName')  THEN VendorName END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='vendorName')  THEN VendorName END DESC,     
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
  
   CASE WHEN (@SortOrder=1  AND @SortColumn='partNumberType')  THEN PartNumber END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='partNumberType')  THEN PartNumber END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,  
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
   CASE WHEN (@SortOrder=1  AND @SortColumn='WorkOrderNoType')  THEN WorkOrderNoType END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderNoType')  THEN WorkOrderNoType END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='SubWorkOrderNoType')  THEN SubWorkOrderNoType END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='SubWorkOrderNoType')  THEN SubWorkOrderNoType END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='SalesOrderNoType')  THEN SalesOrderNoType END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesOrderNoType')  THEN SalesOrderNoType END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='MemoType')  THEN MemoType END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='MemoType')  THEN MemoType END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='mgmtStructure')  THEN Level1Type END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='mgmtStructure')  THEN Level1Type END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='Status')  THEN Status END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='Status')  THEN Status END DESC,  
   CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumberType')  THEN PurchaseOrderNumberType END ASC,  
   CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumberType')  THEN PurchaseOrderNumberType END DESC  
  
   OFFSET @RecordFrom ROWS   
   FETCH NEXT @PageSize ROWS ONLY  
  --END  
  --COMMIT  TRANSACTION  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   --ROLLBACK TRAN;  
   SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;

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