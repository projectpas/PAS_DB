
/*************************************************************           
 ** File:   [UpdateCustomerRMADetails]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer Invoicedataby InvoiceId   
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/18/2022   Subhash Saliya Created
	
 -- exec [UpdateCustomerRMADetails] 1    
**************************************************************/ 

CREATE PROCEDURE [dbo].[UpdateCustomerRMADetails]
@RMAHeaderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
	BEGIN TRAN
	 
		UPDATE CM SET		
		CM.RMAStatus = CMS.Status,
		CM.RequestedBy = ISNULL(e.FirstName,'') + ' ' + ISNULL(e.LastName,''),		
		CM.ApprovedBy = ISNULL(AP.FirstName,'') + ' ' + ISNULL(AP.LastName,'')

		FROM dbo.CustomerRMAHeader CM WITH (NOLOCK)		
		LEFT JOIN dbo.RMAStatus CMS WITH (NOLOCK) on CMS.RMAStatusId = CM.RMAStatusId
		LEFT JOIN dbo.Employee E WITH (NOLOCK) on E.EmployeeId =  CM.RequestedId
		LEFT JOIN dbo.Employee AP WITH (NOLOCK) ON AP.EmployeeId = CM.ApprovedbyId		
		WHERE CM.RMAHeaderId = @RMAHeaderId 

		
		SELECT RMANumber as value FROM dbo.CustomerRMAHeader CM WITH (NOLOCK) WHERE RMAHeaderId = @RMAHeaderId;	

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateCustomerRMADetails' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RMAHeaderId, '') + ''
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