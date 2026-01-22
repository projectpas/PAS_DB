/*************************************************************           
 ** File:   [USP_CreateOrUpdateVendorInternationalShipping]        
 ** Author:   Ayushi Patel
 ** Description: Create Or Update Vendor International Shipping
 ** Purpose:         
 ** Date:  16/05/2025 
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 16-MAY-2025   AYUSHI PATEL 		Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_CreateOrUpdateVendorInternationalShipping]
    @VendorInternationalShippingId BIGINT,
    @VendorId BIGINT,
    @ExportLicense VARCHAR(200) = NULL,
    @StartDate DATETIME2(7) = NULL,
    @Amount DECIMAL(18, 3) = NULL,
    @IsPrimary BIT,
    @Description VARCHAR(250) = NULL,
    @ExpirationDate DATETIME = NULL,
    @ShipToCountryId SMALLINT,
    @MasterCompanyId INT,
    @Username VARCHAR(256) ,
    @IsActive BIT,
    @IsDeleted BIT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    BEGIN TRY

        IF @IsPrimary = 1
        BEGIN
            UPDATE dbo.VendorInternationalShipping
            SET IsPrimary = 0,
                UpdatedDate = GETUTCDATE(),
                UpdatedBy = @Username
            WHERE VendorId = @VendorId
              AND ISNULL(IsPrimary,0) = 1
              AND (@VendorInternationalShippingId = 0 OR VendorInternationalShippingId <> @VendorInternationalShippingId);
        END

        IF @VendorInternationalShippingId > 0
        BEGIN
            UPDATE dbo.VendorInternationalShipping
            SET
                VendorId = @VendorId,
                ExportLicense = @ExportLicense,
                StartDate = @StartDate,
                Amount = @Amount,
                IsPrimary = @IsPrimary,
                Description = @Description,
                ExpirationDate = @ExpirationDate,
                ShipToCountryId = @ShipToCountryId,
                MasterCompanyId = @MasterCompanyId,
                UpdatedBy = @Username,
                UpdatedDate = GETUTCDATE(),
                IsActive = @IsActive,
                IsDeleted = @IsDeleted
            WHERE VendorInternationalShippingId = @VendorInternationalShippingId;
        END
        ELSE
        BEGIN
            INSERT INTO DBO.VendorInternationalShipping
            (
                VendorId,
                ExportLicense,
                StartDate,
                Amount,
                IsPrimary,
                Description,
                ExpirationDate,
                ShipToCountryId,
                MasterCompanyId,
                CreatedBy,
                UpdatedBy,
                CreatedDate,
                UpdatedDate,
                IsActive,
                IsDeleted
            )
            VALUES
            (
                @VendorId,
                @ExportLicense,
                @StartDate,
                @Amount,
                @IsPrimary,
                @Description,
                @ExpirationDate,
                @ShipToCountryId,
                @MasterCompanyId,
                @Username,
                @Username,
                GETUTCDATE(),
                GETUTCDATE(),
                @IsActive,
                @IsDeleted
            );
        END
    END TRY
    BEGIN CATCH
	SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CreateOrUpdateVendorInternationalShipping' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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
END;