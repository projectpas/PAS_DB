
/*************************************************************           
 ** File:  [GetCreditMemoPartsDetailsById]           
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
     
-- EXEC GetCreditMemoPartsDetailsById 7
************************************************************************/
CREATE PROCEDURE [dbo].[GetCreditMemoPartsDetailsById]
@CreditMemoHeaderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	SELECT CM.[CreditMemoDetailId]           
          ,CM.[ItemMasterId]
          ,CM.[PartNumber]
		 FROM [dbo].[CreditMemoDetails] CM WITH (NOLOCK) 
        WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId AND CM.IsDeleted = 0 ;

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoPartsDetailsById' 
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