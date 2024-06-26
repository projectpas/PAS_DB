
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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/08/2023  Ekta Chandegara     Convert text into uppercase
	2    06/26/2024  AMIT GHEDIYA        Added orderby for RequestedDate,EstimatedShipDate
************************************************************************/  
CREATE    PROCEDURE [dbo].[SearchSalesOrderPNViewData]  
 -- Add the parameters for the stored procedure here  
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
 @ManufacturerType varchar(50)=null
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
    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
    IF @IsDeleted is null  
    Begin  
     Set @IsDeleted=0  
    End  
    print @IsDeleted   
    IF @SortColumn is null  
    Begin  
     Set @SortColumn=Upper('CreatedDate')  
    End   
    Else  
    Begin   
     Set @SortColumn=Upper(@SortColumn)  
    End  
    
    If @StatusID=0  
    Begin   
     Set @StatusID=null  
    End   
  
    If @Status='0'  
    Begin  
     Set @Status=null  
    End  
    DECLARE @MSModuleID INT = 17; -- Sales Order Management Structure Module ID  
   -- Insert statements for procedure here  
   ;With Result AS(  
    Select DISTINCT SO.SalesOrderId, SO.SalesOrderNumber, SOQ.SalesOrderQuoteNumber, SO.OpenDate as 'OpenDate',   
    --SO.OpenDate as 'QuoteDate'  
    SOQ.OpenDate as 'QuoteDate'  
    , C.CustomerId, C.Name as 'CustomerName', MST.Name as 'Status', ISNULL(SP.NetSales,0) as 'QuoteAmount',  
    ISNULL(SP.UnitCost, 0) as 'UnitCost', ISNULL(SP.CustomerRequestDate, '0001-01-01') as 'RequestedDate', ISNULL(SP.CustomerRequestDate, '0001-01-01') as 'RequestedDateType', SO.StatusId, SO.CustomerReference, IsNull(P.Description, '') as 'Priority', IsNull(P.Description, '') as 'PriorityType', (E.FirstName+' '+E.LastName)as SalesPerson,  
    IsNull(IM.partnumber,'') as 'PartNumber',M.Name As 'ManufacturerType', IsNull(IM.partnumber,'') as 'PartNumberType', IsNull(im.PartDescription,'') as 'PartDescription', IsNull(im.PartDescription,'') as 'PartDescriptionType',  
    SO.CreatedDate, SO.UpdatedDate, SO.UpdatedBy, SO.CreatedBy, ISNULL(SP.EstimatedShipDate, '0001-01-01') as 'EstimatedShipDate', ISNULL(SP.EstimatedShipDate, '0001-01-01') as 'EstimatedShipDateType', ISNULL(SP.PromisedDate, '0001-01-01') as 'PromisedDate',  
    ISNULL(SO.ShippedDate, '0001-01-01') as 'ShippedDate',   
    SO.IsDeleted, --dbo.GenearteVersionNumber(SO.Version) as 'VersionNumber'  
    SOQ.VersionNumber  
    from SalesOrder SO WITH (NOLOCK)  
    Inner Join MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SO.StatusId = MST.Id  
    Inner Join Customer C WITH (NOLOCK) on C.CustomerId = SO.CustomerId  
    Left Join SalesOrderPart SP WITH (NOLOCK) on SO.SalesOrderId = SP.SalesOrderId and SP.IsDeleted = 0  
    Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId = SP.ItemMasterId  
    LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
    Left Join Employee E WITH (NOLOCK) on  E.EmployeeId = SO.SalesPersonId  
    Left Join Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId  
    Left Join SalesOrderQuote SOQ WITH (NOLOCK) on SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId  
    INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SO.SalesOrderId  
    INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId  
    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
    Where (SO.IsDeleted = @IsDeleted) and (@StatusID is null or SO.StatusId = @StatusID)  
    AND SO.MasterCompanyId = @MasterCompanyId  
    Group By SO.SalesOrderId, SalesOrderNumber, SalesOrderQuoteNumber, SO.OpenDate, SOQ.OpenDate, C.CustomerId, C.Name,   
    MST.Name, SP.NetSales, SP.UnitCost, SP.CustomerRequestDate, SO.StatusId, SO.CustomerReference,  
    P.Description, E.FirstName, E.LastName, IM.partnumber,M.Name, IM.PartDescription, SOQ.VersionNumber,   
    SO.CreatedDate, SO.UpdatedDate, SO.UpdatedBy, SO.CreatedBy, SP.EstimatedShipDate, SP.PromisedDate, SO.ShippedDate, SO.IsDeleted, SO.Version),  
    --ResultCount AS (Select COUNT(SalesOrderId) AS NumberOfItems FROM Result)  
    FinalResult AS (  
    SELECT SalesOrderId, SalesOrderNumber, SalesOrderQuoteNumber, VersionNumber, OpenDate, CustomerId, CustomerName, CustomerReference, Priority,   
      PriorityType, QuoteAmount, UnitCost, RequestedDate, RequestedDateType, QuoteDate, EstimatedShipDate, EstimatedShipDateType, PromisedDate,   
      ShippedDate, SalesPerson, Status, StatusId, PartNumber,ManufacturerType, PartNumberType, PartDescription, PartDescriptionType,  
      CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result  
    where (  
     (@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR   
       (SalesOrderNumber like '%' +@GlobalFilter+'%') OR  
       (OpenDate like '%' +@GlobalFilter+'%') OR  
       (CustomerName like '%' +@GlobalFilter+'%') OR  
       (SalesPerson like '%' +@GlobalFilter+'%') OR  
       (@VersionNumber like '%'+@GlobalFilter+'%') OR  
       (CustomerReference like '%' +@GlobalFilter+'%') OR  
       (PriorityType like '%' +@GlobalFilter+'%') OR  
       (RequestedDateType like '%' +@GlobalFilter+'%') OR  
       (QuoteDate like '%' +@GlobalFilter+'%') OR  
       (EstimatedShipDateType like '%' +@GlobalFilter+'%') OR  
       (ShippedDate like '%' +@GlobalFilter+'%') OR  
       (PromisedDate like '%' +@GlobalFilter+'%') OR  
       (PartNumberType like '%' +@GlobalFilter+'%') OR 
	    (ManufacturerType like '%' +@GlobalFilter+'%') OR
       (PartDescriptionType like '%' +@GlobalFilter+'%') OR  
       (CreatedDate like '%' +@GlobalFilter+'%') OR  
       (UpdatedDate like '%' +@GlobalFilter+'%') OR  
       (Status like '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND (IsNull(@SOQNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SOQNumber+'%') and   
       (IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and  
       (IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and  
       (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%'+@CustomerReference+'%') and  
       (IsNull(@PriorityType,'') ='' OR PriorityType like '%'+ @PriorityType+'%') and
	   (IsNull(@ManufacturerType,'') ='' OR ManufacturerType like '%'+ @ManufacturerType+'%') and
       (IsNull(@VersionNumber,'') ='' OR VersionNumber like '%'+@VersionNumber+'%') and  
       (IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and  
       (IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date) = Cast(@OpenDate as date)) and  
       (IsNull(@RequestedDateType,'') ='' OR RequestedDateType like '%'+ @RequestedDateType +'%') and  
       (IsNull(@EstimatedShipDateType,'') ='' OR EstimatedShipDateType like '%'+ @EstimatedShipDateType +'%') and  
       (IsNull(@QuoteDate,'') ='' OR Cast(QuoteDate as Date) = Cast(@QuoteDate as date)) and  
       (IsNull(@ShippedDate,'') ='' OR Cast(ShippedDate as Date) = Cast(@ShippedDate as date)) and  
       (IsNull(@PartNumberType,'') ='' OR PartNumberType like '%'+@PartNumberType+'%') and  
       (IsNull(@PartDescriptionType,'') ='' OR PartDescriptionType like '%'+@PartDescriptionType+'%') and  
       (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and  
       (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and  
       (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and  
       (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and  
       (IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%'))  
       )),  
      ResultCount AS (Select COUNT(SalesOrderId) AS NumberOfItems FROM FinalResult)  
      SELECT SalesOrderId, UPPER(SalesOrderNumber) 'SalesOrderNumber', UPPER(SalesOrderQuoteNumber) 'SalesOrderQuoteNumber', UPPER(VersionNumber) 'VersionNumber', OpenDate, CustomerId, UPPER(CustomerName) 'CustomerName', UPPER(CustomerReference) 'CustomerReference' , UPPER(Priority) 'Priority',   
      UPPER(PriorityType) 'PriorityType', QuoteAmount, UnitCost, RequestedDate, RequestedDateType, QuoteDate, EstimatedShipDate, EstimatedShipDateType, PromisedDate,   
      ShippedDate, UPPER(SalesPerson) 'SalesPerson', UPPER(Status) 'Status', StatusId, UPPER(PartNumber) 'PartNumber',UPPER(ManufacturerType) 'ManufacturerType', UPPER(PartNumberType) 'PartNumberType', UPPER(PartDescription) 'PartDescription', UPPER(PartDescriptionType) 'PartDescriptionType',  
      CreatedDate, UpdatedDate, UPPER(CreatedBy) 'CreatedBy', UPPER(UpdatedBy) 'UpdatedBy', NumberOfItems FROM FinalResult, ResultCount  
  
      ORDER BY    
     CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERID')  THEN SalesOrderId END DESC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='REQUESTEDDATE')  THEN RequestedDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimatedShipDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='REQUESTEDDATETYPE')  THEN RequestedDateType END ASC,  
	 CASE WHEN (@SortOrder=1 and @SortColumn='ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END ASC,
  
     CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERID')  THEN SalesOrderId END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='REQUESTEDDATE')  THEN RequestedDate END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='ESTIMATEDSHIPDATE')  THEN EstimatedShipDate END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC ,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='REQUESTEDDATETYPE')  THEN RequestedDateType END DESC,
	 CASE WHEN (@SortOrder=-1 and @SortColumn='ESTIMATEDSHIPDATETYPE')  THEN EstimatedShipDateType END DESC 

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