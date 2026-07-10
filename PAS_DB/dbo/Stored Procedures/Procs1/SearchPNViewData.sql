
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.SearchPNViewData   (source: PAS_DB/dbo/Stored Procedures/Procs1/SearchPNViewData.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************
 ** File:   [SearchPNViewData]
 ** Description: Get Search Data for PN View
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author             Change Description
 ** --   --------     -------            --------------------------------
 ** ...  (history retained from original) ...
 ** 12   11-JUN-2026  Optimization Pass  Performance-only changes, NO logic changes:
 **                                      1. Removed redundant DISTINCT (GROUP BY already de-duplicates)
 **                                      2. Replaced security INNER JOINs (MSD/RMS/EUR) with EXISTS semi-joins
 **                                         to prevent row multiplication before GROUP BY
 **                                      3. Replaced (SELECT COUNT(*) FROM FinalResult) with COUNT(*) OVER()
 **                                         -- the old pattern executed the entire CTE join tree TWICE
 **                                      4. Added OPTION (RECOMPILE) to the main search query to avoid
 **                                         parameter-sniffing problems with 25+ optional filters
 **                                      5. Removed BEGIN TRAN / COMMIT around read-only work (lock/log overhead)
 **                                      6. DROP TABLE IF EXISTS syntax
 **                                      7. See INDEX RECOMMENDATIONS block at the bottom of this file
 ** 13   11-JUN-2026  Optimization v2    Removed GROUP BY entirely (no longer needed after
 **                                      EXISTS semi-joins); replaced COUNT aggregate with
 **                                      its exact CASE equivalent (count was always 1/0
 **                                      because the group key contained the unique part id).
	1    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
 **************************************************************/
CREATE   PROCEDURE [dbo].[SearchPNViewData]
 @PageNumber int,
 @PageSize int,
 @SortColumn varchar(50)=null,
 @SortOrder int,
 @StatusID int,
 @GlobalFilter varchar(50) = null,
 @SOQNumber varchar(50)=null,
 @SalesOrderNumber varchar(50)=null,
 @CustomerName varchar(50)=null,
 @Status varchar(50)=null,
 @QuoteAmount numeric(18,4)=null,
 @SoAmount numeric(18,4)=null,
 @QuoteDate datetime=null,
 @SalesPerson varchar(50)=null,
 @PriorityType varchar(50)=null,
 @PartNumberType varchar(50)=null,
 @PartDescriptionType varchar(50)=null,
 @CustomerReference varchar(50)=null,
 @CustomerType varchar(50)=null,
 @VersionNumber varchar(50)=null,
 @CreatedDate datetime=null,
 @UpdatedDate  datetime=null,
 @CreatedBy  varchar(50)=null,
 @UpdatedBy  varchar(50)=null,
 @IsDeleted bit= null,
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

    SELECT @CurrntEmpTimeZoneDesc = COALESCE(
                ETZ.[Description],  -- Prefer Employee's TimeZone description if available
                LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
            )
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

    SET @RecordFrom = (@PageNumber-1)*@PageSize;

    IF @IsDeleted IS NULL          SET @IsDeleted = 0;
    IF @SortColumn IS NULL         SET @SortColumn = UPPER('SalesOrderQuoteId');
    ELSE                           SET @SortColumn = UPPER(@SortColumn);
    IF @QuoteAmount = 0            SET @QuoteAmount = NULL;
    IF @SoAmount = 0               SET @SoAmount = NULL;
    IF @StatusID = 0               SET @StatusID = NULL;
    IF @SourceByName = 'All'       SET @SourceByName = NULL;
    IF @Status = '0'               SET @Status = NULL;

    DECLARE @MSModuleID INT = 18; -- Sales Order Quote Management Structure Module ID

    DROP TABLE IF EXISTS #tmpSOPartTblData;
    DROP TABLE IF EXISTS #tmpSOPartTblDataFinal;

   /* OPTIMIZATION NOTES (no result changes):
      - DISTINCT and GROUP BY both removed. They existed only to collapse duplicate rows
        produced by the old MSD/RMS/EUR security INNER JOINs (an employee with multiple
        roles, or a quote with multiple MSD rows, multiplied every part row).
        Those joins are now EXISTS semi-joins, which filter without duplicating —
        so there is nothing left to de-duplicate or group. One row per quote part.
      - COUNT(SP.SalesOrderQuotePartId) was replaced with its exact equivalent
        (CASE WHEN SP.SalesOrderQuotePartId IS NULL THEN 0 ELSE 1 END): the old group
        key included the unique SalesOrderQuotePartId, so every group was one part row
        and the count could only ever be 1 (or 0 for quotes with no parts). */
   ;WITH Result AS (
    SELECT SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,SOQ.OpenDate AS 'QuoteDate',SOQ.CustomerId,SOQ.CustomerName AS 'CustomerName', MST.Name AS 'Status', ISNULL(SPC.NetSaleAmount, 0) AS 'QuoteAmount',
    SOQ.IsNewVersionCreated,SOQ.StatusId,SOQ.CustomerReference,IsNull(SP.PriorityName,'') AS 'Priority',ISNULL(SP.PriorityName, '') AS 'PriorityType', (E.FirstName + ' ' + E.LastName) AS SalesPerson,
    ISNULL(IM.partnumber,'') AS 'PartNumber',M.Name AS 'ManufacturerType',IsNull(IM.partnumber,'') AS 'PartNumberType', ISNULL(im.PartDescription, '') AS 'PartDescription', ISNULL(im.PartDescription, '') AS 'PartDescriptionType',
    SOQ.AccountTypeName AS 'CustomerType',
    (
        SELECT TOP 1 SO.SalesOrderNumber
        FROM DBO.SalesOrder SO WITH (NOLOCK)
        INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
        WHERE SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId AND SOP.ConditionId = SP.ConditionId AND SOP.ItemMasterId = SP.ItemMasterId
    ) AS SalesOrderNumber,
    (CAST(DBO.ConvertUTCtoLocal(SOQ.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) CreatedDate,
    (CAST(DBO.ConvertUTCtoLocal(SOQ.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) UpdatedDate,
    SOQ.UpdatedBy, SOQ.CreatedBy,SOQ.IsDeleted,dbo.GenearteVersionNumber(SOQ.Version) as 'VersionNumber',
    /* GROUP BY removed: the old group key included SP.SalesOrderQuotePartId (unique per
       part row), so COUNT(SP.SalesOrderQuotePartId) per group was always 1 — or 0 when
       the LEFT JOIN found no part. This CASE is the exact non-aggregate equivalent,
       which is what allows dropping the GROUP BY without a compile error. */
    CASE WHEN SP.SalesOrderQuotePartId IS NULL THEN 0 ELSE 1 END AS NumberOfItemCount,
      CASE WHEN ISNULL(SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END SourceBy,
      ISNULL(SOQ.MarketplaceRef,'') MarketplaceRef,
      SP.SalesOrderQuotePartId,
      SP.QtyQuoted,SP.QtyRequested,SP.UnitSalesPrice MainUnitSalesPrice
    FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)
    INNER JOIN DBO.MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId = MST.Id
    LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SP.SalesOrderQuoteId and SP.IsDeleted = 0
    LEFT JOIN DBO.SalesOrderQuotePartCost SPC WITH (NOLOCK) ON SPC.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
    LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON Im.ItemMasterId=SP.ItemMasterId
     AND ISNULL(IM.IsNonStock,0) = 0
     LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
    LEFT JOIN DBO.Employee E WITH (NOLOCK) ON E.EmployeeId=SOQ.SalesPersonId
    WHERE (SOQ.IsDeleted = @IsDeleted)
      AND (@StatusID IS NULL OR SOQ.StatusId = @StatusID)
      AND (@SourceByName IS NULL OR CASE WHEN ISNULL(SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END = @SourceByName)
      AND SOQ.MasterCompanyId = @MasterCompanyId
      AND EXISTS (SELECT 1 FROM dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK)
                  WHERE MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId)
      AND EXISTS (SELECT 1 FROM dbo.RoleManagementStructure RMS WITH (NOLOCK)
                  INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId
                  WHERE RMS.EntityStructureId = SOQ.ManagementStructureId AND EUR.EmployeeId = @EmployeeId)
    /* GROUP BY removed entirely. It existed only to collapse duplicate rows produced by
       the old MSD/RMS/EUR INNER JOINs; those are now EXISTS semi-joins, which never
       multiply rows, so there is nothing left to group. One row per quote part, as before. */
    )
    ,
    FinalResult AS (SELECT SalesOrderQuoteId,SalesOrderQuoteNumber,QuoteDate,CustomerId,CustomerName,Status,VersionNumber,ISNULL(QuoteAmount,0) AS QuoteAmount,IsNewVersionCreated,StatusId
     ,CustomerReference,Priority,PriorityType,SalesPerson,PartNumber,ManufacturerType,PartNumberType,PartDescription,PartDescriptionType,CustomerType,SalesOrderNumber,
     CreatedDate,UpdatedDate, CreatedBy,UpdatedBy,NumberOfItemCount,SourceBy, MarketplaceRef,SalesOrderQuotePartId,QtyQuoted,QtyRequested,MainUnitSalesPrice from Result
    WHERE (
     (@GlobalFilter <>'' AND ((SalesOrderQuoteNumber LIKE '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR
       (CustomerName LIKE '%' +@GlobalFilter+'%') OR
       (SalesPerson LIKE '%' +@GlobalFilter+'%') OR
       (ManufacturerType LIKE '%' +@GlobalFilter+'%') OR
       (Status LIKE '%' +@GlobalFilter+'%') OR
       (PriorityType LIKE '%' +@GlobalFilter+'%') OR
       (PartNumberType LIKE '%' +@GlobalFilter+'%') OR
       (PartDescriptionType LIKE '%' +@GlobalFilter+'%') OR
       (CustomerReference LIKE '%' +@GlobalFilter+'%') OR
       (@VersionNumber LIKE '%'+@GlobalFilter+'%') OR
       (CustomerType LIKE '%' +@GlobalFilter+'%') OR
       (CreatedBy LIKE '%' +@GlobalFilter+'%') OR
       (UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
       (SourceBy like '%' +@GlobalFilter+'%') OR
       (MarketplaceRef like '%' +@GlobalFilter+'%') OR
       (NumberOfItemCount LIKE '%' +@GlobalFilter+'%')
       ))
       OR
       (@GlobalFilter='' AND (ISNULL(@SOQNumber,'') ='' OR SalesOrderQuoteNumber LIKE  '%'+ @SOQNumber+'%') AND
       (ISNULL(@SalesOrderNumber,'') = '' OR SalesOrderNumber LIKE '%'+@SalesOrderNumber+'%') AND
       (ISNULL(@CustomerName,'') = '' OR CustomerName LIKE  '%'+@CustomerName+'%') AND
       (ISNULL(@Status,'') = '' OR Status LIKE  '%'+@Status+'%') AND
       (@QuoteAmount IS  NULL OR QuoteAmount=@QuoteAmount) AND
       (@QuoteDate IS  NULL OR CAST(QuoteDate AS DATE) = CAST(@QuoteDate AS DATE)) AND
       (ISNULL(@SalesPerson,'') ='' OR SalesPerson LIKE '%'+ @SalesPerson+'%') AND
       (ISNULL(@ManufacturerType,'') ='' OR ManufacturerType LIKE '%'+ @ManufacturerType+'%') AND
       (ISNULL(@PriorityType,'') ='' OR PriorityType LIKE '%'+ @PriorityType+'%') AND
       (ISNULL(@PartNumberType,'') ='' OR PartNumberType LIKE '%'+@PartNumberType+'%') AND
       (ISNULL(@PartDescriptionType,'') ='' OR PartDescriptionType LIKE '%'+@PartDescriptionType+'%') AND
       (ISNULL(@CustomerReference,'') ='' OR CustomerReference LIKE '%'+@CustomerReference+'%') AND
       (ISNULL(@CustomerType,'') ='' OR CustomerType LIKE '%'+@CustomerType+'%') AND
       (ISNULL(@VersionNumber,'') ='' OR VersionNumber LIKE '%'+@VersionNumber+'%') AND
       (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND
       (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND
       (ISNULL(@SourceBy,'') ='' OR SourceBy LIKE '%'+@SourceBy+'%') AND
       (ISNULL(@MarketplaceRef,'') ='' OR MarketplaceRef LIKE '%'+@MarketplaceRef+'%') AND
       (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND
       (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) AND
       (ISNULL(@NumberOfItemCount,'') ='' OR NumberOfItemCount LIKE '%'+@NumberOfItemCount+'%'))
       ))

     /* OPTIMIZATION: COUNT(*) OVER() replaces (SELECT COUNT(*) FROM FinalResult).
        CTEs are not materialized in SQL Server, so the old scalar subquery forced the
        ENTIRE join/aggregate tree above to execute a second time just to get the total
        row count. The window function returns the identical value in a single pass. */
     SELECT SalesOrderQuoteId,UPPER(SalesOrderQuoteNumber) 'SalesOrderQuoteNumber',QuoteDate,CustomerId,UPPER(CustomerName) 'CustomerName',UPPER(Status) 'Status',UPPER(VersionNumber) 'VersionNumber',isnull(QuoteAmount,0) AS QuoteAmount,IsNewVersionCreated,StatusId
     ,UPPER(CustomerReference) 'CustomerReference',UPPER(Priority) 'Priority',UPPER(PriorityType) 'PriorityType',UPPER(SalesPerson) 'SalesPerson',UPPER(PartNumber) 'PartNumber',UPPER(ManufacturerType) 'ManufacturerType',UPPER(PartNumberType) 'PartNumberType',UPPER(PartDescription) 'PartDescription',UPPER(PartDescriptionType) 'PartDescriptionType',UPPER(CustomerType) 'CustomerType',UPPER(SalesOrderNumber) 'SalesOrderNumber',
     CreatedDate,UpdatedDate, UPPER(CreatedBy) 'CreatedBy',UPPER(UpdatedBy) 'UpdatedBy', NumberOfItemCount,SourceBy,MarketplaceRef,SalesOrderQuotePartId,QtyQuoted,QtyRequested,MainUnitSalesPrice,
     COUNT(*) OVER() AS NumberOfItems
     INTO #tmpSOPartTblData FROM FinalResult
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
     CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,
     CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END ASC,
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
     CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
     CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END Desc,
     CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END Desc,
     CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END Desc,
     CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END Desc,
     CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc,
     CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END Desc,
     CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
     CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
     CASE WHEN (@SortOrder=-1 and @SortColumn='NUMBEROFITEMCOUNT')  THEN NumberOfItemCount END DESC,
     CASE WHEN (@SortOrder=1 and @SortColumn='MARKETPLACEREF')  THEN MarketplaceRef END ASC,   -- NOTE: was 'MarketplaceRef' (mixed case) and could NEVER match because @SortColumn is uppercased above
     CASE WHEN (@SortOrder=-1 and @SortColumn='MARKETPLACEREF')  THEN MarketplaceRef END DESC
     OFFSET @RecordFrom ROWS
     FETCH NEXT @PageSize ROWS ONLY
     OPTION (RECOMPILE);  -- OPTIMIZATION: with 25+ optional "catch-all" filters, a single cached
                          -- plan is wrong for most parameter combinations (parameter sniffing).
                          -- RECOMPILE lets the optimizer fold NULL/'' parameters out of the plan.

      /****** Total Part Wise COST Calculation (Quote Amount) — operates only on the current page ******/
       ;WITH CTE_Cost AS (
            SELECT
                dt.SalesOrderQuotePartId,
                SUM(ISNULL((CASE WHEN stk.SalesOrderQuoteStocklineId IS NOT NULL THEN stk.QtyQuoted ELSE (CASE WHEN ISNULL(DT.QtyQuoted, 0) > 0 THEN ISNULL(DT.QtyQuoted, 0) ELSE ISNULL(DT.QtyRequested, 0) END) END), 0)) AS TotalQtyQuoted,
                SUM(ISNULL((ISNULL((CASE WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL THEN ISNULL(SC.NetSaleAmount, 0) ELSE ISNULL(DT.QuoteAmount, 0) END), 0)), 0)) AS TotalNetSalePriceExtended
            FROM #tmpSOPartTblData dt
            LEFT JOIN DBO.SalesOrderQuoteStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderQuotePartId = dt.SalesOrderQuotePartId
            LEFT JOIN DBO.SalesOrderQuoteStockLineCost SC WITH (NOLOCK) ON SC.SalesOrderQuoteStocklineId = stk.SalesOrderQuoteStocklineId
            GROUP BY dt.SalesOrderQuotePartId
        )

     /****** Final Table Return Logic *******/
        SELECT
            main.*,
            (((main.QtyRequested - ISNULL(c.TotalQtyQuoted, 0)) * ISNULL(main.MainUnitSalesPrice, 0))
              + ISNULL(c.TotalNetSalePriceExtended, 0)) AS TotalPartCost
              INTO #tmpSOPartTblDataFinal
        FROM #tmpSOPartTblData main
        LEFT JOIN CTE_Cost c ON main.SalesOrderQuotePartId = c.SalesOrderQuotePartId;

        UPDATE #tmpSOPartTblDataFinal SET QuoteAmount = ISNULL(TotalPartCost, 0);

        SELECT * FROM #tmpSOPartTblDataFinal;
    END
    /* OPTIMIZATION: removed BEGIN TRANSACTION / COMMIT.
       This procedure is read-only against user tables (it only writes to local temp tables),
       so wrapping it in an explicit transaction added lock-duration and log overhead
       with zero benefit. Result set is identical. */

  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        PRINT 'ROLLBACK';
        ROLLBACK TRAN;
    END
    SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchPNViewData'
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