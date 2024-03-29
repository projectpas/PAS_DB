﻿-----------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [SearchPORODataByPartNumber]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used SearchPORODataByPartNumber 
 ** Purpose:         
 ** Date:   02/05/2022        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/05/20221   Subhash Saliya		Created
     
-- EXEC [SearchPORODataByPartNumber] 44
**************************************************************/
Create   PROCEDURE [dbo].[SearchPORODataByPartNumber]
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50) = null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@Module varchar(50) = null,
	@RefId bigint = null,
	@PORO varchar(50) = null,
	@OpenDate datetime = null,
	@PartNumber varchar(50) = null,
	@PartDescription varchar(100) = null,
	@Requisitioner varchar(50) = null,
	@Age int = null,
	@Amount decimal(18, 2) = null,
	@Currency varchar(50) = null,
	@Vendor varchar(50) = null,
	@WorkOrderNo varchar(50) = null,
	@SalesOrderNo varchar(50) = null,
	@PromisedDate datetime = null,
	@EstRecdDate datetime = null,
	@Status varchar(50) = null,
    @IsDeleted bit = null,
	@MasterCompanyId int = null,
	@EmployeeId bigint = 1,
	@QuantityOrdered varchar(50) = null,
	@Condition varchar(50) = null,
	@ItemMasterid bigint = null
	
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
				DECLARE @POModuleId int =5;
				DECLARE @ROModuleId int =25;
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

				;With Result AS(
				SELECT 'PO' AS 'Module', POP.PurchaseOrderPartRecordId AS 'RefId', PO.PurchaseOrderId AS 'POROId', PO.PurchaseOrderNumber AS 'PORO', PO.OpenDate, POP.PartNumber, POP.PartDescription, PO.Requisitioner, 
				(DATEDIFF(day, PO.OpenDate, GETDATE())) AS 'Age', POP.VendorListPrice AS 'Amount', POP.FunctionalCurrency AS 'Currency', 
				PO.VendorName AS 'Vendor', POP.WorkOrderNo, POP.SalesOrderNo, PO.NeedByDate AS 'PromisedDate', POP.EstDeliveryDate AS 'EstRecdDate', PO.Status,POP.QuantityOrdered,POP.Condition,po.VendorCode,po.VendorId FROM 
				DBO.PurchaseOrderPart POP INNER JOIN DBO.PurchaseOrder PO ON PO.PurchaseOrderId = POP.PurchaseOrderId
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @POModuleId AND MSD.ReferenceID = POP.PurchaseOrderPartRecordId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON POP.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where  POP.ItemMasterId=@ItemMasterid
				AND (PO.IsDeleted = @IsDeleted) 
				AND PO.MasterCompanyId = @MasterCompanyId
				UNION
				SELECT 'RO' AS 'Module', ROP.RepairOrderPartRecordId AS 'RefId', RO.RepairOrderId AS 'POROId', RO.RepairOrderNumber AS 'PORO', RO.OpenDate, ROP.PartNumber, ROP.PartDescription, RO.Requisitioner, 
				(DATEDIFF(day, RO.OpenDate, GETDATE())) AS 'Age', ROP.VendorListPrice AS 'Amount', ROP.FunctionalCurrency AS 'Currency', 
				RO.VendorName AS 'Vendor', ROP.WorkOrderNo, ROP.SalesOrderNo, RO.NeedByDate AS 'PromisedDate', ROP.EstRecordDate AS 'EstRecdDate', RO.Status,ROP.QuantityOrdered,ROP.Condition,RO.VendorCode,RO.VendorId FROM 
				DBO.RepairOrderPart ROP INNER JOIN DBO.RepairOrder RO ON RO.RepairOrderId = ROP.RepairOrderId
				INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROModuleId AND MSD.ReferenceID = ROP.RepairOrderPartRecordId
	            INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON ROP.ManagementStructureId = RMS.EntityStructureId
	            INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				Where ROP.ItemMasterId=@ItemMasterid
				AND (RO.IsDeleted = @IsDeleted)
				AND RO.MasterCompanyId = @MasterCompanyId),
				FinalResult AS (
				SELECT Module, RefId, POROId, PORO, OpenDate, PartNumber, PartDescription, Requisitioner, Age, 
				Amount, Currency, Vendor, WorkOrderNo, SalesOrderNo, PromisedDate, EstRecdDate, Status,QuantityOrdered,Condition,VendorCode,VendorId FROM Result
				where (
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
							(QuantityOrdered like '%' + @GlobalFilter +'%') OR
							(Condition like '%' + @GlobalFilter +'%') OR
							(Status like '%' + @GlobalFilter +'%')
							))
							OR   
							(@GlobalFilter = '' AND 
							(IsNull(@Module, '') = '' OR Module like  '%'+ @Module +'%') and 
							(IsNull(@PORO, '') = '' OR PORO like  '%'+ @PORO +'%') and
							(IsNull(@OpenDate, '') = '' OR Cast(OpenDate as Date) = Cast(@OpenDate as date)) and
							(IsNull(@PartNumber, '') = '' OR PartNumber like '%'+ @PartNumber +'%') and
							(IsNull(@PartDescription, '') = '' OR PartDescription like '%'+ @PartDescription +'%') and
							(IsNull(@Requisitioner, '') = '' OR Requisitioner like '%'+ @Requisitioner +'%') and
							(IsNull(@Currency, '') = '' OR Currency like '%'+ @Currency +'%') and
							(IsNull(@Vendor, '') = '' OR Vendor like '%'+ @Vendor +'%') and
							(IsNull(@WorkOrderNo, '') = '' OR WorkOrderNo like '%'+ @WorkOrderNo +'%') and
							(IsNull(@SalesOrderNo, '') = '' OR SalesOrderNo like '%'+ @SalesOrderNo +'%') and
							(IsNull(@PromisedDate, '') = '' OR Cast(PromisedDate as Date) = Cast(@PromisedDate as date)) and
							(IsNull(@EstRecdDate, '') = '' OR Cast(EstRecdDate as Date) = Cast(@EstRecdDate as date)) and
							(IsNull(@QuantityOrdered, '') = '' OR QuantityOrdered like '%'+ @QuantityOrdered +'%') and
							(IsNull(@Condition, '') = '' OR Condition like '%'+ @Condition +'%') and
							(IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%'))
							)),
					ResultCount AS (Select COUNT(PORO) AS NumberOfItems FROM FinalResult)

					SELECT Module, RefId, POROId, PORO, OpenDate, PartNumber, PartDescription, Requisitioner, Age, 
					Amount, Currency, Vendor, WorkOrderNo, SalesOrderNo, PromisedDate, EstRecdDate, Status,QuantityOrdered,Condition,VendorCode,VendorId,NumberOfItems FROM FinalResult, ResultCount
				ORDER BY  
				CASE WHEN (@SortOrder=1 and @SortColumn='MODULE')  THEN Module END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='REFID')  THEN RefId END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PORO')  THEN PORO END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='REQUISITIONER')  THEN Requisitioner END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='AGE')  THEN Age END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='AMOUNT')  THEN Amount END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='CURRENCY')  THEN Currency END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='VENDOR')  THEN Vendor END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNO')  THEN WorkOrderNo END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNO')  THEN SalesOrderNo END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDDATE')  THEN PromisedDate END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='ESTRECDDATE')  THEN EstRecdDate END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='QuantityOrdered')  THEN QuantityOrdered END ASC,
				CASE WHEN (@SortOrder=1 and @SortColumn='Condition')  THEN Condition END ASC,

				CASE WHEN (@SortOrder=-1 and @SortColumn='MODULE')  THEN Module END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='REFID')  THEN RefId END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PORO')  THEN PORO END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='REQUISITIONER')  THEN Requisitioner END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='AGE')  THEN Age END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='AMOUNT')  THEN Amount END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='CURRENCY')  THEN Currency END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='VENDOR')  THEN Vendor END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNO')  THEN WorkOrderNo END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNO')  THEN SalesOrderNo END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDDATE')  THEN PromisedDate END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='ESTRECDDATE')  THEN EstRecdDate END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='QuantityOrdered')  THEN QuantityOrdered END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='Condition')  THEN Condition END DESC,
				CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC

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