/*************************************************************           
 ** File:   [USP_GetCustomerGeneralLedgerListByCustomer]
 ** Author: unknown
 ** Description: 
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1					unknown			Created
	2	02/1/2024		AMIT GHEDIYA	added isperforma Flage for SO

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerGeneralLedgerListByCustomer]    
(    
  @PageNumber int,        
  @PageSize int,        
  @SortColumn varchar(50)=null,        
  @SortOrder int,        
  @GlobalFilter varchar(50) = null,     
  @CustomerName varchar(50) = null,    
  @ModuleName varchar(50) = null,    
  @DocumentNumber varchar(20) = null,    
  @CreditAmount varchar(20) = null,  
  @DebitAmount varchar(20) = null,    
  @Amount varchar(20) = null,    
  @AccountingPeriod varchar(20) = null,    
  @MasterCompanyId bigint = NULL,    
  @CreatedDate datetime=null,        
  @UpdatedDate  datetime=null,        
  @UpdatedBy  varchar(50)=null,    
  @CustomerId bigint = NULL  
)    
AS    
BEGIN    
 SET NOCOUNT ON;        
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED         
 BEGIN TRY    
  DECLARE @RecordFrom int;        
  DECLARE @IsActive bit=1        
  DECLARE @Count Int;        
  SET @RecordFrom = (@PageNumber-1)*@PageSize;        
  IF @SortColumn IS NULL        
  BEGIN        
   SET @SortColumn=UPPER('CreatedDate')        
  END         
  Else        
  BEGIN         
   SET @SortColumn=UPPER(@SortColumn)        
  END        
    
  ;WITH Result AS(    
   SELECT     
   CustomerGeneralLedgerId,C.Name 'CustomerName',CL.ModuleName,  
   CL.DocumentNumber,ISNULL(CL.CreditAmount,0) 'CreditAmount',  
   ISNULL(DebitAmount,0) 'DebitAmount', ISNULL(CL.Amount,0) 'Amount',  
 AccountingPeriod,CL.MasterCompanyId,CL.CreatedDate,CL.UpdatedBy,  
 CL.UpdatedDate,CL.ReferenceId,CL.CustomerId,  
 CASE WHEN M.ModuleName = 'SalesOrder' THEN SB.InvoiceFilePath   
 WHEN M.ModuleName = 'WorkOrder' THEN WB.InvoiceFilePath   
 WHEN M.ModuleName = 'ExchangeSO' THEN ESB.InvoiceFilePath  
 ELSE '' END AS 'PdfPath',  
 ISNULL(SB.SalesOrderId,0) SalesOrderId ,ISNULL(WB.WorkOrderId,0) WorkOrderId,ISNULL(ESB.ExchangeSalesOrderId,0)ExchangeSalesOrderId,  
 ISNULL(CS.ReceiptId,0) 'ReciptId'  
   FROM [dbo].CustomerGeneralLedger CL WITH(NOLOCK)  
   LEFT JOIN [dbo].Customer C WITH(NOLOCK) ON CL.CustomerId = C.CustomerId  
   LEFT JOIN [dbo].ManagementStructureModule M WITH(NOLOCK) ON CL.ModuleId = M.ManagementStructureModuleId  
   LEFT JOIN [dbo].SalesOrderBillingInvoicing SB WITH(NOLOCK) ON CL.ReferenceId = SB.SOBillingInvoicingId AND ISNULL(SB.IsProforma,0) = 0  
   LEFT JOIN [dbo].WorkOrderBillingInvoicing WB WITH(NOLOCK) ON CL.ReferenceId = WB.BillingInvoicingId  
   LEFT JOIN [dbo].ExchangeSalesOrderBillingInvoicing ESB WITH(NOLOCK) ON CL.ReferenceId = ESB.SOBillingInvoicingId  
   LEFT JOIN [dbo].CustomerPayments CS ON CL.ReferenceId = CS.ReceiptId  
  
   WHERE CL.MasterCompanyId = @MasterCompanyId AND CL.CustomerId = ISNULL(@CustomerId,0)   
  )    
    
  SELECT * INTO #TempResult FROM Result    
  WHERE(    
   (@GlobalFilter <>'' AND (    
   (CustomerName LIKE '%' +@GlobalFilter+'%') OR        
   (ModuleName LIKE '%' +@GlobalFilter+'%') OR        
   (DocumentNumber LIKE '%' +@GlobalFilter+'%') OR        
   (CreditAmount LIKE '%' +@GlobalFilter+'%') OR        
   (DebitAmount LIKE '%' +@GlobalFilter+'%') OR        
   (Amount LIKE '%' +@GlobalFilter+'%') OR        
   (AccountingPeriod LIKE '%' +@GlobalFilter+'%') OR        
   (UpdatedBy LIKE '%' +@GlobalFilter+'%')         
  ))OR    
  (@GlobalFilter='' AND     
  (ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName+'%') AND         
  (ISNULL(@ModuleName,'') ='' OR ModuleName LIKE '%' + @ModuleName+'%') AND         
  (ISNULL(@DocumentNumber,'') ='' OR DocumentNumber LIKE '%' + @DocumentNumber+'%') AND         
  (ISNULL(@CreditAmount,0) =0 OR CreditAmount LIKE '%' + @CreditAmount+'%') AND         
  (ISNULL(@DebitAmount,0) =0 OR DebitAmount LIKE '%' + @DebitAmount+'%') AND         
  (ISNULL(@Amount,0) =0 OR Amount LIKE '%' + @Amount+'%') AND         
  (ISNULL(@AccountingPeriod,'') ='' OR AccountingPeriod LIKE '%' + @AccountingPeriod+'%') AND         
  (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND        
  (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND        
  (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))        
  )    
    
  Select @Count = COUNT(CustomerGeneralLedgerId) FROM #TempResult        
      
  SELECT *, @Count AS NumberOfItems FROM #TempResult        
  ORDER BY          
  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,              
  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='CustomerName')  THEN CustomerName END ASC,    
  CASE WHEN (@SortOrder=1 AND @SortColumn='ModuleName')  THEN ModuleName END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='DocumentNumber')  THEN DocumentNumber END ASC,        
  CASE WHEN (@SortOrder=1 AND @SortColumn='CreditAmount')  THEN CreditAmount END ASC,    
  CASE WHEN (@SortOrder=1 AND @SortColumn='DebitAmount')  THEN DebitAmount END ASC,    
  CASE WHEN (@SortOrder=1 AND @SortColumn='Amount')  THEN Amount END ASC,    
  CASE WHEN (@SortOrder=1 AND @SortColumn='AccountingPeriod')  THEN AccountingPeriod END ASC,     
        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END ASC,    
  CASE WHEN (@SortOrder=-1 AND @SortColumn='ModuleName')  THEN ModuleName END ASC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='DocumentNumber')  THEN DocumentNumber END ASC,        
  CASE WHEN (@SortOrder=-1 AND @SortColumn='CreditAmount')  THEN CreditAmount END ASC,    
  CASE WHEN (@SortOrder=-1 AND @SortColumn='DebitAmount')  THEN DebitAmount END ASC,    
  CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount')  THEN Amount END ASC,    
  CASE WHEN (@SortOrder=-1 AND @SortColumn='AccountingPeriod')  THEN AccountingPeriod END ASC  
  
  OFFSET @RecordFrom ROWS         
  FETCH NEXT @PageSize ROWS ONLY        
    
 END TRY    
 BEGIN CATCH    
  DECLARE @ErrorLogID INT        
    ,@DatabaseName VARCHAR(100) = db_name()        
    -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------        
    ,@AdhocComments VARCHAR(150) = 'USP_GetCustomerGeneralLedgerListByCustomer'        
    ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))        
    + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))         
    + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))        
    + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))        
    + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))        
    + '@Parameter7 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100))        
    + '@Parameter8 = ''' + CAST(ISNULL(@ModuleName, '') AS varchar(100))        
   + '@Parameter9 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))        
   + '@Parameter19 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))        
   + '@Parameter11 = ''' + CAST(ISNULL(@DocumentNumber  , '') AS varchar(100))        
   + '@Parameter12 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))        
   + '@Parameter13 = ''' + CAST(ISNULL(@CreditAmount , '') AS varchar(100))        
   + '@Parameter13 = ''' + CAST(ISNULL(@DebitAmount , '') AS varchar(100))        
   + '@Parameter13 = ''' + CAST(ISNULL(@Amount , '') AS varchar(100))        
   + '@Parameter13 = ''' + CAST(ISNULL(@AccountingPeriod, '') AS varchar(100))        
   + '@Parameter14 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))      
  ,@ApplicationName VARCHAR(100) = 'PAS'        
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
    EXEC spLogException @DatabaseName = @DatabaseName        
  ,@AdhocComments = @AdhocComments        
  ,@ProcedureParameters = @ProcedureParameters        
  ,@ApplicationName = @ApplicationName        
  ,@ErrorLogID = @ErrorLogID OUTPUT;        
        
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)        
        
    RETURN (1);      
 END CATCH    
END