/*************************************************************           
 ** File:   [GetCreditMemoDetailsById]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get Credit Memo Part Details
 ** Purpose:         
 ** Date:   25/04/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    25/04/2022  Moin Bloch     Created
     
-- EXEC GetCreditMemoDetailsById 34
************************************************************************/
CREATE   PROCEDURE [dbo].[GetCreditMemoDetailsById]
@CreditMemoHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	SELECT CM.[CreditMemoDetailId]
          ,CM.[CreditMemoHeaderId]
		  ,CM.[RMADeatilsId]
          ,CM.[RMAHeaderId]
          ,CM.[InvoiceId]
          ,CM.[ItemMasterId]
          ,CM.[PartNumber]
          ,CM.[PartDescription]
          ,CM.[AltPartNumber]
          ,CM.[CustPartNumber]
          ,CM.[SerialNumber]
          ,CM.[Qty]
          ,CM.[UnitPrice]
          ,CM.[Amount]
          ,CM.[ReasonId]
          ,CM.[Reason]
          ,CM.[StocklineId]
          ,CM.[StocklineNumber]
          ,CM.[ControlNumber]
          ,CM.[ControlId]
          ,CM.[ReferenceId]
          ,CM.[ReferenceNo]
          ,CM.[SOWONum]
          ,CM.[Notes]
          ,CM.[IsWorkOrder]
          ,CM.[MasterCompanyId]
          ,CM.[CreatedBy]
          ,CM.[UpdatedBy]
          ,CM.[CreatedDate]
          ,CM.[UpdatedDate]
          ,CM.[IsActive]
          ,CM.[IsDeleted]
		  ,CM.[BillingInvoicingItemId]
		  ,CASE WHEN CA.ActionId = 5 THEN 1 ELSE 0 END  'IsApproved'
		  ,IM.ManufacturerName
  FROM [dbo].[CreditMemoDetails] CM WITH (NOLOCK) 		
	   LEFT JOIN [dbo].[CreditMemoApproval] CA WITH (NOLOCK) ON CA.CreditMemoDetailId = CM.CreditMemoDetailId
	   LEFT JOIN ItemMaster IM WITH (NOLOCK) ON CM.ItemMasterId=IM.ItemMasterId
	  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId AND CM.IsDeleted = 0 ;

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoDetailsById' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CreditMemoHeaderId, '') AS varchar(100))			   
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