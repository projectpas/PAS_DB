/*************************************************************             
 ** File:   [USP_GetStandAloneCreditMemoById]             
 ** Author:  AMIT GHEDIYA  
 ** Description: This stored procedure is used to Get Stand Alone Credit Memo Details  
 ** Purpose:           
 ** Date:   29/08/2023        
            
 ** PARAMETERS: @CreditMemoHeaderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date            Author                 Change Description              
 ** --   --------       -----------				--------------------------------            
    1    29/08/2023     AMIT GHEDIYA			Created
	2    01/09/2023     AMIT GHEDIYA			Get Details table data.
	3    04/09/2023     AMIT GHEDIYA			Get Details GLAccount Description for View time.
	4    05/09/2023     AMIT GHEDIYA			Get Reason for details view.
	5    11/09/2023     AMIT GHEDIYA			Get IsEnforce field for approved process.
	6    12/09/2023     AMIT GHEDIYA			Get LE field for Item List.
       
-- EXEC USP_GetStandAloneCreditMemoById 8  
  
************************************************************************/  
CREATE        PROCEDURE [dbo].[USP_GetStandAloneCreditMemoById]  
	@CreditMemoHeaderId BIGINT,
	@Opr INT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
	IF(@Opr = 1)
	BEGIN
		SELECT CM.[CreditMemoHeaderId]  
		  ,CM.[CreditMemoNumber]  
		  ,CM.[RMAHeaderId]  
		  ,CM.[StatusId]  
		  ,CM.[Status]  
		  ,CM.[CustomerId]  
		  ,CM.[CustomerName]  
		  ,CM.[CustomerCode]  
		  ,CM.[CustomerContactId]  
		  ,CT.[FirstName] + ' ' + CT.[LastName] + '-' + CT.[WorkPhone] AS 'CustomerContact'
		  ,CM.[CustomerContactPhone]  
		  ,CM.[RequestedById]  
		  ,CM.[RequestedBy]  
		  ,CM.[Notes]  
		  ,CM.[ManagementStructureId]  
		  ,CM.[IsEnforce]
		  ,CM.[MasterCompanyId]  
		  ,CM.[CreatedBy]  
		  ,CM.[UpdatedBy]  
		  ,CM.[CreatedDate]  
		  ,CM.[UpdatedDate]  
		  ,CM.[IsActive]  
		  ,CM.[IsDeleted]  
		  ,CM.[IsWorkOrder]  
		  ,ISNULL(CM.Amount,0) Amount
		  ,CM.[AcctingPeriodId]
	  FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
	  LEFT JOIN [dbo].[CustomerContact] CC WITH (NOLOCK) ON CM.CustomerContactId = CC.CustomerContactId
	  LEFT JOIN [dbo].[Contact] CT WITH (NOLOCK) ON CC.ContactId = CT.ContactId
	  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId; 
	END
	IF(@Opr = 2)
	BEGIN
		SELECT CMD.[StandAloneCreditMemoDetailId]
			  ,CMD.[CreditMemoHeaderId]  
			  ,CMD.[GlAccountId]  
			  ,CMD.[Reason]  
			  ,CMD.[Qty]
			  ,CMD.[Rate]
			  ,CMD.[Amount]
			  ,GL.[AccountDescription]
			  ,CMD.[ManagementStructureId]
			  ,CMD.[LastMSLevel]
			  ,CMD.[AllMSlevels]
	   FROM [dbo].[StandAloneCreditMemoDetails] CMD WITH (NOLOCK)   
	   LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON CMD.GlAccountId = GL.GLAccountId
	   WHERE CMD.CreditMemoHeaderId = @CreditMemoHeaderId AND CMD.IsActive = 1; 
	END
END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetStandAloneCreditMemoById'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CreditMemoHeaderId, '') + ''  
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