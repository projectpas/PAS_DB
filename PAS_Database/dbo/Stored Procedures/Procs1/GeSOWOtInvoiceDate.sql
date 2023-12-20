/*************************************************************           
 ** File:   [GeSOWOtInvoiceDate]
 ** Author: unknown
 ** Description: This stored procedure is used FIRST INVOICE DATE
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------      -------		--------------------------------          
    1                 unknown        Created
	2    09/27/2023   Moin Bloch     Modify(Formatted the SP)

-- EXEC GeSOWOtInvoiceDate '74'  
************************************************************************/
CREATE   PROCEDURE [dbo].[GeSOWOtInvoiceDate]  
@CustomerIDS NVARCHAR(100) = NULL  
AS  
BEGIN   
     SET NOCOUNT ON;  
     SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
	 BEGIN TRY  
			DECLARE @SOSTDT datetime2(7) = NULL;   
			DECLARE @WOSTDT datetime2(7) = NULL;   
			DECLARE @StartDate datetime2(7) = NULL;  
			
			SELECT @SOSTDT = MIN(sb.InvoiceDate) 
			FROM [dbo].[SalesOrderBillingInvoicing] sb WITH(NOLOCK)WHERE sb.RemainingAmount > 0 
				AND sb.InvoiceStatus = 'Invoiced' 
				AND sb.CustomerId IN((SELECT Item FROM DBO.SPLITSTRING(@CustomerIDS,',')));    
			
			SELECT @WOSTDT = MIN(wb.InvoiceDate) 
			FROM [dbo].[WorkOrderBillingInvoicing] wb WITH(NOLOCK) WHERE wb.RemainingAmount > 0 
				AND wb.InvoiceStatus = 'Invoiced' 
				AND wb.CustomerId IN ((SELECT Item FROM DBO.SPLITSTRING(@CustomerIDS,',')));    
			
			IF(@SOSTDT IS NULL OR @SOSTDT = '')  
			BEGIN   
				SET @StartDate = @WOSTDT;    
			END   
			ELSE   
			BEGIN    
				IF(@WOSTDT IS NULL OR @WOSTDT = '')    
				BEGIN          
					SET @StartDate = @SOSTDT;    
				END    
				ELSE   
				BEGIN     
					IF(@SOSTDT < @WOSTDT)     
					BEGIN      
						SET @StartDate = @SOSTDT;     
					END     
					ELSE     
					BEGIN      
						SET @StartDate = @WOSTDT;      
					END    
				END   
			END  
		    IF(ISNULL(@StartDate, '') != '')  
		    BEGIN  
				SELECT CAST(@StartDate AS DATE) AS InvoiceDate  
		    END  
		    ELSE  
		    BEGIN  
				SELECT NULL AS InvoiceDate  
		    END  
	END TRY      
 BEGIN CATCH        
 DECLARE @ErrorLogID INT  
   ,@DatabaseName VARCHAR(100) = db_name()  
   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
   ,@AdhocComments VARCHAR(150) = 'GeSOWOtInvoiceDate'  
   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerIDS, '') AS varchar(100))  
   ,@ApplicationName VARCHAR(100) = 'PAS'  
  
  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  EXEC spLogException @DatabaseName = @DatabaseName  
   ,@AdhocComments = @AdhocComments  
   ,@ProcedureParameters = @ProcedureParameters  
   ,@ApplicationName = @ApplicationName  
   ,@ErrorLogID = @ErrorLogID OUTPUT;  
  
  RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    ,16  
    ,1  
    ,@ErrorLogID  
    )  
  
  RETURN (1);             
 END CATCH  
END