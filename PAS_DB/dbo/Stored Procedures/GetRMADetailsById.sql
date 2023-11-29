

/*************************************************************           
 ** File:   [GetRMADetailsById]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get RMA Part Details
 ** Purpose:         
 ** Date:   22/04/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    22/04/2022  Moin Bloch     Created
     
-- EXEC GetRMADetailsById 1
************************************************************************/
CREATE   PROCEDURE [dbo].[GetRMADetailsById]
@RMAHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

SELECT [RMADeatilsId]
      ,[RMAHeaderId]
      ,CRD.[ItemMasterId]
      ,CRD.[PartNumber]
      ,CRD.[PartDescription]
      ,[AltPartNumber]
      ,[CustPartNumber]
      ,[SerialNumber]
      ,[StocklineId]
      ,[StocklineNumber]
      ,[ControlNumber]
      ,[ControlId]
      ,[ReferenceId]
      ,[ReferenceNo]
      ,[Qty]
      ,[UnitPrice]
      ,[Amount]
      ,[RMAReasonId]
      ,[RMAReason]
      ,[Notes]
      ,[isWorkOrder]
	  ,CRD.[MasterCompanyId]
	  ,CRD.[CreatedBy]
	  ,CRD.[UpdatedBy]
	  ,CRD.[CreatedDate]
	  ,CRD.[UpdatedDate]
	  ,CRD.[IsActive]
	  ,CRD.[IsDeleted]
	  ,IM.ManufacturerName
	  ,CRD.BillingInvoicingItemId
  FROM [dbo].[CustomerRMADeatils] CRD WITH (NOLOCK) 
  LEFT JOIN ItemMaster IM WITH (NOLOCK) ON CRD.ItemMasterId=IM.ItemMasterId
  WHERE RMAHeaderId = @RMAHeaderId AND CRD.IsDeleted = 0 AND CRD.IsActive = 1;

END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetRMADetailsById' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RMAHeaderId, '') AS varchar(100))			   
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