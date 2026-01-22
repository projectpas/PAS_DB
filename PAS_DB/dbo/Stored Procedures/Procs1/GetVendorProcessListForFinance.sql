/*************************************************************           
 ** File:   [GetVendorProcessListForFinance]           
 ** Author:  Ayushi Patel
 ** Description: This stored procedure is used to get Vendor Process List for Finance from Master1099
 ** Purpose:  To fetch active and non-deleted records for given companyId       
 ** Date:   02/05/2025      
          
 ** PARAMETERS: 
 **  @CompanyId INT
         
 ** RETURN VALUE:  List of active Master1099 records           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		      Change Description            
 ** --   --------     -------		      --------------------------------          
    1    29/04/2025   Ayushi Patel        Created 
     
-- exec [dbo].[GetVendorProcessListForFinance] @CompanyId = 1
************************************************************************/

CREATE   PROCEDURE [dbo].[GetVendorProcessListForFinance]
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN
            SELECT DISTINCT 
                M.Master1099Id,
                M.Description,
                M.MasterCompanyId,
                M.CreatedDate,
                M.CreatedBy,
                M.UpdatedDate,
                M.UpdatedBy,
                ISNULL(M.IsActive, 0) AS IsActive,
                ISNULL(M.IsDeleted, 0) AS IsDeleted,
                M.Memo,
                M.Name,
                M.SequenceNo
            FROM dbo.Master1099 M WITH (NOLOCK)
            WHERE 
                M.MasterCompanyId = @CompanyId
                AND ISNULL(M.IsDeleted, 0) = 0
                AND ISNULL(M.IsActive, 0) = 1
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'GetVendorProcessListForFinance',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred. Inform Support with Error Number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END