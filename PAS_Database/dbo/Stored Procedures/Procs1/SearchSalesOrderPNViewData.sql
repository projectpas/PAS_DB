/*************************************************************           
 ** File:   [SearchSalesOrderPNViewData]
 ** Author:  
 ** Description: This stored procedure is used display sales order list
 ** Purpose:         
 ** Date:        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    04/08/2023		Ekta Chandegara		Convert text into uppercase
	2    06/26/2024		AMIT GHEDIYA		Added orderby for RequestedDate,EstimatedShipDate
	3    20-09-2024		Shrey Chandegara	ADD New Column in list (@ContractReference)
	4	 22-01-2025		Ayushi Patel		converted the date into utc (created , updated) , Added a case to get timeZone
	5	 10-04-2025		Vishal Suthar		Applied Optimization, Standard Formatting and Cleanup
	6    27-06-2025		Bhargav Saliya		Add New Fields @NumberOfItemCount 
	7    19-11-2025		RAJESH GAMI			Added SO Amount
	10   20-11-2025		Rajesh Gami			Correct the SO Amount
	11   19/JUN/2026	AMIT GHEDIYA		Get [MarketplaceRef] data [PN-16922]
    12   29/JUL/2026	Kishor Makwana      PERFORMANCE ONLY - Sales Order List filter slowness.
	13	 05/August/2026	Divyesh Kathiriya	[PN-17555] - Fix filter to the search query.

***************************************************************************************/
CREATE PROCEDURE [dbo].[SearchSalesOrderPNViewData]
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

	BEGIN TRY

		---------------------------------------------------------------------------
		-- 1. Context / employee timezone.		
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
		-- 2. Parameter normalisation.		
		---------------------------------------------------------------------------
		DECLARE @RecordFrom INT;

		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		IF @RecordFrom IS NULL OR @RecordFrom < 0 SET @RecordFrom = 0;
		SET @PageSize = ISNULL(NULLIF(@PageSize, 0), 20);

		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted = 0
		END

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('CreatedDate')
		END
		ELSE
		BEGIN
			SET @SortColumn = UPPER(@SortColumn)
		END

		IF @StatusID = 0
		BEGIN
			SET @StatusID = NULL
		END

		IF @Status = '0'
		BEGIN
			SET @Status = NULL
		END

		IF @SoAmount = 0
		BEGIN
			SET @SoAmount = NULL
		END

		DECLARE @GfMode TINYINT =
			CASE WHEN @GlobalFilter IS NULL THEN 2
			     WHEN @GlobalFilter <> ''   THEN 1
			     ELSE 0 END;
		DECLARE @GF VARCHAR(102) = '%' + @GlobalFilter + '%';

		SET @SOQNumber             = NULLIF(@SOQNumber,             '');
		SET @SalesOrderNumber      = NULLIF(@SalesOrderNumber,      '');
		SET @CustomerName          = NULLIF(@CustomerName,          '');
		SET @Status                = NULLIF(@Status,                '');
		SET @SalesPerson           = NULLIF(@SalesPerson,           '');
		SET @PriorityType          = NULLIF(@PriorityType,          '');
		SET @RequestedDateType     = NULLIF(@RequestedDateType,     '');
		SET @EstimatedShipDateType = NULLIF(@EstimatedShipDateType, '');
		SET @PartNumberType        = NULLIF(@PartNumberType,        '');
		SET @PartDescriptionType   = NULLIF(@PartDescriptionType,   '');
		SET @CustomerReference     = NULLIF(@CustomerReference,     '');
		SET @VersionNumber         = NULLIF(@VersionNumber,         '');
		SET @CreatedBy             = NULLIF(@CreatedBy,             '');
		SET @UpdatedBy             = NULLIF(@UpdatedBy,             '');
		SET @ManufacturerType      = NULLIF(@ManufacturerType,      '');
		SET @ContractReference     = NULLIF(@ContractReference,     '');
		SET @NumberOfItemCount     = NULLIF(@NumberOfItemCount,     '');
		SET @MarketplaceRef        = NULLIF(@MarketplaceRef,        '');

		---------------------------------------------------------------------------
		-- 3. Timezone offset and SARGable date windows, computed ONCE.
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
		        @ShipIsMinDate  BIT = 0;

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

		/* The original compares CAST(ISNULL(SO.ShippedDate,'0001-01-01') AS DATE),
		   so filtering on 0001-01-01 must still match rows where ShippedDate IS
		   NULL. @ShipIsMinDate carries that case.                                */
		IF ISNULL(@ShippedDate, '') <> ''
		BEGIN
			SET @ShipFrom      = CAST(CAST(@ShippedDate AS DATE) AS DATETIME2(3));
			SET @ShipTo        = DATEADD(DAY, 1, @ShipFrom);
			SET @ShipIsMinDate = CASE WHEN CAST(@ShippedDate AS DATE) = '0001-01-01' THEN 1 ELSE 0 END;
		END

		IF OBJECT_ID(N'tempdb..#tmpSOPartTblData') IS NOT NULL DROP TABLE #tmpSOPartTblData;

		---------------------------------------------------------------------------
		-- 4. Filter -> group -> rank -> page, in a single pass.
		---------------------------------------------------------------------------
		;WITH Result AS
		(
			SELECT
				SO.SalesOrderId,
				SO.SalesOrderNumber,
				SOQ.SalesOrderQuoteNumber,
				SO.OpenDate                                     AS OpenDate,
				SO.ContractReference                            AS ContractReference,
				SOQ.OpenDate                                    AS QuoteDate,
				SO.CustomerId,
				SO.CustomerName                                 AS CustomerName,
				MST.[Name]                                      AS [Status],
				ISNULL(SPC.NetSaleAmount, 0)                    AS QuoteAmount,
				ISNULL(SPC.UnitCost, 0)                         AS UnitCost,
				ISNULL(SP.CustomerRequestDate, '0001-01-01')    AS RequestedDate,
				ISNULL(SP.CustomerRequestDate, '0001-01-01')    AS RequestedDateType,
				SO.StatusId,
				SO.CustomerReference,
				ISNULL(SP.PriorityName, '')                     AS Priority,
				ISNULL(SP.PriorityName, '')                     AS PriorityType,
				(E.FirstName + ' ' + E.LastName)                AS SalesPerson,
				ISNULL(IM.PartNumber, '')                       AS PartNumber,
				M.[Name]                                        AS ManufacturerType,
				ISNULL(IM.PartNumber, '')                       AS PartNumberType,
				ISNULL(IM.PartDescription, '')                  AS PartDescription,
				ISNULL(IM.PartDescription, '')                  AS PartDescriptionType,
				/* raw UTC values are carried through so the UDF can be applied to
				   the returned page only; the *Local columns are the day-precision
				   values the original sorted and filtered on.                     */
				SO.CreatedDate                                  AS CreatedDateUtc,
				SO.UpdatedDate                                  AS UpdatedDateUtc,
				CAST(DATEADD(MINUTE, @TzOffsetMin, SO.CreatedDate) AS DATE) AS CreatedDateLocal,
				CAST(DATEADD(MINUTE, @TzOffsetMin, SO.UpdatedDate) AS DATE) AS UpdatedDateLocal,
				SO.UpdatedBy,
				SO.CreatedBy,
				ISNULL(SP.EstimatedShipDate, '0001-01-01')      AS EstimatedShipDate,
				ISNULL(SP.EstimatedShipDate, '0001-01-01')      AS EstimatedShipDateType,
				ISNULL(SP.PromisedDate, '0001-01-01')           AS PromisedDate,
				ISNULL(SO.ShippedDate, '0001-01-01')            AS ShippedDate,
				SO.IsDeleted,
				SOQ.VersionNumber,
				
				CASE WHEN SP.SalesOrderPartId IS NULL
				     THEN 0
				     ELSE ISNULL(MSDC.Cnt, 0) * ISNULL(ROLEC.Cnt, 0)
				END                                             AS NumberOfItemCount,
				ISNULL(SPC.NetSaleAmount, 0)                    AS soAmount,
				SP.SalesOrderPartId,
				SP.QtyRequested,
				SP.QtyOrder,
				SP.UnitSalesPrice                               AS MainUnitSalesPrice,
				SO.MarketplaceRef
			FROM dbo.SalesOrder SO WITH (NOLOCK)
			INNER JOIN dbo.MasterSalesOrderQuoteStatus MST WITH (NOLOCK)
				ON SO.StatusId = MST.Id
			LEFT JOIN dbo.SalesOrderPartV1 SP WITH (NOLOCK)
				ON SO.SalesOrderId = SP.SalesOrderId AND SP.IsDeleted = 0
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

			/* the two fan-out factors the original COUNT() was really measuring */
			OUTER APPLY
			(
				SELECT COUNT(*) AS Cnt
				FROM dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
				WHERE MSD.ModuleID    = @MSModuleID
				  AND MSD.ReferenceID = SO.SalesOrderId
			) MSDC
			OUTER APPLY
			(
				SELECT COUNT(*) AS Cnt
				FROM dbo.RoleManagementStructure RMS WITH (NOLOCK)
				INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK)
					ON EUR.RoleId = RMS.RoleId
				WHERE RMS.EntityStructureId = SO.ManagementStructureId
				  AND EUR.EmployeeId        = @EmployeeId
			) ROLEC

			WHERE @GfMode <> 2

			    -- ---- unchanged, always applied ---------------------------------
			AND (SO.IsDeleted = @IsDeleted)
			AND (@StatusID IS NULL OR SO.StatusId = @StatusID)
			AND SO.MasterCompanyId = @MasterCompanyId

			    -- ---- was INNER JOIN, now semi-join: same rows, no fan-out ------
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
			   
			AND
			(
					    (@SOQNumber            IS NULL OR SOQ.SalesOrderQuoteNumber LIKE '%' + @SOQNumber            + '%')
					AND (@SoAmount             IS NULL OR ISNULL(SPC.NetSaleAmount, 0) = @SoAmount)
					AND (@SalesOrderNumber     IS NULL OR SO.SalesOrderNumber       LIKE '%' + @SalesOrderNumber     + '%')
					AND (@ContractReference    IS NULL OR SO.ContractReference      LIKE '%' + @ContractReference    + '%')
					AND (@CustomerName         IS NULL OR SO.CustomerName           LIKE '%' + @CustomerName         + '%')
					AND (@CustomerReference    IS NULL OR SO.CustomerReference      LIKE '%' + @CustomerReference    + '%')
					AND (@PriorityType         IS NULL OR ISNULL(SP.PriorityName, '') LIKE '%' + @PriorityType       + '%')
					AND (@ManufacturerType     IS NULL OR M.[Name]                  LIKE '%' + @ManufacturerType     + '%')
					AND (@VersionNumber        IS NULL OR SOQ.VersionNumber         LIKE '%' + @VersionNumber        + '%')
					AND (@SalesPerson          IS NULL OR (E.FirstName + ' ' + E.LastName) LIKE '%' + @SalesPerson    + '%')
					AND (@PartNumberType       IS NULL OR ISNULL(IM.PartNumber, '') LIKE '%' + @PartNumberType       + '%')
					AND (@PartDescriptionType  IS NULL OR ISNULL(IM.PartDescription, '') LIKE '%' + @PartDescriptionType + '%')
					AND (@CreatedBy            IS NULL OR SO.CreatedBy              LIKE '%' + @CreatedBy            + '%')
					AND (@UpdatedBy            IS NULL OR SO.UpdatedBy              LIKE '%' + @UpdatedBy            + '%')
					AND (@MarketplaceRef       IS NULL OR SO.MarketplaceRef         LIKE '%' + @MarketplaceRef       + '%')
					AND (@Status               IS NULL OR MST.[Name]                LIKE '%' + @Status               + '%')
					AND (@RequestedDateType    IS NULL OR ISNULL(SP.CustomerRequestDate, '0001-01-01') LIKE '%' + @RequestedDateType    + '%')
					AND (@EstimatedShipDateType IS NULL OR ISNULL(SP.EstimatedShipDate, '0001-01-01') LIKE '%' + @EstimatedShipDateType + '%')

					-- SARGable equivalents of CAST(col AS DATE) = CAST(@p AS DATE)
					AND (@OpenFrom       IS NULL OR (SO.OpenDate    >= @OpenFrom       AND SO.OpenDate    < @OpenTo))
					AND (@QuoteFrom      IS NULL OR (SOQ.OpenDate   >= @QuoteFrom      AND SOQ.OpenDate   < @QuoteTo))
					AND (@CreatedFromUtc IS NULL OR (SO.CreatedDate >= @CreatedFromUtc AND SO.CreatedDate < @CreatedToUtc))
					AND (@UpdatedFromUtc IS NULL OR (SO.UpdatedDate >= @UpdatedFromUtc AND SO.UpdatedDate < @UpdatedToUtc))
					AND (@ShipFrom       IS NULL
					     OR (SO.ShippedDate >= @ShipFrom AND SO.ShippedDate < @ShipTo)
					     OR (@ShipIsMinDate = 1 AND SO.ShippedDate IS NULL))
					
					AND (@NumberOfItemCount IS NULL
					     OR CAST(CASE WHEN SP.SalesOrderPartId IS NULL THEN 0
					                  ELSE ISNULL(MSDC.Cnt,0) * ISNULL(ROLEC.Cnt,0) END AS VARCHAR(20))
					        LIKE '%' + @Status + '%')
			)
			 
			AND
			(
				@GfMode <> 1
				OR
				(
					   SOQ.SalesOrderQuoteNumber LIKE @GF
					OR SO.SalesOrderNumber       LIKE @GF
					OR SO.OpenDate               LIKE @GF
					OR SO.ContractReference      LIKE @GF
					OR SO.CustomerName           LIKE @GF
					OR (E.FirstName + ' ' + E.LastName) LIKE @GF
					OR @VersionNumber            LIKE @GF        -- [B] preserved as written
					OR SO.CustomerReference      LIKE @GF
					OR ISNULL(SP.PriorityName, '')               LIKE @GF
					OR ISNULL(SP.CustomerRequestDate, '0001-01-01') LIKE @GF
					OR SOQ.OpenDate              LIKE @GF
					OR ISNULL(SP.EstimatedShipDate, '0001-01-01')   LIKE @GF
					OR ISNULL(SO.ShippedDate, '0001-01-01')         LIKE @GF
					OR ISNULL(SP.PromisedDate, '0001-01-01')        LIKE @GF
					OR ISNULL(IM.PartNumber, '')      LIKE @GF
					OR M.[Name]                       LIKE @GF
					OR ISNULL(IM.PartDescription, '') LIKE @GF
					OR CAST(DATEADD(MINUTE, @TzOffsetMin, SO.CreatedDate) AS DATE) LIKE @GF
					OR CAST(DATEADD(MINUTE, @TzOffsetMin, SO.UpdatedDate) AS DATE) LIKE @GF
					OR MST.[Name]                     LIKE @GF
					OR CAST(CASE WHEN SP.SalesOrderPartId IS NULL THEN 0
					             ELSE ISNULL(MSDC.Cnt,0) * ISNULL(ROLEC.Cnt,0) END AS VARCHAR(20)) LIKE @GF
				)
			)
			
			GROUP BY SO.SalesOrderId, SO.SalesOrderNumber, SOQ.SalesOrderQuoteNumber, SO.OpenDate, SO.ContractReference, SOQ.OpenDate, SO.CustomerId, SO.CustomerName,
			         MST.[Name], SPC.NetSaleAmount, SPC.UnitCost, SP.CustomerRequestDate, SO.StatusId, SO.CustomerReference,
			         SP.PriorityName, E.FirstName, E.LastName, IM.PartNumber, M.[Name], IM.PartDescription, SOQ.VersionNumber,
			         SO.CreatedDate, SO.UpdatedDate, SO.UpdatedBy, SO.CreatedBy, SP.EstimatedShipDate, SP.PromisedDate, SO.ShippedDate, SO.IsDeleted,
			         SO.[Version], SP.QtyRequested, SP.QtyOrder, SP.UnitSalesPrice, SP.SalesOrderPartId, SO.MarketplaceRef,
			         MSDC.Cnt, ROLEC.Cnt
		),
		Ranked AS
		(
			SELECT
				Result.*,
				COUNT(*) OVER ()  AS NumberOfItems,   -- replaces (SELECT COUNT(*) FROM FinalResult)
				ROW_NUMBER() OVER (ORDER BY
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'SALESORDERID')           THEN SalesOrderId          END DESC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'SALESORDERNUMBER')       THEN SalesOrderNumber      END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CONTRACTREFERENCE')      THEN ContractReference     END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'VERSIONNUMBER')          THEN VersionNumber         END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'QUOTEDATE')              THEN QuoteDate             END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'STATUS')                 THEN [Status]              END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTNUMBERTYPE')         THEN PartNumberType        END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTDESCRIPTIONTYPE')    THEN PartDescriptionType   END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CUSTOMERNAME')           THEN CustomerName          END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CUSTOMERREFERENCE')      THEN CustomerReference     END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PRIORITYTYPE')           THEN PriorityType          END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'OPENDATE')               THEN OpenDate              END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'REQUESTEDDATE')          THEN RequestedDate         END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ESTIMATEDSHIPDATE')      THEN EstimatedShipDate     END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'SALESPERSON')            THEN SalesPerson           END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CREATEDDATE')            THEN CreatedDateLocal      END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UPDATEDDATE')            THEN UpdatedDateLocal      END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'MarketplaceRef')         THEN MarketplaceRef        END ASC,  -- [H] preserved: never matches
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CREATEDBY')              THEN CreatedBy             END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UPDATEDBY')              THEN UpdatedBy             END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'REQUESTEDDATETYPE')      THEN RequestedDateType     END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END ASC,
					CASE WHEN (@SortOrder = 1 AND @SortColumn = 'NUMBEROFITEMCOUNT')      THEN NumberOfItemCount     END ASC,

					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERID')          THEN SalesOrderId          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERNUMBER')      THEN SalesOrderNumber      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONTRACTREFERENCE')     THEN ContractReference     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESORDERQUOTENUMBER') THEN SalesOrderQuoteNumber END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VERSIONNUMBER')         THEN VersionNumber         END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUOTEDATE')             THEN QuoteDate             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'STATUS')                THEN [Status]              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTNUMBERTYPE')        THEN PartNumberType        END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTIONTYPE')   THEN PartDescriptionType   END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERNAME')          THEN CustomerName          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CUSTOMERREFERENCE')     THEN CustomerReference     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PRIORITYTYPE')          THEN PriorityType          END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'OPENDATE')              THEN OpenDate              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'REQUESTEDDATE')         THEN RequestedDate         END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ESTIMATEDSHIPDATE')     THEN EstimatedShipDate     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SALESPERSON')           THEN SalesPerson           END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDDATE')           THEN CreatedDateLocal      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDDATE')           THEN UpdatedDateLocal      END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDBY')             THEN CreatedBy             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MarketplaceRef')        THEN MarketplaceRef        END DESC,  -- [H] preserved
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDBY')             THEN UpdatedBy             END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'REQUESTEDDATETYPE')     THEN RequestedDateType     END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ESTIMATEDSHIPDATETYPE') THEN EstimatedShipDateType END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'SOAMOUNT')              THEN soAmount              END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'SOAMOUNT')              THEN soAmount              END DESC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'NUMBEROFITEMCOUNT')     THEN NumberOfItemCount     END DESC,

					
					SalesOrderId DESC, SalesOrderPartId ASC
				) AS RowSeq
			FROM Result
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
			UPPER(PriorityType)             AS PriorityType,
			QuoteAmount,
			UnitCost,
			RequestedDate,
			RequestedDateType,
			QuoteDate,
			EstimatedShipDate,
			EstimatedShipDateType,
			PromisedDate,
			ShippedDate,
			UPPER(SalesPerson)              AS SalesPerson,
			UPPER([Status])                 AS [Status],
			StatusId,
			UPPER(PartNumber)               AS PartNumber,
			UPPER(ManufacturerType)         AS ManufacturerType,
			UPPER(PartNumberType)           AS PartNumberType,
			UPPER(PartDescription)          AS PartDescription,
			UPPER(PartDescriptionType)      AS PartDescriptionType,
			-- identical values to the original: the UDF now sees <= @PageSize rows
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
		-- 5. Part-wise cost (SO Amount). Logic verbatim from the original; it now
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
			ISNULL(tp.TotalPartCost, 0)     AS soAmount,   -- replaces the UPDATE pass
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
		ORDER BY main.RowSeq;

		IF OBJECT_ID(N'tempdb..#tmpSOPartTblData') IS NOT NULL DROP TABLE #tmpSOPartTblData;

	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0
		BEGIN
			PRINT 'ROLLBACK';
			ROLLBACK TRANSACTION;          -- was outside the IF in the original
		END

		/* Capture the REAL error first. The original handler discarded it, which is
		   why the application only ever showed a bare System.Exception.          */
		DECLARE @ErrNum  INT            = ERROR_NUMBER(),
		        @ErrLine INT            = ERROR_LINE(),
		        @ErrProc SYSNAME        = ISNULL(ERROR_PROCEDURE(), '<adhoc>'),
		        @ErrMsg  NVARCHAR(2048) = ERROR_MESSAGE();

		PRINT '*** SearchSalesOrderPNViewData failed ***';
		PRINT 'Error ' + CONVERT(VARCHAR(20), @ErrNum)
		    + ' at line ' + CONVERT(VARCHAR(20), @ErrLine)
		    + ' in ' + @ErrProc + ': ' + @ErrMsg;

		DECLARE @ErrorLogID          INT,
		        @DatabaseName        VARCHAR(100)  = DB_NAME(),
		        @AdhocComments       VARCHAR(150)  = 'SearchSalesOrderPNViewData',
		        @ProcedureParameters VARCHAR(3000) =
		              '@PageNumber = ''' + ISNULL(CONVERT(VARCHAR(20), @PageNumber), '') + ''''
		            + ' | @PageSize = '        + ISNULL(CONVERT(VARCHAR(20), @PageSize), 'NULL')
		            + ' | @SortColumn = '      + ISNULL(@SortColumn, 'NULL')
		            + ' | @SortOrder = '       + ISNULL(CONVERT(VARCHAR(20), @SortOrder), 'NULL')
		            + ' | @MasterCompanyId = ' + ISNULL(CONVERT(VARCHAR(20), @MasterCompanyId), 'NULL')
		            + ' | @EmployeeId = '      + ISNULL(CONVERT(VARCHAR(20), @EmployeeId), 'NULL')
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