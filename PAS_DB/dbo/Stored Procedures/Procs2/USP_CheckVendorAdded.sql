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
    1    29/07/2025    Amit Ghediya			Created
    2    26/09/2025    Devendra Shekh		Added VendorId Select From Vendor
**************************************************************
 EXEC USP_CheckVendorAdded 'RAINCO OF DALLAS',1 
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_CheckVendorAdded] 
	@VendorName VARCHAR(150) = NULL,
	@MasterCompanyId int = 0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	BEGIN
		DECLARE @IsExists INT = 0, @VendorId BIGINT = 0;

		SELECT TOP 1 @VendorId = [VendorId] FROM [DBO].[VendorRFQPart] WITH(NOLOCK) WHERE VendorName = @VendorName AND [MasterCompanyId] = @MasterCompanyId;

		IF(ISNULL(@VendorId,0) > 0 )
		BEGIN
			 SET @VendorId = (SELECT [VendorId] FROM [DBO].[Vendor] WITH(NOLOCK) WHERE [VendorId] = @VendorId AND [MasterCompanyId] = @MasterCompanyId  AND IsActive = 1 AND IsDeleted = 0)
			 SET @IsExists = 1;
		END

		IF(ISNULL(@VendorId,0) = 0 )
		BEGIN
			IF EXISTS(SELECT 1 FROM [dbo].[Vendor] WITH(NOLOCK) WHERE UPPER(TRIM([VendorName])) = UPPER(TRIM(@VendorName)) AND [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0)
			BEGIN
				SET @VendorId = (SELECT TOP 1 [VendorId] FROM [dbo].[Vendor] WITH(NOLOCK) WHERE UPPER(TRIM([VendorName])) = UPPER(TRIM(@VendorName)) AND [MasterCompanyId] = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0)
				SET @IsExists = 1;
			END
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