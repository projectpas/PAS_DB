/*********************           
 ** File:   [USP_AddOrUpdateMROPriceMaster]           
 ** Author: Priyansh Patel
 ** Description: This stored procedure inserts or updates MROPriceMaster records.
 ** Date:   26/09/2025

 **********************           
  ** Change History           
 **********************           
 ** PR   Date          Author  			Change Description            
 ** --   --------      -------			---------------------------     
    1    26/09/2025    Priyansh Patel   Created
    2    15/10/2025    Priyansh Patel   Updated the Parameter to user defiend table type

**********************/

CREATE PROCEDURE [dbo].[USP_AddOrUpdateMROPriceMaster]
    @MROPriceMasterList MROPriceMasterListType READONLY  --  the list of objects
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRAN;

	-- Temp table to stage the rows with a sequential ID
    IF OBJECT_ID('tempdb..#MROPriceMasterTemp') IS NOT NULL
        DROP TABLE #MROPriceMasterTemp;

    CREATE TABLE #MROPriceMasterTemp
    (
        SeqID INT IDENTITY(1,1) PRIMARY KEY,
        MROPriceMasterId BIGINT NULL,
        ItemMasterId BIGINT NULL,
        MasterCompanyId INT NULL,
        CustomerId BIGINT NULL,
        WorkscopeId BIGINT NULL,
        CurrencyId INT NULL,
        UnitPrice DECIMAL(18,2) NULL,
        StartDate DATETIME2(7) NULL,
        EndDate DATETIME2(7) NULL,
        CreatedBy VARCHAR(50) NULL,
        UpdatedBy VARCHAR(50) NULL
    );

    INSERT INTO #MROPriceMasterTemp
    (
        MROPriceMasterId,
        ItemMasterId,
        MasterCompanyId,
        CustomerId,
        WorkscopeId,
        CurrencyId,
        UnitPrice,
        StartDate,
		EndDate,
        CreatedBy,
        UpdatedBy
    )
    SELECT 
        MROPriceMasterId,
        ItemMasterId,
        MasterCompanyId,
        CustomerId,
        WorkscopeId,
        CurrencyId,
        UnitPrice,
        StartDate,
		EndDate,
        CreatedBy,
        UpdatedBy
    FROM @MROPriceMasterList;

    DECLARE @MaxSeq INT;
    DECLARE @CurrSeq INT = 1;

    SELECT @MaxSeq = MAX(SeqID) FROM #MROPriceMasterTemp;

            PRINT @MaxSeq;
   
        WHILE @CurrSeq <= @MaxSeq
        BEGIN
            PRINT @CurrSeq;

            DECLARE 
                @MROPriceMasterId BIGINT,
                @ItemMasterId BIGINT,
                @MasterCompanyId INT,
                @CustomerId BIGINT,
                @WorkscopeId BIGINT,
                @CurrencyId INT,
                @UnitPrice DECIMAL(18,2),
                @StartDate DATETIME2(7),
                @EndDate DATETIME2(7),
                @CreatedBy VARCHAR(50),
                @UpdatedBy VARCHAR(50);

            -- Load the row’s values into the variables
            SELECT
                @MROPriceMasterId = MROPriceMasterId,
                @ItemMasterId = ItemMasterId,
                @MasterCompanyId = MasterCompanyId,
                @CustomerId = CustomerId,
                @WorkscopeId = WorkscopeId,
                @CurrencyId = CurrencyId,
                @UnitPrice = UnitPrice,
                @StartDate = StartDate,
                @EndDate = EndDate,
                @CreatedBy = CreatedBy,
                @UpdatedBy = UpdatedBy
            FROM #MROPriceMasterTemp
            WHERE SeqID = @CurrSeq;

                -- If new record
                IF @MROPriceMasterId IS NULL OR @MROPriceMasterId = 0
                BEGIN
                    INSERT INTO dbo.MROPriceMaster
                    (
                        ItemMasterId, MasterCompanyId, CustomerId, WorkscopeId,
                        UnitPrice, CurrencyId, StartDate,EndDate,
                        CreatedBy, CreatedDate,
                        UpdatedBy, UpdatedDate, IsActive, IsDeleted
                    )
                    VALUES
                    (
                        @ItemMasterId, @MasterCompanyId, @CustomerId, @WorkscopeId,
                        @UnitPrice, @CurrencyId, @StartDate,@EndDate,
                        @CreatedBy, GETUTCDATE(),
                        @UpdatedBy, GETUTCDATE(),
                        1, 0
                    );
                END
                ELSE
                BEGIN
                    -- Existing record, update
                    UPDATE mp
                    SET
                        mp.CustomerId = @CustomerId,
                        mp.WorkscopeId = @WorkscopeId,
                        mp.StartDate = @StartDate,
                        mp.EndDate = @EndDate,
                        mp.CurrencyId = @CurrencyId,
                        mp.UnitPrice = @UnitPrice,
                        mp.UpdatedBy = @UpdatedBy,
                        mp.UpdatedDate = GETUTCDATE()
                    FROM dbo.MROPriceMaster mp
                    WHERE mp.MROPriceMasterId = @MROPriceMasterId;
                END
				 SET @CurrSeq = @CurrSeq + 1;
                END
            PRINT @ItemMasterId;

        COMMIT TRAN;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            PRINT 'ROLLBACK';
            ROLLBACK TRAN;
        END

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
 -------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = '[USP_AddOrUpdateMROPriceMaster]',
                @ProcedureParameters VARCHAR(3000) = 
                    '@MROPriceMasterId=''' + CAST(ISNULL(@MROPriceMasterId, 0) AS VARCHAR(100)) + ''',
                     @ItemMasterId=''' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR(100)) + ''',
                     @MasterCompanyId=''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)) + ''',
                     @CustomerId=''' + CAST(ISNULL(@CustomerId, 0) AS VARCHAR(100)) + ''',
                     @WorkscopeId=''' + CAST(ISNULL(@WorkscopeId, 0) AS VARCHAR(100)) + ''',
                     @UnitPrice=''' + CAST(ISNULL(@UnitPrice, 0) AS VARCHAR(100)) + '''',
                  
                @ApplicationName VARCHAR(100) = 'PAS';
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END