
/*************************************************************           
 ** File:   [GetPurchaseOrderPartById]           
 ** Author:  Subhash saliya
 ** Description: This stored procedure is used to Get Purchase Order Part Details
 ** Purpose:         
 ** Date:   29/06/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    29/06/2022  Subhash saliya     Created
     
-- EXEC GetPurchaseOrderPartById 303
************************************************************************/
create PROCEDURE [dbo].[GetPurchaseOrderPartById]
@PurchaseOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	SELECT pop.PartNumber,pop.ItemMasterId,pop.PurchaseOrderPartRecordId
      FROM [dbo].PurchaseOrderPart pop WITH (NOLOCK) 		
	  WHERE pop.PurchaseOrderId = @PurchaseOrderId and pop.isParent=1 AND pop.IsDeleted = 0 ;

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetPurchaseOrderPartById' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PurchaseOrderId, '') AS varchar(100))			   
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