
/*************************************************************           
 ** File:   [GetPurchaseOrderHistory]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get purchase order history   
 ** Purpose:         
 ** Date:    01/04/2024
          
 ** PARAMETERS:    

 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    01/04/2024   Vishal Suthar		Modified the SP to convert outer join for the performance issue
	2    01-02-2024   Shrey Chandegara  Modified for add from date and t odate 
     
**************************************************************/
CREATE   PROCEDURE [dbo].[GetPurchaseOrderHistory]
@PageNumber int = 1,
@PageSize int = 10,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = '',	
@PurchaseOrderNumber varchar(50) = NULL,
@PODate datetime = NULL,
@EstDeliveryDate  datetime = NULL,
@VendorName varchar(50) = NULL,
@Partnumber varchar(50) = NULL,
@PartDescription varchar(100) = NULL,
@UnitCost decimal = 0,
@QuoteNumber varchar(100) = NULL,
@QuoteDate datetime = NULL,
@Condition varchar(100) = NULL,
@EmployeeId bigint=61,
@MasterCompanyId bigint=1,
@ItemMasterId bigint=7,
@ViewType varchar(50)='poview',
@FromDate datetime = NULL,
@ToDate datetime = NULL
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;
		DECLARE @MSModuleID INT = 4; -- Employee Management Structure Module ID
		DECLARE @VendorRFQPO INT = 20; -- Employee Management Structure Module ID
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END
		
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			SELECT * INTO #TempStkList FROM (SELECT ST.ReceivedDate, ST.ItemMasterId, ST.PurchaseOrderId, ST.PurchaseOrderPartRecordId FROM DBO.Stockline ST WITH (NOLOCK) WHERE ST.MasterCompanyId = @MasterCompanyId AND ST.IsParent = 1 AND ISNULL(ST.PurchaseOrderId, 0) != 0 AND ISNULL(ST.PurchaseOrderPartRecordId, 0) != 0) AS Stk;

			IF(@ViewType = 'poview')
			BEGIN		

			;WITH Result AS(									
		   		SELECT PO.PurchaseOrderId, POP.ItemMasterId,IM.partnumber as 'PartNumber',IM.PartDescription,PO.PurchaseOrderNumber,PO.OpenDate as 'PODate',
				--POP.EstDeliveryDate as 'ReceivedDate',
				F.ReceiveDate as 'ReceivedDate',
				PO.VendorId,VN.VendorName as 'VendorName',VN.VendorCode as 'VendorCode',VRFQPO.VendorRFQPurchaseOrderNumber AS 'QuoteNumber',
				VRFQPO.OpenDate as 'QuoteDate',POP.Memo,POP.UnitCost,CN.[Description] as 'Condition',CN.ConditionId,
				DATEDIFF(day, PO.OpenDate, F.ReceiveDate) AS TAT from PurchaseOrderPart POP WITH (NOLOCK)
				INNER JOIN PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId
				INNER JOIN ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId
				INNER JOIN Vendor VN WITH (NOLOCK) ON VN.VendorId = PO.VendorId
				LEFT JOIN VendorRFQPurchaseOrder VRFQPO WITH (NOLOCK) ON PO.VendorRFQPurchaseOrderId = VRFQPO.VendorRFQPurchaseOrderId
				--LEFT JOIN VendorRFQPurchaseOrderPart VRFQPOP WITH (NOLOCK) ON POP.ItemMasterId = VRFQPOP.ItemMasterId AND POP.PurchaseOrderId = VRFQPOP.PurchaseOrderId
				INNER JOIN Condition CN WITH (NOLOCK) ON CN.ConditionId = POP.ConditionId
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				OUTER APPLY
			    (
					SELECT TOP 1 ST.ReceivedDate AS ReceiveDate from #TempStkList ST WITH (NOLOCK) WHERE ST.ItemMasterId = POP.ItemMasterId AND ST.PurchaseOrderId = POP.PurchaseOrderId AND ST.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId
					ORDER BY ST.ReceivedDate ASC
		        ) F
				WHERE (@ItemMasterId = 0 OR POP.ItemMasterId = @ItemMasterId) AND (PO.IsDeleted = 0) AND POP.isParent= 1
				  AND PO.MasterCompanyId = @MasterCompanyId
				  AND PO.CreatedDate between @FromDate  AND  @ToDate
			), ResultCount AS(Select COUNT(PurchaseOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(QuoteNumber LIKE '%' +@GlobalFilter+'%') OR
					--(UnitCost LIKE '%' +@GlobalFilter+'%') OR
					(Condition LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber+'%') AND 
					(ISNULL(@Partnumber,'') ='' OR PartNumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@QuoteNumber,'') ='' OR QuoteNumber LIKE '%' + @QuoteNumber + '%') AND
					--(ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%'))
				   )

			SELECT @Count = COUNT(PurchaseOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PODate')  THEN PODate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PODate')  THEN PODate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN PurchaseOrderId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN PurchaseOrderId END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
			;WITH Result AS(									
		   		select PO.VendorRFQPurchaseOrderId as 'PurchaseOrderId', POP.ItemMasterId,IM.partnumber as 'PartNumber',IM.PartDescription,P.PurchaseOrderNumber,PO.OpenDate as 'PODate',
				F.ReceiveDate as 'ReceivedDate',
				PO.VendorId,VN.VendorName as 'VendorName',VN.VendorCode as 'VendorCode',PO.VendorRFQPurchaseOrderNumber AS 'QuoteNumber',
				PO.OpenDate as 'QuoteDate',POP.Memo,POP.UnitCost,CN.[Description] as 'Condition',CN.ConditionId,
				DATEDIFF(day, PO.OpenDate, F.ReceiveDate) AS TAT from VendorRFQPurchaseOrderPart POP WITH (NOLOCK)
				INNER JOIN VendorRFQPurchaseOrder PO WITH (NOLOCK) ON PO.VendorRFQPurchaseOrderId = POP.VendorRFQPurchaseOrderId
				INNER JOIN ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId
				INNER JOIN Vendor VN WITH (NOLOCK) ON VN.VendorId = PO.VendorId
				LEFT JOIN PurchaseOrder P WITH (NOLOCK) ON P.PurchaseOrderId = POP.PurchaseOrderId
				LEFT JOIN PurchaseOrderPart VRFQPO WITH (NOLOCK) ON POP.ItemMasterId = VRFQPO.ItemMasterId AND P.PurchaseOrderId = VRFQPO.PurchaseOrderId AND POP.ConditionId = VRFQPO.ConditionId
				INNER JOIN Condition CN WITH (NOLOCK) ON CN.ConditionId = POP.ConditionId
				INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @VendorRFQPO AND MSD.ReferenceID = PO.VendorRFQPurchaseOrderId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				OUTER APPLY
			    (
					SELECT TOP 1 ST.ReceivedDate AS ReceiveDate from #TempStkList ST WHERE ST.ItemMasterId = VRFQPO.ItemMasterId AND ST.PurchaseOrderId = VRFQPO.PurchaseOrderId AND ST.PurchaseOrderPartRecordId = VRFQPO.PurchaseOrderPartRecordId
					ORDER BY ST.ReceivedDate ASC
		        ) F
				WHERE (@ItemMasterId = 0 OR POP.ItemMasterId=@ItemMasterId) AND (PO.IsDeleted = 0) --AND EMS.EmployeeId = 	@EmployeeId 
				  AND PO.MasterCompanyId = @MasterCompanyId
				  AND PO.CreatedDate between @FromDate  AND  @ToDate
			), ResultCount AS(Select COUNT(PurchaseOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult1 FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(QuoteNumber LIKE '%' +@GlobalFilter+'%') OR
					(Condition LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber+'%') AND 
					(ISNULL(@Partnumber,'') ='' OR PartNumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@QuoteNumber,'') ='' OR QuoteNumber LIKE '%' + @QuoteNumber + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%'))
				   )

			SELECT @Count = COUNT(PurchaseOrderId) FROM #TempResult1			

			SELECT *, @Count AS NumberOfItems FROM #TempResult1
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PODate')  THEN PODate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PODate')  THEN PODate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN PurchaseOrderId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN PurchaseOrderId END DESC
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
            , @AdhocComments     VARCHAR(150)    = 'GetPurchaseOrderHistory' 
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