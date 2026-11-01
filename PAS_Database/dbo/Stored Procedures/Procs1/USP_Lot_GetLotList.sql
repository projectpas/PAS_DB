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
	4    09/July/2026 RAJESH GAMI    [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	5    23/July/2026 RAJESH GAMI    [PN-17350] - Removed leftover IsNonStock=0 exclusion filters.
	6    25/Aug/2026 RAJESH GAMI    [PN-17745] Ported from PAS_DB - TransferredInCost SUM subquery now also recognizes the new 'Turn In' type (in addition to 'Trans In (Lot)') so stocklines created via "Create Stockline from Lot" are still included/calculated correctly.
	7    06/08/2026		 Nakul Chnadigra		Added status Filter [PN-17566]
	8    29-Oct-2026     RAJESH GAMI    [PN-18450] Performance only (output unchanged, was 30+ sec): light columns for all lots, filter + sort + page first, heavy columns (vendor / PO no, acquisition / remaining cost, revenue, margin) calculated set based and only for the page lots unless filtered / sorted on; DISTINCT + LotDetail join replaced by EXISTS; time zone offset read once instead of dbo.ConvertUTCtoLocal per lot.
**************************************************************
**************************************************************/
CREATE PROCEDURE [dbo].[USP_Lot_GetLotList]
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
 
		-- [PN-18450] Performance (was 30+ sec): the heavy columns (vendor / reference no, acquisition / remaining cost, revenue, margin - ~15 correlated subqueries per lot) were
		-- calculated for EVERY open lot, then filtered, sorted and paged. Now: light columns for all lots (#Lots), page selected, and the heavy columns are calculated
		-- only for the lots of the page - unless the filter / sort uses them (@NeedAll = 1, then for all lots, but set based instead of per row).
		DECLARE @NeedAll BIT = CASE WHEN ISNULL(@GlobalFilter, '') <> ''
		                              OR ISNULL(@VendorName, '') <> '' OR ISNULL(@ReferenceNumber, '') <> ''
		                              OR ISNULL(@AcqusitionCost, 0) <> 0 OR ISNULL(@RemainingCost, 0) <> 0 OR ISNULL(@RemainingPercentage, 0) <> 0
		                              OR ISNULL(@Revenue, 0) <> 0 OR ISNULL(@MarginAmount, 0) <> 0 OR ISNULL(@Margin, 0) <> 0
		                              OR @SortColumn IN ('VENDORNAME','REFERENCENUMBER','ACQUSITIONCOST','REMAININGCOST','REMAININGPERCENTAGE','REVENUE','MARGINAMOUNT','MARGIN')
		                            THEN 1 ELSE 0 END

		-- time zone offset read ONCE (dbo.ConvertUTCtoLocal read dbo.TimeZone for every lot)
		DECLARE @BaseUtcOffsetSec INT
		SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc

		IF OBJECT_ID(N'tempdb..#Lots') IS NOT NULL DROP TABLE #Lots
		IF OBJECT_ID(N'tempdb..#Target') IS NOT NULL DROP TABLE #Target
		IF OBJECT_ID(N'tempdb..#Page') IS NOT NULL DROP TABLE #Page

		-- light columns for every lot (the heavy ones are NULL placeholders with the same data types as before)
		SELECT
			LT.[LotId] LotId
		   ,UPPER(LT.LotNumber) LotNumber
		   ,UPPER(LT.LotName) LotName
		   ,CAST(NULL AS BIGINT) AS VendorId
		   ,CAST(NULL AS VARCHAR(100)) AS VendorName
		   ,CAST(NULL AS VARCHAR(50)) AS ReferenceNumber
		   ,case when CAST(LT.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date) then null else (Cast(DATEADD(SECOND, @BaseUtcOffsetSec, CAST(LT.[CreatedDate] AS DATETIME)) as Date)) end OpenDate
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
		   ,CAST(NULL AS DECIMAL(38,6)) AS AcqusitionCost
		   ,CAST(NULL AS DECIMAL(18,2)) AS RemainingCost
		   ,CAST(NULL AS DECIMAL(38,6)) AS Revenue
		   ,CAST(NULL AS DECIMAL(38,6)) AS MarginAmount
		   ,CAST(NULL AS DECIMAL(18,2)) AS Margin
		   ,CAST(NULL AS DECIMAL(18,2)) AS RemainingPercentage
		   ,LT.InitialPOCost AS _InitialPOCost
		INTO #Lots
		FROM [dbo].[Lot] LT WITH(NOLOCK)
		INNER JOIN [dbo].[LotStatus] S WITH(NOLOCK) ON LT.[LotStatusId] = S.[LotStatusId]
		LEFT JOIN [dbo].[LotConsignment] LC WITH (NOLOCK) ON LT.ConsignmentId = LC.ConsignmentId
		WHERE ISNULL(LT.IsDeleted,0) = 0
		  AND ISNULL(LT.IsActive,1) = 1
		  AND LT.MasterCompanyId = @MasterCompanyId
		  AND (UPPER(ISNULL(@StatusName, 'Open')) = 'ALL'
		       OR UPPER(S.StatusName) = UPPER(ISNULL(@StatusName, 'Open')))
		  -- was INNER JOIN dbo.LotDetail + SELECT DISTINCT (one row per lot)
		  AND EXISTS (SELECT 1 FROM dbo.LotDetail LD WITH(NOLOCK) WHERE LD.LotId = LT.LotId)
		CREATE UNIQUE CLUSTERED INDEX IX_Lots ON #Lots (LotId)

		CREATE TABLE #Target (LotId BIGINT NOT NULL PRIMARY KEY)
		CREATE TABLE #Page (Seq INT IDENTITY(1,1) NOT NULL PRIMARY KEY, LotId BIGINT NOT NULL, TotalCnt INT NOT NULL)

		-- the heavy step and the page step run in a different order depending on @NeedAll (so the filter / ORDER BY below exist only once)
		DECLARE @Step INT = 1
		WHILE @Step <= 2
		BEGIN
			IF (@NeedAll = 1 AND @Step = 1) OR (@NeedAll = 0 AND @Step = 2)
			BEGIN
				-- HEAVY columns: all lots (@NeedAll = 1) or only the lots of the page
				TRUNCATE TABLE #Target
				IF @NeedAll = 1
					INSERT INTO #Target (LotId) SELECT LotId FROM #Lots
				ELSE
					INSERT INTO #Target (LotId) SELECT LotId FROM #Page

				UPDATE L
				SET L.VendorId = ISNULL(PV.VendorId, 0),
				    L.VendorName = VN.VendorName,
				    L.ReferenceNumber = ISNULL(PV.PurchaseOrderNumber, ''),
				    L.AcqusitionCost = D.AcqusitionCost,
				    L.RemainingCost = R.RemainingCost,
				    L.Revenue = D.Revenue,
				    L.MarginAmount = D.MarginAmount,
				    L.Margin = CONVERT(DECIMAL(18,2), (CASE WHEN D.Revenue > 0 THEN ((ISNULL(D.MarginAmount,0)/ISNULL(D.Revenue,0))*100) ELSE 0 END)),
				    L.RemainingPercentage = CONVERT(DECIMAL(18,2), (CASE WHEN ISNULL(D.AcqusitionCost,0) > 0 THEN ((ISNULL(R.RemainingCost,0)/ISNULL(D.AcqusitionCost,0))*100) ELSE 0 END))
				FROM #Lots L
				INNER JOIN #Target T ON T.LotId = L.LotId
				-- first (non deleted) Purchase Order of the lot: vendor id + number
				LEFT JOIN (
					SELECT x.LotId, x.VendorId, x.PurchaseOrderNumber
					FROM (SELECT po.LotId, po.VendorId, po.PurchaseOrderNumber,
					             ROW_NUMBER() OVER (PARTITION BY po.LotId ORDER BY po.PurchaseOrderId) AS rn
					      FROM dbo.PurchaseOrder po WITH(NOLOCK)
					      INNER JOIN #Target t ON t.LotId = po.LotId
					      WHERE ISNULL(po.IsDeleted,0) = 0) x
					WHERE x.rn = 1
				) PV ON PV.LotId = L.LotId
				-- vendor name of the first (non deleted) Purchase Order that has a vendor
				LEFT JOIN (
					SELECT x.LotId, x.VendorName
					FROM (SELECT po.LotId, ISNULL(ven.VendorName,'') AS VendorName,
					             ROW_NUMBER() OVER (PARTITION BY po.LotId ORDER BY po.PurchaseOrderId) AS rn
					      FROM dbo.PurchaseOrder po WITH(NOLOCK)
					      INNER JOIN #Target t ON t.LotId = po.LotId
					      INNER JOIN dbo.Vendor ven WITH(NOLOCK) ON po.VendorId = ven.VendorId
					      WHERE ISNULL(po.IsDeleted,0) = 0) x
					WHERE x.rn = 1
				) VN ON VN.LotId = L.LotId
				-- Lot Calculation Details: repair / trans in / trans out / revenue / margin in ONE pass
				LEFT JOIN (
					SELECT X.LotId,
					       SUM(ISNULL(X.RepairCost, 0)) AS RepairCost,
					       SUM(CASE WHEN ISNULL(X.IsFromPreCostStk, 0) = 0
					                 AND (X.TN = UPPER(REPLACE('Trans In (Lot)', ' ', '')) OR X.TN = UPPER(REPLACE('Turn In', ' ', '')))
					                THEN ISNULL(X.TransferredInCost, 0) END) AS TransIn,
					       SUM(CASE WHEN X.TN = UPPER(REPLACE('Trans Out(Lot)', ' ', '')) THEN ISNULL(X.TransferredOutCost, 0) END) AS TransOut,
					       SUM(CASE WHEN X.TN = UPPER(REPLACE('Trans Out(SO)', ' ', '')) THEN ISNULL(X.ExtSalesUnitPrice, 0) END) AS Revenue,
					       SUM(CASE WHEN X.TN = UPPER(REPLACE('Trans Out(SO)', ' ', '')) THEN ISNULL(X.MarginAmount, 0) END) AS MarginAmt
					FROM (SELECT LCD.LotId, LCD.RepairCost, LCD.IsFromPreCostStk, LCD.TransferredInCost, LCD.TransferredOutCost, LCD.ExtSalesUnitPrice, LCD.MarginAmount,
					             UPPER(REPLACE(LCD.[Type], ' ', '')) AS TN
					      FROM dbo.LotCalculationDetails LCD WITH(NOLOCK)
					      INNER JOIN #Target t ON t.LotId = LCD.LotId) X
					GROUP BY X.LotId
				) AG ON AG.LotId = L.LotId
				-- SoldCost: join on SalesOrderPartId (as before)
				LEFT JOIN (
					SELECT LCD.LotId, SUM(ISNULL(SOPC.UnitCost, 0) * ISNULL(LCD.Qty, 0)) AS Sold
					FROM DBO.LotCalculationDetails LCD WITH(NOLOCK)
					INNER JOIN #Target t ON t.LotId = LCD.LotId
					INNER JOIN DBO.SalesOrder SO WITH(NOLOCK) ON LCD.ReferenceId = SO.SalesOrderId
					INNER JOIN DBO.SalesOrderPartV1 SOP WITH(NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId AND LCD.ChildId = SOP.SalesOrderPartId
					INNER JOIN DBO.SalesOrderPartCost SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId AND SOPC.IsDeleted = 0
					WHERE UPPER(REPLACE(LCD.[Type], ' ', '')) = UPPER(REPLACE('Trans Out(SO)', ' ', ''))
					GROUP BY LCD.LotId
				) SC ON SC.LotId = L.LotId
				-- OtherCost (PO): Freight / Charges at part-record level
				LEFT JOIN (
					SELECT PO.LotId, SUM(ISNULL(PF.Amount, 0)) AS Amt
					FROM dbo.PurchaseOrder PO WITH(NOLOCK)
					INNER JOIN #Target t ON t.LotId = PO.LotId
					INNER JOIN dbo.PurchaseOrderPart PP WITH(NOLOCK) ON PP.PurchaseOrderId = PO.PurchaseOrderId
					INNER JOIN dbo.PurchaseOrderFreight PF WITH(NOLOCK) ON PF.PurchaseOrderPartRecordId = PP.PurchaseOrderPartRecordId
					WHERE ISNULL(PF.IsDeleted, 0) = 0
					GROUP BY PO.LotId
				) POF ON POF.LotId = L.LotId
				LEFT JOIN (
					SELECT PO.LotId, SUM(ISNULL(PC.ExtendedCost, 0)) AS Amt
					FROM dbo.PurchaseOrder PO WITH(NOLOCK)
					INNER JOIN #Target t ON t.LotId = PO.LotId
					INNER JOIN dbo.PurchaseOrderPart PP WITH(NOLOCK) ON PP.PurchaseOrderId = PO.PurchaseOrderId
					INNER JOIN dbo.PurchaseOrderCharges PC WITH(NOLOCK) ON PC.PurchaseOrderPartRecordId = PP.PurchaseOrderPartRecordId
					WHERE ISNULL(PC.IsDeleted, 0) = 0
					GROUP BY PO.LotId
				) POC ON POC.LotId = L.LotId
				-- OtherCost (RO): Freight / Charges at part-record level
				LEFT JOIN (
					SELECT RP.LotId, SUM(ISNULL(RF.Amount, 0)) AS Amt
					FROM dbo.RepairOrderPart RP WITH(NOLOCK)
					INNER JOIN #Target t ON t.LotId = RP.LotId
					INNER JOIN dbo.RepairOrderFreight RF WITH(NOLOCK) ON RF.RepairOrderPartRecordId = RP.RepairOrderPartRecordId
					WHERE ISNULL(RF.IsDeleted, 0) = 0
					GROUP BY RP.LotId
				) ROF ON ROF.LotId = L.LotId
				LEFT JOIN (
					SELECT RP.LotId, SUM(ISNULL(RC.ExtendedCost, 0)) AS Amt
					FROM dbo.RepairOrderPart RP WITH(NOLOCK)
					INNER JOIN #Target t ON t.LotId = RP.LotId
					INNER JOIN dbo.RepairOrderCharges RC WITH(NOLOCK) ON RC.RepairOrderPartRecordId = RP.RepairOrderPartRecordId
					WHERE ISNULL(RC.IsDeleted, 0) = 0
					GROUP BY RP.LotId
				) ROC ON ROC.LotId = L.LotId
				-- AdjustmentAmount: Adjustment * QuantityOnHand per Stockline
				LEFT JOIN (
					SELECT ltin.LotId, SUM(ISNULL(sl.Adjustment, 0) * ISNULL(sl.QuantityOnHand, 0)) AS Amt
					FROM DBO.LotTransInOutDetails ltin WITH(NOLOCK)
					INNER JOIN #Target t ON t.LotId = ltin.LotId
					INNER JOIN DBO.Stockline sl WITH(NOLOCK) ON ltin.StockLineId = sl.StockLineId
					GROUP BY ltin.LotId
				) ADJ ON ADJ.LotId = L.LotId
				CROSS APPLY (
					SELECT
						(
						   ISNULL(L._InitialPOCost, 0)
						   + ISNULL(AG.RepairCost, 0)
						   + ISNULL(AG.TransIn, 0)
						   + ISNULL(POF.Amt, 0)
						   + ISNULL(POC.Amt, 0)
						   + ISNULL(ROF.Amt, 0)
						   + ISNULL(ROC.Amt, 0)
						   + ISNULL(ADJ.Amt, 0)
						) AS AcqusitionCost,
						ISNULL(AG.TransOut, 0) AS TransOut,
						ISNULL(SC.Sold, 0) AS Sold,
						ISNULL(AG.Revenue, 0) AS Revenue,
						ISNULL(AG.MarginAmt, 0) AS MarginAmount
				) D
				CROSS APPLY (
					-- RemainingCost = LotCostRemaining, floored at 0 (same as USP_Lot_GetLotSummaryByLotId)
					SELECT CASE WHEN D.AcqusitionCost - D.TransOut - D.Sold < 0
					            THEN CONVERT(DECIMAL(18,2), 0)
					            ELSE CONVERT(DECIMAL(18,2), D.AcqusitionCost - D.TransOut - D.Sold)
					       END AS RemainingCost
				) R
			END

			IF (@NeedAll = 1 AND @Step = 2) OR (@NeedAll = 0 AND @Step = 1)
			BEGIN
				-- PAGE step: filter + sort + page (the filter and ORDER BY are the original ones)
				INSERT INTO #Page (LotId, TotalCnt)
				SELECT LotId, COUNT(*) OVER()
				FROM #Lots
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

			SET @Step = @Step + 1
		END

		SELECT L.LotId, L.LotNumber, L.LotName, L.VendorId, L.VendorName, L.ReferenceNumber,
		       L.OpenDate, L.OriginalCost, L.LotStatusId, L.StatusName, L.ConsignmentId,
		       L.ConsignmentNumber, L.ConsigneeName, L.EmployeeId, L.ObtainFromId, L.ObtainFromTypeId,
		       L.TraceableToId, L.TraceableToTypeId, L.ManagementStructureId, L.MasterCompanyId,
		       L.CreatedBy, L.UpdatedBy, L.CreatedDate, L.UpdatedDate,
		       L.AcqusitionCost, L.RemainingCost, L.Revenue, L.MarginAmount, L.Margin, L.RemainingPercentage,
		       P.TotalCnt AS NumberOfItems
		FROM #Page P
		INNER JOIN #Lots L ON L.LotId = P.LotId
		ORDER BY P.Seq
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