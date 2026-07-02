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
	1	 15/05/2026          Nakul Chandigra    Created 
    2    20/05/2026          Nakul Chandigra    Added fields 
    3    22/05/2026          Bhargav Saliya     Added field [SiteId] 
    4    29/05/2026          Bhargav Saliya     Added field [MaintenanceTypeId]
    5    29/06/2026          Divyesh Kathiriya  Added field ConditionId and WorkScopeId. [PN-17041]
    
**************************************************************/
Create   PROCEDURE [dbo].[USP_AddupdateAircraftSetup]
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
                T.UOMId = S.UOMId,
	            T.ItemClassificationId = S.ItemClassificationId,
	            T.InventoryGLSettingId = S.InventoryGLSettingId,
                T.RedIndicator = S.RedIndicator,
                T.YellowIndicator = S.YellowIndicator,
                T.GreenIndicator = S.GreenIndicator,
                T.ItemgroupId = S.ItemgroupId,
                T.CurrencyId = S.CurrencyId,
                T.UpdatedBy = S.UpdatedBy,
                T.UpdatedDate = GETUTCDATE(),
                T.SiteId = S.SiteId,
                T.[WorkScopeId] = S.[WorkScopeId],
                T.[ConditionId] = S.[ConditionId]
            FROM dbo.AircraftSetup T
            CROSS APPLY
            (
                SELECT TOP 1
                    MaintenanceStatusId,
                    AircraftStatusId,
                    CurrencyId,
                    UOMId,
	                ItemClassificationId,
	                InventoryGLSettingId,
                    RedIndicator,
                    YellowIndicator,
                    GreenIndicator,
                    ItemgroupId,
                    UpdatedBy,
                    SiteId,
                    [WorkScopeId],
                    [ConditionId]
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
                UOMId,
	            ItemClassificationId,
	            InventoryGLSettingId,
                RedIndicator,
                YellowIndicator,
                GreenIndicator,
                ItemgroupId,
                CreatedBy,
                CreatedDate,
                UpdatedBy,
                UpdatedDate,
                IsActive,
                IsDeleted,
                MasterCompanyId,
                SiteId,
                [WorkScopeId],
                [ConditionId]
            )
            SELECT TOP 1
                MaintenanceStatusId,
                AircraftStatusId,
                CurrencyId,
                UOMId,
	            ItemClassificationId,
	            InventoryGLSettingId,
                RedIndicator,
                YellowIndicator,
                GreenIndicator,
                ItemgroupId,
                CreatedBy,
                GETUTCDATE(),
                UpdatedBy,
                GETUTCDATE(),
                IsActive,
                IsDeleted,
                MasterCompanyId,
                SiteId,
                [WorkScopeId],
                [ConditionId]
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