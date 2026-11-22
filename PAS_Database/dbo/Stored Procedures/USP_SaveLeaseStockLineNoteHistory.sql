/*************************************************************
 ** File:   [USP_SaveLeaseStockLineNoteHistory]
 ** Desc:   Add (@LeaseStockLineNoteHistoryId = 0 -> new record with Entered By / Created Date) or
 **         Edit (existing record -> Description, Edited By, Updated Date) a lease stockline note.
 ** EXEC USP_SaveLeaseStockLineNoteHistory @LeaseStockLineNoteHistoryId = 0, @LeaseStocklineId = 1, @Description = 'Test note', @MasterCompanyId = 1, @UserName = 'ADMIN User'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveLeaseStockLineNoteHistory]
    @LeaseStockLineNoteHistoryId BIGINT = 0,
    @LeaseStocklineId            BIGINT,
    @Description                 NVARCHAR(MAX),
    @MasterCompanyId             INT,
    @UserName                    VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF (ISNULL(LTRIM(RTRIM(@Description)), '') = '')
        BEGIN
            THROW 50001, 'Note description is required.', 1;
        END

        IF (ISNULL(@LeaseStockLineNoteHistoryId, 0) = 0)
        BEGIN
            INSERT INTO [dbo].[LeaseStockLineNoteHistory] ([LeaseStocklineId], [Description], [EnteredBy], [CreatedDate], [MasterCompanyId], [IsActive], [IsDeleted])
            VALUES (@LeaseStocklineId, @Description, @UserName, GETUTCDATE(), @MasterCompanyId, 1, 0);

            SET @LeaseStockLineNoteHistoryId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE [dbo].[LeaseStockLineNoteHistory]
            SET [Description] = @Description,
                [EditedBy]    = @UserName,
                [UpdatedDate] = GETUTCDATE()
            WHERE [LeaseStockLineNoteHistoryId] = @LeaseStockLineNoteHistoryId
              AND [LeaseStocklineId] = @LeaseStocklineId;
        END

        SELECT N.[LeaseStockLineNoteHistoryId], N.[LeaseStocklineId], N.[Description], N.[EnteredBy], N.[CreatedDate], N.[EditedBy], N.[UpdatedDate]
        FROM [dbo].[LeaseStockLineNoteHistory] N
        WHERE N.[LeaseStockLineNoteHistoryId] = @LeaseStockLineNoteHistoryId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END