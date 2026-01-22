/*************************************************************
 ** File:     [USP_GetPublicationSettingData]
 ** Author:   Ayushi Patel
 ** Description: 
 ** Purpose:
 ** Date:   06/25/2025
 ** PARAMETERS: @MasterCompanyId

 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/25/2025   Ayushi Patel		Created

	EXEC USP_GetPublicationSettingData 1
**************************************************************/ 
CREATE   PROCEDURE dbo.USP_GetPublicationSettingData
    @MasterCompanyId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        SELECT TOP 1
            Id,
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
        FROM dbo.PublicationSettings WITH (NOLOCK)
        WHERE MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_GetPublicationSettingData',
                @ProcedureParameters VARCHAR(MAX) = 'MasterCompanyId=' + CAST(@MasterCompanyId AS VARCHAR),
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