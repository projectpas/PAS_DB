/*************************************************************             
 ** File:   [USP_CreateAircraftInfoHeader]          
 ** Author:   Abhishek Jirawla 
 ** Description: This stored procedure is used to add a record in [AircraftInfo].
 ** Jira Id: PN-16426
 ** Purpose:           
 ** Date:  [05/19/2026] 
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author              Change Description              
 ** --   --------     -------          --------------------------------    
    1    05/19/2026   Abhishek Jirawla     Adding Data Validation & Restrictions [PN-16426] 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateAircraftInfoHeader]
    @tbl_AircraftInfoHeaderType dbo.AircraftInfoTableType READONLY
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  

	    DECLARE @AircraftInfoId BIGINT = (SELECT AircraftInfoId FROM @tbl_AircraftInfoHeaderType);
	    DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50),@AircraftInfoNum VARCHAR(30) = NULL;
	    DECLARE @CurrentNo INT = 0;
	    DECLARE @AircraftInfoCodePrefix INT = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='AircraftInfoNumber');
	    DECLARE @MasterCompanyId INT = (SELECT [MasterCompanyId] FROM @tbl_AircraftInfoHeaderType);
	    SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @AircraftInfoCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
            IF(@AircraftInfoId > 0)
	        BEGIN
		        UPDATE AR
                SET
                    AR.ACMakeTypeId = T.MakeTypeId,
                    AR.ACMakeTypeName = T.MakeType,
                    AR.ACModelId = T.AircraftModelId,
                    AR.ACModelName = T.AircraftModel,
                    AR.ACSubModel = T.AircraftSubModel,
                    AR.ItemMasterId = T.ItemMasterId,
                    AR.IsActive = ISNULL(T.IsActive, AR.IsActive),
                    AR.IsDeleted = ISNULL(T.IsDeleted, AR.IsDeleted),
                    AR.MasterCompanyId = T.MasterCompanyId,
                    AR.UpdatedBy = T.UpdatedBy,
                    AR.UpdatedDate = GETUTCDATE()
                FROM dbo.[AircraftInfo] AR
                INNER JOIN @tbl_AircraftInfoHeaderType T ON AR.AircraftInfoId = T.AircraftInfoId
                WHERE T.AircraftInfoId IS NOT NULL;

                SELECT 1 AS Status, 'Saved successfully' AS Message
	        END
	        ELSE
	        BEGIN
                INSERT INTO [AircraftInfo]
                (
                    ACMakeTypeId,
                    ACMakeTypeName,
                    ACModelId,
                    ACModelName,
                    ACSubModel,
                    ItemMasterId,
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
                    T.ItemMasterId,
                    ISNULL(T.IsActive, 1),
                    ISNULL(T.IsDeleted, 0),
                    T.MasterCompanyId,
                    T.CreatedBy,
                    T.UpdatedBy,
                    GETUTCDATE(),
                    GETUTCDATE()
                FROM @tbl_AircraftInfoHeaderType T
	        END
	        SET @AircraftInfoId = SCOPE_IDENTITY();
	        SELECT 1 AS Status, 'Saved successfully' AS Message, * FROM dbo.[AircraftInfo] WITH(NOLOCK) WHERE AircraftInfoId = @AircraftInfoId


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