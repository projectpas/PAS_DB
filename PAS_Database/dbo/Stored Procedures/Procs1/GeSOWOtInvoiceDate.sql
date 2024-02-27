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
    1					unknown			Created
	2	09/27/2023		Moin Bloch		Modify(Formatted the SP)
	3	01/31/2024		Devendra Shekh	added isperforma Flage for WO
	4	 01/02/2024	    AMIT GHEDIYA	added isperforma Flage for SO
	5	 19/02/2024	    Devendra Shekh	removed isperforma and added isinvoiceposted flage for wo
	6	 27/02/2024	    AMIT GHEDIYA	removed isperforma and added IsBilling flage for so

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
				AND ISNULL(sb.IsBilling,0) = 0
				AND sb.CustomerId IN((SELECT Item FROM DBO.SPLITSTRING(@CustomerIDS,',')));    
			
			SELECT @WOSTDT = MIN(wb.InvoiceDate) 
			FROM [dbo].[WorkOrderBillingInvoicing] wb WITH(NOLOCK) WHERE wb.RemainingAmount > 0 
				AND wb.InvoiceStatus = 'Invoiced' AND ISNULL(wb.IsInvoicePosted, 0) = 0
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