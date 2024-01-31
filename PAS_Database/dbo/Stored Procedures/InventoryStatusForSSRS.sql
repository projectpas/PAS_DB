-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <30-1-2024>
-- Description:	<AssetAttributeTypeForSSRS,,>
-- =============================================
CREATE   PROCEDURE InventoryStatusForSSRS	
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
			SELECT * 
			FROM AssetInventoryStatus WITH (NOLOCK)
	END TRY
	BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[InventoryStatusForSSRS]',
        @ProcedureParameters varchar(3000) = '@Parameter1 = ''',
        @ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC Splogexception @DatabaseName = @DatabaseName,
			@AdhocComments = @AdhocComments,
			@ProcedureParameters = @ProcedureParameters,
			@ApplicationName = @ApplicationName,
			@ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
 END