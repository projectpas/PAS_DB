/**********************************************************************************
** File:        [SearchSalesOrderPNViewData]
** Description: Sales Order List - PN View grid data (paged / filtered / sorted)
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
**  6   27-06-2025      Bhargav Saliya      Add New Fields @NumberOfItemCount
**  7   19-11-2025      Rajesh Gami         Added SO Amount
** 10   20-11-2025      Rajesh Gami         Correct the SO Amount
** 11   19/JUN/2026     Amit Ghediya        Get [MarketplaceRef] data [PN-16922]
** 12   01/JUL/2026     Rajesh Gami         [PN-17008] Merge Non Stock Inventory to ItemMaster
** 13   22/JUL/2026     Rajesh Gami         [PN-17350] Removed leftover IsNonStock=0 filter
** 14   29/JUL/2026     Kishor Makwana      [PN-17466] PERFORMANCE REWRITE - Sales Order List filter slowness
** 15	05/August/2026	Divyesh Kathiriya	[PN-17555] - Fix filter to the search query.
  
***********************************************************************************/
CREATE   PROCEDURE [dbo].[SearchSalesOrderPNViewData]
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
	@OpenDate                DATETIME      = NULL,
	@QuoteDate               DATETIME      = NULL,
	@ShippedDate             DATETIME      = NULL,
	@SalesPerson             VARCHAR(50)   = NULL,
	@PriorityType            VARCHAR(50)   = NULL,
	@RequestedDateType       VARCHAR(50)   = NULL,
	@EstimatedShipDateType   VARCHAR(50)   = NULL,
	@PartNumberType          VARCHAR(50)   = NULL,
	@PartDescriptionType     VARCHAR(50)   = NULL,
	@CustomerReference       VARCHAR(50)   = NULL,
	@CustomerType            VARCHAR(50)   = NULL,
	@VersionNumber           VARCHAR(50)   = NULL,
	@CreatedDate             DATETIME      = NULL,
	@UpdatedDate             DATETIME      = NULL,
	@IsDeleted               BIT           = NULL,
	@CreatedBy               VARCHAR(50)   = NULL,
	@UpdatedBy               VARCHAR(50)   = NULL,
	@MasterCompanyId         INT           = NULL,
	@EmployeeId              BIGINT,
	@ManufacturerType        VARCHAR(50)   = NULL,
	@ContractReference       VARCHAR(50)   = NULL,
	@NumberOfItemCount       VARCHAR(50)   = NULL,
	@SoAmount                NUMERIC(18,4) = NULL,
	@MarketplaceRef          VARCHAR(100)  = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   -- read-only screen query
	SET XACT_ABORT OFF;

	BEGIN TRY

		---------------------------------------------------------------------------
		-- 1. Context / employee timezone   (2 round trips collapsed into 1)
		---------------------------------------------------------------------------
		DECLARE @MSModuleID            INT          = 17;   -- Sales Order Management Structure Module ID
		DECLARE @EmpLegalEntiyId       BIGINT       = 0;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		DECLARE @DateStyle             INT          = 120;  -- yyyy-mm-dd hh:mi:ss

		SELECT
			@EmpLegalEntiyId       = E.LegalEntityId,
			@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description], '')
		FROM dbo.Employee E WITH (NOLOCK)
		LEFT JOIN dbo.[TimeZone]  ETZ WITH (NOLOCK) ON E.TimeZoneId  = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE  WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.[TimeZone]  LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

		---------------------------------------------------------------------------
		-- 2. Parameter normalisation
		--    Every optional string becomes NULL when blank so that the
		--    (@p IS NULL OR ...) predicates can be constant-folded by RECOMPILE.
		---------------------------------------------------------------------------
		DECLARE @RecordFrom INT;

		SET @PageSize   = ISNULL(NULLIF(@PageSize, 0), 20);
		SET @PageNumber = CASE WHEN ISNULL(@PageNumber, 1) < 1 THEN 1 ELSE @PageNumber END;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		SET @IsDeleted   = ISNULL(@IsDeleted, 0);
		SET @SortColumn  = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@SortColumn)), ''), 'CreatedDate'));
		SET @SortOrder   = ISNULL(@SortOrder, 1);

		IF @StatusID = 0    SET @StatusID  = NULL;
		IF @Status   = '0'  SET @Status    = NULL;
		IF @SoAmount = 0    SET @SoAmount  = NULL;

		SET @GlobalFilter          = ISNULL(LTRIM(RTRIM(@GlobalFilter)), '');   -- BUG 3
		SET @SOQNumber             = NULLIF(LTRIM(RTRIM(@SOQNumber)),            '');
		SET @SalesOrderNumber      = NULLIF(LTRIM(RTRIM(@SalesOrderNumber)),     '');
		SET @CustomerName          = NULLIF(LTRIM(RTRIM(@CustomerName)),         '');
		SET @Status                = NULLIF(LTRIM(RTRIM(@Status)),               '');
		SET @SalesPerson           = NULLIF(LTRIM(RTRIM(@SalesPerson)),          '');
		SET @PriorityType          = NULLIF(LTRIM(RTRIM(@PriorityType)),         '');
		SET @RequestedDateType     = NULLIF(LTRIM(RTRIM(@RequestedDateType)),    '');
		SET @EstimatedShipDateType = NULLIF(LTRIM(RTRIM(@EstimatedShipDateType)),'');
		SET @PartNumberType        = NULLIF(LTRIM(RTRIM(@PartNumberType)),       '');
		SET @PartDescriptionType   = NULLIF(LTRIM(RTRIM(@PartDescriptionType)),  '');
		SET @CustomerReference     = NULLIF(LTRIM(RTRIM(@CustomerReference)),    '');
		SET @VersionNumber         = NULLIF(LTRIM(RTRIM(@VersionNumber)),        '');
		SET @CreatedBy             = NULLIF(LTRIM(RTRIM(@CreatedBy)),            '');
		SET @UpdatedBy             = NULLIF(LTRIM(RTRIM(@UpdatedBy)),            '');
		SET @ManufacturerType      = NULLIF(LTRIM(RTRIM(@ManufacturerType)),     '');
		SET @ContractReference     = NULLIF(LTRIM(RTRIM(@ContractReference)),    '');
		SET @NumberOfItemCount     = NULLIF(LTRIM(RTRIM(@NumberOfItemCount)),    '');
		SET @MarketplaceRef        = NULLIF(LTRIM(RTRIM(@MarketplaceRef)),       '');

		DECLARE @HasGlobalFilter BIT = CASE WHEN @GlobalFilter <> '' THEN 1 ELSE 0 END;
		DECLARE @GF VARCHAR(102) = '%' + @GlobalFilter + '%';

		---------------------------------------------------------------------------
		-- 3. Timezone offset + SARGable date windows (computed ONCE, not per row)
		---------------------------------------------------------------------------
		DECLARE @UtcRef       DATETIME = GETUTCDATE();
		DECLARE @TzOffsetMin  INT      = 0;

		IF @CurrntEmpTimeZoneDesc <> ''
			SET @TzOffsetMin = DATEDIFF(MINUTE, @UtcRef,
			                            dbo.ConvertUTCtoLocal(@UtcRef, @CurrntEmpTimeZoneDesc));

		DECLARE @CreatedFromUtc DATETIME, @CreatedToUtc DATETIME,
		        @UpdatedFromUtc DATETIME, @UpdatedToUtc DATETIME,
		        @OpenFrom       DATETIME, @OpenTo       DATETIME,
		        @QuoteFrom      DATETIME, @QuoteTo      DATETIME,
		        @ShipFrom       DATETIME, @ShipTo       DATETIME,
		        @ShipIsMinDate  BIT = 0;

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

		IF @ShippedDate IS NOT NULL
		BEGIN
			SET @ShipFrom      = CAST(CAST(@ShippedDate AS DATE) AS DATETIME);
			SET @ShipTo        = DATEADD(DAY, 1, @ShipFrom);
			-- original compared ISNULL(ShippedDate,'0001-01-01'), so the sentinel
			-- date must still match rows where ShippedDate IS NULL
			SET @ShipIsMinDate = CASE WHEN CAST(@ShippedDate AS DATE) = '0001-01-01' THEN 1 ELSE 0 END;
		END

		---------------------------------------------------------------------------
		-- 4. Single-pass: filter -> rank -> page
		---------------------------------------------------------------------------
		;WITH Src AS
		(
			SELECT
				SO.SalesOrderId,
				SO.SalesOrderNumber,
				SO.ContractReference,
				SOQ.SalesOrderQuoteNumber,
				SOQ.VersionNumber,
				SO.OpenDate,
				SO.CustomerId,
				SO.CustomerName,
				SO.CustomerReference,
				ISNULL(SP.PriorityName, '')                     AS Priority,
				ISNULL(SPC.NetSaleAmount, 0)                    AS QuoteAmount,
				ISNULL(SPC.UnitCost, 0)                         AS UnitCost,
				ISNULL(SP.CustomerRequestDate, '0001-01-01')    AS RequestedDate,
				SOQ.OpenDate                                    AS QuoteDate,
				ISNULL(SP.EstimatedShipDate, '0001-01-01')      AS EstimatedShipDate,
				ISNULL(SP.PromisedDate,      '0001-01-01')      AS PromisedDate,
				ISNULL(SO.ShippedDate,       '0001-01-01')      AS ShippedDate,
				(E.FirstName + ' ' + E.LastName)                AS SalesPerson,
				MST.[Name]                                      AS [Status],
				SO.StatusId,
				ISNULL(IM.PartNumber, '')                       AS PartNumber,
				M.[Name]                                        AS ManufacturerType,
				ISNULL(IM.PartDescription, '')                  AS PartDescription,
				SO.CreatedDate                                  AS CreatedDateUtc,   -- converted after paging
				SO.UpdatedDate                                  AS UpdatedDateUtc,   -- converted after paging
				SO.CreatedBy,
				SO.UpdatedBy,
				SO.MarketplaceRef,
				ISNULL(PC.ItemCount, 0)                         AS NumberOfItemCount,
				ISNULL(SPC.NetSaleAmount, 0)                    AS soAmount,
				SP.SalesOrderPartId,
				SP.QtyRequested,
				SP.QtyOrder,
				SP.UnitSalesPrice                               AS MainUnitSalesPrice
			FROM dbo.SalesOrder SO WITH (NOLOCK)
			INNER JOIN dbo.MasterSalesOrderQuoteStatus MST WITH (NOLOCK)
				ON SO.StatusId = MST.Id
			LEFT JOIN dbo.SalesOrderPartV1 SP WITH (NOLOCK)
				ON SO.SalesOrderId = SP.SalesOrderId
			   AND SP.IsDeleted = 0
			LEFT JOIN dbo.SalesOrderPartCost SPC WITH (NOLOCK)
				ON SPC.SalesOrderPartId = SP.SalesOrderPartId
			LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK)
				ON IM.ItemMasterId = SP.ItemMasterId
			LEFT JOIN dbo.Manufacturer M WITH (NOLOCK)
				ON IM.ManufacturerId = M.ManufacturerId
			LEFT JOIN dbo.Employee E WITH (NOLOCK)
				ON E.EmployeeId = SO.SalesPersonId
			LEFT JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK)
				ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
			OUTER APPLY
			(
				SELECT COUNT(1) AS ItemCount
				FROM dbo.SalesOrderPartV1 SPCNT WITH (NOLOCK)
				WHERE SPCNT.SalesOrderId = SO.SalesOrderId
				  AND SPCNT.IsDeleted    = 0
			) PC
			WHERE
			    -- ---- cheap, indexable, always applied -------------------------
			    SO.IsDeleted        = @IsDeleted
			AND SO.MasterCompanyId  = @MasterCompanyId
			AND (@StatusID IS NULL OR SO.StatusId = @StatusID)

			    -- ---- security: semi-joins, no row multiplication --------------
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
			
			    -- ---- per-column filters (only when no global filter) ----------
			AND
			(
					    (@SOQNumber            IS NULL OR SOQ.SalesOrderQuoteNumber LIKE '%' + @SOQNumber            + '%')
					AND (@SalesOrderNumber     IS NULL OR SO.SalesOrderNumber       LIKE '%' + @SalesOrderNumber     + '%')
					AND (@ContractReference    IS NULL OR SO.ContractReference      LIKE '%' + @ContractReference    + '%')
					AND (@CustomerName         IS NULL OR SO.CustomerName           LIKE '%' + @CustomerName         + '%')
					AND (@CustomerReference    IS NULL OR SO.CustomerReference      LIKE '%' + @CustomerReference    + '%')
					AND (@MarketplaceRef       IS NULL OR SO.MarketplaceRef         LIKE '%' + @MarketplaceRef       + '%')
					AND (@VersionNumber        IS NULL OR SOQ.VersionNumber         LIKE '%' + @VersionNumber        + '%')
					AND (@PriorityType         IS NULL OR SP.PriorityName           LIKE '%' + @PriorityType         + '%')
					AND (@ManufacturerType     IS NULL OR M.[Name]                  LIKE '%' + @ManufacturerType     + '%')
					AND (@PartNumberType       IS NULL OR IM.PartNumber             LIKE '%' + @PartNumberType       + '%')
					AND (@PartDescriptionType  IS NULL OR IM.PartDescription        LIKE '%' + @PartDescriptionType  + '%')
					AND (@Status               IS NULL OR MST.[Name]                LIKE '%' + @Status               + '%')
					AND (@CreatedBy            IS NULL OR SO.CreatedBy              LIKE '%' + @CreatedBy            + '%')
					AND (@UpdatedBy            IS NULL OR SO.UpdatedBy              LIKE '%' + @UpdatedBy            + '%')
					AND (@SalesPerson          IS NULL OR (E.FirstName + ' ' + E.LastName) LIKE '%' + @SalesPerson   + '%')
					AND (@SoAmount             IS NULL OR ISNULL(SPC.NetSaleAmount, 0) = @SoAmount)

					-- SARGable date equality (half-open ranges)
					AND (@OpenDate    IS NULL OR (SO.OpenDate    >= @OpenFrom       AND SO.OpenDate    < @OpenTo))
					AND (@QuoteDate   IS NULL OR (SOQ.OpenDate   >= @QuoteFrom      AND SOQ.OpenDate   < @QuoteTo))
					AND (@CreatedDate IS NULL OR (SO.CreatedDate >= @CreatedFromUtc AND SO.CreatedDate < @CreatedToUtc))
					AND (@UpdatedDate IS NULL OR (SO.UpdatedDate >= @UpdatedFromUtc AND SO.UpdatedDate < @UpdatedToUtc))
					AND (@ShippedDate IS NULL
					     OR (SO.ShippedDate >= @ShipFrom AND SO.ShippedDate < @ShipTo)
					     OR (@ShipIsMinDate = 1 AND SO.ShippedDate IS NULL))

					-- these two are "type" filters that the UI sends as text
					AND (@RequestedDateType IS NULL
					     OR CONVERT(VARCHAR(30), ISNULL(SP.CustomerRequestDate, '0001-01-01'), @DateStyle) LIKE '%' + @RequestedDateType + '%')
					AND (@EstimatedShipDateType IS NULL
					     OR CONVERT(VARCHAR(30), ISNULL(SP.EstimatedShipDate,   '0001-01-01'), @DateStyle) LIKE '%' + @EstimatedShipDateType + '%')

					-- BUG 2 fixed: was comparing against @Status
					AND (@NumberOfItemCount IS NULL
					     OR CAST(ISNULL(PC.ItemCount, 0) AS VARCHAR(20)) LIKE '%' + @NumberOfItemCount + '%')
			)

			    -- ---- global "search everything" filter ------------------------
			AND
			(
				@HasGlobalFilter = 0
				OR
				(
					   SOQ.SalesOrderQuoteNumber LIKE @GF
					OR SO.SalesOrderNumber       LIKE @GF
					OR SO.ContractReference      LIKE @GF
					OR SO.CustomerName           LIKE @GF
					OR SO.CustomerReference      LIKE @GF
					OR SO.MarketplaceRef         LIKE @GF
					OR SOQ.VersionNumber         LIKE @GF        -- BUG 1 fixed
					OR SP.PriorityName           LIKE @GF
					OR IM.PartNumber             LIKE @GF
					OR IM.PartDescription        LIKE @GF
					OR M.[Name]                  LIKE @GF
					OR MST.[Name]                LIKE @GF
					OR (E.FirstName + ' ' + E.LastName) LIKE @GF
					OR CONVERT(VARCHAR(30), SO.OpenDate,            @DateStyle) LIKE @GF
					OR CONVERT(VARCHAR(30), SOQ.OpenDate,           @DateStyle) LIKE @GF
					OR CONVERT(VARCHAR(30), SP.CustomerRequestDate, @DateStyle) LIKE @GF
					OR CONVERT(VARCHAR(30), SP.EstimatedShipDate,   @DateStyle) LIKE @GF
					OR CONVERT(VARCHAR(30), SP.PromisedDate,        @DateStyle) LIKE @GF
					OR CONVERT(VARCHAR(30), SO.ShippedDate,         @DateStyle) LIKE @GF
					OR CONVERT(VARCHAR(30), DATEADD(MINUTE, @TzOffsetMin, SO.CreatedDate), @DateStyle) LIKE @GF
					OR CONVERT(VARCHAR(30), DATEADD(MINUTE, @TzOffsetMin, SO.UpdatedDate), @DateStyle) LIKE @GF
					OR CAST(ISNULL(PC.ItemCount, 0) AS VARCHAR(20)) LIKE @GF
				)
			)
		),
		Ranked AS
		(
			SELECT
				Src.*,
				COUNT(*) OVER ()  AS NumberOfItems,     -- total row count, single pass
				ROW_NUMBER() OVER (ORDER BY
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERID')            THEN Src.SalesOrderId          END DESC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERNUMBER')        THEN Src.SalesOrderNumber      END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CONTRACTREFERENCE')       THEN Src.ContractReference     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERQUOTENUMBER')   THEN Src.SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'VERSIONNUMBER')           THEN Src.VersionNumber         END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'QUOTEDATE')               THEN Src.QuoteDate             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'STATUS')                  THEN Src.[Status]              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PARTNUMBERTYPE')          THEN Src.PartNumber            END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PARTDESCRIPTIONTYPE')     THEN Src.PartDescription       END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CUSTOMERNAME')            THEN Src.CustomerName          END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CUSTOMERREFERENCE')       THEN Src.CustomerReference     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PRIORITYTYPE')            THEN Src.Priority              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'OPENDATE')                THEN Src.OpenDate              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'REQUESTEDDATE')           THEN Src.RequestedDate         END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'REQUESTEDDATETYPE')       THEN Src.RequestedDate         END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'ESTIMATEDSHIPDATE')       THEN Src.EstimatedShipDate     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'ESTIMATEDSHIPDATETYPE')   THEN Src.EstimatedShipDate     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESPERSON')             THEN Src.SalesPerson           END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CREATEDDATE')             THEN Src.CreatedDateUtc        END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'UPDATEDDATE')             THEN Src.UpdatedDateUtc        END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CREATEDBY')               THEN Src.CreatedBy             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'UPDATEDBY')               THEN Src.UpdatedBy             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'MARKETPLACEREF')          THEN Src.MarketplaceRef        END ASC,  -- BUG 4
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'NUMBEROFITEMCOUNT')       THEN Src.NumberOfItemCount     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SOAMOUNT')                THEN Src.soAmount              END ASC,

					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERID')            THEN Src.SalesOrderId          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERNUMBER')        THEN Src.SalesOrderNumber      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONTRACTREFERENCE')       THEN Src.ContractReference     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERQUOTENUMBER')   THEN Src.SalesOrderQuoteNumber END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VERSIONNUMBER')           THEN Src.VersionNumber         END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUOTEDATE')               THEN Src.QuoteDate             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'STATUS')                  THEN Src.[Status]              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTNUMBERTYPE')          THEN Src.PartNumber            END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTIONTYPE')     THEN Src.PartDescription       END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERNAME')            THEN Src.CustomerName          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERREFERENCE')       THEN Src.CustomerReference     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PRIORITYTYPE')            THEN Src.Priority              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'OPENDATE')                THEN Src.OpenDate              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'REQUESTEDDATE')           THEN Src.RequestedDate         END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'REQUESTEDDATETYPE')       THEN Src.RequestedDate         END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ESTIMATEDSHIPDATE')       THEN Src.EstimatedShipDate     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ESTIMATEDSHIPDATETYPE')   THEN Src.EstimatedShipDate     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESPERSON')             THEN Src.SalesPerson           END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDDATE')             THEN Src.CreatedDateUtc        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDDATE')             THEN Src.UpdatedDateUtc        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDBY')               THEN Src.CreatedBy             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDBY')               THEN Src.UpdatedBy             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MARKETPLACEREF')          THEN Src.MarketplaceRef        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'NUMBEROFITEMCOUNT')       THEN Src.NumberOfItemCount     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SOAMOUNT')                THEN Src.soAmount              END DESC,

					-- deterministic tie-breaker: guarantees stable paging
					Src.SalesOrderId DESC, Src.SalesOrderPartId ASC
				) AS RowSeq
			FROM Src
		)
		SELECT
			SalesOrderId,
			UPPER(SalesOrderNumber)         AS SalesOrderNumber,
			UPPER(ContractReference)        AS ContractReference,
			UPPER(SalesOrderQuoteNumber)    AS SalesOrderQuoteNumber,
			UPPER(VersionNumber)            AS VersionNumber,
			OpenDate,
			CustomerId,
			UPPER(CustomerName)             AS CustomerName,
			UPPER(CustomerReference)        AS CustomerReference,
			UPPER(Priority)                 AS Priority,
			UPPER(Priority)                 AS PriorityType,
			QuoteAmount,
			UnitCost,
			RequestedDate,
			RequestedDate                   AS RequestedDateType,
			QuoteDate,
			EstimatedShipDate,
			EstimatedShipDate               AS EstimatedShipDateType,
			PromisedDate,
			ShippedDate,
			UPPER(SalesPerson)              AS SalesPerson,
			UPPER([Status])                 AS [Status],
			StatusId,
			UPPER(PartNumber)               AS PartNumber,
			UPPER(ManufacturerType)         AS ManufacturerType,
			UPPER(PartNumber)               AS PartNumberType,
			UPPER(PartDescription)          AS PartDescription,
			UPPER(PartDescription)          AS PartDescriptionType,
			-- exact same value as before: UDF now runs on <= @PageSize rows only
			CAST(dbo.ConvertUTCtoLocal(CreatedDateUtc, @CurrntEmpTimeZoneDesc) AS DATE) AS CreatedDate,
			CAST(dbo.ConvertUTCtoLocal(UpdatedDateUtc, @CurrntEmpTimeZoneDesc) AS DATE) AS UpdatedDate,
			UPPER(CreatedBy)                AS CreatedBy,
			UPPER(UpdatedBy)                AS UpdatedBy,
			MarketplaceRef,
			NumberOfItemCount,
			NumberOfItems,
			soAmount,
			SalesOrderPartId,
			QtyRequested,
			QtyOrder,
			MainUnitSalesPrice,
			RowSeq
		INTO #tmpSOPartTblData
		FROM Ranked
		WHERE RowSeq >  @RecordFrom
		  AND RowSeq <= @RecordFrom + @PageSize
		OPTION (RECOMPILE);

		CREATE CLUSTERED INDEX CIX_tmpSOPartTblData ON #tmpSOPartTblData (SalesOrderPartId);

		---------------------------------------------------------------------------
		-- 5. Part-wise cost (SO Amount) - runs against the current page only
		---------------------------------------------------------------------------
		;WITH CTE_Cost AS
		(
			SELECT
				dt.SalesOrderPartId,
				SUM(ISNULL(
						CASE WHEN stk.SalesOrderStocklineId IS NOT NULL
							 THEN stk.QtyOrder
							 ELSE CASE WHEN ISNULL(dt.QtyOrder, 0) > 0
									   THEN ISNULL(dt.QtyOrder, 0)
									   ELSE ISNULL(dt.QtyRequested, 0)
								  END
						END, 0))                                        AS TotalQtyQuoted,
				SUM(ISNULL(
						CASE WHEN SC.SalesOrderStocklineId IS NOT NULL
							 THEN ISNULL(SC.NetSaleAmount, 0)
							 ELSE ISNULL(dt.QuoteAmount,   0)
						END, 0))                                        AS TotalNetSalePriceExtended
			FROM #tmpSOPartTblData dt
			LEFT JOIN dbo.SalesOrderStocklineV1 stk WITH (NOLOCK)
				ON stk.SalesOrderPartId = dt.SalesOrderPartId
			LEFT JOIN dbo.SalesOrderStockLineCost SC WITH (NOLOCK)
				ON SC.SalesOrderStocklineId = stk.SalesOrderStocklineId
			GROUP BY dt.SalesOrderPartId
		)
		SELECT
			main.SalesOrderId,
			main.SalesOrderNumber,
			main.ContractReference,
			main.SalesOrderQuoteNumber,
			main.VersionNumber,
			main.OpenDate,
			main.CustomerId,
			main.CustomerName,
			main.CustomerReference,
			main.Priority,
			main.PriorityType,
			main.QuoteAmount,
			main.UnitCost,
			main.RequestedDate,
			main.RequestedDateType,
			main.QuoteDate,
			main.EstimatedShipDate,
			main.EstimatedShipDateType,
			main.PromisedDate,
			main.ShippedDate,
			main.SalesPerson,
			main.[Status],
			main.StatusId,
			main.PartNumber,
			main.ManufacturerType,
			main.PartNumberType,
			main.PartDescription,
			main.PartDescriptionType,
			main.CreatedDate,
			main.UpdatedDate,
			main.CreatedBy,
			main.UpdatedBy,
			main.MarketplaceRef,
			main.NumberOfItemCount,
			main.NumberOfItems,
			ISNULL(tp.TotalPartCost, 0)     AS soAmount,      -- replaces the old UPDATE pass
			main.SalesOrderPartId,
			main.QtyRequested,
			main.QtyOrder,
			main.MainUnitSalesPrice,
			tp.TotalPartCost
		FROM #tmpSOPartTblData main
		LEFT JOIN CTE_Cost c
			ON main.SalesOrderPartId = c.SalesOrderPartId
		CROSS APPLY
		(
			SELECT ((main.QtyRequested - ISNULL(c.TotalQtyQuoted, 0)) * ISNULL(main.MainUnitSalesPrice, 0))
			       + ISNULL(c.TotalNetSalePriceExtended, 0) AS TotalPartCost
		) tp
		ORDER BY main.RowSeq;                                  -- deterministic grid order

		IF OBJECT_ID(N'tempdb..#tmpSOPartTblData') IS NOT NULL
			DROP TABLE #tmpSOPartTblData;

	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'ROLLBACK';
			ROLLBACK TRANSACTION;          -- was outside the IF in the original
		END

		DECLARE @ErrorLogID          INT,
		        @DatabaseName        VARCHAR(100)  = DB_NAME(),
		        @AdhocComments       VARCHAR(150)  = 'SearchSalesOrderPNViewData',
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