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
	6    27-06-2025  Bhargav Saliya		Add New Fields @NumberOfItemCount 
**************************************************************/ 
CREATE    PROCEDURE [dbo].[SearchSOQViewData]
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
 @NumberOfItemCount varchar(50)=null
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

    DECLARE @MSModuleID INT = 18; -- Sales Order Quote Management Structure Module ID  
    ;With Main AS (
      Select DISTINCT SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,
	  SOQ.OpenDate,
	  SOQ.CustomerId, SOQ.CustomerName Name, SOQ.CustomerCode CustomerCode, MST.Name AS 'Status',  
      B.Cost, B.NetSales AS 'SalesPrice', (E.FirstName + ' ' + E.LastName) AS SalesPerson, SOQ.AccountTypeName CustomerTypeName, SO.SalesOrderNumber,  
      A.SoAmount,
	  (Cast(DBO.ConvertUTCtoLocal(SOQ.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) CreatedDate,
	  (Cast(DBO.ConvertUTCtoLocal(SOQ.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) UpdatedDate,
	  SOQ.StatusId,SOQ.CreatedBy,SOQ.UpdatedBy,  
      dbo.GenearteVersionNumber(SOQ.Version) AS 'VersionNumber',SOQ.IsNewVersionCreated,SOQ.CustomerReference,ISNULL(PartCount.Items,0) AS NumberOfItemCount
      FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK) INNER JOIN MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId = MST.Id
	  LEFT JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
	  LEFT JOIN DBO.SalesOrderPartV1 SP WITH (NOLOCK) ON SOQP.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
      LEFT JOIN DBO.Employee E WITH (NOLOCK) ON E.EmployeeId = SOQ.SalesPersonId
      LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId AND SO.SalesOrderQuoteId IS NOT NULL
      INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
      INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
      INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
      OUTER APPLY(
       SELECT SUM(SOPC.NetSaleAmount) AS SoAmount FROM DBO.SalesOrderPartV1 SOP WITH (NOLOCK)
	   INNER JOIN DBO.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
	   INNER JOIN DBO.SalesOrderQuotePartV1 SOQP WITH (NOLOCK) ON SOQP.SalesOrderQuotePartId = SOP.SalesOrderQuotePartId
       Where SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
      ) A
      OUTER APPLY (
       SELECT SUM(SOC.UnitCost) AS 'Cost', SUM(SOC.NetSaleAmount) AS 'NetSales' FROM DBO.SalesOrderQuotePartV1 S WITH (NOLOCK)
	   INNER JOIN DBO.SalesOrderQuotePartCost SOC WITH (NOLOCK) ON S.SalesOrderQuotePartId = SOC.SalesOrderQuotePartId
       Where S.SalesOrderQuoteId=SOQ.SalesOrderQuoteId
      ) B
	  OUTER APPLY(SELECT count(SalesOrderQuotePartId) as 'Items' FROM [dbo].[SalesOrderQuotePartV1] soqv1 with(nolock) where soqv1.SalesOrderQuoteId = SOQ.SalesOrderQuoteId GROUP BY soqv1.SalesOrderQuoteId) PartCount
      WHERE (SOQ.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SOQ.StatusId = @StatusID) AND SOQ.MasterCompanyId = @MasterCompanyId), PartCTE AS (  
      SELECT SQ.SalesOrderQuoteId,(CASE WHEN Count(SP.SalesOrderQuotePartId) > 1 THEN 'Multiple' ELSE A.PartNumber END)  AS 'PartNumberType',A.PartNumber FROM DBO.SalesOrderQuote SQ WITH (NOLOCK)  
      LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) On SQ.SalesOrderQuoteId = SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0  
      OUTER APPLY (  
       SELECT   
          STUFF((SELECT ',' + I.partnumber  
           FROM DBO.SalesOrderQuotePartV1 S WITH (NOLOCK)  
           LEFT JOIN DBO.ItemMaster I WITH (NOLOCK) On S.ItemMasterId = I.ItemMasterId  
           WHERE S.SalesOrderQuoteId = SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
           FOR XML PATH('')), 1, 1, '') PartNumber
      ) A  
      WHERE ((SQ.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR sq.StatusId = @StatusID))  
      GROUP BY SQ.SalesOrderQuoteId, A.PartNumber  
      ),
	  PartMFCTE AS(  
      SELECT SQ.SalesOrderQuoteId,(CASE WHEN COUNT(SP.SalesOrderQuotePartId) > 1 THEN 'Multiple' ELSE A.Manufacturer END) AS 'ManufacturerType', A.Manufacturer FROM DBO.SalesOrderQuote SQ WITH (NOLOCK)
      LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
      OUTER APPLY (  
       SELECT   
        STUFF((SELECT ', ' + MA.Name
        FROM DBO.SalesOrderQuote S WITH (NOLOCK)  
        LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) ON S.SalesOrderQuoteId = SP.SalesOrderQuoteId
		LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId = SP.ItemMasterId  
		LEFT JOIN DBO.Manufacturer MA WITH(NOLOCK) ON Im.ManufacturerId = MA.ManufacturerId
        WHERE S.SalesOrderQuoteId=SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0  
        FOR XML PATH('')), 1, 1, '') Manufacturer  
      ) A  
      WHERE ((SQ.IsDeleted=@IsDeleted) AND (@StatusID IS NULL OR SQ.StatusId=@StatusID))  
      GROUP BY SQ.SalesOrderQuoteId,A.Manufacturer  
      ),PartDescCTE AS (  
      SELECT SQ.SalesOrderQuoteId, (CASE WHEN COUNT(SP.SalesOrderQuotePartId) > 1 THEN 'Multiple' ELSE A.PartDescription END) AS 'PartDescriptionType', A.PartDescription FROM DBO.SalesOrderQuote SQ WITH (NOLOCK)  
      LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) On SQ.SalesOrderQuoteId = SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0  
      OUTER APPLY (  
       SELECT   
          STUFF((SELECT ', ' + I.PartDescription  
           FROM DBO.SalesOrderQuotePartV1 S WITH (NOLOCK)  
           LEFT JOIN DBO.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
           Where S.SalesOrderQuoteId=SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0  
           FOR XML PATH('')), 1, 1, '') PartDescription  
      ) A  
      WHERE ((SQ.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SQ.StatusId = @StatusID))  
      GROUP BY SQ.SalesOrderQuoteId,A.PartDescription  
      ), PriorityCTE AS (  
      SELECT SQ.SalesOrderQuoteId,(CASE WHEN COUNT(SP.SalesOrderQuotePartId) > 1 THEN 'Multiple' ELSE A.PriorityDescription END) AS 'PriorityType', A.PriorityDescription FROM DBO.SalesOrderQuote SQ WITH (NOLOCK)  
      LEFT JOIN DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
      OUTER APPLY (  
       SELECT   
          STUFF((SELECT ', ' + P.Description  
           FROM DBO.SalesOrderQuotePartV1 S WITH (NOLOCK)  
           LEFT JOIN DBO.[Priority] P WITH (NOLOCK) On P.PriorityId = S.PriorityId  
           WHERE S.SalesOrderQuoteId = SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0  
           FOR XML PATH('')), 1, 1, '') PriorityDescription  
      ) A  
      WHERE ((SQ.IsDeleted = @IsDeleted) AND (@StatusID IS NULL OR SQ.StatusId = @StatusID))   
      GROUP BY SQ.SalesOrderQuoteId,A.PriorityDescription  
      ),Result AS (  
      SELECT M.SalesOrderQuoteId,M.SalesOrderQuoteNumber,M.OpenDate as 'QuoteDate',M.CustomerId,M.Name as 'CustomerName',M.Status,  
         M.VersionNumber,IsNull(M.SalesPrice,0) as 'QuoteAmount',M.IsNewVersionCreated,M.StatusId,M.CustomerReference,  
         PR.PriorityDescription as 'Priority',PR.PriorityType,M.SalesPerson,PT.PartNumber,PT.PartNumberType,PD.PartDescription,  
         PD.PartDescriptionType,M.CustomerTypeName as 'CustomerType',M.SalesOrderNumber,IsNULL(M.SoAmount,0) as 'SoAmount',M.CreatedDate,  
         M.UpdatedDate,M.CreatedBy,M.UpdatedBy,MF.Manufacturer,MF.ManufacturerType,M.NumberOfItemCount   
         FROM Main M   
      LEFT JOIN PartCTE PT On M.SalesOrderQuoteId=PT.SalesOrderQuoteId  
      LEFT JOIN PartDescCTE PD on PD.SalesOrderQuoteId=M.SalesOrderQuoteId  
	  LEFT JOIN PartMFCTE MF on MF.SalesOrderQuoteId=M.SalesOrderQuoteId
      LEFT JOIN PriorityCTE PR on PR.SalesOrderQuoteId=M.SalesOrderQuoteId  
      WHERE (
      (@GlobalFilter <>'' AND ((M.SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (M.SalesOrderNumber like '%' +@GlobalFilter+'%') OR  
        (M.SalesOrderNumber like '%' +@GlobalFilter+'%') OR  
        (M.Name like '%' +@GlobalFilter+'%') OR  
        (M.Status like '%' +@GlobalFilter+'%') OR  
        (M.VersionNumber like '%' +@GlobalFilter+'%') OR  
        (M.SalesPerson like '%' +@GlobalFilter+'%') OR
		(MF.ManufacturerType like '%' +@GlobalFilter+'%') OR
        (PR.PriorityType like '%' +@GlobalFilter+'%') OR  
        (PT.PartNumberType like '%' +@GlobalFilter+'%') OR  
        (PD.PartDescriptionType like '%' +@GlobalFilter+'%') OR  
        (M.CustomerReference like '%' +@GlobalFilter+'%') OR  
        (M.CustomerTypeName like '%' +@GlobalFilter+'%') OR   
        (M.CreatedBy like '%' +@GlobalFilter+'%') OR  
        (M.UpdatedBy like '%' +@GlobalFilter+'%') OR
		(M.NumberOfItemCount like '%' +@GlobalFilter+'%')
        ))  
        OR     
        (@GlobalFilter='' AND (ISNULL(@SOQNumber,'') ='' OR M.SalesOrderQuoteNumber LIKE '%'+@SOQNumber+'%') AND
        (ISNULL(@SalesOrderNumber,'') = '' OR M.SalesOrderNumber LIKE '%'+@SalesOrderNumber+'%') AND
        (ISNULL(@CustomerName,'') = '' OR M.Name LIKE '%'+ @CustomerName+'%') AND  
        (ISNULL(@Status,'') = ''  OR M.Status LIKE '%'+@Status+'%') AND  
        (@QuoteAmount IS  NULL OR M.SalesPrice=@QuoteAmount) AND  
        (@SoAmount IS  NULL OR M.SoAmount=@SoAmount) AND  
        (@QuoteDate IS  NULL OR Cast(M.OpenDate AS DATE) = Cast(@QuoteDate AS DATE)) AND 
        (ISNULL(@SalesPerson,'') ='' OR M.SalesPerson LIKE '%'+@SalesPerson+'%') AND  
        (ISNULL(@PriorityType,'') ='' OR PR.PriorityType LIKE '%'+ @PriorityType+'%') AND  
        (ISNULL(@PartNumberType,'') ='' OR PT.PartNumberType LIKE '%'+@PartNumberType+'%') AND  
        (ISNULL(@PartDescriptionType,'') ='' OR PD.PartDescriptionType LIKE '%'+@PartDescriptionType+'%') AND  
        (ISNULL(@CustomerReference,'') ='' OR M.CustomerReference LIKE '%'+@CustomerReference+'%') AND  
        (ISNULL(@CustomerType,'') ='' OR M.CustomerTypeName LIKE '%'+@CustomerType+'%') AND  
		(ISNULL(@ManufacturerType,'') ='' OR MF.ManufacturerType LIKE '%'+@ManufacturerType+'%') AND  
        (ISNULL(@VersionNumber,'') ='' OR M.VersionNumber LIKE '%'+@VersionNumber+'%') AND  
        (ISNULL(@CreatedBy,'') ='' OR M.CreatedBy LIKE '%'+@CreatedBy+'%') AND  
        (ISNULL(@UpdatedBy,'') ='' OR M.UpdatedBy LIKE '%'+@UpdatedBy+'%') AND  
        (ISNULL(@CreatedDate,'') ='' OR Cast(M.CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND  
        (ISNULL(@UpdatedDate,'') ='' OR Cast(M.UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) AND
		(ISNULL(@NumberOfItemCount,'') ='' OR M.NumberOfItemCount LIKE '%'+@NumberOfItemCount+'%'))  
        )), CTE_Count AS (SELECT COUNT(SalesOrderQuoteId) AS NumberOfItems FROM Result)  
      SELECT SalesOrderQuoteId,SalesOrderQuoteNumber,QuoteDate,CustomerId,UPPER(CustomerName) 'CustomerName',UPPER(Status) 'Status',UPPER(VersionNumber) 'VersionNumber',QuoteAmount,IsNewVersionCreated,StatusId  
      ,UPPER(CustomerReference) 'CustomerReference',UPPER(Priority) 'Priority',UPPER(PriorityType) 'PriorityType',UPPER(SalesPerson) 'SalesPerson',UPPER(PartNumber) 'PartNumber',UPPER(PartNumberType) 'PartNumberType',UPPER(PartDescription) 'PartDescription',UPPER(PartDescriptionType) 'PartDescriptionType',UPPER(CustomerType) 'CustomerType',UPPER(SalesOrderNumber) 'SalesOrderNumber',  
      CreatedDate,UpdatedDate,NumberOfItems,UPPER(CreatedBy) 'CreatedBy',UPPER(UpdatedBy) 'UpdatedBy',UPPER(Manufacturer) 'Manufacturer',UPPER(ManufacturerType) 'ManufacturerType',NumberOfItemCount FROM Result,CTE_Count  
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