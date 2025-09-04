/*************************************************************           
 ** File:   [USP_CheckVendorAdded]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used to check is vensor already added or not
 ** Date:   29/07/2025
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date          Author  			Change Description            
 ** --   --------      -------			---------------------------     
    1    29/07/2025    Amit Ghediya     Created
**************************************************************
 EXEC USP_CheckVendorAdded 'AMETEK MRO',1 
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_CheckVendorAdded] 
	@ILSRFQDetailId BIGINT = 0,
	@ItemId BIGINT = 0,
	@ItemSupplierPartId BIGINT = 0,
	@MasterCompanyId int = 0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	BEGIN
		DECLARE @IsExists INT = 0, @VendorId BIGINT = 0;

		SELECT @VendorId = [VendorId] FROM [DBO].[VendorRFQPart] WITH(NOLOCK) WHERE [ILSRFQDetailId] = @ILSRFQDetailId AND [ItemId] = @ItemId AND [ItemSupplierPartId] = @ItemSupplierPartId AND [MasterCompanyId] = @MasterCompanyId;

		IF(ISNULL(@VendorId,0) > 0 )
		BEGIN
			 SET @VendorId = (SELECT [VendorId] FROM [DBO].[Vendor] WITH(NOLOCK) WHERE [VendorId] = @VendorId AND [MasterCompanyId] = @MasterCompanyId)
			 SET @IsExists = 1;
		END

		SELECT @IsExists 'Exists', @VendorId 'VendorId'
	END
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_CheckVendorAdded]',
            @ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END