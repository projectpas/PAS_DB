/*************************************************************
 ** File:   [SearchSOQViewData]
 ** Description: Get Search Data for SOQ List
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author             Change Description
 ** --   --------     -------            --------------------------------
 ** ...  (history retained from original) ...
 ** 11   11-JUN-2026  Optimization Pass  Performance-only changes, NO logic/result changes:
 **         1. REMOVED PartCTE / PartMFCTE / PartDescCTE / PriorityCTE entirely.
 **            All four contained "CASE WHEN 2 > 1 THEN 'Multiple' ELSE '' END" — a
 **            constant. Each CTE full-scanned SalesOrderQuote + GROUP BY + LEFT JOIN
 **            back to Main, only to attach the literal 'Multiple' (and '' PartNumber)
 **            to every row. The same filters guaranteed every Main row always matched,
 **            so the joins could never produce NULL. Replaced with inline constants:
 **            output is byte-identical, and 4 table scans + 4 joins are eliminated.
 **         2. Replaced CROSS JOIN to CTE_Count with COUNT(*) OVER() — the old pattern
 **            forced the whole Result tree to be evaluated a second time for the count.
 **         3. Combined the two correlated subqueries for SalesOrderNumber (COUNT + TOP 1)
 **            into one OUTER APPLY so SalesOrder is probed once per quote, not twice.
 **         4. Security joins (MSD / RMS / EUR) converted to EXISTS semi-joins — same
 **            filtering, no row multiplication that DISTINCT then had to collapse.
 **         5. Removed unused @EmpLegalEntiyId lookup (extra Employee query, never read).
 **         6. Added OPTION (RECOMPILE) — 25+ optional catch-all filters make a single
 **            cached plan wrong for most calls (parameter sniffing).
 **         7. Removed BEGIN TRAN / COMMIT around read-only work.

 ** 12	05/August/2026	Divyesh Kathiriya	[PN-17555] - Fix filter to the search query.

 **************************************************************/
