/********************************************************************
 ** File:   [USP_GetLeaseHeaderById]
 ** Description: Returns a single Lease Header record by Id.
 **
 ***********************************************************************
 ** Change History
 ***********************************************************************
 ** PR   Date         Author          Change Description
 ** --   --------     -------         ------------------------------------
    1    04/08/2026   Amit Ghediya    Created

exec USP_GetLeaseHeaderById @LeaseHeaderId = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLeaseHeaderById]
	@LeaseHeaderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT
			   LH.LeaseHeaderId
			  ,ISNULL(LH.LeaseNumber,'') AS LeaseNumber
			  ,LH.LeaseName
			  ,LH.LeaseTypeId
			  ,LH.LeaseStatusId
			  ,LH.ManagementStructureId
			  ,MS.Name AS ManagementStructureName
			  ,LH.CustomerId
			  ,C.Name AS CustomerName
			  ,LH.CustomerRef
			  ,LH.CustomerContactId
			  ,LH.Email
			  ,LH.SalespersonEmployeeId
			  ,LH.LocalCurrencyId
			  ,LH.ForeignCurrencyId
			  ,LH.ForeignExchangeRate
			  ,LH.EmployeeId
			  ,ISNULL(LH.Memo,'') AS Memo
			  ,ISNULL(LH.Notes,'') AS Notes
			  ,LH.MasterCompanyId
			  ,LH.CreatedBy
			  ,LH.UpdatedBy
			  ,LH.CreatedDate
			  ,LH.UpdatedDate
			  ,LH.IsActive
			  ,LH.IsDeleted
		FROM [dbo].[LeaseHeader] LH WITH (NOLOCK)
		LEFT JOIN dbo.Customer C WITH (NOLOCK) ON LH.CustomerId = C.CustomerId
		LEFT JOIN dbo.ManagementStructure MS WITH (NOLOCK) ON LH.ManagementStructureId = MS.ManagementStructureId
		WHERE LH.LeaseHeaderId = @LeaseHeaderId
		  AND LH.IsDeleted = 0
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_GetLeaseHeaderById]',
            @ProcedureParameters varchar(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END