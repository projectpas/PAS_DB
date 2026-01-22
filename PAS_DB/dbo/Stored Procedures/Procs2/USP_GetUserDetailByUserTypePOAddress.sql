
/*************************************************************           
 ** File:   [USP_GetUserDetailByUserTypePOAddress]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve User List Based on User Type for Purchage Order Addressed    
 ** Purpose:         
 ** Date:   09/23/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/23/2020   Hemant Saliya Created
     
 EXECUTE [USP_GetUserDetailByUserTypePOAddress] 9, '',1,'50','313',1
**************************************************************/

CREATE PROCEDURE [dbo].[USP_GetUserDetailByUserTypePOAddress] (@UserTypeId bigint,
@StrFilter varchar(50),
@StartWith bit = TRUE,
@Count varchar(10) = '0',
@Idlist varchar(max) = '0',
@MasterCompanyId int)
AS
BEGIN

  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      DECLARE @Sql nvarchar(max);
      DECLARE @UserType nvarchar(50);

      IF (@Count = '0')
      BEGIN
        SET @Count = '20';
      END

      SELECT  @UserType = ModuleName  FROM dbo.Module WITH (NOLOCK)   WHERE ModuleId = @UserTypeId;
      IF (@UserType = 'Company')
      BEGIN
        SELECT DISTINCT TOP 20 LegalEntityId AS UserID,[Name] AS UserName FROM dbo.LegalEntity WITH (NOLOCK)
			WHERE MasterCompanyId = @MasterCompanyId AND (IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND (Name LIKE @StrFilter + '%'))
        UNION
        SELECT DISTINCT LegalEntityId AS UserID,[Name] AS UserName FROM dbo.LegalEntity WITH (NOLOCK) 
			WHERE LegalEntityId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ORDER BY UserName
      END
      IF (@UserType = 'Customer')
      BEGIN
        SELECT DISTINCT TOP 20 CustomerId AS UserID,Name AS UserName FROM dbo.Customer WITH (NOLOCK)
        WHERE MasterCompanyId = @MasterCompanyId AND (IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND (Name LIKE @StrFilter + '%'))
        UNION
        SELECT DISTINCT CustomerId AS UserID,Name AS UserName FROM dbo.Customer WITH (NOLOCK)
		WHERE CustomerId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ORDER BY UserName
      END
      IF (@UserType = 'Vendor')
      BEGIN
        SELECT DISTINCT TOP 20 VendorId AS UserID,VendorName AS UserName FROM dbo.Vendor WITH (NOLOCK)
        WHERE MasterCompanyId = @MasterCompanyId AND (IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND (VendorName LIKE @StrFilter + '%'))
		UNION
        SELECT DISTINCT VendorId AS UserID,VendorName AS UserName FROM dbo.Vendor WITH (NOLOCK)
		WHERE VendorId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',')) ORDER BY UserName
      END
    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[USP_GetUserDetailByUserTypePOAddress]',
            @ProcedureParameters varchar(3000) = '@Parameter1= ''' + CAST(ISNULL(@UserTypeId, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@StrFilter, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH
END