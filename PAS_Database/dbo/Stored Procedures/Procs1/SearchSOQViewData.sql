/*************************************************************             
 ** File:   [SearchSOQViewData]             
 ** Author:    
 ** Description: Get Search Data for SOQ List   
 ** Purpose:           
 ** Date:     
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author             Change Description              
 ** --   --------     -------            --------------------------------            
    1    07/08/2023   Ekta Chandegra     Convert text into uppercase   
    2    09/20/2024   Vishal Suthar      Modified the SOQ table joins with new tables
	3	 22-Jan-2025  Ayushi Patel		 converted the date into utc (created , updated) , Added a case to get timeZone 
	4	 12-Mar-2025  Vishal Suthar		 Modified default sort column to SalesOrderQuoteId 
	5	 09-APR-2025  Vishal Suthar		 Applied Optimization, Standard Formatting and Cleanup
	6    27-06-2025  Bhargav Saliya		 Add New Fields @NumberOfItemCount 
	7    13-08-2025  Rajesh Gami		 Add New Parameters @SourceBy,@MarketplaceRef And as same as for Return 
	8    24-09-2025  Sahdev Saliya       Added New Dropdown Filter Lead Source
	9    20-11-2025  Rajesh Gami		Correct the QuoteAmount 
	10   21-MAY-2026  Rajesh Gami		 PN-16508 : Fix the duplicate issue when Single SOQ have muliple SO Converted
    12	 05-August-2026	Divyesh Kathiriya	[PN-17555] - Fix filter to the search query.
    13   29-Oct-2026  Rajesh Gami         [PN-18450] Performance: the heavy columns (Quote Amount, SO Amount, Part Number / Description / Manufacturer / Priority, Version, local dates)
                                         are now calculated only for the rows of the requested page (all rows only when a filter / sort needs them), the helper CTEs no longer scan every company's quotes,
                                         unused Cost calculation removed. Same output / same filters / same sorting as before.

**************************************************************/ 
CREATE PROCEDURE [dbo].[SearchSOQViewData]
 -- Add the parameters for the stored procedure here
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
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
    DECLARE @RecordFrom int;  
	DECLARE @EmpLegalEntiyId BIGINT = 0;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
	SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
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
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

    SET @RecordFrom = (@PageNumber - 1) * @PageSize;  
    IF @IsDeleted IS NULL
    BEGIN
		SET @IsDeleted = 0
    END
    
    IF @SortColumn IS NULL
    BEGIN
		SET @SortColumn = Upper('SalesOrderQuoteId')
    END
    ELSE
    BEGIN
		SET @SortColumn = Upper(@SortColumn)
    END
  
    IF @QuoteAmount = 0
    BEGIN
		SET @QuoteAmount = NULL
    END
    
    IF @SoAmount = 0
    BEGIN
		SET @SoAmount = NULL
    END
  
    IF @StatusID = 0
    BEGIN
		SET @StatusID = NULL
    END
  
    IF @Status = '0'
    BEGIN
		SET @Status = NULL
    END

	 
    IF @SourceByName = 'All'
    BEGIN
		SET @SourceByName = NULL
    END

    DECLARE @MSModuleID INT = 18; -- Sales Order Quote Management Structure Module ID  

    /* [PN-18450]
       Step 0 : the heavy columns (QuoteAmount, SoAmount, Part Number / Description / Manufacturer / Priority strings, Version, local dates)
                are only needed for the rows that are shown, unless a filter / sort works on them (@NeedAll = 1).
    */
    DECLARE @NeedAll BIT = 0;
    IF (ISNULL(@GlobalFilter, '') <> '' OR @QuoteAmount IS NOT NULL OR @SoAmount IS NOT NULL
        OR ISNULL(@PriorityType, '') <> '' OR ISNULL(@PartNumberType, '') <> '' OR ISNULL(@PartDescriptionType, '') <> ''
        OR ISNULL(@ManufacturerType, '') <> '' OR ISNULL(@VersionNumber, '') <> ''
        OR ISNULL(@CreatedDate, '') <> '' OR ISNULL(@UpdatedDate, '') <> ''
        OR @SortColumn IN ('CREATEDDATE', 'UPDATEDDATE', 'VERSIONNUMBER', 'PARTNUMBERTYPE', 'PARTDESCRIPTIONTYPE', 'MANUFACTURERTYPE', 'QUOTEAMOUNT', 'SOAMOUNT', 'PRIORITYTYPE'))
    BEGIN
        SET @NeedAll = 1;
    END

    /* Step 1 : quotes of the company the employee is allowed to see (same conditions as the old [Main] CTE, security joins as EXISTS) */
    SELECT SOQ.SalesOrderQuoteId, SOQ.SalesOrderQuoteNumber, SOQ.OpenDate, SOQ.CustomerId,
           SOQ.CustomerName AS Name, MST.Name AS Status, (E.FirstName + ' ' + E.LastName) AS SalesPerson, SOQ.AccountTypeName AS CustomerTypeName,
           SOQ.CreatedDate AS CreatedDateUtc, SOQ.UpdatedDate AS UpdatedDateUtc, SOQ.StatusId, SOQ.CreatedBy, SOQ.UpdatedBy,
           SOQ.[Version], SOQ.IsNewVersionCreated, SOQ.CustomerReference,
           CASE WHEN ISNULL(SOQ.SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END AS SourceBy,
           ISNULL(SOQ.MarketplaceRef,'') AS MarketplaceRef
    INTO #Q
    FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)
    INNER JOIN DBO.MasterSalesOrderQuoteStatus MST WITH (NOLOCK) ON SOQ.StatusId = MST.Id
    LEFT JOIN DBO.Employee E WITH (NOLOCK) ON E.EmployeeId = SOQ.SalesPersonId
    WHERE (SOQ.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SOQ.StatusId = @StatusID)
      AND (@SourceByName IS NULL OR CASE WHEN ISNULL(SOQ.SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END = @SourceByName)
      AND SOQ.MasterCompanyId = @MasterCompanyId
      AND EXISTS (SELECT 1 FROM dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) WHERE MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId)
      AND EXISTS (SELECT 1 FROM [dbo].[RoleManagementStructure] RMS WITH (NOLOCK)
                  INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
                  WHERE SOQ.ManagementStructureId = RMS.EntityStructureId)
    OPTION (RECOMPILE);

    CREATE UNIQUE CLUSTERED INDEX CIX_Q ON #Q (SalesOrderQuoteId);

    /* Step 2 : Sales Order number of the quote ('MULTIPLE' when more than one SO was converted, else the SO of the part) - same logic as before,
                the per part look up only runs for quotes that have exactly one Sales Order */
    SELECT SOR.SalesOrderQuoteId, COUNT(SOR.SalesOrderId) AS SOCount
    INTO #SOCnt
    FROM DBO.SalesOrder SOR WITH (NOLOCK)
    INNER JOIN #Q Q ON Q.SalesOrderQuoteId = SOR.SalesOrderQuoteId
    GROUP BY SOR.SalesOrderQuoteId;

    CREATE UNIQUE CLUSTERED INDEX CIX_SOCnt ON #SOCnt (SalesOrderQuoteId);

    SELECT DISTINCT Q.SalesOrderQuoteId,
           CASE WHEN ISNULL(C.SOCount, 0) > 1 THEN 'MULTIPLE'
                WHEN ISNULL(C.SOCount, 0) = 1 THEN
                    (SELECT TOP 1 SO.SalesOrderNumber
                     FROM DBO.SalesOrder SO WITH (NOLOCK) INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
                     WHERE SO.SalesOrderQuoteId = Q.SalesOrderQuoteId AND SOP.ConditionId = SOQP.ConditionId AND SOP.ItemMasterId = SOQP.ItemMasterId)
                ELSE NULL END AS SalesOrderNumber
    INTO #SONum
    FROM #Q Q
    LEFT JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = Q.SalesOrderQuoteId
    LEFT JOIN #SOCnt C ON C.SalesOrderQuoteId = Q.SalesOrderQuoteId;

    SELECT soqv1.SalesOrderQuoteId, COUNT(soqv1.SalesOrderQuotePartId) AS Items
    INTO #PC
    FROM [dbo].[SalesOrderQuotePartV1] soqv1 WITH (NOLOCK)
    INNER JOIN #Q Q ON Q.SalesOrderQuoteId = soqv1.SalesOrderQuoteId
    GROUP BY soqv1.SalesOrderQuoteId;

    CREATE UNIQUE CLUSTERED INDEX CIX_PC ON #PC (SalesOrderQuoteId);

    /* Step 3 : light weight rows (one row per quote / SO number, as the old DISTINCT) with all the filters that only need these light columns */
    SELECT IDENTITY(INT, 1, 1) AS RowId, Q.SalesOrderQuoteId, Q.SalesOrderQuoteNumber, Q.OpenDate, Q.CustomerId, Q.Name, Q.Status, Q.SalesPerson, Q.CustomerTypeName,
           S.SalesOrderNumber, Q.StatusId, Q.CreatedBy, Q.UpdatedBy, Q.IsNewVersionCreated, Q.CustomerReference,
           ISNULL(PC.Items, 0) AS NumberOfItemCount, Q.SourceBy, Q.MarketplaceRef
    INTO #Base
    FROM #Q Q
    INNER JOIN #SONum S ON S.SalesOrderQuoteId = Q.SalesOrderQuoteId
    LEFT JOIN #PC PC ON PC.SalesOrderQuoteId = Q.SalesOrderQuoteId
    WHERE (ISNULL(@SOQNumber,'') ='' OR Q.SalesOrderQuoteNumber LIKE '%'+@SOQNumber+'%') AND
          (ISNULL(@SalesOrderNumber,'') = '' OR S.SalesOrderNumber LIKE '%'+@SalesOrderNumber+'%') AND
          (ISNULL(@CustomerName,'') = '' OR Q.Name LIKE '%'+ @CustomerName+'%') AND
          (ISNULL(@Status,'') = ''  OR Q.Status LIKE '%'+@Status+'%') AND
          (@QuoteDate IS  NULL OR Cast(Q.OpenDate AS DATE) = Cast(@QuoteDate AS DATE)) AND
          (ISNULL(@SalesPerson,'') ='' OR Q.SalesPerson LIKE '%'+@SalesPerson+'%') AND
          (ISNULL(@CustomerReference,'') ='' OR Q.CustomerReference LIKE '%'+@CustomerReference+'%') AND
          (ISNULL(@CustomerType,'') ='' OR Q.CustomerTypeName LIKE '%'+@CustomerType+'%') AND
          (ISNULL(@CreatedBy,'') ='' OR Q.CreatedBy LIKE '%'+@CreatedBy+'%') AND
          (ISNULL(@UpdatedBy,'') ='' OR Q.UpdatedBy LIKE '%'+@UpdatedBy+'%') AND
          (ISNULL(@SourceBy,'') ='' OR Q.SourceBy LIKE '%'+@SourceBy+'%') AND
          (ISNULL(@MarketplaceRef,'') ='' OR Q.MarketplaceRef LIKE '%'+@MarketplaceRef+'%') AND
          (ISNULL(@NumberOfItemCount,'') ='' OR ISNULL(PC.Items, 0) LIKE '%'+@NumberOfItemCount+'%')
    OPTION (RECOMPILE);

    CREATE UNIQUE CLUSTERED INDEX CIX_Base ON #Base (RowId);
    CREATE NONCLUSTERED INDEX IX_Base_Quote ON #Base (SalesOrderQuoteId);

    /* Step 4 : work tables
       #Need : quotes the heavy columns are calculated for      #Exp : the heavy columns      #Page : the requested page (Seq = display order, Total = number of rows) */
    CREATE TABLE #Need (SalesOrderQuoteId BIGINT NOT NULL PRIMARY KEY);
    CREATE TABLE #Exp (
        SalesOrderQuoteId BIGINT NOT NULL PRIMARY KEY,
        SalesPrice DECIMAL(38, 12) NULL,
        SoAmount DECIMAL(38, 6) NULL,
        PartNumberType NVARCHAR(MAX) NULL, PartNumber NVARCHAR(MAX) NULL,
        PartDescriptionType NVARCHAR(MAX) NULL, PartDescription NVARCHAR(MAX) NULL,
        ManufacturerType NVARCHAR(MAX) NULL, Manufacturer NVARCHAR(MAX) NULL,
        PriorityType NVARCHAR(MAX) NULL, PriorityDescription NVARCHAR(MAX) NULL,
        VersionNumber VARCHAR(50) NULL, CreatedDate DATE NULL, UpdatedDate DATE NULL);
    CREATE TABLE #Page (Seq INT IDENTITY(1,1) NOT NULL PRIMARY KEY, RowId INT NOT NULL, Total INT NOT NULL);

    /* Step 5 : two steps, the order depends on @NeedAll
         @NeedAll = 0 (normal grid load / simple filters) : 1) select the page  2) calculate the heavy columns for the page rows only
         @NeedAll = 1 (a filter / sort uses a heavy column) : 1) calculate the heavy columns for all rows  2) filter / sort / select the page */
    DECLARE @Step INT = 1;
    WHILE @Step <= 2
    BEGIN
        IF (@NeedAll = 0 AND @Step = 1) OR (@NeedAll = 1 AND @Step = 2)
        BEGIN
            /* ---------- PAGE : filters on heavy columns + global filter + sort + paging ---------- */
            ;WITH Result AS (
                SELECT M.RowId, M.SalesOrderQuoteId, M.SalesOrderQuoteNumber, M.OpenDate AS 'QuoteDate', M.CustomerId, M.Name AS 'CustomerName', M.Status,
                       X.VersionNumber, ISNULL(X.SalesPrice, 0) AS 'QuoteAmount', M.IsNewVersionCreated, M.StatusId, M.CustomerReference,
                       X.PriorityDescription AS 'Priority', X.PriorityType, M.SalesPerson, X.PartNumber, X.PartNumberType, X.PartDescription,
                       X.PartDescriptionType, M.CustomerTypeName AS 'CustomerType', M.SalesOrderNumber, ISNULL(X.SoAmount, 0) AS 'SoAmount', X.CreatedDate,
                       X.UpdatedDate, M.CreatedBy, M.UpdatedBy, X.Manufacturer, X.ManufacturerType, M.NumberOfItemCount, M.SourceBy, M.MarketplaceRef
                FROM #Base M
                LEFT JOIN #Exp X ON X.SalesOrderQuoteId = M.SalesOrderQuoteId
                WHERE
                (ISNULL(@GlobalFilter, '') = '' OR ((M.SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (M.SalesOrderNumber like '%' +@GlobalFilter+'%') OR
                  (M.Name like '%' +@GlobalFilter+'%') OR
                  (M.Status like '%' +@GlobalFilter+'%') OR
                  (X.VersionNumber like '%' +@GlobalFilter+'%') OR
                  (M.SalesPerson like '%' +@GlobalFilter+'%') OR
                  (X.ManufacturerType like '%' +@GlobalFilter+'%') OR
                  (X.PriorityType like '%' +@GlobalFilter+'%') OR
                  (X.PartNumberType like '%' +@GlobalFilter+'%') OR
                  (X.PartDescriptionType like '%' +@GlobalFilter+'%') OR
                  (M.CustomerReference like '%' +@GlobalFilter+'%') OR
                  (M.CustomerTypeName like '%' +@GlobalFilter+'%') OR
                  (M.CreatedBy like '%' +@GlobalFilter+'%') OR
                  (M.UpdatedBy like '%' +@GlobalFilter+'%') OR
                  (M.SourceBy like '%' +@GlobalFilter+'%') OR
                  (M.MarketplaceRef like '%' +@GlobalFilter+'%') OR
                  (M.NumberOfItemCount like '%' +@GlobalFilter+'%')
                  )) AND
                (@QuoteAmount IS  NULL OR X.SalesPrice = @QuoteAmount) AND
                (@SoAmount IS  NULL OR X.SoAmount = @SoAmount) AND
                (ISNULL(@PriorityType,'') ='' OR X.PriorityType LIKE '%'+ @PriorityType+'%') AND
                (ISNULL(@PartNumberType,'') ='' OR X.PartNumberType LIKE '%'+@PartNumberType+'%') AND
                (ISNULL(@PartDescriptionType,'') ='' OR X.PartDescriptionType LIKE '%'+@PartDescriptionType+'%') AND
                (ISNULL(@ManufacturerType,'') ='' OR X.ManufacturerType LIKE '%'+@ManufacturerType+'%') AND
                (ISNULL(@VersionNumber,'') ='' OR X.VersionNumber LIKE '%'+@VersionNumber+'%') AND
                (ISNULL(@CreatedDate,'') ='' OR Cast(X.CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND
                (ISNULL(@UpdatedDate,'') ='' OR Cast(X.UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE))
            )
            INSERT INTO #Page (RowId, Total)
            SELECT RowId, COUNT(*) OVER ()
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
            CASE WHEN (@SortOrder=1 and @SortColumn='MarketplaceRef')  THEN MarketplaceRef END ASC,
            CASE WHEN (@SortOrder=-1 and @SortColumn='MarketplaceRef')  THEN MarketplaceRef END DESC
            OFFSET @RecordFrom ROWS
            FETCH NEXT @PageSize ROWS ONLY
            OPTION (RECOMPILE);
        END
        ELSE
        BEGIN
            /* ---------- HEAVY COLUMNS : for all rows (@NeedAll = 1) or for the page rows only (@NeedAll = 0) ---------- */
            IF @NeedAll = 1
            BEGIN
                INSERT INTO #Need (SalesOrderQuoteId) SELECT DISTINCT SalesOrderQuoteId FROM #Base;
            END
            ELSE
            BEGIN
                INSERT INTO #Need (SalesOrderQuoteId) SELECT DISTINCT B.SalesOrderQuoteId FROM #Page P INNER JOIN #Base B ON B.RowId = P.RowId;
            END

            INSERT INTO #Exp (SalesOrderQuoteId, SalesPrice, SoAmount, PartNumberType, PartNumber, PartDescriptionType, PartDescription, ManufacturerType, Manufacturer,
                              PriorityType, PriorityDescription, VersionNumber, CreatedDate, UpdatedDate)
            SELECT N.SalesOrderQuoteId, Z.NetSales, A.SoAmount, PT.PartNumberType, PT.PartNumber, PD.PartDescriptionType, PD.PartDescription,
                   MF.ManufacturerType, MF.Manufacturer, PR.PriorityType, PR.PriorityDescription,
                   dbo.GenearteVersionNumber(Q.[Version]),
                   Cast(DBO.ConvertUTCtoLocal(Q.CreatedDateUtc, @CurrntEmpTimeZoneDesc) AS DATE),
                   Cast(DBO.ConvertUTCtoLocal(Q.UpdatedDateUtc, @CurrntEmpTimeZoneDesc) AS DATE)
            FROM #Need N
            INNER JOIN #Q Q ON Q.SalesOrderQuoteId = N.SalesOrderQuoteId
            OUTER APPLY(
                SELECT SUM(SOPC.NetSaleAmount) AS SoAmount FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
                INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
                INNER JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuotePartId = SOP.SalesOrderQuotePartId
                Where SOQP.SalesOrderQuoteId = N.SalesOrderQuoteId
            ) A
            OUTER APPLY ( /*********  Total Part Wise COST Calculation (Quote Amount) **********/
					SELECT SUM(X.NetSales) AS NetSales
						FROM (

						SELECT 
								 (CASE 
									WHEN ISNULL(SUM(SOP.QtyRequested), 0) = ISNULL(SUM(SOP.QtyQuoted), 0) 
										THEN 0 
									ELSE 
										(
											(
												ISNULL(SUM(
													CASE 
														WHEN stk.SalesOrderQuoteStocklineId IS NOT NULL 
															THEN stk.QtyQuoted 
														ELSE 
															CASE 
																WHEN ISNULL(SOP.QtyQuoted, 0) > 0 
																	THEN ISNULL(SOP.QtyQuoted, 0) 
																ELSE 
																	ISNULL(SOP.QtyRequested, 0) 
															END 
													END
												), 0)
												* -1
												+ ISNULL(SOP.QtyRequested, 0)
											) * ISNULL(U.UnitSalesPrice, 0)
										)
								END)
								+
								ISNULL(SUM(
									CASE 
										WHEN SC.SalesOrderQuoteStocklineId IS NOT NULL 
											THEN ISNULL(SC.NetSaleAmount, 0) 
										ELSE 
											ISNULL(SOQPS.NetSaleAmount, 0) 
									END
								), 0) AS NetSales--,U.UnitSalesPrice
							FROM DBO.SalesOrderQuote quote WITH (NOLOCK)
							INNER JOIN DBO.SalesOrderQuotePartV1 SOP WITH (NOLOCK) 
								ON SOP.SalesOrderQuoteId = quote.SalesOrderQuoteId
							INNER JOIN DBO.SalesOrderQuotePartCost SOQPS WITH (NOLOCK) 
								ON SOQPS.SalesOrderQuoteId = quote.SalesOrderQuoteId 
								AND SOP.SalesOrderQuotePartId = SOQPS.SalesOrderQuotePartId
							LEFT JOIN DBO.SalesOrderQuoteStocklineV1 stk WITH (NOLOCK) 
								ON stk.SalesOrderQuotePartId = SOQPS.SalesOrderQuotePartId
							LEFT JOIN DBO.SalesOrderQuoteStockLineCost SC WITH (NOLOCK) 
								ON SC.SalesOrderQuoteStocklineId = stk.SalesOrderQuoteStocklineId 
								AND quote.SalesOrderQuoteId = SC.SalesOrderQuoteId

							OUTER APPLY (
								SELECT  
									ISNULL(SOQPS2.UnitSalesPrice, 0) AS UnitSalesPrice
								FROM DBO.SalesOrderQuotePartV1 SOQPS2 WITH (NOLOCK)
								 LEFT JOIN DBO.SalesOrderQuoteStocklineV1 stk2 WITH (NOLOCK) 
								ON stk2.SalesOrderQuotePartId = SOQPS2.SalesOrderQuotePartId
								WHERE SOQPS2.SalesOrderQuoteId = quote.SalesOrderQuoteId 
								  AND SOQPS2.SalesOrderQuotePartId = SOP.SalesOrderQuotePartId
								--ORDER BY SOQPS2.SalesOrderQuotePartCostId DESC
								GROUP BY SOQPS2.UnitSalesPrice
							) AS U

							WHERE quote.SalesOrderQuoteId = N.SalesOrderQuoteId
							AND SOP.SalesOrderQuoteId =N.SalesOrderQuoteId
							GROUP BY U.UnitSalesPrice,SOP.SalesOrderQuotePartId,SOP.QtyRequested
							) AS X
      ) Z
            OUTER APPLY (
                SELECT (CASE WHEN Count(SP.SalesOrderQuotePartId) > 1 THEN 'Multiple' ELSE X1.PartNumber END) AS 'PartNumberType', X1.PartNumber
                FROM DBO.SalesOrderQuote SQ WITH (NOLOCK)
                LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) On SQ.SalesOrderQuoteId = SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
                OUTER APPLY (
                    SELECT STUFF((SELECT ',' + I.partnumber
                                  FROM DBO.SalesOrderQuotePartV1 S WITH (NOLOCK)
                                  LEFT JOIN DBO.ItemMaster I WITH (NOLOCK) On S.ItemMasterId = I.ItemMasterId
                                  WHERE S.SalesOrderQuoteId = SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
                                  FOR XML PATH('')), 1, 1, '') PartNumber
                ) X1
                WHERE SQ.SalesOrderQuoteId = N.SalesOrderQuoteId
                GROUP BY SQ.SalesOrderQuoteId, X1.PartNumber
            ) PT
            OUTER APPLY (
                SELECT (CASE WHEN COUNT(SP.SalesOrderQuotePartId) > 1 THEN 'Multiple' ELSE X1.PartDescription END) AS 'PartDescriptionType', X1.PartDescription
                FROM DBO.SalesOrderQuote SQ WITH (NOLOCK)
                LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) On SQ.SalesOrderQuoteId = SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
                OUTER APPLY (
                    SELECT STUFF((SELECT ', ' + I.PartDescription
                                  FROM DBO.SalesOrderQuotePartV1 S WITH (NOLOCK)
                                  LEFT JOIN DBO.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
                                  Where S.SalesOrderQuoteId=SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
                                  FOR XML PATH('')), 1, 1, '') PartDescription
                ) X1
                WHERE SQ.SalesOrderQuoteId = N.SalesOrderQuoteId
                GROUP BY SQ.SalesOrderQuoteId, X1.PartDescription
            ) PD
            OUTER APPLY (
                SELECT (CASE WHEN COUNT(SP.SalesOrderQuotePartId) > 1 THEN 'Multiple' ELSE X1.Manufacturer END) AS 'ManufacturerType', X1.Manufacturer
                FROM DBO.SalesOrderQuote SQ WITH (NOLOCK)
                LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
                OUTER APPLY (
                    SELECT STUFF((SELECT ', ' + MA.Name
                                  FROM DBO.SalesOrderQuote S WITH (NOLOCK)
                                  LEFT JOIN DBO.SalesOrderQuotePartV1 SP2 WITH (NOLOCK) ON S.SalesOrderQuoteId = SP2.SalesOrderQuoteId
                                  LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId = SP2.ItemMasterId
                                  LEFT JOIN DBO.Manufacturer MA WITH(NOLOCK) ON Im.ManufacturerId = MA.ManufacturerId
                                  WHERE S.SalesOrderQuoteId=SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
                                  FOR XML PATH('')), 1, 1, '') Manufacturer
                ) X1
                WHERE SQ.SalesOrderQuoteId = N.SalesOrderQuoteId
                GROUP BY SQ.SalesOrderQuoteId, X1.Manufacturer
            ) MF
            OUTER APPLY (
                SELECT (CASE WHEN COUNT(SP.SalesOrderQuotePartId) > 1 THEN 'Multiple' ELSE X1.PriorityDescription END) AS 'PriorityType', X1.PriorityDescription
                FROM DBO.SalesOrderQuote SQ WITH (NOLOCK)
                LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
                OUTER APPLY (
                    SELECT STUFF((SELECT ', ' + P.Description
                                  FROM DBO.SalesOrderQuotePartV1 S WITH (NOLOCK)
                                  LEFT JOIN DBO.[Priority] P WITH (NOLOCK) On P.PriorityId = S.PriorityId
                                  WHERE S.SalesOrderQuoteId = SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
                                  FOR XML PATH('')), 1, 1, '') PriorityDescription
                ) X1
                WHERE SQ.SalesOrderQuoteId = N.SalesOrderQuoteId
                GROUP BY SQ.SalesOrderQuoteId, X1.PriorityDescription
            ) PR
            OPTION (RECOMPILE);
        END

        SET @Step = @Step + 1;
    END

    /* Step 6 : result of the requested page (same columns / order as before) */
    SELECT M.SalesOrderQuoteId, M.SalesOrderQuoteNumber, M.OpenDate AS 'QuoteDate', M.CustomerId, UPPER(M.Name) 'CustomerName', UPPER(M.Status) 'Status',
           UPPER(X.VersionNumber) 'VersionNumber', ISNULL(X.SalesPrice, 0) AS 'QuoteAmount', M.IsNewVersionCreated, M.StatusId,
           UPPER(M.CustomerReference) 'CustomerReference', UPPER(X.PriorityDescription) 'Priority', UPPER(X.PriorityType) 'PriorityType', UPPER(M.SalesPerson) 'SalesPerson',
           UPPER(X.PartNumber) 'PartNumber', UPPER(X.PartNumberType) 'PartNumberType', UPPER(X.PartDescription) 'PartDescription', UPPER(X.PartDescriptionType) 'PartDescriptionType',
           UPPER(M.CustomerTypeName) 'CustomerType', UPPER(M.SalesOrderNumber) 'SalesOrderNumber',
           X.CreatedDate, X.UpdatedDate, P.Total AS 'NumberOfItems', UPPER(M.CreatedBy) 'CreatedBy', UPPER(M.UpdatedBy) 'UpdatedBy',
           UPPER(X.Manufacturer) 'Manufacturer', UPPER(X.ManufacturerType) 'ManufacturerType', M.NumberOfItemCount, M.SourceBy, M.MarketplaceRef
    FROM #Page P
    INNER JOIN #Base M ON M.RowId = P.RowId
    LEFT JOIN #Exp X ON X.SalesOrderQuoteId = M.SalesOrderQuoteId
    ORDER BY P.Seq;
     END  
   COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'SearchSOQViewData'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''  
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