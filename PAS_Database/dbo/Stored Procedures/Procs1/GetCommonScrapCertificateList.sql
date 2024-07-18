/*************************************************************             
 ** File:   [GetCommonScrapCertificateist]             
 ** Author:   SUBHASH  Saliya  
 ** Description: Get Search Data for Scrap Certificate List  
 ** Purpose:           
 ** Date:   17/10/2022          
            
 ** PARAMETERS: @POId varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    17/10/2022   SUBHASH Saliya Created 
    2    24/01/2024   Bhargav Saliya Add Field [StockLineNumber] 
    3    16/04/2024   Moin Bloch      Added New Field Scrap Certificate Date	
	4    18 July 2024   Shrey Chandegara       Modified( use this function @CurrntEmpTimeZoneDesc for date issue.)
	
 EXECUTE [GetCommonScrapCertificateist] 1, 50, null, -1, 1, '', 'mpn', '','','','','','','','','all'  
**************************************************************/   
CREATE       PROCEDURE [dbo].[GetCommonScrapCertificateList]  
 @PageNumber int,  
 @PageSize int,  
 @SortColumn varchar(50) = null,  
 @SortOrder int,  
 @GlobalFilter varchar(50) = '',  
 @PartNumber varchar(50) = null,  
 @SerialNumber varchar(50) = null,  
 @CustomerReference varchar(50) = null,  
 @Manufacturer varchar(50) = null,  
 @WorkOrderNumber varchar(50) = null,  
 @ScrapReason varchar(50) = null,  
 @CustomerName varchar(50) = null, 
 @ScrapedByEmployee varchar(50) = null,  
 @CertifiedBy varchar(50) = null,  
 @CreatedDate datetime = null,  
 @UpdatedDate datetime = null,  
 @CreatedBy varchar(50) = null,  
 @UpdatedBy varchar(50) = null,  
 @MasterCompanyId varchar(200) = null,
 @partDescription varchar(50) = null,
 @cntrlNum varchar(50) = null,
 @stockLineNumber varchar(50) = null,
 @IsDeleted bit= null
 
