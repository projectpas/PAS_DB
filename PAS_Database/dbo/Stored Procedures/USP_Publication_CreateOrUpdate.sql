/************************************************************* 
 ** File:     [USP_Publication_CreateOrUpdate]
 ** Author:   Ayushi Patel
 ** Description: Creates or updates publication record and related management structure mapping
 ** Purpose:   Replaces EF logic with SQL logic using WHILE loop instead of cursor
 ** Date:      06/25/2025
 ** PARAMETERS:
    @PublicationRecordId BIGINT OUTPUT,
    @PublicationId VARCHAR(50),
    @Description VARCHAR(MAX),
    @MasterCompanyId INT,
    @EntryDate DATETIME,
    @RevisionDate DATETIME = NULL,
    @NextReviewDate DATETIME = NULL,
    @ASD VARCHAR(100),
    @VerifiedBy BIGINT = 0,
    @VerifiedDate DATETIME = NULL,
    @EmployeeId BIGINT = NULL,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100),
    @PublicationTypeId INT = 0,
    @Sequence INT = 0,
    @RevisionNum VARCHAR(50),
    @ExpirationDate DATETIME = NULL,
    @VerifiedStatus BIT,
    @LocationId BIGINT,
    @PublishedById INT = 0,
    @PublishedByRefId INT = 0,
    @PublishedByOthers VARCHAR(100),
    @ManagementStructureIds VARCHAR(MAX),
    @URL VARCHAR(500),
    @Fleet VARCHAR(100)

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author          Change Description            
 ** --   --------     -------         --------------------------------          
    1    06/25/2025   Ayushi Patel    Created - replaced cursor with WHILE loop

-- exec [USP_Publication_CreateOrUpdate] 716,'qwe','',1,'25-06-2025 18:52:32',null,null,'',53,'25-06-2025 00:00:00',229,'AYUSHI P','AYUSHI P',70,1,'',null,true,886,2,4762,'',1,'',''

**************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_Publication_CreateOrUpdate]
    @PublicationRecordId BIGINT OUTPUT,
    @PublicationId VARCHAR(50),
    @Description VARCHAR(MAX),
    @MasterCompanyId INT,
    @EntryDate DATETIME,
    @RevisionDate DATETIME = NULL,
    @NextReviewDate DATETIME = NULL,
    @ASD VARCHAR(100),
    @VerifiedBy BIGINT = 0,
    @VerifiedDate DATETIME = NULL,
    @EmployeeId BIGINT = NULL,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100),
    @PublicationTypeId INT = 0,
    @Sequence INT = 0,
    @RevisionNum VARCHAR(50),
    @ExpirationDate DATETIME = NULL,
    @VerifiedStatus BIT,
    @LocationId BIGINT,
    @PublishedById INT = 0,
    @PublishedByRefId INT = 0,
    @PublishedByOthers VARCHAR(100),
    @ManagementStructureIds VARCHAR(MAX),
    @URL VARCHAR(500),
    @Fleet VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        DECLARE @PublicationMSMappingId BIGINT;
        DECLARE @MSDetailsId BIGINT = NULL;
        DECLARE @PublicationHeaderId INT = (SELECT ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'PublicationHeader');

        IF (ISNULL(@PublicationRecordId,0) = 0)
        BEGIN
            INSERT INTO dbo.Publication (
                PublicationId, Description, MasterCompanyId, EntryDate, RevisionDate,
                NextReviewDate, ASD, VerifiedBy, VerifiedDate, EmployeeId,
                CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
                PublicationTypeId, Sequence, RevisionNum, ExpirationDate,
                VerifiedStatus, LocationId, PublishedById, PublishedByRefId,
                PublishedByOthers, URL, Fleet, ManagementStructureIds, IsActive, IsDeleted
            )
            VALUES (
                @PublicationId, @Description, @MasterCompanyId, @EntryDate, @RevisionDate,
                @NextReviewDate, @ASD, @VerifiedBy, @VerifiedDate, @EmployeeId,
                @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
                @PublicationTypeId, @Sequence, @RevisionNum, @ExpirationDate,
                @VerifiedStatus, @LocationId, @PublishedById, @PublishedByRefId,
                @PublishedByOthers, @URL, @Fleet, @ManagementStructureIds, 1, 0
            );
            SET @PublicationRecordId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.Publication
            SET
                Description = @Description,
                EntryDate = @EntryDate,
                RevisionDate = @RevisionDate,
                NextReviewDate = @NextReviewDate,
                ASD = @ASD,
                VerifiedBy = @VerifiedBy,
                VerifiedDate = @VerifiedDate,
                EmployeeId = @EmployeeId,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE(),
                PublicationTypeId = @PublicationTypeId,
                Sequence = @Sequence,
                RevisionNum = @RevisionNum,
                ExpirationDate = @ExpirationDate,
                VerifiedStatus = @VerifiedStatus,
                LocationId = @LocationId,
                PublishedById = @PublishedById,
                PublishedByRefId = @PublishedByRefId,
                PublishedByOthers = @PublishedByOthers,
                URL = @URL,
                Fleet = @Fleet,
                ManagementStructureIds = @ManagementStructureIds
            WHERE PublicationRecordId = @PublicationRecordId;
        END

        DELETE FROM dbo.PublicationManagementStructureMapping
        WHERE PublicationRecordId = @PublicationRecordId;

        IF (LEN(@ManagementStructureIds) > 0)
        BEGIN
            IF OBJECT_ID('tempdb..#TempMSIds') IS NOT NULL DROP TABLE #TempMSIds;

            CREATE TABLE #TempMSIds (
                ID INT IDENTITY(1,1),
                ManagementStructureId BIGINT,
                IsProcessed BIT DEFAULT 0
            );

            INSERT INTO #TempMSIds (ManagementStructureId)
            SELECT TRY_CAST(value AS BIGINT)
            FROM STRING_SPLIT(@ManagementStructureIds, ',')
            WHERE TRY_CAST(value AS BIGINT) IS NOT NULL;

            DECLARE @MSID BIGINT;

            WHILE EXISTS (SELECT 1 FROM #TempMSIds WHERE IsProcessed = 0)
            BEGIN
                SELECT TOP 1 @MSID = ManagementStructureId
                FROM #TempMSIds
                WHERE IsProcessed = 0
                ORDER BY ID;

                INSERT INTO dbo.PublicationManagementStructureMapping (
                    PublicationRecordId, MasterCompanyId,
                    CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
                    IsDeleted, IsActive, ManagementStructureId
                )
                VALUES (
                    @PublicationRecordId, @MasterCompanyId,
                    @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
                    0, 1, @MSID
                );

                SET @PublicationMSMappingId = SCOPE_IDENTITY();

                EXEC dbo.PROCAddUpdatePublicationMSData
                    @PublicationMSMappingId,
                    @MSID,
                    @MasterCompanyId,
                    @CreatedBy,
                    @UpdatedBy,
                    @PublicationHeaderId,
                    1,
                    @PublicationRecordId,
                    @MSDetailsId = @MSDetailsId OUTPUT;

                UPDATE #TempMSIds SET IsProcessed = 1 WHERE ManagementStructureId = @MSID;
            END
        END

        SELECT @PublicationRecordId AS PublicationRecordId, @MSDetailsId AS MSDetailsId;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_Publication_CreateOrUpdate',
                @ProcedureParameters VARCHAR(MAX) = 'Publication creation input parameters',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC dbo.spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Database error: %d', 16, 1, @ErrorLogID);
    END CATCH
END;