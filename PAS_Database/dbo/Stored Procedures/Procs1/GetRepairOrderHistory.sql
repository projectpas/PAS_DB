/*********************           
 ** File:   [GetRepairOrderHistory]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get repair order history   
 ** Purpose:         
 ** Date:    01/04/2024
          
 ** PARAMETERS:    

 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    01/04/2024   Vishal Suthar		Modified the SP to convert outer join for the performance issue
	2    01-02-2024   Shrey Chandegara  Modified for add from date and t odate 
    3    02-07-2024   Sahdev Saliya     Added Global Filters ,Set Listing Order With RepairOrderNumber or QuoteNumber and Sorting (UnitCost)
**********************/
CREATE   PROCEDURE [dbo].[GetRepairOrderHistory]
@PageNumber int = 1,
@PageSize int = 10,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = '',	
@RepairOrderNumber varchar(50) = NULL,
@PODate datetime = NULL,
@EstDeliveryDate  datetime = NULL,
@VendorName varchar(50) = NULL,
@Partnumber varchar(50) = NULL,
@PartDescription varchar(100) = NULL,
@UnitCost VARCHAR(50) = NULL,
@QuoteNumber varchar(100) = NULL,
@QuoteDate datetime = NULL,
@Condition varchar(100) = NULL,
@EmployeeId bigint=61,
@MasterCompanyId bigint=1,
@ItemMasterId bigint=7,
@ViewType varchar(50),
@FromDate datetime = NULL,
@ToDate datetime = NULL
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;
		DECLARE @MSModuleID INT = 24; -- Employee Management Structure Module ID
		DECLARE @VendorRFQRO INT = 22; -- Employee Management Structure Module ID
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=CASE WHEN @ViewType = 'roview' THEN 'RepairOrderNumber' ELSE 'QuoteNumber' END;
			SET @SortOrder = -1;
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END
		
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			SELECT * INTO #TempStkList FROM (SELECT ST.ReceivedDate, ST.ItemMasterId, ST.RepairOrderId, ST.RepairOrderPartRecordId FROM DBO.Stockline ST WITH (NOLOCK) WHERE ST.MasterCompanyId = @MasterCompanyId AND ST.IsParent = 1 AND ISNULL(ST.RepairOrderId, 0) != 0 AND ISNULL(ST.RepairOrderPartRecordId, 0) != 0) AS Stk;

			IF(@ViewType = 'roview')
			BEGIN
				;WITH Result AS(									
		   			select PO.RepairOrderId, POP.ItemMasterId,IM.partnumber as 'PartNumber',IM.PartDescription,PO.RepairOrderNumber,PO.OpenDate as 'PODate',
					--POP.EstRecordDate as 'ReceivedDate',
					F.ReceiveDate as 'ReceivedDate',
					PO.VendorId,VN.VendorName as 'VendorName',VN.VendorCode as 'VendorCode',VRFQPO.VendorRFQRepairOrderNumber AS 'QuoteNumber',
					VRFQPO.OpenDate as 'QuoteDate',POP.Memo,cast(POP.UnitCost AS VARCHAR) as [UnitCost],CN.[Description] as 'Condition',CN.ConditionId,
					DATEDIFF(day, PO.OpenDate, F.ReceiveDate) AS TAT,POP.RepairOrderPartRecordId as RepairOrderPartId,ISNULL(POP.WorkPerformedId,0) as WorkPerformedId from RepairOrderPart POP WITH (NOLOCK)
					INNER JOIN RepairOrder PO WITH (NOLOCK) ON PO.RepairOrderId = POP.RepairOrderId
					INNER JOIN ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId
					INNER JOIN Vendor VN WITH (NOLOCK) ON VN.VendorId = PO.VendorId
					LEFT JOIN VendorRFQRepairOrder VRFQPO WITH (NOLOCK) ON PO.VendorRFQRepairOrderId = VRFQPO.VendorRFQRepairOrderId
					INNER JOIN Condition CN WITH (NOLOCK) ON CN.ConditionId = POP.ConditionId
					INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.RepairOrderId
					INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
					INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
					OUTER APPLY
					(
						SELECT TOP 1 ST.ReceivedDate AS ReceiveDate from #TempStkList ST WHERE ST.ItemMasterId = POP.ItemMasterId AND ST.RepairOrderId = POP.RepairOrderId AND ST.RepairOrderPartRecordId = POP.RepairOrderPartRecordId
						ORDER BY ST.ReceivedDate ASC
					) F
					--WHERE POP.ItemMasterId=@ItemMasterId AND (PO.IsDeleted = 0) --AND EMS.EmployeeId = 	@EmployeeId
					WHERE (@ItemMasterId = 0 OR POP.ItemMasterId=@ItemMasterId) AND (PO.IsDeleted = 0) AND POP.isParent=1 --AND EMS.EmployeeId = 	@EmployeeId
					AND PO.MasterCompanyId = @MasterCompanyId
					AND PO.CreatedDate between @FromDate  AND  @ToDate
			), ResultCount AS(Select COUNT(RepairOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((RepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(QuoteNumber LIKE '%' +@GlobalFilter+'%') OR
					(UnitCost LIKE '%' +@GlobalFilter+'%') OR
					(Condition LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@RepairOrderNumber,'') ='' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber+'%') AND 
					(ISNULL(@Partnumber,'') ='' OR PartNumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@QuoteNumber,'') ='' OR QuoteNumber LIKE '%' + @QuoteNumber + '%') AND
					(ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%'))
				   )

			SELECT @Count = COUNT(RepairOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PODate')  THEN PODate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PODate')  THEN PODate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
			;WITH Result AS(									
		   		select PO.VendorRFQRepairOrderId as 'RepairOrderId', POP.ItemMasterId,IM.partnumber as 'PartNumber',IM.PartDescription,P.RepairOrderNumber,PO.OpenDate as 'PODate',
				--NULL as 'ReceivedDate',
				F.ReceiveDate as 'ReceivedDate',
				PO.VendorId,VN.VendorName as 'VendorName',VN.VendorCode as 'VendorCode',PO.VendorRFQRepairOrderNumber AS 'QuoteNumber',
				PO.OpenDate as 'QuoteDate',POP.Memo,POP.UnitCost,CN.[Description] as 'Condition',CN.ConditionId,
				DATEDIFF(day, PO.OpenDate, F.ReceiveDate) AS TAT,POP.VendorRFQROPartRecordId as RepairOrderPartId,ISNULL(POP.WorkPerformedId,0)as WorkPerformedId from VendorRFQRepairOrderPart POP WITH (NOLOCK)
				INNER JOIN VendorRFQRepairOrder PO WITH (NOLOCK) ON PO.VendorRFQRepairOrderId = POP.VendorRFQRepairOrderId
				INNER JOIN ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId
				INNER JOIN Vendor VN WITH (NOLOCK) ON VN.VendorId = PO.VendorId
				LEFT JOIN RepairOrder P WITH (NOLOCK) ON P.RepairOrderId = POP.RepairOrderId
				LEFT JOIN RepairOrderPart VRFQPO WITH (NOLOCK) ON POP.ItemMasterId = VRFQPO.ItemMasterId AND P.RepairOrderId = VRFQPO.RepairOrderId AND POP.ConditionId = VRFQPO.ConditionId
				INNER JOIN Condition CN WITH (NOLOCK) ON CN.ConditionId = POP.ConditionId
				INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @VendorRFQRO AND MSD.ReferenceID = PO.VendorRFQRepairOrderId
			    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
				OUTER APPLY
			    (
					SELECT TOP 1 ST.ReceivedDate AS ReceiveDate from #TempStkList ST WHERE ST.ItemMasterId = VRFQPO.ItemMasterId AND ST.RepairOrderId = VRFQPO.RepairOrderId AND ST.RepairOrderPartRecordId = VRFQPO.RepairOrderPartRecordId
					ORDER BY ST.ReceivedDate ASC
		        ) F
				--WHERE POP.ItemMasterId=@ItemMasterId AND (PO.IsDeleted = 0) --AND EMS.EmployeeId = 	@EmployeeId
				WHERE (@ItemMasterId = 0 OR POP.ItemMasterId=@ItemMasterId) AND (PO.IsDeleted = 0) --AND EMS.EmployeeId = 	@EmployeeId
				  AND PO.MasterCompanyId = @MasterCompanyId
				  AND PO.CreatedDate between @FromDate  AND  @ToDate
			), ResultCount AS(Select COUNT(RepairOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult1 FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((RepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(QuoteNumber LIKE '%' +@GlobalFilter+'%') OR
					(UnitCost LIKE '%' +@GlobalFilter+'%') OR
					(Condition LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@RepairOrderNumber,'') ='' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber+'%') AND 
					(ISNULL(@Partnumber,'') ='' OR PartNumber LIKE '%' + @Partnumber + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@QuoteNumber,'') ='' OR QuoteNumber LIKE '%' + @QuoteNumber + '%') AND
					(ISNULL(@UnitCost,'') ='' OR UnitCost LIKE '%' + @UnitCost + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%'))
				   )

			SELECT @Count = COUNT(RepairOrderId) FROM #TempResult1			

			SELECT *, @Count AS NumberOfItems FROM #TempResult1
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PODate')  THEN PODate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PODate')  THEN PODate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC
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
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderNumber, '') + ''
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