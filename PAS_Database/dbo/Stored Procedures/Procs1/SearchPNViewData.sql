/*************************************************************             
 ** File:   [SearchPNViewData]             
 ** Author:    
 ** Description: Get Search Data for PN View  
 ** Purpose:           
 ** Date:     
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author             Change Description              
 ** --   --------     -------			 --------------------------------            
    1    07/08/2023   Ekta Chandegra     Convert text into uppercase
	2	 11/04/2024	  Vishal Suthar		 Modified to make use of new SO Part tables
	3	 23-Jan-2025  Ayushi Patel		 converted the date into utc (created , updated) , Added a case to get timeZone
	4	 12-Mar-2025  Vishal Suthar		 Modified default sort column to SalesOrderQuoteId
	5	 09-APR-2025  Vishal Suthar		 Applied Optimization, Standard Formatting and Cleanup
	6    27-06-2025  Bhargav Saliya		Add New Fields @NumberOfItemCount and set Group By
	7    15-07-2025  Rajesh Gami		Fixed: Getting proper status as shown as in header
	8    13-08-2025  Rajesh Gami		 Add New Parameters @SourceBy,@MarketplaceRef And as same as for Return
    9    24-09-2025  Sahdev Saliya       Added New Dropdown Filter Lead Source
	10   20-11-2025  Rajesh Gami		 Correct the QuoteAmount
	11   16-Apr-026  Bhargav Saliya	     UOM Changes
	12   21-MAY-2026  Rajesh Gami		 PN-16508 : Fix the duplicate issue when Single SOQ have muliple SO Converted
**************************************************************/ 
CREATE PROCEDURE [dbo].[SearchPNViewData]  
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
 @QuoteAmount numeric(18,6)=null,  
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
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
    DECLARE @RecordFrom int;  
	--DECLARE @EmpLegalEntiyId BIGINT = 0;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	--SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

    SET @RecordFrom = (@PageNumber-1)*@PageSize;  
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
		SET @SortColumn = UPPER(@SortColumn)  
    End  
  
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
	
	IF @SourceByName = 'All'
    BEGIN
		SET @SourceByName = NULL
    END
  
    If @Status = '0'  
    BEGIN  
		SET @Status = NULL  
    END  
    DECLARE @MSModuleID INT = 18; -- Sales Order Quote Management Structure Module ID
	   
	IF OBJECT_ID(N'tempdb..#tmpSOPartTblData') IS NOT NULL
	BEGIN
		DROP TABLE #tmpSOPartTblData
	END
	IF OBJECT_ID(N'tempdb..#tmpSOPartTblDataFinal') IS NOT NULL
	BEGIN
		DROP TABLE #tmpSOPartTblDataFinal
	END

   ;WITH Result AS (
    SELECT DISTINCT SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,SOQ.OpenDate AS 'QuoteDate',SOQ.CustomerId,SOQ.CustomerName AS 'CustomerName', MST.Name AS 'Status', ([dbo].[fn_ConvertUOM](ISNULL(SPC.NetSaleAmount, 0),IM.[StockUnitOfMeasure] ,IM.[ConsumeUnitOfMeasure],0,@MasterCompanyId)) AS 'QuoteAmount',  
	SOQ.IsNewVersionCreated,SOQ.StatusId,SOQ.CustomerReference,IsNull(SP.PriorityName,'') AS 'Priority',ISNULL(SP.PriorityName, '') AS 'PriorityType', (E.FirstName + ' ' + E.LastName) AS SalesPerson,  
    ISNULL(IM.partnumber,'') AS 'PartNumber',M.Name AS 'ManufacturerType',IsNull(IM.partnumber,'') AS 'PartNumberType', ISNULL(im.PartDescription, '') AS 'PartDescription', ISNULL(im.PartDescription, '') AS 'PartDescriptionType',  
    SOQ.AccountTypeName AS 'CustomerType',
	(
    SELECT TOP 1 SO.SalesOrderNumber
    FROM DBO.SalesOrder SO WITH (NOLOCK) INNER JOIN DBO.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId 
    WHERE SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId AND SOP.ConditionId = SP.ConditionId AND SOP.ItemMasterId = SP.ItemMasterId
) AS SalesOrderNumber,
--SO.SalesOrderNumber,
	(CAST(DBO.ConvertUTCtoLocal(SOQ.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) CreatedDate,
	(CAST(DBO.ConvertUTCtoLocal(SOQ.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) UpdatedDate,
	SOQ.UpdatedBy, SOQ.CreatedBy,SOQ.IsDeleted,dbo.GenearteVersionNumber(SOQ.Version) as 'VersionNumber',ISNULL(count(SP.SalesOrderQuotePartId),0) AS NumberOfItemCount,
	  CASE WHEN ISNULL(SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END SourceBy, 
	  ISNULL(SOQ.MarketplaceRef,'') MarketplaceRef,
	  SP.SalesOrderQuotePartId,
	  SP.QtyQuoted,SP.QtyRequested,SP.UnitSalesPrice MainUnitSalesPrice
    FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)  
	INNER JOIN DBO.MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId = MST.Id
    LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = SP.SalesOrderQuoteId and SP.IsDeleted = 0  
    LEFT JOIN DBO.SalesOrderQuotePartCost SPC WITH (NOLOCK) ON SPC.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
    LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON Im.ItemMasterId=SP.ItemMasterId  
    LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
  LEFT JOIN DBO.Employee E WITH (NOLOCK) ON E.EmployeeId=SOQ.SalesPersonId --and SOQ.SalesPersonId is not null  
 --LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null  AND SOP.SalesOrderId = SO.SalesOrderId
	
    INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId  
    INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId  
    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
	--OUTER APPLY (SELECT COUNT(SP.SalesOrderQuoteId) AS 'ItemNo' FROM DBO.SalesOrderQuotePartV1 SP WITH(NOLOCK) WHERE SOQ.SalesOrderQuoteId = SP.SalesOrderQuoteId GROUP BY SP.SalesOrderQuoteId) PartCount
    WHERE (SOQ.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SOQ.StatusId = @StatusID) AND (@SourceByName IS NULL OR CASE WHEN ISNULL(SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END = @SourceByName) AND SOQ.MasterCompanyId = @MasterCompanyId
	GROUP BY SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,SOQ.OpenDate,SOQ.CustomerId,SOQ.CustomerName, SOQ.StatusName, SPC.NetSaleAmount,  
	SOQ.IsNewVersionCreated,SOQ.StatusId,SOQ.CustomerReference,Priority,SP.PriorityName,E.FirstName, E.LastName,
    IM.partnumber,M.Name,IM.partnumber, im.PartDescription, im.PartDescription,  
    SOQ.AccountTypeName, SOQ.CreatedDate, SOQ.UpdatedDate,MST.Name,SP.ConditionId, SP.ItemMasterId,
	SOQ.UpdatedBy, SOQ.CreatedBy,SOQ.IsDeleted,SOQ.Version, SOQ.SourceBy, SOQ.MarketplaceRef,SP.SalesOrderQuotePartId,SP.QtyQuoted,SP.QtyRequested,SP.UnitSalesPrice,IM.[StockUnitOfMeasure],IM.[ConsumeUnitOfMeasure])
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

     SELECT SalesOrderQuoteId,UPPER(SalesOrderQuoteNumber) 'SalesOrderQuoteNumber',QuoteDate,CustomerId,UPPER(CustomerName) 'CustomerName',UPPER(Status) 'Status',UPPER(VersionNumber) 'VersionNumber',isnull(QuoteAmount,0) AS QuoteAmount,IsNewVersionCreated,StatusId  
     ,UPPER(CustomerReference) 'CustomerReference',UPPER(Priority) 'Priority',UPPER(PriorityType) 'PriorityType',UPPER(SalesPerson) 'SalesPerson',UPPER(PartNumber) 'PartNumber',UPPER(ManufacturerType) 'ManufacturerType',UPPER(PartNumberType) 'PartNumberType',UPPER(PartDescription) 'PartDescription',UPPER(PartDescriptionType) 'PartDescriptionType',UPPER(CustomerType) 'CustomerType',UPPER(SalesOrderNumber) 'SalesOrderNumber',  
     CreatedDate,UpdatedDate, UPPER(CreatedBy) 'CreatedBy',UPPER(UpdatedBy) 'UpdatedBy', NumberOfItemCount,SourceBy,MarketplaceRef,SalesOrderQuotePartId,QtyQuoted,QtyRequested,MainUnitSalesPrice,
	 (SELECT COUNT(*) FROM FinalResult) AS NumberOfItems INTO #tmpSOPartTblData FROM FinalResult
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
	  CASE WHEN (@SortOrder=1 and @SortColumn='MarketplaceRef')  THEN MarketplaceRef END ASC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='MarketplaceRef')  THEN MarketplaceRef END DESC  
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
       
	  /****** Total Part Wise COST Calculation (Quote Amount)******/
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
	
	 /****** Final Table Return Logic*******/
		SELECT 
			main.*,
			(((main.QtyRequested - ISNULL(c.TotalQtyQuoted, 0)) * ISNULL(main.MainUnitSalesPrice, 0))
			  + ISNULL(c.TotalNetSalePriceExtended, 0)) AS TotalPartCost
			  INTO #tmpSOPartTblDataFinal
		FROM #tmpSOPartTblData main
		LEFT JOIN CTE_Cost c ON main.SalesOrderQuotePartId = c.SalesOrderQuotePartId;

		Update #tmpSOPartTblDataFinal SET QuoteAmount = ISNULL(TotalPartCost ,0)
		SELECT * FROM #tmpSOPartTblDataFinal
    END  
   COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
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