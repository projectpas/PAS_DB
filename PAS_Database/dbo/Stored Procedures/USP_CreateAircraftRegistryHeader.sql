/*************************************************************             
 ** File:   [USP_CreateAircraftRegistryHeader]          
 ** Author:   Bhargav Saliya 
 ** Description: This stored procedure is used to add a record in [AircraftRegistryHeader].
 ** Jira Id: PN-15843
 ** Purpose:           
 ** Date:  [26-Mar-2026] 
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------     
    1    26/02/2026   Bhargav Saliya       PN-15456: Created
**************************************************************/
CREATE   PROCEDURE dbo.[USP_CreateAircraftRegistryHeader]
    @tbl_AircraftRegistryHeaderType dbo.AircraftRegistryTableType READONLY
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  

	DECLARE @AircraftRegistryId BIGINT = (SELECT AircraftRegistryId FROM @tbl_AircraftRegistryHeaderType);

	IF(@AircraftRegistryId > 0)
	BEGIN
		UPDATE AR
        SET
            AR.MakeTypeId = T.MakeTypeId,
            AR.MakeType = T.MakeType,
            AR.AircraftModelId = T.AircraftModelId,
            AR.AircraftModel = T.AircraftModel,
            AR.AircraftSubModel = T.AircraftSubModel,
            AR.NumOfEngines = T.NumOfEngines,
            AR.TailNum = T.TailNum,
            AR.SerialNum = T.SerialNum,
            AR.ManufacturedDate = T.ManufacturedDate,
            AR.PlaceInServiceDate = T.PlaceInServiceDate,
            AR.TotalTSN = T.TotalTSN,
            AR.TotalCSN = T.TotalCSN,
            AR.Hobbs = T.Hobbs,
            AR.AircraftLocation = T.AircraftLocation,
            AR.NextScheduled = T.NextScheduled,
            AR.MEL = T.MEL,
            AR.AircraftStatusId = T.AircraftStatusId,
            AR.AircraftStatus = T.AircraftStatus,
            AR.MaintenanceStatusId = T.MaintenanceStatusId,
            AR.MaintenanceStatus = T.MaintenanceStatus,
            AR.Memo = T.Memo,
            AR.IsActive = ISNULL(T.IsActive, AR.IsActive),
            AR.IsDeleted = ISNULL(T.IsDeleted, AR.IsDeleted),
            AR.MasterCompanyId = T.MasterCompanyId,
            AR.UpdatedBy = T.UpdatedBy,
            AR.UpdatedDate = GETUTCDATE()
        FROM AircraftRegistryHeader AR
        INNER JOIN @tbl_AircraftRegistryHeaderType T ON AR.AircraftRegistryId = T.AircraftRegistryId
        WHERE T.AircraftRegistryId IS NOT NULL;
	END
	ELSE
	BEGIN
        INSERT INTO [AircraftRegistryHeader]
        (
            MakeTypeId,
            MakeType,
            AircraftModelId,
            AircraftModel,
            AircraftSubModel,
            NumOfEngines,
            TailNum,
            SerialNum,
            ManufacturedDate,
            PlaceInServiceDate,
            TotalTSN,
            TotalCSN,
            Hobbs,
            AircraftLocation,
            NextScheduled,
            MEL,
            AircraftStatusId,
            AircraftStatus,
            MaintenanceStatusId,
            MaintenanceStatus,
			Memo,
            IsActive,
            IsDeleted,
            MasterCompanyId,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            UpdatedDate
        )
        SELECT
            T.MakeTypeId,
            T.MakeType,
            T.AircraftModelId,
            T.AircraftModel,
            T.AircraftSubModel,
            T.NumOfEngines,
            T.TailNum,
            T.SerialNum,
            T.ManufacturedDate,
            T.PlaceInServiceDate,
            T.TotalTSN,
            T.TotalCSN,
            T.Hobbs,
            T.AircraftLocation,
            T.NextScheduled,
            T.MEL,
            T.AircraftStatusId,
            T.AircraftStatus,
            T.MaintenanceStatusId,
            T.MaintenanceStatus,
			T.Memo,
            ISNULL(T.IsActive, 1),
            ISNULL(T.IsDeleted, 0),
            T.MasterCompanyId,
            T.CreatedBy,
            T.UpdatedBy,
            GETUTCDATE(),
            GETUTCDATE()
        FROM @tbl_AircraftRegistryHeaderType T
	END
	SET @AircraftRegistryId = SCOPE_IDENTITY();
	SELECT * FROM dbo.[AircraftRegistryHeader] WITH(NOLOCK) WHERE AircraftRegistryId = @AircraftRegistryId

    END TRY      
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateAircraftRegistryHeader'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END