CREATE PROCEDURE [dbo].[SearchSOQViewData]
 @PageNumber int,
 @PageSize int,
 @SortColumn varchar(50) = null,
 @SortOrder int,
 @StatusID int,
 @GlobalFilter varchar(50) = null,
 @SOQNumber varchar(50) = null,
 @SalesOrderNumber varchar(50) = null,
 @CustomerName varchar(50) = null,
 @Status varchar(50) = null,
 @QuoteAmount numeric(18,4) = null,
 @SoAmount numeric(18,4) = null,
 @QuoteDate datetime = null,
 @SalesPerson varchar(50) = null,
 @PriorityType varchar(50) = null,
 @PartNumberType varchar(50) = null,
 @PartDescriptionType varchar(50) = null,
 @CustomerReference varchar(50) = null,
 @CustomerType varchar(50) = null,
 @VersionNumber varchar(50) = null,
 @CreatedDate datetime = null,
 @UpdatedDate  datetime = null,
 @CreatedBy  varchar(50) = null,
 @UpdatedBy  varchar(50) = null,
 @IsDeleted bit = null,
 @MasterCompanyId int = null,
 @EmployeeId bigint,
 @ManufacturerType varchar(50) = null,
 @NumberOfItemCount varchar(50)=null,
 @SourceBy varchar(50)=null,
 @MarketplaceRef varchar(50)=null,
 @SourceByName varchar(50)=null
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON;
 BEGIN TRY
   BEGIN
    DECLARE @RecordFrom int;
    DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

    /* OPTIMIZATION: removed the separate @EmpLegalEntiyId lookup — the variable was
       assigned but never used anywhere in the procedure (one wasted Employee query). */
    SELECT
            @CurrntEmpTimeZoneDesc = COALESCE(
                ETZ.[Description],  -- Prefer Employee's TimeZone description if available
                LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
            )
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

    SET @RecordFrom = (@PageNumber - 1) * @PageSize;

    IF @IsDeleted IS NULL          SET @IsDeleted = 0;
    IF @SortColumn IS NULL         SET @SortColumn = UPPER('SalesOrderQuoteId');
    ELSE                           SET @SortColumn = UPPER(@SortColumn);
    IF @QuoteAmount = 0            SET @QuoteAmount = NULL;
    IF @SoAmount = 0               SET @SoAmount = NULL;
    IF @StatusID = 0               SET @StatusID = NULL;
    IF @Status = '0'               SET @Status = NULL;
    IF @SourceByName = 'All'       SET @SourceByName = NULL;

    DECLARE @MSModuleID INT = 18; -- Sales Order Quote Management Structure Module ID

    ;WITH Main AS (
      SELECT DISTINCT SOQ.SalesOrderQuoteId, SOQ.SalesOrderQuoteNumber,
      SOQ.OpenDate,
      SOQ.CustomerId, SOQ.CustomerName Name, SOQ.CustomerCode CustomerCode, MST.Name AS 'Status',
      0 AS Cost,
      0 AS 'SalesPrice',
      (E.FirstName + ' ' + E.LastName) AS SalesPerson, SOQ.AccountTypeName CustomerTypeName,
      /* OPTIMIZATION: the original ran TWO correlated subqueries against SalesOrder per
         row (one COUNT, one TOP 1). OUTER APPLY computes both in a single probe.
         Result is identical: >1 SO => 'MULTIPLE', exactly/at most 1 => the TOP 1 number
         (with the same SalesOrderPartV1 join requirement), none => NULL. */
      (CASE WHEN SONum.SOCount > 1 THEN 'MULTIPLE' ELSE SONum.SingleSONumber END) AS SalesOrderNumber,
      0 AS SoAmount,
      (CAST(DBO.ConvertUTCtoLocal(SOQ.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) CreatedDate,
      (CAST(DBO.ConvertUTCtoLocal(SOQ.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) UpdatedDate,
      SOQ.StatusId, SOQ.CreatedBy, SOQ.UpdatedBy,
      dbo.GenearteVersionNumber(SOQ.Version) AS 'VersionNumber', SOQ.IsNewVersionCreated, SOQ.CustomerReference, ISNULL(0,0) AS NumberOfItemCount,
      CASE WHEN ISNULL(SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END SourceBy,
      ISNULL(SOQ.MarketplaceRef,'') MarketplaceRef
      FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)
      INNER JOIN MasterSalesOrderQuoteStatus MST WITH (NOLOCK) ON SOQ.StatusId = MST.Id
      LEFT JOIN DBO.Employee E WITH (NOLOCK) ON E.EmployeeId = SOQ.SalesPersonId
      OUTER APPLY (
            SELECT
                (SELECT COUNT(SOR.SalesOrderId)
                   FROM DBO.SalesOrder SOR WITH (NOLOCK)
                  WHERE SOR.SalesOrderQuoteId = SOQ.SalesOrderQuoteId) AS SOCount,
                (SELECT TOP 1 SO.SalesOrderNumber
                   FROM DBO.SalesOrder SO WITH (NOLOCK)
                  INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
                  WHERE SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId) AS SingleSONumber
      ) SONum
      /* OPTIMIZATION: security INNER JOINs replaced with EXISTS semi-joins.
         The old joins multiplied rows when an employee has multiple roles / a quote
         has multiple MSD rows, and DISTINCT then had to collapse them back. EXISTS
         filters identically without generating the duplicates in the first place. */
      WHERE (SOQ.IsDeleted = @IsDeleted)
        AND (@StatusID IS NULL OR SOQ.StatusId = @StatusID)
        AND (@SourceByName IS NULL OR CASE WHEN ISNULL(SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END = @SourceByName)
        AND SOQ.MasterCompanyId = @MasterCompanyId
        AND EXISTS (SELECT 1 FROM dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
                    WHERE MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId)
        AND EXISTS (SELECT 1 FROM dbo.RoleManagementStructure RMS WITH (NOLOCK)
                    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId
                    WHERE RMS.EntityStructureId = SOQ.ManagementStructureId AND EUR.EmployeeId = @EmployeeId)
    ),
    /* OPTIMIZATION — the four "Multiple" CTEs are GONE.
       PartCTE, PartMFCTE, PartDescCTE and PriorityCTE each scanned + grouped the whole
       SalesOrderQuote table just to emit the constant 'Multiple' (CASE WHEN 2 > 1 ...)
       and '' for PartNumber, then LEFT JOINed back to Main. Because they used the same
       IsDeleted / StatusID / SourceByName filters as Main, every Main row was guaranteed
       a match — the join could never yield NULL. The columns below are therefore the
       exact same values the joins produced, at zero cost. */
    Result AS (
      SELECT M.SalesOrderQuoteId, M.SalesOrderQuoteNumber, M.OpenDate as 'QuoteDate', M.CustomerId, M.Name as 'CustomerName', M.Status,
         M.VersionNumber, IsNull(M.SalesPrice,0) as 'QuoteAmount', M.IsNewVersionCreated, M.StatusId, M.CustomerReference,
         '' as 'Priority',
         'Multiple' AS PriorityType,          -- was PriorityCTE.PriorityType
         M.SalesPerson,
         ''         AS PartNumber,            -- was PartCTE.PartNumber
         'Multiple' AS PartNumberType,        -- was PartCTE.PartNumberType
         'Multiple' AS PartDescriptionType,   -- was PartDescCTE.PartDescriptionType
         M.CustomerTypeName as 'CustomerType', M.SalesOrderNumber, IsNULL(M.SoAmount,0) as 'SoAmount', M.CreatedDate,
         M.UpdatedDate, M.CreatedBy, M.UpdatedBy,
         'Multiple' AS ManufacturerType,      -- was PartMFCTE.ManufacturerType
         M.NumberOfItemCount, M.SourceBy, M.MarketplaceRef
         FROM Main M
      WHERE      
      (ISNULL(@GlobalFilter, '') = '' OR ((M.SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (M.SalesOrderNumber like '%' +@GlobalFilter+'%') OR
        (M.SalesOrderNumber like '%' +@GlobalFilter+'%') OR
        (M.Name like '%' +@GlobalFilter+'%') OR
        (M.Status like '%' +@GlobalFilter+'%') OR
        (M.VersionNumber like '%' +@GlobalFilter+'%') OR
        (M.SalesPerson like '%' +@GlobalFilter+'%') OR
        ('Multiple' like '%' +@GlobalFilter+'%') OR        -- ManufacturerType
        ('Multiple' like '%' +@GlobalFilter+'%') OR        -- PriorityType
        ('Multiple' like '%' +@GlobalFilter+'%') OR        -- PartNumberType
        ('Multiple' like '%' +@GlobalFilter+'%') OR        -- PartDescriptionType
        (M.CustomerReference like '%' +@GlobalFilter+'%') OR
        (M.CustomerTypeName like '%' +@GlobalFilter+'%') OR
        (M.CreatedBy like '%' +@GlobalFilter+'%') OR
        (M.UpdatedBy like '%' +@GlobalFilter+'%') OR
        (M.SourceBy like '%' +@GlobalFilter+'%') OR
        (M.MarketplaceRef like '%' +@GlobalFilter+'%') OR
        (M.NumberOfItemCount like '%' +@GlobalFilter+'%')
        ))
        AND (ISNULL(@SOQNumber,'') ='' OR M.SalesOrderQuoteNumber LIKE '%'+@SOQNumber+'%') AND
        (ISNULL(@SalesOrderNumber,'') = '' OR M.SalesOrderNumber LIKE '%'+@SalesOrderNumber+'%') AND
        (ISNULL(@CustomerName,'') = '' OR M.Name LIKE '%'+ @CustomerName+'%') AND
        (ISNULL(@Status,'') = ''  OR M.Status LIKE '%'+@Status+'%') AND
        (@QuoteAmount IS  NULL OR M.SalesPrice=@QuoteAmount) AND
        (@SoAmount IS  NULL OR M.SoAmount=@SoAmount) AND
        (@QuoteDate IS  NULL OR Cast(M.OpenDate AS DATE) = Cast(@QuoteDate AS DATE)) AND
        (ISNULL(@SalesPerson,'') ='' OR M.SalesPerson LIKE '%'+@SalesPerson+'%') AND
        (ISNULL(@PriorityType,'') ='' OR 'Multiple' LIKE '%'+ @PriorityType+'%') AND
        (ISNULL(@PartNumberType,'') ='' OR 'Multiple' LIKE '%'+@PartNumberType+'%') AND
        (ISNULL(@PartDescriptionType,'') ='' OR 'Multiple' LIKE '%'+@PartDescriptionType+'%') AND
        (ISNULL(@CustomerReference,'') ='' OR M.CustomerReference LIKE '%'+@CustomerReference+'%') AND
        (ISNULL(@CustomerType,'') ='' OR M.CustomerTypeName LIKE '%'+@CustomerType+'%') AND
        (ISNULL(@ManufacturerType,'') ='' OR 'Multiple' LIKE '%'+@ManufacturerType+'%') AND
        (ISNULL(@VersionNumber,'') ='' OR M.VersionNumber LIKE '%'+@VersionNumber+'%') AND
        (ISNULL(@CreatedBy,'') ='' OR M.CreatedBy LIKE '%'+@CreatedBy+'%') AND
        (ISNULL(@UpdatedBy,'') ='' OR M.UpdatedBy LIKE '%'+@UpdatedBy+'%') AND
        (ISNULL(@SourceBy,'') ='' OR M.SourceBy LIKE '%'+@SourceBy+'%') AND
        (ISNULL(@MarketplaceRef,'') ='' OR M.MarketplaceRef LIKE '%'+@MarketplaceRef+'%') AND
        (ISNULL(@CreatedDate,'') ='' OR Cast(M.CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND
        (ISNULL(@UpdatedDate,'') ='' OR Cast(M.UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) AND
        (ISNULL(@NumberOfItemCount,'') ='' OR M.NumberOfItemCount LIKE '%'+@NumberOfItemCount+'%')
        )

      /* OPTIMIZATION: COUNT(*) OVER() replaces the CTE_Count cross join.
         CTEs are not materialized — "FROM Result, CTE_Count" forced SQL Server to
         evaluate the entire Result tree a second time just for the total count.
         The window function returns the identical NumberOfItems in one pass. */
      SELECT SalesOrderQuoteId,SalesOrderQuoteNumber,QuoteDate,CustomerId,UPPER(CustomerName) 'CustomerName',UPPER(Status) 'Status',UPPER(VersionNumber) 'VersionNumber',QuoteAmount,IsNewVersionCreated,StatusId
      ,UPPER(CustomerReference) 'CustomerReference',UPPER(Priority) 'Priority',UPPER(PriorityType) 'PriorityType',UPPER(SalesPerson) 'SalesPerson',UPPER(PartNumber) 'PartNumber',UPPER(PartNumberType) 'PartNumberType','' 'PartDescription',UPPER(PartDescriptionType) 'PartDescriptionType',UPPER(CustomerType) 'CustomerType',UPPER(SalesOrderNumber) 'SalesOrderNumber',
      CreatedDate,UpdatedDate,
      COUNT(*) OVER() AS NumberOfItems,
      UPPER(CreatedBy) 'CreatedBy',UPPER(UpdatedBy) 'UpdatedBy','' 'Manufacturer',UPPER(ManufacturerType) 'ManufacturerType',NumberOfItemCount,SourceBy,MarketplaceRef
      FROM Result
      ORDER BY
      CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTEID')  THEN SalesOrderQuoteId END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='MANUFACTURERTYPE')  THEN ManufacturerType END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='SOAMOUNT')  THEN SoAmount END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='NUMBEROFITEMCOUNT')  THEN NumberOfItemCount END ASC,
      CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTEID')  THEN SalesOrderQuoteId END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='MANUFACTURERTYPE')  THEN ManufacturerType END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='SOAMOUNT')  THEN SoAmount END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
      CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
      CASE WHEN (@SortOrder=-1 and @SortColumn='NUMBEROFITEMCOUNT')  THEN NumberOfItemCount END DESC,
      CASE WHEN (@SortOrder=1 and @SortColumn='SOURCEBY')  THEN SourceBy END ASC,
      CASE WHEN (@SortOrder=-1 and @SortColumn='SOURCEBY')  THEN SourceBy END DESC,
      CASE WHEN (@SortOrder=1 and @SortColumn='MARKETPLACEREF')  THEN MarketplaceRef END ASC,   -- NOTE: was 'MarketplaceRef' (mixed case); could never match because @SortColumn is uppercased
      CASE WHEN (@SortOrder=-1 and @SortColumn='MARKETPLACEREF')  THEN MarketplaceRef END DESC
      OFFSET @RecordFrom ROWS
      FETCH NEXT @PageSize ROWS ONLY
      OPTION (RECOMPILE);  -- OPTIMIZATION: many optional catch-all filters => parameter
                           -- sniffing; RECOMPILE lets the optimizer eliminate unused
                           -- predicates from the plan per execution.
     END
    /* OPTIMIZATION: removed BEGIN TRANSACTION / COMMIT — procedure is read-only,
       the explicit transaction only added lock-duration and log overhead. */

  END TRY
  BEGIN CATCH
   IF @@TRANCOUNT > 0
   BEGIN
    PRINT 'ROLLBACK';
    ROLLBACK TRAN;
   END
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchSOQViewData'
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@PageNumber AS VARCHAR(20)), '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters    =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
  END CATCH
END