AS   
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
    DECLARE @RecordFrom int;  
    DECLARE @IsActive bit=1  
    DECLARE @Count Int;  
    DECLARE @WorkOrderStatusId int;   
    DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId   
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
    DROP TABLE #TempResult   
    END  
  
    SET @RecordFrom = (@PageNumber-1)*@PageSize;  
    IF @IsDeleted is null  
    BEGIN  
		SET @IsDeleted = 0;
    END
  
    IF (@GlobalFilter IS NULL OR @GlobalFilter = '')  
    BEGIN  
     SET @GlobalFilter= ''  
    END   
  
    IF @SortColumn is null  
    BEGIN  
     Set @SortColumn=Upper('CreatedDate')  
    END   
    Else  
    BEGIN   
     Set @SortColumn=Upper(@SortColumn)  
    END  
  ;WITH CTE AS( SELECT DISTINCT UPPER(WO.WorkOrderNum) as WorkOrderNumber
				,UPPER(WO.CustomerName) CustomerName
				,ST.SerialNumber
				,UPPER(CASE WHEN ISNULL(WOPN.RevisedItemmasterid, 0) > 0 THEN WOPN.RevisedPartNumber ELSE imt.PartNumber END) as 'PartNumber'
			    ,UPPER(CASE WHEN ISNULL(WOPN.RevisedItemmasterid, 0) > 0 THEN WOPN.RevisedPartDescription ELSE imt.PartDescription END) as 'partDescription'
				,UPPER(ST.Manufacturer) AS Manufacturer
				,UPPER(ST.ControlNumber) as cntrlNum
				,UPPER(WOPN.CustomerReference) AS CustomerReference
				,WOPN.Id as workOrderPartNoId
				,WO.WorkOrderId as WorkOrderId
				,isnull(SC.ScrapCertificateId,0) as ScrapCertificateId 
				,UPPER(ST.StockLineNumber) StockLineNumber				
				FROM [dbo].[WorkOrder] WO WITH (NOLOCK)
				INNER JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WO.WorkOrderId
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOPN.ItemMasterId=IM.ItemMasterId
				INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
				 LEFT JOIN [dbo].[ScrapCertificate] SC WITH (NOLOCK) ON SC.WorkOrderId=WO.WorkOrderId AND WOPN.ID=SC.workOrderPartNoId
				 LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) on imt.ItemMasterId = WOPN.ItemMasterId
				WHERE SC.MasterCompanyId=@MasterCompanyId and isnull(SC.isSubWorkOrder,0)= 0 

			UNION ALL

			SELECT DISTINCT UPPER(WO.WorkOrderNum) as WorkOrderNumber
				,UPPER(WO.CustomerName) CustomerName
				,ST.SerialNumber
				,UPPER(IM.partnumber) AS partnumber 
				,UPPER(IM.PartDescription) AS partDescription 
				,UPPER(ST.Manufacturer) AS Manufacturer
				,UPPER(ST.ControlNumber) as cntrlNum
				,UPPER(SWOPN.CustomerReference) AS CustomerReference
				,SWOPN.SubWOPartNoId as workOrderPartNoId
				,SWO.SubWorkOrderId as WorkOrderId
				,isnull(SC.ScrapCertificateId,0) as ScrapCertificateId 
				,UPPER(ST.StockLineNumber) StockLineNumber				
				FROM [dbo].[SubWorkOrder] SWO WITH (NOLOCK)
				INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOPN WITH (NOLOCK) ON SWOPN.SubWorkOrderId =SWO.SubWorkOrderId
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SWOPN.ItemMasterId=IM.ItemMasterId
				INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=SWOPN.StockLineId AND ST.IsParent = 1
				 LEFT JOIN [dbo].[ScrapCertificate] SC WITH (NOLOCK) ON SC.WorkOrderId=SWOPN.SubWorkOrderId AND SWOPN.SubWOPartNoId=SC.workOrderPartNoId
				 LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId=SWO.WorkOrderId 
			  	WHERE SWO.MasterCompanyId=@MasterCompanyId and SC.isSubWorkOrder= 1 
			  )
		,Result AS(  
         SELECT UPPER(CTE.WorkOrderNumber) as WorkOrderNumber
				,UPPER(CTE.CustomerName) CustomerName
				,CTE.SerialNumber
				,CTE.PartNumber
			    ,CTE.partDescription
				,UPPER(CTE.Manufacturer) AS Manufacturer
				,UPPER(CTE.cntrlNum) as cntrlNum
				,UPPER(CTE.CustomerReference) AS CustomerReference
				,isnull(SC.ScrapCertificateId,0) as ScrapCertificateId
				,isnull(SC.ScrapedByEmployeeId,0) as ScrapedByEmployeeId
				,isnull(SC.ScrapedByVendorId,0) as ScrapedByVendorId
				,isnull(SC.CertifiedById,0) as CertifiedById
				,isnull(SC.ScrapReasonId,0) as ScrapReasonId
				,isnull(SC.IsExternal,0) as IsExternal
				,UPPER(case when isnull(SC.IsExternal,0)  =1 then vo.vendorName else (EM.FirstName +'  '+EM.LastName) end) as ScrapedByEmployee 
				,UPPER(SR.Reason) as ScrapReason
				,CTE.workOrderPartNoId as workOrderPartNoId
				,CTE.WorkOrderId as WorkOrderId
				,UPPER(EMc.FirstName +'  '+EMc.LastName) as CertifiedBy
				,isnull(SC.CreatedBy,SC.CreatedBy) as CreatedBy
				,isnull(SC.UpdatedBy,SC.UpdatedBy) as UpdatedBy
				,isnull(SC.CreatedDate,SC.CreatedDate) as CreatedDate
				,isnull(SC.UpdatedDate,SC.UpdatedDate) as UpdatedDate
				,Isnull(SC.isSubWorkOrder,0) as isSubWorkOrder
				,SC.MasterCompanyId
				,UPPER(CTE.StockLineNumber) StockLineNumber
				,SC.ScrapCertificateDate
				FROM CTE CTE WITH (NOLOCK)
				INNER JOIN [dbo].[ScrapCertificate] SC WITH (NOLOCK) ON SC.ScrapCertificateId=CTE.ScrapCertificateId 
				 LEFT JOIN [dbo].[ScrapReason] SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId 
				 LEFT JOIN [dbo].[vendor] vo WITH (NOLOCK) ON vo.vendorid=SC.ScrapedByVendorId 
				 LEFT JOIN [dbo].[employee] EM WITH (NOLOCK) ON EM.EmployeeId=SC.ScrapedByEmployeeId 
				 LEFT JOIN [dbo].[employee] EMc WITH (NOLOCK) ON EMc.EmployeeId=SC.CertifiedById 
                WHERE SC.MasterCompanyId = @MasterCompanyId  AND (SC.IsDeleted = @IsDeleted)
				--AND isnull(SC.IsDeleted, 0) = 0
     ), ResultCount AS(SELECT COUNT(ScrapCertificateId) AS totalItems FROM Result)  
      SELECT * INTO #TempResult FROM  Result  
      WHERE (  
      (@GlobalFilter <>'' AND (  
      (PartNumber like '%' +@GlobalFilter+'%') OR        
      (SerialNumber like '%' +@GlobalFilter+'%') OR 
	  (cntrlNum like '%' +@GlobalFilter+'%') OR        
      (partDescription like '%' +@GlobalFilter+'%') OR 
      (CustomerReference like '%' +@GlobalFilter+'%') OR  
      (Manufacturer like '%' +@GlobalFilter+'%') OR  
      (WorkOrderNumber like '%' +@GlobalFilter+'%') OR  
      (ScrapReason like '%' +@GlobalFilter+'%') OR  
      (CustomerName like '%' +@GlobalFilter+'%') OR  
      (ScrapedByEmployee like '%'+@GlobalFilter+'%') OR  
      (CertifiedBy like '%' +@GlobalFilter+'%' ) OR   
      (CreatedBy like '%' +@GlobalFilter+'%') OR  
      (UpdatedBy like '%' +@GlobalFilter+'%') OR
	  (StockLineNumber like '%' +@GlobalFilter+'%')  
      ))  
      OR     
      (@GlobalFilter='' AND (IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND  
      (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
      (IsNull(@customerName,'') ='' OR customerName like '%' + @customerName+'%') AND
	  (IsNull(@cntrlNum,'') ='' OR cntrlNum like '%' + @cntrlNum+'%') AND  
      (IsNull(@partDescription,'') ='' OR partDescription like '%' + @partDescription+'%') AND 
      (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
      (IsNull(@Manufacturer,'') ='' OR Manufacturer like '%' + @Manufacturer+'%') AND  
      (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
      (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND  
      (IsNull(@WorkOrderNumber,'') ='' OR WorkOrderNumber like '%' + @WorkOrderNumber+'%') AND  
      (IsNull(@CreatedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc )AS date)=Cast(@CreatedDate as date)) AND  
      (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and  
      (IsNull(@ScrapReason,'') ='' OR ScrapReason like '%' + @ScrapReason+'%') AND  
      (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
      (IsNull(@ScrapedByEmployee,'') ='' OR ScrapedByEmployee like '%' + @ScrapedByEmployee+'%') AND  
      (IsNull(@CertifiedBy,'') ='' OR CertifiedBy like '%' + @CertifiedBy+'%')  AND
      (IsNull(@StockLineNumber,'') ='' OR StockLineNumber like '%' + @StockLineNumber+'%')  

      ))  
  
      SELECT @Count = COUNT(ScrapCertificateId) from #TempResult     
  
      SELECT *, @Count As NumberOfItems FROM #TempResult  
      ORDER BY    
      CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='CustomerReference')  THEN CustomerReference END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='Manufacturer')  THEN Manufacturer END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNumber')  THEN WorkOrderNumber END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='ScrapReason')  THEN ScrapReason END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='ScrapedByEmployee')  THEN ScrapedByEmployee END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
	   CASE WHEN (@SortOrder=1 and @SortColumn='cntrlNum')  THEN cntrlNum END ASC,  
      CASE WHEN (@SortOrder=1 and @SortColumn='partDescription')  THEN partDescription END ASC,
      CASE WHEN (@SortOrder=1 and @SortColumn='StockLineNumber')  THEN StockLineNumber END ASC,  
	  
  
      CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,  
	  CASE WHEN (@SortOrder=-1 and @SortColumn='cntrlNum')  THEN cntrlNum END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,
      CASE WHEN (@SortOrder=-1 and @SortColumn='partDescription')  THEN partDescription END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerReference')  THEN CustomerReference END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='Manufacturer')  THEN Manufacturer END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNumber')  THEN WorkOrderNumber END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='ScrapReason')  THEN ScrapReason END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='ScrapedByEmployee')  THEN ScrapedByEmployee END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
      CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
      CASE WHEN (@SortOrder=-1 and @SortColumn='StockLineNumber')  THEN StockLineNumber END DESC  
	  
  
      OFFSET @RecordFrom ROWS   
      FETCH NEXT @PageSize ROWS ONLY  
  
      IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
      BEGIN  
      DROP TABLE #TempResult   
      END  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuoteList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ScrapReason, '') + ''  
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