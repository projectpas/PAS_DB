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
    1    04/08/2023  Ekta Chandegara    Convert text into uppercase
	2    06/26/2024  AMIT GHEDIYA       Added orderby for RequestedDate,EstimatedShipDate
	3    20-09-2024  Shrey Chandegara	ADD New Column in list (@ContractReference)
	4	 22-01-2025  Ayushi Patel		converted the date into utc (created , updated) , Added a case to get timeZone
	5	 10-04-2025  Vishal Suthar		Applied Optimization, Standard Formatting and Cleanup
	6	 25-04-2025  Bhargav Saliya		Customer Name Get from the SO table instead of the Customer table
	7    27-06-2025  Bhargav Saliya		Add New Fields @NumberOfItemCount 
	8    03-09-2025  AMIT GHEDIYA		Updated for filter issue (SalesQuoteNumber)
************************************************************************/ 
CREATE    PROCEDURE [dbo].[SearchSOViewData]    
	@PageNumber INT,
	@PageSize INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@StatusID INT,
	@GlobalFilter VARCHAR(50) = NULL,
	@SOQNumber VARCHAR(50) = NULL,
	@SalesOrderNumber VARCHAR(50) = NULL,
	@CustomerName VARCHAR(50) = NULL,
	@Status VARCHAR(50) = NULL,
	@QuoteAmount NUMERIC(18,4) = NULL,
	@SoAmount NUMERIC(18,4) = NULL,
	@QuoteDate DATETIME = NULL,
	@SalesPerson VARCHAR(50) = NULL,
	@PriorityType VARCHAR(50) = NULL,
	@PartNumberType VARCHAR(50) = NULL,
	@PartDescriptionType VARCHAR(50) = NULL,
	@CustomerReference VARCHAR(50) = NULL,
	@CustomerType VARCHAR(50) = NULL,
	@VersionNumber VARCHAR(50) = NULL,
	@CreatedDate DATETIME = NULL,
	@UpdatedDate  DATETIME = NULL,
	@CreatedBy  VARCHAR(50) = NULL,
	@UpdatedBy  VARCHAR(50) = NULL,
	@IsDeleted BIT = NULL,
	@MasterCompanyId int = NULL,
	@OpenDate DATETIME = NULL,
	@ShippedDate VARCHAR(50) = NULL,
	@RequestedDateType VARCHAR(50) = NULL,
	@EstimatedShipDateType VARCHAR(50) = NULL,
	@EmployeeId BIGINT,
	@ManufacturerType VARCHAR(50) = NULL,
	@ContractReference VARCHAR(50) = NULL,
	@NumberOfItemCount varchar(50)=null
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY    
  BEGIN TRANSACTION    
   BEGIN    
    DECLARE @RecordFrom int;  
	DECLARE @EmpLegalEntiyId BIGINT = 0;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(
		ETZ.[Description],  -- Prefer Employee's TimeZone description if available
		LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
	)
	FROM DBO.Employee E WITH (NOLOCK) 
	LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
	LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
	LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

    SET @RecordFrom = (@PageNumber - 1) * @PageSize;
    IF @IsDeleted IS NULL
    BEGIN
		SET @IsDeleted = 0
    END    
    
    IF @SortColumn IS NULL
    BEGIN    
		SET @SortColumn = UPPER('SalesOrderId')    
    END     
    ELSE    
    BEGIN     
		SET @SortColumn = UPPER(@SortColumn)    
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
	
    DECLARE @MSModuleID INT = 17; -- Sales Order Management Structure Module ID    
    
    ;WITH Main AS (    
      SELECT DISTINCT SO.SalesOrderId, SO.SalesOrderNumber, SOQ.SalesOrderQuoteNumber as 'SalesQuoteNumber',SO.ContractReference as ContractReference,     
      SOQ.VersionNumber, SO.OpenDate, SOQ.OpenDate AS 'QuoteDate', C.CustomerId,SO.CustomerName as [Name], SO.CustomerReference, C.CustomerCode, MST.Name as 'Status',    
      B.Cost,B.NetSales as 'SalesPrice',(E.FirstName+' '+E.LastName)as SalesPerson, SO.AccountTypeName CustomerTypeName, SO.ShippedDate, A.SoAmount,
	  (Cast(DBO.ConvertUTCtoLocal(SO.CreatedDate, @CurrntEmpTimeZoneDesc) as Date)) CreatedDate,
	  (Cast(DBO.ConvertUTCtoLocal(SO.UpdatedDate, @CurrntEmpTimeZoneDesc) as Date)) UpdatedDate,
	  SO.StatusId, SO.CreatedBy, SO.UpdatedBy,ISNULL(PartCount.ItemNo,0) AS NumberOfItemCount    
      FROM dbo.SalesOrder SO WITH (NOLOCK) Inner Join MasterSalesOrderStatus MST on SO.StatusId = MST.Id    
      INNER JOIN DBO.Customer C WITH (NOLOCK) on SO.CustomerId = C.CustomerId    
      LEFT JOIN DBO.Employee E WITH (NOLOCK) on  E.EmployeeId = SO.SalesPersonId   
      LEFT JOIN DBO.SalesOrderQuote SOQ WITH (NOLOCK) on SOQ.SalesOrderQuoteId = SO.SalesOrderQuoteId and SOQ.SalesOrderQuoteId is not Null    
      INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SO.SalesOrderId    
      INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId    
      INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId    
      OUTER APPLY (
       SELECT SUM(NetSaleAmount) AS SoAmount FROM DBO.SalesOrderPartCost WITH (NOLOCK)     
       WHERE SalesOrderId = SO.SalesOrderId    
      ) A    
      OUTER APPLY (    
       SELECT SUM(S.UnitCost) AS 'Cost', SUM(S.NetSaleAmount) AS 'NetSales' FROM DBO.SalesOrderPartCost S WITH (NOLOCK)    
       WHERE S.SalesOrderId = SO.SalesOrderId    
      ) B
	  OUTER APPLY (SELECT COUNT(SP.SalesOrderPartId) AS 'ItemNo' FROM DBO.SalesOrderPartV1 SP WITH(NOLOCK) WHERE SP.SalesOrderId = so.SalesOrderId GROUP BY SP.SalesOrderId) PartCount
	  WHERE (SO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SO.StatusId = @StatusID) AND SO.MasterCompanyId = @MasterCompanyId),    
      DatesCTE AS(    
       SELECT SO.SalesOrderId,     
       A.RequestedDate,    
       (CASE WHEN COUNT(SP.SalesOrderId) > 1 THEN 'Multiple' ELSE A.RequestedDate END) AS 'RequestedDateType',    
       A.PromisedDate,    
       A.EstimatedShipDate,    
       (CASE WHEN COUNT(SP.SalesOrderId) > 1 THEN 'Multiple' ELSE A.EstimatedShipDate END)  as 'EstimatedShipDateType'    
       from SalesOrder SO WITH (NOLOCK)    
       Left Join DBO.SalesOrderPartV1 SP WITH (NOLOCK) On SO.SalesOrderId = SP.SalesOrderId    
       Outer Apply(    
        SELECT     
           STUFF((SELECT ',' + CONVERT(VARCHAR, CustomerRequestDate, 101)--CAST(CustomerRequestDate as varchar)    
            FROM DBO.SalesOrderPartV1 S WITH (NOLOCK) Where S.SalesOrderId = SO.SalesOrderId    
            AND S.IsActive = 1 AND S.IsDeleted = 0    
            FOR XML PATH('')), 1, 1, '') RequestedDate,    
           STUFF((SELECT ',' + CONVERT(VARCHAR, PromisedDate, 101)--CAST(PromisedDate as varchar)    
            FROM DBO.SalesOrderPartV1 S WITH (NOLOCK) Where S.SalesOrderId = SO.SalesOrderId    
            AND S.IsActive = 1 AND S.IsDeleted = 0    
            FOR XML PATH('')), 1, 1, '') PromisedDate,    
           STUFF((SELECT ',' + CONVERT(VARCHAR, EstimatedShipDate, 101)--CAST(EstimatedShipDate as varchar)    
            FROM DBO.SalesOrderPartV1 S WITH (NOLOCK) Where S.SalesOrderId = SO.SalesOrderId    
            AND S.IsActive = 1 AND S.IsDeleted = 0    
            FOR XML PATH('')), 1, 1, '') EstimatedShipDate    
       ) A    
       WHERE ((SO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR so.StatusId = @StatusID))    
       AND SP.IsActive = 1 AND SP.IsDeleted = 0    
       GROUP BY SO.SalesOrderId, A.RequestedDate, A.PromisedDate, A.EstimatedShipDate    
      ),    
      PartCTE AS (    
      SELECT SO.SalesOrderId,(CASE WHEN COUNT(SP.SalesOrderId) > 1 THEN 'Multiple' ELSE A.PartNumber END) AS 'PartNumberType', A.PartNumber 
	  FROM DBO.SalesOrder SO WITH (NOLOCK)    
      LEFT JOIN DBO.SalesOrderPartV1 SP WITH (NOLOCK) On SO.SalesOrderId = SP.SalesOrderId    
      OUTER APPLY (    
       SELECT     
          STUFF((SELECT ',' + I.partnumber    
           FROM DBO.SalesOrderPartV1 S WITH (NOLOCK)    
           LEFT JOIN DBO.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId    
           WHERE S.SalesOrderId = SO.SalesOrderId    
           AND S.IsActive = 1 AND S.IsDeleted = 0    
           FOR XML PATH('')), 1, 1, '') PartNumber    
      ) A    
      WHERE ((SO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR so.StatusId = @StatusID))    
      AND SP.IsActive = 1 AND SP.IsDeleted = 0    
      GROUP BY SO.SalesOrderId, A.PartNumber    
      ),    
      PartDescCTE AS (
      SELECT SO.SalesOrderId, (CASE WHEN COUNT(SP.SalesOrderId) > 1 THEN 'Multiple' ELSE A.PartDescription END) AS 'PartDescriptionType', A.PartDescription 
	  FROM DBO.SalesOrder SO WITH (NOLOCK)    
      LEFT JOIN DBO.SalesOrderPartV1 SP WITH (NOLOCK) On SO.SalesOrderId = SP.SalesOrderId    
      OUTER APPLY (    
       SELECT     
          STUFF((SELECT ', ' + I.PartDescription    
           FROM DBO.SalesOrderPartV1 S WITH (NOLOCK)
           LEFT JOIN DBO.ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
           WHERE S.SalesOrderId = SO.SalesOrderId
           AND S.IsActive = 1 AND S.IsDeleted = 0
           FOR XML PATH('')), 1, 1, '') PartDescription
      ) A
      WHERE ((SO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SO.StatusId = @StatusID))
      AND SP.IsActive = 1 AND SP.IsDeleted = 0
      GROUP BY SO.SalesOrderId, A.PartDescription
      ), PartMFCTE AS (
      SELECT SO.SalesOrderId, (CASE WHEN COUNT(SP.SalesOrderId) > 1 THEN 'Multiple' ELSE A.Manufacturer END) AS 'ManufacturerType', A.Manufacturer
	  FROM DBO.SalesOrder SO WITH (NOLOCK)
      LEFT JOIN DBO.SalesOrderPartV1 SP WITH (NOLOCK) On SO.SalesOrderId = SP.SalesOrderId
      Outer Apply (
       SELECT
          STUFF((SELECT ',' + MA.Name
          FROM SalesOrder S WITH (NOLOCK)
          LEFT JOIN DBO.SalesOrderPartV1 SP WITH (NOLOCK) ON S.SalesOrderId = SP.SalesOrderId
	   	  LEFT JOIN ItemMaster IM WITH (NOLOCK) ON Im.ItemMasterId = SP.ItemMasterId
		  LEFT JOIN Manufacturer MA WITH(NOLOCK) ON Im.ManufacturerId = MA.ManufacturerId   
          WHERE S.SalesOrderId = SO.SalesOrderId    
          AND S.IsActive = 1 AND S.IsDeleted = 0    
          FOR XML PATH('')), 1, 1, '') Manufacturer    
      ) A    
      WHERE ((SO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SO.StatusId = @StatusID))    
      AND SP.IsActive = 1 AND SP.IsDeleted = 0    
      GROUP BY SO.SalesOrderId,A.Manufacturer), 
	  PriorityCTE AS(    
      SELECT SO.SalesOrderId, (CASE WHEN COUNT(SP.SalesOrderId) > 1 THEN 'Multiple' ELSE A.PriorityDescription END) AS 'PriorityType', A.PriorityDescription 
	  FROM SalesOrder SO WITH (NOLOCK)    
      LEFT JOIN DBO.SalesOrderPartV1 SP WITH (NOLOCK) ON SO.SalesOrderId = SP.SalesOrderId    
      OUTER APPLY (    
       SELECT     
          STUFF((SELECT ', ' + P.Description    
           FROM DBO.SalesOrderPartV1 S WITH (NOLOCK)    
           LEFT JOIN Priority P WITH (NOLOCK) ON P.PriorityId = S.PriorityId    
           WHERE S.SalesOrderId = SO.SalesOrderId    
           AND S.IsActive = 1 AND S.IsDeleted = 0    
           FOR XML PATH('')), 1, 1, '') PriorityDescription    
      ) A    
      WHERE ((SO.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SO.StatusId = @StatusID))    
      AND SP.IsActive = 1 AND SP.IsDeleted = 0    
      GROUP BY SO.SalesOrderId, A.PriorityDescription    
      ), Result AS (    
      SELECT M.SalesOrderId, SalesOrderNumber,M.SalesQuoteNumber AS 'SalesOrderQuoteNumber', M.QuoteDate AS 'QuoteDate',M.ContractReference, M.OpenDate AS 'OpenDate',M.CustomerId,M.Name as 'CustomerName',M.Status,    
         M.VersionNumber,IsNull(M.SalesPrice,0) as 'QuoteAmount', IsNull(M.Cost,0) AS 'Cost', M.StatusId, M.CustomerReference,    
         PR.PriorityDescription as 'Priority', PR.PriorityType, M.SalesPerson, PT.PartNumber, PT.PartNumberType, PD.PartDescription,    
         PD.PartDescriptionType,M.CustomerTypeName as 'CustomerType',IsNULL(M.SoAmount,0) as 'SoAmount',    
         D.RequestedDate, D.RequestedDateType, D.PromisedDate, D.EstimatedShipDate, D.EstimatedShipDateType,ShippedDate,MF.Manufacturer,MF.ManufacturerType,    
         M.CreatedDate,M.UpdatedDate,M.CreatedBy,M.UpdatedBy,m.NumberOfItemCount
      FROM Main M     
      LEFT JOIN PartCTE PT ON M.SalesOrderId = PT.SalesOrderId    
      LEFT JOIN PartDescCTE PD ON PD.SalesOrderId = M.SalesOrderId    
      LEFT JOIN PriorityCTE PR ON PR.SalesOrderId = M.SalesOrderId 
	  LEFT JOIN PartMFCTE MF ON MF.SalesOrderId = M.SalesOrderId 
      LEFT JOIN DatesCTE D ON D.SalesOrderId = M.SalesOrderId    
      WHERE (    
      (@GlobalFilter <>'' AND ((M.SalesQuoteNumber LIKE '%' +@GlobalFilter+'%' ) OR (M.SalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR    
        (M.SalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR    
        (M.ContractReference LIKE '%' +@GlobalFilter+'%') OR    
        (M.Name LIKE '%' +@GlobalFilter+'%') OR    
        (M.Status LIKE '%' +@GlobalFilter+'%') OR    
        (M.VersionNumber LIKE '%' +@GlobalFilter+'%') OR    
        (M.SalesPerson LIKE '%' +@GlobalFilter+'%') OR    
        (PR.PriorityType LIKE '%' +@GlobalFilter+'%') OR    
        (PT.PartNumberType LIKE '%' +@GlobalFilter+'%') OR    
        (PD.PartDescriptionType LIKE '%' +@GlobalFilter+'%') OR    
		(MF.ManufacturerType LIKE '%' +@GlobalFilter+'%') OR
        (M.CustomerReference LIKE '%' +@GlobalFilter+'%') OR    
        (M.CustomerTypeName LIKE '%' +@GlobalFilter+'%') OR     
        (M.CreatedBy LIKE '%' +@GlobalFilter+'%') OR    
        (M.UpdatedBy LIKE '%' +@GlobalFilter+'%') OR    
        (OpenDate LIKE '%' +@GlobalFilter+'%') OR    
        (M.ShippedDate LIKE '%' +@GlobalFilter+'%') OR    
        (D.RequestedDateType LIKE '%' +@GlobalFilter+'%') OR    
        (D.EstimatedShipDateType LIKE '%' +@GlobalFilter+'%')  OR
		(M.NumberOfItemCount LIKE '%' +@GlobalFilter+'%')
        ))    
        OR       
        (@GlobalFilter='' AND (ISNULL(@SOQNumber,'') ='' OR M.SalesQuoteNumber LIKE '%'+@SOQNumber+'%') AND     
        (ISNULL(@SalesOrderNumber,'') ='' OR M.SalesOrderNumber LIKE '%'+@SalesOrderNumber+'%') AND    
        (ISNULL(@ContractReference,'') ='' OR M.ContractReference LIKE '%'+@ContractReference+'%') AND    
        (ISNULL(@CustomerName,'') ='' OR M.Name LIKE '%'+ @CustomerName+'%') AND    
        (@QuoteAmount IS  NULL OR M.SalesPrice = @QuoteAmount) AND    
        (@SoAmount IS  NULL OR M.SoAmount = @SoAmount) AND    
        (@QuoteDate IS  NULL OR CAST(M.QuoteDate AS DATE) = CAST(@QuoteDate as date)) AND    
        (ISNULL(@SalesPerson,'') ='' OR M.SalesPerson LIKE '%'+@SalesPerson+'%') AND    
        (ISNULL(@PriorityType,'') ='' OR PR.PriorityType LIKE '%'+ @PriorityType+'%') AND    
        (ISNULL(@PartNumberType,'') ='' OR PT.PartNumberType LIKE '%'+@PartNumberType+'%') AND    
		(ISNULL(@ManufacturerType,'') ='' OR MF.ManufacturerType LIKE '%'+ @ManufacturerType+'%') AND  
        (ISNULL(@PartDescriptionType,'') ='' OR PD.PartDescriptionType LIKE '%'+@PartDescriptionType+'%') AND    
        (ISNULL(@CustomerReference,'') ='' OR M.CustomerReference LIKE '%'+@CustomerReference+'%') AND    
        (ISNULL(@CustomerType,'') ='' OR M.CustomerTypeName LIKE '%'+@CustomerType+'%') AND    
        (ISNULL(@VersionNumber,'') ='' OR M.VersionNumber LIKE '%'+@VersionNumber+'%') AND    
        (ISNULL(@CreatedBy,'') ='' OR M.CreatedBy LIKE '%'+@CreatedBy+'%') AND    
        (ISNULL(@UpdatedBy,'') ='' OR M.UpdatedBy LIKE '%'+@UpdatedBy+'%') AND    
        (ISNULL(@CreatedDate,'') ='' OR CAST(M.CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND    
        (ISNULL(@UpdatedDate,'') ='' OR CAST(M.UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)) AND    
        (ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND    
        (ISNULL(@ShippedDate,'') ='' OR CAST(M.ShippedDate AS DATE) = CAST(@ShippedDate AS DATE)) AND    
        (ISNULL(@RequestedDateType,'') ='' OR D.RequestedDateType LIKE '%'+@RequestedDateType+'%') AND    
        (ISNULL(@EstimatedShipDateType,'') ='' OR D.EstimatedShipDateType LIKE '%'+@EstimatedShipDateType+'%') and
		(ISNULL(@NumberOfItemCount,'') ='' OR M.NumberOfItemCount LIKE '%'+@NumberOfItemCount+'%'))    
        )    
      ), CTE_Count AS (SELECT COUNT(SalesOrderId) AS NumberOfItems FROM Result)    
      SELECT SalesOrderId, UPPER(SalesOrderNumber) 'SalesOrderNumber',UPPER(ContractReference) 'ContractReference', UPPER(SalesOrderQuoteNumber) 'SalesOrderQuoteNumber', UPPER(VersionNumber) 'VersionNumber', QuoteDate, OpenDate, CustomerId, UPPER(CustomerName) 'CustomerName', UPPER(CustomerReference) 'CustomerReference',    
      UPPER(Priority) 'Priority',UPPER(PriorityType) 'PriorityType', QuoteAmount, Cost, RequestedDate, RequestedDateType, EstimatedShipDate, EstimatedShipDateType, PromisedDate,    
      ShippedDate,UPPER(Manufacturer) 'Manufacturer',UPPER(ManufacturerType) 'ManufacturerType', UPPER(SalesPerson) 'SalesPerson', UPPER(Status) 'Status', StatusId    
      ,UPPER(PartNumber) 'PartNumber', UPPER(PartNumberType) 'PartNumberType',UPPER(PartDescription) 'PartDescription',UPPER(PartDescriptionType) 'PartDescriptionType',    
      CreatedDate, UpdatedDate, NumberOfItems, UPPER(CreatedBy) 'CreatedBy', UPPER(UpdatedBy) 'UpdatedBy',NumberOfItemCount FROM Result,CTE_Count    
      ORDER BY      
      CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERID')  THEN SalesOrderId END DESC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='CONTRACTREFERENCE')  THEN ContractReference END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='SOAMOUNT')  THEN SoAmount END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,    
      CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
	  CASE WHEN (@SortOrder=1 and @SortColumn='REQUESTEDDATETYPE')  THEN RequestedDateType END ASC,  
	  CASE WHEN (@SortOrder=1 and @SortColumn='ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END ASC,
	  CASE WHEN (@SortOrder=1 and @SortColumn='NUMBEROFITEMCOUNT')  THEN NumberOfItemCount END ASC,

      CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END Desc,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END Desc,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END Desc,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END Desc,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END Desc,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='CONTRACTREFERENCE')  THEN ContractReference END Desc,    
      CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END Desc,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerType')  THEN ManufacturerType END Desc,
      CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END Desc,    
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
	  CASE WHEN (@SortOrder=-1 and @SortColumn='REQUESTEDDATETYPE')  THEN RequestedDateType END DESC,
	  CASE WHEN (@SortOrder=-1 and @SortColumn='ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END DESC, 
	  CASE WHEN (@SortOrder=-1 and @SortColumn='NUMBEROFITEMCOUNT')  THEN NumberOfItemCount END DESC 

      OFFSET @RecordFrom ROWS     
      FETCH NEXT @PageSize ROWS ONLY    
     END    
   COMMIT  TRANSACTION    
    
  END TRY        
  BEGIN CATCH          
   IF @@trancount > 0    
    PRINT 'ROLLBACK'    
    ROLLBACK TRAN;    
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
              , @AdhocComments     VARCHAR(150)    = 'SearchSOViewData'     
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