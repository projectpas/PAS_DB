/*********************             
 ** File:   USP_SearchCreditMemoDataForRefund           
 ** Author:  Devendra Shekh   
 ** Description: Get Credit Memo data for refund
 ** Purpose:           
 ** Date: 17-OCT-2023       
            
    
 **********************             
  ** Change History             
 **********************             
 ** PR   Date			Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    17/10/2023		Devendra Shekh        Created  
   
 -- exec USP_SearchCreditMemoDataForRefund 
**********************/   
  
CREATE   PROCEDURE [dbo].[USP_SearchCreditMemoDataForRefund]  
	@CustomerId BIGINT = NULL,
	@MasterCompanyId INT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY    
   
     BEGIN
		SELECT DISTINCT	CM.[CreditMemoHeaderId]  
						,CM.[CreditMemoNumber]  
						,CM.[StatusId]  
						,CM.[Status]  
						,CM.[CustomerId]  
						,CM.[CustomerName]  
						,CM.[CustomerCode]  
						,CM.[CreatedDate]  
						,ISNULL(CM.[Amount], 0) AS [Amount]  
				FROM dbo.CreditMemo CM WITH (NOLOCK)           
				WHERE ((CM.IsDeleted = 0) AND (CM.IsActive = 1)) AND CM.MasterCompanyId=@MasterCompanyId AND CM.CustomerId = @CustomerId
				AND CM.StatusId  = (SELECT Id FROM [DBO].[CreditMemoStatus] WITH(NOLOCK) WHERE [Name] = 'Posted')
		END
  
 END TRY      
 BEGIN CATCH  
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
        , @AdhocComments     VARCHAR(150)    = 'USP_SearchCreditMemoDataForRefund'   
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100))  
      + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))   
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