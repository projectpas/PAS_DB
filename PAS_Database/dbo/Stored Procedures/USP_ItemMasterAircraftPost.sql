/*************************************************************           
 ** File:        [usp_ItemMasterAircraftPost]           
 ** Author:      Nakul Chandigra
 ** Description: This stored procedure is used to Add ItemMasterAircraftPost
 ** Purpose:     Insert ItemMaster–Aircraft mappings and prevent duplicates      
 ** Date:        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author             Change Description            
 ** --   ----------  -----------------  -----------------------------         
 **  1   01-09-2025   Nakul Chandigra    Created
 ************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ItemMasterAircraftPost] 
    @Tbl_ItemMasterAircraftMappingType ItemMasterAircraftMappingType READONLY,
    @IsSuccess BIT OUTPUT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TotalRecord     INT      = 0;
        DECLARE @MinId           BIGINT   = 1;
        DECLARE @AircraftModelId BIGINT;      
        DECLARE @AircraftTypeId  INT;
        DECLARE @DashNumberId    BIGINT;
        DECLARE @ItemMasterId    BIGINT;
        DECLARE @MasterCompanyId INT;

        -- Drop temp table if exists
        IF OBJECT_ID(N'tempdb..#tmpItemMasterAircraftPost') IS NOT NULL
            DROP TABLE #tmpItemMasterAircraftPost;

        -- Create temp table
        CREATE TABLE #tmpItemMasterAircraftPost
        (
            ID              INT NOT NULL IDENTITY,
            ItemMasterId    BIGINT NULL,
            AircraftTypeId  INT NULL,
            AircraftModelId BIGINT NULL,
            DashNumberId    BIGINT NULL,
            PartNumber      VARCHAR(50) NULL,
            DashNumber      VARCHAR(250) NULL,
            AircraftType    VARCHAR(250) NULL,
            AircraftModel   VARCHAR(250) NULL,
            Memo            NVARCHAR(MAX) NULL,
            MasterCompanyId INT NULL,
            CreatedBy       VARCHAR(256) NULL,
            UpdatedBy       VARCHAR(256) NULL,
            CreatedDate     DATETIME2(7) NULL,
            UpdatedDate     DATETIME2(7) NULL,
            IsActive        BIT NULL,
            IsDeleted       BIT NULL,
            ATAReferenceId  BIGINT NULL,
            ATAReference    VARCHAR(250) NULL,
            Level1          VARCHAR(50) NULL,
            Level2          VARCHAR(50) NULL,
            Level3          VARCHAR(50) NULL,
            ATAChapterId    BIGINT NULL
        );

        -- Insert into temp table
        INSERT INTO #tmpItemMasterAircraftPost
        (
            ItemMasterId, AircraftTypeId, AircraftModelId, DashNumberId,
            PartNumber, DashNumber, AircraftType, AircraftModel, Memo,
            MasterCompanyId, CreatedBy, CreatedDate,
            UpdatedBy, UpdatedDate, IsActive, IsDeleted,
            ATAReferenceId, ATAReference, Level1, Level2, Level3, ATAChapterId
        )
        SELECT 
            ItemMasterId, AircraftTypeId, AircraftModelId, DashNumberId,
            PartNumber, DashNumber, AircraftType, AircraftModel, Memo,
            MasterCompanyId, CreatedBy, GETUTCDATE(),
            UpdatedBy, GETUTCDATE(), 1, 0,
            ATAReferenceId, ATAReference, Level1, Level2, Level3, ATAChapterId
        FROM @Tbl_ItemMasterAircraftMappingType;	

        SET @IsSuccess = 1;

        -- Get total record count and min id
        SELECT 
            @TotalRecord = COUNT(*),
            @MinId       = MIN(ID)
        FROM #tmpItemMasterAircraftPost;

        -- Loop through records
        WHILE (@MinId <= @TotalRecord) 
        BEGIN
            SELECT 
                @AircraftModelId = AircraftModelId,
                @DashNumberId    = DashNumberId,
                @ItemMasterId    = ItemMasterId,
                @MasterCompanyId = MasterCompanyId,
                @AircraftTypeId  = AircraftTypeId
            FROM #tmpItemMasterAircraftPost
            WHERE ID = @MinId;

            -- Check if record already exists
            IF NOT EXISTS 
            (
                SELECT 1
                FROM dbo.ItemMasterAircraftMapping M WITH (NOLOCK)
                WHERE ISNULL(M.AircraftModelId, 0) = ISNULL(@AircraftModelId, 0)
                  AND ISNULL(M.DashNumberId, 0)    = ISNULL(@DashNumberId, 0)
                  AND ISNULL(M.ItemMasterId, 0)    = ISNULL(@ItemMasterId, 0)
                  AND ISNULL(M.MasterCompanyId, 0) = ISNULL(@MasterCompanyId, 0)
                  AND ISNULL(M.AircraftTypeId, 0)  = ISNULL(@AircraftTypeId, 0)
            )
            BEGIN
                -- Insert new ItemMasterAircraftMapping
                INSERT INTO dbo.ItemMasterAircraftMapping
                (
                    ItemMasterId, AircraftTypeId, AircraftModelId, DashNumberId,
                    PartNumber, DashNumber, AircraftType, AircraftModel, Memo,
                    MasterCompanyId, CreatedBy, UpdatedBy,
                    CreatedDate, UpdatedDate, IsActive, IsDeleted,
                    ATAReferenceId, ATAReference, Level1, Level2, Level3, ATAChapterId
                )
                SELECT 
                    ItemMasterId, AircraftTypeId, AircraftModelId, DashNumberId,
                    PartNumber, DashNumber, AircraftType, AircraftModel, Memo,
                    MasterCompanyId, CreatedBy, UpdatedBy,
                    GETUTCDATE(), GETUTCDATE(), 1, 0,
                    ATAReferenceId, ATAReference, Level1, Level2, Level3, ATAChapterId
                FROM #tmpItemMasterAircraftPost
                WHERE ID = @MinId;
            END
            ELSE
            BEGIN
                SET @IsSuccess = 0;
            END
                SET @MinId = @MinId + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_ItemMasterAircraftPost' 
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
END