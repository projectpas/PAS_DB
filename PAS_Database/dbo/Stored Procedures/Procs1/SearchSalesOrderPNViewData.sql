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
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    04/08/2023  Ekta Chandegara	Convert text into uppercase
	2    06/26/2024  AMIT GHEDIYA		Added orderby for RequestedDate,EstimatedShipDate
	3    20-09-2024  Shrey Chandegara	ADD New Column in list (@ContractReference)
	4	 22-01-2025  Ayushi Patel		converted the date into utc (created , updated) , Added a case to get timeZone
	5	 10-04-2025  Vishal Suthar		Applied Optimization, Standard Formatting and Cleanup

************************************************************************/  
CREATE   PROCEDURE [dbo].[SearchSalesOrderPNViewData]  
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
	@OpenDate datetime=null,  
	@QuoteDate datetime=null,  
	@ShippedDate datetime=null,  
	@SalesPerson varchar(50)=null,  
	@PriorityType varchar(50)=null,  
	@RequestedDateType varchar(50)=null,  
	@EstimatedShipDateType varchar(50)=null,  
	@PartNumberType varchar(50)=null,  
	@PartDescriptionType varchar(50)=null,  
	@CustomerReference varchar(50)=null,  
	@CustomerType varchar(50)=null,  
	@VersionNumber varchar(50)=null,  
	@CreatedDate datetime=null,  
	@UpdatedDate  datetime=null,  
	@IsDeleted bit = null,  
	@CreatedBy varchar(50)=null,  
	@UpdatedBy varchar(50)=null,  
	@MasterCompanyId int = null,  
	@EmployeeId bigint ,
	@ManufacturerType varchar(50)=null,
	@ContractReference varchar(50)=null
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
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description],  -- Prefer Employee's TimeZone description if available
			LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
	FROM dbo.Employee E WITH (NOLOCK) 
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
		SET @SortColumn = Upper('CreatedDate')  
    END   
    ELSE  
    BEGIN   
		SET @SortColumn = Upper(@SortColumn)  
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
   
	;WITH Result AS(  
    SELECT DISTINCT SO.SalesOrderId, SO.SalesOrderNumber, SOQ.SalesOrderQuoteNumber, SO.OpenDate as 'OpenDate',SO.ContractReference as ContractReference,   
    SOQ.OpenDate as 'QuoteDate'  
    , SO.CustomerId, SO.CustomerName as 'CustomerName', MST.Name as 'Status', ISNULL(SPC.NetSaleAmount, 0) as 'QuoteAmount',  
    ISNULL(SPC.UnitCost, 0) as 'UnitCost', ISNULL(SP.CustomerRequestDate, '0001-01-01') as 'RequestedDate', ISNULL(SP.CustomerRequestDate, '0001-01-01') as 'RequestedDateType', SO.StatusId, SO.CustomerReference, IsNull(SP.PriorityName, '') as 'Priority', IsNull(SP.PriorityName, '') as 'PriorityType', (E.FirstName+' '+E.LastName)as SalesPerson,  
    IsNull(IM.partnumber,'') as 'PartNumber',M.Name As 'ManufacturerType', IsNull(IM.partnumber,'') as 'PartNumberType', IsNull(im.PartDescription,'') as 'PartDescription', IsNull(im.PartDescription,'') as 'PartDescriptionType',  
	(Cast(DBO.ConvertUTCtoLocal(SO.CreatedDate, @CurrntEmpTimeZoneDesc) as Date)) CreatedDate,
	(Cast(DBO.ConvertUTCtoLocal(SO.UpdatedDate, @CurrntEmpTimeZoneDesc) as Date)) UpdatedDate,
	SO.UpdatedBy, SO.CreatedBy, ISNULL(SP.EstimatedShipDate, '0001-01-01') as 'EstimatedShipDate', ISNULL(SP.EstimatedShipDate, '0001-01-01') as 'EstimatedShipDateType', ISNULL(SP.PromisedDate, '0001-01-01') as 'PromisedDate',  
    ISNULL(SO.ShippedDate, '0001-01-01') as 'ShippedDate',   
    SO.IsDeleted, SOQ.VersionNumber  
    FROM DBO.SalesOrder SO WITH (NOLOCK)
    INNER JOIN DBO.MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SO.StatusId = MST.Id
    LEFT JOIN DBO.SalesOrderPartV1 SP WITH (NOLOCK) on SO.SalesOrderId = SP.SalesOrderId and SP.IsDeleted = 0
    LEFT JOIN DBO.SalesOrderPartCost SPC WITH (NOLOCK) on SPC.SalesOrderPartId = SP.SalesOrderPartId
    LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId = SP.ItemMasterId
    LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
    LEFT JOIN DBO.Employee E WITH (NOLOCK) on  E.EmployeeId = SO.SalesPersonId
    LEFT JOIN DBO.SalesOrderQuote SOQ WITH (NOLOCK) on SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
    INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SO.SalesOrderId
    INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
    WHERE (SO.IsDeleted = @IsDeleted) and (@StatusID is null or SO.StatusId = @StatusID)
    AND SO.MasterCompanyId = @MasterCompanyId
    GROUP BY SO.SalesOrderId, SalesOrderNumber, SalesOrderQuoteNumber, SO.OpenDate,SO.ContractReference, SOQ.OpenDate, SO.CustomerId, SO.CustomerName,
    MST.Name, SPC.NetSaleAmount, SPC.UnitCost, SP.CustomerRequestDate, SO.StatusId, SO.CustomerReference,
    SP.PriorityName, E.FirstName, E.LastName, IM.partnumber,M.Name, IM.PartDescription, SOQ.VersionNumber,
    SO.CreatedDate, SO.UpdatedDate, SO.UpdatedBy, SO.CreatedBy, SP.EstimatedShipDate, SP.PromisedDate, SO.ShippedDate, SO.IsDeleted, SO.Version),
    FinalResult AS (
    SELECT SalesOrderId, SalesOrderNumber, SalesOrderQuoteNumber, VersionNumber, OpenDate,ContractReference, CustomerId, CustomerName, CustomerReference, Priority,
      PriorityType, QuoteAmount, UnitCost, RequestedDate, RequestedDateType, QuoteDate, EstimatedShipDate, EstimatedShipDateType, PromisedDate,
      ShippedDate, SalesPerson, Status, StatusId, PartNumber,ManufacturerType, PartNumberType, PartDescription, PartDescriptionType,
      CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result
    WHERE (
     (@GlobalFilter <>'' AND ((SalesOrderQuoteNumber LIKE '%' +@GlobalFilter+'%' ) OR
       (SalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR
       (OpenDate LIKE '%' +@GlobalFilter+'%') OR
       (ContractReference LIKE '%' +@GlobalFilter+'%') OR
       (CustomerName LIKE '%' +@GlobalFilter+'%') OR
       (SalesPerson LIKE '%' +@GlobalFilter+'%') OR 
       (@VersionNumber LIKE '%'+@GlobalFilter+'%') OR
       (CustomerReference LIKE '%' +@GlobalFilter+'%') OR
       (PriorityType LIKE '%' +@GlobalFilter+'%') OR
       (RequestedDateType LIKE '%' +@GlobalFilter+'%') OR  
       (QuoteDate LIKE '%' +@GlobalFilter+'%') OR
       (EstimatedShipDateType LIKE '%' +@GlobalFilter+'%') OR
       (ShippedDate LIKE '%' +@GlobalFilter+'%') OR
       (PromisedDate LIKE '%' +@GlobalFilter+'%') OR
       (PartNumberType LIKE '%' +@GlobalFilter+'%') OR
	    (ManufacturerType LIKE '%' +@GlobalFilter+'%') OR
       (PartDescriptionType LIKE '%' +@GlobalFilter+'%') OR
       (CreatedDate LIKE '%' +@GlobalFilter+'%') OR
       (UpdatedDate LIKE '%' +@GlobalFilter+'%') OR
       (Status LIKE '%' +@GlobalFilter+'%')
       ))
       OR
       (@GlobalFilter='' AND (ISNULL(@SOQNumber,'') ='' OR SalesOrderQuoteNumber LIKE  '%'+ @SOQNumber+'%') AND
       (ISNULL(@SalesOrderNumber,'') ='' OR SalesOrderNumber LIKE '%'+@SalesOrderNumber+'%') AND
       (ISNULL(@ContractReference,'') ='' OR ContractReference LIKE '%'+@ContractReference+'%') AND
       (ISNULL(@CustomerName,'') ='' OR CustomerName LIKE  '%'+@CustomerName+'%') AND
       (ISNULL(@CustomerReference,'') ='' OR CustomerReference LIKE '%'+@CustomerReference+'%') AND
       (ISNULL(@PriorityType,'') ='' OR PriorityType LIKE '%'+ @PriorityType+'%') AND
	   (ISNULL(@ManufacturerType,'') ='' OR ManufacturerType LIKE '%'+ @ManufacturerType+'%') AND
       (ISNULL(@VersionNumber,'') ='' OR VersionNumber LIKE '%'+@VersionNumber+'%') AND
       (ISNULL(@SalesPerson,'') ='' OR SalesPerson LIKE '%'+ @SalesPerson+'%') AND
       (ISNULL(@OpenDate,'') ='' OR CAST(OpenDate as Date) = CAST(@OpenDate AS DATE)) AND
       (ISNULL(@RequestedDateType,'') ='' OR RequestedDateType LIKE '%'+ @RequestedDateType +'%') AND
       (ISNULL(@EstimatedShipDateType,'') ='' OR EstimatedShipDateType LIKE '%'+ @EstimatedShipDateType +'%') AND  
       (ISNULL(@QuoteDate,'') ='' OR CAST(QuoteDate AS DATE) = CAST(@QuoteDate AS DATE)) AND  
       (ISNULL(@ShippedDate,'') ='' OR CAST(ShippedDate AS DATE) = CAST(@ShippedDate AS DATE)) AND  
       (ISNULL(@PartNumberType,'') ='' OR PartNumberType LIKE '%'+@PartNumberType+'%') AND  
       (ISNULL(@PartDescriptionType,'') ='' OR PartDescriptionType LIKE '%'+@PartDescriptionType+'%') AND  
       (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND  
       (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND  
       (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND  
       (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) AND  
       (ISNULL(@Status,'') ='' OR Status LIKE  '%'+@Status+'%'))  
       ))
     SELECT SalesOrderId, UPPER(SalesOrderNumber) 'SalesOrderNumber',UPPER(ContractReference) 'ContractReference', UPPER(SalesOrderQuoteNumber) 'SalesOrderQuoteNumber', UPPER(VersionNumber) 'VersionNumber', OpenDate, CustomerId, UPPER(CustomerName) 'CustomerName', UPPER(CustomerReference) 'CustomerReference' , UPPER(Priority) 'Priority',   
     UPPER(PriorityType) 'PriorityType', QuoteAmount, UnitCost, RequestedDate, RequestedDateType, QuoteDate, EstimatedShipDate, EstimatedShipDateType, PromisedDate,   
     ShippedDate, UPPER(SalesPerson) 'SalesPerson', UPPER(Status) 'Status', StatusId, UPPER(PartNumber) 'PartNumber',UPPER(ManufacturerType) 'ManufacturerType', UPPER(PartNumberType) 'PartNumberType', UPPER(PartDescription) 'PartDescription', UPPER(PartDescriptionType) 'PartDescriptionType',  
     CreatedDate, UpdatedDate, UPPER(CreatedBy) 'CreatedBy', UPPER(UpdatedBy) 'UpdatedBy', (Select COUNT(*) FROM FinalResult) AS NumberOfItems FROM FinalResult
     ORDER BY
     CASE WHEN (@SortOrder=1 AND @SortColumn='SALESORDERID')  THEN SalesOrderId END DESC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,  
	 CASE WHEN (@SortOrder=1 AND @SortColumn='CONTRACTREFERENCE')  THEN ContractReference END ASC, 
     CASE WHEN (@SortOrder=1 AND @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='VERSIONNUMBER')  THEN VersionNumber END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='QUOTEDATE')  THEN QuoteDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='STATUS')  THEN Status END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='PRIORITYTYPE')  THEN PriorityType END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='OPENDATE')  THEN OpenDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='REQUESTEDDATE')  THEN RequestedDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimatedShipDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
	 CASE WHEN (@SortOrder=1 AND @SortColumn='REQUESTEDDATETYPE')  THEN RequestedDateType END ASC,  
	 CASE WHEN (@SortOrder=1 AND @SortColumn='ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END ASC,
  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESORDERID')  THEN SalesOrderId END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTRACTREFERENCE')  THEN ContractReference END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='VERSIONNUMBER')  THEN VersionNumber END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='QUOTEDATE')  THEN QuoteDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='STATUS')  THEN Status END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='PRIORITYTYPE')  THEN PriorityType END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='OPENDATE')  THEN OpenDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='REQUESTEDDATE')  THEN RequestedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimatedShipDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESPERSON')  THEN SalesPerson END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC ,
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='REQUESTEDDATETYPE')  THEN RequestedDateType END DESC,
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END DESC 

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
              , @AdhocComments     VARCHAR(150)    = 'SearchSalesOrderPNViewData'   
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