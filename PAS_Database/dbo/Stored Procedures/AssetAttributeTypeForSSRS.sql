-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <30-1-2024>
-- Description:	<AssetAttributeTypeForSSRS,,>
-- =============================================
CREATE   PROCEDURE [dbo].[AssetAttributeTypeForSSRS]	
@MasterCompanyId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
			SELECT AAT.AssetAttributeTypeId, AAT.AssetAttributeTypeName, AAT.MasterCompanyId
			FROM AssetAttributeType AAT WITH (NOLOCK)
			WHERE AAT.MasterCompanyId=@MasterCompanyId AND AAT.IsActive = 1 AND AAT.IsDeleted = 0;	
	END TRY
	BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[AssetAttributeTypeForSSRS]',
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