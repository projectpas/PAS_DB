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
 ** --   --------     -------           --------------------------------            
    1    07/08/2023   Ekta Chandegra     Convert text into uppercase   
**************************************************************/ 
CREATE    PROCEDURE [dbo].[SearchSOQViewData]  
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
    ;With Main AS(  
      Select DISTINCT SOQ.SalesOrderQuoteId,SOQ.SalesOrderQuoteNumber,SOQ.OpenDate,C.CustomerId,C.Name,C.CustomerCode,MST.Name as 'Status',  
      B.Cost,B.NetSales as 'SalesPrice',(E.FirstName+' '+E.LastName)as SalesPerson,CT.CustomerTypeName,SO.SalesOrderNumber,  
      A.SoAmount,SOQ.CreatedDate,SOQ.UpdatedDate,SOQ.StatusId,SOQ.CreatedBy,SOQ.UpdatedBy,  
      dbo.GenearteVersionNumber(SOQ.Version) as 'VersionNumber',SOQ.IsNewVersionCreated,SOQ.CustomerReference  
      from dbo.SalesOrderQuote SOQ WITH (NOLOCK) Inner Join MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId=MST.Id  
      Inner Join Customer C WITH (NOLOCK) on SOQ.CustomerId=C.CustomerId  
      Inner Join CustomerType CT WITH (NOLOCK) on SOQ.AccountTypeId=CT.CustomerTypeId  
	  Left Join SalesOrderPart SP WITH (NOLOCK) on SOQ.SalesOrderQuoteId = SP.SalesOrderQuoteId
	  Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId = SP.ItemMasterId  
      LEFT JOIN Manufacturer MA WITH(NOLOCK) ON Im.ManufacturerId = MA.ManufacturerId 
      Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SOQ.SalesPersonId --and SOQ.SalesPersonId is not null  
      Left Join SalesOrder SO WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null  
      INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId  
      INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId  
      INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
      Outer Apply(  
       Select SUM(NetSales) as SoAmount from SalesOrderPart   
       Where SalesOrderQuoteId=SOQ.SalesOrderQuoteId  
      ) A  
      Outer Apply (  
       Select SUM(S.UnitCost) as 'Cost',SUM(S.NetSales) as 'NetSales' from SalesOrderQuotePart S  
       Where S.SalesOrderQuoteId=SOQ.SalesOrderQuoteId  
      ) B  
      Where (SOQ.IsDeleted=@IsDeleted) and (@StatusID is null or SOQ.StatusId=@StatusID) AND SOQ.MasterCompanyId = @MasterCompanyId),PartCTE AS(  
      Select SQ.SalesOrderQuoteId,(Case When Count(SP.SalesOrderQuotePartId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber from SalesOrderQuote SQ WITH (NOLOCK)  
      Left Join SalesOrderQuotePart SP WITH (NOLOCK) On SQ.SalesOrderQuoteId=SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0  
      Outer Apply(  
       SELECT   
          STUFF((SELECT ',' + I.partnumber  
           FROM SalesOrderQuotePart S WITH (NOLOCK)  
           Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
           Where S.SalesOrderQuoteId=SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0  
           FOR XML PATH('')), 1, 1, '') PartNumber  
      ) A  
      Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or sq.StatusId=@StatusID))  
      Group By SQ.SalesOrderQuoteId,A.PartNumber  
      ),
	  PartMFCTE AS(  
      Select SQ.SalesOrderQuoteId,(Case When Count(SP.SalesOrderQuotePartId) > 1 Then 'Multiple' ELse A.Manufacturer End)  as 'ManufacturerType',A.Manufacturer from SalesOrderQuote SQ WITH (NOLOCK)  
      Left Join SalesOrderQuotePart SP WITH (NOLOCK) On SQ.SalesOrderQuoteId=SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0  
      Outer Apply(  
       SELECT   
          STUFF((SELECT ', ' + MA.Name
           FROM SalesOrderQuote S WITH (NOLOCK)  
           Left Join SalesOrderQuotePart SP WITH (NOLOCK) on S.SalesOrderQuoteId = SP.SalesOrderQuoteId
	  Left Join ItemMaster IM WITH (NOLOCK) on Im.ItemMasterId = SP.ItemMasterId  
      LEFT JOIN Manufacturer MA WITH(NOLOCK) ON Im.ManufacturerId = MA.ManufacturerId
           Where S.SalesOrderQuoteId=SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0  
           FOR XML PATH('')), 1, 1, '') Manufacturer  
      ) A  
      Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or SQ.StatusId=@StatusID))  
      Group By SQ.SalesOrderQuoteId,A.Manufacturer  
      ),PartDescCTE AS(  
      Select SQ.SalesOrderQuoteId,(Case When Count(SP.SalesOrderQuotePartId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescriptionType',A.PartDescription from SalesOrderQuote SQ WITH (NOLOCK)  
      Left Join SalesOrderQuotePart SP WITH (NOLOCK) On SQ.SalesOrderQuoteId=SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0  
      Outer Apply(  
       SELECT   
          STUFF((SELECT ', ' + I.PartDescription  
           FROM SalesOrderQuotePart S WITH (NOLOCK)  
           Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
           Where S.SalesOrderQuoteId=SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0  
           FOR XML PATH('')), 1, 1, '') PartDescription  
      ) A  
      Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or SQ.StatusId=@StatusID))  
      Group By SQ.SalesOrderQuoteId,A.PartDescription  
      ),PriorityCTE AS(  
      Select SQ.SalesOrderQuoteId,(Case When Count(SP.SalesOrderQuotePartId) > 1 Then 'Multiple' ELse A.PriorityDescription End)  as 'PriorityType',A.PriorityDescription from SalesOrderQuote SQ WITH (NOLOCK)  
      Left Join SalesOrderQuotePart SP WITH (NOLOCK) On SQ.SalesOrderQuoteId=SP.SalesOrderQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0  
      Outer Apply(  
       SELECT   
          STUFF((SELECT ', ' + P.Description  
           FROM SalesOrderQuotePart S WITH (NOLOCK)  
           Left Join Priority P WITH (NOLOCK) On P.PriorityId=S.PriorityId  
           Where S.SalesOrderQuoteId=SQ.SalesOrderQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0  
           FOR XML PATH('')), 1, 1, '') PriorityDescription  
      ) A  
      Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or SQ.StatusId=@StatusID))   
      Group By SQ.SalesOrderQuoteId,A.PriorityDescription  
      ),Result AS(  
      Select M.SalesOrderQuoteId,M.SalesOrderQuoteNumber,M.OpenDate as 'QuoteDate',M.CustomerId,M.Name as 'CustomerName',M.Status,  
         M.VersionNumber,IsNull(M.SalesPrice,0) as 'QuoteAmount',M.IsNewVersionCreated,M.StatusId,M.CustomerReference,  
         PR.PriorityDescription as 'Priority',PR.PriorityType,M.SalesPerson,PT.PartNumber,PT.PartNumberType,PD.PartDescription,  
         PD.PartDescriptionType,M.CustomerTypeName as 'CustomerType',M.SalesOrderNumber,IsNULL(M.SoAmount,0) as 'SoAmount',M.CreatedDate,  
         M.UpdatedDate,M.CreatedBy,M.UpdatedBy,MF.Manufacturer,MF.ManufacturerType   
         from Main M   
      Left Join PartCTE PT On M.SalesOrderQuoteId=PT.SalesOrderQuoteId  
      Left Join PartDescCTE PD on PD.SalesOrderQuoteId=M.SalesOrderQuoteId  
	   Left Join PartMFCTE MF on MF.SalesOrderQuoteId=M.SalesOrderQuoteId
      Left Join PriorityCTE PR on PR.SalesOrderQuoteId=M.SalesOrderQuoteId  
      Where (  
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
        (M.UpdatedBy like '%' +@GlobalFilter+'%')   
        ))  
        OR     
        (@GlobalFilter='' AND (IsNull(@SOQNumber,'') ='' OR M.SalesOrderQuoteNumber like '%'+@SOQNumber+'%') and   
        (IsNull(@SalesOrderNumber,'') ='' OR M.SalesOrderNumber like '%'+@SalesOrderNumber+'%') and  
        (IsNull(@CustomerName,'') ='' OR M.Name like '%'+ @CustomerName+'%') and  
        (IsNull(@Status,'') =''  OR M.Status like '%'+@Status+'%') and  
        (@QuoteAmount is  null or M.SalesPrice=@QuoteAmount) and  
        (@SoAmount is  null or M.SoAmount=@SoAmount) and  
        (@QuoteDate is  null or Cast(M.OpenDate as date)=Cast(@QuoteDate as date)) and  
        (IsNull(@SalesPerson,'') ='' OR M.SalesPerson like '%'+@SalesPerson+'%') and  
        (IsNull(@PriorityType,'') ='' OR PR.PriorityType like '%'+ @PriorityType+'%') and  
        (IsNull(@PartNumberType,'') ='' OR PT.PartNumberType like '%'+@PartNumberType+'%') and  
        (IsNull(@PartDescriptionType,'') ='' OR PD.PartDescriptionType like '%'+@PartDescriptionType+'%') and  
        (IsNull(@CustomerReference,'') ='' OR M.CustomerReference like '%'+@CustomerReference+'%') and  
        (IsNull(@CustomerType,'') ='' OR M.CustomerTypeName like '%'+@CustomerType+'%') and  
		(IsNull(@ManufacturerType,'') ='' OR MF.ManufacturerType like '%'+@ManufacturerType+'%') and  
        (IsNull(@VersionNumber,'') ='' OR M.VersionNumber like '%'+@VersionNumber+'%') and  
        (IsNull(@CreatedBy,'') ='' OR M.CreatedBy like '%'+@CreatedBy+'%') and  
        (IsNull(@UpdatedBy,'') ='' OR M.UpdatedBy like '%'+@UpdatedBy+'%') and  
        (IsNull(@CreatedDate,'') ='' OR Cast(M.CreatedDate as Date)=Cast(@CreatedDate as date)) and  
        (IsNull(@UpdatedDate,'') ='' OR Cast(M.UpdatedDate as date)=Cast(@UpdatedDate as date)))  
        )  
       
     
      ), CTE_Count AS (Select COUNT(SalesOrderQuoteId) AS NumberOfItems FROM Result)  
      SELECT SalesOrderQuoteId,SalesOrderQuoteNumber,QuoteDate,CustomerId,UPPER(CustomerName) 'CustomerName',UPPER(Status) 'Status',UPPER(VersionNumber) 'VersionNumber',QuoteAmount,IsNewVersionCreated,StatusId  
      ,UPPER(CustomerReference) 'CustomerReference',UPPER(Priority) 'Priority',UPPER(PriorityType) 'PriorityType',UPPER(SalesPerson) 'SalesPerson',UPPER(PartNumber) 'PartNumber',UPPER(PartNumberType) 'PartNumberType',UPPER(PartDescription) 'PartDescription',UPPER(PartDescriptionType) 'PartDescriptionType',UPPER(CustomerType) 'CustomerType',UPPER(SalesOrderNumber) 'SalesOrderNumber',  
      CreatedDate,UpdatedDate,NumberOfItems,UPPER(CreatedBy) 'CreatedBy',UPPER(UpdatedBy) 'UpdatedBy',UPPER(Manufacturer) 'Manufacturer',UPPER(ManufacturerType) 'ManufacturerType' FROM Result,CTE_Count  
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
	  CASE WHEN (@SortOrder=1 and @SortColumn='MANUFACTURERTYPE')  THEN ManufacturerType END ASC,
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
      CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
	  --CASE WHEN (@SortOrder=-1 and @SortColumn='MANUFACTURERTYPE')  THEN ManufacturerType END DESC
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