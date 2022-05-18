

/*************************************************************           
 ** File:   [GetCreditMemoHeaderDetails]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to get Credit Memo Details
 ** Purpose:         
 ** Date:   18/04/2022      
          
 ** PARAMETERS: @RMAHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/04/2022  Moin Bloch     Created
     
-- EXEC GetCreditMemoHeaderDetails 1
************************************************************************/
CREATE PROCEDURE [dbo].[GetCreditMemoHeaderDetails]
@RMAHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	SELECT  [RMAHeaderId]
	   ,[RMANumber]
	   ,[CustomerId]
	   ,[CustomerName]
	   ,[CustomerCode]
	   ,[CustomerContactId]
	   ,[ContactInfo]
	   ,[OpenDate]
	   ,[InvoiceId]
	   ,[InvoiceNo]
	   ,[InvoiceDate]
	   ,[RMAStatusId]
	   ,[RMAStatus]
	   ,[Iswarranty]
	   ,[ValidDate]
	   ,[RequestedId]
	   ,[Requestedby]
	   ,[ApprovedbyId]
	   ,[Approvedby]
	   ,[ApprovedDate]
	   ,[ReturnDate]
	   ,[WorkOrderId]
	   ,[WorkOrderNum]
	   ,[ManagementStructureId]
	   ,[Notes]
	   ,[Memo]
	   ,[MasterCompanyId]
	   ,[CreatedBy]
	   ,[UpdatedBy]
	   ,[CreatedDate]
	   ,[UpdatedDate]
       ,[IsActive]
 	   ,[IsDeleted]
	   ,[isWorkOrder]
	   ,[ReferenceId]

   FROM [dbo].[CustomerRMAHeader] WITH (NOLOCK) WHERE RMAHeaderId = @RMAHeaderId;

END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoHeaderDetails' 
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