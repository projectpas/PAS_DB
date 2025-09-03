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
	@VendorName NVARCHAR(256),
	@MasterCompanyId int = 0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	BEGIN
		DECLARE @IsExists INT = 0, @VendorId BIGINT = 0;

		IF EXISTS (SELECT TOP 1 [VendorId] FROM [DBO].[Vendor] WITH(NOLOCK) WHERE LTRIM(RTRIM([VendorName])) = LTRIM(RTRIM(@VendorName)) AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0 AND [IsActive] = 1)
		BEGIN
			 SET @VendorId = (SELECT TOP 1 [VendorId] FROM [DBO].[Vendor] WITH(NOLOCK) WHERE LTRIM(RTRIM([VendorName])) = LTRIM(RTRIM(@VendorName)) AND [MasterCompanyId] = @MasterCompanyId)
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