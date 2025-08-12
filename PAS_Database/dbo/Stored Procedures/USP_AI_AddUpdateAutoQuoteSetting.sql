/*************************************************************           
 ** File:   [USP_AI_AddUpdateAutoQuoteSetting]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to create or update Auto Quote Setting.
 ** Date:   12/08/2025
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		    Change Description            
 ** --   --------     -------		    ---------------------------     
    1    12/08/2025   Rajesh Gami      Created
**************************************************************           
 EXEC USP_AI_AddUpdateAutoQuoteSetting 0,1,'Price List','PRL',1,2,'Auto Send',1,'Admin'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AI_AddUpdateAutoQuoteSetting] 
    @AIAutoQouteSettingId BIGINT OUTPUT,
    @QuoteSettingNameId INT = NULL,
    @QuoteSettingName VARCHAR(100) = NULL,
    @Code VARCHAR(50) = NULL,
    @Sequence INT = NULL,
    @QuoteSendReviewId INT = NULL,
    @QuoteSendReview VARCHAR(100) = NULL,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION
            IF (@AIAutoQouteSettingId = 0)
            BEGIN
                INSERT INTO [dbo].[AIAutoQouteSetting]
                    ([QuoteSettingNameId], [QuoteSettingName], [Code], [Sequence], 
                     [QuoteSendReviewId], [QuoteSendReview], [MasterCompanyId], 
                     [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], 
                     [IsDeleted], [IsActive])
                VALUES
                    (@QuoteSettingNameId, (SELECT TOP 1 QuoteSettingName FROM dbo.QuoteSettingName WITH(NOLOCK) WHERE QuoteSettingNameId =@QuoteSettingNameId), @Code, @Sequence, 
                     @QuoteSendReviewId, (SELECT TOP 1 [QuoteName] FROM dbo.QuoteSendReview WITH(NOLOCK) WHERE QuoteSendReviewId =@QuoteSendReviewId), @MasterCompanyId, 
                     @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 
                     0, 1);

                SET @AIAutoQouteSettingId = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                UPDATE [dbo].[AIAutoQouteSetting]
                   SET [QuoteSettingNameId] = @QuoteSettingNameId,
                       [QuoteSettingName] = (SELECT TOP 1 QuoteSettingName FROM dbo.QuoteSettingName WITH(NOLOCK) WHERE QuoteSettingNameId =@QuoteSettingNameId),
                       [Sequence] = @Sequence,
                       [QuoteSendReviewId] = @QuoteSendReviewId,
                       [QuoteSendReview] = (SELECT TOP 1 [QuoteName] FROM dbo.QuoteSendReview WITH(NOLOCK) WHERE QuoteSendReviewId =@QuoteSendReviewId),
                       [MasterCompanyId] = @MasterCompanyId,
                       [UpdatedBy] = @CreatedBy,
                       [UpdatedDate] = GETUTCDATE()
                 WHERE AIAutoQouteSettingId = @AIAutoQouteSettingId;
            END

            SELECT @AIAutoQouteSettingId AS AIAutoQouteSettingId;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_AI_AddUpdateAutoQuoteSetting]',
                @ProcedureParameters VARCHAR(3000) = 
                    '@AIAutoQouteSettingId = ''' + CAST(ISNULL(@AIAutoQouteSettingId, '') AS VARCHAR(100)) + ''',
                     @QuoteSettingNameId = ''' + CAST(ISNULL(@QuoteSettingNameId, '') AS VARCHAR(100)) + ''',
                     @QuoteSettingName = ''' + ISNULL(@QuoteSettingName, '') + ''',
                     @Code = ''' + ISNULL(@Code, '') + ''',
                     @Sequence = ''' + CAST(ISNULL(@Sequence, '') AS VARCHAR(100)) + ''',
                     @QuoteSendReviewId = ''' + CAST(ISNULL(@QuoteSendReviewId, '') AS VARCHAR(100)) + ''',
                     @QuoteSendReview = ''' + ISNULL(@QuoteSendReview, '') + ''',
                     @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + ''',
                     @CreatedBy = ''' + ISNULL(@CreatedBy, '') + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 
                   16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END