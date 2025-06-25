/*************************************************************
 ** File:     [USP_SavePublicationSettingData]
 ** Author:   Ayushi Patel
 ** Description: 
 ** Purpose:
 ** Date:   06/25/2025
 ** PARAMETERS:  @Id BIGINT OUTPUT,
    @RedIndicator INT,
    @YellowIndicator INT,
    @GreenIndicator INT,
    @UpdatedBy VARCHAR(100),
    @CreatedBy VARCHAR(100),
    @MasterCompanyId INT

 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/25/2025   Ayushi Patel		Created
**************************************************************/ 
CREATE   PROCEDURE dbo.USP_SavePublicationSettingData
    @Id BIGINT OUTPUT,
    @RedIndicator INT,
    @YellowIndicator INT,
    @GreenIndicator INT,
    @UpdatedBy VARCHAR(100),
    @CreatedBy VARCHAR(100),
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRANSACTION;
    BEGIN TRY
        IF (@Id > 0)
        BEGIN
            UPDATE dbo.PublicationSettings
            SET 
                RedIndicator = @RedIndicator,
                YellowIndicator = @YellowIndicator,
                GreenIndicator = @GreenIndicator,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE Id = @Id;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.PublicationSettings (
                RedIndicator,
                YellowIndicator,
                GreenIndicator,
                UpdatedBy,
                UpdatedDate,
                CreatedBy,
                CreatedDate,
                IsActive,
                IsDeleted,
                MasterCompanyId
            )
            VALUES (
                @RedIndicator,
                @YellowIndicator,
                @GreenIndicator,
                @UpdatedBy,
                GETUTCDATE(),
                @CreatedBy,
                GETUTCDATE(),
                1, 
                0,  
                @MasterCompanyId
            );

            SET @Id = SCOPE_IDENTITY();
        END

        COMMIT TRANSACTION;

        SELECT @Id AS Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_SavePublicationSettingData',
                @ProcedureParameters VARCHAR(MAX) = 'Id=' + CAST(@Id AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Database error occurred. ErrorLogID = %d', 16, 1, @ErrorLogID);
    END CATCH
END;