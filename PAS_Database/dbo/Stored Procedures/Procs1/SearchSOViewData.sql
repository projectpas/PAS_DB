/*************************************************************           
 ** File:   [SearchSOViewData]
 ** Author:  
 ** Description: This stored procedure is used display sales order list
 ** Purpose:         
 ** Date:        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
 ** 1    04/08/2023  Ekta Chandegara    Convert text into uppercase
 **	2    06/26/2024  AMIT GHEDIYA       Added orderby for RequestedDate,EstimatedShipDate
 **	3    20-09-2024  Shrey Chandegara	ADD New Column in list (@ContractReference)
 **	4	 22-01-2025  Ayushi Patel		converted the date into utc (created , updated) , Added a case to get timeZone
 **	5	 10-04-2025  Vishal Suthar		Applied Optimization, Standard Formatting and Cleanup
 **	6	 25-04-2025  Bhargav Saliya		Customer Name Get from the SO table instead of the Customer table
 **	7    27-06-2025  Bhargav Saliya		Add New Fields @NumberOfItemCount 
 **	8    03-09-2025  AMIT GHEDIYA		Updated for filter issue (SalesQuoteNumber)
 **	9    19-11-2025  RAJESH GAMI		Return SO Amount
 **	10   20-11-2025  Rajesh Gami		Correct the SOAmount
 **	11   19/JUN/2026 AMIT GHEDIYA		Get [MarketplaceRef] data [PN-16922]
** 12   01/JUL/2026     Rajesh Gami         [PN-17008] Merge Non Stock Inventory to ItemMaster
** 13   23/JUL/2026     Rajesh Gami         [PN-17350] Removed leftover IsNonStock=0 filters
**  14   29/JUL/2026     Kishor Makwana      PERFORMANCE ONLY - Sales Order List filter slowness.
** 15	 05/Aug/2026	 Divyesh Kathiriya	[PN-17555] - Fix filter to the search query.

***********************************************************************************/
CREATE PROCEDURE [dbo].[SearchSOViewData]
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
		---------------------------------------------------------------------------
		DECLARE @RecordFrom INT;

		SET @PageSize   = ISNULL(NULLIF(@PageSize, 0), 20);
		SET @PageNumber = CASE WHEN ISNULL(@PageNumber, 1) < 1 THEN 1 ELSE @PageNumber END;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		SET @IsDeleted  = ISNULL(@IsDeleted, 0);
		SET @SortColumn = UPPER(ISNULL(NULLIF(@SortColumn, ''), 'SalesOrderId'));
		SET @SortOrder  = ISNULL(@SortOrder, 1);

		IF @QuoteAmount = 0 SET @QuoteAmount = NULL;
		IF @SoAmount    = 0 SET @SoAmount    = NULL;
		IF @StatusID    = 0 SET @StatusID    = NULL;
		IF @Status   = '0'  SET @Status      = NULL;
		
		SET @SOQNumber             = NULLIF(@SOQNumber, '');
		SET @SalesOrderNumber      = NULLIF(@SalesOrderNumber, '');
		SET @CustomerName          = NULLIF(@CustomerName, '');
		SET @Status                = NULLIF(@Status, '');
		SET @SalesPerson           = NULLIF(@SalesPerson, '');
		SET @PriorityType          = NULLIF(@PriorityType, '');
		SET @PartNumberType        = NULLIF(@PartNumberType, '');
		SET @PartDescriptionType   = NULLIF(@PartDescriptionType, '');
		SET @CustomerReference     = NULLIF(@CustomerReference, '');
		SET @CustomerType          = NULLIF(@CustomerType, '');
		SET @VersionNumber         = NULLIF(@VersionNumber, '');
		SET @CreatedBy             = NULLIF(@CreatedBy, '');
		SET @UpdatedBy             = NULLIF(@UpdatedBy, '');
		SET @RequestedDateType     = NULLIF(@RequestedDateType, '');
		SET @EstimatedShipDateType = NULLIF(@EstimatedShipDateType, '');
		SET @ManufacturerType      = NULLIF(@ManufacturerType, '');
		SET @ContractReference     = NULLIF(@ContractReference, '');
		SET @NumberOfItemCount     = NULLIF(@NumberOfItemCount, '');
		SET @MarketplaceRef        = NULLIF(@MarketplaceRef, '');
		SET @ShippedDate           = NULLIF(@ShippedDate, '');

		DECLARE @GfMode TINYINT =
			CASE WHEN @GlobalFilter IS NULL THEN 2
			     WHEN @GlobalFilter <> ''   THEN 1
			     ELSE 0 END;
		DECLARE @GF VARCHAR(102) = '%' + @GlobalFilter + '%';

		---------------------------------------------------------------------------
		-- 2b. Cost gates.
		---------------------------------------------------------------------------
		DECLARE @NeedPartsEarly BIT =
			CASE WHEN @GfMode                 = 1
			       OR @PartNumberType        IS NOT NULL
			       OR @PartDescriptionType   IS NOT NULL
			       OR @PriorityType          IS NOT NULL
			       OR @ManufacturerType      IS NOT NULL
			       OR @RequestedDateType     IS NOT NULL
			       OR @EstimatedShipDateType IS NOT NULL
			       OR @NumberOfItemCount     IS NOT NULL
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

		DECLARE @CreatedFromUtc DATETIME2(3), @CreatedToUtc DATETIME2(3),
		        @UpdatedFromUtc DATETIME2(3), @UpdatedToUtc DATETIME2(3),
		        @OpenFrom       DATETIME2(3), @OpenTo       DATETIME2(3),
		        @QuoteFrom      DATETIME2(3), @QuoteTo      DATETIME2(3),
		        @ShipFrom       DATETIME2(3), @ShipTo       DATETIME2(3),
		        @ShippedDt      DATE = TRY_CONVERT(DATE, @ShippedDate);   -- BUG 6

		IF ISNULL(@CreatedDate, '') <> ''
		BEGIN
			SET @CreatedFromUtc = DATEADD(MINUTE, -@TzOffsetMin, CAST(CAST(@CreatedDate AS DATE) AS DATETIME2(3)));
			SET @CreatedToUtc   = DATEADD(MINUTE, -@TzOffsetMin, DATEADD(DAY, 1, CAST(CAST(@CreatedDate AS DATE) AS DATETIME2(3))));
		END

		IF ISNULL(@UpdatedDate, '') <> ''
		BEGIN
			SET @UpdatedFromUtc = DATEADD(MINUTE, -@TzOffsetMin, CAST(CAST(@UpdatedDate AS DATE) AS DATETIME2(3)));
			SET @UpdatedToUtc   = DATEADD(MINUTE, -@TzOffsetMin, DATEADD(DAY, 1, CAST(CAST(@UpdatedDate AS DATE) AS DATETIME2(3))));
		END

		IF ISNULL(@OpenDate, '') <> ''
		BEGIN
			SET @OpenFrom = CAST(CAST(@OpenDate AS DATE) AS DATETIME2(3));
			SET @OpenTo   = DATEADD(DAY, 1, @OpenFrom);
		END

		IF ISNULL(@QuoteDate, '') <> ''
		BEGIN
			SET @QuoteFrom = CAST(CAST(@QuoteDate AS DATE) AS DATETIME2(3));
			SET @QuoteTo   = DATEADD(DAY, 1, @QuoteFrom);
		END

		IF @ShippedDt IS NOT NULL AND ISNULL(@ShippedDate, '') <> ''
		BEGIN
			SET @ShipFrom = CAST(@ShippedDt AS DATETIME2(3));
			SET @ShipTo   = DATEADD(DAY, 1, @ShipFrom);
		END

		IF OBJECT_ID(N'tempdb..#Page') IS NOT NULL DROP TABLE #Page;

		---------------------------------------------------------------------------
		-- 4. PHASE 1 - filter, rank, page.
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
				SO.CreatedDate                      AS CreatedDateUtc,  -- UDF applied after paging
				SO.UpdatedDate                      AS UpdatedDateUtc,  -- UDF applied after paging
				/* the day-precision local values the original sorted/filtered on */
				CAST(DATEADD(MINUTE, @TzOffsetMin, SO.CreatedDate) AS DATE) AS CreatedDateLocal,
				CAST(DATEADD(MINUTE, @TzOffsetMin, SO.UpdatedDate) AS DATE) AS UpdatedDateLocal,
				SO.CreatedBy,
				SO.UpdatedBy,
				SO.MarketplaceRef,
				ISNULL(AG.AllParts, 0)              AS NumberOfItemCount,
				AG.PartNumberType,
				AG.PartDescriptionType,
				AG.ManufacturerType,
				AG.PriorityType,
				AG.RequestedDateType,
				AG.EstimatedShipDateType,
				Z.SoAmount
			FROM dbo.SalesOrder SO WITH (NOLOCK)
			INNER JOIN dbo.MasterSalesOrderStatus MST WITH (NOLOCK)
				ON SO.StatusId = MST.Id
			LEFT JOIN dbo.Employee E WITH (NOLOCK)
				ON E.EmployeeId = SO.SalesPersonId
			LEFT JOIN dbo.SalesOrderQuote SOQ WITH (NOLOCK)
				ON SOQ.SalesOrderQuoteId = SO.SalesOrderQuoteId
			
			OUTER APPLY
			(
				SELECT SUM(S.UnitCost)      AS Cost,
				       SUM(S.NetSaleAmount) AS NetSales
				FROM dbo.SalesOrderPartCost S WITH (NOLOCK)
				WHERE S.SalesOrderId = SO.SalesOrderId
			) B

			
			OUTER APPLY
			(
				SELECT
					RAW.AllParts,					
					CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.PartNumberList        END AS PartNumberType,
					CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.PartDescriptionList   END AS PartDescriptionType,
					CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.ManufacturerList      END AS ManufacturerType,
					CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.PriorityList          END AS PriorityType,
					CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.RequestedDateList     END AS RequestedDateType,
					CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.EstimatedShipDateList END AS EstimatedShipDateType
				FROM
				(
					SELECT
						/* PartCount apply, verbatim: NO IsActive/IsDeleted filter */
						(SELECT COUNT(SP.SalesOrderPartId)
						 FROM dbo.SalesOrderPartV1 SP WITH (NOLOCK)
						 WHERE SP.SalesOrderId = SO.SalesOrderId)                    AS AllParts,
						/* the COUNT(SP.SalesOrderId) that drove 'Multiple' in all
						   five CTEs: active parts only */
						(SELECT COUNT(SP.SalesOrderPartId)
						 FROM dbo.SalesOrderPartV1 SP WITH (NOLOCK)
						 WHERE SP.SalesOrderId = SO.SalesOrderId
						   AND SP.IsActive = 1 AND SP.IsDeleted = 0)                 AS ActiveParts,
						STUFF((SELECT ',' + CONVERT(VARCHAR, S.CustomerRequestDate, 101)
						       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
						       WHERE S.SalesOrderId = SO.SalesOrderId
						         AND S.IsActive = 1 AND S.IsDeleted = 0
						       FOR XML PATH('')), 1, 1, '')                          AS RequestedDateList,
						STUFF((SELECT ',' + CONVERT(VARCHAR, S.EstimatedShipDate, 101)
						       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
						       WHERE S.SalesOrderId = SO.SalesOrderId
						         AND S.IsActive = 1 AND S.IsDeleted = 0
						       FOR XML PATH('')), 1, 1, '')                          AS EstimatedShipDateList,
						STUFF((SELECT ',' + I.PartNumber
						       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
						       LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
						       WHERE S.SalesOrderId = SO.SalesOrderId
						         AND S.IsActive = 1 AND S.IsDeleted = 0
						       FOR XML PATH('')), 1, 1, '')                          AS PartNumberList,
						STUFF((SELECT ', ' + I.PartDescription
						       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
						       LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
						       WHERE S.SalesOrderId = SO.SalesOrderId
						         AND S.IsActive = 1 AND S.IsDeleted = 0
						       FOR XML PATH('')), 1, 1, '')                          AS PartDescriptionList,
						STUFF((SELECT ', ' + P.[Description]
						       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
						       LEFT JOIN dbo.[Priority] P WITH (NOLOCK) ON P.PriorityId = S.PriorityId
						       WHERE S.SalesOrderId = SO.SalesOrderId
						         AND S.IsActive = 1 AND S.IsDeleted = 0
						       FOR XML PATH('')), 1, 1, '')                          AS PriorityList,
						/* verbatim, including the original's quirk of testing
						   IsActive / IsDeleted on the SALES ORDER (alias S)        */
						STUFF((SELECT ',' + MA.[Name]
						       FROM dbo.SalesOrder S WITH (NOLOCK)
						       LEFT JOIN dbo.SalesOrderPartV1 SP WITH (NOLOCK) ON S.SalesOrderId   = SP.SalesOrderId
						       LEFT JOIN dbo.ItemMaster       IM WITH (NOLOCK) ON IM.ItemMasterId   = SP.ItemMasterId
						       LEFT JOIN dbo.Manufacturer     MA WITH (NOLOCK) ON MA.ManufacturerId = IM.ManufacturerId
						       WHERE S.SalesOrderId = SO.SalesOrderId
						         AND S.IsActive = 1 AND S.IsDeleted = 0
						       FOR XML PATH('')), 1, 1, '')                          AS ManufacturerList
				) RAW
				WHERE @NeedPartsEarly = 1          -- folded to a constant by RECOMPILE
			) AG
			
			OUTER APPLY
			(
				SELECT SUM(X.NetSales) AS SoAmount
				FROM
				(
					SELECT
						(
							CASE
								WHEN ISNULL(SOP.QtyRequested, 0) =
								     ISNULL(SUM(CASE WHEN stk.SalesOrderStocklineId IS NOT NULL
								                     THEN stk.QtyOrder
								                     ELSE SOP.QtyOrder
								                END), 0)
								THEN 0
								ELSE
								(
									(
										ISNULL(SUM(
											CASE WHEN stk.SalesOrderStocklineId IS NOT NULL
											     THEN stk.QtyOrder
											     ELSE CASE WHEN ISNULL(SOP.QtyOrder, 0) > 0
											               THEN ISNULL(SOP.QtyOrder, 0)
											               ELSE ISNULL(SOP.QtyRequested, 0)
											          END
											END), 0) * -1
										+ ISNULL(SOP.QtyRequested, 0)
									) * ISNULL(SOP.UnitSalesPrice, 0)
								)
							END
						)
						+
						ISNULL(SUM(
							CASE WHEN SC.SalesOrderStocklineId IS NOT NULL
							     THEN ISNULL(SC.NetSaleAmount,    0)
							     ELSE ISNULL(SOQPS.NetSaleAmount, 0)
							END), 0)                                    AS NetSales
					FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK)
					INNER JOIN dbo.SalesOrderPartCost SOQPS WITH (NOLOCK)
						ON  SOQPS.SalesOrderId     = SOP.SalesOrderId
						AND SOQPS.SalesOrderPartId = SOP.SalesOrderPartId
					LEFT JOIN dbo.SalesOrderStocklineV1 stk WITH (NOLOCK)
						ON stk.SalesOrderPartId = SOP.SalesOrderPartId
					LEFT JOIN dbo.SalesOrderStockLineCost SC WITH (NOLOCK)
						ON  SC.SalesOrderStocklineId = stk.SalesOrderStocklineId
						AND SC.SalesOrderId          = SOP.SalesOrderId
					WHERE SOP.SalesOrderId  = SO.SalesOrderId
					  AND @NeedSoAmountEarly = 1   -- folded to a constant by RECOMPILE
					GROUP BY SOP.SalesOrderPartId, SOP.QtyRequested, SOP.UnitSalesPrice
				) X
			) Z
			/*==================== end KEEP IN SYNC block 2 ======================*/

			WHERE
			    /* [D] mode 2 = @GlobalFilter IS NULL -> zero rows, exactly as before */
			    @GfMode <> 2
			AND SO.IsDeleted       = @IsDeleted
			AND SO.MasterCompanyId = @MasterCompanyId
			AND (@StatusID IS NULL OR SO.StatusId = @StatusID)
			 
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
					AND (@QuoteFrom   IS NULL OR (SOQ.OpenDate   >= @QuoteFrom      AND SOQ.OpenDate   < @QuoteTo))
					AND (@OpenFrom    IS NULL OR (SO.OpenDate    >= @OpenFrom       AND SO.OpenDate    < @OpenTo))
					AND (@ShipFrom    IS NULL OR (SO.ShippedDate >= @ShipFrom       AND SO.ShippedDate < @ShipTo))
					AND (@CreatedFromUtc IS NULL OR (SO.CreatedDate >= @CreatedFromUtc AND SO.CreatedDate < @CreatedToUtc))
					AND (@UpdatedFromUtc IS NULL OR (SO.UpdatedDate >= @UpdatedFromUtc AND SO.UpdatedDate < @UpdatedToUtc))
			)
		),
		Filtered AS
		(
			SELECT *
			FROM Base
			WHERE
			    -- part-derived column filters
			    (
						    (@PartNumberType        IS NULL OR PartNumberType        LIKE '%' + @PartNumberType        + '%')
						AND (@PartDescriptionType   IS NULL OR PartDescriptionType   LIKE '%' + @PartDescriptionType   + '%')
						AND (@ManufacturerType      IS NULL OR ManufacturerType      LIKE '%' + @ManufacturerType      + '%')
						AND (@PriorityType          IS NULL OR PriorityType          LIKE '%' + @PriorityType          + '%')
						AND (@RequestedDateType     IS NULL OR RequestedDateType     LIKE '%' + @RequestedDateType     + '%')
						AND (@EstimatedShipDateType IS NULL OR EstimatedShipDateType LIKE '%' + @EstimatedShipDateType + '%')
						AND (@NumberOfItemCount     IS NULL OR CAST(NumberOfItemCount AS VARCHAR(20)) LIKE '%' + @NumberOfItemCount + '%')
				)
			    -- global "search everything" filter
			AND
			    (
					@GfMode <> 1
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
						OR OpenDate    LIKE @GF   -- [G] bare LIKE = original implicit style 0
						OR ShippedDate LIKE @GF   -- [G] bare LIKE = original implicit style 0
						OR CAST(NumberOfItemCount AS VARCHAR(20)) LIKE @GF
					)
				)
		),
		Ranked AS
		(
			SELECT
				Filtered.*,
				COUNT(*) OVER ()  AS NumberOfItems,     -- total row count, single pass
				ROW_NUMBER() OVER (ORDER BY
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERID')           THEN SalesOrderId          END DESC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CREATEDDATE')            THEN CreatedDateLocal      END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'VERSIONNUMBER')          THEN VersionNumber         END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'OPENDATE')               THEN OpenDate              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'QUOTEDATE')              THEN QuoteDate             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'STATUS')                 THEN [Status]              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESORDERNUMBER')       THEN SalesOrderNumber      END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CONTRACTREFERENCE')      THEN ContractReference     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PARTNUMBERTYPE')         THEN PartNumberType        END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'ManufacturerType')       THEN ManufacturerType      END ASC,  -- [H] preserved: never matches
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PARTDESCRIPTIONTYPE')    THEN PartDescriptionType   END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CUSTOMERNAME')           THEN CustomerName          END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CUSTOMERTYPE')           THEN CustomerType          END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CUSTOMERREFERENCE')      THEN CustomerReference     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'QUOTEAMOUNT')            THEN QuoteAmount           END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SOAMOUNT')               THEN SoAmount              END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'PRIORITYTYPE')           THEN PriorityType          END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'SALESPERSON')            THEN SalesPerson           END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'UPDATEDDATE')            THEN UpdatedDateLocal      END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'CREATEDBY')              THEN CreatedBy             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'MarketplaceRef')         THEN MarketplaceRef        END ASC,  -- [H] preserved: never matches
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'UPDATEDBY')              THEN UpdatedBy             END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'REQUESTEDDATETYPE')      THEN RequestedDateType     END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END ASC,
					CASE WHEN (@SortOrder =  1 AND @SortColumn = 'NUMBEROFITEMCOUNT')      THEN NumberOfItemCount     END ASC,

					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDDATE')            THEN CreatedDateLocal      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VERSIONNUMBER')          THEN VersionNumber         END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'OPENDATE')               THEN OpenDate              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUOTEDATE')              THEN QuoteDate             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'STATUS')                 THEN [Status]              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERNUMBER')       THEN SalesOrderNumber      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONTRACTREFERENCE')      THEN ContractReference     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTNUMBERTYPE')         THEN PartNumberType        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ManufacturerType')       THEN ManufacturerType      END DESC, -- [H] preserved
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTIONTYPE')    THEN PartDescriptionType   END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERNAME')           THEN CustomerName          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERTYPE')           THEN CustomerType          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERREFERENCE')      THEN CustomerReference     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUOTEAMOUNT')            THEN QuoteAmount           END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SOAMOUNT')               THEN SoAmount              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PRIORITYTYPE')           THEN PriorityType          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESPERSON')            THEN SalesPerson           END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDDATE')            THEN UpdatedDateLocal      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDBY')              THEN CreatedBy             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MarketplaceRef')         THEN MarketplaceRef        END DESC, -- [H] preserved
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDBY')              THEN UpdatedBy             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'REQUESTEDDATETYPE')      THEN RequestedDateType     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'NUMBEROFITEMCOUNT')      THEN NumberOfItemCount     END DESC,

					-- deterministic tie-breaker: guarantees stable paging
					SalesOrderId DESC
				) AS RowSeq
			FROM Filtered
		)
	
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
		-- 5. PHASE 2 - build the expensive values for the returned page only
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
			UPPER(AG.PriorityList)          AS Priority,
			UPPER(AG.PriorityType)          AS PriorityType,
			k.QuoteAmount,
			k.Cost,
			AG.RequestedDateList            AS RequestedDate,
			AG.RequestedDateType,
			AG.EstimatedShipDateList        AS EstimatedShipDate,
			AG.EstimatedShipDateType,
			AG.PromisedDateList             AS PromisedDate,
			k.ShippedDate,
			UPPER(AG.ManufacturerList)      AS Manufacturer,
			UPPER(AG.ManufacturerType)      AS ManufacturerType,
			UPPER(k.SalesPerson)            AS SalesPerson,
			UPPER(k.[Status])               AS [Status],
			k.StatusId,
			UPPER(AG.PartNumberList)        AS PartNumber,
			UPPER(AG.PartNumberType)        AS PartNumberType,
			UPPER(AG.PartDescriptionList)   AS PartDescription,
			UPPER(AG.PartDescriptionType)   AS PartDescriptionType,
			-- exact same value as before: UDF now runs on <= @PageSize rows only
			CAST(dbo.ConvertUTCtoLocal(k.CreatedDateUtc, @CurrntEmpTimeZoneDesc) AS DATE) AS CreatedDate,
			CAST(dbo.ConvertUTCtoLocal(k.UpdatedDateUtc, @CurrntEmpTimeZoneDesc) AS DATE) AS UpdatedDate,
			k.NumberOfItems,
			UPPER(k.CreatedBy)              AS CreatedBy,
			UPPER(k.UpdatedBy)              AS UpdatedBy,
			ISNULL(AG.AllParts, 0)          AS NumberOfItemCount,
			ISNULL(Z.SoAmount, 0)           AS SoAmount,
			k.MarketplaceRef
		FROM #Page k
		
		OUTER APPLY
		(
			SELECT
				RAW.AllParts,
				RAW.RequestedDateList,
				RAW.EstimatedShipDateList,
				RAW.PromisedDateList,
				RAW.PartNumberList,
				RAW.PartDescriptionList,
				RAW.PriorityList,
				RAW.ManufacturerList,
				CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.PartNumberList        END AS PartNumberType,
				CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.PartDescriptionList   END AS PartDescriptionType,
				CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.ManufacturerList      END AS ManufacturerType,
				CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.PriorityList          END AS PriorityType,
				CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.RequestedDateList     END AS RequestedDateType,
				CASE WHEN RAW.ActiveParts > 1 THEN 'Multiple' ELSE RAW.EstimatedShipDateList END AS EstimatedShipDateType
			FROM
			(
				SELECT
					(SELECT COUNT(SP.SalesOrderPartId)
					 FROM dbo.SalesOrderPartV1 SP WITH (NOLOCK)
					 WHERE SP.SalesOrderId = k.SalesOrderId)                     AS AllParts,
					(SELECT COUNT(SP.SalesOrderPartId)
					 FROM dbo.SalesOrderPartV1 SP WITH (NOLOCK)
					 WHERE SP.SalesOrderId = k.SalesOrderId
					   AND SP.IsActive = 1 AND SP.IsDeleted = 0)                  AS ActiveParts,
					STUFF((SELECT ',' + CONVERT(VARCHAR, S.CustomerRequestDate, 101)
					       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
					       WHERE S.SalesOrderId = k.SalesOrderId
					         AND S.IsActive = 1 AND S.IsDeleted = 0
					       FOR XML PATH('')), 1, 1, '')                           AS RequestedDateList,
					STUFF((SELECT ',' + CONVERT(VARCHAR, S.EstimatedShipDate, 101)
					       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
					       WHERE S.SalesOrderId = k.SalesOrderId
					         AND S.IsActive = 1 AND S.IsDeleted = 0
					       FOR XML PATH('')), 1, 1, '')                           AS EstimatedShipDateList,
					STUFF((SELECT ',' + CONVERT(VARCHAR, S.PromisedDate, 101)
					       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
					       WHERE S.SalesOrderId = k.SalesOrderId
					         AND S.IsActive = 1 AND S.IsDeleted = 0
					       FOR XML PATH('')), 1, 1, '')                           AS PromisedDateList,
					STUFF((SELECT ',' + I.PartNumber
					       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
					       LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
					       WHERE S.SalesOrderId = k.SalesOrderId
					         AND S.IsActive = 1 AND S.IsDeleted = 0
					       FOR XML PATH('')), 1, 1, '')                           AS PartNumberList,
					STUFF((SELECT ', ' + I.PartDescription
					       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
					       LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
					       WHERE S.SalesOrderId = k.SalesOrderId
					         AND S.IsActive = 1 AND S.IsDeleted = 0
					       FOR XML PATH('')), 1, 1, '')                           AS PartDescriptionList,
					STUFF((SELECT ', ' + P.[Description]
					       FROM dbo.SalesOrderPartV1 S WITH (NOLOCK)
					       LEFT JOIN dbo.[Priority] P WITH (NOLOCK) ON P.PriorityId = S.PriorityId
					       WHERE S.SalesOrderId = k.SalesOrderId
					         AND S.IsActive = 1 AND S.IsDeleted = 0
					       FOR XML PATH('')), 1, 1, '')                           AS PriorityList,
					STUFF((SELECT ',' + MA.[Name]
					       FROM dbo.SalesOrder S WITH (NOLOCK)
					       LEFT JOIN dbo.SalesOrderPartV1 SP WITH (NOLOCK) ON S.SalesOrderId   = SP.SalesOrderId
					       LEFT JOIN dbo.ItemMaster       IM WITH (NOLOCK) ON IM.ItemMasterId   = SP.ItemMasterId
					       LEFT JOIN dbo.Manufacturer     MA WITH (NOLOCK) ON MA.ManufacturerId = IM.ManufacturerId
					       WHERE S.SalesOrderId = k.SalesOrderId
					         AND S.IsActive = 1 AND S.IsDeleted = 0
					       FOR XML PATH('')), 1, 1, '')                           AS ManufacturerList
			) RAW
		) AG
		
		OUTER APPLY
		(
			SELECT SUM(X.NetSales) AS SoAmount
			FROM
			(
				SELECT
					(
						CASE
							WHEN ISNULL(SOP.QtyRequested, 0) =
							     ISNULL(SUM(CASE WHEN stk.SalesOrderStocklineId IS NOT NULL
							                     THEN stk.QtyOrder
							                     ELSE SOP.QtyOrder
							                END), 0)
							THEN 0
							ELSE
							(
								(
									ISNULL(SUM(
										CASE WHEN stk.SalesOrderStocklineId IS NOT NULL
										     THEN stk.QtyOrder
										     ELSE CASE WHEN ISNULL(SOP.QtyOrder, 0) > 0
										               THEN ISNULL(SOP.QtyOrder, 0)
										               ELSE ISNULL(SOP.QtyRequested, 0)
										          END
										END), 0) * -1
									+ ISNULL(SOP.QtyRequested, 0)
								) * ISNULL(SOP.UnitSalesPrice, 0)
							)
						END
					)
					+
					ISNULL(SUM(
						CASE WHEN SC.SalesOrderStocklineId IS NOT NULL
						     THEN ISNULL(SC.NetSaleAmount,    0)
						     ELSE ISNULL(SOQPS.NetSaleAmount, 0)
						END), 0)                                    AS NetSales
				FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK)
				INNER JOIN dbo.SalesOrderPartCost SOQPS WITH (NOLOCK)
					ON  SOQPS.SalesOrderId     = SOP.SalesOrderId
					AND SOQPS.SalesOrderPartId = SOP.SalesOrderPartId
				LEFT JOIN dbo.SalesOrderStocklineV1 stk WITH (NOLOCK)
					ON stk.SalesOrderPartId = SOP.SalesOrderPartId
				LEFT JOIN dbo.SalesOrderStockLineCost SC WITH (NOLOCK)
					ON  SC.SalesOrderStocklineId = stk.SalesOrderStocklineId
					AND SC.SalesOrderId          = SOP.SalesOrderId
				WHERE SOP.SalesOrderId = k.SalesOrderId
				GROUP BY SOP.SalesOrderPartId, SOP.QtyRequested, SOP.UnitSalesPrice
			) X
		) Z
		

		ORDER BY k.RowSeq;                                  -- deterministic grid order

		IF OBJECT_ID(N'tempdb..#Page') IS NOT NULL DROP TABLE #Page;

	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'ROLLBACK';
			ROLLBACK TRANSACTION;          -- was outside the IF in the original
		END

		
		DECLARE @ErrNum  INT            = ERROR_NUMBER(),
		        @ErrLine INT            = ERROR_LINE(),
		        @ErrProc SYSNAME        = ISNULL(ERROR_PROCEDURE(), '<adhoc>'),
		        @ErrMsg  NVARCHAR(2048) = ERROR_MESSAGE();

		PRINT '*** SearchSOViewData failed ***';
		PRINT 'Error ' + CONVERT(VARCHAR(20), @ErrNum)
		    + ' at line ' + CONVERT(VARCHAR(20), @ErrLine)
		    + ' in ' + @ErrProc + ': ' + @ErrMsg;

		DECLARE @ErrorLogID          INT,
		        @DatabaseName        VARCHAR(100)  = DB_NAME(),
		        @AdhocComments       VARCHAR(150)  = 'SearchSOViewData',
		        @ProcedureParameters VARCHAR(3000) =
		              '@PageNumber = ''' + ISNULL(CONVERT(VARCHAR(20), @PageNumber), '') + ''''
		            + ' | @PageSize = ' + ISNULL(CONVERT(VARCHAR(20), @PageSize), 'NULL')
		            + ' | @SortColumn = ' + ISNULL(@SortColumn, 'NULL')
		            + ' | @SortOrder = ' + ISNULL(CONVERT(VARCHAR(20), @SortOrder), 'NULL')
		            + ' | @MasterCompanyId = ' + ISNULL(CONVERT(VARCHAR(20), @MasterCompanyId), 'NULL')
		            + ' | @EmployeeId = ' + ISNULL(CONVERT(VARCHAR(20), @EmployeeId), 'NULL')
		            + ' || SQL ERROR ' + CONVERT(VARCHAR(20), @ErrNum)
		            + ' line ' + CONVERT(VARCHAR(20), @ErrLine) + ': '
		            + CONVERT(VARCHAR(1800), @ErrMsg),
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