/*************************************************************
 ** File:   [USP_GetLeasePostedInvoiceListByLeaseHeaderId]
 ** Description: [PN-18601] Billing/Invoicing > Invoiced tab (posted invoices). Paged list like the other list pages
 **              (ProcItemMasterStockList / SearchSOViewData): page, column filters, global filter, sort, total record count.
 **              Returns ONE row per POSTED invoice of the lease (BillingInvoicing.IsInvoicePosted = 1): the parts of the invoice are listed
 **              together in PartNumber / EngineType / PartDescription / SerialNumber: the value itself when the invoice has one distinct value,
 **              otherwise the word 'Multiple' (like the Work Order list; the column filters still search all the values of the invoice),
 **              Qty is the sum of the quantities of the invoiced lease items and TotalBillingAmount the sum of all its invoice lines
 **              (LeaseBillingInvoicingItemDetails.LineAmount, current version only; same lines as USP_GetLeaseBillingListByLeaseHeaderId).
 **              TotalBillingSum = sum of TotalBillingAmount of ALL filtered rows (grid footer total, not only the page).
 **              Default order : latest invoice first.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    19/11/2026     Kishor Makwana          [PN-18601] Created

 exec USP_GetLeasePostedInvoiceListByLeaseHeaderId @LeaseHeaderId=1, @PageNumber=1, @PageSize=20, @SortColumn=NULL, @SortOrder=-1, @GlobalFilter=N'', @EmployeeId=226
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeasePostedInvoiceListByLeaseHeaderId]
	@LeaseHeaderId BIGINT,
	@PageNumber INT = 1,
	@PageSize INT = 20,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT = NULL,
	@GlobalFilter VARCHAR(50) = NULL,
	@PartNumber VARCHAR(200) = NULL,
	@EngineType VARCHAR(200) = NULL,
	@PartDescription VARCHAR(500) = NULL,
	@SerialNumber VARCHAR(200) = NULL,
	@Qty VARCHAR(50) = NULL,
	@TotalBillingAmount VARCHAR(50) = NULL,
	@BillingStatus VARCHAR(50) = NULL,
	@InvoiceNumber VARCHAR(50) = NULL,
	@InvoiceDate DATETIME = NULL,
	@EmployeeId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		---------------------------------------------------------------------------
		-- 1. Employee time zone (the grid shows the invoice date in the user's time zone)
		---------------------------------------------------------------------------
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description], '')
		FROM dbo.Employee E WITH (NOLOCK)
		LEFT JOIN dbo.[TimeZone] ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.[TimeZone] LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

		---------------------------------------------------------------------------
		-- 2. Parameter normalisation
		---------------------------------------------------------------------------
		DECLARE @RecordFrom INT;

		SET @PageSize = ISNULL(NULLIF(@PageSize, 0), 20);
		SET @PageNumber = CASE WHEN ISNULL(@PageNumber, 1) < 1 THEN 1 ELSE @PageNumber END;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		IF ISNULL(@SortColumn, '') = ''
		BEGIN
			SET @SortColumn = 'INVOICEDATE';
			SET @SortOrder = -1;
		END
		ELSE
		BEGIN
			SET @SortColumn = UPPER(@SortColumn);
			SET @SortOrder = ISNULL(@SortOrder, 1);
		END

		SET @GlobalFilter = NULLIF(LTRIM(RTRIM(@GlobalFilter)), '');
		SET @PartNumber = NULLIF(LTRIM(RTRIM(@PartNumber)), '');
		SET @EngineType = NULLIF(LTRIM(RTRIM(@EngineType)), '');
		SET @PartDescription = NULLIF(LTRIM(RTRIM(@PartDescription)), '');
		SET @SerialNumber = NULLIF(LTRIM(RTRIM(@SerialNumber)), '');
		SET @Qty = NULLIF(LTRIM(RTRIM(@Qty)), '');
		SET @TotalBillingAmount = NULLIF(REPLACE(LTRIM(RTRIM(@TotalBillingAmount)), ',', ''), '');
		SET @BillingStatus = NULLIF(LTRIM(RTRIM(@BillingStatus)), '');
		SET @InvoiceNumber = NULLIF(LTRIM(RTRIM(@InvoiceNumber)), '');

		-- normalised part number text, evaluated once instead of once per row
		DECLARE @GFNorm VARCHAR(500) = dbo.fn_NormalizePartNumber(@GlobalFilter);
		DECLARE @PNNorm VARCHAR(500) = dbo.fn_NormalizePartNumber(@PartNumber);

		---------------------------------------------------------------------------
		-- 3. Invoice date filter : the picked day (user's time zone) as a UTC window on the stored UTC date
		---------------------------------------------------------------------------
		DECLARE @UtcRef DATETIME = GETUTCDATE();
		DECLARE @TzOffsetMin INT = 0;
		DECLARE @InvFromUtc DATETIME2(3), @InvToUtc DATETIME2(3);

		IF @CurrntEmpTimeZoneDesc <> ''
			SET @TzOffsetMin = DATEDIFF(MINUTE, @UtcRef, dbo.ConvertUTCtoLocal(@UtcRef, @CurrntEmpTimeZoneDesc));

		IF ISNULL(@InvoiceDate, '') <> ''
		BEGIN
			SET @InvFromUtc = DATEADD(MINUTE, -@TzOffsetMin, CAST(CAST(@InvoiceDate AS DATE) AS DATETIME2(3)));
			SET @InvToUtc = DATEADD(MINUTE, -@TzOffsetMin, DATEADD(DAY, 1, CAST(CAST(@InvoiceDate AS DATE) AS DATETIME2(3))));
		END

		---------------------------------------------------------------------------
		-- 4. One row per posted invoice and lease item
		---------------------------------------------------------------------------
		IF OBJECT_ID(N'tempdb..#InvoiceItems') IS NOT NULL DROP TABLE #InvoiceItems;
		IF OBJECT_ID(N'tempdb..#Posted') IS NOT NULL DROP TABLE #Posted;

		SELECT
			BI.BillingInvoicingId,
			BI.InvoiceNo,
			BI.InvoiceDate,
			LBID.LeaseStocklineId,
			LSL.PN AS PartNumber,
			LSL.PNDescription AS PartDescription,
			SLIVE.SerialNumber,
			SLIVE.EngineType,
			ISNULL(LSL.QtyReserved, 0) AS Qty,
			SUM(ISNULL(LBID.LineAmount, 0)) AS TotalBillingAmount
		INTO #InvoiceItems
		FROM [dbo].[LeaseBillingInvoicingItemDetails] LBID WITH (NOLOCK)
		INNER JOIN [dbo].[LeaseStockline] LSL WITH (NOLOCK) ON LSL.LeaseStocklineId = LBID.LeaseStocklineId
		LEFT JOIN [dbo].[Stockline] SLIVE WITH (NOLOCK) ON SLIVE.StockLineId = LSL.StockLineId
		INNER JOIN [dbo].[BillingInvoicingItems] BII WITH (NOLOCK) ON BII.BillingInvoicingItemId = LBID.BillingInvoicingItemId AND BII.IsDeleted = 0 AND ISNULL(BII.IsVersionIncrease, 0) = 0
		INNER JOIN [dbo].[BillingInvoicing] BI WITH (NOLOCK) ON BI.BillingInvoicingId = BII.BillingInvoicingId AND ISNULL(BI.IsInvoicePosted, 0) = 1
		WHERE LSL.LeaseHeaderId = @LeaseHeaderId AND LSL.IsDeleted = 0 AND ISNULL(LBID.IsDeleted, 0) = 0 AND ISNULL(LBID.IsVersionIncrease, 0) = 0
		  AND NOT (LBID.LineType = 'Overrun' AND ISNULL(LBID.LineAmount, 0) = 0)
		GROUP BY BI.BillingInvoicingId, BI.InvoiceNo, BI.InvoiceDate, LBID.LeaseStocklineId, LSL.PN, LSL.PNDescription, SLIVE.SerialNumber, SLIVE.EngineType, LSL.QtyReserved;

		-- one row per posted invoice (parts of the invoice listed together)
		SELECT
			H.BillingInvoicingId,
			H.FirstLeaseStocklineId AS LeaseStocklineId,
			H.InvoiceNo AS InvoiceNumber,
			H.InvoiceDate,
			CAST('Y' AS VARCHAR(10)) AS BillingStatus,
			PN.Val AS PartNumber,
			EN.Val AS EngineType,
			PD.Val AS PartDescription,
			SN.Val AS SerialNumber,
			-- grid display values: the value itself when the invoice has one distinct value, otherwise the word 'Multiple' (same as the Work Order list)
			CASE WHEN PN.Cnt > 1 THEN 'Multiple' ELSE PN.Val END AS PartNumberDisp,
			CASE WHEN EN.Cnt > 1 THEN 'Multiple' ELSE EN.Val END AS EngineTypeDisp,
			CASE WHEN PD.Cnt > 1 THEN 'Multiple' ELSE PD.Val END AS PartDescriptionDisp,
			CASE WHEN SN.Cnt > 1 THEN 'Multiple' ELSE SN.Val END AS SerialNumberDisp,
			H.Qty,
			H.TotalBillingAmount
		INTO #Posted
		FROM (
			SELECT BillingInvoicingId, InvoiceNo, InvoiceDate,
				SUM(Qty) AS Qty,
				SUM(TotalBillingAmount) AS TotalBillingAmount,
				MIN(LeaseStocklineId) AS FirstLeaseStocklineId
			FROM #InvoiceItems
			GROUP BY BillingInvoicingId, InvoiceNo, InvoiceDate
		) H
		OUTER APPLY (
			SELECT STRING_AGG(X.Val, ', ') WITHIN GROUP (ORDER BY X.FirstLine) AS Val, COUNT(*) AS Cnt
			FROM (SELECT II.PartNumber AS Val, MIN(II.LeaseStocklineId) AS FirstLine FROM #InvoiceItems II
				  WHERE II.BillingInvoicingId = H.BillingInvoicingId AND ISNULL(II.PartNumber, '') <> '' GROUP BY II.PartNumber) X
		) PN
		OUTER APPLY (
			SELECT STRING_AGG(X.Val, ', ') WITHIN GROUP (ORDER BY X.FirstLine) AS Val, COUNT(*) AS Cnt
			FROM (SELECT II.EngineType AS Val, MIN(II.LeaseStocklineId) AS FirstLine FROM #InvoiceItems II
				  WHERE II.BillingInvoicingId = H.BillingInvoicingId AND ISNULL(II.EngineType, '') <> '' GROUP BY II.EngineType) X
		) EN
		OUTER APPLY (
			SELECT STRING_AGG(X.Val, ', ') WITHIN GROUP (ORDER BY X.FirstLine) AS Val, COUNT(*) AS Cnt
			FROM (SELECT II.PartDescription AS Val, MIN(II.LeaseStocklineId) AS FirstLine FROM #InvoiceItems II
				  WHERE II.BillingInvoicingId = H.BillingInvoicingId AND ISNULL(II.PartDescription, '') <> '' GROUP BY II.PartDescription) X
		) PD
		OUTER APPLY (
			SELECT STRING_AGG(X.Val, ', ') WITHIN GROUP (ORDER BY X.FirstLine) AS Val, COUNT(*) AS Cnt
			FROM (SELECT II.SerialNumber AS Val, MIN(II.LeaseStocklineId) AS FirstLine FROM #InvoiceItems II
				  WHERE II.BillingInvoicingId = H.BillingInvoicingId AND ISNULL(II.SerialNumber, '') <> '' GROUP BY II.SerialNumber) X
		) SN;

		---------------------------------------------------------------------------
		-- 5. Filter + sort + page
		---------------------------------------------------------------------------
		;WITH Filtered AS (
			SELECT P.*
			FROM #Posted P
			WHERE (
				@GlobalFilter IS NOT NULL AND (
					P.PartNumber LIKE '%' + @GlobalFilter + '%' OR dbo.fn_NormalizePartNumber(P.PartNumber) LIKE '%' + @GFNorm + '%'
					OR P.EngineType LIKE '%' + @GlobalFilter + '%'
					OR P.PartDescription LIKE '%' + @GlobalFilter + '%'
					OR P.SerialNumber LIKE '%' + @GlobalFilter + '%'
					OR CAST(P.Qty AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%'
					OR CAST(CAST(P.TotalBillingAmount AS DECIMAL(18,2)) AS VARCHAR(50)) LIKE '%' + REPLACE(@GlobalFilter, ',', '') + '%'
					OR P.BillingStatus LIKE '%' + @GlobalFilter + '%'
					OR P.InvoiceNumber LIKE '%' + @GlobalFilter + '%')
			)
			OR (
				@GlobalFilter IS NULL
				AND (@PartNumber IS NULL OR P.PartNumber LIKE '%' + @PartNumber + '%' OR dbo.fn_NormalizePartNumber(P.PartNumber) LIKE '%' + @PNNorm + '%')
				AND (@EngineType IS NULL OR P.EngineType LIKE '%' + @EngineType + '%')
				AND (@PartDescription IS NULL OR P.PartDescription LIKE '%' + @PartDescription + '%')
				AND (@SerialNumber IS NULL OR P.SerialNumber LIKE '%' + @SerialNumber + '%')
				AND (@Qty IS NULL OR CAST(P.Qty AS VARCHAR(50)) LIKE '%' + @Qty + '%')
				AND (@TotalBillingAmount IS NULL OR CAST(CAST(P.TotalBillingAmount AS DECIMAL(18,2)) AS VARCHAR(50)) LIKE '%' + @TotalBillingAmount + '%')
				AND (@BillingStatus IS NULL OR P.BillingStatus LIKE '%' + @BillingStatus + '%')
				AND (@InvoiceNumber IS NULL OR P.InvoiceNumber LIKE '%' + @InvoiceNumber + '%')
				AND (@InvFromUtc IS NULL OR (P.InvoiceDate >= @InvFromUtc AND P.InvoiceDate < @InvToUtc))
			)
		)
		SELECT
			F.BillingInvoicingId,
			F.LeaseStocklineId,
			F.InvoiceNumber,
			F.InvoiceDate,
			F.BillingStatus,
			F.PartNumberDisp AS PartNumber,
			F.EngineTypeDisp AS EngineType,
			F.PartDescriptionDisp AS PartDescription,
			F.SerialNumberDisp AS SerialNumber,
			F.Qty,
			F.TotalBillingAmount,
			SUM(F.TotalBillingAmount) OVER () AS TotalBillingSum,
			COUNT(*) OVER () AS NumberOfItems
		FROM Filtered F
		ORDER BY
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTNUMBER') THEN F.PartNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTNUMBER') THEN F.PartNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ENGINETYPE') THEN F.EngineType END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ENGINETYPE') THEN F.EngineType END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTDESCRIPTION') THEN F.PartDescription END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTION') THEN F.PartDescription END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'SERIALNUMBER') THEN F.SerialNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SERIALNUMBER') THEN F.SerialNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QTY') THEN F.Qty END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QTY') THEN F.Qty END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'TOTALBILLINGAMOUNT') THEN F.TotalBillingAmount END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'TOTALBILLINGAMOUNT') THEN F.TotalBillingAmount END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'BILLINGSTATUS') THEN F.BillingStatus END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'BILLINGSTATUS') THEN F.BillingStatus END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'INVOICENUMBER') THEN F.InvoiceNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'INVOICENUMBER') THEN F.InvoiceNumber END DESC,
			CASE WHEN (@SortOrder = 1 AND @SortColumn = 'INVOICEDATE') THEN F.InvoiceDate END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'INVOICEDATE') THEN F.InvoiceDate END DESC,
			-- deterministic tie-breaker: stable paging, latest invoice first
			F.BillingInvoicingId DESC
		OFFSET @RecordFrom ROWS
		FETCH NEXT @PageSize ROWS ONLY
		OPTION (RECOMPILE);

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeasePostedInvoiceListByLeaseHeaderId]',
            @ProcedureParameters varchar(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS varchar(100))
				+ ' @PageNumber = ''' + CAST(ISNULL(@PageNumber, 0) AS varchar(100))
				+ ' @PageSize = ''' + CAST(ISNULL(@PageSize, 0) AS varchar(100))
				+ ' @SortColumn = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
				+ ' @SortOrder = ''' + CAST(ISNULL(@SortOrder, 0) AS varchar(100))
				+ ' @GlobalFilter = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100)),
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
