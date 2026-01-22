/*************************************************************                 
 ** File:   [SearchPODashboardData]                 
 ** Author:   Satish Gohil      
 ** Description: This stored procedure is used to display PO/RO records in Dashboard    
 ** Purpose:               
 ** Date:   18/05/2023         
             
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change Description                  
 ** --   --------     -------  -------------------------------                
    1    18/05/2023   Satish Gohil   Count Showing issue fixed    
	2    01/01/2025   Hemant Saliya  Removed MS Employee USer Role Join    
**************************************************************/     
      
-- EXEC [dbo].[SearchPODashboardData] 1, 10, null, 1, 1      
CREATE      PROCEDURE [dbo].[SearchPODashboardData]      
 @PageNumber int,      
 @PageSize int,      
 @SortColumn VARCHAR(50) = null,      
 @SortOrder int,      
 @StatusID int,      
 @GlobalFilter VARCHAR(50) = null,      
 @Module VARCHAR(50) = null,      
 @RefId bigint = null,      
 @PORO VARCHAR(50) = null,      
 @OpenDate datetime = null,      
 @PartNumber VARCHAR(50) = null,      
 @PartDescription VARCHAR(100) = null,      
 @Requisitioner VARCHAR(50) = null,      
 @Age VARCHAR(20) = null,      
 @Amount VARCHAR(50) = null,      
 @Currency VARCHAR(50) = null,      
 @Vendor VARCHAR(50) = null,      
 @WorkOrderNo VARCHAR(50) = null,      
 @SalesOrderNo VARCHAR(50) = null,      
 @PromisedDate datetime = null,      
 @EstRecdDate datetime = null,      
 @Status VARCHAR(50) = null,      
 @IsDeleted bit = null,      
 @MasterCompanyId int = null,      
 @EmployeeId bigint = 1      
