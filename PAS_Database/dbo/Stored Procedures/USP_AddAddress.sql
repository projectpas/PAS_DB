/*************************************************************
** File: [USP_AddAddress]
** Author:   Ayushi Patel
** Description: Add Address
** Purpose:  
** Date:     07-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    07-07-2025   Ayushi Patel   Created

-- EXEC USP_AddAddress 4797
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddAddress]
(
    @Address1 NVARCHAR(100),
    @Address2 NVARCHAR(100) = NULL,
    @Address3 NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(50) = NULL,
    @StateOrProvince NVARCHAR(100) = NULL,
    @City NVARCHAR(100) = NULL,
    @CountryId BIGINT = NULL,
    @MasterCompanyId BIGINT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100),
    @AddressId BIGINT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO [dbo].[Address]
        (
            Line1,
            Line2,
            Line3,
            PostalCode,
            StateOrProvince,
            City,
            CountryId,
            MasterCompanyId,
            IsActive,
            IsDeleted,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            UpdatedDate
        )
        VALUES
        (
            @Address1,
            @Address2,
            @Address3,
            @PostalCode,
            @StateOrProvince,
            @City,
            @CountryId,
            @MasterCompanyId,
            1,                  -- IsActive = true
            0,                  -- IsDeleted = false
            @CreatedBy,
            @UpdatedBy,
            GETUTCDATE(),
            GETUTCDATE()
        );

        SET @AddressId = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        DECLARE @ErrorProcedure NVARCHAR(200) = ERROR_PROCEDURE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME();
        EXEC spLogException 
            @DatabaseName = @DatabaseName, 
            @AdhocComments = 'USP_AddAddress', 
            @ProcedureParameters = '', 
            @ApplicationName = 'PAS',
            @ErrorLogID = @ErrorLogID OUTPUT;

        THROW;
    END CATCH
END