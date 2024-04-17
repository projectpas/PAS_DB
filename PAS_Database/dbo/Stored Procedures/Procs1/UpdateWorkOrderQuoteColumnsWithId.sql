/*************************************************************           
 ** File:   [UpdateWorkOrderQuoteColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This Stored Procedure is Used WOQ Details Based in WOQ Id.    
 ** Purpose:         
 ** Date:   10/13/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    10/13/2021   Hemant Saliya Created
	2	 10-Apr-2024  Bhargav Saliya  CreditTerms Changes
     
-- EXEC [UpdateWorkOrderQuoteColumnsWithId] 6
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateWorkOrderQuoteColumnsWithId]
@WorkOrderQuoteId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				UPDATE WOQ SET 
					WOQ.CustomerName = C.Name,
					WOQ.CustomerContact = CO.FirstName + ' ' + CO.LastName,
					WOQ.CreditLimit = CF.CreditLimit,
					WOQ.CreditTerms = CASE WHEN ISNULL(WO.CreditTerms,'') != '' THEN  WO.CreditTerms ELSE CT.[Name] END
				FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
					INNER JOIN dbo.Customer C WITH(NOLOCK) ON WOQ.CustomerId = C.CustomerId
					LEFT JOIN dbo.CustomerContact CC WITH(NOLOCK) ON C.CustomerId = CC.CustomerId AND IsDefaultContact = 1					
					LEFT JOIN dbo.Contact CO WITH(NOLOCK) ON CO.ContactId = CC.ContactId 
					LEFT JOIN dbo.CustomerFinancial CF  WITH(NOLOCK) ON C.CustomerId = CF.CustomerId
					LEFT JOIN dbo.CreditTerms CT WITH(NOLOCK) ON CF.CreditTermsId = CT.CreditTermsId
					LEFT JOIN DBO.WorkOrder WO WITH(NOLOCK) ON WOQ.WorkOrderId = WO.WorkOrderId
				WHERE WOQ.WorkOrderQuoteId = @WorkOrderQuoteId

				UPDATE WOQA SET 
					WOQA.InternalSentToName = (INST.FirstName + ' ' + INST.LastName)
				FROM [dbo].[WorkOrderApproval] WOQA WITH(NOLOCK)
				LEFT JOIN DBO.Employee INST WITH (NOLOCK) ON INST.EmployeeId = WOQA.InternalSentToId
				WHERE WOQA.WorkOrderQuoteId = @WorkOrderQuoteId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteId, '') + ''
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
		END CATCH
END