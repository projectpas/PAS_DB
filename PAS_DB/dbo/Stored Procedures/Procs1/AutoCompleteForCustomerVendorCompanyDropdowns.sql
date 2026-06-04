/*************************************************************           
 ** File:   [AutoCompleteForCustomerVendorCompanyDropdowns]           
 ** Author:   Abhishek Jirawla
 ** Description: This stored procedure is used get list of customer, vendor and legalentity
 ** Purpose:         
 ** Date:    05/22/2025   
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/22/2025   Abhishek Jirawla		Created

--select * from dbo.Employee    
**************************************************************/
CREATE     PROCEDURE [dbo].[AutoCompleteForCustomerVendorCompanyDropdowns] 
	--@TableName VARCHAR(50) = NULL, 
	--@Parameter1 VARCHAR(50) = NULL, 
	--@Parameter2 VARCHAR(100) = NULL, 
	@Parameter VARCHAR(50) = NULL, 
	--@Parameter4 BIT = TRUE, 
	--@Count VARCHAR(10) = 0, 
	@Idlist VARCHAR(MAX) = '0', 
	@MasterCompanyId INT
	--@IsFromUpload BIT = 0
AS BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    BEGIN TRY
		DECLARE @CustomerModuleId INT = 0, @CompanyModuleId INT = 0, @VendorModuleId INT = 0, @OthersModuleId INT = 0

		SELECT @CustomerModuleId = ModuleId FROM Module WHERE ModuleName = 'Customer'
		SELECT @CompanyModuleId = ModuleId FROM Module WHERE ModuleName = 'Company'
		SELECT @VendorModuleId = ModuleId FROM Module WHERE ModuleName = 'Vendor'
		SELECT @OthersModuleId = ModuleId FROM Module WHERE ModuleName = 'Others'

        CREATE TABLE #TempTable (
			Value BIGINT,
			Label VARCHAR(MAX),
			ModuleId INT,
			MasterCompanyId INT
		)
       
		INSERT INTO #TempTable
		SELECT DISTINCT CustomerId AS Value, Name AS Label, @CustomerModuleId, MasterCompanyId
		FROM dbo.Customer WITH(NOLOCK)
		WHERE MasterCompanyId=@MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(Name LIKE '%'+@Parameter+'%' OR @Parameter IS NULL) )
		UNION
		SELECT DISTINCT CustomerId AS Value, Name AS Label, @CustomerModuleId, MasterCompanyId
		FROM dbo.Customer WITH(NOLOCK)
		WHERE MasterCompanyId=@MasterCompanyId AND CustomerId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
		UNION
		SELECT DISTINCT VendorId AS Value, VendorName AS Label, @VendorModuleId, MasterCompanyId
		FROM dbo.Vendor WITH(NOLOCK)
		WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(VendorName LIKE '%'+@Parameter+'%' OR @Parameter IS NULL))
		UNION
		SELECT DISTINCT VendorId AS Value, VendorName AS Label, @VendorModuleId, MasterCompanyId
		FROM dbo.Vendor WITH(NOLOCK)
		WHERE MasterCompanyId=@MasterCompanyId AND VendorId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') )
		UNION
		SELECT DISTINCT LegalEntityId AS Value, Name AS Label, @CompanyModuleId, MasterCompanyId
		FROM dbo.LegalEntity WITH(NOLOCK)
		WHERE MasterCompanyId=@MasterCompanyId AND(IsActive=1 AND ISNULL(IsDeleted, 0)=0 AND(Name LIKE '%'+@Parameter+'%' OR @Parameter IS NULL))
		UNION
		SELECT DISTINCT LegalEntityId AS Value, Name AS Label, @CompanyModuleId, MasterCompanyId
		FROM dbo.LegalEntity WITH(NOLOCK)
		WHERE MasterCompanyId=@MasterCompanyId AND LegalEntityId IN(SELECT Item FROM DBO.SPLITSTRING(@Idlist, ',') );

        WITH Ranked AS (
		SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Label ORDER BY (SELECT NULL)) AS rn
			FROM #TempTable
		)
		SELECT Value, Label, ModuleId, MasterCompanyId
		FROM Ranked
		WHERE rn = 1
		ORDER BY Label, ModuleId;
        DROP Table #TempTable
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) =db_name(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments VARCHAR(150) ='AutoCompleteForCustomerVendorCompanyDropdowns', @ProcedureParameters VARCHAR(3000) = 
			--'@Parameter1 = '''+CAST(ISNULL(@TableName, '') as varchar(100))+ 
			--'@Parameter2 = '''+CAST(ISNULL(@Parameter1, '') as varchar(100))+
			--'@Parameter = '''+CAST(ISNULL(@Parameter2, '') as varchar(100))+
			'@Parameter1 = '''+CAST(ISNULL(@Parameter, '') as varchar(100))+
			--'@Parameter5 = '''+CAST(ISNULL(@Parameter4, '') as varchar(100))+
			--'@Parameter6 = '''+CAST(ISNULL(@Count, '') as varchar(100))+
			'@Parameter2 = '''+CAST(ISNULL(@Idlist, '') as varchar(100))+
			'@Parameter3 = '''+CAST(ISNULL(@MasterCompanyId, '') as varchar(100)), 
			@ApplicationName VARCHAR(100) = 'PAS'
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
        EXEC spLogException @DatabaseName=@DatabaseName, @AdhocComments=@AdhocComments, @ProcedureParameters=@ProcedureParameters, @ApplicationName=@ApplicationName, @ErrorLogID=@ErrorLogID OUTPUT;
        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END