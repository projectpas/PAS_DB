/*************************************************************           
 ** File:   [dbo].[GetBillingInvoiceByShipping]          
 ** Author:   SUBHASH Patel
 ** Description: Get Billing Data based on Shipping id.
 ** Date:    27/05/2021 
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    27/05/2021   Subhash Patel    Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment

**************************************************************/ 
CREATE PROCEDURE [dbo].[GetWorkorderBillingInvoiceByShipping]
	@WorkOrderShippingId bigint
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON 
BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT wop.WorkOrderId,
						wop.id as WorkOrderPartId,
						wos.WorkOrderShippingId,
						wos.ShipDate,wo.WorkOrderNum as WorkOrderNumber,
						CONCAT(emp.FirstName,' ',emp.LastName) as EmployeeName,
						wo.EmployeeId,wo.OpenDate,'' as CustomerRef,
						wo.CustomerId, 
						CONCAT(empsp.FirstName,' ',empsp.LastName) as SalesPerson,
						wo.SalesPersonId,
						cf.CreditLimit, 
						cf.CreditTermsId,ct.[Name] as CreditTerm,
						cf.CurrencyId,
						0 as TypeId,
						'' as RevType, 
						wosi.QtyShipped as NoofPieces
					FROM DBO.WorkOrderShipping wos WITH (NOLOCK) 
						INNER JOIN DBO.WorkOrderPartNumber wop WITH (NOLOCK)  ON wop.WorkOrderId = wos.WorkOrderId
						INNER JOIN DBO.WorkOrderShippingItem wosi WITH (NOLOCK)  ON wosi.WorkOrderShippingId = wos.WorkOrderShippingId 
						INNER JOIN DBO.WorkOrder wo WITH (NOLOCK)  ON wo.WorkOrderId = wop.WorkOrderId
						INNER JOIN DBO.Customer co WITH (NOLOCK)  ON co.CustomerId = wo.CustomerId
						LEFT JOIN DBO.CustomerFinancial cf WITH (NOLOCK)  ON cf.CustomerId = co.CustomerId
						INNER JOIN DBO.CreditTerms ct WITH (NOLOCK)  ON ct.CreditTermsId = cf.CreditTermsId
						LEFT JOIN DBO.Employee emp WITH (NOLOCK)  ON emp.EmployeeId = wo.EmployeeId
						LEFT JOIN DBO.Employee empsp WITH (NOLOCK)  ON empsp.EmployeeId = wo.SalesPersonId
				WHERE wos.WorkOrderShippingId = @WorkOrderShippingId;
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkorderBillingInvoiceByShipping' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderShippingId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
END