AS      
BEGIN      
 -- SET NOCOUNT ON added to prevent extra result sets from      
 -- interfering with SELECT statements.      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      
  BEGIN TRANSACTION      
   BEGIN      
    DECLARE @RecordFrom int;      
    DECLARE @POModuleId int =4;      
    DECLARE @ROModuleId int =24;      
    SET @RecordFrom = (@PageNumber-1) * @PageSize;      
          
    IF @SortColumn IS NULL      
    BEGIN      
     SET @SortColumn = Upper('OpenDate')      
    END       
    ELSE      
    BEGIN       
     SET @SortColumn = Upper(@SortColumn)      
    END      
        
    IF @StatusID = 0      
    BEGIN       
     SET @StatusID = null      
    END       
      
    IF @Status = '0'      
    BEGIN      
     SET @Status = null      
    END      

		IF OBJECT_ID(N'tempdb..#tmpPOEmpUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpPOEmpUserRole
		END

		SELECT * INTO #tmpPOEmpUserRole FROM (SELECT DISTINCT
			MSD.ReferenceID,
			RMS.EntityStructureId
		FROM dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK)
		INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) 
			ON MSD.EntityMsId = RMS.EntityStructureId
		INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) 
			ON EUR.RoleId = RMS.RoleId
		WHERE MSD.ModuleID = @POModuleId AND EUR.EmployeeId = @EmployeeId) AS poUserRole

		IF OBJECT_ID(N'tempdb..#tmpROEmpUserRole') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpROEmpUserRole
		END

		SELECT * INTO #tmpROEmpUserRole FROM (SELECT DISTINCT
			MSD.ReferenceID,
			RMS.EntityStructureId
		FROM dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK)
		INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) 
			ON MSD.EntityMsId = RMS.EntityStructureId
		INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) 
			ON EUR.RoleId = RMS.RoleId
		WHERE MSD.ModuleID = @ROModuleId AND EUR.EmployeeId = @EmployeeId) AS roUserRole
      
		;With Result AS(      
		SELECT 'PO' AS 'Module', POP.PurchaseOrderPartRecordId AS 'RefId', PO.PurchaseOrderId AS 'POROId', PO.PurchaseOrderNumber AS 'PORO',     
				PO.OpenDate, POP.PartNumber, POP.PartDescription, PO.Requisitioner,       
				(DATEDIFF(day, PO.OpenDate, GETDATE())) AS 'Age', ISNULL(POP.VendorListPrice, 0) AS 'Amount', POP.FunctionalCurrency AS 'Currency',       
				PO.VendorName AS 'Vendor',  
				(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1  Then 'Multiple' ELse MAX(WorkOrderRefNumber.RefNumber) End)  as 'WorkOrderNo',  
				(CASE WHEN COUNT(POP.PurchaseOrderPartRecordId) > 1 Then 'Multiple' ELse MAX(SalesOrderRefNumber.RefNumber) End)  as 'SalesOrderNo',  
				WorkOrderRefNumber.WONum AS 'WorkOrderNum',
				SalesOrderRefNumber.SONum AS 'SalesOrderNumber',
				PO.NeedByDate AS 'PromisedDate', POP.EstDeliveryDate AS 'EstRecdDate', PO.Status       
		FROM PurchaseOrder PO WITH (NOLOCK)      
			 LEFT JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId AND POP.isParent=1      
			 --INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POModuleId AND MSD.ReferenceID = Po.PurchaseOrderId      
			 --INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId      
			 --INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId     
			 INNER JOIN #tmpPOEmpUserRole DR ON DR.ReferenceID = Po.PurchaseOrderId
			 LEFT JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON POP.SalesOrderId = SO.SalesOrderId      
			 LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON POP.WorkOrderId = WO.WorkOrderId      
			 LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON POP.RepairOrderId = RO.RepairOrderId      
			 LEFT JOIN [dbo].[Manufacturer] M WITH (NOLOCK) ON POP.ManufacturerId = M.ManufacturerId      
			OUTER APPLY(      
				SELECT CASE WHEN COUNT(*) > 1 THEN 'Multiple' ELSE MAX(I.WorkOrderNum) END 'RefNumber'  ,STRING_AGG(I.WorkOrderNum, ',') as 'WONum'    
				FROM dbo.PurchaseOrderPartReference popr WITH (NOLOCK)   
					LEFT JOIN  [DBO].[WorkOrder] I WITH (NOLOCK) On POPR.ReferenceId = I.WorkOrderId    
				WHERE POPR.PurchaseOrderId = PO.PurchaseOrderId  AND pop.PurchaseOrderPartRecordId = POPR.PurchaseOrderPartId   
					AND POPR.ModuleId = 1  
			) AS WorkOrderRefNumber   
			OUTER APPLY(      
				SELECT  case when COUNT(*) > 1 then 'Multiple' else MAX(S.SalesOrderNumber) end 'RefNumber'   ,STRING_AGG(S.SalesOrderNumber, ',') as 'SONum'
				FROM dbo.PurchaseOrderPartReference popr WITH (NOLOCK)   
					LEFT JOIN  [DBO].[SalesOrder] S WITH (NOLOCK) On POPR.ReferenceId = S.SalesOrderId   
				WHERE POPR.PurchaseOrderId = PO.PurchaseOrderId  AND pop.PurchaseOrderPartRecordId = POPR.PurchaseOrderPartId   
					AND POPR.ModuleId = 3  
			) AS SalesOrderRefNumber   
		WHERE POP.QuantityBackOrdered > 0      
			AND ISNULL(PO.IsDeleted, 0) = @IsDeleted AND (@StatusID is null or PO.StatusId = @StatusID)      
			AND PO.MasterCompanyId = @MasterCompanyId   
		GROUP BY PO.PurchaseOrderId, PO.PurchaseOrderNumber,POP.PurchaseOrderPartRecordId,PO.OpenDate, POP.PartNumber, POP.PartDescription,PO.Requisitioner,POP.VendorListPrice,POP.FunctionalCurrency, PO.VendorName ,PO.NeedByDate , POP.EstDeliveryDate, PO.Status, WorkOrderRefNumber.WONum,SalesOrderRefNumber.SONum
      
		UNION All      
      
		SELECT 'RO' AS 'Module', ROP.RepairOrderPartRecordId AS 'RefId', RO.RepairOrderId AS 'POROId', RO.RepairOrderNumber AS 'PORO', RO.OpenDate, ROP.PartNumber, ROP.PartDescription, RO.Requisitioner,       
			(DATEDIFF(day, RO.OpenDate, GETDATE())) AS 'Age', ISNULL(ROP.VendorListPrice, 0) AS 'Amount', ROP.FunctionalCurrency AS 'Currency',       
			RO.VendorName AS 'Vendor', ROP.WorkOrderNo, ROP.SalesOrderNo,'','', RO.NeedByDate AS 'PromisedDate', ROP.EstRecordDate AS 'EstRecdDate', RO.Status 
		FROM  DBO.RepairOrder RO WITH (NOLOCK)      
			LEFT JOIN DBO.RepairOrderPart ROP WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId AND ROP.isParent=1      
			--INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROModuleId AND MSD.ReferenceID = RO.RepairOrderId      
			--INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId      
			--INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId   
			INNER JOIN #tmpROEmpUserRole DR ON DR.ReferenceID = RO.RepairOrderId 

		WHERE ROP.QuantityBackOrdered > 0      
			AND (RO.IsDeleted = @IsDeleted) AND (@StatusID is null or RO.StatusId = @StatusID)      
			AND RO.MasterCompanyId = @MasterCompanyId),      
			FinalResult AS (      
			SELECT Module, RefId, POROId, PORO, OpenDate, PartNumber, PartDescription, Requisitioner, Age,       
			Amount, Currency, Vendor, WorkOrderNo, SalesOrderNo,WorkOrderNum,SalesOrderNumber, PromisedDate, EstRecdDate, Status FROM Result      
		WHERE (      
		   (@GlobalFilter <> '' AND ((Module like '%' + @GlobalFilter +'%' ) OR       
		   (PORO like '%' + @GlobalFilter +'%') OR      
		   (OpenDate like '%' + @GlobalFilter +'%') OR      
		   (PartNumber like '%' + @GlobalFilter +'%') OR      
		   (PartDescription like '%'+ @GlobalFilter +'%') OR      
		   (Requisitioner like '%' + @GlobalFilter +'%') OR      
		   (Currency like '%' + @GlobalFilter +'%') OR      
		   (Vendor like '%' + @GlobalFilter +'%') OR      
		   (WorkOrderNo like '%' + @GlobalFilter +'%') OR      
		   (SalesOrderNo like '%' + @GlobalFilter +'%') OR      
		   (PromisedDate like '%' + @GlobalFilter +'%') OR      
		   (EstRecdDate like '%' + @GlobalFilter +'%') OR   
		   (Status like '%' + @GlobalFilter +'%')  OR    
		(CAST(Age AS VARCHAR(20)) like '%' + @GlobalFilter +'%') OR     
		(CAST(Amount AS VARCHAR(50)) like '%' + @GlobalFilter +'%')    
    
		   ))      
		   OR         
		   (@GlobalFilter = '' AND       
		   (IsNull(@Module, '') = '' OR Module like  '%'+ @Module +'%') AND       
		   (IsNull(@PORO, '') = '' OR PORO like  '%'+ @PORO +'%') AND      
		   (IsNull(@OpenDate, '') = '' OR Cast(OpenDate as Date) = Cast(@OpenDate as date)) AND      
		   (IsNull(@PartNumber, '') = '' OR PartNumber like '%'+ @PartNumber +'%') AND      
		   (IsNull(@PartDescription, '') = '' OR PartDescription like '%'+ @PartDescription +'%') AND      
		   (IsNull(@Requisitioner, '') = '' OR Requisitioner like '%'+ @Requisitioner +'%') AND      
		   (IsNull(@Currency, '') = '' OR Currency like '%'+ @Currency +'%') AND      
		   (IsNull(@Vendor, '') = '' OR Vendor like '%'+ @Vendor +'%') AND      
		   (IsNull(@WorkOrderNo, '') = '' OR WorkOrderNo like '%'+ @WorkOrderNo +'%') AND      
		   (IsNull(@SalesOrderNo, '') = '' OR SalesOrderNo like '%'+ @SalesOrderNo +'%') AND      
		   (IsNull(@PromisedDate, '') = '' OR Cast(PromisedDate as Date) = Cast(@PromisedDate as date)) AND      
		   (IsNull(@EstRecdDate, '') = '' OR Cast(EstRecdDate as Date) = Cast(@EstRecdDate as date)) AND      
		   (IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') AND    
		(IsNull(@Age, '') = '' OR CAST(Age AS VARCHAR(20)) like '%'+ @Age +'%') AND      
		(IsNull(@Amount, '') = '' OR CAST(Amount AS VARCHAR(50)) like '%'+ @Amount +'%'))      
		   )),      
		 ResultCount AS (Select COUNT(PORO) AS NumberOfItems FROM FinalResult)      
      
     SELECT Module, RefId, POROId, PORO, OpenDate, PartNumber, PartDescription, Requisitioner, Age,       
     Amount, Currency, Vendor, WorkOrderNo, SalesOrderNo,WorkOrderNum,SalesOrderNumber, PromisedDate, EstRecdDate, Status, NumberOfItems FROM FinalResult, ResultCount      
    ORDER BY        
    CASE WHEN (@SortOrder=1 AND @SortColumn='MODULE')  THEN Module END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='REFID')  THEN RefId END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='PORO')  THEN POROId END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='OPENDATE')  THEN OpenDate END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='REQUISITIONER')  THEN Requisitioner END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='AGE')  THEN CAST(Age AS VARCHAR(20)) END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='AMOUNT')  THEN CAST(Amount AS VARCHAR(50)) END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='CURRENCY')  THEN Currency END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='VENDOR')  THEN Vendor END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='WORKORDERNO')  THEN WorkOrderNo END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='SALESORDERNO')  THEN SalesOrderNo END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='PROMISEDDATE')  THEN PromisedDate END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='ESTRECDDATE')  THEN EstRecdDate END ASC,      
    CASE WHEN (@SortOrder=1 AND @SortColumn='STATUS')  THEN Status END ASC,      
      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='MODULE')  THEN Module END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='REFID')  THEN RefId END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='PORO')  THEN POROId END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='OPENDATE')  THEN OpenDate END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='REQUISITIONER')  THEN Requisitioner END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='AGE')  THEN CAST(Age AS VARCHAR(20)) END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='AMOUNT')  THEN CAST(Amount AS VARCHAR(50)) END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='CURRENCY')  THEN Currency END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDOR')  THEN Vendor END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='WORKORDERNO')  THEN WorkOrderNo END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESORDERNO')  THEN SalesOrderNo END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='PROMISEDDATE')  THEN PromisedDate END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='ESTRECDDATE')  THEN EstRecdDate END DESC,      
    CASE WHEN (@SortOrder=-1 AND @SortColumn='STATUS')  THEN Status END DESC      
      
    OFFSET @RecordFrom ROWS       
    FETCH NEXT @PageSize ROWS ONLY      
   END      
  COMMIT  TRANSACTION      
      
  END TRY          
 BEGIN CATCH            
  IF @@trancount > 0      
   ROLLBACK TRAN;   
  
  DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        ,@AdhocComments VARCHAR(150) = 'SearchPODashboardData'       
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''      
        ,@ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
        exec spLogException       
                @DatabaseName         =  @DatabaseName      
                ,@AdhocComments       =  @AdhocComments      
                ,@ProcedureParameters =  @ProcedureParameters      
                ,@ApplicationName     =  @ApplicationName      
                ,@ErrorLogID          =  @ErrorLogID OUTPUT;      
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
        RETURN(1);      
 END CATCH      
END