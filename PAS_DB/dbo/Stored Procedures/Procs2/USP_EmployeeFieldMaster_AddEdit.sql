/*************************************************************             
 ** File:   [USP_EmployeeFieldMaster_AddEdit]             
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to Add or Update Employee Field Master data  
 ** Purpose:           
 ** Date:   31/05/2022  
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author    Change Description              
 ** --   --------     -------    --------------------------------            
    1    19/06/2023   Vishal Suthar   Created  
    2    03/19/2024   Ekta Chandegra IsEditable field is retrieve

************************************************************************/  
CREATE    PROCEDURE [dbo].[USP_EmployeeFieldMaster_AddEdit]  
(  
 @ModuleId bigint,  
 @CompanyId bigint,  
 @EmployeeId bigint,  
 @fieldList FieldSettingTableType READONLY  
)  
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
    IF EXISTS (SELECT FieldMasterId FROM [dbo].[EmployeeFieldMaster] WITH (NOLOCK) WHERE MasterCompanyId = @CompanyId AND ModuleId = @ModuleId AND EmployeeId = @EmployeeId)  
    BEGIN  
      --UPDATE EMP  
      --SET EMP.HeaderName = F.HeaderName,  
      --    EMP.FieldWidth = F.FieldWidth,  
      --    EMP.FieldSortOrder = F.FieldSortOrder,  
      --    EMP.FieldAlign = F.FieldAlign,  
      --    EMP.IsMobileView = F.IsMobileView,  
      --    EMP.IsActive = F.IsActive  
      --FROM [DBO].[EmployeeFieldMaster] EMP WITH (NOLOCK)  
      --INNER JOIN @fieldList F ON EMP.FieldMasterId = F.FieldMasterId  
      --WHERE MasterCompanyId = @CompanyId AND EMP.ModuleId = @ModuleId AND EmployeeId = @EmployeeId  
  
   DELETE FROM [DBO].[EmployeeFieldMaster] WHERE MasterCompanyId = @CompanyId AND ModuleId = @ModuleId AND EmployeeId = @EmployeeId  
    END  
    --ELSE  
    --BEGIN  
    INSERT INTO [DBO].[EmployeeFieldMaster] (ModuleId, EmployeeId, FieldMasterId, FieldName, HeaderName, FieldWidth, FieldType, FieldAlign, FieldFormate,  
    FieldSortOrder, IsMultiValue, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsActive, IsDeleted, IsToolTipShow, IsNumString,IsRequired , IsEditable)  
    (SELECT  
        @ModuleId,  
        @EmployeeId,  
        FL.FieldMasterId,  
        F.FieldName,  
        FL.HeaderName,  
        FL.FieldWidth,  
        F.FieldType,  
        FL.FieldAlign,  
        F.FieldFormate,  
        FL.FieldSortOrder,  
        F.IsMultiValue,  
        @CompanyId,  
        @EmployeeId,  
        GETDATE(),  
        @EmployeeId,  
        GETDATE(),  
        FL.IsActive,  
        F.IsDeleted,  
        F.IsToolTipShow,  
		F.IsNumString,
		F.IsRequired,
		F.IsEditable
    FROM @fieldList FL INNER JOIN [DBO].[FieldMaster] F WITH (NOLOCK) ON F.FieldMasterId = FL.FieldMasterId)  
    --END  
  END TRY  
  BEGIN CATCH  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            ,@AdhocComments varchar(150) = 'USP_EmployeeFieldMaster_AddEdit',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100))  
            + '@Parameter2 = ''' + CAST(ISNULL(@CompanyId, '') AS varchar(100))  
            + '@Parameter3 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
    EXEC spLogException @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
    RETURN (1);  
  END CATCH  
END