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
 ** --   --------     -------           --------------------------------            
    1    07/08/2023   Ekta Chandegra     Convert text into uppercase   
**************************************************************/ 
CREATE   PROCEDURE [dbo].[SearchPNViewData]  
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
 @ManufacturerType varchar(50) = null
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
    SET @RecordFrom = (@PageNumber-1)*@PageSize;  
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
  
    If @QuoteAmount=0  
    Begin   
     Set @QuoteAmount=null  
    End  
    
    If @SoAmount=0  
    Begin   
     Set @SoAmount=null  
    End  
  
    If @StatusID=0  
    Begin   
     Set @StatusID=null  
    End   
  
    If @Status='0'  
    Begin  
     Set @Status=null  
    End  
    DECLARE @MSModuleID INT = 18; -- Sales Order Quote Management Structure Module ID  
   -- Insert statements for procedure here  
   ;With Result AS(  
    Select DISTINCT SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,SOQ.OpenDate as 'QuoteDate',C.CustomerId,C.Name as 'CustomerName',MST.Name as 'Status',ISNULL(SPC.NetSaleAmount,0) as 'QuoteAmount',  
    SOQ.CreatedDate,SOQ.IsNewVersionCreated,SOQ.StatusId,SOQ.CustomerReference,IsNull(P.Description,'') as 'Priority',IsNull(P.Description,'') as 'PriorityType',(E.FirstName+' '+E.LastName)as SalesPerson,  
    IsNull(IM.partnumber,'') as 'PartNumber',M.Name As 'ManufacturerType',IsNull(IM.partnumber,'') as 'PartNumberType',IsNull(im.PartDescription,'') as 'PartDescription',IsNull(im.PartDescription,'') as 'PartDescriptionType',  
    Ct.CustomerTypeName as 'CustomerType',SO.SalesOrderNumber,SOP.NetSales as 'SoAmount',SOQ.UpdatedDate,SOQ.UpdatedBy, SOQ.CreatedBy,SOQ.IsDeleted,dbo.GenearteVersionNumber(SOQ.Version) as 'VersionNumber'  
    from DBO.SalesOrderQuote SOQ WITH (NOLOCK)  
    Inner Join DBO.MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId=MST.Id  
    Inner Join DBO.Customer C WITH (NOLOCK) on C.CustomerId=SOQ.CustomerId  
    Inner Join DBO.CustomerType CT WITH (NOLOCK) on CT.CustomerTypeId=SOQ.AccountTypeId  
    --Left Join DBO.SalesOrderQuotePart SP WITH (NOLOCK) on SOQ.SalesOrderQuoteId=SP.SalesOrderQuoteId and SP.IsDeleted=0  
    Left Join DBO.SalesOrderQuotePartV1 SP WITH (NOLOCK) on SOQ.SalesOrderQuoteId = SP.SalesOrderQuoteId and SP.IsDeleted=0  
    LEFT Join DBO.SalesOrderQuotePartCost SPC WITH (NOLOCK) on SPC.SalesOrderQuotePartId = SP.SalesOrderQuotePartId
    Left Join DBO.ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId=SP.ItemMasterId  
    LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId  
    Left Join DBO.Employee E WITH (NOLOCK) on  E.EmployeeId=SOQ.SalesPersonId --and SOQ.SalesPersonId is not null  
    Left Join DBO.Priority P WITH (NOLOCK) on SP.PriorityId=P.PriorityId  
    Left Join DBO.SalesOrder SO WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null  
    Left Join DBO.SalesOrderPart SOP WITH (NOLOCK) on SOP.SalesOrderQuotePartId=SP.SalesOrderQuotePartId and SOP.SalesOrderQuotePartId is not null  
    INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId  
    INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId  
    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
    Where (SOQ.IsDeleted=@IsDeleted) and (@StatusID is null or SOQ.StatusId=@StatusID) AND SOQ.MasterCompanyId = @MasterCompanyId),  
    FinalResult AS (SELECT SalesOrderQuoteId,SalesOrderQuoteNumber,QuoteDate,CustomerId,CustomerName,Status,VersionNumber,QuoteAmount,IsNewVersionCreated,StatusId  
     ,CustomerReference,Priority,PriorityType,SalesPerson,PartNumber,ManufacturerType,PartNumberType,PartDescription,PartDescriptionType,CustomerType,SalesOrderNumber,  
     SoAmount, CreatedDate,UpdatedDate, CreatedBy,UpdatedBy from Result  
    Where (  
     (@GlobalFilter <>'' AND ((SalesOrderQuoteNumber like '%' +@GlobalFilter+'%' ) OR (SalesOrderNumber like '%' +@GlobalFilter+'%') OR  
       (CustomerName like '%' +@GlobalFilter+'%') OR  
       (SalesPerson like '%' +@GlobalFilter+'%') OR  
	   (ManufacturerType like '%' +@GlobalFilter+'%') OR
       (Status like '%' +@GlobalFilter+'%') OR  
       (PriorityType like '%' +@GlobalFilter+'%') OR  
       (PartNumberType like '%' +@GlobalFilter+'%') OR  
       (PartDescriptionType like '%' +@GlobalFilter+'%') OR  
       (CustomerReference like '%' +@GlobalFilter+'%') OR  
       (@VersionNumber like '%'+@GlobalFilter+'%') OR  
       (CustomerType like '%' +@GlobalFilter+'%') OR   
       (CreatedBy like '%' +@GlobalFilter+'%') OR  
       (UpdatedBy like '%' +@GlobalFilter+'%')   
       ))  
       OR     
       (@GlobalFilter='' AND (IsNull(@SOQNumber,'') ='' OR SalesOrderQuoteNumber like  '%'+ @SOQNumber+'%') and   
       (IsNull(@SalesOrderNumber,'') ='' OR SalesOrderNumber like '%'+@SalesOrderNumber+'%') and  
       (IsNull(@CustomerName,'') ='' OR CustomerName like  '%'+@CustomerName+'%') and  
       (IsNull(@Status,'') ='' OR Status like  '%'+@Status+'%') and  
       (@QuoteAmount is  null or QuoteAmount=@QuoteAmount) and  
       (@SoAmount is  null or SoAmount=@SoAmount) and  
       (@QuoteDate is  null or Cast(QuoteDate as date)=Cast(@QuoteDate as date)) and  
       (IsNull(@SalesPerson,'') ='' OR SalesPerson like '%'+ @SalesPerson+'%') and  
	    (IsNull(@ManufacturerType,'') ='' OR ManufacturerType like '%'+ @ManufacturerType+'%') and  
       (IsNull(@PriorityType,'') ='' OR PriorityType like '%'+ @PriorityType+'%') and  
       (IsNull(@PartNumberType,'') ='' OR PartNumberType like '%'+@PartNumberType+'%') and  
       (IsNull(@PartDescriptionType,'') ='' OR PartDescriptionType like '%'+@PartDescriptionType+'%') and  
       (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%'+@CustomerReference+'%') and  
       (IsNull(@CustomerType,'') ='' OR CustomerType like '%'+@CustomerType+'%') and  
       (IsNull(@VersionNumber,'') ='' OR VersionNumber like '%'+@VersionNumber+'%') and  
       (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%'+ @CreatedBy+'%') and  
       (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%'+ @UpdatedBy+'%') and  
       (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) and  
       (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)))  
       )),  
     ResultCount AS (Select COUNT(SalesOrderQuoteId) AS NumberOfItems FROM FinalResult)  
     SELECT SalesOrderQuoteId,UPPER(SalesOrderQuoteNumber) 'SalesOrderQuoteNumber',QuoteDate,CustomerId,UPPER(CustomerName) 'CustomerName',UPPER(Status) 'Status',UPPER(VersionNumber) 'VersionNumber',QuoteAmount,IsNewVersionCreated,StatusId  
     ,UPPER(CustomerReference) 'CustomerReference',UPPER(Priority) 'Priority',UPPER(PriorityType) 'PriorityType',UPPER(SalesPerson) 'SalesPerson',UPPER(PartNumber) 'PartNumber',UPPER(ManufacturerType) 'ManufacturerType',UPPER(PartNumberType) 'PartNumberType',UPPER(PartDescription) 'PartDescription',UPPER(PartDescriptionType) 'PartDescriptionType',UPPER(CustomerType) 'CustomerType',UPPER(SalesOrderNumber) 'SalesOrderNumber',  
     CreatedDate,UpdatedDate, UPPER(CreatedBy) 'CreatedBy',UPPER(UpdatedBy) 'UpdatedBy', NumberOfItems from FinalResult, ResultCount  
    ORDER BY    
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
     CASE WHEN (@SortOrder=1 and @SortColumn='SOAMOUNT')  THEN SoAmount END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
     CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
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
     CASE WHEN (@SortOrder=-1 and @SortColumn='SOAMOUNT')  THEN SoAmount END Desc,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END Desc,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END Desc,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
     CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC  
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