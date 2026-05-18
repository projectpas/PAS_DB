/*************************************************************           
 ** File:		   [USP_AddupdateAircraftSetup]       
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Add,update AircraftSetup 
 ** Purpose:         
 ** Date:   
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 15/05/2026          Nakul Chandigra     Created 

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddupdateAircraftSetup]
(
    @tblType_AircraftSetupType [AircraftSetupType] READONLY,
    @AircraftSetupId BIGINT,
    @IsError BIT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @IsError = 0;

        IF EXISTS(SELECT 1 FROM dbo.AircraftSetup WITH (NOLOCK) WHERE AircraftSetupId = @AircraftSetupId )
        BEGIN
            UPDATE T
            SET
                T.MaintenanceStatusId = S.MaintenanceStatusId,
                T.AircraftStatusId = S.AircraftStatusId,
                T.CurrencyId = S.CurrencyId,
                T.UpdatedBy = S.UpdatedBy,
                T.UpdatedDate = GETUTCDATE()
            FROM dbo.AircraftSetup T
            CROSS APPLY
            (
                SELECT TOP 1
                    MaintenanceStatusId,
                    AircraftStatusId,
                    CurrencyId,
                    UpdatedBy
                FROM @tblType_AircraftSetupType
            ) S
            WHERE T.AircraftSetupId = @AircraftSetupId;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.AircraftSetup
            (
                MaintenanceStatusId,
                AircraftStatusId,
                CurrencyId,
                CreatedBy,
                CreatedDate,
                UpdatedBy,
                UpdatedDate,
                IsActive,
                IsDeleted,
                MasterCompanyId
            )
            SELECT TOP 1
                MaintenanceStatusId,
                AircraftStatusId,
                CurrencyId,
                CreatedBy,
                GETUTCDATE(),
                UpdatedBy,
                GETUTCDATE(),
                IsActive,
                IsDeleted,
                MasterCompanyId
            FROM @tblType_AircraftSetupType;
        END
    END TRY
BEGIN CATCH
IF @@trancount > 0		  
	ROLLBACK TRAN;  
	DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_AddupdateAircraftSetup]'
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName
		,@AdhocComments = @AdhocComments
		,@ProcedureParameters = @ProcedureParameters
		,@ApplicationName = @ApplicationName
		,@ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1); 
END CATCH
END