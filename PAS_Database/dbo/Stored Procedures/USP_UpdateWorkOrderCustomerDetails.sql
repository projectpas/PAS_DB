/*********************             
 ** File:   UPDATE CUSTOMER IN WO           
 ** Author:  HEMANT SALIYA  
 ** Description: This SP Is Used to Update Customer from WO
 ** Purpose:           
 ** Date:   14-APRIL-2024
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    04/16/2024   HEMANT SALIYA      Created  
   
  
*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_UpdateWorkOrderCustomerDetails] 	
@CustomerId BIGINT = NULL,  
@WorkOrderPartNoId BIGINT = NULL,
@MasterCompanyId INT = NULL  
	
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY
		DECLARE @WorkOrderId BIGINT = NULL;
		DECLARE @CustomerContactId BIGINT = NULL;
		DECLARE @SalesPersonId BIGINT = NULL;
		DECLARE @CSRId BIGINT = NULL;
		DECLARE @ContactNumber VARCHAR(30) = NULL;
		DECLARE @CustomerName VARCHAR(30) = NULL;
		DECLARE @CustomerCode VARCHAR(30) = NULL;
		DECLARE @CustomerType VARCHAR(30) = NULL;

		SELECT @WorkOrderId = WorkOrderId FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE ID = @WorkOrderPartNoId

		SELECT	@CustomerName = C.[Name], @CustomerCode = C.CustomerCode, @CustomerType = CT.CustomerTypeName,
				@CustomerContactId = CC.CustomerContactId, 
				@ContactNumber = CASE WHEN ISNULL(CO.WorkPhone, '') != '' THEN CO.WorkPhone ELSE CO.MobilePhone END  
		FROM dbo.Customer C WITH(NOLOCK) 
			JOIN dbo.CustomerContact CC WITH(NOLOCK) ON C.CustomerId = CC.CustomerId AND ISNULL(IsDefaultContact, 0) = 1
			JOIN dbo.Contact CO WITH(NOLOCK) ON CO.ContactId = CC.ContactId 
			JOIN dbo.CustomerType CT WITH(NOLOCK) ON CT.CustomerTypeId = C.CustomerTypeId 
			LEFT JOIN dbo.CustomerFinancial CF WITH(NOLOCK) ON CF.CustomerId = C.CustomerId 
			LEFT JOIN dbo.CreditTerms CTs WITH(NOLOCK) ON CF.CreditTermsId = CTs.CreditTermsId 
		WHERE C.CustomerId = @CustomerId

		IF(@CustomerId > 0)
		BEGIN
			SELECT * FROM dbo.WorkOrderPartNumber 
			SELECT * FROM dbo.ReceivingCustomerWork
			SELECT * FROM dbo.Stockline
			SELECT * FROM dbo.WorkOrderQuote
			SELECT * FROM dbo.SubWorkOrder
			SELECT * FROM dbo.WorkOrderWorkFlow

			UPDATE WorkOrder SET CustomerId =  @CustomerId WHERE WorkOrderId = @WorkOrderId

			UPDATE WorkOrder
				SET CustomerName = C.[Name], CustomerContactId = CC.CustomerContactId ,
					CreditTerms = CTs.[Name] , CreditTermId = CF.CreditTermsId ,
					[Days] = CTs.[Days], CustomerType = CT.CustomerTypeName, NetDays = CTs.NetDays,
					PercentId = CTs.PercentId , SalesPersonId = CS.PrimarySalesPersonId, CSRId = CS.CsrId, 
					CreditLimit = CF.CreditLimit
			FROM dbo.Customer C WITH(NOLOCK) 
				JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN dbo.CustomerContact CC WITH(NOLOCK) ON C.CustomerId = CC.CustomerId AND ISNULL(IsDefaultContact, 0) = 1
				LEFT JOIN dbo.CustomerType CT WITH(NOLOCK) ON CT.CustomerTypeId = C.CustomerTypeId 
				LEFT JOIN dbo.Contact CO WITH(NOLOCK) ON CO.ContactId = CC.ContactId 
				LEFT JOIN dbo.CustomerFinancial CF WITH(NOLOCK) ON CF.CustomerId = C.CustomerId 
				LEFT JOIN dbo.CreditTerms CTs WITH(NOLOCK) ON CF.CreditTermsId = CTs.CreditTermsId 
				LEFT JOIN dbo.CustomerSales CS WITH(NOLOCK) ON CS.CustomerId = C.CustomerId 
			WHERE WorkOrderId = @WorkOrderId AND C.CustomerId = WO.CustomerId

		END
  
 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'SearchCreditMemoData'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))   
        , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
        exec spLogException   
                @DatabaseName           = @DatabaseName  
                , @AdhocComments          = @AdhocComments  
                , @ProcedureParameters = @ProcedureParameters  
                , @ApplicationName        =  @ApplicationName  
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
        RETURN(1);  
 END CATCH  
END