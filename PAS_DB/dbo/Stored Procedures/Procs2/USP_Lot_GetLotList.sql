
/*************************************************************           
 ** File:   [USP_Lot_GetLotList]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Lot Listing 
 ** Date:   03/04/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author  				Change Description            
 ** --   --------		 -------				---------------------------     
    1    03/04/2023		 Rajesh Gami			Created
	2    10/16/2024		 Abhishek Jirawla		Implemented the new tables for SalesOrder related tables
	3    19/02/2025		 Ayushi Patel			converted the date into utc (created) , Added a case to get timeZone
	4    28 May 2026	 Rajesh Gami			Added VendorName [PN-16601]
	5    12 June 2026    Rajesh Gami			Fixed the Amount related issue (PN-16799)
	6    09/July/2026 RAJESH GAMI    [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	7    23/July/2026 RAJESH GAMI    [PN-17350] - Removed leftover IsNonStock=0 exclusion filters.
	8    06/08/2026		 Nakul Chnadigra		Added status Filter [PN-17566]
**************************************************************
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_Lot_GetLotList]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@LotStatusId int = 1,
	@StatusName varchar(50) = 'Open',
	@GlobalFilter varchar(50) = '',
	@LotNumber varchar(50) = NULL,
	@LotName varchar(200) = NULL,
	@ReferenceNumber varchar(100) = NULL,
	@OpenDate datetime = NULL,
	@OriginalCost decimal(18,2) = NULL,
	@ConsignmentNumber varchar(100) = NULL,
	@ConsigneeName varchar(200) = NULL,
	@AcqusitionCost decimal(18,2) = NULL,
	@RemainingCost decimal(18,2) = NULL,
	@RemainingPercentage decimal(18,2) = NULL,
	@Revenue decimal(18,2) = NULL,
	@MarginAmount decimal(18,2) = NULL,
	@Margin decimal(18,2) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy  varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@MasterCompanyId bigint = NULL,
	@EmployeeId bigint,
	@VendorName varchar(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @Count Int;
		DECLARE @RecordFrom int;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
 
		SELECT
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],
					LTZ.[Description]
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
			WHERE
				E.EmployeeId = @EmployeeId;
 
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = Upper('CreatedDate')
			SET @SortOrder = -1
		END
		ELSE
		BEGIN
			Set @SortColumn = Upper(@SortColumn)
		END
 
		;WITH Result AS (
			SELECT DISTINCT
				LT.[LotId] LotId
			   ,UPPER(LT.LotNumber) LotNumber
			   ,UPPER(LT.LotName) LotName
			   ,ISNULL((Select top 1 ISNULL(VendorId,0) from dbo.PurchaseOrder po WITH(NOLOCK) Where po.LotId = Lt.LotId AND ISNULL(po.IsDeleted,0) = 0),0) AS VendorId
			   ,(Select top 1 ISNULL(ven.VendorName,'') from dbo.PurchaseOrder po WITH(NOLOCK) INNER JOIN dbo.Vendor ven WITH(NOLOCK) on po.VendorId = ven.VendorId Where po.LotId = Lt.LotId AND ISNULL(po.IsDeleted,0) = 0) AS VendorName
			   ,ISNULL((Select top 1 ISNULL(PurchaseOrderNumber,'') from dbo.PurchaseOrder po WITH(NOLOCK) Where po.LotId = Lt.LotId AND ISNULL(po.IsDeleted,0) = 0),'') AS ReferenceNumber
			   ,case when CAST(LT.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date) then null else (Cast(DBO.ConvertUTCtoLocal(LT.[CreatedDate], @CurrntEmpTimeZoneDesc) as Date)) end OpenDate
			   ,ISNULL(LT.OriginalCost,0.00) OriginalCost
			   ,LT.LotStatusId
			   ,S.StatusName
			   ,LT.ConsignmentId
			   ,UPPER(LC.ConsignmentNumber) ConsignmentNumber
			   ,UPPER(LC.ConsigneeName) ConsigneeName
			   ,LT.EmployeeId
			   ,LT.ObtainFromId
			   ,LT.ObtainFromTypeId
			   ,LT.TraceableToId
			   ,LT.TraceableToTypeId
			   ,LT.ManagementStructureId
			   ,LT.[MasterCompanyId]
			   ,LT.[CreatedBy]
			   ,LT.[UpdatedBy]
			   ,LT.[CreatedDate]
			   ,LT.[UpdatedDate]
			   ,(
			       -- OriginalCost: InitialPOCost from Lot table
			       ISNULL(LT.InitialPOCost, 0)
 
			       -- RepairCost: SUM of ALL RepairCost rows in LotCalculationDetails
			       + ISNULL((
			           SELECT SUM(ISNULL(RepairCost, 0))
			           FROM dbo.LotCalculationDetails LCD WITH(NOLOCK)
			           WHERE LCD.LotId = LT.LotId
			       ), 0)
 
			       -- TransferredInCost: only 'Trans In (Lot)' type, IsFromPreCostStk = 0
			       + ISNULL((
			           SELECT SUM(ISNULL(TransferredInCost, 0))
			           FROM DBO.LotCalculationDetails LCD WITH(NOLOCK)
			           WHERE LCD.LotId = LT.LotId
			             AND ISNULL(LCD.IsFromPreCostStk, 0) = 0
			             AND UPPER(REPLACE(LCD.[Type], ' ', '')) = UPPER(REPLACE('Trans In (Lot)', ' ', ''))
			       ), 0)
 
			       -- OtherCost (PO): Freight at part-record level
			       + ISNULL((
			           SELECT SUM(ISNULL(PF.Amount, 0))
			           FROM dbo.PurchaseOrder PO WITH(NOLOCK)
			           INNER JOIN dbo.PurchaseOrderPart PP WITH(NOLOCK) ON PP.PurchaseOrderId = PO.PurchaseOrderId
			           INNER JOIN dbo.PurchaseOrderFreight PF WITH(NOLOCK) ON PF.PurchaseOrderPartRecordId = PP.PurchaseOrderPartRecordId
			           WHERE PO.LotId = LT.LotId AND ISNULL(PF.IsDeleted, 0) = 0
			       ), 0)
 
			       -- OtherCost (PO): Charges at part-record level
			       + ISNULL((
			           SELECT SUM(ISNULL(PC.ExtendedCost, 0))
			           FROM dbo.PurchaseOrder PO WITH(NOLOCK)
			           INNER JOIN dbo.PurchaseOrderPart PP WITH(NOLOCK) ON PP.PurchaseOrderId = PO.PurchaseOrderId
			           INNER JOIN dbo.PurchaseOrderCharges PC WITH(NOLOCK) ON PC.PurchaseOrderPartRecordId = PP.PurchaseOrderPartRecordId
			           WHERE PO.LotId = LT.LotId AND ISNULL(PC.IsDeleted, 0) = 0
			       ), 0)
 
			       -- OtherCost (RO): Freight at part-record level
			       + ISNULL((
			           SELECT SUM(ISNULL(RF.Amount, 0))
			           FROM dbo.RepairOrderPart RP WITH(NOLOCK)
			           INNER JOIN dbo.RepairOrderFreight RF WITH(NOLOCK) ON RF.RepairOrderPartRecordId = RP.RepairOrderPartRecordId
			           WHERE RP.LotId = LT.LotId AND ISNULL(RF.IsDeleted, 0) = 0
			       ), 0)
 
			       -- OtherCost (RO): Charges at part-record level
			       + ISNULL((
			           SELECT SUM(ISNULL(RC.ExtendedCost, 0))
			           FROM dbo.RepairOrderPart RP WITH(NOLOCK)
			           INNER JOIN dbo.RepairOrderCharges RC WITH(NOLOCK) ON RC.RepairOrderPartRecordId = RP.RepairOrderPartRecordId
			           WHERE RP.LotId = LT.LotId AND ISNULL(RC.IsDeleted, 0) = 0
			       ), 0)
 
			       -- AdjustmentAmount: Adjustment * QuantityOnHand per Stockline
			       + ISNULL((
			           SELECT SUM(ISNULL(sl.Adjustment, 0) * ISNULL(sl.QuantityOnHand, 0))
			           FROM DBO.LotTransInOutDetails ltin WITH(NOLOCK)
			           INNER JOIN DBO.Stockline sl WITH(NOLOCK) ON ltin.StockLineId = sl.StockLineId
			           WHERE ltin.LotId = LT.LotId
			       ), 0)
			   ) AS AcqusitionCost
 
			   /*
			    * TransferredOutCost (intermediate — used to compute RemainingCost in Result2 CTE)
			    */
			   ,ISNULL((
			       SELECT SUM(ISNULL(TransferredOutCost, 0))
			       FROM DBO.LotCalculationDetails LCD WITH(NOLOCK)
			       WHERE LCD.LotId = LT.LotId
			         AND UPPER(REPLACE(LCD.[Type], ' ', '')) = UPPER(REPLACE('Trans Out(Lot)', ' ', ''))
			   ), 0) AS _TransferredOutCost
 
			   /*
			    * SoldCost (intermediate — used to compute RemainingCost in Result2 CTE)
			    * Join on SalesOrderPartId (not SalesOrderId) to match USP_Lot_GetLotSummaryByLotId
			    */
			   ,ISNULL((
			       SELECT SUM(ISNULL(SOPC.UnitCost, 0) * ISNULL(LCD.Qty, 0))
			       FROM DBO.LotCalculationDetails LCD WITH(NOLOCK)
			       INNER JOIN DBO.SalesOrder SO WITH(NOLOCK) ON LCD.ReferenceId = SO.SalesOrderId
			       INNER JOIN DBO.SalesOrderPartV1 SOP WITH(NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId AND LCD.ChildId = SOP.SalesOrderPartId
			       INNER JOIN DBO.SalesOrderPartCost SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId AND SOPC.IsDeleted = 0
			       WHERE LCD.LotId = LT.LotId
			         AND UPPER(REPLACE(LCD.[Type], ' ', '')) = UPPER(REPLACE('Trans Out(SO)', ' ', ''))
			   ), 0) AS _SoldCost
 
			   -- Revenue = SUM(ExtSalesUnitPrice) for Trans Out(SO)
			   ,ISNULL((
			       SELECT SUM(ISNULL(LOC.ExtSalesUnitPrice, 0))
			       FROM DBo.LotCalculationDetails LOC WITH(NOLOCK)
			       WHERE LOC.LotId = LT.LotId
			         AND UPPER(REPLACE(LOC.Type, ' ', '')) = UPPER(REPLACE('Trans Out(SO)', ' ', ''))
			   ), 0) AS Revenue
 
			   -- MarginAmount = SUM(MarginAmount) for Trans Out(SO)
			   ,ISNULL((
			       SELECT SUM(ISNULL(LOC.MarginAmount, 0))
			       FROM DBo.LotCalculationDetails LOC WITH(NOLOCK)
			       WHERE LOC.LotId = LT.LotId
			         AND UPPER(REPLACE(LOC.Type, ' ', '')) = UPPER(REPLACE('Trans Out(SO)', ' ', ''))
			   ), 0) AS MarginAmount
 
			FROM [dbo].[Lot] LT WITH(NOLOCK)
			INNER JOIN dbo.LotDetail LD WITH(NOLOCK) on LT.LotId = LD.LotId
			INNER JOIN [dbo].[LotStatus] S WITH(NOLOCK) ON LT.[LotStatusId] = S.[LotStatusId]
			LEFT JOIN [dbo].[LotConsignment] LC WITH (NOLOCK) ON LT.ConsignmentId = LC.ConsignmentId
		 	WHERE ISNULL(LT.IsDeleted,0) = 0
			  AND ISNULL(LT.IsActive,1) = 1
			  AND LT.MasterCompanyId = @MasterCompanyId
			  AND (UPPER(ISNULL(@StatusName, 'Open')) = 'ALL'
			       OR UPPER(S.StatusName) = UPPER(ISNULL(@StatusName, 'Open')))
		)
		/*
		 * Result2: compute RemainingCost from the intermediate columns, then drop them.
		 * RemainingCost = MAX(0, AcqusitionCost - TransferredOutCost - SoldCost)
		 *   matches LotCostRemaining in USP_Lot_GetLotSummaryByLotId
		 */
		,Result2 AS (
		    SELECT
		        LotId, LotNumber, LotName, VendorId, VendorName, ReferenceNumber,
		        OpenDate, OriginalCost, LotStatusId, StatusName, ConsignmentId,
		        ConsignmentNumber, ConsigneeName, EmployeeId, ObtainFromId, ObtainFromTypeId,
		        TraceableToId, TraceableToTypeId, ManagementStructureId, MasterCompanyId,
		        CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
		        AcqusitionCost,
		        -- RemainingCost = LotCostRemaining, floored at 0
		        CASE WHEN AcqusitionCost - _TransferredOutCost - _SoldCost < 0
		             THEN CONVERT(DECIMAL(18,2), 0)
		             ELSE CONVERT(DECIMAL(18,2), AcqusitionCost - _TransferredOutCost - _SoldCost)
		        END AS RemainingCost,
		        Revenue,
		        MarginAmount
		    FROM Result
		)
		SELECT *,
		    CONVERT(DECIMAL(18,2), (CASE WHEN Revenue > 0 THEN ((ISNULL(MarginAmount,0)/ISNULL(Revenue,0))*100) ELSE 0 END)) AS Margin,
		    CONVERT(DECIMAL(18,2), (CASE WHEN ISNULL(AcqusitionCost,0) > 0 THEN ((ISNULL(RemainingCost,0)/ISNULL(AcqusitionCost,0))*100) ELSE 0 END)) AS RemainingPercentage
		INTO #TempTblLot FROM Result2
 
		SELECT * INTO #TempResult FROM #TempTblLot
			WHERE
			 ((@GlobalFilter <>'' AND ((LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(ReferenceNumber LIKE '%' + @GlobalFilter + '%') OR
					(OpenDate LIKE '%' + @GlobalFilter + '%') OR
					(CAST(OriginalCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(ConsignmentNumber LIKE '%' + @GlobalFilter + '%') OR
					(ConsigneeName LIKE '%' + @GlobalFilter + '%') OR
					(VendorName LIKE '%' + @GlobalFilter + '%') OR
					(CAST(AcqusitionCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(RemainingCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(RemainingPercentage AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(Revenue AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(MarginAmount AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(Margin AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CreatedBy like '%' + @GlobalFilter + '%') OR
					(CreatedDate like '%' + @GlobalFilter + '%') OR
					(UpdatedBy like '%' + @GlobalFilter + '%') OR
					(UpdatedDate like '%' + @GlobalFilter + '%')))
					OR
					(@GlobalFilter = '' AND (ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@LotName, '') = '' OR LotName LIKE '%' + @LotName + '%') AND
					(ISNULL(@ReferenceNumber, '') = '' OR ReferenceNumber LIKE '%' + @ReferenceNumber + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND
					(IsNull(@OriginalCost, 0) = 0 OR CAST(OriginalCost as VARCHAR(10)) like @OriginalCost) AND
					(ISNULL(@ConsignmentNumber, '') = '' OR ConsignmentNumber LIKE '%' + @ConsignmentNumber + '%') AND
					(ISNULL(@ConsigneeName, '') = '' OR ConsigneeName LIKE '%' + @ConsigneeName + '%') AND
					(ISNULL(@VendorName, '') = '' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@AcqusitionCost, 0) = 0 OR CAST(AcqusitionCost as VARCHAR(10)) LIKE @AcqusitionCost) AND
					(ISNULL(@RemainingCost, 0) = 0 OR CAST(RemainingCost as VARCHAR(10)) LIKE @RemainingCost) AND
					(ISNULL(@RemainingPercentage, 0) = 0 OR CAST(RemainingPercentage as VARCHAR(10)) = @RemainingPercentage) AND
					(ISNULL(@Revenue, 0) = 0 OR CAST(Revenue as VARCHAR(10)) = @Revenue) AND
					(ISNULL(@MarginAmount, 0) = 0 OR CAST(MarginAmount as VARCHAR(10)) = @MarginAmount) AND
					(ISNULL(@Margin, 0) = 0 OR CAST(Margin as VARCHAR(10)) = @Margin) AND
					(ISNULL(@CreatedBy, '') = '' OR CreatedBy  like '%'+ @CreatedBy + '%') AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date) = CAST(CreatedDate AS date)))
				  )
		SELECT @Count = COUNT(LotId) FROM #TempResult
		SELECT *, @Count AS NumberOfItems FROM #TempResult
		ORDER BY
		CASE WHEN (@SortOrder=1  AND @SortColumn='LotNumber')  THEN LotNumber END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='LotNumber')  THEN LotNumber END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='LotName')  THEN LotName END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='LotName')  THEN LotName END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='ReferenceNumber')  THEN ReferenceNumber END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ReferenceNumber')  THEN ReferenceNumber END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='OriginalCost')  THEN OriginalCost END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='OriginalCost')  THEN OriginalCost END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='ConsignmentNumber')  THEN ConsignmentNumber END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ConsignmentNumber')  THEN ConsignmentNumber END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='ConsigneeName')  THEN ConsigneeName END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='ConsigneeName')  THEN ConsigneeName END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='AcqusitionCost')  THEN AcqusitionCost END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='AcqusitionCost')  THEN AcqusitionCost END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='RemainingCost')  THEN RemainingCost END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='RemainingCost')  THEN RemainingCost END DESC,
		CASE WHEN (@SortOrder=1  AND @SortColumn='RemainingPercentage')  THEN RemainingPercentage END ASC,
		CASE WHEN (@SortOrder=-1 AND @SortColumn='RemainingPercentage')  THEN RemainingPercentage END DESC,
		CASE WHEN (@SortOrder=1 and @SortColumn='Revenue')  THEN Revenue END ASC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='Revenue')  THEN Revenue END DESC,
		CASE WHEN (@SortOrder=1 and @SortColumn='MarginAmount')  THEN MarginAmount END ASC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='MarginAmount')  THEN MarginAmount END DESC,
		CASE WHEN (@SortOrder=1 and @SortColumn='Margin')  THEN Margin END ASC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='Margin')  THEN Margin END DESC,
		CASE WHEN (@SortOrder=1 and @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
		CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC
		OFFSET @RecordFrom ROWS
		FETCH NEXT @PageSize ROWS ONLY
	END
	COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_Lot_GetLotList]',
            @ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END