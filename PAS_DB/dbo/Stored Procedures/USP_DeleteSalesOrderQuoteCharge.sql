/*************************************************************           
 ** File:   [USP_DeleteSalesOrderQuoteCharge]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to delete SOQ charges and Recalculate SOQ Part Total Cost    
 ** Purpose:         
 ** Date:   17/03/2026
          
 ** PARAMETERS:
 
 ** RETURN VALUE:

 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    17/03/2026   Vishal Suthar		Created
     
 EXECUTE USP_UpdateSOQPartCostDetails 745, 551, 'ADMIN User', 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_DeleteSalesOrderQuoteCharge]
(
    @SalesOrderQuoteChargesId BIGINT,
    @UpdatedBy VARCHAR(256)
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON    
	
    BEGIN TRY
        UPDATE dbo.SalesOrderQuoteCharges
        SET 
            IsDeleted = 1,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETDATE()
        WHERE SalesOrderQuoteChargesId = @SalesOrderQuoteChargesId;
        
		DECLARE @MasterCompanyId BIGINT = 0;
		DECLARE @SalesOrderQuoteId BIGINT = 0;
		DECLARE @SalesOrderQuotePartId BIGINT = 0;

		SELECT @MasterCompanyId = MasterCompanyId, @SalesOrderQuoteId = SalesOrderQuoteId, @SalesOrderQuotePartId = SalesOrderQuotePartId 
		FROM DBO.SalesOrderQuoteCharges WITH (NOLOCK) WHERE SalesOrderQuoteChargesId = @SalesOrderQuoteChargesId;
		
		EXEC dbo.USP_UpdateSOQPartCostDetails @SalesOrderQuoteId, @SalesOrderQuotePartId, @UpdatedBy, @MasterCompanyId;
    END TRY
    BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
		ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments varchar(150) = 'USP_DeleteSalesOrderQuoteCharge',
        @ProcedureParameters varchar(3000) = '@SalesOrderQuoteChargesId = ''' + CAST(ISNULL(@SalesOrderQuoteChargesId, '') AS varchar(100)),
        @ApplicationName varchar(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName,
		@AdhocComments = @AdhocComments,
		@ProcedureParameters = @ProcedureParameters,
		@ApplicationName = @ApplicationName,
		@ErrorLogID = @ErrorLogID OUTPUT;
	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1);
	END CATCH
END