/*************************************************************
** File:  [USP_AddUpdateVendorCapabilities]
** Author:   Ayushi Patel
** Description: Add Update Vendor Capability
** Purpose:  
** Date:     02-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    02-07-2025   Ayushi Patel   Created

-- EXEC USP_AddUpdateVendorCapabilities 4797
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateVendorCapabilities]
    @VendorCapabilityTypeTVP [dbo].VendorCapabilityTVP READONLY,
    @VendorId BIGINT,
    @UpdatedBy VARCHAR(256),
    @MasterCompanyId INT,
    @OutputMessage NVARCHAR(MAX) OUTPUT,
    @IsDuplicate BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
	SET @IsDuplicate = 0;
        BEGIN TRANSACTION;

        -- Update Vendor
        UPDATE V
        SET V.UpdatedBy = @UpdatedBy,
            V.UpdatedDate = GETUTCDATE()
        FROM dbo.Vendor V
        WHERE V.VendorId = @VendorId;

        -- Prepare for iteration
        IF OBJECT_ID('tempdb..#TempVendorCapabilities') IS NOT NULL DROP TABLE #TempVendorCapabilities;

        SELECT IDENTITY(INT, 1, 1) AS RowNum, *
        INTO #TempVendorCapabilities
        FROM @VendorCapabilityTypeTVP;

        DECLARE 
            @Row INT = 1,
            @TotalRows INT = (SELECT COUNT(*) FROM #TempVendorCapabilities),
            @Msg NVARCHAR(MAX) = '',
            @CompanyName NVARCHAR(200) = '',
            @PartNum VARCHAR(100),
            @CapDesc VARCHAR(200);

        SELECT TOP 1 @CompanyName = CompanyName FROM dbo.MasterCompany WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;

        WHILE @Row <= @TotalRows
        BEGIN
            DECLARE 
                @VendorCapabilityId BIGINT,
                @CapabilityTypeId INT,
                @ItemMasterId BIGINT,
                @VendorRanking INT,
                @IsPMA BIT,
                @IsDER BIT,
                @Cost DECIMAL(18,2),
                @TAT NVARCHAR(100),
                @Memo NVARCHAR(MAX),
                @IsActive BIT,
                @IsDeleted BIT,
                @CapabilityTypeDescription NVARCHAR(200),
                @PartDescription NVARCHAR(200),
                @ManufacturerId BIGINT,
                @ManufacturerName NVARCHAR(200),
                @CostDate DATETIME2(7),
                @CurrencyId BIGINT,
                @Currency NVARCHAR(50),
                @EmployeeId BIGINT;

            SELECT
                @VendorCapabilityId = VendorCapabilityId,
                @CapabilityTypeId = CapabilityTypeId,
                @ItemMasterId = ItemMasterId,
                @VendorRanking = VendorRanking,
                @IsPMA = IsPMA,
                @IsDER = IsDER,
                @Cost = Cost,
                @TAT = TAT,
                @Memo = Memo,
                @IsActive = IsActive,
                @IsDeleted = IsDeleted,
                @CapabilityTypeDescription = CapabilityTypeDescription,
                @PartNum = PartNumber,
                @PartDescription = PartDescription,
                @ManufacturerId = ManufacturerId,
                @ManufacturerName = ManufacturerName,
                @CostDate = CostDate,
                @CurrencyId = CurrencyId,
                @Currency = Currency,
                @EmployeeId = EmployeeId
            FROM #TempVendorCapabilities
            WHERE RowNum = @Row;

            IF EXISTS (SELECT 1 FROM dbo.VendorCapability WITH(NOLOCK) WHERE VendorCapabilityId = @VendorCapabilityId)
            BEGIN
                -- Update existing
                UPDATE dbo.VendorCapability
                SET CapabilityTypeId = @CapabilityTypeId,
                    CapabilityTypeDescription = @CapabilityTypeDescription,
                    ItemMasterId = @ItemMasterId,
                    VendorRanking = @VendorRanking,
                    IsPMA = @IsPMA,
                    IsDER = @IsDER,
                    Cost = @Cost,
                    TAT = @TAT,
                    Memo = @Memo,
                    IsActive = @IsActive,
                    IsDeleted = @IsDeleted,
                    PartNumber = @PartNum,
                    PartDescription = @PartDescription,
                    ManufacturerId = @ManufacturerId,
                    ManufacturerName = @ManufacturerName,
                    CostDate = @CostDate,
                    CurrencyId = @CurrencyId,
                    Currency = @Currency,
                    EmployeeId = @EmployeeId,
                    UpdatedBy = @UpdatedBy,
                    UpdatedDate = GETUTCDATE()
                WHERE VendorCapabilityId = @VendorCapabilityId;
            END
            ELSE
            BEGIN
                -- Check for duplicates
                IF EXISTS (
                    SELECT 1 FROM dbo.VendorCapability WITH(NOLOCK)
                    WHERE VendorId = @VendorId
                      AND ItemMasterId = @ItemMasterId
                      AND CapabilityTypeId = @CapabilityTypeId
                      AND MasterCompanyId = @MasterCompanyId
                )
                BEGIN
                    SET @Msg += 'Record Already Exists - PartNumber: ' + ISNULL(@PartNum, '') + 
                                ', CapabilityType: ' + ISNULL(@CapabilityTypeDescription, '') + 
                                ', Company: ' + ISNULL(@CompanyName, '') + CHAR(13);
                    SET @IsDuplicate = 1;
                END
                ELSE
                BEGIN
                    -- Insert new
                    INSERT INTO dbo.VendorCapability
                    (
                        VendorId, CapabilityTypeId, CapabilityTypeDescription, ItemMasterId, VendorRanking,
                        IsPMA, IsDER, Cost, TAT, Memo, IsActive, IsDeleted,
                        PartNumber, PartDescription, ManufacturerId, ManufacturerName,
                        CostDate, CurrencyId, Currency, EmployeeId,
                        CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, MasterCompanyId
                    )
                    VALUES
                    (
                        @VendorId, @CapabilityTypeId, @CapabilityTypeDescription, @ItemMasterId, @VendorRanking,
                        @IsPMA, @IsDER, @Cost, @TAT, @Memo, @IsActive, @IsDeleted,
                        @PartNum, @PartDescription, @ManufacturerId, @ManufacturerName,
                        @CostDate, @CurrencyId, @Currency, @EmployeeId,
                        @UpdatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), @MasterCompanyId
                    );
                END
            END

            SET @Row = @Row + 1;
        END

        SET @OutputMessage = @Msg;

        IF @IsDuplicate = 1
        BEGIN
            ROLLBACK TRANSACTION;
        END
        ELSE
        BEGIN
            COMMIT TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME();
        EXEC spLogException 
            @DatabaseName = @DatabaseName, 
            @AdhocComments = 'USP_AddUpdateVendorCapabilities (no cursor)', 
            @ProcedureParameters = '', 
            @ApplicationName = 'PAS',
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected error occurred. Contact support with Error ID: %d', 16, 1, @ErrorLogID);
        RETURN 1;
    END CATCH
END