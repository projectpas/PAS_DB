/**********************************************************************************
** File:        [SearchSOViewData]
** Description: Sales Order List - SO View grid data (paged / filtered / sorted)
***********************************************************************************
** Change History
***********************************************************************************
** PR   Date            Author              Change Description
** --   --------        -------             ----------------------------------------
**  1   04/08/2023      Ekta Chandegara     Convert text into uppercase
**  2   06/26/2024      Amit Ghediya        Added orderby for RequestedDate, EstimatedShipDate
**  3   20-09-2024      Shrey Chandegara    ADD New Column in list (@ContractReference)
**  4   22-01-2025      Ayushi Patel        Converted the date into UTC (created, updated)
**  5   10-04-2025      Vishal Suthar       Applied Optimization, Standard Formatting and Cleanup
**  6   25-04-2025      Bhargav Saliya      Customer Name from SO table instead of Customer table
**  7   27-06-2025      Bhargav Saliya      Add New Fields @NumberOfItemCount
**  8   03-09-2025      Amit Ghediya        Updated for filter issue (SalesQuoteNumber)
**  9   19-11-2025      Rajesh Gami         Return SO Amount
** 10   20-11-2025      Rajesh Gami         Correct the SOAmount
** 11   19/JUN/2026     Amit Ghediya        Get [MarketplaceRef] data [PN-16922]
** 12   01/JUL/2026     Rajesh Gami         [PN-17008] Merge Non Stock Inventory to ItemMaster
** 13   23/JUL/2026     Rajesh Gami         [PN-17350] Removed leftover IsNonStock=0 filters
** 14   29/JUL/2026     Kishor Makwana      [PN-17466] PERFORMANCE REWRITE - Sales Order List filter slowness
**
**  DEPENDENCY: deploy dbo.fnGetSalesOrderSoAmount (fnGetSalesOrderSoAmount.sql) 
**  BEFORE this procedure.
***********************************************************************************/
CREATE   PROCEDURE [dbo].[SearchSOViewData]
	@PageNumber              INT,
	@PageSize                INT,
	@SortColumn              VARCHAR(50)   = NULL,
	@SortOrder               INT,
	@StatusID                INT,
	@GlobalFilter            VARCHAR(50)   = NULL,
	@SOQNumber               VARCHAR(50)   = NULL,
	@SalesOrderNumber        VARCHAR(50)   = NULL,
	@CustomerName            VARCHAR(50)   = NULL,
	@Status                  VARCHAR(50)   = NULL,
	@QuoteAmount             NUMERIC(18,4) = NULL,
	@SoAmount                NUMERIC(18,4) = NULL,
	@QuoteDate               DATETIME      = NULL,
	@SalesPerson             VARCHAR(50)   = NULL,
	@PriorityType            VARCHAR(50)   = NULL,
	@PartNumberType          VARCHAR(50)   = NULL,
	@PartDescriptionType     VARCHAR(50)   = NULL,
	@CustomerReference       VARCHAR(50)   = NULL,
	@CustomerType            VARCHAR(50)   = NULL,
	@VersionNumber           VARCHAR(50)   = NULL,
	@CreatedDate             DATETIME      = NULL,
	@UpdatedDate             DATETIME      = NULL,
	@CreatedBy               VARCHAR(50)   = NULL,
	@UpdatedBy               VARCHAR(50)   = NULL,
	@IsDeleted               BIT           = NULL,
	@MasterCompanyId         INT           = NULL,
	@OpenDate                DATETIME      = NULL,
	@ShippedDate             VARCHAR(50)   = NULL,
	@RequestedDateType       VARCHAR(50)   = NULL,
	@EstimatedShipDateType   VARCHAR(50)   = NULL,
	@EmployeeId              BIGINT,
	@ManufacturerType        VARCHAR(50)   = NULL,
	@ContractReference       VARCHAR(50)   = NULL,
	@NumberOfItemCount       VARCHAR(50)   = NULL,
	@MarketplaceRef          VARCHAR(100)  = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   -- read-only screen query

	BEGIN TRY

		---------------------------------------------------------------------------
		-- 1. Context / employee timezone   (2 round trips collapsed into 1)
		---------------------------------------------------------------------------
		DECLARE @MSModuleID            INT          = 17;   -- Sales Order Management Structure Module ID
		DECLARE @EmpLegalEntiyId       BIGINT       = 0;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		DECLARE @DateStyle             INT          = 101;  -- mm/dd/yyyy - the format this grid displays

		SELECT
			@EmpLegalEntiyId       = E.LegalEntityId,
			@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description], '')
		FROM dbo.Employee E WITH (NOLOCK)
		LEFT JOIN dbo.[TimeZone]  ETZ WITH (NOLOCK) ON E.TimeZoneId    = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE  WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.[TimeZone]  LTZ WITH (NOLOCK) ON LE.TimeZoneId   = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

		---------------------------------------------------------------------------
		-- 2. Parameter normalisation
		--    Optional strings become NULL when blank so the (@p IS NULL OR ...)
		--    predicates can be constant-folded away by OPTION (RECOMPILE).
		---------------------------------------------------------------------------
		DECLARE @RecordFrom INT;

		SET @PageSize   = ISNULL(NULLIF(@PageSize, 0), 20);
		SET @PageNumber = CASE WHEN ISNULL(@PageNumber, 1) < 1 THEN 1 ELSE @PageNumber END;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		SET @IsDeleted  = ISNULL(@IsDeleted, 0);
		SET @SortColumn = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@SortColumn)), ''), 'SalesOrderId'));
		SET @SortOrder  = ISNULL(@SortOrder, 1);

		IF @QuoteAmount = 0 SET @QuoteAmount = NULL;
		IF @SoAmount    = 0 SET @SoAmount    = NULL;
		IF @StatusID    = 0 SET @StatusID    = NULL;
		IF @Status   = '0'  SET @Status      = NULL;

		SET @GlobalFilter          = ISNULL(LTRIM(RTRIM(@GlobalFilter)), '');   -- BUG 3
		SET @SOQNumber             = NULLIF(LTRIM(RTRIM(@SOQNumber)),             '');
		SET @SalesOrderNumber      = NULLIF(LTRIM(RTRIM(@SalesOrderNumber)),      '');
		SET @CustomerName          = NULLIF(LTRIM(RTRIM(@CustomerName)),          '');
		SET @Status                = NULLIF(LTRIM(RTRIM(@Status)),                '');
		SET @SalesPerson           = NULLIF(LTRIM(RTRIM(@SalesPerson)),           '');
		SET @PriorityType          = NULLIF(LTRIM(RTRIM(@PriorityType)),          '');
		SET @PartNumberType        = NULLIF(LTRIM(RTRIM(@PartNumberType)),        '');
		SET @PartDescriptionType   = NULLIF(LTRIM(RTRIM(@PartDescriptionType)),   '');
		SET @CustomerReference     = NULLIF(LTRIM(RTRIM(@CustomerReference)),     '');
		SET @CustomerType          = NULLIF(LTRIM(RTRIM(@CustomerType)),          '');
		SET @VersionNumber         = NULLIF(LTRIM(RTRIM(@VersionNumber)),         '');
		SET @CreatedBy             = NULLIF(LTRIM(RTRIM(@CreatedBy)),             '');
		SET @UpdatedBy             = NULLIF(LTRIM(RTRIM(@UpdatedBy)),             '');
		SET @RequestedDateType     = NULLIF(LTRIM(RTRIM(@RequestedDateType)),     '');
		SET @EstimatedShipDateType = NULLIF(LTRIM(RTRIM(@EstimatedShipDateType)), '');
		SET @ManufacturerType      = NULLIF(LTRIM(RTRIM(@ManufacturerType)),      '');
		SET @ContractReference     = NULLIF(LTRIM(RTRIM(@ContractReference)),     '');
		SET @NumberOfItemCount     = NULLIF(LTRIM(RTRIM(@NumberOfItemCount)),     '');
		SET @MarketplaceRef        = NULLIF(LTRIM(RTRIM(@MarketplaceRef)),        '');
		SET @ShippedDate           = NULLIF(LTRIM(RTRIM(@ShippedDate)),           '');

		DECLARE @HasGlobalFilter BIT          = CASE WHEN @GlobalFilter <> '' THEN 1 ELSE 0 END;
		DECLARE @GF              VARCHAR(102) = '%' + @GlobalFilter + '%';

		---------------------------------------------------------------------------
		-- 2b. Cost gates.
		--     These two flags decide whether the expensive per-Sales-Order
		--     sub-plans have to run over the whole candidate set, or whether they
		--     can be deferred to the returned page. OPTION (RECOMPILE) turns them
		--     into literals, so a gated sub-plan is removed from the plan entirely.
		---------------------------------------------------------------------------
		DECLARE @NeedPartsEarly BIT =
			CASE WHEN @HasGlobalFilter       = 1
			       OR @PartNumberType       IS NOT NULL
			       OR @PartDescriptionType  IS NOT NULL
			       OR @PriorityType         IS NOT NULL
			       OR @ManufacturerType     IS NOT NULL
			       OR @RequestedDateType    IS NOT NULL
			       OR @EstimatedShipDateType IS NOT NULL
			       OR @NumberOfItemCount    IS NOT NULL
			       OR @SortColumn IN ('PARTNUMBERTYPE','PARTDESCRIPTIONTYPE','PRIORITYTYPE',
			                          'MANUFACTURERTYPE','REQUESTEDDATETYPE','ESTIMATEDSHIPDATETYPE',
			                          'NUMBEROFITEMCOUNT')
			     THEN 1 ELSE 0 END;

		DECLARE @NeedSoAmountEarly BIT =
			CASE WHEN @SoAmount IS NOT NULL OR @SortColumn = 'SOAMOUNT' THEN 1 ELSE 0 END;

		---------------------------------------------------------------------------
		-- 3. Timezone offset + SARGable date windows (computed ONCE, not per row)
		---------------------------------------------------------------------------
		DECLARE @UtcRef      DATETIME = GETUTCDATE();
		DECLARE @TzOffsetMin INT      = 0;

		IF @CurrntEmpTimeZoneDesc <> ''
			SET @TzOffsetMin = DATEDIFF(MINUTE, @UtcRef,
			                            dbo.ConvertUTCtoLocal(@UtcRef, @CurrntEmpTimeZoneDesc));

		DECLARE @CreatedFromUtc DATETIME, @CreatedToUtc DATETIME,
		        @UpdatedFromUtc DATETIME, @UpdatedToUtc DATETIME,
		        @OpenFrom       DATETIME, @OpenTo       DATETIME,
		        @QuoteFrom      DATETIME, @QuoteTo      DATETIME,
		        @ShipFrom       DATETIME, @ShipTo       DATETIME,
		        @ShippedDt      DATE     = TRY_CONVERT(DATE, @ShippedDate);   -- BUG 6

		IF @CreatedDate IS NOT NULL
		BEGIN
			SET @CreatedFromUtc = DATEADD(MINUTE, -@TzOffsetMin, CAST(CAST(@CreatedDate AS DATE) AS DATETIME));
			SET @CreatedToUtc   = DATEADD(MINUTE, -@TzOffsetMin, DATEADD(DAY, 1, CAST(CAST(@CreatedDate AS DATE) AS DATETIME)));
		END

		IF @UpdatedDate IS NOT NULL
		BEGIN
			SET @UpdatedFromUtc = DATEADD(MINUTE, -@TzOffsetMin, CAST(CAST(@UpdatedDate AS DATE) AS DATETIME));
			SET @UpdatedToUtc   = DATEADD(MINUTE, -@TzOffsetMin, DATEADD(DAY, 1, CAST(CAST(@UpdatedDate AS DATE) AS DATETIME)));
		END

		IF @OpenDate IS NOT NULL
		BEGIN
			SET @OpenFrom = CAST(CAST(@OpenDate AS DATE) AS DATETIME);
			SET @OpenTo   = DATEADD(DAY, 1, @OpenFrom);
		END

		IF @QuoteDate IS NOT NULL
		BEGIN
			SET @QuoteFrom = CAST(CAST(@QuoteDate AS DATE) AS DATETIME);
			SET @QuoteTo   = DATEADD(DAY, 1, @QuoteFrom);
		END

		IF @ShippedDt IS NOT NULL
		BEGIN
			SET @ShipFrom = CAST(@ShippedDt AS DATETIME);
			SET @ShipTo   = DATEADD(DAY, 1, @ShipFrom);
		END

		IF OBJECT_ID(N'tempdb..#Page') IS NOT NULL DROP TABLE #Page;

		---------------------------------------------------------------------------
		-- 4. PHASE 1 - filter, rank, page.
		--    Nothing expensive happens here unless the caller asked for it.
		---------------------------------------------------------------------------
		;WITH Base AS
		(
			SELECT
				SO.SalesOrderId,
				SO.SalesOrderNumber,
				SO.ContractReference,
				SOQ.SalesOrderQuoteNumber,
				SOQ.VersionNumber,
				SOQ.OpenDate                        AS QuoteDate,
				SO.OpenDate,
				SO.CustomerId,
				SO.CustomerName,
				SO.CustomerReference,
				MST.[Name]                          AS [Status],
				SO.StatusId,
				ISNULL(B.NetSales, 0)               AS QuoteAmount,
				ISNULL(B.Cost,     0)               AS Cost,
				(E.FirstName + ' ' + E.LastName)    AS SalesPerson,
				SO.AccountTypeName                  AS CustomerType,
				SO.ShippedDate,
				SO.CreatedDate                      AS CreatedDateUtc,  -- converted after paging
				SO.UpdatedDate                      AS UpdatedDateUtc,  -- converted after paging
				SO.CreatedBy,
				SO.UpdatedBy,
				SO.MarketplaceRef,
				ISNULL(PA.ItemNo, 0)                AS NumberOfItemCount,
				PA.ActiveCnt,
				PA.OnePartNumber,
				PA.OnePartDescription,
				PA.OneManufacturer,
				PA.OnePriority,
				PA.OneRequestedDate,
				PA.OneEstimatedShipDate,
				Z.SoAmount
			FROM dbo.SalesOrder SO WITH (NOLOCK)
			INNER JOIN dbo.MasterSalesOrderStatus MST WITH (NOLOCK)
				ON SO.StatusId = MST.Id
			LEFT JOIN dbo.Employee E WITH (NOLOCK)
				ON E.EmployeeId = SO.SalesPersonId
			LEFT JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK)
				ON SOQ.SalesOrderQuoteId = SO.SalesOrderQuoteId

			/* QuoteAmount + Cost roll-up. Cheap (one indexed table), and both are
			   filterable AND sortable, so it always runs.                        */
			OUTER APPLY
			(
				SELECT SUM(S.UnitCost)      AS Cost,
				       SUM(S.NetSaleAmount) AS NetSales
				FROM dbo.SalesOrderPartCost S WITH (NOLOCK)
				WHERE S.SalesOrderId = SO.SalesOrderId
			) B

			/* Replaces DatesCTE + PartCTE + PartDescCTE + PartMFCTE + PriorityCTE
			   + the PartCount apply: ONE pass over the parts of THIS Sales Order.
			   Gated - only runs when a part-derived column is filtered or sorted. */
			OUTER APPLY
			(
				SELECT
					COUNT(SP.SalesOrderPartId)                                          AS ItemNo,
					COUNT(CASE WHEN SP.IsActive = 1 AND SP.IsDeleted = 0 THEN 1 END)     AS ActiveCnt,
					MIN(CASE WHEN SP.IsActive = 1 AND SP.IsDeleted = 0 THEN IM.PartNumber      END) AS OnePartNumber,
					MIN(CASE WHEN SP.IsActive = 1 AND SP.IsDeleted = 0 THEN IM.PartDescription END) AS OnePartDescription,
					MIN(CASE WHEN SP.IsActive = 1 AND SP.IsDeleted = 0 THEN MA.[Name]          END) AS OneManufacturer,
					MIN(CASE WHEN SP.IsActive = 1 AND SP.IsDeleted = 0 THEN P.[Description]    END) AS OnePriority,
					MIN(CASE WHEN SP.IsActive = 1 AND SP.IsDeleted = 0
					         THEN CONVERT(VARCHAR(30), SP.CustomerRequestDate, @DateStyle) END)     AS OneRequestedDate,
					MIN(CASE WHEN SP.IsActive = 1 AND SP.IsDeleted = 0
					         THEN CONVERT(VARCHAR(30), SP.EstimatedShipDate,   @DateStyle) END)     AS OneEstimatedShipDate
				FROM dbo.SalesOrderPartV1 SP WITH (NOLOCK)
				LEFT JOIN dbo.ItemMaster   IM WITH (NOLOCK) ON IM.ItemMasterId   = SP.ItemMasterId
				LEFT JOIN dbo.Manufacturer MA WITH (NOLOCK) ON MA.ManufacturerId = IM.ManufacturerId
				LEFT JOIN dbo.[Priority]   P  WITH (NOLOCK) ON P.PriorityId      = SP.PriorityId
				WHERE SP.SalesOrderId  = SO.SalesOrderId
				  AND @NeedPartsEarly  = 1          -- folded to a constant by RECOMPILE
			) PA

			/* SO Amount roll-up - gated. Recomputed for the page in phase 2.      */
			OUTER APPLY
			(
				SELECT f.SoAmount
				FROM dbo.fnGetSalesOrderSoAmount(SO.SalesOrderId) f
				WHERE @NeedSoAmountEarly = 1        -- folded to a constant by RECOMPILE
			) Z

			WHERE
			    SO.IsDeleted       = @IsDeleted
			AND SO.MasterCompanyId = @MasterCompanyId
			AND (@StatusID IS NULL OR SO.StatusId = @StatusID)

			    /* was INNER JOIN dbo.Customer C - only ever used for C.CustomerId
			       (the join key itself) and C.CustomerCode (never projected out of
			       the Main CTE). Kept as a semi-join: identical filtering effect,
			       no join.                                                        */
			AND EXISTS (
					SELECT 1 FROM dbo.Customer C WITH (NOLOCK)
					WHERE C.CustomerId = SO.CustomerId
				)

			    -- security: semi-joins, no row multiplication, no DISTINCT needed
			AND EXISTS (
					SELECT 1
					FROM dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
					WHERE MSD.ModuleID    = @MSModuleID
					  AND MSD.ReferenceID = SO.SalesOrderId
				)
			AND EXISTS (
					SELECT 1
					FROM dbo.RoleManagementStructure RMS WITH (NOLOCK)
					INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK)
						ON EUR.RoleId = RMS.RoleId
					WHERE RMS.EntityStructureId = SO.ManagementStructureId
					  AND EUR.EmployeeId        = @EmployeeId
				)

			    -- base-column filters, pushed all the way down to the tables
			AND
			(
				@HasGlobalFilter = 1
				OR
				(
					    (@SOQNumber         IS NULL OR SOQ.SalesOrderQuoteNumber LIKE '%' + @SOQNumber         + '%')
					AND (@SalesOrderNumber  IS NULL OR SO.SalesOrderNumber       LIKE '%' + @SalesOrderNumber  + '%')
					AND (@ContractReference IS NULL OR SO.ContractReference      LIKE '%' + @ContractReference + '%')
					AND (@CustomerName      IS NULL OR SO.CustomerName           LIKE '%' + @CustomerName      + '%')
					AND (@CustomerReference IS NULL OR SO.CustomerReference      LIKE '%' + @CustomerReference + '%')
					AND (@CustomerType      IS NULL OR SO.AccountTypeName        LIKE '%' + @CustomerType      + '%')
					AND (@VersionNumber     IS NULL OR SOQ.VersionNumber         LIKE '%' + @VersionNumber     + '%')
					AND (@MarketplaceRef    IS NULL OR SO.MarketplaceRef         LIKE '%' + @MarketplaceRef    + '%')
					AND (@CreatedBy         IS NULL OR SO.CreatedBy              LIKE '%' + @CreatedBy         + '%')
					AND (@UpdatedBy         IS NULL OR SO.UpdatedBy              LIKE '%' + @UpdatedBy         + '%')
					AND (@Status            IS NULL OR MST.[Name]                LIKE '%' + @Status            + '%')
					AND (@SalesPerson       IS NULL OR (E.FirstName + ' ' + E.LastName) LIKE '%' + @SalesPerson + '%')
					AND (@QuoteAmount       IS NULL OR B.NetSales = @QuoteAmount)
					AND (@SoAmount          IS NULL OR Z.SoAmount = @SoAmount)

					-- SARGable date equality (half-open ranges)
					AND (@QuoteDate   IS NULL OR (SOQ.OpenDate     >= @QuoteFrom      AND SOQ.OpenDate     < @QuoteTo))
					AND (@OpenDate    IS NULL OR (SO.OpenDate      >= @OpenFrom       AND SO.OpenDate      < @OpenTo))
					AND (@ShippedDt   IS NULL OR (SO.ShippedDate   >= @ShipFrom       AND SO.ShippedDate   < @ShipTo))
					AND (@CreatedDate IS NULL OR (SO.CreatedDate   >= @CreatedFromUtc AND SO.CreatedDate   < @CreatedToUtc))
					AND (@UpdatedDate IS NULL OR (SO.UpdatedDate   >= @UpdatedFromUtc AND SO.UpdatedDate   < @UpdatedToUtc))
				)
			)
		),
		Src AS
		(
			SELECT
				Base.*,
				-- "...Type" = 'Multiple' when the SO has more than one active part,
				-- otherwise that single part's value, otherwise NULL. Identical to
				-- the five CTEs this replaces.
				CASE WHEN ISNULL(Base.ActiveCnt, 0) = 0 THEN NULL
				     WHEN Base.ActiveCnt > 1           THEN 'Multiple'
				     ELSE Base.OnePartNumber        END AS PartNumberType,
				CASE WHEN ISNULL(Base.ActiveCnt, 0) = 0 THEN NULL
				     WHEN Base.ActiveCnt > 1           THEN 'Multiple'
				     ELSE Base.OnePartDescription   END AS PartDescriptionType,
				CASE WHEN ISNULL(Base.ActiveCnt, 0) = 0 THEN NULL
				     WHEN Base.ActiveCnt > 1           THEN 'Multiple'
				     ELSE Base.OneManufacturer      END AS ManufacturerType,
				CASE WHEN ISNULL(Base.ActiveCnt, 0) = 0 THEN NULL
				     WHEN Base.ActiveCnt > 1           THEN 'Multiple'
				     ELSE Base.OnePriority          END AS PriorityType,
				CASE WHEN ISNULL(Base.ActiveCnt, 0) = 0 THEN NULL
				     WHEN Base.ActiveCnt > 1           THEN 'Multiple'
				     ELSE Base.OneRequestedDate     END AS RequestedDateType,
				CASE WHEN ISNULL(Base.ActiveCnt, 0) = 0 THEN NULL
				     WHEN Base.ActiveCnt > 1           THEN 'Multiple'
				     ELSE Base.OneEstimatedShipDate END AS EstimatedShipDateType
			FROM Base
		),
		Filtered AS
		(
			SELECT *
			FROM Src
			WHERE
			    -- part-derived column filters
			    (
					@HasGlobalFilter = 1
					OR
					(
						    (@PartNumberType        IS NULL OR PartNumberType        LIKE '%' + @PartNumberType        + '%')
						AND (@PartDescriptionType   IS NULL OR PartDescriptionType   LIKE '%' + @PartDescriptionType   + '%')
						AND (@ManufacturerType      IS NULL OR ManufacturerType      LIKE '%' + @ManufacturerType      + '%')
						AND (@PriorityType          IS NULL OR PriorityType          LIKE '%' + @PriorityType          + '%')
						AND (@RequestedDateType     IS NULL OR RequestedDateType     LIKE '%' + @RequestedDateType     + '%')
						AND (@EstimatedShipDateType IS NULL OR EstimatedShipDateType LIKE '%' + @EstimatedShipDateType + '%')
						AND (@NumberOfItemCount     IS NULL OR CAST(NumberOfItemCount AS VARCHAR(20)) LIKE '%' + @NumberOfItemCount + '%')
					)
				)
			    -- global "search everything" filter
			AND
			    (
					@HasGlobalFilter = 0
					OR
					(
						   SalesOrderQuoteNumber LIKE @GF
						OR SalesOrderNumber      LIKE @GF
						OR ContractReference     LIKE @GF
						OR CustomerName          LIKE @GF
						OR CustomerReference     LIKE @GF
						OR CustomerType          LIKE @GF
						OR [Status]              LIKE @GF
						OR VersionNumber         LIKE @GF
						OR SalesPerson           LIKE @GF
						OR MarketplaceRef        LIKE @GF
						OR CreatedBy             LIKE @GF
						OR UpdatedBy             LIKE @GF
						OR PriorityType          LIKE @GF
						OR PartNumberType        LIKE @GF
						OR PartDescriptionType   LIKE @GF
						OR ManufacturerType      LIKE @GF
						OR RequestedDateType     LIKE @GF
						OR EstimatedShipDateType LIKE @GF
						OR CONVERT(VARCHAR(30), OpenDate,    @DateStyle) LIKE @GF
						OR CONVERT(VARCHAR(30), ShippedDate, @DateStyle) LIKE @GF
						OR CAST(NumberOfItemCount AS VARCHAR(20))        LIKE @GF
					)
				)
		),
		Ranked AS
		(
			SELECT
				Filtered.*,
				COUNT(*) OVER ()  AS NumberOfItems,     -- total row count, single pass
				ROW_NUMBER() OVER (ORDER BY
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERID')          THEN SalesOrderId          END DESC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CREATEDDATE')            THEN CreatedDateUtc        END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'VERSIONNUMBER')          THEN VersionNumber         END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'OPENDATE')               THEN OpenDate              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'QUOTEDATE')              THEN QuoteDate             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'STATUS')                 THEN [Status]              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERNUMBER')       THEN SalesOrderNumber      END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CONTRACTREFERENCE')      THEN ContractReference     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PARTNUMBERTYPE')         THEN PartNumberType        END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'MANUFACTURERTYPE')       THEN ManufacturerType      END ASC,  -- BUG 1
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PARTDESCRIPTIONTYPE')    THEN PartDescriptionType   END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CUSTOMERNAME')           THEN CustomerName          END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CUSTOMERTYPE')           THEN CustomerType          END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CUSTOMERREFERENCE')      THEN CustomerReference     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'QUOTEAMOUNT')            THEN QuoteAmount           END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SOAMOUNT')               THEN SoAmount              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PRIORITYTYPE')           THEN PriorityType          END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESPERSON')            THEN SalesPerson           END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'UPDATEDDATE')            THEN UpdatedDateUtc        END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CREATEDBY')              THEN CreatedBy             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'MARKETPLACEREF')         THEN MarketplaceRef        END ASC,  -- BUG 1
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'UPDATEDBY')              THEN UpdatedBy             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'REQUESTEDDATETYPE')      THEN RequestedDateType     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'NUMBEROFITEMCOUNT')      THEN NumberOfItemCount     END ASC,

					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERID')           THEN SalesOrderId          END DESC,  -- BUG 2
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDDATE')            THEN CreatedDateUtc        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VERSIONNUMBER')          THEN VersionNumber         END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'OPENDATE')               THEN OpenDate              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUOTEDATE')              THEN QuoteDate             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'STATUS')                 THEN [Status]              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERNUMBER')       THEN SalesOrderNumber      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONTRACTREFERENCE')      THEN ContractReference     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTNUMBERTYPE')         THEN PartNumberType        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MANUFACTURERTYPE')       THEN ManufacturerType      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTIONTYPE')    THEN PartDescriptionType   END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERNAME')           THEN CustomerName          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERTYPE')           THEN CustomerType          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERREFERENCE')      THEN CustomerReference     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUOTEAMOUNT')            THEN QuoteAmount           END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SOAMOUNT')               THEN SoAmount              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PRIORITYTYPE')           THEN PriorityType          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESPERSON')            THEN SalesPerson           END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDDATE')            THEN UpdatedDateUtc        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDBY')              THEN CreatedBy             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MARKETPLACEREF')         THEN MarketplaceRef        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDBY')              THEN UpdatedBy             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'REQUESTEDDATETYPE')      THEN RequestedDateType     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'NUMBEROFITEMCOUNT')      THEN NumberOfItemCount     END DESC,

					-- deterministic tie-breaker: guarantees stable paging
					SalesOrderId DESC
				) AS RowSeq
			FROM Filtered
		)
		/* Only the cheap base-table columns are carried forward. Everything that
		   is derived from the parts of the Sales Order is rebuilt in phase 2 for
		   the returned page - the phase 1 copies exist purely so that filtering
		   and sorting can see them, and they are deliberately NOT projected here
		   (when the gates are off they would be NULL / 0).                       */
		SELECT
			SalesOrderId,
			SalesOrderNumber,
			ContractReference,
			SalesOrderQuoteNumber,
			VersionNumber,
			QuoteDate,
			OpenDate,
			CustomerId,
			CustomerName,
			CustomerReference,
			QuoteAmount,
			Cost,
			ShippedDate,
			SalesPerson,
			[Status],
			StatusId,
			CreatedDateUtc,
			UpdatedDateUtc,
			CreatedBy,
			UpdatedBy,
			MarketplaceRef,
			NumberOfItems,
			RowSeq
		INTO #Page
		FROM Ranked
		WHERE RowSeq >  @RecordFrom
		  AND RowSeq <= @RecordFrom + @PageSize
		OPTION (RECOMPILE);

		---------------------------------------------------------------------------
		-- 5. PHASE 2 - build the expensive display values for the returned page
		--    only (<= @PageSize rows), then return.
		--
		--    The FOR XML PATH concatenations and the "...Type" CASE expressions are
		--    reproduced verbatim from the five CTEs they replace - including the
		--    separators, the leading space left behind by STUFF(...,1,1,'') on the
		--    ', ' lists, and the XML escaping of &, < and > - so every returned
		--    string is byte-identical to the original.
		---------------------------------------------------------------------------
		SELECT
			k.SalesOrderId,
			UPPER(k.SalesOrderNumber)       AS SalesOrderNumber,
			UPPER(k.ContractReference)      AS ContractReference,
			UPPER(k.SalesOrderQuoteNumber)  AS SalesOrderQuoteNumber,
			UPPER(k.VersionNumber)          AS VersionNumber,
			k.QuoteDate,
			k.OpenDate,
			k.CustomerId,
			UPPER(k.CustomerName)           AS CustomerName,
			UPPER(k.CustomerReference)      AS CustomerReference,
			UPPER(L.PriorityDescription)    AS Priority,
			UPPER(T.PriorityType)           AS PriorityType,
			k.QuoteAmount,
			k.Cost,
			L.RequestedDate,
			T.RequestedDateType,
			L.EstimatedShipDate,
			T.EstimatedShipDateType,
			L.PromisedDate,
			k.ShippedDate,
			UPPER(L.Manufacturer)           AS Manufacturer,
			UPPER(T.ManufacturerType)       AS ManufacturerType,
			UPPER(k.SalesPerson)            AS SalesPerson,
			UPPER(k.[Status])               AS [Status],
			k.StatusId,
			UPPER(L.PartNumber)             AS PartNumber,
			UPPER(T.PartNumberType)         AS PartNumberType,
			UPPER(L.PartDescription)        AS PartDescription,
			UPPER(T.PartDescriptionType)    AS PartDescriptionType,
			-- exact same value as before: UDF now runs on <= @PageSize rows only
			CAST(dbo.ConvertUTCtoLocal(k.CreatedDateUtc, @CurrntEmpTimeZoneDesc) AS DATE) AS CreatedDate,
			CAST(dbo.ConvertUTCtoLocal(k.UpdatedDateUtc, @CurrntEmpTimeZoneDesc) AS DATE) AS UpdatedDate,
			k.NumberOfItems,
			UPPER(k.CreatedBy)              AS CreatedBy,
			UPPER(k.UpdatedBy)              AS UpdatedBy,
			ISNULL(L.ItemNo, 0)             AS NumberOfItemCount,
			ISNULL(Z.SoAmount, 0)           AS SoAmount,
			k.MarketplaceRef
		FROM #Page k
		OUTER APPLY
		(
			SELECT
				/* NumberOfItemCount: no IsActive / IsDeleted filter, matching the
				   original PartCount apply exactly - see BUG 8 in the header.     */
				(SELECT COUNT(SP2.SalesOrderPartId)
				 FROM dbo.SalesOrderPartV1 SP2 WITH (NOLOCK)
				 WHERE SP2.SalesOrderId = k.SalesOrderId)                    AS ItemNo,
				/* active part count - drives the 'Multiple' logic below           */
				(SELECT COUNT(SP3.SalesOrderPartId)
				 FROM dbo.SalesOrderPartV1 SP3 WITH (NOLOCK)
				 WHERE SP3.SalesOrderId = k.SalesOrderId
				   AND SP3.IsActive = 1 AND SP3.IsDeleted = 0)               AS ActiveCnt,
				STUFF((SELECT ',' + CONVERT(VARCHAR, S.CustomerRequestDate, 101)
				       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
				       WHERE S.SalesOrderId = k.SalesOrderId
				         AND S.IsActive = 1 AND S.IsDeleted = 0
				       FOR XML PATH('')), 1, 1, '')                          AS RequestedDate,
				STUFF((SELECT ',' + CONVERT(VARCHAR, S.PromisedDate, 101)
				       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
				       WHERE S.SalesOrderId = k.SalesOrderId
				         AND S.IsActive = 1 AND S.IsDeleted = 0
				       FOR XML PATH('')), 1, 1, '')                          AS PromisedDate,
				STUFF((SELECT ',' + CONVERT(VARCHAR, S.EstimatedShipDate, 101)
				       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
				       WHERE S.SalesOrderId = k.SalesOrderId
				         AND S.IsActive = 1 AND S.IsDeleted = 0
				       FOR XML PATH('')), 1, 1, '')                          AS EstimatedShipDate,
				STUFF((SELECT ',' + I.PartNumber
				       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
				       LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
				       WHERE S.SalesOrderId = k.SalesOrderId
				         AND S.IsActive = 1 AND S.IsDeleted = 0
				       FOR XML PATH('')), 1, 1, '')                          AS PartNumber,
				STUFF((SELECT ', ' + I.PartDescription
				       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
				       LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
				       WHERE S.SalesOrderId = k.SalesOrderId
				         AND S.IsActive = 1 AND S.IsDeleted = 0
				       FOR XML PATH('')), 1, 1, '')                          AS PartDescription,
				STUFF((SELECT ', ' + P.[Description]
				       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
				       LEFT JOIN dbo.[Priority] P WITH (NOLOCK) ON P.PriorityId = S.PriorityId
				       WHERE S.SalesOrderId = k.SalesOrderId
				         AND S.IsActive = 1 AND S.IsDeleted = 0
				       FOR XML PATH('')), 1, 1, '')                          AS PriorityDescription,
				/* reproduced verbatim, including the original's quirk of testing
				   IsActive / IsDeleted on the SALES ORDER (alias S) rather than on
				   the part - see BUG 7 in the header.                            */
				STUFF((SELECT ',' + MA.[Name]
				       FROM dbo.SalesOrder S WITH (NOLOCK)
				       LEFT JOIN dbo.SalesOrderPartV1 SP WITH (NOLOCK) ON S.SalesOrderId   = SP.SalesOrderId
				       LEFT JOIN dbo.ItemMaster       IM WITH (NOLOCK) ON IM.ItemMasterId   = SP.ItemMasterId
				       LEFT JOIN dbo.Manufacturer     MA WITH (NOLOCK) ON MA.ManufacturerId = IM.ManufacturerId
				       WHERE S.SalesOrderId = k.SalesOrderId
				         AND S.IsActive = 1 AND S.IsDeleted = 0
				       FOR XML PATH('')), 1, 1, '')                          AS Manufacturer
		) L
		CROSS APPLY
		(
			/* "...Type" = 'Multiple' when the SO has more than one active part,
			   otherwise the single value - which, when there is exactly one active
			   part, IS the concatenated list. Same construction as the original
			   CASE WHEN COUNT(SP.SalesOrderId) > 1 THEN 'Multiple' ELSE A.x END.  */
			SELECT
				CASE WHEN L.ActiveCnt = 0 THEN NULL WHEN L.ActiveCnt > 1 THEN 'Multiple' ELSE L.PartNumber          END AS PartNumberType,
				CASE WHEN L.ActiveCnt = 0 THEN NULL WHEN L.ActiveCnt > 1 THEN 'Multiple' ELSE L.PartDescription     END AS PartDescriptionType,
				CASE WHEN L.ActiveCnt = 0 THEN NULL WHEN L.ActiveCnt > 1 THEN 'Multiple' ELSE L.Manufacturer        END AS ManufacturerType,
				CASE WHEN L.ActiveCnt = 0 THEN NULL WHEN L.ActiveCnt > 1 THEN 'Multiple' ELSE L.PriorityDescription END AS PriorityType,
				CASE WHEN L.ActiveCnt = 0 THEN NULL WHEN L.ActiveCnt > 1 THEN 'Multiple' ELSE L.RequestedDate       END AS RequestedDateType,
				CASE WHEN L.ActiveCnt = 0 THEN NULL WHEN L.ActiveCnt > 1 THEN 'Multiple' ELSE L.EstimatedShipDate   END AS EstimatedShipDateType
		) T
		OUTER APPLY dbo.fnGetSalesOrderSoAmount(k.SalesOrderId) Z
		ORDER BY k.RowSeq;                                  -- deterministic grid order

		IF OBJECT_ID(N'tempdb..#Page') IS NOT NULL DROP TABLE #Page;

	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'ROLLBACK';
			ROLLBACK TRANSACTION;          -- was outside the IF in the original
		END

		DECLARE @ErrorLogID          INT,
		        @DatabaseName        VARCHAR(100)  = DB_NAME(),
		        @AdhocComments       VARCHAR(150)  = 'SearchSOViewData',
		        @ProcedureParameters VARCHAR(3000) = '@PageNumber = ''' + ISNULL(CONVERT(VARCHAR(20), @PageNumber), '') + '''',
		        @ApplicationName     VARCHAR(100)  = 'PAS';

		EXEC spLogException
			  @DatabaseName        = @DatabaseName
			, @AdhocComments       = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName     = @ApplicationName
			, @ErrorLogID          = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);

	END CATCH
END